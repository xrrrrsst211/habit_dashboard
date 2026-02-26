import 'package:flutter/material.dart';

@immutable
class AppStyles extends ThemeExtension<AppStyles> {
  final TextStyle secondaryText;

  const AppStyles({
    required this.secondaryText,
  });

  @override
  AppStyles copyWith({TextStyle? secondaryText}) {
    return AppStyles(
      secondaryText: secondaryText ?? this.secondaryText,
    );
  }

  @override
  AppStyles lerp(ThemeExtension<AppStyles>? other, double t) {
    if (other is! AppStyles) return this;
    return AppStyles(
      secondaryText:
          TextStyle.lerp(secondaryText, other.secondaryText, t) ?? secondaryText,
    );
  }
}

extension AppStylesContextX on BuildContext {
  /// Safe access to [AppStyles].
  ///
  /// If the theme forgot to register the extension, we fall back to a reasonable
  /// Material color so the app doesn't crash ("Unexpected null value").
  AppStyles get appStyles {
    final theme = Theme.of(this);
    final ext = theme.extension<AppStyles>();
    if (ext != null) return ext;

    final fallbackColor = theme.colorScheme.onSurfaceVariant;
    return AppStyles(
      secondaryText: (theme.textTheme.bodyMedium ?? const TextStyle())
          .copyWith(color: fallbackColor),
    );
  }

  TextStyle get secondaryTextStyle => appStyles.secondaryText;
}