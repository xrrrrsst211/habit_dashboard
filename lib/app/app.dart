import 'package:flutter/material.dart';
import 'package:habit_dashboard/app/routes.dart';
import 'package:habit_dashboard/app/theme.dart';

class HabitDashboardApp extends StatelessWidget {
  const HabitDashboardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Habit Dashboard',
      theme: buildAppTheme(),
      onGenerateRoute: AppRoutes.onGenerateRoute,
      initialRoute: AppRoutes.home,
    );
  }
}