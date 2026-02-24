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
  late final Future<void> _initFuture = _repo.init();

  List<Habit> get _habits => _repo.getHabits();

  Future<void> _toggle(String id) async {
    await _repo.toggleHabit(id);
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _remove(String id) async {
    await _repo.removeHabit(id);
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _openAddHabit() async {
    final value = await Navigator.pushNamed(context, AppRoutes.addHabit);
    if (value is String && value.trim().isNotEmpty) {
      await _repo.addHabit(value.trim());
      if (!mounted) return;
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _initFuture,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final completed = _habits.where((h) => h.doneToday).length;

        return AppScaffold(
          title: AppStrings.today,
          floatingActionButton: FloatingActionButton(
            onPressed: _openAddHabit,
            child: const Icon(Icons.add),
          ),
          body: _habits.isEmpty
              ? const EmptyState(
                  title: AppStrings.emptyTitle,
                  subtitle: AppStrings.emptySubtitle,
                )
              : ListView(
                  padding: const EdgeInsets.only(bottom: 120),
                  children: [
                    const SizedBox(height: 8),
                    const TodayHeader(),
                    const SizedBox(height: 12),
                    DailyProgressCard(
                      completed: completed,
                      total: _habits.length,
                    ),
                    const SizedBox(height: 12),
                    ..._habits.map(
                      (h) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: HabitTile(
                          habit: h,
                          onToggle: () => _toggle(h.id),
                          onDelete: () => _remove(h.id),
                        ),
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }
}