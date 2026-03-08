import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:habit_dashboard/core/widgets/polished_feedback.dart';

class AboutScreen extends StatefulWidget {
  final AboutSection initialSection;

  const AboutScreen({
    super.key,
    this.initialSection = AboutSection.about,
  });

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

enum AboutSection { about, privacy, support }

class _AboutScreenState extends State<AboutScreen> {
  late final Future<String> _privacyFuture = rootBundle.loadString('assets/privacy_policy.md');

  Future<void> _copySupportEmail() async {
    await Clipboard.setData(const ClipboardData(text: 'support@habitdashboard.app'));
    if (!mounted) return;
    showAppSnackBar(
      context,
      'Support email copied',
      icon: Icons.mail_outline_rounded,
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final title = switch (widget.initialSection) {
      AboutSection.about => 'About Habit Dashboard',
      AboutSection.privacy => 'Privacy policy',
      AboutSection.support => 'Support',
    };

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: FutureBuilder<String>(
        future: _privacyFuture,
        builder: (context, snapshot) {
          final privacyText = snapshot.data ?? 'Loading privacy policy...';
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (widget.initialSection != AboutSection.privacy) ...[
                _HeroCard(
                  icon: Icons.check_circle_rounded,
                  title: 'Habit Dashboard',
                  subtitle: 'Build better routines. Quit bad ones.',
                  trailing: 'v1.0.0+1',
                ),
                const SizedBox(height: 16),
              ],
              if (widget.initialSection == AboutSection.about || widget.initialSection == AboutSection.support)
                _SectionCard(
                  title: 'Support',
                  icon: Icons.support_agent_rounded,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'For feedback, bug reports, or demo questions, use the support email below.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: cs.onSurface.withValues(alpha: 0.78),
                            ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: cs.surfaceContainerHighest.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: cs.outline.withValues(alpha: 0.14)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.mail_outline_rounded),
                            const SizedBox(width: 10),
                            const Expanded(
                              child: Text(
                                'support@habitdashboard.app',
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                            ),
                            TextButton(
                              onPressed: _copySupportEmail,
                              child: const Text('Copy'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              if (widget.initialSection == AboutSection.about) const SizedBox(height: 16),
              if (widget.initialSection == AboutSection.about)
                _SectionCard(
                  title: 'Product summary',
                  icon: Icons.apps_rounded,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _bullet(context, 'Track build habits and quit habits in one place.'),
                      _bullet(context, 'Use streaks, milestones, reminders, and analytics to stay consistent.'),
                      _bullet(context, 'Protect your data with backup, restore, and restore points.'),
                      _bullet(context, 'Review progress with heatmaps, trend storytelling, and exportable summaries.'),
                    ],
                  ),
                ),
              if (widget.initialSection != AboutSection.support) const SizedBox(height: 16),
              if (widget.initialSection == AboutSection.about || widget.initialSection == AboutSection.privacy)
                _SectionCard(
                  title: 'Privacy policy',
                  icon: Icons.privacy_tip_outlined,
                  child: SelectableText(
                    privacyText,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.45),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _bullet(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(
              Icons.check_circle_outline_rounded,
              size: 18,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String trailing;

  const _HeroCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            cs.primary.withValues(alpha: 0.12),
            cs.secondary.withValues(alpha: 0.06),
            cs.surface,
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: cs.outline.withValues(alpha: 0.14)),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(18),
            ),
            alignment: Alignment.center,
            child: Icon(icon, color: cs.primary, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: cs.onSurface.withValues(alpha: 0.78),
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: cs.outline.withValues(alpha: 0.14)),
            ),
            child: Text(trailing, style: const TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: cs.outline.withValues(alpha: 0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
