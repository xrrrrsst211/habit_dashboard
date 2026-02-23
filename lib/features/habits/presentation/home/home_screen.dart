import 'package:flutter/material.dart';

import 'package:habit_dashboard/app/routes.dart';
import 'package:habit_dashboard/core/constants/app_strings.dart';
import 'package:habit_dashboard/core/widgets/app_scaffold.dart';
import 'package:habit_dashboard/core/widgets/empty_state.dart';

import 'package:habit_dashboard/features/habits/data/habit_repository.dart';
import 'package:habit_dashboard/features/habits/domain/habit.dart';

import 'widgets/daily_progress_card.dart';
import 'widgets/habit_tile.dart';
import 'widgets/today_header.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final HabitRepository _repo = HabitRepository();

  List<Habit> get _habits => _repo.getHabits();

  void _toggle(String id) {
    setState(() => _repo.toggleHabit(id));
  }

  void _openAddHabit() {
    Navigator.pushNamed(context, AppRoutes.addHabit).then((value) {
      // add_habit_screen возвращает String? (название привычки)
      if (value is String && value.trim().isNotEmpty) {
        setState(() => _repo.addHabit(value.trim()));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final completed = _habits.where((h) => h.doneToday).length;
    final total = _habits.length;

    return AppScaffold(
      title: AppStrings.appTitle,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: total == 0
            ? EmptyState(
                title: 'No habits yet',
                subtitle: 'Add your first habit and start tracking.',
                icon: Icons.checklist_rounded,
                action: FilledButton.icon(
                  onPressed: _openAddHabit,
                  icon: const Icon(Icons.add),
                  label: const Text(AppStrings.addHabit),
                ),
              )
            : ListView(
                children: [
                  const TodayHeader(),
                  const SizedBox(height: 12),
                  DailyProgressCard(completed: completed, total: total),
                  const SizedBox(height: 12),
                  ..._habits.map(
                    (h) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: HabitTile(
                        title: h.title,
                        done: h.doneToday,
                        onToggle: () => _toggle(h.id),
                      ),
                    ),
                  ),
                  const SizedBox(height: 80),
                ],
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddHabit,
        child: const Icon(Icons.add),
      ),
    );
  }
}