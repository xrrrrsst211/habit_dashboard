import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:habit_dashboard/app/theme.dart';
import 'package:habit_dashboard/features/habits/presentation/home/home_screen.dart';

class MyApp extends StatefulWidget {
  final bool initialDarkMode;

  const MyApp({super.key, required this.initialDarkMode});

  /// Access the app state (used for theme toggling).
  static MyAppState? of(BuildContext context) {
    return context.findAncestorStateOfType<MyAppState>();
  }

  @override
  State<MyApp> createState() => MyAppState();
}

class MyAppState extends State<MyApp> with WidgetsBindingObserver {
  late bool _isDarkMode;

  // Detect day changes on cold start and when returning from background.
  // We persist the last opened day to SharedPreferences so the check also
  // works across full app restarts.
  static const String _lastOpenedDayPrefKey = 'last_opened_day';
  String _lastKnownDayKey = _dayKeyFrom(DateTime.now());

  @override
  void initState() {
    super.initState();
    _isDarkMode = widget.initialDarkMode;

    WidgetsBinding.instance.addObserver(this);

    // Cold start: ensure "today" is fresh.
    // (We don't mutate habits here; we just trigger a rebuild if the day changed.)
    _ensureDayIsFresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Returning from background: refresh "today".
      _ensureDayIsFresh();
    }
  }

  static String _dayKeyFrom(DateTime d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${d.year}-${two(d.month)}-${two(d.day)}';
  }

  Future<void> _ensureDayIsFresh() async {
    final prefs = await SharedPreferences.getInstance();
    final today = _dayKeyFrom(DateTime.now());
    final last = prefs.getString(_lastOpenedDayPrefKey);

    // Always write the latest day key (helps with future migrations/features).
    if (last != today) {
      await prefs.setString(_lastOpenedDayPrefKey, today);
    }

    // If the day changed while app was backgrounded (or device time changed),
    // force a rebuild so screens using DateTime.now() update "today".
    if (_lastKnownDayKey != today) {
      _lastKnownDayKey = today;
      if (!mounted) return;
      setState(() {});
    }
  }

  bool get isDarkMode => _isDarkMode;

  Future<void> toggleDarkMode() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = !_isDarkMode;
    await prefs.setBool('is_dark_mode', _isDarkMode);
    if (!mounted) return;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      darkTheme: buildDarkAppTheme(),
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: const HomeScreen(),
    );
  }
}


