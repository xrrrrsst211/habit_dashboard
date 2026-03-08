import 'package:flutter/material.dart';

import 'package:habit_dashboard/core/theme/app_styles.dart';

ThemeData _buildBaseTheme(Brightness brightness) {
  final base = ThemeData(
    useMaterial3: true,
    colorSchemeSeed: Colors.teal,
    brightness: brightness,
  );

  final cs = base.colorScheme;
  final isDark = brightness == Brightness.dark;

  return base.copyWith(
    scaffoldBackgroundColor: cs.surface,
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: <TargetPlatform, PageTransitionsBuilder>{
        TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
        TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
      },
    ),
    extensions: <ThemeExtension<dynamic>>[
      AppStyles(
        secondaryText: (base.textTheme.bodyMedium ?? const TextStyle())
            .copyWith(color: cs.onSurfaceVariant),
      ),
    ],
    cardTheme: CardThemeData(
      elevation: 0,
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      color: cs.surface,
      shadowColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.all(Radius.circular(22)),
        side: BorderSide(color: cs.outline.withValues(alpha: isDark ? 0.20 : 0.12)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: cs.surfaceContainerHighest.withValues(alpha: isDark ? 0.20 : 0.35),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: const BorderRadius.all(Radius.circular(16)),
        borderSide: BorderSide(color: cs.outline.withValues(alpha: isDark ? 0.18 : 0.10)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: const BorderRadius.all(Radius.circular(16)),
        borderSide: BorderSide(color: cs.primary.withValues(alpha: 0.55), width: 1.2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: const BorderRadius.all(Radius.circular(16)),
        borderSide: BorderSide(color: cs.error.withValues(alpha: 0.75)),
      ),
    ),
    listTileTheme: ListTileThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      iconColor: cs.primary,
    ),
    dividerTheme: DividerThemeData(
      color: cs.outline.withValues(alpha: isDark ? 0.18 : 0.10),
      space: 1,
      thickness: 1,
    ),
    chipTheme: base.chipTheme.copyWith(
      side: BorderSide(color: cs.outline.withValues(alpha: isDark ? 0.18 : 0.10)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      labelStyle: base.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700),
    ),
  );
}

ThemeData buildAppTheme() => _buildBaseTheme(Brightness.light);

ThemeData buildDarkAppTheme() => _buildBaseTheme(Brightness.dark);
