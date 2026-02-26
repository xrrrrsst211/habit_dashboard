import 'package:flutter/material.dart';
import 'package:habit_dashboard/features/habits/domain/habit.dart';

class StatsScreen extends StatelessWidget {
  final List<Habit> habits;

  const StatsScreen({super.key, required this.habits});

  String _keyFromDate(DateTime d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${d.year}-${two(d.month)}-${two(d.day)}';
  }

  String _todayKey() => _keyFromDate(DateTime.now());

  List<String> _last7Keys() {
    final now = DateTime.now();
    return List.generate(7, (i) {
      final d = now.subtract(Duration(days: 6 - i));
      return _keyFromDate(d);
    });
  }

  int _calcStreak(Set<String> dates) {
    final now = DateTime.now();
    int count = 0;
    while (true) {
      final d = now.subtract(Duration(days: count));
      final key = _keyFromDate(d);
      if (!dates.contains(key)) break;
      count++;
    }
    return count;
  }

  @override
  Widget build(BuildContext context) {
    final todayKey = _todayKey();
    final last7 = _last7Keys();

    final total = habits.length;
    final doneToday =
        habits.where((h) => h.completedDates.contains(todayKey)).length;

    int bestStreak = 0;
    for (final h in habits) {
      final s = _calcStreak(h.completedDates);
      if (s > bestStreak) bestStreak = s;
    }

    final goalsTotal = habits.where((h) => h.targetDays > 0).length;
    final goalsReached = habits.where((h) {
      if (h.targetDays <= 0) return false;
      return _calcStreak(h.completedDates) >= h.targetDays;
    }).length;

    // Week completion: total check-ins over the last 7 days / (7 * habits)
    int weekDonePoints = 0;
    for (final h in habits) {
      for (final k in last7) {
        if (h.completedDates.contains(k)) weekDonePoints++;
      }
    }
    final weekTotalPoints = total * 7;
    final weekRate =
        weekTotalPoints == 0 ? 0.0 : (weekDonePoints / weekTotalPoints);

    return Scaffold(
      appBar: AppBar(title: const Text('Stats')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _StatCard(
            title: 'Today',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$doneToday / $total habits done'),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: total == 0 ? 0 : (doneToday / total),
                    minHeight: 10,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _StatCard(
            title: 'Best streak',
            child: Text('🔥 $bestStreak days'),
          ),
          const SizedBox(height: 12),
          _StatCard(
            title: 'Goals',
            child: Text('$goalsReached / $goalsTotal goals reached'),
          ),
          const SizedBox(height: 12),
          _StatCard(
            title: 'Last 7 days',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$weekDonePoints / $weekTotalPoints completions'),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: weekRate,
                    minHeight: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _StatCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }
}