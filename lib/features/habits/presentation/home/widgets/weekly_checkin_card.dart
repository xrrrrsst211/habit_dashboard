import 'package:flutter/material.dart';

class WeeklyCheckInCard extends StatelessWidget {
  /// 7 values (Mon..Sun) in range 0..1 where 1 means all habits done that day.
  final List<double> dayRatios;

  /// How many days this week have at least one completion.
  final int checkInDays;

  const WeeklyCheckInCard({
    super.key,
    required this.dayRatios,
    required this.checkInDays,
  }) : assert(dayRatios.length == 7);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'This week',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: cs.primary.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '$checkInDays/7',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Days where you completed at least one habit.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(7, (i) {
                final r = dayRatios[i].clamp(0.0, 1.0);
                final isEmpty = r <= 0.0001;

                final Color fill = cs.primary.withOpacity(0.15 + (0.75 * r));
                final Color border = isEmpty
                    ? cs.outlineVariant
                    : cs.primary.withOpacity(0.40);

                return Column(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOut,
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isEmpty ? cs.surface : fill,
                        border: Border.all(color: border, width: 1.2),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][i],
                      style: Theme.of(context)
                          .textTheme
                          .labelSmall
                          ?.copyWith(color: cs.onSurfaceVariant),
                    ),
                  ],
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}