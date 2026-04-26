import 'package:flutter/material.dart';

@immutable
class AppThemeExtension extends ThemeExtension<AppThemeExtension> {
  const AppThemeExtension({
    required this.gradientStart,
    required this.gradientEnd,
    required this.tileBackground,
    required this.bodyTextColor,
    required this.tileTextColor,
    required this.tileBorderColor,
  });

  final Color gradientStart;
  final Color gradientEnd;
  final Color tileBackground;
  final Color bodyTextColor;
  final Color tileTextColor;
  final Color tileBorderColor;

  @override
  AppThemeExtension copyWith({
    Color? gradientStart,
    Color? gradientEnd,
    Color? tileBackground,
    Color? bodyTextColor,
    Color? tileTextColor,
    Color? tileBorderColor,
  }) {
    return AppThemeExtension(
      gradientStart: gradientStart ?? this.gradientStart,
      gradientEnd: gradientEnd ?? this.gradientEnd,
      tileBackground: tileBackground ?? this.tileBackground,
      bodyTextColor: bodyTextColor ?? this.bodyTextColor,
      tileTextColor: tileTextColor ?? this.tileTextColor,
      tileBorderColor: tileBorderColor ?? this.tileBorderColor,
    );
  }

  @override
  AppThemeExtension lerp(ThemeExtension<AppThemeExtension>? other, double t) {
    if (other is! AppThemeExtension) {
      return this;
    }
    return AppThemeExtension(
      gradientStart: Color.lerp(gradientStart, other.gradientStart, t)!,
      gradientEnd: Color.lerp(gradientEnd, other.gradientEnd, t)!,
      tileBackground: Color.lerp(tileBackground, other.tileBackground, t)!,
      bodyTextColor: Color.lerp(bodyTextColor, other.bodyTextColor, t)!,
      tileTextColor: Color.lerp(tileTextColor, other.tileTextColor, t)!,
      tileBorderColor: Color.lerp(tileBorderColor, other.tileBorderColor, t)!,
    );
  }
}
