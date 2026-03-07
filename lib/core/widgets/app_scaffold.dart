import 'package:flutter/material.dart';

class AppScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final Widget? floatingActionButton;
  final bool showDefaultHeader;

  const AppScaffold({
    super.key,
    required this.title,
    required this.body,
    this.floatingActionButton,
    this.showDefaultHeader = true,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
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
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
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
