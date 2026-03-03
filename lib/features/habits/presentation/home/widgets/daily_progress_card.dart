import 'package:flutter/material.dart';
import 'package:habit_dashboard/core/constants/app_strings.dart';

class DailyProgressCard extends StatelessWidget {
  final int completed;
  final int total;

  const DailyProgressCard({
    super.key,
    required this.completed,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final subtitle = AppStrings.progressSubtitle
        .replaceAll('{done}', completed.toString())
        .replaceAll('{total}', total.toString());

    final progress = total == 0 ? 0.0 : (completed / total).clamp(0.0, 1.0);

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
                    AppStrings.progressTitle,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    // Keep compatibility across Flutter versions.
                    color: cs.primary.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '$completed/$total',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(minHeight: 8, value: progress),
            ),
          ],
        ),
      ),
    );
  }
}