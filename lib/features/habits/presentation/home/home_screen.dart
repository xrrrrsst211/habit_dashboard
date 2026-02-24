import 'package:flutter/material.dart';
import 'package:habit_dashboard/core/constants/app_strings.dart';
import 'package:habit_dashboard/core/widgets/app_scaffold.dart';
import 'package:habit_dashboard/core/widgets/empty_state.dart';
import 'package:habit_dashboard/features/habits/data/habit_repository.dart';
import 'package:habit_dashboard/features/habits/domain/habit.dart';
import 'package:habit_dashboard/features/habits/presentation/add_habit/add_habit_screen.dart';
import 'package:habit_dashboard/features/habits/presentation/habit_detail/habit_detail_screen.dart';
import 'package:habit_dashboard/features/habits/presentation/stats/stats_screen.dart';

import 'widgets/daily_progress_card.dart';
import 'widgets/habit_tile.dart';
import 'widgets/today_header.dart';

enum _HomeMenuAction { markAllDone, resetToday }
enum _HabitFilter { all, active, completed }

class HomeScreen extends StatefulWidget {
const HomeScreen({super.key});

@override
State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
final HabitRepository _repo = HabitRepository();
late final Future<void> _initFuture = _repo.init();

_HabitFilter _filter = _HabitFilter.all;

List<Habit> get _habits => _repo.getHabits();

String _todayKey() {
final now = DateTime.now();
String two(int n) => n.toString().padLeft(2, '0');
return '${now.year}-${two(now.month)}-${two(now.day)}';
}

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

void _openDetails(Habit habit) {
Navigator.push(
context,
MaterialPageRoute(builder: (_) => HabitDetailScreen(habit: habit)),
).then((_) {
// вернулись назад -> обновим UI (на случай если меняли даты)
if (!mounted) return;
setState(() {});
});
}

Future<void> _confirmAndRemoveWithUndo(Habit habit) async {
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

final currentList = List<Habit>.from(_repo.getHabits());
final index = currentList.indexWhere((h) => h.id == habit.id);

await _repo.removeHabit(habit.id);
if (!mounted) return;
setState(() {});

ScaffoldMessenger.of(context).clearSnackBars();

final snack = SnackBar(
content: Text('Deleted “${habit.title}”'),
duration: const Duration(seconds: 4),
action: SnackBarAction(
label: 'UNDO',
onPressed: () async {
await _repo.insertHabitAt(index < 0 ? 0 : index, habit);
if (!mounted) return;
setState(() {});
},
),
);

ScaffoldMessenger.of(context).showSnackBar(snack);
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

void _openStats() {
Navigator.push(
context,
MaterialPageRoute(builder: (_) => StatsScreen(habits: List<Habit>.from(_habits))),
);
}

Widget _filterChips() {
Widget chip(String label, _HabitFilter value) {
final selected = _filter == value;
return ChoiceChip(
label: Text(label),
selected: selected,
onSelected: (_) => setState(() => _filter = value),
);
}

return Padding(
padding: const EdgeInsets.symmetric(horizontal: 12),
child: Wrap(
spacing: 8,
runSpacing: 8,
children: [
chip('All', _HabitFilter.all),
chip('Active', _HabitFilter.active),
chip('Completed', _HabitFilter.completed),
],
),
);
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

final todayKey = _todayKey();

final sorted = List<Habit>.from(_habits)
..sort((a, b) {
final ad = a.completedDates.contains(todayKey) ? 1 : 0;
final bd = b.completedDates.contains(todayKey) ? 1 : 0;
if (ad != bd) return ad.compareTo(bd);
return a.title.toLowerCase().compareTo(b.title.toLowerCase());
});

final filtered = sorted.where((h) {
final doneToday = h.completedDates.contains(todayKey);
switch (_filter) {
case _HabitFilter.all:
return true;
case _HabitFilter.active:
return !doneToday;
case _HabitFilter.completed:
return doneToday;
}
}).toList();

final completed =
sorted.where((h) => h.completedDates.contains(todayKey)).length;

final headerRow = Row(
children: [
const Expanded(child: TodayHeader()),
IconButton(
tooltip: 'Stats',
onPressed: _openStats,
icon: const Icon(Icons.bar_chart_rounded),
),
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
const SizedBox(height: 10),
_filterChips(),
const SizedBox(height: 12),
DailyProgressCard(
completed: completed,
total: sorted.length,
),
const SizedBox(height: 12),
if (filtered.isEmpty)
const Padding(
padding:
EdgeInsets.symmetric(horizontal: 16, vertical: 24),
child: Text('Nothing here 👀'),
)
else
...filtered.map(
(h) => Padding(
padding: const EdgeInsets.only(bottom: 10),
child: HabitTile(
habit: h,
onToggle: () => _toggle(h.id),
onOpenDetails: () => _openDetails(h),
onEdit: () => _openEditHabit(h),
onDelete: () => _confirmAndRemoveWithUndo(h),
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
