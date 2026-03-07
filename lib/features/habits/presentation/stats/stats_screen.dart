import 'dart:math';

import 'package:flutter/material.dart';
import 'package:habit_dashboard/features/habits/domain/habit.dart';

class StatsScreen extends StatelessWidget {
  final List<Habit> habits;

  const StatsScreen({super.key, required this.habits});

  String _keyFromDate(DateTime d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${d.year}-${two(d.month)}-${two(d.day)}';
  }

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  int _calcStreak(Habit h) {
    return Habit.calcCurrentStreakPublic(h.completedDates, h.skippedDates);
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

  int _countDoneInLastDays(Habit habit, int days) {
    final today = _dateOnly(DateTime.now());
    int count = 0;
    for (int i = 0; i < days; i++) {
      final d = today.subtract(Duration(days: i));
      if (habit.completedDates.contains(_keyFromDate(d))) count++;
    }
    return count;
  }

  int _countSkippedInLastDays(Habit habit, int days) {
    final today = _dateOnly(DateTime.now());
    int count = 0;
    for (int i = 0; i < days; i++) {
      final d = today.subtract(Duration(days: i));
      if (habit.skippedDates.contains(_keyFromDate(d))) count++;
    }
    return count;
  }

  int _activeDaysInLastDays(Habit habit, int days) {
    return max(0, days - _countSkippedInLastDays(habit, days));
  }

  double _completionRate(Habit habit, int days) {
    final active = _activeDaysInLastDays(habit, days);
    if (active == 0) return 0;
    return _countDoneInLastDays(habit, days) / active;
  }

  List<_DayStat> _lastNDaysOverview(List<Habit> habits, int days) {
    final today = _dateOnly(DateTime.now());
    return List.generate(days, (index) {
      final date = today.subtract(Duration(days: days - 1 - index));
      int done = 0;
      int active = 0;
      for (final habit in habits) {
        final key = _keyFromDate(date);
        if (habit.skippedDates.contains(key)) continue;
        active += 1;
        if (habit.completedDates.contains(key)) done += 1;
      }
      final rate = active == 0 ? 0.0 : done / active;
      return _DayStat(date: date, done: done, active: active, rate: rate);
    });
  }

  List<_MonthCell> _lastMonthCells(List<Habit> habits, int days) {
    final today = _dateOnly(DateTime.now());
    return List.generate(days, (index) {
      final date = today.subtract(Duration(days: days - 1 - index));
      final key = _keyFromDate(date);
      int done = 0;
      int active = 0;
      for (final habit in habits) {
        if (habit.skippedDates.contains(key)) continue;
        active += 1;
        if (habit.completedDates.contains(key)) done += 1;
      }
      final rate = active == 0 ? 0.0 : done / active;
      return _MonthCell(date: date, rate: rate);
    });
  }

  String _weekdayShort(DateTime d) {
    const names = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return names[d.weekday - 1];
  }

  String _monthShort(DateTime d) {
    const names = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return names[d.month - 1];
  }

  @override
  Widget build(BuildContext context) {
    final activeHabits = habits.where((h) => !h.archived).toList();
    final todayKey = _keyFromDate(DateTime.now());

    final total = activeHabits.length;
    final doneToday = activeHabits.where((h) => h.completedDates.contains(todayKey)).length;
    final skippedToday = activeHabits.where((h) => h.skippedDates.contains(todayKey)).length;

    final buildHabits = activeHabits.where((h) => h.isBuild).toList();
    final quitHabits = activeHabits.where((h) => h.isQuit).toList();

    int bestStreak = 0;
    Habit? topStreakHabit;
    for (final h in activeHabits) {
      final s = _calcStreak(h);
      if (s > bestStreak) {
        bestStreak = s;
        topStreakHabit = h;
      }
    }

    final goalsTotal = activeHabits.where((h) => h.targetDays > 0 || h.weeklyTarget > 0).length;
    final goalsReached = activeHabits.where((h) {
      if (h.weeklyTarget > 0) {
        return _countThisWeek(h.completedDates) >= h.weeklyTarget;
      }
      if (h.targetDays > 0) {
        return _calcStreak(h) >= h.targetDays;
      }
      return false;
    }).length;

    final last7 = _lastNDaysOverview(activeHabits, 7);
    final last30Cells = _lastMonthCells(activeHabits, 30);
    final weekDonePoints = last7.fold<int>(0, (sum, day) => sum + day.done);
    final weekTotalPoints = last7.fold<int>(0, (sum, day) => sum + day.active);
    final weekRate = weekTotalPoints == 0 ? 0.0 : weekDonePoints / weekTotalPoints;

    final completionLeaders = [...activeHabits]
      ..sort((a, b) {
        final rateCmp = _completionRate(b, 30).compareTo(_completionRate(a, 30));
        if (rateCmp != 0) return rateCmp;
        return _calcStreak(b).compareTo(_calcStreak(a));
      });

    final focusNeeded = activeHabits.where((h) {
      if (h.completedDates.contains(todayKey)) return false;
      if (h.skippedDates.contains(todayKey)) return false;
      return _calcStreak(h) >= 3 || h.weeklyTarget > 0;
    }).toList()
      ..sort((a, b) {
        final streakCmp = _calcStreak(b).compareTo(_calcStreak(a));
        if (streakCmp != 0) return streakCmp;
        return _completionRate(b, 7).compareTo(_completionRate(a, 7));
      });

    return Scaffold(
      appBar: AppBar(title: const Text('Stats & insights')),
      body: activeHabits.isEmpty
          ? const Center(child: Text('No active habits yet.'))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Theme.of(context).colorScheme.primary.withOpacity(0.14),
                        Theme.of(context).colorScheme.secondary.withOpacity(0.08),
                        Theme.of(context).colorScheme.surface,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outline.withOpacity(0.16),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your habit dashboard',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        topStreakHabit == null
                            ? 'Start stacking small wins.'
                            : '${topStreakHabit.title} is leading with a $bestStreak-day ${topStreakHabit.isQuit ? 'clean streak' : 'streak'}.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.72),
                            ),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(
                            child: _HeroMetric(
                              label: 'Today',
                              value: '$doneToday/$total',
                              icon: Icons.today_rounded,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _HeroMetric(
                              label: 'Best streak',
                              value: '$bestStreak',
                              icon: Icons.local_fire_department_outlined,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _HeroMetric(
                              label: 'Goals hit',
                              value: '$goalsReached/$goalsTotal',
                              icon: Icons.emoji_events_outlined,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _InsightCard(
                        title: 'Build vs quit',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _SplitBar(
                              leftValue: buildHabits.length,
                              rightValue: quitHabits.length,
                              leftLabel: 'Build',
                              rightLabel: 'Quit',
                            ),
                            const SizedBox(height: 12),
                            Text('${buildHabits.length} build • ${quitHabits.length} quit'),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _InsightCard(
                        title: 'Today status',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('$doneToday done • $skippedToday skipped'),
                            const SizedBox(height: 10),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(999),
                              child: LinearProgressIndicator(
                                value: total == 0 ? 0 : doneToday / total,
                                minHeight: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _InsightCard(
                  title: 'Last 7 days',
                  subtitle: '$weekDonePoints / $weekTotalPoints active check-ins completed',
                  child: Column(
                    children: [
                      SizedBox(
                        height: 148,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: last7
                              .map(
                                (day) => Expanded(
                                  child: _DayBar(
                                    label: _weekdayShort(day.date),
                                    value: day.rate,
                                    done: day.done,
                                    active: day.active,
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text('Weekly consistency: ${(weekRate * 100).round()}%'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _InsightCard(
                  title: '30-day heatmap',
                  subtitle: 'Darker cells mean better completion across all active habits.',
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: last30Cells
                        .map(
                          (cell) => _HeatCell(
                            label: '${_monthShort(cell.date)} ${cell.date.day}',
                            value: cell.rate,
                          ),
                        )
                        .toList(),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _InsightCard(
                        title: 'Top momentum',
                        child: Column(
                          children: completionLeaders.take(3).map((habit) {
                            return _LeaderboardTile(
                              habit: habit,
                              trailing: '${(_completionRate(habit, 30) * 100).round()}%',
                              subtitle: '${_calcStreak(habit)} day streak',
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _InsightCard(
                        title: 'Protect today',
                        child: focusNeeded.isEmpty
                            ? const Text('No streaks at risk right now. Nice.')
                            : Column(
                                children: focusNeeded.take(3).map((habit) {
                                  final streak = _calcStreak(habit);
                                  return _LeaderboardTile(
                                    habit: habit,
                                    trailing: '${streak}d',
                                    subtitle: habit.isQuit ? 'Clean streak to protect' : 'Keep the streak alive',
                                  );
                                }).toList(),
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

class _DayStat {
  final DateTime date;
  final int done;
  final int active;
  final double rate;

  const _DayStat({
    required this.date,
    required this.done,
    required this.active,
    required this.rate,
  });
}

class _MonthCell {
  final DateTime date;
  final double rate;

  const _MonthCell({required this.date, required this.rate});
}

class _InsightCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;

  const _InsightCard({required this.title, required this.child, this.subtitle});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: cs.outline.withOpacity(0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 6),
            Text(
              subtitle!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: cs.onSurface.withOpacity(0.68),
                    height: 1.35,
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

  const _HeroMetric({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.42),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.outline.withOpacity(0.10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18),
          const SizedBox(height: 10),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 2),
          Text(label),
        ],
      ),
    );
  }
}

class _SplitBar extends StatelessWidget {
  final int leftValue;
  final int rightValue;
  final String leftLabel;
  final String rightLabel;

  const _SplitBar({
    required this.leftValue,
    required this.rightValue,
    required this.leftLabel,
    required this.rightLabel,
  });

  @override
  Widget build(BuildContext context) {
    final total = max(1, leftValue + rightValue);
    final safeLeft = max(1, leftValue);
    final safeRight = max(1, rightValue);
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: SizedBox(
            height: 12,
            child: Row(
              children: [
                Expanded(
                  flex: safeLeft,
                  child: Container(color: cs.primary.withOpacity(0.8)),
                ),
                Expanded(
                  flex: safeRight,
                  child: Container(color: cs.secondary.withOpacity(0.55)),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: Text('$leftLabel $leftValue')),
            Expanded(
              child: Text(
                '$rightLabel $rightValue',
                textAlign: TextAlign.end,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _DayBar extends StatelessWidget {
  final String label;
  final double value;
  final int done;
  final int active;

  const _DayBar({
    required this.label,
    required this.value,
    required this.done,
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            '$done',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: cs.onSurface.withOpacity(0.70),
                ),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                width: 22,
                height: 18 + (90 * value),
                decoration: BoxDecoration(
                  color: cs.primary.withOpacity(0.22 + (0.58 * value)),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(label),
          Text(
            active == 0 ? '—' : '${(value * 100).round()}%',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: cs.onSurface.withOpacity(0.58),
                ),
          ),
        ],
      ),
    );
  }
}

class _HeatCell extends StatelessWidget {
  final String label;
  final double value;

  const _HeatCell({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Tooltip(
      message: '$label • ${(value * 100).round()}%',
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: cs.primary.withOpacity(0.08 + (0.72 * value)),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: cs.outline.withOpacity(0.10)),
        ),
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
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
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.66),
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            trailing,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
        ],
      ),
    );
  }
}
