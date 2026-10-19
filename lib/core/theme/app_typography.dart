import 'package:flutter/material.dart';

/// Centralized typography definitions for the Nothing-inspired advocate aesthetic.
class AppTypography {
  AppTypography._();

  static const String fontFamilyBase = 'SpaceGrotesk';

  /// Clean Space Grotesk technical typography.
  static TextStyle spaceGrotesk({
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.normal,
    Color? color,
    double letterSpacing = 0.0,
    double? height,
  }) {
    return TextStyle(
      fontFamily: fontFamilyBase,
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing,
      height: height,
    );
  }

  /// Financial figures, amounts, and metrics with proper bolding and crisp numeral kerning.
  static TextStyle figure({
    double fontSize = 24,
    FontWeight fontWeight = FontWeight.w700,
    Color? color,
    double letterSpacing = -0.5,
  }) {
    return TextStyle(
      fontFamily: fontFamilyBase,
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing,
    );
  }

  /// Alias for backward compatibility - now uses Space Grotesk with bolding.
  static TextStyle ndot({
    double fontSize = 24,
    FontWeight fontWeight = FontWeight.w700,
    Color? color,
    double letterSpacing = -0.5,
  }) {
    return figure(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing,
    );
  }
}
