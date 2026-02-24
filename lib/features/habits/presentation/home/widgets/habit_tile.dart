import 'dart:math';
import 'package:flutter/material.dart';
import 'package:habit_dashboard/features/habits/domain/habit.dart';

class HabitTile extends StatelessWidget {
  final Habit habit;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const HabitTile({
    super.key,
    required this.habit,
    required this.onToggle,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final done = habit.doneToday;
    final cs = Theme.of(context).colorScheme;

    final filled = habit.streak.clamp(0, 7);

    final hasGoal = habit.targetDays > 0;
    final goalDone = hasGoal ? min(habit.streak, habit.targetDays) : 0;
    final goalProgress = hasGoal ? (goalDone / habit.targetDays).clamp(0.0, 1.0) : 0.0;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onToggle,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Icon(done ? Icons.check_circle : Icons.circle_outlined, size: 26),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      habit.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            decoration: done ? TextDecoration.lineThrough : null,
                          ),
                    ),
                    const SizedBox(height: 6),

                    _WeekDots(
                      filledCount: filled,
                      activeColor: cs.primary,
                      todayBorderColor: cs.primary,
                    ),

                    const SizedBox(height: 6),

                    // 🔥 streak line + goal line
                    Row(
                      children: [
                        Text(
                          habit.streak > 0 ? '🔥 ${habit.streak} day streak' : 'No streak yet',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: Colors.black54),
                        ),
                        const SizedBox(width: 10),
                        if (hasGoal)
                          Text(
                            '• $goalDone/${habit.targetDays}',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: Colors.black54),
                          ),
                      ],
                    ),

                    if (hasGoal) ...[
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
                tooltip: 'Edit',
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined),
              ),
              IconButton(
                tooltip: 'Delete',
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WeekDots extends StatelessWidget {
  final int filledCount; // 0..7
  final Color activeColor;
  final Color todayBorderColor;

  const _WeekDots({
    required this.filledCount,
    required this.activeColor,
    required this.todayBorderColor,
  });

  @override
  Widget build(BuildContext context) {
    const dotSize = 10.0;
    const gap = 6.0;

    final startFilledIndex = 7 - filledCount;

    return Row(
      children: List.generate(7, (index) {
        final isToday = index == 6;
        final isFilled = filledCount > 0 && index >= startFilledIndex;

        return Padding(
          padding: EdgeInsets.only(right: index == 6 ? 0 : gap),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            width: dotSize,
            height: dotSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isFilled ? activeColor : Colors.black.withOpacity(0.12),
              border: isToday ? Border.all(color: todayBorderColor, width: 1.6) : null,
            ),
          ),
        );
      }),
    );
  }
}