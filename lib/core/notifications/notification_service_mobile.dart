import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'package:habit_dashboard/features/habits/domain/habit.dart';

/// Handles local notifications for habit reminders.
///
/// - Schedules ONE daily notification per habit (if reminderMinutes != null).
/// - Cancels when reminder is turned off or habit is archived/deleted.
/// - On app start, re-syncs schedules from persisted habits.
class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    // Timezone init (required for zonedSchedule).
    tz.initializeTimeZones();
    final localTz = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(localTz));

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    const initSettings = InitializationSettings(android: androidInit, iOS: iosInit);

    await _plugin.initialize(initSettings);

    // Permissions (Android 13+ and iOS).
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

  /// Re-create all schedules from the provided habits.
  /// (Useful on cold start or after you changed reminder times.)
  Future<void> syncFromHabits(List<Habit> habits) async {
    if (!_initialized) {
      await init();
    }

    // Cancel all then re-schedule only the active reminders.
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

    final id = _notifIdForHabit(habit.id);
    final when = _nextInstanceOfMinutes(minutesFromMidnight);

    const androidDetails = AndroidNotificationDetails(
      'habit_reminders',
      'Habit reminders',
      channelDescription: 'Daily reminders for your habits',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails();

    const details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _plugin.zonedSchedule(
      id,
      'Habit reminder',
      habit.title,
      when,
      details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time, // repeats daily
      payload: habit.id,
    );

    if (kDebugMode) {
      // ignore: avoid_print
      print('[notifications] scheduled "${habit.title}" at $minutesFromMidnight -> $when (id=$id)');
    }
  }

  Future<void> cancelHabitReminder(String habitId) async {
    if (!_initialized) await init();
    await _plugin.cancel(_notifIdForHabit(habitId));
  }

  tz.TZDateTime _nextInstanceOfMinutes(int minutesFromMidnight) {
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

    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  int _notifIdForHabit(String habitId) {
    // Stable 32-bit hash (FNV-1a) -> within Android notification id range.
    const int fnvPrime = 16777619;
    int hash = 2166136261;
    for (final codeUnit in habitId.codeUnits) {
      hash ^= codeUnit;
      hash = (hash * fnvPrime) & 0xFFFFFFFF;
    }
    return max(1, hash & 0x7FFFFFFF);
  }
}