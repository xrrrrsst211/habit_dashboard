import 'package:habit_dashboard/features/habits/domain/habit.dart';

/// Web version: notifications are not supported here.
/// This keeps the project runnable in browsers.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  Future<void> init() async {
    // no-op on web
  }

  Future<void> syncFromHabits(List<Habit> habits) async {
    // no-op on web
  }

  Future<void> scheduleHabitReminder({
    required Habit habit,
    required int minutesFromMidnight,
  }) async {
    // no-op on web
  }

  Future<void> cancelHabitReminder(String habitId) async {
    // no-op on web
  }
}