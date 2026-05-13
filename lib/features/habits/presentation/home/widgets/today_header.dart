import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:habit_dashboard/core/theme/app_styles.dart';

class TodayHeader extends StatelessWidget {
  const TodayHeader({super.key});

  String _monthName(int m) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[(m - 1).clamp(0, 11)];
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final text = '${_monthName(now.month)} ${now.day}, ${now.year}';
    final displayName = FirebaseAuth.instance.currentUser?.displayName?.trim() ?? '';
    final title = displayName.isEmpty ? 'Today' : 'Today, $displayName';

    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          text,
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: context.secondaryTextStyle.color),
        ),
      ],
    );
  }
}
