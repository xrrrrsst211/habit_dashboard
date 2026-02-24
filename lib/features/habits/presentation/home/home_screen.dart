import 'package:flutter/material.dart';
import 'package:habit_dashboard/core/constants/app_strings.dart';
import 'package:habit_dashboard/core/widgets/app_scaffold.dart';
import 'package:habit_dashboard/core/widgets/empty_state.dart';
import 'package:habit_dashboard/features/habits/data/habit_repository.dart';
import 'package:habit_dashboard/features/habits/domain/habit.dart';
import 'package:habit_dashboard/features/habits/presentation/add_habit/add_habit_screen.dart';

import 'widgets/daily_progress_card.dart';
import 'widgets/habit_tile.dart';
import 'widgets/today_header.dart';

enum _HomeMenuAction { markAllDone, resetToday }

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

Future<void> _openAddHabit() async {
final result = await Navigator.push<Map<String, dynamic>>(
context,
MaterialPageRoute(builder: (_) => const AddHabitScreen()),
);

if (result == null) return;

final title = (result['title'] as String?)?.trim() ?? '';
final targetDays = (result['targetDays'] as int?) ?? 0;

if (title.isEmpty) return;

await _repo.addHabit(title, targetDays);
if (!mounted) return;
setState(() {});
}

Future<void> _openEditHabit(Habit habit) async {
final result = await Navigator.push<Map<String, dynamic>>(
context,
MaterialPageRoute(
builder: (_) => AddHabitScreen(
initialTitle: habit.title,
initialTargetDays: habit.targetDays,
),
),
);

if (result == null) return;

final newTitle = (result['title'] as String?)?.trim() ?? '';
final newTargetDays = (result['targetDays'] as int?) ?? habit.targetDays;

if (newTitle.isNotEmpty && newTitle != habit.title) {
await _repo.renameHabit(habit.id, newTitle);
}
if (newTargetDays != habit.targetDays) {
await _repo.setTargetDays(habit.id, newTargetDays);
}

if (!mounted) return;
setState(() {});
}

Future<void> _confirmAndRemove(Habit habit) async {
final ok = await showDialog<bool>(
context: context,
builder: (context) => AlertDialog(
title: const Text('Delete habit?'),
content: Text('Delete “${habit.title}”?'),
actions: [
TextButton(
onPressed: () => Navigator.pop(context, false),
child: const Text('Cancel'),
),
FilledButton(
onPressed: () => Navigator.pop(context, true),
child: const Text('Delete'),
),
],
),
);

if (ok != true) return;

await _repo.removeHabit(habit.id);
if (!mounted) return;
setState(() {});
}

Future<void> _onMenuSelected(_HomeMenuAction action) async {
switch (action) {
case _HomeMenuAction.markAllDone:
await _repo.markAllDoneToday();
if (!mounted) return;
setState(() {});
break;

case _HomeMenuAction.resetToday:
await _repo.resetToday();
if (!mounted) return;
setState(() {});
break;
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

if (snap.hasError) {
return Scaffold(
body: Center(child: Text('Error: ${snap.error}')),
);
}

// ✅ СОРТИРОВКА: сначала невыполненные, потом выполненные
final sorted = List<Habit>.from(_habits)
..sort((a, b) {
final ad = a.doneToday ? 1 : 0;
final bd = b.doneToday ? 1 : 0;
if (ad != bd) return ad.compareTo(bd);
// если оба одинаковы по done — сортируем по названию
return a.title.toLowerCase().compareTo(b.title.toLowerCase());
});

final completed = sorted.where((h) => h.doneToday).length;

// ⚠️ AppScaffold у тебя без AppBar, поэтому меню добавим прямо в body
// Вставим мини-строку с TodayHeader + меню справа.
final headerRow = Row(
children: [
const Expanded(child: TodayHeader()),
PopupMenuButton<_HomeMenuAction>(
tooltip: 'Menu',
onSelected: _onMenuSelected,
itemBuilder: (context) => const [
PopupMenuItem(
value: _HomeMenuAction.markAllDone,
child: Text('Mark all done (today)'),
),
PopupMenuItem(
value: _HomeMenuAction.resetToday,
child: Text('Reset today'),
),
],
child: const Padding(
padding: EdgeInsets.symmetric(horizontal: 6, vertical: 6),
child: Icon(Icons.more_vert),
),
),
],
);

return AppScaffold(
title: AppStrings.today,
floatingActionButton: FloatingActionButton(
onPressed: _openAddHabit,
child: const Icon(Icons.add),
),
body: sorted.isEmpty
? const EmptyState(
title: AppStrings.emptyTitle,
subtitle: AppStrings.emptySubtitle,
)
: ListView(
padding: const EdgeInsets.only(bottom: 120),
children: [
const SizedBox(height: 8),
headerRow,
const SizedBox(height: 12),
DailyProgressCard(
completed: completed,
total: sorted.length,
),
const SizedBox(height: 12),
...sorted.map(
(h) => Padding(
padding: const EdgeInsets.only(bottom: 10),
child: HabitTile(
habit: h,
onToggle: () => _toggle(h.id),
onEdit: () => _openEditHabit(h),
onDelete: () => _confirmAndRemove(h),
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