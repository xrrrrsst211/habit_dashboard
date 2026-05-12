import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class RewardResult {
  final int xpGained;
  final int totalXp;
  final int oldLevel;
  final int newLevel;
  final String oldRank;
  final String newRank;
  final bool leveledUp;
  final bool rankChanged;
  final String reason;

  const RewardResult({
    required this.xpGained,
    required this.totalXp,
    required this.oldLevel,
    required this.newLevel,
    required this.oldRank,
    required this.newRank,
    required this.leveledUp,
    required this.rankChanged,
    required this.reason,
  });
}

class RewardProfile {
  final int totalXp;
  final int level;
  final String rank;
  final int currentLevelXp;
  final int nextLevelXp;
  final double levelProgress;
  final int xpToNextLevel;

  const RewardProfile({
    required this.totalXp,
    required this.level,
    required this.rank,
    required this.currentLevelXp,
    required this.nextLevelXp,
    required this.levelProgress,
    required this.xpToNextLevel,
  });
}

class RewardService {
  static const String _xpKey = 'rewards_total_xp_v1';
  static const String _awardedChecksKey = 'rewards_awarded_checks_v1';
  static const int baseCheckInXp = 10;
  static const int quitHabitBonusXp = 5;
  static const int streakMilestoneBonusXp = 20;
  static const int weeklyGoalBonusXp = 25;
  static const int durationGoalBonusXp = 35;

  Future<RewardProfile> getProfile() async {
    final prefs = await SharedPreferences.getInstance();
    return profileFromXp(prefs.getInt(_xpKey) ?? 0);
  }

  Future<RewardResult?> awardCompletion({
    required String habitId,
    required String dateKey,
    required bool isQuitHabit,
    required int currentStreak,
    required bool reachedWeeklyGoalNow,
    required bool reachedDurationGoalNow,
    required String habitTitle,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final checkKey = '$habitId@$dateKey';
    final awarded = _readAwardedSet(prefs);

    // A habit-date can only grant XP once. This prevents farming by tapping on/off.
    if (awarded.contains(checkKey)) return null;

    final oldXp = prefs.getInt(_xpKey) ?? 0;
    int gained = baseCheckInXp + (isQuitHabit ? quitHabitBonusXp : 0);
    final reasons = <String>[];
    reasons.add(isQuitHabit ? 'clean day' : 'habit done');

    if (_isStreakMilestone(currentStreak)) {
      gained += streakMilestoneBonusXp;
      reasons.add('$currentStreak-day streak');
    }
    if (reachedWeeklyGoalNow) {
      gained += weeklyGoalBonusXp;
      reasons.add('weekly goal');
    }
    if (reachedDurationGoalNow) {
      gained += durationGoalBonusXp;
      reasons.add('duration goal');
    }

    awarded.add(checkKey);
    final newXp = oldXp + gained;
    await prefs.setString(_awardedChecksKey, jsonEncode(awarded.toList()));
    await prefs.setInt(_xpKey, newXp);

    final oldProfile = profileFromXp(oldXp);
    final newProfile = profileFromXp(newXp);

    return RewardResult(
      xpGained: gained,
      totalXp: newXp,
      oldLevel: oldProfile.level,
      newLevel: newProfile.level,
      oldRank: oldProfile.rank,
      newRank: newProfile.rank,
      leveledUp: newProfile.level > oldProfile.level,
      rankChanged: newProfile.rank != oldProfile.rank,
      reason: '$habitTitle • ${reasons.join(', ')}',
    );
  }

  Future<List<RewardResult>> awardManyCompletions({
    required List<RewardCompletionInput> inputs,
  }) async {
    final results = <RewardResult>[];
    for (final input in inputs) {
      final result = await awardCompletion(
        habitId: input.habitId,
        dateKey: input.dateKey,
        isQuitHabit: input.isQuitHabit,
        currentStreak: input.currentStreak,
        reachedWeeklyGoalNow: input.reachedWeeklyGoalNow,
        reachedDurationGoalNow: input.reachedDurationGoalNow,
        habitTitle: input.habitTitle,
      );
      if (result != null) results.add(result);
    }
    return results;
  }

  static RewardProfile profileFromXp(int xp) {
    final safeXp = xp < 0 ? 0 : xp;
    final level = (safeXp ~/ 100) + 1;
    final currentLevelXp = (level - 1) * 100;
    final nextLevelXp = level * 100;
    final inLevel = safeXp - currentLevelXp;
    return RewardProfile(
      totalXp: safeXp,
      level: level,
      rank: rankForXp(safeXp),
      currentLevelXp: currentLevelXp,
      nextLevelXp: nextLevelXp,
      levelProgress: (inLevel / 100).clamp(0.0, 1.0),
      xpToNextLevel: nextLevelXp - safeXp,
    );
  }

  static String rankForXp(int xp) {
    if (xp >= 5000) return 'Legend';
    if (xp >= 3000) return 'Master';
    if (xp >= 1800) return 'Champion';
    if (xp >= 1000) return 'Pro';
    if (xp >= 550) return 'Builder';
    if (xp >= 250) return 'Rising Star';
    if (xp >= 100) return 'Starter';
    return 'Rookie';
  }

  static bool _isStreakMilestone(int streak) {
    const milestones = <int>{3, 7, 14, 21, 30, 60, 100, 180, 365};
    return milestones.contains(streak);
  }

  Set<String> _readAwardedSet(SharedPreferences prefs) {
    final raw = prefs.getString(_awardedChecksKey);
    if (raw == null || raw.trim().isEmpty) return <String>{};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded.whereType<String>().toSet();
      }
    } catch (_) {}
    return <String>{};
  }
}

class RewardCompletionInput {
  final String habitId;
  final String dateKey;
  final bool isQuitHabit;
  final int currentStreak;
  final bool reachedWeeklyGoalNow;
  final bool reachedDurationGoalNow;
  final String habitTitle;

  const RewardCompletionInput({
    required this.habitId,
    required this.dateKey,
    required this.isQuitHabit,
    required this.currentStreak,
    required this.reachedWeeklyGoalNow,
    required this.reachedDurationGoalNow,
    required this.habitTitle,
  });
}
