import 'dart:convert';
import 'dart:math';

import 'package:habit_dashboard/features/habits/domain/habit.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HabitRepository {
static const _storageKey = 'habits_v1';
static const _lastDayKey = 'last_day_v1';

final List<Habit> _habits = [];
bool _initialized = false;

// =========================
// INIT
// =========================

Future<void> init() async {
if (_initialized) return;

final prefs = await SharedPreferences.getInstance();
final raw = prefs.getString(_storageKey);

if (raw == null || raw.trim().isEmpty) {
_habits
..clear()
..addAll([
const Habit(
id: '1',
title: 'Drink water',
doneToday: false,
streak: 0,
lastCompletedDate: '',
targetDays: 21,
),
const Habit(
id: '2',
title: 'Workout',
doneToday: false,
streak: 0,
lastCompletedDate: '',
targetDays: 30,
),
const Habit(
id: '3',
title: 'Read 20 minutes',
doneToday: false,
streak: 0,
lastCompletedDate: '',
targetDays: 0,
),
const Habit(
id: '4',
title: 'Meditate',
doneToday: false,
streak: 0,
lastCompletedDate: '',
targetDays: 14,
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

await _resetIfNewDay(prefs);
_initialized = true;
}

List<Habit> getHabits() => List.unmodifiable(_habits);

// =========================
// TOGGLE
// =========================

Future<void> toggleHabit(String id) async {
final i = _habits.indexWhere((h) => h.id == id);
if (i == -1) return;

final prefs = await SharedPreferences.getInstance();
await _resetIfNewDay(prefs);

final today = _todayKey();
final yesterday = _yesterdayKey();

final current = _habits[i];

if (!current.doneToday) {
final wasYesterday = current.lastCompletedDate == yesterday;
final newStreak = wasYesterday ? (current.streak + 1) : 1;

_habits[i] = current.copyWith(
doneToday: true,
streak: newStreak,
lastCompletedDate: today,
);
} else {
_habits[i] = current.copyWith(
doneToday: false,
streak: 0,
lastCompletedDate: '',
);
}

await _save(prefs);
}

// =========================
// ADD / REMOVE / EDIT
// =========================

Future<void> addHabit(String title, int targetDays) async {
final t = title.trim();
if (t.isEmpty) return;

final prefs = await SharedPreferences.getInstance();
await _resetIfNewDay(prefs);

final newId = (Random().nextInt(1 << 30)).toString();

_habits.add(
Habit(
id: newId,
title: t,
doneToday: false,
streak: 0,
lastCompletedDate: '',
targetDays: targetDays,
),
);

await _save(prefs);
}

Future<void> removeHabit(String id) async {
_habits.removeWhere((h) => h.id == id);

final prefs = await SharedPreferences.getInstance();
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

// =========================
// NEW METHODS (меню)
// =========================

Future<void> resetToday() async {
final prefs = await SharedPreferences.getInstance();

for (var i = 0; i < _habits.length; i++) {
_habits[i] = _habits[i].copyWith(doneToday: false);
}

await _save(prefs);
}

Future<void> markAllDoneToday() async {
final prefs = await SharedPreferences.getInstance();
await _resetIfNewDay(prefs);

final today = _todayKey();
final yesterday = _yesterdayKey();

for (var i = 0; i < _habits.length; i++) {
final h = _habits[i];

if (h.doneToday) continue;

final wasYesterday = h.lastCompletedDate == yesterday;
final newStreak = wasYesterday ? (h.streak + 1) : 1;

_habits[i] = h.copyWith(
doneToday: true,
streak: newStreak,
lastCompletedDate: today,
);
}

await _save(prefs);
}

// =========================
// DATE HELPERS
// =========================

String _todayKey() => _keyFromDate(DateTime.now());

String _yesterdayKey() =>
_keyFromDate(DateTime.now().subtract(const Duration(days: 1)));

String _keyFromDate(DateTime d) {
String two(int n) => n.toString().padLeft(2, '0');
return '${d.year}-${two(d.month)}-${two(d.day)}';
}

Future<void> _resetIfNewDay(SharedPreferences prefs) async {
final today = _todayKey();
final lastDay = prefs.getString(_lastDayKey);

if (lastDay == today) return;

final yesterday = _yesterdayKey();

for (var i = 0; i < _habits.length; i++) {
final h = _habits[i];
final shouldKeepStreak = h.lastCompletedDate == yesterday;

_habits[i] = h.copyWith(
doneToday: false,
streak: shouldKeepStreak ? h.streak : 0,
);
}

await prefs.setString(_lastDayKey, today);
await _save(prefs);
}

Future<void> _save(SharedPreferences prefs) async {
final raw = jsonEncode(_habits.map((h) => h.toJson()).toList());
await prefs.setString(_storageKey, raw);
await prefs.setString(_lastDayKey, _todayKey());
}
}