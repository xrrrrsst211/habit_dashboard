import 'package:flutter/material.dart';

ThemeData buildAppTheme() {
final base = ThemeData(
useMaterial3: true,
colorSchemeSeed: Colors.deepPurple,
brightness: Brightness.light,
);

return base.copyWith(
cardTheme: const CardThemeData(
elevation: 0,
margin: EdgeInsets.zero,
shape: RoundedRectangleBorder(
borderRadius: BorderRadius.all(Radius.circular(16)),
),
),
inputDecorationTheme: const InputDecorationTheme(
border: OutlineInputBorder(
borderRadius: BorderRadius.all(Radius.circular(14)),
),
),
);
}

ThemeData buildDarkAppTheme() {
final base = ThemeData(
useMaterial3: true,
colorSchemeSeed: Colors.deepPurple,
brightness: Brightness.dark,
);

return base.copyWith(
cardTheme: const CardThemeData(
elevation: 0,
margin: EdgeInsets.zero,
shape: RoundedRectangleBorder(
borderRadius: BorderRadius.all(Radius.circular(16)),
),
),
inputDecorationTheme: const InputDecorationTheme(
border: OutlineInputBorder(
borderRadius: BorderRadius.all(Radius.circular(14)),
),
),
);
}
