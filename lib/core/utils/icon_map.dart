import 'package:flutter/material.dart';

/// Maps icon key strings stored in the database to Flutter [IconData].
/// Unknown keys fall back to [Icons.category].
class IconMap {
  IconMap._();

  static const Map<String, IconData> _map = {
    'gavel': Icons.gavel,
    'print': Icons.print,
    'directions_car': Icons.directions_car,
    'local_gas_station': Icons.local_gas_station,
    'local_post_office': Icons.local_post_office,
    'more_horiz': Icons.more_horiz,
    'category': Icons.category,
    'receipt': Icons.receipt,
    'attach_money': Icons.attach_money,
    'description': Icons.description,
  };

  static IconData fromKey(String? key) {
    if (key == null) return Icons.category;
    return _map[key] ?? Icons.category;
  }

  /// All available icon keys for the category management UI.
  static List<String> get availableKeys => _map.keys.toList();
}
