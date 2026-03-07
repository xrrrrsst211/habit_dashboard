import 'dart:math';

import 'package:flutter/material.dart';
import 'package:habit_dashboard/core/theme/app_styles.dart';
import 'package:habit_dashboard/features/habits/domain/habit.dart';

class StatsScreen extends StatefulWidget {
  final List<Habit> habits;

  const StatsScreen({super.key, required this.habits});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  static const List<int> _rangeOptions = <int>[30, 90, 365];
  int _selectedDays = 90;
  String _selectedHabitId = 'all';

  String _keyFromDate(DateTime d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${d.year}-${two(d.month)}-${two(d.day)}';
  }

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  int _calcStreak(Habit h) {
    return Habit.calcCurrentStreakPublic(h.completedDates, h.skippedDates);
  }

  int _countThisWeek(Habit habit) {
    final now = DateTime.now();
    final start = _dateOnly(now).subtract(Duration(days: now.weekday - DateTime.monday));
    int count = 0;
    for (int i = 0; i < 7; i++) {
      final d = start.add(Duration(days: i));
      if (habit.completedDates.contains(_keyFromDate(d))) count++;
    }
    return count;
  }

  List<Habit> _activeHabits() => widget.habits.where((h) => !h.archived).toList();

  List<Habit> _filteredHabits(List<Habit> activeHabits) {
    if (_selectedHabitId == 'all') return activeHabits;
    return activeHabits.where((h) => h.id == _selectedHabitId).toList();
  }

  int _doneCount(Habit habit, int days) {
    final today = _dateOnly(DateTime.now());
    int count = 0;
    for (int i = 0; i < days; i++) {
      final date = today.subtract(Duration(days: i));
      if (habit.completedDates.contains(_keyFromDate(date))) count++;
    }
    return count;
  }

  int _skipCount(Habit habit, int days) {
    final today = _dateOnly(DateTime.now());
    int count = 0;
    for (int i = 0; i < days; i++) {
      final date = today.subtract(Duration(days: i));
      if (habit.skippedDates.contains(_keyFromDate(date))) count++;
    }
    return count;
  }

  int _activeCount(Habit habit, int days) {
    return max(0, days - _skipCount(habit, days));
  }

  double _completionRate(Habit habit, int days) {
    final active = _activeCount(habit, days);
    if (active == 0) return 0;
    return _doneCount(habit, days) / active;
  }

  List<_CalendarCellStat> _calendarStats(List<Habit> habits, int days) {
    final today = _dateOnly(DateTime.now());
    return List.generate(days, (index) {
      final date = today.subtract(Duration(days: days - 1 - index));
      final key = _keyFromDate(date);
      int done = 0;
      int skipped = 0;
      int active = 0;
      for (final habit in habits) {
        if (habit.skippedDates.contains(key)) {
          skipped += 1;
          continue;
        }
        active += 1;
        if (habit.completedDates.contains(key)) done += 1;
      }
      final rate = active == 0 ? 0.0 : done / active;
      return _CalendarCellStat(
        date: date,
        done: done,
        skipped: skipped,
        active: active,
        rate: rate,
      );
    });
  }

  List<_WeekStat> _weekStats(List<Habit> habits, int days) {
    final daily = _calendarStats(habits, days);
    final List<_WeekStat> weeks = <_WeekStat>[];
    for (int i = 0; i < daily.length; i += 7) {
      final chunk = daily.sublist(i, min(i + 7, daily.length));
      final done = chunk.fold<int>(0, (sum, d) => sum + d.done);
      final active = chunk.fold<int>(0, (sum, d) => sum + d.active);
      final skipped = chunk.fold<int>(0, (sum, d) => sum + d.skipped);
      weeks.add(
        _WeekStat(
          start: chunk.first.date,
          end: chunk.last.date,
          done: done,
          active: active,
          skipped: skipped,
          rate: active == 0 ? 0.0 : done / active,
        ),
      );
    }
    return weeks;
  }

  Map<int, double> _weekdayRates(List<Habit> habits, int days) {
    final today = _dateOnly(DateTime.now());
    final Map<int, int> done = <int, int>{};
    final Map<int, int> active = <int, int>{};

    for (int i = 0; i < days; i++) {
      final date = today.subtract(Duration(days: i));
      final key = _keyFromDate(date);
      for (final habit in habits) {
        if (habit.skippedDates.contains(key)) continue;
        active[date.weekday] = (active[date.weekday] ?? 0) + 1;
        if (habit.completedDates.contains(key)) {
          done[date.weekday] = (done[date.weekday] ?? 0) + 1;
        }
      }
    }

    final Map<int, double> result = <int, double>{};
    for (int weekday = DateTime.monday; weekday <= DateTime.sunday; weekday++) {
      final a = active[weekday] ?? 0;
      result[weekday] = a == 0 ? 0 : (done[weekday] ?? 0) / a;
    }
    return result;
  }

  String _weekdayShort(int weekday) {
    const names = <String>['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return names[weekday - 1];
  }

  String _monthShort(DateTime d) {
    const names = <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return names[d.month - 1];
  }

  String _rangeLabel(DateTime start, DateTime end) {
    return '${_monthShort(start)} ${start.day} – ${_monthShort(end)} ${end.day}';
  }

  @override
  Widget build(BuildContext context) {
    final activeHabits = _activeHabits();
    final shownHabits = _filteredHabits(activeHabits);
    final colorScheme = Theme.of(context).colorScheme;

    if (shownHabits.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Stats & insights')),
        body: const Center(child: Text('No active habits yet.')),
      );
    }

    final selectedHabit = _selectedHabitId == 'all'
        ? null
        : activeHabits.cast<Habit?>().firstWhere((h) => h?.id == _selectedHabitId, orElse: () => null);

    final todayKey = _keyFromDate(DateTime.now());
    final rangeCells = _calendarStats(shownHabits, _selectedDays);
    final weekStats = _weekStats(shownHabits, _selectedDays);
    final weekdayRates = _weekdayRates(shownHabits, _selectedDays);

    final totalHabits = shownHabits.length;
    final doneToday = shownHabits.where((h) => h.completedDates.contains(todayKey)).length;
    final skippedToday = shownHabits.where((h) => h.skippedDates.contains(todayKey)).length;
    final activeToday = max(0, totalHabits - skippedToday);
    final consistency = activeToday == 0 ? 0.0 : doneToday / activeToday;

    final bestStreak = shownHabits.fold<int>(0, (best, h) => max(best, _calcStreak(h)));
    final totalDone = shownHabits.fold<int>(0, (sum, h) => sum + _doneCount(h, _selectedDays));
    final totalActive = shownHabits.fold<int>(0, (sum, h) => sum + _activeCount(h, _selectedDays));
    final totalSkipped = shownHabits.fold<int>(0, (sum, h) => sum + _skipCount(h, _selectedDays));
    final rangeRate = totalActive == 0 ? 0.0 : totalDone / totalActive;

    final goalsTracked = shownHabits.where((h) => h.targetDays > 0 || h.weeklyTarget > 0).length;
    final goalsOnTrack = shownHabits.where((h) {
      if (h.weeklyTarget > 0) {
        return _countThisWeek(h) >= h.weeklyTarget;
      }
      if (h.targetDays > 0) {
        return _calcStreak(h) >= h.targetDays;
      }
      return false;
    }).length;

    final leaderboard = [...shownHabits]
      ..sort((a, b) {
        final rateCompare = _completionRate(b, _selectedDays).compareTo(_completionRate(a, _selectedDays));
        if (rateCompare != 0) return rateCompare;
        return _calcStreak(b).compareTo(_calcStreak(a));
      });

    final protectToday = shownHabits.where((h) {
      if (h.completedDates.contains(todayKey)) return false;
      if (h.skippedDates.contains(todayKey)) return false;
      return _calcStreak(h) >= 3 || (h.weeklyTarget > 0 && _countThisWeek(h) < h.weeklyTarget);
    }).toList()
      ..sort((a, b) {
        final streakCompare = _calcStreak(b).compareTo(_calcStreak(a));
        if (streakCompare != 0) return streakCompare;
        return _completionRate(b, _selectedDays).compareTo(_completionRate(a, _selectedDays));
      });

    final bestWeekdayEntry = weekdayRates.entries.reduce(
      (a, b) => a.value >= b.value ? a : b,
    );
    final lowestWeekdayEntry = weekdayRates.entries.reduce(
      (a, b) => a.value <= b.value ? a : b,
    );

    final latestWeek = weekStats.isNotEmpty ? weekStats.last : null;
    final previousWeek = weekStats.length > 1 ? weekStats[weekStats.length - 2] : null;
    final weekDelta = latestWeek == null || previousWeek == null
        ? 0.0
        : latestWeek.rate - previousWeek.rate;

    return Scaffold(
      appBar: AppBar(title: const Text('Stats & insights')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: <Color>[
                  colorScheme.primary.withOpacity(0.16),
                  colorScheme.secondary.withOpacity(0.09),
                  colorScheme.surface,
                ],
              ),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: colorScheme.outline.withOpacity(0.16)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  selectedHabit == null ? 'Advanced analytics' : selectedHabit.title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Text(
                  selectedHabit == null
                      ? 'See patterns, pressure points and momentum across your active habits.'
                      : selectedHabit.isQuit
                          ? 'Clean-day trends, weekly rhythm and streak pressure for this quit habit.'
                          : 'Consistency, momentum and streak pressure for this habit.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurface.withOpacity(0.72),
                      ),
                ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _HeroMetric(label: 'Range', value: '${_selectedDays}d', icon: Icons.date_range_rounded),
                    _HeroMetric(
                      label: 'Consistency',
                      value: '${(rangeRate * 100).round()}%',
                      icon: Icons.insights_rounded,
                    ),
                    _HeroMetric(
                      label: 'Best streak',
                      value: '$bestStreak',
                      icon: Icons.local_fire_department_outlined,
                    ),
                    _HeroMetric(
                      label: 'Goals on track',
                      value: '$goalsOnTrack/$goalsTracked',
                      icon: Icons.flag_outlined,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _SectionLabel(title: 'Controls', subtitle: 'Dial in the time range or focus on one habit.'),
          const SizedBox(height: 10),
          _InsightCard(
            title: 'Focus controls',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Switch the time window or drill into one habit to inspect deeper patterns.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurface.withOpacity(0.74),
                      ),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _rangeOptions
                      .map(
                        (days) => ChoiceChip(
                          label: Text('$days days'),
                          selected: _selectedDays == days,
                          onSelected: (_) => setState(() => _selectedDays = days),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  value: _selectedHabitId,
                  decoration: const InputDecoration(
                    labelText: 'Analytics focus',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: [
                    const DropdownMenuItem<String>(
                      value: 'all',
                      child: Text('All active habits'),
                    ),
                    ...activeHabits.map(
                      (habit) => DropdownMenuItem<String>(
                        value: habit.id,
                        child: Text(habit.title, overflow: TextOverflow.ellipsis),
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _selectedHabitId = value);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _InsightCard(
                  title: 'Today snapshot',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('$doneToday done • $skippedToday skipped • $totalHabits tracked'),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: consistency,
                          minHeight: 10,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text('Today consistency: ${(consistency * 100).round()}%'),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _InsightCard(
                  title: 'Range summary',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('$totalDone check-ins across $totalActive active slots'),
                      const SizedBox(height: 8),
                      Text('Skipped days: $totalSkipped'),
                      const SizedBox(height: 8),
                      Text('Coverage: ${shownHabits.length} ${shownHabits.length == 1 ? 'habit' : 'habits'}'),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _SectionLabel(title: 'Patterns', subtitle: 'Where your consistency is strongest and where it softens.'),
          const SizedBox(height: 10),
          _InsightCard(
            title: '${_selectedDays}-day heatmap',
            subtitle: 'Darker cells mean better completion. Grey cells mean the day was skipped for everything in view.',
            child: _HeatmapTimeline(
              cells: rangeCells,
              monthShort: _monthShort,
              weekdayShort: _weekdayShort,
            ),
          ),
          const SizedBox(height: 14),
          _InsightCard(
            title: 'Weekly trend',
            subtitle: weekStats.isEmpty
                ? null
                : 'Latest window: ${_rangeLabel(weekStats.first.start, weekStats.last.end)}',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 180,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: weekStats.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (context, index) {
                      final week = weekStats[index];
                      return _WeekBar(
                        week: week,
                        label: index == weekStats.length - 1 ? 'Now' : 'W${index + 1}',
                      );
                    },
                  ),
                ),
                if (latestWeek != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    previousWeek == null
                        ? 'Latest week: ${(latestWeek.rate * 100).round()}% consistency.'
                        : weekDelta >= 0
                            ? 'You are up ${(weekDelta * 100).round()} pts vs the previous week.'
                            : 'You are down ${(-weekDelta * 100).round()} pts vs the previous week.',
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _InsightCard(
                  title: 'Weekday pattern',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: 110,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: List.generate(7, (index) {
                            final weekday = index + 1;
                            return Expanded(
                              child: _MiniBar(
                                label: _weekdayShort(weekday),
                                value: weekdayRates[weekday] ?? 0,
                              ),
                            );
                          }),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text('Best day: ${_weekdayShort(bestWeekdayEntry.key)} • ${(bestWeekdayEntry.value * 100).round()}%'),
                      const SizedBox(height: 6),
                      Text('Weakest day: ${_weekdayShort(lowestWeekdayEntry.key)} • ${(lowestWeekdayEntry.value * 100).round()}%'),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _InsightCard(
                  title: 'Pressure points',
                  child: protectToday.isEmpty
                      ? const Text('No streaks under pressure right now. Nice.')
                      : Column(
                          children: protectToday.take(4).map((habit) {
                            final streak = _calcStreak(habit);
                            return _LeaderboardTile(
                              habit: habit,
                              trailing: '${streak}d',
                              subtitle: habit.isQuit ? 'Protect clean streak today' : 'Keep the streak alive',
                            );
                          }).toList(),
                        ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _InsightCard(
                  title: 'Top momentum',
                  child: Column(
                    children: leaderboard.take(4).map((habit) {
                      final rate = (_completionRate(habit, _selectedDays) * 100).round();
                      return _LeaderboardTile(
                        habit: habit,
                        trailing: '$rate%',
                        subtitle: '${_calcStreak(habit)} ${habit.isQuit ? 'clean' : 'day'} streak',
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _InsightCard(
                  title: 'What it means',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        rangeRate >= 0.8
                            ? 'Excellent consistency. You are in maintenance mode now.'
                            : rangeRate >= 0.6
                                ? 'Solid momentum. Tighten up your weakest days and you will feel the difference.'
                                : 'You have room to stabilize. Use the pressure list and weakest weekday as your focus.',
                      ),
                      const SizedBox(height: 10),
                      Text(
                        selectedHabit == null
                            ? 'Try switching to a single habit in the focus control to inspect where it slips.'
                            : selectedHabit.isQuit
                                ? 'For quit habits, skipped days are neutral. The real signal is how often you protect the clean streak.'
                                : 'For build habits, the fastest win is making weak weekdays easier, not harder.',
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CalendarCellStat {
  final DateTime date;
  final int done;
  final int skipped;
  final int active;
  final double rate;

  const _CalendarCellStat({
    required this.date,
    required this.done,
    required this.skipped,
    required this.active,
    required this.rate,
  });
}

class _WeekStat {
  final DateTime start;
  final DateTime end;
  final int done;
  final int active;
  final int skipped;
  final double rate;

  const _WeekStat({
    required this.start,
    required this.end,
    required this.done,
    required this.active,
    required this.skipped,
    required this.rate,
  });
}

class _SectionLabel extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionLabel({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: cs.onSurface.withOpacity(0.72),
              ),
        ),
      ],
    );
  }
}

class _InsightCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;

  const _InsightCard({required this.title, required this.child, this.subtitle});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.surface,
            colorScheme.primary.withOpacity(0.025),
          ],
        ),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: colorScheme.outline.withOpacity(0.10)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.025),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 6),
            Text(
              subtitle!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: context.secondaryTextStyle.color,
                  ),
            ),
          ],
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _HeroMetric extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _HeroMetric({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      constraints: const BoxConstraints(minWidth: 132),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.surface.withOpacity(0.84),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outline.withOpacity(0.10)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              Text(label, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeatmapTimeline extends StatelessWidget {
  final List<_CalendarCellStat> cells;
  final String Function(DateTime) monthShort;
  final String Function(int) weekdayShort;

  const _HeatmapTimeline({
    required this.cells,
    required this.monthShort,
    required this.weekdayShort,
  });

  Color _cellColor(BuildContext context, _CalendarCellStat cell) {
    final cs = Theme.of(context).colorScheme;
    if (cell.active == 0 && cell.skipped > 0) return cs.outline.withOpacity(0.18);
    if (cell.active == 0) return cs.surfaceVariant.withOpacity(0.30);
    if (cell.rate >= 0.95) return cs.primary;
    if (cell.rate >= 0.75) return cs.primary.withOpacity(0.82);
    if (cell.rate >= 0.5) return cs.primary.withOpacity(0.58);
    if (cell.rate > 0) return cs.primary.withOpacity(0.32);
    return cs.error.withOpacity(0.22);
  }

  @override
  Widget build(BuildContext context) {
    final List<List<_CalendarCellStat>> weeks = <List<_CalendarCellStat>>[];
    for (int i = 0; i < cells.length; i += 7) {
      weeks.add(cells.sublist(i, min(i + 7, cells.length)));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const SizedBox(width: 26),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: weeks.map((week) {
                    final anchor = week.first.date;
                    final showLabel = anchor.day <= 7;
                    return SizedBox(
                      width: 18,
                      child: Center(
                        child: Text(
                          showLabel ? monthShort(anchor) : '',
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 24,
              child: Column(
                children: List.generate(7, (index) {
                  final weekday = index + 1;
                  return SizedBox(
                    height: 18,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        weekday == 1 || weekday == 4 || weekday == 7 ? weekdayShort(weekday) : '',
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ),
                  );
                }),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: weeks.map((week) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: Column(
                        children: List.generate(7, (index) {
                          final cell = index < week.length ? week[index] : null;
                          return Tooltip(
                            message: cell == null
                                ? ''
                                : '${monthShort(cell.date)} ${cell.date.day}: ${cell.done}/${cell.active} done • ${cell.skipped} skipped',
                            child: Container(
                              width: 14,
                              height: 14,
                              margin: const EdgeInsets.only(bottom: 4),
                              decoration: BoxDecoration(
                                color: cell == null ? Colors.transparent : _cellColor(context, cell),
                                borderRadius: BorderRadius.circular(5),
                                border: Border.all(color: Theme.of(context).colorScheme.surface.withOpacity(0.75)),
                              ),
                            ),
                          );
                        }),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 6,
          children: const [
            _LegendDot(label: 'Low', opacity: 0.22),
            _LegendDot(label: 'Mid', opacity: 0.58),
            _LegendDot(label: 'High', opacity: 1),
            _LegendDot(label: 'Skipped', isNeutral: true),
          ],
        ),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  final String label;
  final double opacity;
  final bool isNeutral;

  const _LegendDot({
    required this.label,
    this.opacity = 1,
    this.isNeutral = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = isNeutral ? cs.outline.withOpacity(0.24) : cs.primary.withOpacity(opacity);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: Theme.of(context).textTheme.labelSmall),
      ],
    );
  }
}

class _WeekBar extends StatelessWidget {
  final _WeekStat week;
  final String label;

  const _WeekBar({required this.week, required this.label});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: 54,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text('${(week.rate * 100).round()}%', style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: 8),
          Expanded(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: FractionallySizedBox(
                heightFactor: week.rate.clamp(0.06, 1.0),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        cs.primary.withOpacity(0.92),
                        cs.primary.withOpacity(0.58),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(label, style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: 4),
          Text(
            '${week.done}/${week.active}',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: cs.onSurface.withOpacity(0.68),
                ),
          ),
        ],
      ),
    );
  }
}

class _MiniBar extends StatelessWidget {
  final String label;
  final double value;

  const _MiniBar({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text('${(value * 100).round()}', style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: 6),
          Expanded(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: FractionallySizedBox(
                heightFactor: value.clamp(0.04, 1.0),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        cs.secondary.withOpacity(0.86),
                        cs.secondary.withOpacity(0.52),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(label, style: Theme.of(context).textTheme.labelSmall),
        ],
      ),
    );
  }
}

class _LeaderboardTile extends StatelessWidget {
  final Habit habit;
  final String subtitle;
  final String trailing;

  const _LeaderboardTile({
    required this.habit,
    required this.subtitle,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surfaceVariant.withOpacity(0.42),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: habit.color.withOpacity(0.16),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(habit.iconData, color: habit.color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  habit.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: cs.onSurface.withOpacity(0.68),
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            trailing,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}
