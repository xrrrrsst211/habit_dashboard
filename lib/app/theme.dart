import 'package:flutter/material.dart';

import 'package:habit_dashboard/core/theme/app_styles.dart';

ThemeData buildAppTheme() {
  final base = ThemeData(
    useMaterial3: true,
    // Minimal teal accent (less "generic" than deepPurple)
    colorSchemeSeed: Colors.teal,
    brightness: Brightness.light,
  );

  return base.copyWith(
    extensions: <ThemeExtension<dynamic>>[
      AppStyles(
        secondaryText: (base.textTheme.bodyMedium ?? const TextStyle())
            .copyWith(color: base.colorScheme.onSurfaceVariant),
      ),
    ],
    // В твоей версии Flutter тут нужен CardThemeData
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
    // Keep the same accent in dark mode for a consistent identity.
    colorSchemeSeed: Colors.teal,
    brightness: Brightness.dark,
  );

  return base.copyWith(
    extensions: <ThemeExtension<dynamic>>[
      AppStyles(
        secondaryText: (base.textTheme.bodyMedium ?? const TextStyle())
            .copyWith(color: base.colorScheme.onSurfaceVariant),
      ),
    ],
    // В твоей версии Flutter тут нужен CardThemeData
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