import 'dart:convert';
import 'dart:math';

import 'package:habit_dashboard/features/habits/domain/habit.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HabitRepository {
static const _storageKey = 'habits_v1';

final List<Habit> _habits = [];
bool _initialized = false;

Future<void> init() async {
if (_initialized) return;

final prefs = await SharedPreferences.getInstance();
final raw = prefs.getString(_storageKey);

if (raw == null || raw.trim().isEmpty) {
_habits
..clear()
..addAll([
Habit(
id: '1',
title: 'Drink water',
completedDates: <String>{},
targetDays: 21,
archived: false,
reminderMinutes: null,
),
Habit(
id: '2',
title: 'Workout',
completedDates: <String>{},
targetDays: 30,
archived: false,
reminderMinutes: null,
),
Habit(
id: '3',
title: 'Read 20 minutes',
completedDates: <String>{},
targetDays: 0,
archived: false,
reminderMinutes: null,
),
Habit(
id: '4',
title: 'Meditate',
completedDates: <String>{},
targetDays: 14,
archived: false,
reminderMinutes: null,
),
]);

await _save(prefs);
_initialized = true;
return;
}

final decoded = jsonDecode(raw);
if (decoded is List) {
_habits
..clear()
..addAll(
decoded
.whereType<Map>()
.map((m) => Habit.fromJson(Map<String, dynamic>.from(m))),
);
}

// после миграций — сохраняем
await _save(prefs);
_initialized = true;
}

List<Habit> getHabits() => List.unmodifiable(_habits);

// ---------- core actions ----------

Future<void> toggleHabit(String id) async {
final i = _habits.indexWhere((h) => h.id == id);
if (i == -1) return;

final prefs = await SharedPreferences.getInstance();
final today = _todayKey();

final current = _habits[i];
final newDates = Set<String>.from(current.completedDates);

if (newDates.contains(today)) {
newDates.remove(today);
} else {
newDates.add(today);
}

_habits[i] = current.copyWith(completedDates: newDates);
await _save(prefs);
}

Future<void> toggleDate(String habitId, String dateKey) async {
final i = _habits.indexWhere((h) => h.id == habitId);
if (i == -1) return;

final prefs = await SharedPreferences.getInstance();

final current = _habits[i];
final newDates = Set<String>.from(current.completedDates);

if (newDates.contains(dateKey)) {
newDates.remove(dateKey);
} else {
newDates.add(dateKey);
}

_habits[i] = current.copyWith(completedDates: newDates);
await _save(prefs);
}

Future<void> addHabit(String title, int targetDays, int? reminderMinutes) async {
final t = title.trim();
if (t.isEmpty) return;

final prefs = await SharedPreferences.getInstance();
final newId = (Random().nextInt(1 << 30)).toString();

_habits.add(
Habit(
id: newId,
title: t,
completedDates: <String>{},
targetDays: targetDays,
archived: false,
reminderMinutes: reminderMinutes,
),
);

await _save(prefs);
}

Future<void> removeHabit(String id) async {
_habits.removeWhere((h) => h.id == id);
final prefs = await SharedPreferences.getInstance();
await _save(prefs);
}

Future<void> insertHabitAt(int index, Habit habit) async {
final prefs = await SharedPreferences.getInstance();
final safeIndex = index.clamp(0, _habits.length);
_habits.insert(safeIndex, habit);
await _save(prefs);
}

Future<void> renameHabit(String id, String newTitle) async {
final t = newTitle.trim();
if (t.isEmpty) return;

final i = _habits.indexWhere((h) => h.id == id);
if (i == -1) return;

_habits[i] = _habits[i].copyWith(title: t);
final prefs = await SharedPreferences.getInstance();
await _save(prefs);
}

Future<void> setTargetDays(String id, int targetDays) async {
final i = _habits.indexWhere((h) => h.id == id);
if (i == -1) return;

_habits[i] = _habits[i].copyWith(targetDays: targetDays);
final prefs = await SharedPreferences.getInstance();
await _save(prefs);
}

// ✅ A) Goal reached actions
Future<void> restartHabitProgress(String id) async {
final i = _habits.indexWhere((h) => h.id == id);
if (i == -1) return;

final prefs = await SharedPreferences.getInstance();
_habits[i] = _habits[i].copyWith(completedDates: <String>{});
await _save(prefs);
}

Future<void> setArchived(String id, bool archived) async {
final i = _habits.indexWhere((h) => h.id == id);
if (i == -1) return;

final prefs = await SharedPreferences.getInstance();
_habits[i] = _habits[i].copyWith(archived: archived);
await _save(prefs);
}

// ✅ B) Reminder UI storage
Future<void> setReminderMinutes(String id, int? reminderMinutes) async {
final i = _habits.indexWhere((h) => h.id == id);
if (i == -1) return;

final prefs = await SharedPreferences.getInstance();
_habits[i] = _habits[i].copyWith(reminderMinutes: reminderMinutes);
await _save(prefs);
}

// ---------- menu actions ----------

Future<void> resetToday() async {
final prefs = await SharedPreferences.getInstance();
final today = _todayKey();

for (var i = 0; i < _habits.length; i++) {
final h = _habits[i];
if (!h.completedDates.contains(today)) continue;

final newDates = Set<String>.from(h.completedDates)..remove(today);
_habits[i] = h.copyWith(completedDates: newDates);
}

await _save(prefs);
}

Future<void> markAllDoneToday() async {
final prefs = await SharedPreferences.getInstance();
final today = _todayKey();

for (var i = 0; i < _habits.length; i++) {
final h = _habits[i];
if (h.completedDates.contains(today)) continue;

final newDates = Set<String>.from(h.completedDates)..add(today);
_habits[i] = h.copyWith(completedDates: newDates);
}

await _save(prefs);
}

// ---------- helpers ----------

String _todayKey() => _keyFromDate(DateTime.now());

String _keyFromDate(DateTime d) {
String two(int n) => n.toString().padLeft(2, '0');
return '${d.year}-${two(d.month)}-${two(d.day)}';
}

Future<void> _save(SharedPreferences prefs) async {
final raw = jsonEncode(_habits.map((h) => h.toJson()).toList());
await prefs.setString(_storageKey, raw);
}
}