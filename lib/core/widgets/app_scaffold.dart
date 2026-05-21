import 'package:flutter/material.dart';
import 'package:habit_dashboard/core/localization/app_localizations.dart';

class AppScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final Widget? floatingActionButton;
  final bool showDefaultHeader;
  final Widget? trailing;
  final String? subtitle;

  const AppScaffold({
    super.key,
    required this.title,
    required this.body,
    this.floatingActionButton,
    this.showDefaultHeader = true,
    this.trailing,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: cs.surface,
      floatingActionButton: floatingActionButton,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Column(
            children: [
              if (showDefaultHeader) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        cs.primary.withValues(alpha: 0.10),
                        cs.secondary.withValues(alpha: 0.05),
                        cs.surface,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: cs.outline.withValues(alpha: 0.10)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title.tr,
                              style: tt.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            if (subtitle != null) ...[
                              const SizedBox(height: 6),
                              Text(
                                subtitle!.tr,
                                style: tt.bodyMedium?.copyWith(
                                  color: cs.onSurface.withValues(alpha: 0.74),
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (trailing != null) ...[
                        const SizedBox(width: 12),
                        trailing!,
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 14),
              ],
              Expanded(child: body),
            ],
          ),
        ),
      ),
    );
  }
}
