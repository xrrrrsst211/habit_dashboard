import 'package:flutter/material.dart';
import '../../../../../core/constants/app_strings.dart';

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
    final value = total == 0 ? 0.0 : completed / total;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppStrings.dailyProgress,
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            Text('$completed / $total habits completed'),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(value: value, minHeight: 10),
            ),
          ],
        ),
      ),
    );
  }
}