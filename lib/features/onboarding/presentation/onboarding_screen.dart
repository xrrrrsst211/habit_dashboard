import 'package:flutter/material.dart';

import 'package:habit_dashboard/features/habits/data/habit_repository.dart';
import 'package:habit_dashboard/features/habits/presentation/add_habit/add_habit_screen.dart';

class OnboardingScreen extends StatefulWidget {
  final Future<void> Function() onFinished;

  const OnboardingScreen({
    super.key,
    required this.onFinished,
  });

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  bool _busy = false;

  Future<void> _startWithExamples() async {
    if (_busy) return;
    setState(() => _busy = true);

    final repo = HabitRepository();
    await repo.init();
    await repo.seedStarterHabitsIfEmpty();
    await widget.onFinished();

    if (!mounted) return;
    setState(() => _busy = false);
  }

  Future<void> _createFirstHabit() async {
    if (_busy) return;
    setState(() => _busy = true);

    final repo = HabitRepository();
    await repo.init();

    if (!mounted) return;
    final result = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(builder: (_) => const AddHabitScreen()),
    );

    if (result == null) {
      if (mounted) setState(() => _busy = false);
      return;
    }

    await repo.addHabit(
      result['title'] as String,
      result['type'] as String,
      result['targetDays'] as int,
      result['weeklyTarget'] as int,
      result['reminderMinutes'] as int?,
      (result['notes'] as String?) ?? '',
      result['iconKey'] as String,
      result['colorValue'] as int,
    );
    await widget.onFinished();

    if (!mounted) return;
    setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 108,
                  height: 108,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: cs.primary.withOpacity(0.18),
                        blurRadius: 28,
                        offset: const Offset(0, 14),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: Image.asset(
                      'assets/branding/app_mark.png',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: cs.primary,
                        child: const Icon(
                          Icons.check_circle_rounded,
                          size: 56,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              Text(
                'Welcome to Habit Dashboard',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: 10),
              Text(
                'A cleaner start for building good habits, quitting bad ones, and tracking streaks without clutter.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: cs.onSurface.withOpacity(0.76),
                      height: 1.35,
                    ),
              ),
              const SizedBox(height: 22),
              _FeatureCard(
                icon: Icons.trending_up_rounded,
                title: 'Build habits',
                text: 'Track routines like water, workouts, reading, sleep, coding, or study goals.',
              ),
              const SizedBox(height: 12),
              _FeatureCard(
                icon: Icons.shield_outlined,
                title: 'Quit habits',
                text: 'Use clean streaks for smoking, alcohol, vaping, sugar, junk food, and more.',
              ),
              const SizedBox(height: 12),
              _FeatureCard(
                icon: Icons.insights_rounded,
                title: 'Stay motivated',
                text: 'History, milestones, reminders, notes, archive, and backup are already built in.',
              ),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cs.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: cs.primary.withOpacity(0.12)),
                ),
                child: Text(
                  'Start clean with your own first habit, or load a few example habits to explore the app faster.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.35),
                ),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _busy ? null : _createFirstHabit,
                  icon: _busy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.add_rounded),
                  label: const Text('Create first habit'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _busy ? null : _startWithExamples,
                  icon: const Icon(Icons.auto_awesome_rounded),
                  label: const Text('Start with examples'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String text;

  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface.withOpacity(0.72),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.outline.withOpacity(0.14)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: cs.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: cs.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  text,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: cs.onSurface.withOpacity(0.76),
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
