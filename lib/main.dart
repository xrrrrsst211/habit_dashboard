import 'package:flutter/material.dart';

void main() => runApp(const HabitDashboardApp());

class HabitDashboardApp extends StatelessWidget {
  const HabitDashboardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'DailyHabit Dashboard',
      theme: ThemeData(useMaterial3: true),
      home: const DashboardScreen(),
    );
  }
}

class Habit {
  final String title;
  bool done;
  Habit(this.title, this.done);
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final List<Habit> habits = [
    Habit('Drink water', false),
    Habit('Workout', true),
    Habit('Read 20 minutes', false),
    Habit('Meditate', false),
  ];

  int get doneCount => habits.where((h) => h.done).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Today'),
        centerTitle: false,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        child: const Icon(Icons.add),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _ProgressCard(done: doneCount, total: habits.length),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.separated(
                itemCount: habits.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, i) {
                  final h = habits[i];
                  return _HabitTile(
                    title: h.title,
                    done: h.done,
                    onToggle: () => setState(() => h.done = !h.done),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  final int done;
  final int total;
  const _ProgressCard({required this.done, required this.total});

  @override
  Widget build(BuildContext context) {
    final progress = total == 0 ? 0.0 : done / total;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Daily progress',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text('$done / $total habits completed'),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(value: progress, minHeight: 10),
          ),
        ],
      ),
    );
  }
}

class _HabitTile extends StatelessWidget {
  final String title;
  final bool done;
  final VoidCallback onToggle;

  const _HabitTile({
    required this.title,
    required this.done,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onToggle,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            Icon(done ? Icons.check_circle : Icons.radio_button_unchecked),
          ],
        ),
      ),
    );
  }
}