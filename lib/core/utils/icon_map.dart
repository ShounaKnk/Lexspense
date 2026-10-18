import 'package:flutter/material.dart';

/// Maps icon key strings stored in the database to Flutter [IconData].
/// Unknown keys fall back to [Icons.category].
class IconMap {
  IconMap._();

  static const Map<String, IconData> _map = {
    'gavel': Icons.gavel_rounded,
    'print': Icons.print_rounded,
    'directions_car': Icons.directions_car_rounded,
    'local_gas_station': Icons.local_gas_station_rounded,
    'local_post_office': Icons.local_post_office_rounded,
    'more_horiz': Icons.more_horiz_rounded,
    'category': Icons.category_rounded,
    'receipt': Icons.receipt_long_rounded,
    'attach_money': Icons.payments_rounded,
    'description': Icons.description_rounded,
  };

  static IconData fromKey(String? key) {
    if (key == null) return Icons.category_rounded;
    return _map[key] ?? Icons.category_rounded;
  }

  /// Curated color for each category icon.
  static Color colorFor(String? key, {bool isDark = false}) {
    switch (key) {
      case 'gavel':
        return isDark ? const Color(0xFF90CAF9) : const Color(0xFF1976D2); // Royal Blue
      case 'print':
        return isDark ? const Color(0xFF80CBC4) : const Color(0xFF00897B); // Teal
      case 'directions_car':
        return isDark ? const Color(0xFFFFAB91) : const Color(0xFFF4511E); // Warm Orange
      case 'local_gas_station':
        return isDark ? const Color(0xFFEF9A9A) : const Color(0xFFE53935); // Crimson Red
      case 'local_post_office':
        return isDark ? const Color(0xFFCE93D8) : const Color(0xFF8E24AA); // Purple
      case 'description':
        return isDark ? const Color(0xFF80DEEA) : const Color(0xFF00ACC1); // Aqua Cyan
      case 'receipt':
        return isDark ? const Color(0xFFA5D6A7) : const Color(0xFF2E7D32); // Emerald Green
      case 'attach_money':
        return isDark ? const Color(0xFFFFCC80) : const Color(0xFFFB8C00); // Amber
      case 'more_horiz':
      case 'category':
      default:
        return isDark ? const Color(0xFFB0BEC5) : const Color(0xFF546E7A); // Slate Blue-Grey
    }
  }

  /// Tinted container background for the category icon badge.
  static Color backgroundFor(String? key, {bool isDark = false}) {
    final fg = colorFor(key, isDark: isDark);
    return fg.withOpacity(isDark ? 0.22 : 0.12);
  }

  /// All available icon keys for the category management UI.
  static List<String> get availableKeys => _map.keys.toList();
}
