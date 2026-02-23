import 'package:flutter/material.dart';
import 'routes.dart';
import 'theme.dart';

class HabitDashboardApp extends StatelessWidget {
  const HabitDashboardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Habit Dashboard',
      theme: buildAppTheme(),
      initialRoute: AppRoutes.home,
      onGenerateRoute: AppRoutes.onGenerateRoute,
    );
  }
}