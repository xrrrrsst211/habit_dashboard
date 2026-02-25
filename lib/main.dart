import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';

Future<void> main() async {
WidgetsFlutterBinding.ensureInitialized();

final prefs = await SharedPreferences.getInstance();
final isDark = prefs.getBool('is_dark_mode') ?? false;

runApp(MyApp(initialDarkMode: isDark));
}