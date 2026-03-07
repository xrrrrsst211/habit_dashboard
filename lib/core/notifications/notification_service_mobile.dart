import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'package:habit_dashboard/features/habits/domain/habit.dart';

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    tz.initializeTimeZones();
    final localTz = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(localTz));

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    const initSettings = InitializationSettings(android: androidInit, iOS: iosInit);

    await _plugin.initialize(initSettings);

    try {
      final android = _plugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      await android?.requestNotificationsPermission();
    } catch (_) {}

    try {
      final ios = _plugin
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
      await ios?.requestPermissions(alert: true, badge: true, sound: true);
    } catch (_) {}

    _initialized = true;
  }

  Future<void> syncFromHabits(List<Habit> habits) async {
    if (!_initialized) {
      await init();
    }

    await _plugin.cancelAll();

    for (final h in habits) {
      if (h.archived) continue;
      final minutes = h.reminderMinutes;
      if (minutes == null) continue;
      await scheduleHabitReminder(habit: h, minutesFromMidnight: minutes);
    }
  }

  Future<void> scheduleHabitReminder({
    required Habit habit,
    required int minutesFromMidnight,
  }) async {
    if (!_initialized) await init();

    await cancelHabitReminder(habit.id);

    const androidDetails = AndroidNotificationDetails(
      'habit_reminders',
      'Habit reminders',
      channelDescription: 'Daily reminders for your habits',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    final weekdays = habit.reminderWeekdays.isEmpty
        ? Habit.defaultReminderWeekdays
        : habit.reminderWeekdays;

    for (final weekday in weekdays) {
      final when = _nextInstanceOfWeekday(weekday, minutesFromMidnight);
      await _plugin.zonedSchedule(
        _notifIdForHabit(habit.id, weekday),
        'Habit reminder',
        _primaryMessageFor(habit),
        when,
        details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        payload: habit.id,
      );

      if (habit.reminderEveningNudge) {
        final nudgeMinutes = min(minutesFromMidnight + 120, 22 * 60);
        final nudgeWhen = _nextInstanceOfWeekday(weekday, nudgeMinutes);
        await _plugin.zonedSchedule(
          _notifIdForHabit(habit.id, weekday, isNudge: true),
          'Protect your streak',
          _nudgeMessageFor(habit),
          nudgeWhen,
          details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
          payload: '${habit.id}::nudge',
        );
      }
    }

    if (kDebugMode) {
      // ignore: avoid_print
      print('[notifications] synced smart reminder for ${habit.title}');
    }
  }

  Future<void> cancelHabitReminder(String habitId) async {
    if (!_initialized) await init();
    for (var weekday = 1; weekday <= 7; weekday++) {
      await _plugin.cancel(_notifIdForHabit(habitId, weekday));
      await _plugin.cancel(_notifIdForHabit(habitId, weekday, isNudge: true));
    }
  }

  tz.TZDateTime _nextInstanceOfWeekday(int weekday, int minutesFromMidnight) {
    final now = tz.TZDateTime.now(tz.local);
    final hour = minutesFromMidnight ~/ 60;
    final minute = minutesFromMidnight % 60;

    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    while (scheduled.weekday != weekday || !scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  int _notifIdForHabit(String habitId, int weekday, {bool isNudge = false}) {
    const int fnvPrime = 16777619;
    int hash = 2166136261;
    for (final codeUnit in '${habitId}_${weekday}_${isNudge ? 'n' : 'p'}'.codeUnits) {
      hash ^= codeUnit;
      hash = (hash * fnvPrime) & 0xFFFFFFFF;
    }
    return max(1, hash & 0x7FFFFFFF);
  }

  String _primaryMessageFor(Habit habit) {
    final custom = habit.reminderMessage.trim();
    if (custom.isNotEmpty) return custom;
    return habit.isQuit ? 'Stay clean today — ${habit.title}' : habit.title;
  }

  String _nudgeMessageFor(Habit habit) {
    if (habit.reminderOnlyIfIncomplete) {
      return habit.isQuit
          ? 'If you have not checked in yet, protect your clean streak tonight.'
          : 'If you have not checked in yet, there is still time to complete this today.';
    }
    return habit.isQuit
        ? 'Evening nudge for ${habit.title}. Keep the clean streak alive.'
        : 'Evening nudge for ${habit.title}. Still time today.';
  }
}
