import 'package:flutter/material.dart';

class Habit {
  final String id;
  final String title;

  /// 'build' or 'quit'
  final String type;

  /// Fact completion dates: {"yyyy-MM-dd", ...}
  final Set<String> completedDates;

  /// Skipped dates (rest days): {"yyyy-MM-dd", ...}
  ///
  /// Skipped days do NOT count as a completion, but they do NOT break streaks.
  final Set<String> skippedDates;

  /// Best (max) streak across all time.
  final int bestStreak;

  /// Goal in days. 0 = no limit
  final int targetDays;

  /// Weekly goal: how many completions per week. 0 = off
  final int weeklyTarget;

  /// Archived?
  final bool archived;

  /// Reminder: minutes from 00:00 (e.g. 20:30 = 1230). null = off
  final int? reminderMinutes;

  /// Optional note / reason for the habit
  final String notes;

  /// UI appearance
  final String iconKey;
  final int colorValue;

  static const String typeBuild = 'build';
  static const String typeQuit = 'quit';
  static const String defaultIconKey = 'spark';
  static const int defaultColorValue = 0xFF6D5DF6;

  static const List<String> typeValues = <String>[typeBuild, typeQuit];

  static const List<String> iconKeys = <String>[
    'spark',
    'water',
    'fitness',
    'book',
    'meditate',
    'walk',
    'code',
    'study',
    'journal',
    'clean',
    'sleep',
    'food',
    'no_smoking',
    'no_alcohol',
    'no_vape',
    'no_sugar',
    'no_junk_food',
    'no_late_sleep',
  ];

  static const List<int> colorValues = <int>[
    0xFF6D5DF6,
    0xFF4F46E5,
    0xFF0EA5E9,
    0xFF10B981,
    0xFFF59E0B,
    0xFFEF4444,
    0xFFEC4899,
    0xFF8B5CF6,
    0xFF14B8A6,
    0xFF84CC16,
    0xFF64748B,
    0xFF7C3AED,
  ];

  const Habit({
    required this.id,
    required this.title,
    required this.type,
    required this.completedDates,
    required this.skippedDates,
    required this.bestStreak,
    required this.targetDays,
    required this.weeklyTarget,
    required this.archived,
    required this.reminderMinutes,
    required this.notes,
    required this.iconKey,
    required this.colorValue,
  });

  Habit copyWith({
    String? id,
    String? title,
    String? type,
    Set<String>? completedDates,
    Set<String>? skippedDates,
    int? bestStreak,
    int? targetDays,
    int? weeklyTarget,
    bool? archived,
    int? reminderMinutes,
    String? notes,
    String? iconKey,
    int? colorValue,
  }) {
    return Habit(
      id: id ?? this.id,
      title: title ?? this.title,
      type: _normalizeType(type ?? this.type),
      completedDates: completedDates ?? this.completedDates,
      skippedDates: skippedDates ?? this.skippedDates,
      bestStreak: bestStreak ?? this.bestStreak,
      targetDays: targetDays ?? this.targetDays,
      weeklyTarget: weeklyTarget ?? this.weeklyTarget,
      archived: archived ?? this.archived,
      reminderMinutes: reminderMinutes ?? this.reminderMinutes,
      notes: _normalizeNotes(notes ?? this.notes),
      iconKey: _normalizeIconKey(iconKey ?? this.iconKey),
      colorValue: _normalizeColorValue(colorValue ?? this.colorValue),
    );
  }

  bool get isQuit => type == typeQuit;
  bool get isBuild => type == typeBuild;
  Color get color => Color(colorValue);
  IconData get iconData => iconDataFor(iconKey);
  String get typeLabel => isQuit ? 'Quit habit' : 'Build habit';
  String get completionActionLabel => isQuit ? 'Stayed clean today' : 'Done today';
  String get streakLabel => isQuit ? 'clean streak' : 'day streak';

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'type': type,
        'completedDates': completedDates.toList(),
        'skippedDates': skippedDates.toList(),
        'bestStreak': bestStreak,
        'targetDays': targetDays,
        'weeklyTarget': weeklyTarget,
        'archived': archived,
        'reminderMinutes': reminderMinutes,
        'notes': notes,
        'iconKey': iconKey,
        'colorValue': colorValue,
      };

  static Habit fromJson(Map<String, dynamic> json) {
    final rawDates = json['completedDates'];
    final rawSkipped = json['skippedDates'];

    Set<String> dates = {};
    Set<String> skipped = {};
    if (rawDates is List) {
      dates = rawDates.whereType<String>().toSet();
    }
    if (rawSkipped is List) {
      skipped = rawSkipped.whereType<String>().toSet();
    }

    if (dates.isEmpty) {
      final oldStreak = (json['streak'] as int?) ?? 0;
      final oldDoneToday = (json['doneToday'] as bool?) ?? false;
      final oldLast = (json['lastCompletedDate'] as String?) ?? '';

      DateTime? endDate;
      if (oldLast.isNotEmpty) endDate = _tryParseYmd(oldLast);
      endDate ??= DateTime.now();

      if (oldDoneToday || oldLast.isNotEmpty || oldStreak > 0) {
        final streakToRebuild = oldStreak > 0 ? oldStreak : 1;
        final capped = streakToRebuild.clamp(1, 365);

        for (int i = 0; i < capped; i++) {
          final d = endDate.subtract(Duration(days: i));
          dates.add(_ymd(d));
        }
      }
    }

    final migratedTitle = (json['title'] as String?) ?? '';
    final migratedType = _normalizeType(
      (json['type'] as String?) ?? _suggestType(migratedTitle),
    );
    final storedBest = (json['bestStreak'] as int?);
    final best = storedBest ?? _calcBestStreak(dates, skipped);

    return Habit(
      id: (json['id'] as String?) ?? '',
      title: migratedTitle,
      type: migratedType,
      completedDates: dates,
      skippedDates: skipped,
      bestStreak: best,
      targetDays: (json['targetDays'] as int?) ?? 0,
      weeklyTarget: (json['weeklyTarget'] as int?) ?? 0,
      archived: (json['archived'] as bool?) ?? false,
      reminderMinutes: (json['reminderMinutes'] as int?),
      notes: _normalizeNotes((json['notes'] as String?) ?? ''),
      iconKey: _normalizeIconKey(
        (json['iconKey'] as String?) ?? _suggestIconKey(migratedTitle, migratedType),
      ),
      colorValue: _normalizeColorValue(
        (json['colorValue'] as int?) ?? _suggestColorValue(migratedTitle, migratedType),
      ),
    );
  }

  static int calcBestStreakPublic(Set<String> dates, [Set<String>? skippedDates]) =>
      _calcBestStreak(dates, skippedDates ?? <String>{});

  static int calcCurrentStreakPublic(
    Set<String> doneDates,
    Set<String> skippedDates, {
    DateTime? now,
  }) =>
      _calcCurrentStreak(doneDates, skippedDates, now: now);

  static int _calcBestStreak(Set<String> doneDates, Set<String> skippedDates) {
    if (doneDates.isEmpty) return 0;

    final all = <DateTime>[];
    for (final s in doneDates.followedBy(skippedDates)) {
      final d = _tryParseYmd(s);
      if (d != null) all.add(DateTime(d.year, d.month, d.day));
    }
    if (all.isEmpty) return 0;

    all.sort((a, b) => a.compareTo(b));
    final start = all.first;
    final end = all.last;

    int best = 0;
    int cur = 0;

    DateTime day = start;
    while (!day.isAfter(end)) {
      final key = _ymd(day);
      final isDone = doneDates.contains(key);
      final isSkipped = skippedDates.contains(key);

      if (isDone) {
        cur += 1;
        if (cur > best) best = cur;
      } else if (isSkipped) {
        // keep streak
      } else {
        cur = 0;
      }

      day = day.add(const Duration(days: 1));
    }

    return best;
  }

  static int _calcCurrentStreak(
    Set<String> doneDates,
    Set<String> skippedDates, {
    DateTime? now,
  }) {
    final n = now ?? DateTime.now();
    final today = DateTime(n.year, n.month, n.day);
    final todayKey = _ymd(today);

    if (!doneDates.contains(todayKey) && !skippedDates.contains(todayKey)) {
      return 0;
    }

    int streak = 0;
    int offset = 0;

    while (true) {
      final d = today.subtract(Duration(days: offset));
      final key = _ymd(d);

      if (doneDates.contains(key)) {
        streak += 1;
      } else if (skippedDates.contains(key)) {
        // keep streak
      } else {
        break;
      }

      offset += 1;
    }

    return streak;
  }

  static IconData iconDataFor(String key) {
    switch (_normalizeIconKey(key)) {
      case 'water':
        return Icons.water_drop_rounded;
      case 'fitness':
        return Icons.fitness_center_rounded;
      case 'book':
        return Icons.menu_book_rounded;
      case 'meditate':
        return Icons.self_improvement_rounded;
      case 'walk':
        return Icons.directions_walk_rounded;
      case 'code':
        return Icons.code_rounded;
      case 'study':
        return Icons.school_rounded;
      case 'journal':
        return Icons.edit_note_rounded;
      case 'clean':
        return Icons.cleaning_services_rounded;
      case 'sleep':
        return Icons.bedtime_rounded;
      case 'food':
        return Icons.restaurant_rounded;
      case 'no_smoking':
        return Icons.smoke_free_rounded;
      case 'no_alcohol':
        return Icons.no_drinks_rounded;
      case 'no_vape':
        return Icons.air_rounded;
      case 'no_sugar':
        return Icons.cake_outlined;
      case 'no_junk_food':
        return Icons.fastfood_rounded;
      case 'no_late_sleep':
        return Icons.nightlight_round_rounded;
      case 'spark':
      default:
        return Icons.auto_awesome_rounded;
    }
  }

  static String iconLabelFor(String key) {
    switch (_normalizeIconKey(key)) {
      case 'water':
        return 'Water';
      case 'fitness':
        return 'Workout';
      case 'book':
        return 'Reading';
      case 'meditate':
        return 'Meditation';
      case 'walk':
        return 'Walking';
      case 'code':
        return 'Coding';
      case 'study':
        return 'Study';
      case 'journal':
        return 'Journal';
      case 'clean':
        return 'Cleaning';
      case 'sleep':
        return 'Sleep';
      case 'food':
        return 'Nutrition';
      case 'no_smoking':
        return 'No smoking';
      case 'no_alcohol':
        return 'No alcohol';
      case 'no_vape':
        return 'No vaping';
      case 'no_sugar':
        return 'No sugar';
      case 'no_junk_food':
        return 'No junk food';
      case 'no_late_sleep':
        return 'Sleep earlier';
      case 'spark':
      default:
        return 'General';
    }
  }

  static String _normalizeType(String value) {
    return typeValues.contains(value) ? value : typeBuild;
  }

  static String _normalizeNotes(String value) {
    return value.trim();
  }

  static String _normalizeIconKey(String key) {
    return iconKeys.contains(key) ? key : defaultIconKey;
  }

  static int _normalizeColorValue(int value) {
    return colorValues.contains(value) ? value : defaultColorValue;
  }

  static String _suggestType(String title) {
    final t = title.toLowerCase();
    if (t.contains('quit') ||
        t.contains('stop') ||
        t.contains('less ') ||
        t.contains('no ') ||
        t.contains('smok') ||
        t.contains('alcohol') ||
        t.contains('drink less') ||
        t.contains('vape') ||
        t.contains('sugar') ||
        t.contains('junk food')) {
      return typeQuit;
    }
    return typeBuild;
  }

  static String _suggestIconKey(String title, String type) {
    final t = title.toLowerCase();
    if (t.contains('water') || t.contains('drink water')) return 'water';
    if (t.contains('workout') || t.contains('gym') || t.contains('run')) return 'fitness';
    if (t.contains('read') || t.contains('book')) return 'book';
    if (t.contains('meditat')) return 'meditate';
    if (t.contains('walk')) return 'walk';
    if (t.contains('code') || t.contains('program')) return 'code';
    if (t.contains('study') || t.contains('learn')) return 'study';
    if (t.contains('journal') || t.contains('write')) return 'journal';
    if (t.contains('clean')) return 'clean';
    if (t.contains('sleep')) return type == typeQuit ? 'no_late_sleep' : 'sleep';
    if (t.contains('meal') || t.contains('food') || t.contains('eat')) {
      if (t.contains('junk')) return 'no_junk_food';
      return 'food';
    }
    if (t.contains('smok')) return 'no_smoking';
    if (t.contains('alcohol') || t.contains('beer') || t.contains('wine')) return 'no_alcohol';
    if (t.contains('vape')) return 'no_vape';
    if (t.contains('sugar') || t.contains('sweet')) return 'no_sugar';
    if (type == typeQuit) return 'no_smoking';
    return defaultIconKey;
  }

  static int _suggestColorValue(String title, String type) {
    final t = title.toLowerCase();
    if (t.contains('water') || t.contains('drink')) return 0xFF0EA5E9;
    if (t.contains('workout') || t.contains('gym') || t.contains('run')) return 0xFFEF4444;
    if (t.contains('read') || t.contains('book')) return 0xFFF59E0B;
    if (t.contains('meditat')) return 0xFF14B8A6;
    if (t.contains('sleep')) return type == typeQuit ? 0xFF64748B : 0xFF4F46E5;
    if (t.contains('smok') || t.contains('vape')) return 0xFF64748B;
    if (t.contains('alcohol')) return 0xFF7C3AED;
    if (t.contains('sugar')) return 0xFFEC4899;
    if (t.contains('junk')) return 0xFFF59E0B;
    if (type == typeQuit) return 0xFF64748B;
    return defaultColorValue;
  }

  static String _ymd(DateTime d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${d.year}-${two(d.month)}-${two(d.day)}';
  }

  static DateTime? _tryParseYmd(String s) {
    final parts = s.split('-');
    if (parts.length != 3) return null;
    final y = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    final d = int.tryParse(parts[2]);
    if (y == null || m == null || d == null) return null;
    return DateTime(y, m, d);
  }
}
