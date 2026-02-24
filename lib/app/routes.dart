import 'package:flutter/material.dart';
import 'package:habit_dashboard/features/habits/presentation/add_habit/add_habit_screen.dart';
import 'package:habit_dashboard/features/habits/presentation/home/home_screen.dart';

class AppRoutes {
  static const home = '/';
  static const addHabit = '/add-habit';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case home:
        return MaterialPageRoute(builder: (_) => const HomeScreen());
      case addHabit:
        return MaterialPageRoute(builder: (_) => const AddHabitScreen());
      default:
        return MaterialPageRoute(builder: (_) => const HomeScreen());
    }
  }
}