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

    if (raw == null || raw.trim().isEmpty) {
      _habits.clear();
      await _save(prefs);
      _initialized = true;
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

  Future<void> seedStarterHabitsIfEmpty() async {
    await init();
    if (_habits.isNotEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    _habits
      ..clear()
      ..addAll(_starterHabits());

    await _save(prefs);
    await NotificationService.instance.syncFromHabits(_habits);
  }

  bool get hasAnyHabits => _habits.isNotEmpty;

  List<Habit> _starterHabits() {
    return const [
      Habit(
        id: 'starter_1',
        title: 'Drink water',
        completedDates: <String>{},
        skippedDates: <String>{},
        bestStreak: 0,
        type: Habit.typeBuild,
        targetDays: 21,
        weeklyTarget: 0,
        archived: false,
        reminderMinutes: null,
        notes: 'A small daily win that helps energy and focus.',
        iconKey: 'water',
        colorValue: 0xFF0EA5E9,
      ),
      Habit(
        id: 'starter_2',
        title: 'Workout',
        completedDates: <String>{},
        skippedDates: <String>{},
        bestStreak: 0,
        type: Habit.typeBuild,
        targetDays: 30,
        weeklyTarget: 0,
        archived: false,
        reminderMinutes: null,
        notes: 'Even a short session counts. Consistency first.',
        iconKey: 'fitness',
        colorValue: 0xFFEF4444,
      ),
      Habit(
        id: 'starter_3',
        title: 'Read 20 minutes',
        completedDates: <String>{},
        skippedDates: <String>{},
        bestStreak: 0,
        type: Habit.typeBuild,
        targetDays: 0,
        weeklyTarget: 4,
        archived: false,
        reminderMinutes: null,
        notes: 'A calm daily habit for growth and focus.',
        iconKey: 'book',
        colorValue: 0xFFF59E0B,
      ),
      Habit(
        id: 'starter_4',
        title: 'No vaping',
        completedDates: <String>{},
        skippedDates: <String>{},
        bestStreak: 0,
        type: Habit.typeQuit,
        targetDays: 14,
        weeklyTarget: 0,
        archived: false,
        reminderMinutes: null,
        notes: 'Breathe easier, save money, feel cleaner.',
        iconKey: 'no_vape',
        colorValue: 0xFF7C3AED,
      ),
    ];
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
final newDone = Set<String>.from(current.completedDates);
final newSkipped = Set<String>.from(current.skippedDates);

if (newDone.contains(today)) {
  newDone.remove(today);
} else {
  newDone.add(today);
  newSkipped.remove(today); // can't be both done and skipped
}

final best = Habit.calcBestStreakPublic(newDone, newSkipped);

_habits[i] = current.copyWith(
  completedDates: newDone,
  skippedDates: newSkipped,
  bestStreak: best,
);

    await _save(prefs);
  }

  Future<void> toggleDate(String habitId, String dateKey) async {
    final i = _habits.indexWhere((h) => h.id == habitId);
    if (i == -1) return;

    final prefs = await SharedPreferences.getInstance();

    final current = _habits[i];
final newDone = Set<String>.from(current.completedDates);
final newSkipped = Set<String>.from(current.skippedDates);

if (newDone.contains(dateKey)) {
  newDone.remove(dateKey);
} else {
  newDone.add(dateKey);
  newSkipped.remove(dateKey); // can't be both done and skipped
}

final best = Habit.calcBestStreakPublic(newDone, newSkipped);

_habits[i] = current.copyWith(
  completedDates: newDone,
  skippedDates: newSkipped,
  bestStreak: best,
);

    await _save(prefs);
  }

/// Toggle "rest day" (skip) for an arbitrary date.
/// Skipped days do NOT count as completions, but they do NOT break streaks.
Future<void> toggleSkipDate(String habitId, String dateKey) async {
  final i = _habits.indexWhere((h) => h.id == habitId);
  if (i == -1) return;

  final prefs = await SharedPreferences.getInstance();

  final current = _habits[i];
  final newDone = Set<String>.from(current.completedDates);
  final newSkipped = Set<String>.from(current.skippedDates);

  if (newSkipped.contains(dateKey)) {
    newSkipped.remove(dateKey);
  } else {
    newSkipped.add(dateKey);
    newDone.remove(dateKey); // can't be both done and skipped
  }

  final best = Habit.calcBestStreakPublic(newDone, newSkipped);

  _habits[i] = current.copyWith(
    completedDates: newDone,
    skippedDates: newSkipped,
    bestStreak: best,
  );

  await _save(prefs);
}


/// Toggle "rest day" (skip) for today.
Future<void> toggleSkipToday(String habitId) async {
  await toggleSkipDate(habitId, _todayKey());
}


  Future<void> addHabit(
    String title,
    String type,
    int targetDays,
    int weeklyTarget,
    int? reminderMinutes,
    String notes,
    String iconKey,
    int colorValue,
  ) async {
    final t = title.trim();
    if (t.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();

    // Very low chance of collision + stable across sessions.
    final newId =
        '${DateTime.now().microsecondsSinceEpoch}_${Random().nextInt(1 << 20)}';

    // Keep the goals mutually exclusive: weeklyTarget wins if set.
    final normalizedWeekly = weeklyTarget.clamp(0, 7);
    final normalizedTargetDays = normalizedWeekly > 0 ? 0 : targetDays;

    final habit = Habit(
      id: newId,
      title: t,
      type: type,
      completedDates: <String>{},
      skippedDates: <String>{},
      bestStreak: 0,
      targetDays: normalizedTargetDays,
      weeklyTarget: normalizedWeekly,
      archived: false,
      reminderMinutes: reminderMinutes,
      notes: notes.trim(),
      iconKey: iconKey,
      colorValue: colorValue,
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

  Future<void> setNotes(String id, String notes) async {
    final i = _habits.indexWhere((h) => h.id == id);
    if (i == -1) return;

    final updated = _habits[i].copyWith(notes: notes.trim());
    _habits[i] = updated;

    final prefs = await SharedPreferences.getInstance();
    await _save(prefs);
  }

  Future<void> setType(String id, String type) async {
    final i = _habits.indexWhere((h) => h.id == id);
    if (i == -1) return;

    _habits[i] = _habits[i].copyWith(type: type);

    final prefs = await SharedPreferences.getInstance();
    await _save(prefs);
  }

  Future<void> setAppearance(String id, String iconKey, int colorValue) async {
    final i = _habits.indexWhere((h) => h.id == id);
    if (i == -1) return;

    _habits[i] = _habits[i].copyWith(
      iconKey: iconKey,
      colorValue: colorValue,
    );

    final prefs = await SharedPreferences.getInstance();
    await _save(prefs);
  }

  Future<void> setTargetDays(String id, int targetDays) async {
    final i = _habits.indexWhere((h) => h.id == id);
    if (i == -1) return;

    // If user sets a duration goal, disable weekly goal.
    final updated = _habits[i].copyWith(
      targetDays: targetDays,
      weeklyTarget: targetDays > 0 ? 0 : _habits[i].weeklyTarget,
    );
    _habits[i] = updated;
    final prefs = await SharedPreferences.getInstance();
    await _save(prefs);
  }

  Future<void> setWeeklyTarget(String id, int weeklyTarget) async {
    final i = _habits.indexWhere((h) => h.id == id);
    if (i == -1) return;

    final prefs = await SharedPreferences.getInstance();

    // If user sets a weekly goal, disable duration goal.
    final normalizedWeekly = weeklyTarget.clamp(0, 7);
    final updated = _habits[i].copyWith(
      weeklyTarget: normalizedWeekly,
      targetDays: normalizedWeekly > 0 ? 0 : _habits[i].targetDays,
    );
    _habits[i] = updated;

    await _save(prefs);
  }

  Future<void> restartHabitProgress(String id) async {
    final i = _habits.indexWhere((h) => h.id == id);
    if (i == -1) return;

    final prefs = await SharedPreferences.getInstance();

    _habits[i] = _habits[i].copyWith(
      completedDates: <String>{},
      skippedDates: <String>{},
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

      // Clear BOTH "done" and "skipped" for today (reset means no status).
      final hadAny = h.completedDates.contains(today) || h.skippedDates.contains(today);
      if (!hadAny) continue;

      final newDone = Set<String>.from(h.completedDates)..remove(today);
      final newSkipped = Set<String>.from(h.skippedDates)..remove(today);

      final best = Habit.calcBestStreakPublic(newDone, newSkipped);

      _habits[i] = h.copyWith(
        completedDates: newDone,
        skippedDates: newSkipped,
        bestStreak: best,
      );
    }

    await _save(prefs);
  }

  Future<void> markAllDoneToday() async {
    final prefs = await SharedPreferences.getInstance();
    final today = _todayKey();

    for (var i = 0; i < _habits.length; i++) {
      final h = _habits[i];

      final newDone = Set<String>.from(h.completedDates)..add(today);
      // Can't be both done and skipped on the same day.
      final newSkipped = Set<String>.from(h.skippedDates)..remove(today);

      final best = Habit.calcBestStreakPublic(newDone, newSkipped);

      _habits[i] = h.copyWith(
        completedDates: newDone,
        skippedDates: newSkipped,
        bestStreak: best,
      );
    }

    await _save(prefs);
  }

  /// Export all habits as plain JSON array (legacy/clipboard-friendly format).
  /// Use pretty=true to make it easier for humans to store/share.
  String exportHabitsJson({bool pretty = false}) {
    final list = _habits.map((h) => h.toJson()).toList();
    if (!pretty) return jsonEncode(list);

    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(list);
  }

  /// Export a richer JSON backup object for file-based backups.
  /// Includes metadata while staying easy to inspect manually.
  Map<String, dynamic> exportBackupPayload() {
    return <String, dynamic>{
      'app': 'habit_dashboard',
      'formatVersion': 2,
      'exportedAt': DateTime.now().toIso8601String(),
      'habitCount': _habits.length,
      'habits': _habits.map((h) => h.toJson()).toList(),
    };
  }

  String exportBackupBundleJson({bool pretty = false}) {
    final payload = exportBackupPayload();
    if (!pretty) return jsonEncode(payload);

    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(payload);
  }

  /// Replace ALL habits from a JSON backup.
  /// Supports both legacy List backups and wrapped file backups.
  /// Throws [FormatException] if JSON is invalid.
  Future<void> importHabitsJson(String rawJson) async {
    final decoded = jsonDecode(rawJson);

    List<dynamic> items;
    if (decoded is List) {
      items = decoded;
    } else if (decoded is Map && decoded['habits'] is List) {
      items = List<dynamic>.from(decoded['habits'] as List);
    } else {
      throw const FormatException(
        'Backup JSON must be either a List or an object containing a habits list.',
      );
    }

    final incoming = <Habit>[];
    for (final item in items) {
      if (item is! Map) continue;
      final habit = Habit.fromJson(Map<String, dynamic>.from(item));
      // Ensure bestStreak stays correct (and keeps migrations safe).
      incoming.add(_ensureBestStreakConsistent(habit));
    }

    final prefs = await SharedPreferences.getInstance();

    _habits
      ..clear()
      ..addAll(incoming);

    await _save(prefs);

    // Rebuild notification schedules based on restored data.
    await NotificationService.instance.syncFromHabits(_habits);
  }

  // ---------- helpers ----------

  String _todayKey() => _keyFromDate(DateTime.now());

  String _keyFromDate(DateTime d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${d.year}-${two(d.month)}-${two(d.day)}';
  }

  Habit _ensureBestStreakConsistent(Habit h) {
    final computed = Habit.calcBestStreakPublic(h.completedDates, h.skippedDates);
    if (h.bestStreak == computed) return h;
    return h.copyWith(bestStreak: computed);
  }

  Future<void> _save(SharedPreferences prefs) async {
    final raw = jsonEncode(_habits.map((h) => h.toJson()).toList());
    await prefs.setString(_storageKey, raw);
  }
}
