import 'package:flutter/material.dart';
import '../../core/utils/icon_map.dart';

/// Standardized category icon badge used consistently across all expense cards,
/// detail views, and voucher screens.
class CategoryIconBadge extends StatelessWidget {
  final String? iconKey;
  final double size;
  final double iconSize;
  final double borderRadius;
  final Color? customColor;
  final Color? customBgColor;

  const CategoryIconBadge({
    super.key,
    required this.iconKey,
    this.size = 44,
    this.iconSize = 22,
    this.borderRadius = 6,
    this.customColor,
    this.customBgColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = customColor ?? IconMap.colorFor(iconKey, isDark: isDark);
    final bgColor = customBgColor ?? IconMap.backgroundFor(iconKey, isDark: isDark);
    final borderColor = isDark ? const Color(0xFF2E2E32) : const Color(0xFFDCDCE2);
    final iconData = IconMap.fromKey(iconKey);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: borderColor, width: 1.0),
      ),
      child: Center(
        child: Icon(
          iconData,
          color: color,
          size: iconSize,
        ),
      ),
    );
  }
}
