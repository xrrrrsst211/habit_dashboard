import 'package:flutter/material.dart';

class TodayHeader extends StatelessWidget {
  const TodayHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final text = '${now.day}.${now.month}.${now.year}';

    return Row(
      children: [
        Text('Your day', style: Theme.of(context).textTheme.titleLarge),
        const Spacer(),
        Text(text, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}