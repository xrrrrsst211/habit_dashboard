import 'dart:math';
import 'package:flutter/material.dart';
import 'package:habit_dashboard/features/habits/domain/habit.dart';

class HabitTile extends StatelessWidget {
final Habit habit;
final VoidCallback onToggle;
final VoidCallback onDelete;
final VoidCallback onEdit;
final VoidCallback onOpenDetails;

const HabitTile({
super.key,
required this.habit,
required this.onToggle,
required this.onDelete,
required this.onEdit,
required this.onOpenDetails,
});

@override
Widget build(BuildContext context) {
final cs = Theme.of(context).colorScheme;

final today = _todayKey();
final doneToday = habit.completedDates.contains(today);

final streak = _calcStreak(habit.completedDates);
final last7 = _last7Keys(); // [6 days ago ... today]

final hasGoal = habit.targetDays > 0;
final goalDone = hasGoal ? min(streak, habit.targetDays) : 0;
final goalProgress =
hasGoal ? (goalDone / habit.targetDays).clamp(0.0, 1.0) : 0.0;

return Card(
child: InkWell(
borderRadius: BorderRadius.circular(16),
onTap: onToggle,
child: Padding(
padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
child: Row(
children: [
Icon(doneToday ? Icons.check_circle : Icons.circle_outlined,
size: 26),
const SizedBox(width: 12),
Expanded(
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text(
habit.title,
style:
Theme.of(context).textTheme.titleMedium?.copyWith(
decoration: doneToday
? TextDecoration.lineThrough
: null,
),
),
const SizedBox(height: 6),

_WeekDotsByDates(
last7Keys: last7,
completedDates: habit.completedDates,
activeColor: cs.primary,
todayBorderColor: cs.primary,
),

const SizedBox(height: 6),

Row(
children: [
Text(
streak > 0
? '🔥 $streak day streak'
: 'No streak yet',
style: Theme.of(context)
.textTheme
.bodySmall
?.copyWith(color: Colors.black54),
),
const SizedBox(width: 10),
if (hasGoal)
Text(
'• $goalDone/${habit.targetDays}',
style: Theme.of(context)
.textTheme
.bodySmall
?.copyWith(color: Colors.black54),
),
],
),

if (hasGoal) ...[
const SizedBox(height: 8),
ClipRRect(
borderRadius: BorderRadius.circular(999),
child: LinearProgressIndicator(
value: goalProgress,
minHeight: 8,
),
),
],
],
),
),

IconButton(
tooltip: 'Details',
onPressed: onOpenDetails,
icon: const Icon(Icons.info_outline),
),
IconButton(
tooltip: 'Edit',
onPressed: onEdit,
icon: const Icon(Icons.edit_outlined),
),
IconButton(
tooltip: 'Delete',
onPressed: onDelete,
icon: const Icon(Icons.delete_outline),
),
],
),
),
),
);
}

// -------- date helpers --------

String _todayKey() => _keyFromDate(DateTime.now());

List<String> _last7Keys() {
final now = DateTime.now();
return List.generate(7, (i) {
final d = now.subtract(Duration(days: 6 - i));
return _keyFromDate(d);
});
}

String _keyFromDate(DateTime d) {
String two(int n) => n.toString().padLeft(2, '0');
return '${d.year}-${two(d.month)}-${two(d.day)}';
}

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
}

class _WeekDotsByDates extends StatelessWidget {
final List<String> last7Keys; // oldest -> today
final Set<String> completedDates;
final Color activeColor;
final Color todayBorderColor;

const _WeekDotsByDates({
required this.last7Keys,
required this.completedDates,
required this.activeColor,
required this.todayBorderColor,
});

@override
Widget build(BuildContext context) {
const dotSize = 10.0;
const gap = 6.0;

return Row(
children: List.generate(7, (index) {
final key = last7Keys[index];
final isToday = index == 6;
final isFilled = completedDates.contains(key);

return Padding(
padding: EdgeInsets.only(right: index == 6 ? 0 : gap),
child: AnimatedContainer(
duration: const Duration(milliseconds: 220),
width: dotSize,
height: dotSize,
decoration: BoxDecoration(
shape: BoxShape.circle,
color: isFilled ? activeColor : Colors.black.withOpacity(0.12),
border: isToday
? Border.all(color: todayBorderColor, width: 1.6)
: null,
),
),
);
}),
);
}
}