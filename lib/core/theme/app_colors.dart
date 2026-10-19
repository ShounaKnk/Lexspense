import 'package:flutter/material.dart';

/// Curated color palette for Lexspense: Advocate Black & White / Nothing OS aesthetic.
class AppColors {
  AppColors._();

  // Dark Theme: Pure Obsidian Courtroom
  static const Color backgroundDark = Color(0xFF000000);         // True jet black (OLED)
  static const Color surfaceDark = Color(0xFF101010);            // Deep obsidian
  static const Color surfaceElevatedDark = Color(0xFF181818);    // Tile/Card surface
  static const Color borderDark = Color(0xFF282828);             // Precision architectural border
  static const Color primaryDark = Color(0xFFFFFFFF);            // Starched collar white
  static const Color onPrimaryDark = Color(0xFF000000);          // Jet black on white
  static const Color primaryContainerDark = Color(0xFF222222);
  static const Color secondaryDark = Color(0xFFCCCCCC);          // Silver
  static const Color errorDark = Color(0xFFFF5252);              // Nothing accent red

  // Light Theme: Starched Legal White & Advocate Robe Black
  static const Color backgroundLight = Color(0xFFF7F7F8);        // Crisp legal paper
  static const Color surfaceLight = Color(0xFFFFFFFF);           // Starched white surface
  static const Color surfaceElevatedLight = Color(0xFFF2F2F4);   // Tile surface
  static const Color borderLight = Color(0xFFE2E2E6);            // Clean architectural border
  static const Color primaryLight = Color(0xFF000000);           // Advocate robe black
  static const Color onPrimaryLight = Color(0xFFFFFFFF);         // Starched white on black
  static const Color primaryContainerLight = Color(0xFFEAEAEA);
  static const Color secondaryLight = Color(0xFF333333);         // Deep charcoal
  static const Color errorLight = Color(0xFFD32F2F);             // Classic red

  // Status Badges (Advocate monochrome with subtle seal accents)
  static const Color unpaidBadge = Color(0xFFD9822B);            // Muted legal seal amber
  static const Color paidBadge = Color(0xFF2E7D32);              // Legal stamp green

  // Nothing Red Accent
  static const Color nothingRed = Color(0xFFFF3B30);

  // Dot Matrix background opacity
  static const Color dotMatrixDark = Color(0x18FFFFFF);         // Subtle white dots on black
  static const Color dotMatrixLight = Color(0x12000000);        // Subtle black dots on white
}
