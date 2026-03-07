import 'dart:math';
import 'package:flutter/material.dart';
import 'package:habit_dashboard/core/theme/app_styles.dart';
import 'package:habit_dashboard/features/habits/data/habit_repository.dart';
import 'package:habit_dashboard/features/habits/domain/habit.dart';
import 'package:habit_dashboard/features/habits/presentation/habit_history/habit_history_screen.dart';

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

  void _showCalendarHelp() {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Calendar help'),
          content: Text(
            widget.habit.isQuit
                ? '• Tap a day to mark it as clean\n'
                    '• Long-press a day to toggle rest day (skip)\n\n'
                    'Skipped days don\'t add to your streak, but they also don\'t break it.'
                : '• Tap a day to toggle done\n'
                    '• Long-press a day to toggle rest day (skip)\n\n'
                    'Skipped days don\'t add to your streak, but they also don\'t break it.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Got it'),
            ),
          ],
        );
      },
    );
  }

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

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  int _daysInMonth(DateTime month) {
    final nextMonth = DateTime(month.year, month.month + 1, 1);
    return nextMonth.subtract(const Duration(days: 1)).day;
  }

  int _weekdayToCol(int weekday) => (weekday - 1) % 7;

  int _calcStreak(Habit habit) {
    // Current streak should not be broken by skipped days.
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

  String _weekdayNameShort(int weekday) {
    const names = <int, String>{1: 'Mon', 2: 'Tue', 3: 'Wed', 4: 'Thu', 5: 'Fri', 6: 'Sat', 7: 'Sun'};
    return names[weekday] ?? '?';
  }

  int _slipCountLast30(Habit habit) {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 29));
    return habit.slipDates.where((d) {
      final dt = DateTime.tryParse(d);
      return dt != null && !dt.isBefore(start);
    }).length;
  }


  List<DateTime> _recentSlipDates(Habit habit, {int limit = 6}) {
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

  Future<void> _handleSlipAction(Habit habit, DateTime date) async {
    final key = _keyFromDate(date);
    final slipped = habit.slipDates.contains(key);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(slipped ? 'Undo slip?' : 'Log slip?'),
        content: Text(
          slipped
              ? 'Remove the slip mark for ${_prettyDate(date)}?'
              : 'Mark ${_prettyDate(date)} as a slip / relapse day? This will clear any clean or skipped status for that date.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: Text(slipped ? 'Undo' : 'Log slip')),
        ],
      ),
    );
    if (confirmed != true) return;
    await widget.repo.toggleSlipDate(habit.id, key);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(slipped ? 'Slip removed for ${_prettyDate(date)}' : 'Slip logged for ${_prettyDate(date)}')),
      );
    setState(() {});
  }

  Widget _smartReminderCard(Habit habit) {
    final cs = Theme.of(context).colorScheme;
    final reminderOn = habit.reminderMinutes != null;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface.withOpacity(0.72),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.outline.withOpacity(0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text('Smart reminders', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800))),
              Switch(
                value: reminderOn,
                onChanged: (v) async {
                  await widget.repo.setReminderMinutes(habit.id, v ? (habit.reminderMinutes ?? 20 * 60) : null);
                  if (!mounted) return;
                  setState(() {});
                },
              ),
            ],
          ),
          if (reminderOn) ...[
            Row(
              children: [
                Expanded(child: Text('Time: ${_formatMinutes(habit.reminderMinutes!)}')),
                OutlinedButton(
                  onPressed: () async {
                    final picked = await _pickTime(context, habit.reminderMinutes!);
                    if (picked == null) return;
                    await widget.repo.setReminderMinutes(habit.id, picked);
                    if (!mounted) return;
                    setState(() {});
                  },
                  child: const Text('Change'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List<Widget>.generate(7, (index) {
                final weekday = index + 1;
                return FilterChip(
                  label: Text(_weekdayNameShort(weekday)),
                  selected: habit.reminderWeekdays.contains(weekday),
                  onSelected: (_) async {
                    final next = List<int>.from(habit.reminderWeekdays);
                    if (next.contains(weekday)) {
                      if (next.length == 1) return;
                      next.remove(weekday);
                    } else {
                      next.add(weekday);
                      next.sort();
                    }
                    await widget.repo.setReminderOptions(habit.id, reminderWeekdays: next);
                    if (!mounted) return;
                    setState(() {});
                  },
                );
              }),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: TextEditingController(text: habit.reminderMessage)..selection = TextSelection.collapsed(offset: habit.reminderMessage.length),
              onSubmitted: (value) async {
                await widget.repo.setReminderOptions(habit.id, reminderMessage: value);
                if (!mounted) return;
                setState(() {});
              },
              decoration: const InputDecoration(
                labelText: 'Custom reminder message',
                hintText: 'Press enter to save',
              ),
            ),
            const SizedBox(height: 6),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              value: habit.reminderOnlyIfIncomplete,
              onChanged: (v) async {
                await widget.repo.setReminderOptions(habit.id, reminderOnlyIfIncomplete: v);
                if (!mounted) return;
                setState(() {});
              },
              title: const Text('Only if not completed yet'),
              subtitle: const Text('Helpful copy for more accountable reminders.'),
            ),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              value: habit.reminderEveningNudge,
              onChanged: (v) async {
                await widget.repo.setReminderOptions(habit.id, reminderEveningNudge: v);
                if (!mounted) return;
                setState(() {});
              },
              title: const Text('Evening nudge'),
              subtitle: const Text('Adds a softer later reminder on selected days.'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _slipCard(Habit habit) {
    if (!habit.isQuit) return const SizedBox.shrink();
    final cs = Theme.of(context).colorScheme;
    final slips30 = _slipCountLast30(habit);
    final today = _dateOnly(DateTime.now());
    final todayKey = _keyFromDate(today);
    final slippedToday = habit.slipDates.contains(todayKey);
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
              Text('Relapse / slip log', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Use this when there was a relapse. Slips stay separate from clean-day check-ins so your quit analytics stay honest and easier to review later.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: cs.onSurface.withOpacity(0.82)),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.tonalIcon(
                onPressed: () => _handleSlipAction(habit, today),
                icon: Icon(slippedToday ? Icons.undo_rounded : Icons.flag_rounded),
                label: Text(slippedToday ? 'Undo slip today' : 'Log slip today'),
              ),
              OutlinedButton.icon(
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: today,
                    firstDate: DateTime(today.year - 3),
                    lastDate: today,
                  );
                  if (picked == null) return;
                  if (!mounted) return;
                  await _handleSlipAction(habit, _dateOnly(picked));
                },
                icon: const Icon(Icons.event_rounded),
                label: const Text('Log past slip'),
              ),
              Chip(label: Text('Last 30 days: $slips30 slip${slips30 == 1 ? '' : 's'}')),
            ],
          ),
          if (recentSlips.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text('Recent slips', style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: recentSlips.map((date) {
                final key = _keyFromDate(date);
                final isToday = key == todayKey;
                return InputChip(
                  avatar: const Icon(Icons.flag_rounded, size: 16),
                  label: Text(isToday ? 'Today' : _prettyDate(date)),
                  onPressed: () => _handleSlipAction(habit, date),
                  onDeleted: () => _handleSlipAction(habit, date),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
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


  Widget _notesCard(Habit habit) {
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
                habit.isQuit ? Icons.favorite_outline_rounded : Icons.lightbulb_outline_rounded,
                size: 20,
                color: habit.color,
              ),
              const SizedBox(width: 8),
              Text(
                habit.isQuit ? 'Reason to stay clean' : 'Why this matters',
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

  Widget _legendItem({
    required Color color,
    required Widget icon,
    required String label,
    Border? border,
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
          child: Center(child: IconTheme(data: const IconThemeData(size: 14), child: icon)),
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
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _legendItem(
          color: habit.color,
          icon: Icon(Icons.check, color: cs.onPrimary),
          label: habit.isQuit ? 'Clean' : 'Done',
        ),
        _legendItem(
          color: cs.onSurface.withAlpha(13),
          icon: Icon(Icons.remove, color: cs.onSurface.withAlpha(160)),
          label: 'Rest day',
          border: mutedBorder,
        ),
        _legendItem(
          color: cs.onSurface.withAlpha(20),
          icon: const SizedBox.shrink(),
          label: 'Empty',
        ),
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

  _MilestoneData? _nextMilestone(Habit habit, int streak) {
    for (final milestone in _milestones(habit)) {
      if (streak < milestone.days) return milestone;
    }
    return null;
  }

  Widget _nextMilestoneCard(Habit habit, int streak) {
    final cs = Theme.of(context).colorScheme;
    final next = _nextMilestone(habit, streak);
    final achieved = _milestones(habit).where((m) => streak >= m.days).length;

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
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: habit.color.withOpacity(0.16),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(Icons.workspace_premium_outlined, color: habit.color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'All milestone tiers reached',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'You unlocked $achieved achievement${achieved == 1 ? '' : 's'} for this habit.',
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

    final remaining = next.days - streak;
    final previousDays = _milestones(habit)
        .where((m) => m.days < next.days)
        .fold<int>(0, (maxDays, m) => m.days > maxDays ? m.days : maxDays);
    final segmentDenominator = (next.days - previousDays).clamp(1, 1000000);
    final segmentProgress = ((streak - previousDays) / segmentDenominator).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.outline.withOpacity(0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: habit.color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(next.icon, color: habit.color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Next milestone',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      next.label,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: context.secondaryTextStyle.color,
                          ),
                    ),
                  ],
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
              value: segmentProgress,
              minHeight: 10,
              valueColor: AlwaysStoppedAnimation<Color>(habit.color),
              backgroundColor: habit.color.withOpacity(0.12),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            habit.isQuit
                ? 'Keep stacking clean days to unlock the next badge.'
                : 'Keep checking in to unlock the next streak badge.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: context.secondaryTextStyle.color,
                ),
          ),
        ],
      ),
    );
  }

  Widget _achievementChip(_MilestoneData milestone, bool unlocked, Habit habit) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: unlocked ? habit.color.withOpacity(0.12) : cs.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: unlocked ? habit.color.withOpacity(0.28) : cs.outline.withOpacity(0.18),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            unlocked ? milestone.icon : Icons.lock_outline_rounded,
            size: 16,
            color: unlocked ? habit.color : context.secondaryTextStyle.color,
          ),
          const SizedBox(width: 6),
          Text(
            milestone.label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: unlocked ? null : context.secondaryTextStyle.color,
                ),
          ),
        ],
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

    final streak = _calcStreak(current);

    final hasWeeklyGoal = current.weeklyTarget > 0;
    final thisWeekDone = _countThisWeek(current.completedDates);
    final weeklyProgress = hasWeeklyGoal
        ? (min(thisWeekDone, current.weeklyTarget) / current.weeklyTarget)
            .clamp(0.0, 1.0)
        : 0.0;
    final weeklyReached = hasWeeklyGoal && thisWeekDone >= current.weeklyTarget;

    final hasGoal = current.targetDays > 0;
    final doneToGoal = hasGoal ? min(streak, current.targetDays) : 0;
    final progress = hasGoal ? (doneToGoal / current.targetDays) : 0.0;
    final goalReached = hasGoal && streak >= current.targetDays;

    final now = DateTime.now();
    final cells = _buildMonthCells(_month);


    return Scaffold(
      appBar: AppBar(title: const Text('Habit details')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: current.color.withOpacity(0.14),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(current.iconData, color: current.color),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        current.title,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ),
                  ],
                ),
              ),
              if (goalReached || weeklyReached)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: cs.primary.withAlpha(31),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text('🎉 Goal reached'),
                )
            ],
          ),
          const SizedBox(height: 6),
          Text(
            streak > 0 ? '🔥 $streak ${current.streakLabel}' : 'No streak yet',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: context.secondaryTextStyle.color,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            current.isQuit ? 'Tap days to mark them clean.' : 'Tap days to mark them done.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: context.secondaryTextStyle.color,
                ),
          ),
          const SizedBox(height: 12),

          _nextMilestoneCard(current, streak),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _milestones(current)
                .map((milestone) => _achievementChip(
                      milestone,
                      streak >= milestone.days,
                      current,
                    ))
                .toList(),
          ),

          if (hasWeeklyGoal || hasGoal) ...[
            if (hasWeeklyGoal) ...[
              Text('Weekly goal: $thisWeekDone / ${current.weeklyTarget} this week'),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: weeklyProgress,
                  minHeight: 10,
                ),
              ),
              const SizedBox(height: 12),
            ] else ...[
              Text(current.isQuit ? 'Goal: $doneToGoal / ${current.targetDays} clean days' : 'Goal: $doneToGoal / ${current.targetDays} days'),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: progress.clamp(0.0, 1.0),
                  minHeight: 10,
                ),
              ),
              const SizedBox(height: 12),
            ],
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
                    label: Text(current.isQuit ? 'Reset clean streak' : 'Restart progress'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],

          _smartReminderCard(current),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => HabitHistoryScreen(
                          repo: widget.repo,
                          habit: current,
                        ),
                      ),
                    );
                    if (!mounted) return;
                    setState(() {});
                  },
                  icon: const Icon(Icons.insights_outlined),
                  label: const Text('View history & insights'),
                ),
              ),
            ],
          ),

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

          Row(
            children: [
              Expanded(child: _monthHeader()),
              IconButton(
                tooltip: 'How it works',
                onPressed: _showCalendarHelp,
                icon: const Icon(Icons.info_outline),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _weekdayRow(),
          const SizedBox(height: 10),
          _calendarLegend(cs, current),
          const SizedBox(height: 12),

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
              final skipped = current.skippedDates.contains(key);
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
                onLongPress: isFuture
                    ? null
                    : () async {
                        await widget.repo.toggleSkipDate(current.id, key);
                        if (!mounted) return;
                        setState(() {});
                      },
                child: Opacity(
                  opacity: isFuture ? 0.35 : 1,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      color: done
                          ? cs.primary
                          : (skipped
                              ? cs.onSurface.withAlpha(13)
                              : cs.onSurface.withAlpha(20)),
                      border: isToday
                          ? Border.all(color: current.color, width: 2)
                          : (skipped
                              ? Border.all(color: cs.onSurface.withAlpha(90), width: 1.2)
                              : null),
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
            current.isQuit ? 'Tip: tap to mark a clean day, long-press to mark a rest day.' : 'Tip: tap to check-in, long-press to mark a rest day.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: context.secondaryTextStyle.color,
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
