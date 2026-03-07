import 'package:flutter/material.dart';
import 'package:habit_dashboard/core/theme/app_styles.dart';

class EmptyState extends StatelessWidget {
  final String title;
  final String subtitle;

  const EmptyState({
    super.key,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                cs.primary.withValues(alpha: 0.08),
                cs.surface,
              ],
            ),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: cs.outline.withValues(alpha: 0.10)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(22),
                ),
                alignment: Alignment.center,
                child: Icon(
                  Icons.inbox_outlined,
                  size: 34,
                  color: cs.primary,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: t.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: t.bodyMedium?.copyWith(
                  color: context.secondaryTextStyle.color,
                  height: 1.35,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
