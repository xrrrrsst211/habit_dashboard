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

enum _HomeMenuAction { markAllDone, resetToday, toggleArchived }
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
bool _showArchived = false;

final TextEditingController _searchCtrl = TextEditingController();
String _query = '';

List<Habit> get _habits => _repo.getHabits();

@override
void dispose() {
_searchCtrl.dispose();
super.dispose();
}

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
final reminderMinutes = (result['reminderMinutes'] as int?);

if (title.isEmpty) return;

await _repo.addHabit(title, targetDays, reminderMinutes);
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
initialReminderMinutes: habit.reminderMinutes,
),
),
);

if (result == null) return;

final newTitle = (result['title'] as String?)?.trim() ?? '';
final newTargetDays = (result['targetDays'] as int?) ?? habit.targetDays;
final newReminder = (result['reminderMinutes'] as int?);

if (newTitle.isNotEmpty && newTitle != habit.title) {
await _repo.renameHabit(habit.id, newTitle);
}
if (newTargetDays != habit.targetDays) {
await _repo.setTargetDays(habit.id, newTargetDays);
}
if (newReminder != habit.reminderMinutes) {
await _repo.setReminderMinutes(habit.id, newReminder);
}

if (!mounted) return;
setState(() {});
}

void _openDetails(Habit habit) {
Navigator.push(
context,
MaterialPageRoute(builder: (_) => HabitDetailScreen(habit: habit)),
).then((_) {
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
case _HomeMenuAction.toggleArchived:
setState(() => _showArchived = !_showArchived);
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

Widget _searchBar() {
return Padding(
padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
child: TextField(
controller: _searchCtrl,
onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
decoration: InputDecoration(
hintText: 'Search habits...',
prefixIcon: const Icon(Icons.search),
suffixIcon: _query.isEmpty
? null
: IconButton(
tooltip: 'Clear',
onPressed: () {
_searchCtrl.clear();
setState(() => _query = '');
},
icon: const Icon(Icons.close),
),
border: OutlineInputBorder(
borderRadius: BorderRadius.circular(14),
),
),
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
final base = _showArchived ? _habits : _habits.where((h) => !h.archived).toList();

// Keep current order; don't sort now (drag&drop defines order)
final list = List<Habit>.from(base);

// Apply filter + search without changing underlying order
final visible = list.where((h) {
final doneToday = h.completedDates.contains(todayKey);

final passFilter = switch (_filter) {
_HabitFilter.all => true,
_HabitFilter.active => !doneToday,
_HabitFilter.completed => doneToday,
};
if (!passFilter) return false;

if (_query.isEmpty) return true;
return h.title.toLowerCase().contains(_query);
}).toList();

final visibleIds = visible.map((h) => h.id).toList();

// Progress is based on visible base list (not filtered list) — feels consistent
final completed = list.where((h) => h.completedDates.contains(todayKey)).length;

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
itemBuilder: (context) => [
const PopupMenuItem(
value: _HomeMenuAction.markAllDone,
child: Text('Mark all done (today)'),
),
const PopupMenuItem(
value: _HomeMenuAction.resetToday,
child: Text('Reset today'),
),
PopupMenuItem(
value: _HomeMenuAction.toggleArchived,
child: Text(_showArchived ? 'Hide archived' : 'Show archived'),
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
body: list.isEmpty
? const EmptyState(
title: AppStrings.emptyTitle,
subtitle: AppStrings.emptySubtitle,
)
: Column(
children: [
const SizedBox(height: 8),
Padding(
padding: const EdgeInsets.symmetric(horizontal: 12),
child: headerRow,
),
const SizedBox(height: 10),
_searchBar(),
_filterChips(),
const SizedBox(height: 12),
Padding(
padding: const EdgeInsets.symmetric(horizontal: 12),
child: DailyProgressCard(
completed: completed,
total: list.length,
),
),
const SizedBox(height: 12),

Expanded(
child: visible.isEmpty
? Center(
child: Text(
_query.isEmpty ? 'Nothing here 👀' : 'No matches for “$_query”',
),
)
: ReorderableListView.builder(
padding: const EdgeInsets.fromLTRB(12, 0, 12, 120),
itemCount: visible.length,
onReorder: (oldIndex, newIndex) async {
await _repo.reorderByIds(oldIndex, newIndex, visibleIds);
if (!mounted) return;
setState(() {});
},
itemBuilder: (context, index) {
final h = visible[index];

return Container(
key: ValueKey('habit_${h.id}'),
margin: const EdgeInsets.only(bottom: 10),
child: Row(
children: [
ReorderableDragStartListener(
index: index,
child: const Padding(
padding: EdgeInsets.only(right: 8),
child: Icon(Icons.drag_handle),
),
),
Expanded(
child: HabitTile(
habit: h,
onToggle: () => _toggle(h.id),
onOpenDetails: () => _openDetails(h),
onEdit: () => _openEditHabit(h),
onDelete: () => _confirmAndRemoveWithUndo(h),
),
),
],
),
);
},
),
),
],
),
);
},
);
}
}
