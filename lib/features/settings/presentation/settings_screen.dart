import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:habit_dashboard/app/app.dart';
import 'package:habit_dashboard/core/widgets/app_scaffold.dart';
import 'package:habit_dashboard/core/widgets/polished_feedback.dart';
import 'package:habit_dashboard/features/about/about_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const String _prefHomeFilterKey = 'pref_home_filter';
  static const String _prefHomeSortKey = 'pref_home_sort';
  static const String _prefShowArchivedKey = 'pref_show_archived';
  static const String _prefExpandArchivedKey = 'pref_expand_archived';
  static const String _seenOnboardingKey = 'seen_onboarding_v1';

  bool _loading = true;
  bool _showArchived = false;
  bool _expandArchived = false;
  int _filterIndex = 0;
  int _sortIndex = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _filterIndex = prefs.getInt(_prefHomeFilterKey) ?? 0;
      _sortIndex = prefs.getInt(_prefHomeSortKey) ?? 0;
      _showArchived = prefs.getBool(_prefShowArchivedKey) ?? false;
      _expandArchived = prefs.getBool(_prefExpandArchivedKey) ?? false;
      _loading = false;
    });
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefHomeFilterKey, _filterIndex);
    await prefs.setInt(_prefHomeSortKey, _sortIndex);
    await prefs.setBool(_prefShowArchivedKey, _showArchived);
    await prefs.setBool(_prefExpandArchivedKey, _expandArchived);
  }

  Future<void> _setShowArchived(bool value) async {
    setState(() {
      _showArchived = value;
      if (!value) _expandArchived = false;
    });
    await _save();
  }

  Future<void> _setExpandArchived(bool value) async {
    setState(() => _expandArchived = value);
    await _save();
  }

  Future<void> _setFilter(int value) async {
    setState(() => _filterIndex = value);
    await _save();
  }

  Future<void> _setSort(int value) async {
    setState(() => _sortIndex = value);
    await _save();
  }

  Future<void> _resetOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_seenOnboardingKey, false);
    if (!mounted) return;
    showAppSnackBar(
      context,
      'Onboarding will appear again next launch.',
      icon: Icons.flag_outlined,
    );
  }

  Future<void> _openAbout(AboutSection section) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AboutScreen(initialSection: section),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final app = MyApp.of(context);
    final isDark =
        app?.isDarkMode ?? Theme.of(context).brightness == Brightness.dark;

    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return AppScaffold(
      title: 'Settings & preferences',
      subtitle:
          'Tune startup behavior, appearance, and launch-ready info without touching your habit data.',
      body: ListView(
        children: [
          _HeroSettingsCard(
            title: 'Your experience, your defaults',
            subtitle:
                'Pick how the app opens, how the dashboard behaves, and what’s ready for demos or Play Market presentation.',
            icon: Icons.tune_rounded,
          ),
          const SizedBox(height: 16),
          _SectionCard(
            title: 'Appearance',
            icon: Icons.palette_outlined,
            child: Column(
              children: [
                SwitchListTile.adaptive(
                  value: isDark,
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Dark mode'),
                  subtitle: Text(
                    isDark
                        ? 'Use the darker look across the app.'
                        : 'Use the lighter look across the app.',
                  ),
                  onChanged: (_) async {
                    await app?.toggleDarkMode();
                    if (!mounted) return;
                    setState(() {});
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _SectionCard(
            title: 'Home screen defaults',
            icon: Icons.home_outlined,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Choose how the dashboard should look when you open the app.',
                  style: tt.bodyMedium?.copyWith(
                    color: cs.onSurface.withValues(alpha: 0.72),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Default filter',
                  style: tt.labelLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<int>(
                  value: _filterIndex,
                  items: const [
                    DropdownMenuItem(value: 0, child: Text('All habits')),
                    DropdownMenuItem(value: 1, child: Text('Active only')),
                    DropdownMenuItem(
                      value: 2,
                      child: Text('Completed today'),
                    ),
                    DropdownMenuItem(value: 3, child: Text('Build habits')),
                    DropdownMenuItem(value: 4, child: Text('Quit habits')),
                  ],
                  onChanged: (value) {
                    if (value != null) _setFilter(value);
                  },
                ),
                const SizedBox(height: 14),
                Text(
                  'Default sort',
                  style: tt.labelLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<int>(
                  value: _sortIndex,
                  items: const [
                    DropdownMenuItem(value: 0, child: Text('Manual order')),
                    DropdownMenuItem(value: 1, child: Text('Highest streak')),
                    DropdownMenuItem(value: 2, child: Text('Name')),
                    DropdownMenuItem(value: 3, child: Text('Today status')),
                  ],
                  onChanged: (value) {
                    if (value != null) _setSort(value);
                  },
                ),
                const SizedBox(height: 10),
                SwitchListTile.adaptive(
                  value: _showArchived,
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Show archived section on startup'),
                  subtitle: const Text(
                    'Keep archived habits visible when the dashboard opens.',
                  ),
                  onChanged: _setShowArchived,
                ),
                SwitchListTile.adaptive(
                  value: _expandArchived,
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Expand archived section on startup'),
                  subtitle: const Text(
                    'Useful if you often restore or review older habits.',
                  ),
                  onChanged: _showArchived ? _setExpandArchived : null,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _SectionCard(
            title: 'Account',
            icon: Icons.person_outline_rounded,
            child: Column(
              children: const [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.lock_open_rounded),
                  title: Text('No login required'),
                  subtitle: Text(
                    'This release opens straight into your habit dashboard. Firebase auth can stay in the project for future updates, but it is not required for everyday use.',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _SectionCard(
            title: 'Launch & support',
            icon: Icons.rocket_launch_outlined,
            child: Column(
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.flag_circle_outlined),
                  title: const Text('Show onboarding again'),
                  subtitle: const Text(
                    'Useful before demos or if you want to review the intro flow.',
                  ),
                  trailing: TextButton(
                    onPressed: _resetOnboarding,
                    child: const Text('Reset'),
                  ),
                ),
                const Divider(height: 20),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.info_outline_rounded),
                  title: const Text('About'),
                  subtitle: const Text(
                    'App version, product summary, and support basics.',
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _openAbout(AboutSection.about),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.privacy_tip_outlined),
                  title: const Text('Privacy policy'),
                  subtitle: const Text(
                    'Check the local privacy policy included with the app.',
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _openAbout(AboutSection.privacy),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.support_agent_rounded),
                  title: const Text('Support'),
                  subtitle: const Text(
                    'Find the contact address and basic help info.',
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _openAbout(AboutSection.support),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: cs.primary.withValues(alpha: 0.14)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.check_circle_outline_rounded, color: cs.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'These preferences change only the app experience and startup defaults. Your habits, streaks, backups, and analytics stay untouched.',
                    style: tt.bodyMedium?.copyWith(
                      color: cs.onSurface.withValues(alpha: 0.84),
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _HeroSettingsCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const _HeroSettingsCard({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
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
        border: Border.all(color: cs.outline.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.12),
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
                Text(
                  title,
                  style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: tt.bodyMedium?.copyWith(
                    color: cs.onSurface.withValues(alpha: 0.78),
                    height: 1.35,
                  ),
                ),
              ],
            ),
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
        border: Border.all(color: cs.outline.withValues(alpha: 0.12)),
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
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}