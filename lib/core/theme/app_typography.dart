import 'package:flutter/material.dart';

/// Centralized typography definitions for the Nothing-inspired advocate aesthetic.
class AppTypography {
  AppTypography._();

  static const String fontFamilyBase = 'SpaceGrotesk';
  static const String fontFamilyDot = 'NDot';

  /// Signature Nothing dot-matrix text style (for amounts, counts, codes, dates).
  static TextStyle ndot({
    double fontSize = 24,
    FontWeight fontWeight = FontWeight.normal,
    Color? color,
    double letterSpacing = 1.2,
  }) {
    return TextStyle(
      fontFamily: fontFamilyDot,
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing,
    );
  }

  /// Clean Space Grotesk technical typography.
  static TextStyle spaceGrotesk({
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.normal,
    Color? color,
    double letterSpacing = 0.2,
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
}
