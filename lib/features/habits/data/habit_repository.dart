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
      // стартовые демо-привычки
      _habits.addAll(const [
        Habit(id: '1', title: 'Drink water', doneToday: false),
        Habit(id: '2', title: 'Workout', doneToday: true),
        Habit(id: '3', title: 'Read 20 minutes', doneToday: true),
        Habit(id: '4', title: 'Meditate', doneToday: false),
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

    _initialized = true;
  }

  List<Habit> getHabits() => List.unmodifiable(_habits);

  Future<void> toggleHabit(String id) async {
    final i = _habits.indexWhere((h) => h.id == id);
    if (i == -1) return;

    _habits[i] = _habits[i].copyWith(doneToday: !_habits[i].doneToday);

    final prefs = await SharedPreferences.getInstance();
    await _save(prefs);
  }

  Future<void> addHabit(String title) async {
    final t = title.trim();
    if (t.isEmpty) return;

    final newId = (Random().nextInt(1 << 30)).toString();
    _habits.add(Habit(id: newId, title: t, doneToday: false));

    final prefs = await SharedPreferences.getInstance();
    await _save(prefs);
  }

  Future<void> removeHabit(String id) async {
    _habits.removeWhere((h) => h.id == id);

    final prefs = await SharedPreferences.getInstance();
    await _save(prefs);
  }

  Future<void> _save(SharedPreferences prefs) async {
    final raw = jsonEncode(_habits.map((h) => h.toJson()).toList());
    await prefs.setString(_storageKey, raw);
  }
}