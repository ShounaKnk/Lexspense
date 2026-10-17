import 'package:flutter/material.dart';

/// Curated color palette for Lexspense.
class AppColors {
  AppColors._();

  // Light theme
  static const Color primaryLight = Color(0xFF1B5E20);       // Deep legal green
  static const Color primaryContainerLight = Color(0xFFC8E6C9);
  static const Color secondaryLight = Color(0xFF37474F);     // Blue-grey
  static const Color surfaceLight = Color(0xFFFAFAFA);
  static const Color backgroundLight = Color(0xFFF5F5F5);
  static const Color errorLight = Color(0xFFD32F2F);
  static const Color unpaidBadge = Color(0xFFFF8F00);        // Amber for pending
  static const Color paidBadge = Color(0xFF2E7D32);          // Green for paid

  // Dark theme
  static const Color primaryDark = Color(0xFF81C784);
  static const Color primaryContainerDark = Color(0xFF1B5E20);
  static const Color secondaryDark = Color(0xFF90A4AE);
  static const Color surfaceDark = Color(0xFF1E1E1E);
  static const Color backgroundDark = Color(0xFF121212);
  static const Color errorDark = Color(0xFFEF5350);
}
