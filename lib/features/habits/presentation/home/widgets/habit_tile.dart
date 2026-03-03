import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:habit_dashboard/core/theme/app_styles.dart';
import 'package:habit_dashboard/features/habits/domain/habit.dart';

class HabitTile extends StatelessWidget {
  final Habit habit;

  /// Marks/unmarks *done today* (existing behavior).
  final VoidCallback onToggle;

  /// Toggles skip for *today* (rest day).
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

    // Minimal status chip (does not remove any existing actions).
    final statusLabel = doneToday
        ? 'DONE'
        : (skippedToday ? 'SKIPPED' : 'TODAY');

    final statusBg = doneToday
        ? cs.primary.withValues(alpha: 0.12)
        : (skippedToday
            ? cs.onSurface.withValues(alpha: 0.06)
            : cs.onSurface.withValues(alpha: 0.04));

    final statusFg = doneToday
        ? cs.primary
        : (skippedToday
            ? cs.onSurface.withValues(alpha: 0.75)
            : cs.onSurface.withValues(alpha: 0.75));

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          HapticFeedback.lightImpact();
          onToggle();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Icon(
                doneToday
                    ? Icons.check_circle
                    : (skippedToday
                        ? Icons.remove_circle_outline
                        : Icons.circle_outlined),
                size: 26,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            habit.title,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  decoration: doneToday
                                      ? TextDecoration.lineThrough
                                      : null,
                                ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusBg,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            statusLabel,
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.6,
                                  color: statusFg,
                                ),
                          ),
                        ),
                        if (goalReached || weeklyReached) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: cs.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              '🎉 reached',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                    _WeekDotsByDates(
                      last7Keys: last7,
                      completedDates: habit.completedDates,
                      skippedDates: habit.skippedDates,
                      activeColor: cs.primary,
                      todayBorderColor: cs.primary,
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 10,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          streak > 0 ? '🔥 $streak day streak' : 'No streak yet',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: secondaryColor),
                        ),
                        if (hasGoal)
                          Text(
                            '• $goalDone/${habit.targetDays}',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: secondaryColor),
                          ),
                        if (hasWeeklyGoal)
                          Text(
                            '• $thisWeekDone/${habit.weeklyTarget} this week',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: secondaryColor),
                          ),
                        if (habit.reminderMinutes != null)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.notifications_active_outlined,
                                  size: 16),
                              const SizedBox(width: 4),
                              Text(
                                _formatMinutes(habit.reminderMinutes!),
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(color: secondaryColor),
                              ),
                            ],
                          ),

                        // Skip/Unskip button (new UI feature) — keeps all other actions intact.
                        if (onToggleSkipToday != null)
                          OutlinedButton.icon(
                            onPressed: () {
                              HapticFeedback.selectionClick();
                              onToggleSkipToday!.call();
                            },
                            icon: Icon(
                              skippedToday
                                  ? Icons.undo_rounded
                                  : Icons.hotel_rounded,
                              size: 16,
                            ),
                            label: Text(
                              skippedToday ? 'Unskip today' : 'Skip today',
                            ),
                            style: OutlinedButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(999),
                              ),
                            ),
                          ),
                      ],
                    ),
                    if (hasWeeklyGoal) ...[
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: weeklyProgress,
                          minHeight: 8,
                        ),
                      ),
                    ] else if (hasGoal) ...[
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: goalProgress,
                          minHeight: 8,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Details',
                onPressed: () {
                  HapticFeedback.selectionClick();
                  onOpenDetails();
                },
                icon: const Icon(Icons.info_outline),
              ),
              IconButton(
                tooltip: 'Edit',
                onPressed: () {
                  HapticFeedback.selectionClick();
                  onEdit();
                },
                icon: const Icon(Icons.edit_outlined),
              ),
              IconButton(
                tooltip: 'Delete',
                onPressed: () {
                  HapticFeedback.selectionClick();
                  onDelete();
                },
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ),
        ),
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
                      ? cs.onSurface.withValues(alpha: 0.06)
                      : cs.onSurface.withValues(alpha: 0.12)),
              border: isToday
                  ? Border.all(color: todayBorderColor, width: 1.6)
                  : (isSkipped
                      ? Border.all(
                          color: cs.onSurface.withValues(alpha: 0.35),
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
