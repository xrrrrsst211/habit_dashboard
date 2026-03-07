import 'dart:math';

import 'package:flutter/material.dart';
import 'package:habit_dashboard/core/theme/app_styles.dart';
import 'package:habit_dashboard/features/habits/data/habit_repository.dart';
import 'package:habit_dashboard/features/habits/domain/habit.dart';

class HabitHistoryScreen extends StatefulWidget {
  final HabitRepository repo;
  final Habit habit;

  const HabitHistoryScreen({
    super.key,
    required this.repo,
    required this.habit,
  });

  @override
  State<HabitHistoryScreen> createState() => _HabitHistoryScreenState();
}

class _HabitHistoryScreenState extends State<HabitHistoryScreen> {
  late DateTime _month;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = DateTime(now.year, now.month, 1);
  }

  Habit get _current => widget.repo.getById(widget.habit.id) ?? widget.habit;

  String _keyFromDate(DateTime d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${d.year}-${two(d.month)}-${two(d.day)}';
  }

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  int _daysInMonth(DateTime month) {
    final nextMonth = DateTime(month.year, month.month + 1, 1);
    return nextMonth.subtract(const Duration(days: 1)).day;
  }

  int _weekdayToCol(int weekday) => (weekday - 1) % 7;

  List<DateTime?> _buildMonthCells(DateTime month) {
    final first = DateTime(month.year, month.month, 1);
    final daysCount = _daysInMonth(month);
    final startCol = _weekdayToCol(first.weekday);
    final cells = <DateTime?>[];

    for (int i = 0; i < startCol; i++) {
      cells.add(null);
    }
    for (int day = 1; day <= daysCount; day++) {
      cells.add(DateTime(month.year, month.month, day));
    }
    while (cells.length % 7 != 0) {
      cells.add(null);
    }
    return cells;
  }

  String _monthTitle(DateTime m) {
    const names = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${names[m.month - 1]} ${m.year}';
  }

  void _prevMonth() =>
      setState(() => _month = DateTime(_month.year, _month.month - 1, 1));

  void _nextMonth() {
    final now = DateTime.now();
    final currentMonth = DateTime(now.year, now.month, 1);
    final candidate = DateTime(_month.year, _month.month + 1, 1);
    if (candidate.isAfter(currentMonth)) return;
    setState(() => _month = candidate);
  }

  int _countDoneInLastDays(Habit habit, int days) {
    final today = _dateOnly(DateTime.now());
    int count = 0;

    for (int i = 0; i < days; i++) {
      final date = today.subtract(Duration(days: i));
      if (habit.completedDates.contains(_keyFromDate(date))) count++;
    }

    return count;
  }

  int _countSkippedInLastDays(Habit habit, int days) {
    final today = _dateOnly(DateTime.now());
    int count = 0;

    for (int i = 0; i < days; i++) {
      final date = today.subtract(Duration(days: i));
      if (habit.skippedDates.contains(_keyFromDate(date))) count++;
    }

    return count;
  }

  int _countActiveDaysInLastDays(Habit habit, int days) {
    final skipped = _countSkippedInLastDays(habit, days);
    return max(0, days - skipped);
  }

  int _countMissedInLastDays(Habit habit, int days) {
    final done = _countDoneInLastDays(habit, days);
    final active = _countActiveDaysInLastDays(habit, days);
    return max(0, active - done);
  }

  double _completionRate(Habit habit, int days) {
    final done = _countDoneInLastDays(habit, days);
    final active = _countActiveDaysInLastDays(habit, days);
    if (active == 0) return 0;
    return done / active;
  }

  int _currentStreak(Habit habit) {
    return Habit.calcCurrentStreakPublic(
      habit.completedDates,
      habit.skippedDates,
    );
  }

  int _monthDoneCount(Habit habit, DateTime month) {
    int count = 0;
    final days = _daysInMonth(month);
    for (int day = 1; day <= days; day++) {
      final key = _keyFromDate(DateTime(month.year, month.month, day));
      if (habit.completedDates.contains(key)) count++;
    }
    return count;
  }

  int _monthSkippedCount(Habit habit, DateTime month) {
    int count = 0;
    final days = _daysInMonth(month);
    for (int day = 1; day <= days; day++) {
      final key = _keyFromDate(DateTime(month.year, month.month, day));
      if (habit.skippedDates.contains(key)) count++;
    }
    return count;
  }

  double _monthCompletionRate(Habit habit, DateTime month) {
    final now = _dateOnly(DateTime.now());
    final first = DateTime(month.year, month.month, 1);
    final last = DateTime(month.year, month.month, _daysInMonth(month));
    final end = last.isAfter(now) ? now : last;

    if (end.isBefore(first)) return 0;

    int done = 0;
    int active = 0;

    for (DateTime d = first; !d.isAfter(end); d = d.add(const Duration(days: 1))) {
      final key = _keyFromDate(d);
      if (habit.skippedDates.contains(key)) continue;
      active += 1;
      if (habit.completedDates.contains(key)) done += 1;
    }

    if (active == 0) return 0;
    return done / active;
  }


  int _countSlipsInLastDays(Habit habit, int days) {
    final today = _dateOnly(DateTime.now());
    int count = 0;
    for (int i = 0; i < days; i++) {
      final date = today.subtract(Duration(days: i));
      if (habit.slipDates.contains(_keyFromDate(date))) count++;
    }
    return count;
  }

  Map<int, int> _slipWeekdayCounts(Habit habit, int days) {
    final today = _dateOnly(DateTime.now());
    final result = <int, int>{};
    for (int i = 0; i < days; i++) {
      final date = today.subtract(Duration(days: i));
      if (habit.slipDates.contains(_keyFromDate(date))) {
        result[date.weekday] = (result[date.weekday] ?? 0) + 1;
      }
    }
    return result;
  }

  String _weekdayName(int weekday) {
    const names = <int, String>{
      1: 'Monday',
      2: 'Tuesday',
      3: 'Wednesday',
      4: 'Thursday',
      5: 'Friday',
      6: 'Saturday',
      7: 'Sunday',
    };
    return names[weekday] ?? '?';
  }

  List<DateTime> _recentSlipDates(Habit habit, {int limit = 8}) {
    final dates = habit.slipDates
        .map(DateTime.tryParse)
        .whereType<DateTime>()
        .map(_dateOnly)
        .toList()
      ..sort((a, b) => b.compareTo(a));
    return dates.take(limit).toList();
  }

  String _prettyDate(DateTime d) {
    const months = <String>['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }

  Widget _slipInsightsCard(Habit habit) {
    if (!habit.isQuit) return const SizedBox.shrink();
    final slips7 = _countSlipsInLastDays(habit, 7);
    final slips30 = _countSlipsInLastDays(habit, 30);
    final weekdayCounts = _slipWeekdayCounts(habit, 90);
    final topSlipDay = weekdayCounts.isEmpty
        ? null
        : weekdayCounts.entries.reduce((a, b) => a.value >= b.value ? a : b);
    final recentSlips = _recentSlipDates(habit);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.red.withOpacity(0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.flag_outlined),
              const SizedBox(width: 8),
              Text(
                'Slip insights',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              SizedBox(width: 150, child: _statCard(icon: Icons.history_toggle_off_rounded, label: 'Last 7 days', value: '$slips7')),
              SizedBox(width: 150, child: _statCard(icon: Icons.date_range_outlined, label: 'Last 30 days', value: '$slips30')),
              SizedBox(
                width: 180,
                child: _statCard(
                  icon: Icons.event_busy_outlined,
                  label: 'Most common slip day',
                  value: topSlipDay == null ? 'None' : _weekdayName(topSlipDay.key),
                  subtitle: topSlipDay == null ? 'No slips logged yet.' : '${topSlipDay.value} in the last 90 days',
                ),
              ),
            ],
          ),
          if (recentSlips.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text('Recent slip history', style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: recentSlips.map((date) => Chip(label: Text(_prettyDate(date)))).toList(),
            ),
          ],
        ],
      ),
    );
  }


  Widget _motivationCard(Habit habit) {
    final notes = habit.notes.trim();
    if (notes.isEmpty) return const SizedBox.shrink();

    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: habit.color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: habit.color.withOpacity(0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                habit.isQuit ? Icons.shield_outlined : Icons.flag_outlined,
                size: 20,
                color: habit.color,
              ),
              const SizedBox(width: 8),
              Text(
                habit.isQuit ? 'Your reason' : 'Your note',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            notes,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  height: 1.4,
                  color: cs.onSurface.withOpacity(0.88),
                ),
          ),
        ],
      ),
    );
  }

  String _percentText(double value) => '${(value * 100).round()}%';

  Widget _statCard({
    required IconData icon,
    required String label,
    required String value,
    String? subtitle,
  }) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface.withOpacity(0.65),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.outline.withOpacity(0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20),
          const SizedBox(height: 12),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 4),
          Text(label),
          if (subtitle != null) ...[
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: context.secondaryTextStyle.color,
                  ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _rangeTile({
    required String label,
    required String doneLabel,
    required int done,
    required int skipped,
    required int missed,
    required double rate,
  }) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: cs.surface.withOpacity(0.55),
        border: Border.all(color: cs.outline.withOpacity(0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
              Text(
                _percentText(rate),
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: rate.clamp(0.0, 1.0),
              minHeight: 8,
              valueColor: AlwaysStoppedAnimation<Color>(_current.color),
              backgroundColor: _current.color.withOpacity(0.12),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _smallChip('$doneLabel: $done'),
              _smallChip('Skipped: $skipped'),
              _smallChip('Missed: $missed'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _smallChip(String text) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: cs.surface,
        border: Border.all(color: cs.outline.withOpacity(0.18)),
      ),
      child: Text(text),
    );
  }

  Widget _legendItem({
    required Color color,
    required String label,
    Border? border,
    Widget? icon,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(6),
            border: border,
          ),
          child: Center(child: icon),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: context.secondaryTextStyle.color,
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }

  Widget _calendarLegend(ColorScheme cs, Habit habit) {
    final mutedBorder = Border.all(color: cs.onSurface.withAlpha(60), width: 1.2);
    return Wrap(
      spacing: 14,
      runSpacing: 8,
      children: [
        _legendItem(
          color: habit.color,
          label: habit.isQuit ? 'Clean' : 'Done',
          icon: Icon(Icons.check, color: cs.onPrimary, size: 13),
        ),
        _legendItem(
          color: cs.onSurface.withAlpha(13),
          label: 'Skipped',
          border: mutedBorder,
          icon: Icon(Icons.remove, color: cs.onSurface.withAlpha(160), size: 13),
        ),
        _legendItem(
          color: cs.error.withOpacity(0.12),
          label: 'Missed',
          border: Border.all(color: cs.error.withOpacity(0.35)),
        ),
        _legendItem(
          color: cs.onSurface.withAlpha(20),
          label: 'Future / empty',
        ),
      ],
    );
  }

  Widget _weekdayRow() {
    const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Row(
        children: List.generate(7, (i) {
          return Expanded(
            child: Center(
              child: Text(
                labels[i],
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: context.secondaryTextStyle.color,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _sectionTitle(String title, {String? subtitle}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: context.secondaryTextStyle.color,
                ),
          ),
        ],
      ],
    );
  }



  List<_MilestoneData> _milestones(Habit habit) {
    return [
      _MilestoneData(days: 3, label: habit.isQuit ? '3 clean days' : '3-day streak', icon: Icons.looks_3_rounded),
      _MilestoneData(days: 7, label: habit.isQuit ? '1 week clean' : '1 week streak', icon: Icons.date_range_outlined),
      _MilestoneData(days: 14, label: habit.isQuit ? '2 weeks clean' : '2 weeks streak', icon: Icons.bolt_outlined),
      _MilestoneData(days: 30, label: habit.isQuit ? '30 clean days' : '30-day streak', icon: Icons.emoji_events_outlined),
      _MilestoneData(days: 60, label: habit.isQuit ? '60 clean days' : '60-day streak', icon: Icons.workspace_premium_outlined),
      _MilestoneData(days: 100, label: habit.isQuit ? '100 clean days' : '100-day streak', icon: Icons.stars_rounded),
    ];
  }

  _MilestoneData? _nextMilestone(Habit habit) {
    final streak = _currentStreak(habit);
    for (final milestone in _milestones(habit)) {
      if (streak < milestone.days) return milestone;
    }
    return null;
  }

  Widget _achievementCard(Habit habit, _MilestoneData milestone, bool unlocked) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: 170,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: unlocked ? habit.color.withOpacity(0.12) : cs.surface.withOpacity(0.65),
        border: Border.all(
          color: unlocked ? habit.color.withOpacity(0.30) : cs.outline.withOpacity(0.18),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: unlocked ? habit.color.withOpacity(0.16) : cs.surface,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              unlocked ? milestone.icon : Icons.lock_outline_rounded,
              color: unlocked ? habit.color : context.secondaryTextStyle.color,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            milestone.label,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            unlocked ? 'Unlocked' : 'Locked',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: context.secondaryTextStyle.color,
                ),
          ),
        ],
      ),
    );
  }

  Widget _milestoneOverview(Habit habit) {
    final streak = _currentStreak(habit);
    final next = _nextMilestone(habit);
    final unlockedCount = _milestones(habit).where((m) => streak >= m.days).length;
    final cs = Theme.of(context).colorScheme;

    if (next == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: habit.color.withOpacity(0.10),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: habit.color.withOpacity(0.25)),
        ),
        child: Row(
          children: [
            Icon(Icons.workspace_premium_outlined, color: habit.color),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Top tier unlocked — all $unlockedCount milestones completed.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
          ],
        ),
      );
    }

    final previous = _milestones(habit)
        .where((m) => m.days < next.days)
        .fold<int>(0, (acc, m) => m.days > acc ? m.days : acc);
    final progress = ((streak - previous) / (next.days - previous).clamp(1, 1000000)).clamp(0.0, 1.0);
    final remaining = next.days - streak;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface.withOpacity(0.55),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.outline.withOpacity(0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(next.icon, color: habit.color),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Next milestone: ${next.label}',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
              Text(
                '$remaining left',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              valueColor: AlwaysStoppedAnimation<Color>(habit.color),
              backgroundColor: habit.color.withOpacity(0.12),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            habit.isQuit
                ? 'Each clean day moves you closer to the next badge.'
                : 'Each check-in moves you closer to the next badge.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: context.secondaryTextStyle.color,
                ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final habit = _current;
    final cs = Theme.of(context).colorScheme;
    final now = _dateOnly(DateTime.now());
    final monthCells = _buildMonthCells(_month);

    final done7 = _countDoneInLastDays(habit, 7);
    final skipped7 = _countSkippedInLastDays(habit, 7);
    final missed7 = _countMissedInLastDays(habit, 7);

    final done30 = _countDoneInLastDays(habit, 30);
    final skipped30 = _countSkippedInLastDays(habit, 30);
    final missed30 = _countMissedInLastDays(habit, 30);

    final done90 = _countDoneInLastDays(habit, 90);
    final skipped90 = _countSkippedInLastDays(habit, 90);
    final missed90 = _countMissedInLastDays(habit, 90);

    final monthDone = _monthDoneCount(habit, _month);
    final monthSkipped = _monthSkippedCount(habit, _month);
    final monthRate = _monthCompletionRate(habit, _month);

    return Scaffold(
      appBar: AppBar(title: const Text('History & insights')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: habit.color.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(habit.iconData, color: habit.color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  habit.title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            habit.isQuit ? 'A clearer view of clean streaks and relapse-free days.' : 'A clearer view of consistency, streaks, and recent check-ins.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: context.secondaryTextStyle.color,
                ),
          ),
          const SizedBox(height: 18),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.15,
            children: [
              _statCard(
                icon: Icons.local_fire_department_outlined,
                label: habit.isQuit ? 'Current clean streak' : 'Current streak',
                value: '${_currentStreak(habit)} days',
                subtitle: 'Skipped days do not break it.',
              ),
              _statCard(
                icon: Icons.emoji_events_outlined,
                label: habit.isQuit ? 'Best clean streak' : 'Best streak',
                value: '${habit.bestStreak} days',
                subtitle: habit.isQuit ? 'Your all-time best clean run.' : 'Your all-time best run.',
              ),
              _statCard(
                icon: Icons.calendar_month_outlined,
                label: habit.isQuit ? 'This month clean' : 'This month done',
                value: '$monthDone days',
                subtitle: 'Skipped: $monthSkipped days',
              ),
              _statCard(
                icon: Icons.insights_outlined,
                label: habit.isQuit ? '30-day clean rate' : '30-day completion',
                value: _percentText(_completionRate(habit, 30)),
                subtitle: 'Skipped days are excluded.',
              ),
            ],
          ),
          if (habit.notes.trim().isNotEmpty) ...[
            const SizedBox(height: 18),
            _motivationCard(habit),
          ],
          if (habit.isQuit) ...[
            const SizedBox(height: 18),
            _slipInsightsCard(habit),
          ],
          const SizedBox(height: 24),
          _sectionTitle(
            'Milestones',
            subtitle: habit.isQuit ? 'Unlock clean-day achievements as your streak grows.' : 'Unlock streak achievements as consistency builds up.',
          ),
          const SizedBox(height: 12),
          _milestoneOverview(habit),
          const SizedBox(height: 12),
          SizedBox(
            height: 118,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _milestones(habit).length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final milestone = _milestones(habit)[index];
                return _achievementCard(
                  habit,
                  milestone,
                  _currentStreak(habit) >= milestone.days,
                );
              },
            ),
          ),
          const SizedBox(height: 24),
          _sectionTitle(
            'Recent windows',
            subtitle: habit.isQuit ? 'Quick summary for recent clean, skipped, and missed days.' : 'Quick summary for the last 7, 30, and 90 days.',
          ),
          const SizedBox(height: 12),
          _rangeTile(
            label: 'Last 7 days',
            doneLabel: habit.isQuit ? 'Clean' : 'Done',
            done: done7,
            skipped: skipped7,
            missed: missed7,
            rate: _completionRate(habit, 7),
          ),
          const SizedBox(height: 12),
          _rangeTile(
            label: 'Last 30 days',
            doneLabel: habit.isQuit ? 'Clean' : 'Done',
            done: done30,
            skipped: skipped30,
            missed: missed30,
            rate: _completionRate(habit, 30),
          ),
          const SizedBox(height: 12),
          _rangeTile(
            label: 'Last 90 days',
            doneLabel: habit.isQuit ? 'Clean' : 'Done',
            done: done90,
            skipped: skipped90,
            missed: missed90,
            rate: _completionRate(habit, 90),
          ),
          const SizedBox(height: 24),
          _sectionTitle(
            'Calendar view',
            subtitle: habit.isQuit ? 'Clean, skipped, missed, and future days at a glance.' : 'Done, skipped, missed, and future days at a glance.',
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              IconButton(
                tooltip: 'Previous month',
                onPressed: _prevMonth,
                icon: const Icon(Icons.chevron_left),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    _monthTitle(_month),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Next month',
                onPressed: DateTime(_month.year, _month.month + 1, 1)
                        .isAfter(DateTime(now.year, now.month, 1))
                    ? null
                    : _nextMonth,
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _weekdayRow(),
          const SizedBox(height: 10),
          _calendarLegend(cs, habit),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: monthCells.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 1,
            ),
            itemBuilder: (context, index) {
              final date = monthCells[index];
              if (date == null) return const SizedBox.shrink();

              final key = _keyFromDate(date);
              final done = habit.completedDates.contains(key);
              final skipped = habit.skippedDates.contains(key);
              final isFuture = date.isAfter(now);
              final isMissed = !done && !skipped && !isFuture;
              final isToday = _sameDay(date, now);

              final Color fillColor;
              Border? border;
              Widget? childIcon;

              if (done) {
                fillColor = cs.primary;
                childIcon = Icon(Icons.check, size: 14, color: cs.onPrimary);
              } else if (skipped) {
                fillColor = cs.onSurface.withAlpha(13);
                border = Border.all(color: cs.onSurface.withAlpha(90), width: 1.2);
                childIcon = Icon(Icons.remove, size: 14, color: cs.onSurface.withAlpha(160));
              } else if (isMissed) {
                fillColor = cs.error.withOpacity(0.12);
                border = Border.all(color: cs.error.withOpacity(0.35), width: 1.1);
              } else {
                fillColor = cs.onSurface.withAlpha(20);
              }

              if (isToday) {
                border = Border.all(color: habit.color, width: 2);
              }

              return Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: fillColor,
                  border: border,
                ),
                child: Stack(
                  children: [
                    if (childIcon != null)
                      Positioned(
                        top: 6,
                        right: 6,
                        child: childIcon,
                      ),
                    Center(
                      child: Text(
                        '${date.day}',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: done ? cs.onPrimary : cs.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cs.surface.withOpacity(0.5),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: cs.outline.withOpacity(0.18)),
            ),
            child: Text(
              habit.isQuit ? 'Clean rate = clean days / active days. Skipped days are treated like rest days, so they do not increase the rate and do not break streaks.' : 'Completion rate = done days / active days. Skipped days are treated like rest days, so they do not increase the rate and do not break streaks.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: context.secondaryTextStyle.color,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}


class _MilestoneData {
  final int days;
  final String label;
  final IconData icon;

  const _MilestoneData({
    required this.days,
    required this.label,
    required this.icon,
  });
}


