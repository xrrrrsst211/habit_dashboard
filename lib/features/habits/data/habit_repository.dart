import 'dart:math';
import '../domain/habit.dart';

class HabitRepository {
  final List<Habit> _habits = [
    const Habit(id: '1', title: 'Drink water', doneToday: false),
    const Habit(id: '2', title: 'Workout', doneToday: true),
    const Habit(id: '3', title: 'Read 20 minutes', doneToday: true),
    const Habit(id: '4', title: 'Meditate', doneToday: false),
  ];

  List<Habit> getHabits() => List.unmodifiable(_habits);

  void toggleHabit(String id) {
    final i = _habits.indexWhere((h) => h.id == id);
    if (i == -1) return;
    _habits[i] = _habits[i].copyWith(doneToday: !_habits[i].doneToday);
  }

  void addHabit(String title) {
    final newId = (Random().nextInt(1 << 30)).toString();
    _habits.add(Habit(id: newId, title: title, doneToday: false));
  }
}