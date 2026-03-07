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

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.98, end: 1.0),
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      builder: (context, scale, child) => Transform.scale(scale: scale, child: child),
      child: Card(
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
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 240),
                      transitionBuilder: (child, animation) => FadeTransition(
                        opacity: animation,
                        child: ScaleTransition(scale: animation, child: child),
                      ),
                      child: Text(
                        '$checkInDays/7',
                        key: ValueKey<int>(checkInDays),
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
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
                      ? cs.outline.withOpacity(0.28)
                      : cs.primary.withOpacity(0.40);

                  return TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: 1),
                    duration: Duration(milliseconds: 220 + (i * 35)),
                    curve: Curves.easeOutCubic,
                    builder: (context, t, child) => Opacity(
                      opacity: t,
                      child: Transform.translate(
                        offset: Offset(0, (1 - t) * 10),
                        child: child,
                      ),
                    ),
                    child: Column(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 260),
                          curve: Curves.easeOutCubic,
                          width: 12 + (r * 4),
                          height: 12 + (r * 4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isEmpty ? cs.surface : fill,
                            border: Border.all(color: border, width: 1.2),
                            boxShadow: isEmpty
                                ? null
                                : [
                                    BoxShadow(
                                      color: cs.primary.withOpacity(0.10 + (0.10 * r)),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
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
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
