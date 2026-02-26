import 'dart:convert';
import 'dart:math';

import 'package:habit_dashboard/core/notifications/notification_service.dart';
import 'package:habit_dashboard/features/habits/domain/habit.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HabitRepository {
  static const _storageKey = 'habits_v1';

  final List<Habit> _habits = [];
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);

    // First launch (or wiped storage) -> seed demo habits.
    if (raw == null || raw.trim().isEmpty) {
      _habits
        ..clear()
        ..addAll(
          const [
            Habit(
              id: '1',
              title: 'Drink water',
              completedDates: <String>{},
              bestStreak: 0,
              targetDays: 21,
              archived: false,
              reminderMinutes: null,
            ),
            Habit(
              id: '2',
              title: 'Workout',
              completedDates: <String>{},
              bestStreak: 0,
              targetDays: 30,
              archived: false,
              reminderMinutes: null,
            ),
            Habit(
              id: '3',
              title: 'Read 20 minutes',
              completedDates: <String>{},
              bestStreak: 0,
              targetDays: 0,
              archived: false,
              reminderMinutes: null,
            ),
            Habit(
              id: '4',
              title: 'Meditate',
              completedDates: <String>{},
              bestStreak: 0,
              targetDays: 14,
              archived: false,
              reminderMinutes: null,
            ),
          ],
        );

      await _save(prefs);
      _initialized = true;

      // Sync notifications on first launch too.
      await NotificationService.instance.syncFromHabits(_habits);
      return;
    }

    // Defensive decode: if the JSON gets corrupted, don't crash the whole app.
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        _habits
          ..clear()
          ..addAll(
            decoded
                .whereType<Map>()
                .map((m) => Habit.fromJson(Map<String, dynamic>.from(m)))
                .map(_ensureBestStreakConsistent),
          );
      }
    } catch (_) {
      // Fallback to empty list (keeps app usable).
      _habits.clear();
    }

    // Save back (useful if you add migrations later).
    await _save(prefs);
    _initialized = true;

    // Recreate notification schedules from stored habits.
    await NotificationService.instance.syncFromHabits(_habits);
  }

  List<Habit> getHabits() => List.unmodifiable(_habits);

  Habit? getById(String id) {
    final i = _habits.indexWhere((h) => h.id == id);
    if (i == -1) return null;
    return _habits[i];
  }

  // ---------- core actions ----------

  Future<void> toggleHabit(String id) async {
    final i = _habits.indexWhere((h) => h.id == id);
    if (i == -1) return;

    final prefs = await SharedPreferences.getInstance();
    final today = _todayKey();

    final current = _habits[i];
    final newDates = Set<String>.from(current.completedDates);

    if (newDates.contains(today)) {
      newDates.remove(today);
    } else {
      newDates.add(today);
    }

    final best = Habit.calcBestStreakPublic(newDates);

    _habits[i] = current.copyWith(
      completedDates: newDates,
      bestStreak: best,
    );

    await _save(prefs);
  }

  Future<void> toggleDate(String habitId, String dateKey) async {
    final i = _habits.indexWhere((h) => h.id == habitId);
    if (i == -1) return;

    final prefs = await SharedPreferences.getInstance();

    final current = _habits[i];
    final newDates = Set<String>.from(current.completedDates);

    if (newDates.contains(dateKey)) {
      newDates.remove(dateKey);
    } else {
      newDates.add(dateKey);
    }

    final best = Habit.calcBestStreakPublic(newDates);

    _habits[i] = current.copyWith(
      completedDates: newDates,
      bestStreak: best,
    );

    await _save(prefs);
  }

  Future<void> addHabit(String title, int targetDays, int? reminderMinutes) async {
    final t = title.trim();
    if (t.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();

    // Very low chance of collision + stable across sessions.
    final newId =
        '${DateTime.now().microsecondsSinceEpoch}_${Random().nextInt(1 << 20)}';

    final habit = Habit(
      id: newId,
      title: t,
      completedDates: <String>{},
      bestStreak: 0,
      targetDays: targetDays,
      archived: false,
      reminderMinutes: reminderMinutes,
    );

    _habits.add(habit);

    await _save(prefs);

    // Schedule notification if enabled.
    if (reminderMinutes != null) {
      await NotificationService.instance
          .scheduleHabitReminder(habit: habit, minutesFromMidnight: reminderMinutes);
    }
  }

  Future<void> removeHabit(String id) async {
    _habits.removeWhere((h) => h.id == id);

    // Cancel notification.
    await NotificationService.instance.cancelHabitReminder(id);

    final prefs = await SharedPreferences.getInstance();
    await _save(prefs);
  }

  Future<void> insertHabitAt(int index, Habit habit) async {
    final prefs = await SharedPreferences.getInstance();
    final safeIndex = index.clamp(0, _habits.length);

    // Ensure best streak field is consistent in case it came from an older object.
    final fixed = _ensureBestStreakConsistent(habit);

    _habits.insert(safeIndex, fixed);
    await _save(prefs);

    // Restore reminder if it was on.
    if (!fixed.archived && fixed.reminderMinutes != null) {
      await NotificationService.instance.scheduleHabitReminder(
        habit: fixed,
        minutesFromMidnight: fixed.reminderMinutes!,
      );
    }
  }

  Future<void> renameHabit(String id, String newTitle) async {
    final t = newTitle.trim();
    if (t.isEmpty) return;

    final i = _habits.indexWhere((h) => h.id == id);
    if (i == -1) return;

    final updated = _habits[i].copyWith(title: t);
    _habits[i] = updated;

    final prefs = await SharedPreferences.getInstance();
    await _save(prefs);

    // If reminder exists, reschedule so notification body reflects new title.
    if (!updated.archived && updated.reminderMinutes != null) {
      await NotificationService.instance.scheduleHabitReminder(
        habit: updated,
        minutesFromMidnight: updated.reminderMinutes!,
      );
    }
  }

  Future<void> setTargetDays(String id, int targetDays) async {
    final i = _habits.indexWhere((h) => h.id == id);
    if (i == -1) return;

    _habits[i] = _habits[i].copyWith(targetDays: targetDays);
    final prefs = await SharedPreferences.getInstance();
    await _save(prefs);
  }

  Future<void> restartHabitProgress(String id) async {
    final i = _habits.indexWhere((h) => h.id == id);
    if (i == -1) return;

    final prefs = await SharedPreferences.getInstance();

    _habits[i] = _habits[i].copyWith(
      completedDates: <String>{},
      bestStreak: 0,
    );

    await _save(prefs);
  }

  Future<void> setArchived(String id, bool archived) async {
    final i = _habits.indexWhere((h) => h.id == id);
    if (i == -1) return;

    final prefs = await SharedPreferences.getInstance();
    final updated = _habits[i].copyWith(archived: archived);
    _habits[i] = updated;

    await _save(prefs);

    // Archived habits shouldn't notify.
    if (archived) {
      await NotificationService.instance.cancelHabitReminder(id);
    } else {
      // Re-schedule if reminder is enabled.
      final minutes = updated.reminderMinutes;
      if (minutes != null) {
        await NotificationService.instance
            .scheduleHabitReminder(habit: updated, minutesFromMidnight: minutes);
      }
    }
  }

  Future<void> setReminderMinutes(String id, int? reminderMinutes) async {
    final i = _habits.indexWhere((h) => h.id == id);
    if (i == -1) return;

    final prefs = await SharedPreferences.getInstance();
    final updated = _habits[i].copyWith(reminderMinutes: reminderMinutes);
    _habits[i] = updated;

    await _save(prefs);

    // Update notification schedule.
    if (updated.archived) {
      await NotificationService.instance.cancelHabitReminder(id);
      return;
    }

    if (reminderMinutes == null) {
      await NotificationService.instance.cancelHabitReminder(id);
    } else {
      await NotificationService.instance.scheduleHabitReminder(
        habit: updated,
        minutesFromMidnight: reminderMinutes,
      );
    }
  }

  /// Reorder by IDs (safe when you have filters/search applied).
  Future<void> reorderByIds(int oldIndex, int newIndex, List<String> visibleIds) async {
    if (oldIndex < 0 || oldIndex >= visibleIds.length) return;
    if (newIndex < 0 || newIndex > visibleIds.length) return;

    // ReorderableListView gives newIndex after removal.
    if (newIndex > oldIndex) newIndex -= 1;
    if (oldIndex == newIndex) return;

    final movedId = visibleIds[oldIndex];

    // Remove from the full list.
    final from = _habits.indexWhere((h) => h.id == movedId);
    if (from == -1) return;
    final moved = _habits.removeAt(from);

    // Insert before the ID that is currently at newIndex in visible list.
    var insertAt = _habits.length;
    if (newIndex < visibleIds.length) {
      final beforeId = visibleIds[newIndex];
      final beforePos = _habits.indexWhere((h) => h.id == beforeId);
      if (beforePos != -1) insertAt = beforePos;
    }

    _habits.insert(insertAt, moved);

    final prefs = await SharedPreferences.getInstance();
    await _save(prefs);
  }

  // ---------- menu actions ----------

  Future<void> resetToday() async {
    final prefs = await SharedPreferences.getInstance();
    final today = _todayKey();

    for (var i = 0; i < _habits.length; i++) {
      final h = _habits[i];
      if (!h.completedDates.contains(today)) continue;

      final newDates = Set<String>.from(h.completedDates)..remove(today);
      final best = Habit.calcBestStreakPublic(newDates);
      _habits[i] = h.copyWith(completedDates: newDates, bestStreak: best);
    }

    await _save(prefs);
  }

  Future<void> markAllDoneToday() async {
    final prefs = await SharedPreferences.getInstance();
    final today = _todayKey();

    for (var i = 0; i < _habits.length; i++) {
      final h = _habits[i];
      if (h.completedDates.contains(today)) continue;

      final newDates = Set<String>.from(h.completedDates)..add(today);
      final best = Habit.calcBestStreakPublic(newDates);
      _habits[i] = h.copyWith(completedDates: newDates, bestStreak: best);
    }

    await _save(prefs);
  }

  // ---------- helpers ----------

  String _todayKey() => _keyFromDate(DateTime.now());

  String _keyFromDate(DateTime d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${d.year}-${two(d.month)}-${two(d.day)}';
  }

  Habit _ensureBestStreakConsistent(Habit h) {
    final computed = Habit.calcBestStreakPublic(h.completedDates);
    if (h.bestStreak == computed) return h;
    return h.copyWith(bestStreak: computed);
  }

  Future<void> _save(SharedPreferences prefs) async {
    final raw = jsonEncode(_habits.map((h) => h.toJson()).toList());
    await prefs.setString(_storageKey, raw);
  }
}