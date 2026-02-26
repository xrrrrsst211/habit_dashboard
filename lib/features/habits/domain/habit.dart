class Habit {
  final String id;
  final String title;

  /// Fact completion dates: {"yyyy-MM-dd", ...}
  final Set<String> completedDates;

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
        'bestStreak': bestStreak,
        'targetDays': targetDays,
        'weeklyTarget': weeklyTarget,
        'archived': archived,
        'reminderMinutes': reminderMinutes,
      };

  static Habit fromJson(Map<String, dynamic> json) {
    final rawDates = json['completedDates'];

    Set<String> dates = {};
    if (rawDates is List) {
      dates = rawDates.whereType<String>().toSet();
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
    final best = storedBest ?? _calcBestStreak(dates);

    return Habit(
      id: (json['id'] as String?) ?? '',
      title: (json['title'] as String?) ?? '',
      completedDates: dates,
      bestStreak: best,
      targetDays: (json['targetDays'] as int?) ?? 0,
      weeklyTarget: (json['weeklyTarget'] as int?) ?? 0,
      archived: (json['archived'] as bool?) ?? false,
      reminderMinutes: (json['reminderMinutes'] as int?),
    );
  }

  // ---------- helpers ----------

  static int calcBestStreakPublic(Set<String> dates) => _calcBestStreak(dates);

  static int _calcBestStreak(Set<String> dates) {
    if (dates.isEmpty) return 0;

    // Convert to DateTime, sort.
    final parsed = <DateTime>[];
    for (final s in dates) {
      final d = _tryParseYmd(s);
      if (d != null) parsed.add(DateTime(d.year, d.month, d.day));
    }
    if (parsed.isEmpty) return 0;

    parsed.sort((a, b) => a.compareTo(b));

    int best = 1;
    int cur = 1;

    for (int i = 1; i < parsed.length; i++) {
      final prev = parsed[i - 1];
      final now = parsed[i];

      final diff = now.difference(prev).inDays;
      if (diff == 1) {
        cur++;
      } else if (diff == 0) {
        // Same day duplicates shouldn't happen (Set), but just in case.
        continue;
      } else {
        if (cur > best) best = cur;
        cur = 1;
      }
    }

    if (cur > best) best = cur;
    return best;
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