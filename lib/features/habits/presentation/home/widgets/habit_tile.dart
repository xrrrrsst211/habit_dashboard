import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:habit_dashboard/core/theme/app_styles.dart';
import 'package:habit_dashboard/features/habits/domain/habit.dart';

class HabitTile extends StatelessWidget {
  final Habit habit;
  final VoidCallback onToggle;
  final VoidCallback? onToggleSkipToday;
  final VoidCallback onDelete;
  final VoidCallback onEdit;
  final VoidCallback onOpenDetails;

  const HabitTile({
    super.key,
    required this.habit,
    required this.onToggle,
    required this.onDelete,
    required this.onEdit,
    required this.onOpenDetails,
    this.onToggleSkipToday,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final secondaryColor = context.secondaryTextStyle.color;
    final accent = habit.color;

    final today = _todayKey();
    final doneToday = habit.completedDates.contains(today);
    final skippedToday = habit.skippedDates.contains(today);

    final streak = _calcStreak(habit);
    final last7 = _last7Keys();

    final thisWeekDone = _countThisWeek(habit.completedDates);
    final hasWeeklyGoal = habit.weeklyTarget > 0;
    final weeklyReached = hasWeeklyGoal && thisWeekDone >= habit.weeklyTarget;
    final weeklyProgress = hasWeeklyGoal
        ? (min(thisWeekDone, habit.weeklyTarget) / habit.weeklyTarget)
            .clamp(0.0, 1.0)
        : 0.0;

    final hasGoal = habit.targetDays > 0;
    final goalReached = hasGoal && streak >= habit.targetDays;

    final goalDone = hasGoal ? min(streak, habit.targetDays) : 0;
    final goalProgress =
        hasGoal ? (goalDone / habit.targetDays).clamp(0.0, 1.0) : 0.0;

    final statusLabel = doneToday
        ? (habit.isQuit ? 'CLEAN' : 'DONE')
        : (skippedToday ? 'REST' : 'TODAY');

    final statusBg = doneToday
        ? accent.withOpacity(0.14)
        : (skippedToday
            ? cs.onSurface.withOpacity(0.06)
            : cs.onSurface.withOpacity(0.04));

    final statusFg = doneToday
        ? accent
        : (skippedToday
            ? cs.onSurface.withOpacity(0.75)
            : cs.onSurface.withOpacity(0.75));

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accent.withOpacity(0.08),
            cs.surface,
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: doneToday
              ? accent.withOpacity(0.24)
              : cs.outline.withOpacity(0.10),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () {
            HapticFeedback.lightImpact();
            onToggle();
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ToggleDot(
                  doneToday: doneToday,
                  skippedToday: skippedToday,
                  accent: accent,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: accent.withOpacity(0.14),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(habit.iconData, color: accent, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  habit.title,
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w800,
                                        decoration: doneToday && habit.isBuild
                                            ? TextDecoration.lineThrough
                                            : null,
                                      ),
                                ),
                                const SizedBox(height: 4),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 6,
                                  children: [
                                    _chip(context, habit.typeLabel, icon: habit.isQuit ? Icons.shield_outlined : Icons.auto_awesome_outlined),
                                    _chip(context, Habit.iconLabelFor(habit.iconKey), icon: habit.iconData),
                                    if (habit.reminderMinutes != null)
                                      _chip(context, _formatMinutes(habit.reminderMinutes!), icon: Icons.notifications_active_outlined),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: statusBg,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              statusLabel,
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.7,
                                    color: statusFg,
                                  ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _WeekDotsByDates(
                        last7Keys: last7,
                        completedDates: habit.completedDates,
                        skippedDates: habit.skippedDates,
                        activeColor: accent,
                        todayBorderColor: accent,
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 10,
                        runSpacing: 8,
                        children: [
                          _metaText(context, streak > 0 ? '🔥 $streak ${habit.streakLabel}' : 'No streak yet'),
                          if (hasGoal) _metaText(context, '$goalDone/${habit.targetDays} target'),
                          if (hasWeeklyGoal) _metaText(context, '$thisWeekDone/${habit.weeklyTarget} this week'),
                          if (goalReached || weeklyReached) _metaText(context, '🎉 goal reached', color: accent),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        doneToday
                            ? habit.completionActionLabel
                            : (habit.isQuit ? 'Tap to mark today as clean' : 'Tap to mark done'),
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: secondaryColor),
                      ),
                      if (hasWeeklyGoal || hasGoal) ...[
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: LinearProgressIndicator(
                            value: hasWeeklyGoal ? weeklyProgress : goalProgress,
                            minHeight: 8,
                            valueColor: AlwaysStoppedAnimation<Color>(accent),
                            backgroundColor: accent.withOpacity(0.10),
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _actionButton(
                            context,
                            label: 'Details',
                            icon: Icons.insights_outlined,
                            onPressed: () {
                              HapticFeedback.selectionClick();
                              onOpenDetails();
                            },
                          ),
                          _actionButton(
                            context,
                            label: 'Edit',
                            icon: Icons.edit_outlined,
                            onPressed: () {
                              HapticFeedback.selectionClick();
                              onEdit();
                            },
                          ),
                          if (onToggleSkipToday != null)
                            _actionButton(
                              context,
                              label: skippedToday ? 'Unskip' : 'Skip today',
                              icon: skippedToday ? Icons.undo_rounded : Icons.hotel_rounded,
                              onPressed: () {
                                HapticFeedback.selectionClick();
                                onToggleSkipToday!.call();
                              },
                            ),
                          _actionButton(
                            context,
                            label: 'Delete',
                            icon: Icons.delete_outline,
                            onPressed: () {
                              HapticFeedback.selectionClick();
                              onDelete();
                            },
                            destructive: true,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _chip(BuildContext context, String label, {required IconData icon}) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: cs.surface.withOpacity(0.82),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: cs.outline.withOpacity(0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: cs.onSurface.withOpacity(0.74)),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }

  Widget _metaText(BuildContext context, String text, {Color? color}) {
    return Text(
      text,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: color ?? context.secondaryTextStyle.color,
            fontWeight: FontWeight.w600,
          ),
    );
  }

  Widget _actionButton(
    BuildContext context, {
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
    bool destructive = false,
  }) {
    final cs = Theme.of(context).colorScheme;
    final fg = destructive ? cs.error : cs.onSurface.withOpacity(0.82);
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        visualDensity: VisualDensity.compact,
        foregroundColor: fg,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        side: BorderSide(color: (destructive ? cs.error : cs.outline).withOpacity(0.18)),
      ),
    );
  }

  String _todayKey() => _keyFromDate(DateTime.now());

  List<String> _last7Keys() {
    final now = DateTime.now();
    return List.generate(7, (i) {
      final d = now.subtract(Duration(days: 6 - i));
      return _keyFromDate(d);
    });
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

  String _formatMinutes(int minutes) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }
}

class _ToggleDot extends StatelessWidget {
  final bool doneToday;
  final bool skippedToday;
  final Color accent;

  const _ToggleDot({
    required this.doneToday,
    required this.skippedToday,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: doneToday
            ? accent.withOpacity(0.14)
            : skippedToday
                ? cs.onSurface.withOpacity(0.06)
                : Colors.transparent,
        border: Border.all(
          color: doneToday
              ? accent
              : skippedToday
                  ? cs.onSurface.withOpacity(0.24)
                  : cs.outline.withOpacity(0.28),
          width: 1.4,
        ),
      ),
      child: Icon(
        doneToday
            ? Icons.check_rounded
            : skippedToday
                ? Icons.remove_rounded
                : Icons.circle_outlined,
        size: 18,
        color: doneToday ? accent : cs.onSurface.withOpacity(0.72),
      ),
    );
  }
}

class _WeekDotsByDates extends StatelessWidget {
  final List<String> last7Keys;
  final Set<String> completedDates;
  final Set<String> skippedDates;
  final Color activeColor;
  final Color todayBorderColor;

  const _WeekDotsByDates({
    required this.last7Keys,
    required this.completedDates,
    required this.skippedDates,
    required this.activeColor,
    required this.todayBorderColor,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    const dotSize = 10.0;
    const gap = 6.0;

    return Row(
      children: List.generate(7, (index) {
        final key = last7Keys[index];
        final isToday = index == 6;
        final isFilled = completedDates.contains(key);
        final isSkipped = skippedDates.contains(key);

        return Padding(
          padding: EdgeInsets.only(right: index == 6 ? 0 : gap),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            width: dotSize,
            height: dotSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isFilled
                  ? activeColor
                  : (isSkipped
                      ? cs.onSurface.withOpacity(0.06)
                      : cs.onSurface.withOpacity(0.12)),
              border: isToday
                  ? Border.all(color: todayBorderColor, width: 1.6)
                  : (isSkipped
                      ? Border.all(
                          color: cs.onSurface.withOpacity(0.35),
                          width: 1.2,
                        )
                      : null),
            ),
          ),
        );
      }),
    );
  }
}

