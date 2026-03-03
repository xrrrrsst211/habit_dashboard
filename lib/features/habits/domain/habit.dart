class Habit {
  final String id;
  final String title;

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
  ///
  /// If this is > 0, the UI should treat it as the primary goal type.
  /// (We keep [targetDays] for existing functionality / backwards compatibility.)
  final int weeklyTarget;

  /// Archived?
  final bool archived;

  /// Reminder: minutes from 00:00 (e.g. 20:30 = 1230). null = off
  final int? reminderMinutes;

  const Habit({
    required this.id,
    required this.title,
    required this.completedDates,
    required this.skippedDates,
    required this.bestStreak,
    required this.targetDays,
    required this.weeklyTarget,
    required this.archived,
    required this.reminderMinutes,
  });

  Habit copyWith({
    String? id,
    String? title,
    Set<String>? completedDates,
    Set<String>? skippedDates,
    int? bestStreak,
    int? targetDays,
    int? weeklyTarget,
    bool? archived,
    int? reminderMinutes,
  }) {
    return Habit(
      id: id ?? this.id,
      title: title ?? this.title,
      completedDates: completedDates ?? this.completedDates,
      skippedDates: skippedDates ?? this.skippedDates,
      bestStreak: bestStreak ?? this.bestStreak,
      targetDays: targetDays ?? this.targetDays,
      weeklyTarget: weeklyTarget ?? this.weeklyTarget,
      archived: archived ?? this.archived,
      reminderMinutes: reminderMinutes ?? this.reminderMinutes,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'completedDates': completedDates.toList(),
        'skippedDates': skippedDates.toList(),
        'bestStreak': bestStreak,
        'targetDays': targetDays,
        'weeklyTarget': weeklyTarget,
        'archived': archived,
        'reminderMinutes': reminderMinutes,
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

    // ✅ Migration from older versions (streak/doneToday/lastCompletedDate)
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

    final storedBest = (json['bestStreak'] as int?);
    final best = storedBest ?? _calcBestStreak(dates, skipped);

    return Habit(
      id: (json['id'] as String?) ?? '',
      title: (json['title'] as String?) ?? '',
      completedDates: dates,
      skippedDates: skipped,
      bestStreak: best,
      targetDays: (json['targetDays'] as int?) ?? 0,
      weeklyTarget: (json['weeklyTarget'] as int?) ?? 0,
      archived: (json['archived'] as bool?) ?? false,
      reminderMinutes: (json['reminderMinutes'] as int?),
    );
  }

  // ---------- helpers ----------

// ---------- helpers ----------

/// Backwards-compatible best streak calculator.
/// If you don't care about skipped days, you can call it with only [dates].
static int calcBestStreakPublic(Set<String> dates, [Set<String>? skippedDates]) =>
    _calcBestStreak(dates, skippedDates ?? <String>{});

/// Current streak ending at "today" (includes skipped days as non-breaking).
static int calcCurrentStreakPublic(
  Set<String> doneDates,
  Set<String> skippedDates, {
  DateTime? now,
}) =>
    _calcCurrentStreak(doneDates, skippedDates, now: now);

static int _calcBestStreak(Set<String> doneDates, Set<String> skippedDates) {
  if (doneDates.isEmpty) return 0;

  // Build a sorted list from all known days (done + skipped)
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
      // Skip keeps the streak but doesn't increment it.
    } else {
      cur = 0; // missed day breaks the streak
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

  // If today isn't done or skipped, the "current streak" is 0.
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