import 'dart:math';
import 'package:flutter/material.dart';
import 'package:habit_dashboard/features/habits/data/habit_repository.dart';
import 'package:habit_dashboard/features/habits/domain/habit.dart';

class HabitDetailScreen extends StatefulWidget {
final Habit habit;

const HabitDetailScreen({super.key, required this.habit});

@override
State<HabitDetailScreen> createState() => _HabitDetailScreenState();
}

class _HabitDetailScreenState extends State<HabitDetailScreen> {
final HabitRepository _repo = HabitRepository();

// отображаемый месяц (любой день внутри месяца)
late DateTime _month;

@override
void initState() {
super.initState();
final now = DateTime.now();
_month = DateTime(now.year, now.month, 1);
}

// -------- date helpers --------

String _keyFromDate(DateTime d) {
String two(int n) => n.toString().padLeft(2, '0');
return '${d.year}-${two(d.month)}-${two(d.day)}';
}

bool _sameDay(DateTime a, DateTime b) =>
a.year == b.year && a.month == b.month && a.day == b.day;

int _daysInMonth(DateTime month) {
final nextMonth = DateTime(month.year, month.month + 1, 1);
return nextMonth.subtract(const Duration(days: 1)).day;
}

/// weekday: Mon=1..Sun=7
/// convert to 0-based column where Mon=0..Sun=6
int _weekdayToCol(int weekday) => (weekday - 1) % 7;

int _calcStreak(Set<String> dates) {
final now = DateTime.now();
int count = 0;
while (true) {
final d = now.subtract(Duration(days: count));
final key = _keyFromDate(d);
if (!dates.contains(key)) break;
count++;
}
return count;
}

String _monthTitle(DateTime m) {
const names = [
'January', 'February', 'March', 'April', 'May', 'June',
'July', 'August', 'September', 'October', 'November', 'December'
];
return '${names[m.month - 1]} ${m.year}';
}

void _prevMonth() {
setState(() => _month = DateTime(_month.year, _month.month - 1, 1));
}

void _nextMonth() {
setState(() => _month = DateTime(_month.year, _month.month + 1, 1));
}

// -------- UI blocks --------

Widget _monthHeader() {
return Row(
children: [
IconButton(
tooltip: 'Previous month',
onPressed: _prevMonth,
icon: const Icon(Icons.chevron_left),
),
Expanded(
child: Center(
child: Text(
_monthTitle(_month),
style: Theme.of(context).textTheme.titleLarge,
),
),
),
IconButton(
tooltip: 'Next month',
onPressed: _nextMonth,
icon: const Icon(Icons.chevron_right),
),
],
);
}

Widget _weekdayRow() {
// пн..вс (коротко)
const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
return Padding(
padding: const EdgeInsets.symmetric(horizontal: 6),
child: Row(
children: List.generate(7, (i) {
return Expanded(
child: Center(
child: Text(
labels[i],
style: Theme.of(context)
.textTheme
.bodySmall
?.copyWith(color: Colors.black54, fontWeight: FontWeight.w700),
),
),
);
}),
),
);
}

List<DateTime?> _buildMonthCells(DateTime month) {
final first = DateTime(month.year, month.month, 1);
final daysCount = _daysInMonth(month);

final startCol = _weekdayToCol(first.weekday); // 0..6
final cells = <DateTime?>[];

// пустые ячейки до 1-го числа
for (int i = 0; i < startCol; i++) {
cells.add(null);
}

// дни месяца
for (int day = 1; day <= daysCount; day++) {
cells.add(DateTime(month.year, month.month, day));
}

// добиваем до полного количества недель (кратно 7)
while (cells.length % 7 != 0) {
cells.add(null);
}

return cells;
}

@override
Widget build(BuildContext context) {
// берем актуальную версию привычки из репо
final current = _repo.getHabits().firstWhere(
(h) => h.id == widget.habit.id,
orElse: () => widget.habit,
);

final streak = _calcStreak(current.completedDates);

final hasGoal = current.targetDays > 0;
final doneToGoal = hasGoal ? min(streak, current.targetDays) : 0;
final progress = hasGoal ? (doneToGoal / current.targetDays) : 0.0;

final now = DateTime.now();
final todayKey = _keyFromDate(now);

final cells = _buildMonthCells(_month);

return Scaffold(
appBar: AppBar(title: const Text('Habit details')),
body: ListView(
padding: const EdgeInsets.all(16),
children: [
Text(
current.title,
style: Theme.of(context).textTheme.headlineSmall,
),
const SizedBox(height: 6),
Text(
streak > 0 ? '🔥 $streak day streak' : 'No streak yet',
style: Theme.of(context).textTheme.bodyMedium?.copyWith(
color: Colors.black54,
),
),
const SizedBox(height: 12),

if (hasGoal) ...[
Text('Goal: $doneToGoal / ${current.targetDays} days'),
const SizedBox(height: 8),
ClipRRect(
borderRadius: BorderRadius.circular(999),
child: LinearProgressIndicator(
value: progress.clamp(0.0, 1.0),
minHeight: 10,
),
),
const SizedBox(height: 16),
],

// ✅ календарь месяца
_monthHeader(),
const SizedBox(height: 8),
_weekdayRow(),
const SizedBox(height: 10),

GridView.builder(
shrinkWrap: true,
physics: const NeverScrollableScrollPhysics(),
itemCount: cells.length,
gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
crossAxisCount: 7,
mainAxisSpacing: 8,
crossAxisSpacing: 8,
childAspectRatio: 1,
),
itemBuilder: (context, index) {
final date = cells[index];

if (date == null) {
return const SizedBox.shrink();
}

final key = _keyFromDate(date);
final done = current.completedDates.contains(key);
final isToday = _sameDay(date, now);
final isThisMonth = date.month == _month.month;

// (на всякий) скрытая защита, хотя date всегда текущий месяц
if (!isThisMonth) {
return const SizedBox.shrink();
}

return InkWell(
borderRadius: BorderRadius.circular(14),
onTap: () async {
await _repo.toggleDate(current.id, key);
if (!mounted) return;
setState(() {});
},
child: Container(
decoration: BoxDecoration(
borderRadius: BorderRadius.circular(14),
color: done
? Theme.of(context).colorScheme.primary
: Colors.black.withOpacity(0.06),
border: isToday
? Border.all(
color: Theme.of(context).colorScheme.primary,
width: 2,
)
: null,
),
child: Center(
child: Text(
'${date.day}',
style: TextStyle(
fontWeight: FontWeight.w800,
color: done ? Colors.white : Colors.black87,
),
),
),
),
);
},
),

const SizedBox(height: 18),
Text(
'Tip: tap any day to add/remove a check-in.',
style: Theme.of(context)
.textTheme
.bodySmall
?.copyWith(color: Colors.black54),
),
],
),
);
}
}