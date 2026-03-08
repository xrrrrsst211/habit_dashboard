import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:habit_dashboard/core/widgets/polished_feedback.dart';
import 'package:habit_dashboard/features/habits/domain/habit.dart';

class StoreShowcaseScreen extends StatelessWidget {
  final List<Habit> habits;
  final int rangeDays;

  const StoreShowcaseScreen({super.key, required this.habits, required this.rangeDays});

  String _keyFromDate(DateTime d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${d.year}-${two(d.month)}-${two(d.day)}';
  }

  int _currentStreak(Habit habit) => Habit.calcCurrentStreakPublic(habit.completedDates, habit.skippedDates);

  int _countWindow(Set<String> dates, int days) {
    int total = 0;
    final today = DateTime.now();
    for (int i = 0; i < days; i++) {
      final d = DateTime(today.year, today.month, today.day).subtract(Duration(days: i));
      if (dates.contains(_keyFromDate(d))) total++;
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final active = habits.where((h) => !h.archived).toList();
    final todayKey = _keyFromDate(DateTime.now());
    final doneToday = active.where((h) => h.completedDates.contains(todayKey)).length;
    final skippedToday = active.where((h) => h.skippedDates.contains(todayKey)).length;
    final quitHabits = active.where((h) => h.isQuit).toList();
    final buildHabits = active.where((h) => h.isBuild).toList();
    final leader = active.isEmpty ? null : ([...active]..sort((a, b) => _currentStreak(b).compareTo(_currentStreak(a)))).first;
    final quitLeader = quitHabits.isEmpty
        ? null
        : ([...quitHabits]..sort((a, b) => _countWindow(a.slipDates, rangeDays).compareTo(_countWindow(b.slipDates, rangeDays)))).first;

    const checklist = 'Screenshot ideas\n'
        '• Home dashboard with recovery focus\n'
        '• Stats & insights with heatmap and trends\n'
        '• Progress card share view\n'
        '• Quit-habit intelligence detail view\n'
        '• Add habit with build/quit setup';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Store screenshots'),
        actions: [
          IconButton(
            tooltip: 'Copy checklist',
            onPressed: () async {
              await Clipboard.setData(const ClipboardData(text: checklist));
              if (context.mounted) {
                showAppSnackBar(context, 'Screenshot checklist copied', icon: Icons.copy_rounded);
              }
            },
            icon: const Icon(Icons.copy_rounded),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: [
          Text(
            'Ready-made, clean layouts to screenshot for the Play Store listing or your portfolio.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: cs.onSurface.withOpacity(0.72)),
          ),
          const SizedBox(height: 16),
          RepaintBoundary(
            child: _ShowcaseCard(
              title: 'Habit Dashboard',
              subtitle: 'Build good habits, quit bad ones, and track momentum with smart recovery.',
              accent: cs.primary,
              chips: [
                '${active.length} active habits',
                '$doneToday done today',
                '$skippedToday rest today',
                '${buildHabits.length} build / ${quitHabits.length} quit',
              ],
            ),
          ),
          const SizedBox(height: 14),
          RepaintBoundary(
            child: _ShowcaseCard(
              title: 'Recovery & Quit Intelligence',
              subtitle: quitLeader == null
                  ? 'Slip tracking, recovery guidance, and comeback streaks for quit habits.'
                  : '${quitLeader.title} currently has the cleanest quit momentum across the last $rangeDays days.',
              accent: quitLeader?.color ?? cs.secondary,
              chips: const [
                'Slip analytics',
                'Recovery focus',
                'Avg clean run',
                'Danger window insights',
              ],
            ),
          ),
          const SizedBox(height: 14),
          RepaintBoundary(
            child: _ShowcaseCard(
              title: 'Progress Story',
              subtitle: leader == null
                  ? 'Exportable progress cards and trends help users stay motivated.'
                  : '${leader.title} leads with a ${_currentStreak(leader)} day streak.',
              accent: leader?.color ?? cs.tertiary,
              chips: const [
                'Exportable progress card',
                'Heatmap & trends',
                'Milestones',
                'Smart reminders',
              ],
            ),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: cs.outline.withOpacity(0.14)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Suggested capture order', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 10),
                for (final line in checklist.split('\n'))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(line, style: Theme.of(context).textTheme.bodyMedium),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ShowcaseCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color accent;
  final List<String> chips;

  const _ShowcaseCard({required this.title, required this.subtitle, required this.accent, required this.chips});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [accent.withOpacity(0.18), cs.surface, cs.surface],
        ),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: accent.withOpacity(0.18)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(Icons.auto_awesome_rounded, color: accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
                    const SizedBox(height: 4),
                    Text(
                      'Screenshot-ready layout',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(color: accent, fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(subtitle, style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.35)),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: chips
                .map(
                  (chip) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: accent.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: accent.withOpacity(0.14)),
                    ),
                    child: Text(chip, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700)),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}
