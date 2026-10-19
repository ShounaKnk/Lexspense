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

  /// Monochrome advocate icon colors: crisp white on dark, stark black on light.
  static Color colorFor(String? key, {bool isDark = false}) {
    return isDark ? const Color(0xFFF5F5F5) : const Color(0xFF0F0F0F);
  }

  /// Architectural container background for the category icon badge.
  static Color backgroundFor(String? key, {bool isDark = false}) {
    return isDark ? const Color(0xFF1E1E22) : const Color(0xFFECECEF);
  }

  /// All available icon keys for the category management UI.
  static List<String> get availableKeys => _map.keys.toList();
}
