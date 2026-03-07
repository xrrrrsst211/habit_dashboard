import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:habit_dashboard/app/app.dart';
import 'package:habit_dashboard/core/constants/app_strings.dart';
import 'package:habit_dashboard/core/theme/app_styles.dart';
import 'package:habit_dashboard/core/widgets/app_scaffold.dart';
import 'package:habit_dashboard/core/widgets/empty_state.dart';
import 'package:habit_dashboard/features/habits/data/habit_repository.dart';
import 'package:habit_dashboard/features/habits/domain/habit.dart';
import 'package:habit_dashboard/features/habits/presentation/add_habit/add_habit_screen.dart';
import 'package:habit_dashboard/features/habits/presentation/habit_detail/habit_detail_screen.dart';
import 'package:habit_dashboard/features/habits/presentation/stats/stats_screen.dart';

import 'widgets/daily_progress_card.dart';
import 'widgets/habit_tile.dart';
import 'widgets/today_header.dart';
import 'widgets/weekly_checkin_card.dart';

enum _HomeMenuAction {
  markAllDone,
  resetToday,
  toggleArchived,
  toggleTheme,

  // ✅ Added
  exportBackup,
  importBackup,
  exportBackupFile,
  importBackupFile,
}

enum _HabitFilter { all, active, completed, build, quit }

enum _HabitSort { manual, streak, name, todayStatus }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final HabitRepository _repo = HabitRepository();
  late final Future<void> _initFuture = _repo.init();

  _HabitFilter _filter = _HabitFilter.all;
  _HabitSort _sort = _HabitSort.manual;
  bool _showArchived = false;
  bool _expandArchivedSection = false;

  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';

  List<Habit> get _habits => _repo.getHabits();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  String _todayKey() {
    final now = DateTime.now();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${now.year}-${two(now.month)}-${two(now.day)}';
  }

  String _keyFromDate(DateTime d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${d.year}-${two(d.month)}-${two(d.day)}';
  }

  int _calcStreak(Habit habit) {
    return Habit.calcCurrentStreakPublic(habit.completedDates, habit.skippedDates);
  }


  int _countThisWeek(Set<String> dates) {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - DateTime.monday));

    int count = 0;
    for (int i = 0; i < 7; i++) {
      final d = start.add(Duration(days: i));
      if (dates.contains(_keyFromDate(d))) count++;
    }
    return count;
  }


  static const List<int> _achievementMilestones = <int>[3, 7, 14, 30, 60, 100];

  int? _newlyUnlockedMilestone({
    required int before,
    required int after,
  }) {
    for (final days in _achievementMilestones) {
      if (before < days && after >= days) return days;
    }
    return null;
  }

  Future<void> _showAchievementUnlockedDialog(Habit habit, int days) async {
    if (!mounted) return;

    final cs = Theme.of(context).colorScheme;
    final title = habit.isQuit ? 'Clean streak unlocked!' : 'Achievement unlocked!';
    final subtitle = habit.isQuit
        ? '${habit.title} • $days clean days in a row'
        : '${habit.title} • $days day streak';

    HapticFeedback.heavyImpact();

    await showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Achievement unlocked',
      transitionDuration: const Duration(milliseconds: 380),
      pageBuilder: (context, a1, a2) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.84, end: 1.0),
              duration: const Duration(milliseconds: 380),
              curve: Curves.easeOutBack,
              builder: (context, scale, child) {
                return Transform.scale(scale: scale, child: child);
              },
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: cs.surface,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      blurRadius: 28,
                      offset: const Offset(0, 10),
                      color: Colors.black.withOpacity(0.18),
                    ),
                  ],
                  border: Border.all(
                    color: habit.color.withOpacity(0.22),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 78,
                      height: 78,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: habit.color.withOpacity(0.12),
                      ),
                      alignment: Alignment.center,
                      child: Stack(
                        clipBehavior: Clip.none,
                        alignment: Alignment.center,
                        children: [
                          Icon(
                            habit.iconData,
                            size: 34,
                            color: habit.color,
                          ),
                          const Positioned(
                            right: -4,
                            top: -8,
                            child: Text('✨', style: TextStyle(fontSize: 22)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$days-day milestone',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: habit.color,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      subtitle,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: context.secondaryTextStyle.color,
                          ),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.emoji_events_rounded),
                        label: const Text('Nice'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _showBulkAchievementDialog(List<Map<String, dynamic>> unlocked) async {
    if (!mounted || unlocked.isEmpty) return;

    final cs = Theme.of(context).colorScheme;
    HapticFeedback.heavyImpact();

    await showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Achievements unlocked',
      transitionDuration: const Duration(milliseconds: 380),
      pageBuilder: (context, a1, a2) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.86, end: 1.0),
              duration: const Duration(milliseconds: 380),
              curve: Curves.easeOutBack,
              builder: (context, scale, child) => Transform.scale(scale: scale, child: child),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 22),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: cs.surface,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      blurRadius: 28,
                      offset: const Offset(0, 10),
                      color: Colors.black.withOpacity(0.18),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🏆', style: TextStyle(fontSize: 52)),
                    const SizedBox(height: 10),
                    Text(
                      'Achievements unlocked!',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${unlocked.length} milestone${unlocked.length == 1 ? '' : 's'} reached today',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: context.secondaryTextStyle.color,
                          ),
                    ),
                    const SizedBox(height: 16),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 280),
                      child: SingleChildScrollView(
                        child: Column(
                          children: unlocked.map((entry) {
                            final habit = entry['habit'] as Habit;
                            final days = entry['days'] as int;
                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(18),
                                color: habit.color.withOpacity(0.08),
                                border: Border.all(color: habit.color.withOpacity(0.18)),
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 18,
                                    backgroundColor: habit.color.withOpacity(0.18),
                                    child: Icon(habit.iconData, color: habit.color, size: 18),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          habit.title,
                                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                                fontWeight: FontWeight.w800,
                                              ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          habit.isQuit ? '$days clean days in a row' : '$days day streak',
                                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                color: context.secondaryTextStyle.color,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(Icons.emoji_events_rounded, color: habit.color),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Awesome'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  DateTime _startOfWeek(DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    return today.subtract(Duration(days: today.weekday - DateTime.monday));
  }

  /// Returns a 7-item list (Mon..Sun) where each value is 0..1
  /// representing doneCount/totalHabits for that day.
  List<double> _weekDayRatios(List<Habit> habits) {
    final total = habits.length;
    if (total == 0) return List<double>.filled(7, 0);

    final start = _startOfWeek(DateTime.now());
    return List<double>.generate(7, (i) {
      final d = start.add(Duration(days: i));
      final key = _keyFromDate(d);
      final doneCount = habits.where((h) => h.completedDates.contains(key)).length;
      return (doneCount / total).clamp(0.0, 1.0);
    });
  }

  /// Counts how many days this week have at least one completion.
  int _weekCheckInDays(List<Habit> habits) {
    if (habits.isEmpty) return 0;
    final start = _startOfWeek(DateTime.now());

    int days = 0;
    for (int i = 0; i < 7; i++) {
      final d = start.add(Duration(days: i));
      final key = _keyFromDate(d);
      final anyDone = habits.any((h) => h.completedDates.contains(key));
      if (anyDone) days++;
    }
    return days;
  }


  String _sortLabel(_HabitSort value) {
    switch (value) {
      case _HabitSort.manual:
        return 'Manual order';
      case _HabitSort.streak:
        return 'Highest streak';
      case _HabitSort.name:
        return 'Name';
      case _HabitSort.todayStatus:
        return 'Today status';
    }
  }

  int _todayStatusRank(Habit habit, String todayKey) {
    if (habit.completedDates.contains(todayKey)) return 0;
    if (habit.skippedDates.contains(todayKey)) return 1;
    return 2;
  }

  int _compareHabits(Habit a, Habit b, String todayKey) {
    switch (_sort) {
      case _HabitSort.manual:
        return 0;
      case _HabitSort.streak:
        final streakCompare = _calcStreak(b).compareTo(_calcStreak(a));
        if (streakCompare != 0) return streakCompare;
        return a.title.toLowerCase().compareTo(b.title.toLowerCase());
      case _HabitSort.name:
        return a.title.toLowerCase().compareTo(b.title.toLowerCase());
      case _HabitSort.todayStatus:
        final statusCompare = _todayStatusRank(a, todayKey).compareTo(_todayStatusRank(b, todayKey));
        if (statusCompare != 0) return statusCompare;
        final streakCompare = _calcStreak(b).compareTo(_calcStreak(a));
        if (streakCompare != 0) return streakCompare;
        return a.title.toLowerCase().compareTo(b.title.toLowerCase());
    }
  }


  List<Habit> _applyFilterSortAndSearch(List<Habit> source, String todayKey) {
    final filtered = source.where((h) {
      final doneToday = h.completedDates.contains(todayKey);
      final passFilter = switch (_filter) {
        _HabitFilter.all => true,
        _HabitFilter.active => !doneToday,
        _HabitFilter.completed => doneToday,
        _HabitFilter.build => h.isBuild,
        _HabitFilter.quit => h.isQuit,
      };
      if (!passFilter) return false;
      if (_query.isEmpty) return true;
      return h.title.toLowerCase().contains(_query);
    }).toList();

    if (_sort != _HabitSort.manual) {
      filtered.sort((a, b) => _compareHabits(a, b, todayKey));
    }

    return filtered;
  }

  void _showAppSnackBar(
    String message, {
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
  }) {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        duration: duration,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        action: action,
      ),
    );
  }

  Widget _overviewChip({
    required IconData icon,
    required String label,
    required String value,
  }) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outline.withOpacity(0.14)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: context.secondaryTextStyle.color),
          const SizedBox(width: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: context.secondaryTextStyle.color,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
        ],
      ),
    );
  }

  Widget _homeOverviewRow({
    required List<Habit> activeHabits,
    required List<Habit> archivedHabits,
    required int completedToday,
  }) {
    final buildCount = activeHabits.where((h) => h.isBuild).length;
    final quitCount = activeHabits.where((h) => h.isQuit).length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _overviewChip(
              icon: Icons.check_circle_outline_rounded,
              label: 'Today',
              value: '$completedToday/${activeHabits.length}',
            ),
            const SizedBox(width: 8),
            _overviewChip(
              icon: Icons.trending_up_rounded,
              label: 'Build',
              value: '$buildCount',
            ),
            const SizedBox(width: 8),
            _overviewChip(
              icon: Icons.shield_moon_outlined,
              label: 'Quit',
              value: '$quitCount',
            ),
            const SizedBox(width: 8),
            _overviewChip(
              icon: Icons.archive_outlined,
              label: 'Archived',
              value: '${archivedHabits.length}',
            ),
          ],
        ),
      ),
    );
  }


  int _countDoneInLastDays(Habit habit, int days) {
    final today = DateTime.now();
    int count = 0;
    for (int i = 0; i < days; i++) {
      final d = DateTime(today.year, today.month, today.day)
          .subtract(Duration(days: i));
      if (habit.completedDates.contains(_keyFromDate(d))) count++;
    }
    return count;
  }

  int _countSkippedInLastDays(Habit habit, int days) {
    final today = DateTime.now();
    int count = 0;
    for (int i = 0; i < days; i++) {
      final d = DateTime(today.year, today.month, today.day)
          .subtract(Duration(days: i));
      if (habit.skippedDates.contains(_keyFromDate(d))) count++;
    }
    return count;
  }

  double _completionRateLastDays(Habit habit, int days) {
    final activeDays = (days - _countSkippedInLastDays(habit, days)).clamp(0, days);
    if (activeDays == 0) return 0;
    return _countDoneInLastDays(habit, days) / activeDays;
  }

  Widget _smartCoachCard({
    required List<Habit> activeHabits,
    required String todayKey,
  }) {
    final focusHabits = activeHabits.where((h) {
      if (h.completedDates.contains(todayKey)) return false;
      if (h.skippedDates.contains(todayKey)) return false;
      return true;
    }).toList()
      ..sort((a, b) {
        final streakCmp = _calcStreak(b).compareTo(_calcStreak(a));
        if (streakCmp != 0) return streakCmp;
        return _completionRateLastDays(b, 7).compareTo(_completionRateLastDays(a, 7));
      });

    final protectHabits = focusHabits.where((h) => _calcStreak(h) >= 3).toList();

    final weeklyPressure = activeHabits.where((h) {
      if (h.weeklyTarget <= 0) return false;
      final done = _countThisWeek(h.completedDates);
      final remainingDays = 7 - DateTime.now().weekday;
      final needed = h.weeklyTarget - done;
      return needed > 0 && needed >= remainingDays;
    }).toList();

    final momentum = [...activeHabits]
      ..sort((a, b) {
        final rateCmp = _completionRateLastDays(b, 14).compareTo(_completionRateLastDays(a, 14));
        if (rateCmp != 0) return rateCmp;
        return _calcStreak(b).compareTo(_calcStreak(a));
      });

    final leader = momentum.isEmpty ? null : momentum.first;
    final cs = Theme.of(context).colorScheme;

    Widget pill({required IconData icon, required String text, Color? color}) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: (color ?? cs.primary).withOpacity(0.08),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: (color ?? cs.primary).withOpacity(0.16)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color ?? cs.primary),
            const SizedBox(width: 6),
            Text(
              text,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              cs.primary.withOpacity(0.10),
              cs.secondary.withOpacity(0.06),
              cs.surface,
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: cs.outline.withOpacity(0.16)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.insights_rounded),
                const SizedBox(width: 8),
                Text(
                  'Smart focus',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              leader == null
                  ? 'Start with one small win today.'
                  : '${leader.title} has the best momentum right now.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: context.secondaryTextStyle.color,
                  ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (leader != null)
                  pill(
                    icon: Icons.local_fire_department_outlined,
                    text: '${leader.title} • ${_calcStreak(leader)}d streak',
                    color: leader.color,
                  ),
                if (protectHabits.isNotEmpty)
                  pill(
                    icon: Icons.shield_outlined,
                    text: '${protectHabits.length} streak${protectHabits.length == 1 ? '' : 's'} need protecting',
                  ),
                if (weeklyPressure.isNotEmpty)
                  pill(
                    icon: Icons.calendar_view_week_rounded,
                    text: '${weeklyPressure.length} weekly goal${weeklyPressure.length == 1 ? '' : 's'} under pressure',
                    color: cs.secondary,
                  ),
              ],
            ),
            const SizedBox(height: 14),
            if (focusHabits.isEmpty)
              Text(
                'Everything planned for today is either done or intentionally skipped. Nice.',
                style: Theme.of(context).textTheme.bodyMedium,
              )
            else
              Column(
                children: focusHabits.take(3).map((habit) {
                  final streak = _calcStreak(habit);
                  final rate7 = (_completionRateLastDays(habit, 7) * 100).round();
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: cs.surface,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: cs.outline.withOpacity(0.12)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: habit.color.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(habit.iconData, color: habit.color, size: 20),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                habit.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                streak > 0
                                    ? '${habit.isQuit ? 'Clean' : 'Current'} streak: $streak days • 7d ${rate7}%'
                                    : 'Good pick for today • 7d ${rate7}%',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: context.secondaryTextStyle.color,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        FilledButton.tonal(
                          onPressed: () => _toggle(habit),
                          child: const Text('Done'),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _quickActionsRow() {
    Widget action({
      required IconData icon,
      required String label,
      required VoidCallback onTap,
    }) {
      return Expanded(
        child: OutlinedButton.icon(
          onPressed: onTap,
          icon: Icon(icon, size: 18),
          label: Text(label),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          action(
            icon: Icons.done_all_rounded,
            label: 'Mark all',
            onTap: () => _onMenuSelected(_HomeMenuAction.markAllDone),
          ),
          const SizedBox(width: 8),
          action(
            icon: Icons.restart_alt_rounded,
            label: 'Reset today',
            onTap: () => _onMenuSelected(_HomeMenuAction.resetToday),
          ),
          const SizedBox(width: 8),
          action(
            icon: Icons.file_download_outlined,
            label: 'Backup',
            onTap: () => _onMenuSelected(_HomeMenuAction.exportBackupFile),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({
    required BuildContext context,
    required String title,
    required String subtitle,
    required bool expanded,
    required ValueChanged<bool> onExpanded,
  }) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: cs.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => onExpanded(!expanded),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: cs.outline.withOpacity(0.18)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: context.secondaryTextStyle.color,
                          ),
                    ),
                  ],
                ),
              ),
              Icon(expanded ? Icons.expand_less : Icons.expand_more),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildStaticSectionHeader({
    required BuildContext context,
    required String title,
    required String subtitle,
  }) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cs.outline.withOpacity(0.18)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: context.secondaryTextStyle.color,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _toggle(Habit habit) async {
    final beforeStreak = _calcStreak(habit);
    final beforeReachedDuration =
        habit.targetDays > 0 && beforeStreak >= habit.targetDays;
    final beforeReachedWeekly = habit.weeklyTarget > 0 &&
        _countThisWeek(habit.completedDates) >= habit.weeklyTarget;

    await _repo.toggleHabit(habit.id);

    final updated = _repo.getHabits().firstWhere(
      (h) => h.id == habit.id,
      orElse: () => habit,
    );

    final afterStreak = _calcStreak(updated);
    final afterReachedDuration =
        updated.targetDays > 0 && afterStreak >= updated.targetDays;
    final afterReachedWeekly = updated.weeklyTarget > 0 &&
        _countThisWeek(updated.completedDates) >= updated.weeklyTarget;
    final unlockedMilestone = _newlyUnlockedMilestone(
      before: beforeStreak,
      after: afterStreak,
    );

    HapticFeedback.lightImpact();

    if (!mounted) return;
    setState(() {});

    if ((!beforeReachedDuration && afterReachedDuration) ||
        (!beforeReachedWeekly && afterReachedWeekly)) {
      _showGoalReachedDialog(updated.title);
      return;
    }

    if (unlockedMilestone != null) {
      await _showAchievementUnlockedDialog(updated, unlockedMilestone);
    }
  }

  Future<void> _toggleSkipToday(Habit habit) async {
    await _repo.toggleSkipToday(habit.id);
    HapticFeedback.selectionClick();
    if (!mounted) return;
    setState(() {});
  }

  void _showGoalReachedDialog(String title) {
    HapticFeedback.heavyImpact();

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Goal reached',
      transitionDuration: const Duration(milliseconds: 420),
      pageBuilder: (context, a1, a2) {
        final cs = Theme.of(context).colorScheme;

        return Center(
          child: Material(
            color: Colors.transparent,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.75, end: 1.0),
              duration: const Duration(milliseconds: 420),
              curve: Curves.elasticOut,
              builder: (context, scale, child) {
                return Transform.scale(scale: scale, child: child);
              },
              child: Container(
                padding: const EdgeInsets.all(22),
                margin: const EdgeInsets.symmetric(horizontal: 28),
                decoration: BoxDecoration(
                  color: cs.surface,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      blurRadius: 24,
                      // Keep compatibility across Flutter versions.
                      color: Colors.black.withOpacity(0.18),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🎉', style: TextStyle(fontSize: 60)),
                    const SizedBox(height: 10),
                    Text(
                      'Goal reached!',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: context.secondaryTextStyle.color,
                          ),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Nice 😈'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _openAddHabit() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(builder: (_) => const AddHabitScreen()),
    );

    if (result == null) return;

    final title = (result['title'] as String?)?.trim() ?? '';
    final type = (result['type'] as String?) ?? Habit.typeBuild;
    final targetDays = (result['targetDays'] as int?) ?? 0;
    final weeklyTarget = (result['weeklyTarget'] as int?) ?? 0;
    final reminderMinutes = (result['reminderMinutes'] as int?);
    final notes = (result['notes'] as String?) ?? '';
    final iconKey = (result['iconKey'] as String?) ?? Habit.defaultIconKey;
    final colorValue = (result['colorValue'] as int?) ?? Habit.defaultColorValue;

    if (title.isEmpty) return;

    await _repo.addHabit(
      title,
      type,
      targetDays,
      weeklyTarget,
      reminderMinutes,
      notes,
      iconKey,
      colorValue,
    );
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _openEditHabit(Habit habit) async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => AddHabitScreen(
          initialTitle: habit.title,
          initialType: habit.type,
          initialTargetDays: habit.targetDays,
          initialWeeklyTarget: habit.weeklyTarget,
          initialReminderMinutes: habit.reminderMinutes,
          initialNotes: habit.notes,
          initialIconKey: habit.iconKey,
          initialColorValue: habit.colorValue,
        ),
      ),
    );

    if (result == null) return;

    final newTitle = (result['title'] as String?)?.trim() ?? '';
    final newType = (result['type'] as String?) ?? habit.type;
    final newTargetDays = (result['targetDays'] as int?) ?? habit.targetDays;
    final newWeeklyTarget =
        (result['weeklyTarget'] as int?) ?? habit.weeklyTarget;
    final newReminder = (result['reminderMinutes'] as int?);
    final newNotes = (result['notes'] as String?) ?? habit.notes;
    final newIconKey = (result['iconKey'] as String?) ?? habit.iconKey;
    final newColorValue = (result['colorValue'] as int?) ?? habit.colorValue;

    if (newTitle.isNotEmpty && newTitle != habit.title) {
      await _repo.renameHabit(habit.id, newTitle);
    }
    if (newType != habit.type) {
      await _repo.setType(habit.id, newType);
    }
    if (newTargetDays != habit.targetDays) {
      await _repo.setTargetDays(habit.id, newTargetDays);
    }
    if (newWeeklyTarget != habit.weeklyTarget) {
      await _repo.setWeeklyTarget(habit.id, newWeeklyTarget);
    }
    if (newReminder != habit.reminderMinutes) {
      await _repo.setReminderMinutes(habit.id, newReminder);
    }
    if (newNotes.trim() != habit.notes.trim()) {
      await _repo.setNotes(habit.id, newNotes);
    }
    if (newIconKey != habit.iconKey || newColorValue != habit.colorValue) {
      await _repo.setAppearance(habit.id, newIconKey, newColorValue);
    }

    if (!mounted) return;
    setState(() {});
  }

  void _openDetails(Habit habit) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => HabitDetailScreen(repo: _repo, habit: habit),
      ),
    ).then((_) {
      if (!mounted) return;
      setState(() {});
    });
  }

  Future<void> _confirmAndRemoveWithUndo(Habit habit) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete habit?'),
        content: Text('Delete “${habit.title}”?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    final currentList = List<Habit>.from(_repo.getHabits());
    final index = currentList.indexWhere((h) => h.id == habit.id);

    await _repo.removeHabit(habit.id);
    if (!mounted) return;
    setState(() {});

    _showAppSnackBar(
      'Deleted “${habit.title}”',
      duration: const Duration(seconds: 4),
      action: SnackBarAction(
        label: 'UNDO',
        onPressed: () async {
          await _repo.insertHabitAt(index < 0 ? 0 : index, habit);
          if (!mounted) return;
          setState(() {});
        },
      ),
    );
  }

  // =========================
  // ✅ Backup/Restore (Clipboard)
  // =========================

  String _backupFileName() {
    final now = DateTime.now();
    String two(int n) => n.toString().padLeft(2, '0');
    return 'habit_dashboard_backup_${now.year}${two(now.month)}${two(now.day)}_${two(now.hour)}${two(now.minute)}.json';
  }

  Future<void> _exportBackupToClipboard() async {
    final json = _repo.exportHabitsJson(pretty: true);
    await Clipboard.setData(ClipboardData(text: json));

    if (!mounted) return;
    _showAppSnackBar('Backup copied to clipboard ✅');
  }

  Future<void> _exportBackupToFile() async {
    try {
      final json = _repo.exportBackupBundleJson(pretty: true);
      final bytes = Uint8List.fromList(utf8.encode(json));

      final saved = await FilePicker.platform.saveFile(
        dialogTitle: 'Save backup JSON',
        fileName: _backupFileName(),
        type: FileType.custom,
        allowedExtensions: const ['json'],
        bytes: bytes,
      );

      if (!mounted || saved == null) return;
      _showAppSnackBar('Backup file saved ✅');
    } catch (e) {
      if (!mounted) return;
      _showAppSnackBar(
        'Could not save backup file: $e',
        duration: const Duration(seconds: 4),
      );
    }
  }

  Future<void> _restoreBackupFromFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['json'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) return;

      final file = result.files.single;
      final raw = utf8.decode(file.bytes ?? const <int>[]).trim();

      if (raw.isEmpty) {
        if (!mounted) return;
        _showAppSnackBar('Selected file is empty or could not be read.');
        return;
      }

      final ok = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Import backup file?'),
          content: Text(
            'This will REPLACE your current habits with the selected JSON backup.\n'
            'Current data will be overwritten.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Import'),
            ),
          ],
        ),
      );

      if (ok != true) return;

      await _repo.importHabitsJson(raw);
      if (!mounted) return;
      setState(() {});

      _showAppSnackBar('Backup imported from ${file.name} ✅');
    } catch (e) {
      if (!mounted) return;
      _showAppSnackBar('Import failed: $e', duration: const Duration(seconds: 4));
    }
  }

  Future<void> _restoreBackupFromClipboard() async {
    final clip = await Clipboard.getData('text/plain');
    final initial = (clip?.text ?? '').trim();

    if (!mounted) return;

    final controller = TextEditingController(text: initial);

    Future<void> doImport() async {
      final raw = controller.text.trim();

      if (raw.isEmpty) {
        _showAppSnackBar('Clipboard is empty. Copy your backup JSON first.');
        return;
      }

      final ok = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Restore backup?'),
          content: const Text(
            'This will REPLACE your current habits with the backup data.\n'
            'You can’t undo this. Continue?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Restore'),
            ),
          ],
        ),
      );

      if (ok != true) return;

      try {
        await _repo.importHabitsJson(raw);

        if (!mounted) return;
        Navigator.pop(context); // close editor
        setState(() {});

        _showAppSnackBar('Backup restored ✅');
      } catch (e) {
        if (!mounted) return;
        _showAppSnackBar('Restore failed: $e', duration: const Duration(seconds: 4));
      }
    }

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restore from clipboard'),
        content: SizedBox(
          width: 560,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Paste your backup JSON below (auto-filled from clipboard if available).'),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                maxLines: 10,
                decoration: const InputDecoration(
                  hintText: 'Paste backup JSON here…',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          FilledButton(
            onPressed: doImport,
            child: const Text('Restore'),
          ),
        ],
      ),
    );
  }

  // =========================

  Future<void> _onMenuSelected(_HomeMenuAction action) async {
    switch (action) {
      case _HomeMenuAction.markAllDone:
        final beforeHabits = List<Habit>.from(_repo.getHabits());
        final beforeById = <String, Habit>{
          for (final habit in beforeHabits) habit.id: habit,
        };
        await _repo.markAllDoneToday();
        HapticFeedback.lightImpact();
        if (!mounted) return;
        setState(() {});

        final unlocked = <Map<String, dynamic>>[];
        for (final habit in _repo.getHabits()) {
          final before = beforeById[habit.id];
          if (before == null) continue;
          final days = _newlyUnlockedMilestone(
            before: _calcStreak(before),
            after: _calcStreak(habit),
          );
          if (days != null) {
            unlocked.add({'habit': habit, 'days': days});
          }
        }
        if (unlocked.isNotEmpty) {
          await _showBulkAchievementDialog(unlocked);
        }
        break;
      case _HomeMenuAction.resetToday:
        await _repo.resetToday();
        HapticFeedback.lightImpact();
        if (!mounted) return;
        setState(() {});
        break;
      case _HomeMenuAction.toggleArchived:
        HapticFeedback.selectionClick();
        setState(() { _showArchived = !_showArchived; if (_showArchived) _expandArchivedSection = true; });
        break;
      case _HomeMenuAction.toggleTheme:
        HapticFeedback.selectionClick();
        MyApp.of(context)?.toggleDarkMode();
        break;

      // ✅ Added
      case _HomeMenuAction.exportBackup:
        HapticFeedback.selectionClick();
        await _exportBackupToClipboard();
        break;
      case _HomeMenuAction.importBackup:
        HapticFeedback.selectionClick();
        await _restoreBackupFromClipboard();
        break;
      case _HomeMenuAction.exportBackupFile:
        HapticFeedback.selectionClick();
        await _exportBackupToFile();
        break;
      case _HomeMenuAction.importBackupFile:
        HapticFeedback.selectionClick();
        await _restoreBackupFromFile();
        break;
    }
  }

  void _openStats() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => StatsScreen(habits: List<Habit>.from(_habits))),
    );
  }


  Widget _filterChips() {
    Widget chip(String label, _HabitFilter value) {
      final selected = _filter == value;
      return ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => setState(() => _filter = value),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          chip('All', _HabitFilter.all),
          chip('Active', _HabitFilter.active),
          chip('Completed', _HabitFilter.completed),
          chip('Build', _HabitFilter.build),
          chip('Quit', _HabitFilter.quit),
        ],
      ),
    );
  }

  Widget _sortBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
      child: Row(
        children: [
          Icon(Icons.sort_rounded, size: 18, color: context.secondaryTextStyle.color),
          const SizedBox(width: 8),
          Text(
            'Sort',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: context.secondaryTextStyle.color,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Wrap(
                spacing: 8,
                children: _HabitSort.values.map((value) {
                  return ChoiceChip(
                    label: Text(_sortLabel(value)),
                    selected: _sort == value,
                    onSelected: (_) => setState(() => _sort = value),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _searchBar() {

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      child: TextField(
        controller: _searchCtrl,
        onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
        decoration: InputDecoration(
          hintText: 'Search habits...',
          prefixIcon: const Icon(Icons.search),
          filled: true,
          suffixIcon: _query.isEmpty
              ? null
              : IconButton(
                  tooltip: 'Clear',
                  onPressed: () {
                    _searchCtrl.clear();
                    setState(() => _query = '');
                  },
                  icon: const Icon(Icons.close),
                ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Theme.of(context).colorScheme.outline.withOpacity(0.14)),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    return FutureBuilder<void>(
      future: _initFuture,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (snap.hasError) {
          return Scaffold(body: Center(child: Text('Error: ${snap.error}')));
        }

        final todayKey = _todayKey();
        final isDark = Theme.of(context).brightness == Brightness.dark;

        final activeHabits = _habits.where((h) => !h.archived).toList();
        final archivedHabits = _habits.where((h) => h.archived).toList();

        final visible = _applyFilterSortAndSearch(activeHabits, todayKey);
        final archivedVisible = _applyFilterSortAndSearch(archivedHabits, todayKey);

        final visibleIds = visible.map((h) => h.id).toList();
        final archivedVisibleIds = archivedVisible.map((h) => h.id).toList();
        final completed = activeHabits.where((h) => h.completedDates.contains(todayKey)).length;

        final headerRow = Row(
          children: [
            const Expanded(child: TodayHeader()),
            IconButton(
              tooltip: 'Stats',
              onPressed: _openStats,
              icon: const Icon(Icons.bar_chart_rounded),
            ),
            PopupMenuButton<_HomeMenuAction>(
              tooltip: 'Menu',
              onSelected: _onMenuSelected,
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: _HomeMenuAction.markAllDone,
                  child: Text('Mark all done (today)'),
                ),
                const PopupMenuItem(
                  value: _HomeMenuAction.resetToday,
                  child: Text('Reset today'),
                ),
                PopupMenuItem(
                  value: _HomeMenuAction.toggleArchived,
                  child: Text(_showArchived ? 'Collapse archived habits' : 'Expand archived habits'),
                ),
                PopupMenuItem(
                  value: _HomeMenuAction.toggleTheme,
                  child: Text(isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode'),
                ),

                // ✅ Added
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: _HomeMenuAction.exportBackup,
                  child: Text('Backup: Copy to clipboard'),
                ),
                const PopupMenuItem(
                  value: _HomeMenuAction.importBackup,
                  child: Text('Restore: Paste from clipboard'),
                ),
                const PopupMenuItem(
                  value: _HomeMenuAction.exportBackupFile,
                  child: Text('Backup: Save JSON file'),
                ),
                const PopupMenuItem(
                  value: _HomeMenuAction.importBackupFile,
                  child: Text('Restore: Import JSON file'),
                ),
              ],
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                child: Icon(Icons.more_vert),
              ),
            ),
          ],
        );

        return AppScaffold(
          title: AppStrings.today,
          floatingActionButton: FloatingActionButton(
            onPressed: _openAddHabit,
            child: const Icon(Icons.add),
          ),
          body: activeHabits.isEmpty && archivedHabits.isEmpty
              ? const EmptyState(
                  title: AppStrings.emptyTitle,
                  subtitle: AppStrings.emptySubtitle,
                )
              : Column(
                  children: [
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: headerRow,
                    ),
                    const SizedBox(height: 10),
                    _homeOverviewRow(
                      activeHabits: activeHabits,
                      archivedHabits: archivedHabits,
                      completedToday: completed,
                    ),
                    const SizedBox(height: 10),
                    _quickActionsRow(),
                    const SizedBox(height: 10),
                    _smartCoachCard(
                      activeHabits: activeHabits,
                      todayKey: todayKey,
                    ),
                    const SizedBox(height: 10),
                    _searchBar(),
                    _filterChips(),
                    const SizedBox(height: 10),
                    _sortBar(),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: DailyProgressCard(completed: completed, total: activeHabits.length),
                    ),
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: WeeklyCheckInCard(
                        dayRatios: _weekDayRatios(activeHabits),
                        checkInDays: _weekCheckInDays(activeHabits),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 120),
                        children: [
                          _buildStaticSectionHeader(
                            context: context,
                            title: 'Active habits',
                            subtitle: '${visible.length} shown • ${activeHabits.length} total',
                          ),
                          const SizedBox(height: 12),
                          if (visible.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 24),
                              child: Center(
                                child: Text(
                                  _query.isEmpty ? 'Nothing here 👀' : 'No matches for “$_query”',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(color: context.secondaryTextStyle.color),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            )
                          else if (_sort == _HabitSort.manual)
                            ReorderableListView.builder(
                              key: const ValueKey('active_manual_reorderable'),
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: visible.length,
                              onReorder: (oldIndex, newIndex) async {
                                await _repo.reorderByIds(oldIndex, newIndex, visibleIds);
                                HapticFeedback.mediumImpact();
                                if (!mounted) return;
                                setState(() {});
                              },
                              itemBuilder: (context, index) {
                                final h = visible[index];
                                return Container(
                                  key: ValueKey('habit_${h.id}'),
                                  margin: const EdgeInsets.only(bottom: 10),
                                  child: Row(
                                    children: [
                                      ReorderableDragStartListener(
                                        index: index,
                                        child: const Padding(
                                          padding: EdgeInsets.only(right: 8),
                                          child: Icon(Icons.drag_handle),
                                        ),
                                      ),
                                      Expanded(
                                        child: HabitTile(
                                          habit: h,
                                          onToggle: () => _toggle(h),
                                          onToggleSkipToday: () => _toggleSkipToday(h),
                                          onOpenDetails: () => _openDetails(h),
                                          onEdit: () => _openEditHabit(h),
                                          onDelete: () => _confirmAndRemoveWithUndo(h),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            )
                          else ...visible.map((h) => Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: HabitTile(
                                  key: ValueKey('sorted_habit_${h.id}'),
                                  habit: h,
                                  onToggle: () => _toggle(h),
                                  onToggleSkipToday: () => _toggleSkipToday(h),
                                  onOpenDetails: () => _openDetails(h),
                                  onEdit: () => _openEditHabit(h),
                                  onDelete: () => _confirmAndRemoveWithUndo(h),
                                ),
                              )),
                          if (archivedHabits.isNotEmpty || _showArchived) ...[
                            const SizedBox(height: 8),
                            _buildSectionHeader(
                              context: context,
                              title: 'Archived habits',
                              subtitle: archivedHabits.isEmpty
                                  ? 'No archived habits yet'
                                  : '${archivedVisible.length} shown • ${archivedHabits.length} archived',
                              expanded: _expandArchivedSection,
                              onExpanded: (value) => setState(() {
                                _showArchived = true;
                                _expandArchivedSection = value;
                              }),
                            ),
                            AnimatedCrossFade(
                              firstChild: const SizedBox.shrink(),
                              secondChild: Padding(
                                padding: const EdgeInsets.only(top: 12),
                                child: archivedVisible.isEmpty
                                    ? Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 16),
                                        child: Center(
                                          child: Text(
                                            _query.isEmpty
                                                ? 'Archived habits will appear here.'
                                                : 'No archived matches for “$_query”',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyMedium
                                                ?.copyWith(color: context.secondaryTextStyle.color),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      )
                                    : (_sort == _HabitSort.manual
                                        ? ReorderableListView.builder(
                                            key: const ValueKey('archived_manual_reorderable'),
                                            shrinkWrap: true,
                                            physics: const NeverScrollableScrollPhysics(),
                                            itemCount: archivedVisible.length,
                                            onReorder: (oldIndex, newIndex) async {
                                              await _repo.reorderByIds(oldIndex, newIndex, archivedVisibleIds);
                                              HapticFeedback.mediumImpact();
                                              if (!mounted) return;
                                              setState(() {});
                                            },
                                            itemBuilder: (context, index) {
                                              final h = archivedVisible[index];
                                              return Container(
                                                key: ValueKey('archived_habit_${h.id}'),
                                                margin: const EdgeInsets.only(bottom: 10),
                                                child: Row(
                                                  children: [
                                                    ReorderableDragStartListener(
                                                      index: index,
                                                      child: const Padding(
                                                        padding: EdgeInsets.only(right: 8),
                                                        child: Icon(Icons.drag_handle),
                                                      ),
                                                    ),
                                                    Expanded(
                                                      child: HabitTile(
                                                        habit: h,
                                                        onToggle: () => _toggle(h),
                                                        onToggleSkipToday: () => _toggleSkipToday(h),
                                                        onOpenDetails: () => _openDetails(h),
                                                        onEdit: () => _openEditHabit(h),
                                                        onDelete: () => _confirmAndRemoveWithUndo(h),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            },
                                          )
                                        : Column(
                                            children: archivedVisible
                                                .map((h) => Padding(
                                                      padding: const EdgeInsets.only(bottom: 10),
                                                      child: HabitTile(
                                                        key: ValueKey('sorted_archived_${h.id}'),
                                                        habit: h,
                                                        onToggle: () => _toggle(h),
                                                        onToggleSkipToday: () => _toggleSkipToday(h),
                                                        onOpenDetails: () => _openDetails(h),
                                                        onEdit: () => _openEditHabit(h),
                                                        onDelete: () => _confirmAndRemoveWithUndo(h),
                                                      ),
                                                    ))
                                                .toList(),
                                          )),
                              ),
                              crossFadeState: _expandArchivedSection
                                  ? CrossFadeState.showSecond
                                  : CrossFadeState.showFirst,
                              duration: const Duration(milliseconds: 220),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }
}
