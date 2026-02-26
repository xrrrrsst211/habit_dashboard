import 'dart:math';
import 'package:flutter/material.dart';
import 'package:habit_dashboard/core/theme/app_styles.dart';
import 'package:habit_dashboard/features/habits/data/habit_repository.dart';
import 'package:habit_dashboard/features/habits/domain/habit.dart';

class HabitDetailScreen extends StatefulWidget {
  final HabitRepository repo;
  final Habit habit;

  const HabitDetailScreen({
    super.key,
    required this.repo,
    required this.habit,
  });

  @override
  State<HabitDetailScreen> createState() => _HabitDetailScreenState();
}

class _HabitDetailScreenState extends State<HabitDetailScreen> {
  late DateTime _month;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = DateTime(now.year, now.month, 1);
  }

  String _keyFromDate(DateTime d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${d.year}-${two(d.month)}-${two(d.day)}';
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  int _daysInMonth(DateTime month) {
    final nextMonth = DateTime(month.year, month.month + 1, 1);
    return nextMonth.subtract(const Duration(days: 1)).day;
  }

  int _weekdayToCol(int weekday) => (weekday - 1) % 7;

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

  String _monthTitle(DateTime m) {
    const names = [
      'January','February','March','April','May','June',
      'July','August','September','October','November','December'
    ];
    return '${names[m.month - 1]} ${m.year}';
  }

  void _prevMonth() => setState(() => _month = DateTime(_month.year, _month.month - 1, 1));
  void _nextMonth() => setState(() => _month = DateTime(_month.year, _month.month + 1, 1));

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

  String _formatMinutes(int minutes) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }

  Future<int?> _pickTime(BuildContext context, int initialMinutes) async {
    final initialTime = TimeOfDay(
      hour: initialMinutes ~/ 60,
      minute: initialMinutes % 60,
    );

    final t = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );

    if (t == null) return null;
    return t.hour * 60 + t.minute;
  }

  Widget _monthHeader() {
    return Row(
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
          onPressed: _nextMonth,
          icon: const Icon(Icons.chevron_right),
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

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final current = widget.repo.getHabits().firstWhere(
      (h) => h.id == widget.habit.id,
      orElse: () => widget.habit,
    );

    final streak = _calcStreak(current.completedDates);
    final hasGoal = current.targetDays > 0;
    final doneToGoal = hasGoal ? min(streak, current.targetDays) : 0;
    final progress = hasGoal ? (doneToGoal / current.targetDays) : 0.0;
    final goalReached = hasGoal && streak >= current.targetDays;

    final now = DateTime.now();
    final cells = _buildMonthCells(_month);

    final reminderOn = current.reminderMinutes != null;

    return Scaffold(
      appBar: AppBar(title: const Text('Habit details')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  current.title,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              if (goalReached)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    // withOpacity() is deprecated on newer Flutter; withValues keeps behavior the same.
                    color: cs.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text('🎉 Goal reached'),
                )
            ],
          ),
          const SizedBox(height: 6),
          Text(
            streak > 0 ? '🔥 $streak day streak' : 'No streak yet',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: context.secondaryTextStyle.color,
                ),
          ),
          const SizedBox(height: 12),

          if (hasGoal) ...[
            Text('Goal: $doneToGoal / ${current.targetDays} days'),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                minHeight: 10,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      await widget.repo.restartHabitProgress(current.id);
                      if (!mounted) return;
                      setState(() {});
                    },
                    icon: const Icon(Icons.restart_alt),
                    label: const Text('Restart progress'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],

          Row(
            children: [
              Expanded(
                child: Text(
                  'Reminder',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              Switch(
                value: reminderOn,
                onChanged: (v) async {
                  if (!v) {
                    await widget.repo.setReminderMinutes(current.id, null);
                  } else {
                    await widget.repo.setReminderMinutes(current.id, 20 * 60);
                  }
                  if (!mounted) return;
                  setState(() {});
                },
              ),
            ],
          ),
          if (reminderOn) ...[
            Row(
              children: [
                Expanded(
                  child: Text('Time: ${_formatMinutes(current.reminderMinutes!)}'),
                ),
                OutlinedButton(
                  onPressed: () async {
                    final picked = await _pickTime(context, current.reminderMinutes!);
                    if (picked == null) return;
                    await widget.repo.setReminderMinutes(current.id, picked);
                    if (!mounted) return;
                    setState(() {});
                  },
                  child: const Text('Change'),
                ),
              ],
            ),
          ],

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await widget.repo.setArchived(current.id, !current.archived);
                    if (!mounted) return;
                    setState(() {});
                  },
                  icon: Icon(current.archived
                      ? Icons.unarchive_outlined
                      : Icons.archive_outlined),
                  label: Text(current.archived ? 'Unarchive' : 'Archive'),
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          _monthHeader(),
          const SizedBox(height: 8),
          _weekdayRow(),
          const SizedBox(height: 10),

          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: cells.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 1,
            ),
            itemBuilder: (context, index) {
              final date = cells[index];
              if (date == null) return const SizedBox.shrink();

              final key = _keyFromDate(date);
              final done = current.completedDates.contains(key);
              final isToday = _sameDay(date, now);

              final isFuture = date.isAfter(DateTime(now.year, now.month, now.day));

              return InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: isFuture
                    ? null
                    : () async {
                        await widget.repo.toggleDate(current.id, key);
                        if (!mounted) return;
                        setState(() {});
                      },
                child: Opacity(
                  opacity: isFuture ? 0.35 : 1,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      // withOpacity() is deprecated on newer Flutter; withValues keeps behavior the same.
                      color: done ? cs.primary : cs.onSurface.withValues(alpha: 0.08),
                      border: isToday ? Border.all(color: cs.primary, width: 2) : null,
                    ),
                    child: Center(
                      child: Text(
                        '${date.day}',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: done ? cs.onPrimary : cs.onSurface,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 18),
          Text(
            'Tip: tap any day to add/remove a check-in.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: context.secondaryTextStyle.color,
                ),
          ),
        ],
      ),
    );
  }
}