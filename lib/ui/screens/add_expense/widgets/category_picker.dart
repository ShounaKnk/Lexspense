import 'package:flutter/material.dart';
import '../../../../core/utils/icon_map.dart';
import '../../../../data/models/expense_category.dart';

class CategoryPicker extends StatelessWidget {
  final List<ExpenseCategory> categories;
  final int? selectedCategoryId;
  final ValueChanged<int> onCategorySelected;

  const CategoryPicker({
    super.key,
    required this.categories,
    required this.selectedCategoryId,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (categories.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Text('No categories available. Please add categories in Settings.'),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: categories.map((cat) {
        final isSelected = cat.id == selectedCategoryId;
        final iconData = IconMap.fromKey(cat.icon);

        final isDark = theme.brightness == Brightness.dark;

        return FilterChip(
          selected: isSelected,
          avatar: Icon(
            iconData,
            size: 16,
            color: isSelected
                ? (isDark ? Colors.black : Colors.white)
                : (isDark ? Colors.white : Colors.black),
          ),
          label: Text(cat.name),
          labelStyle: TextStyle(
            color: isSelected
                ? (isDark ? Colors.black : Colors.white)
                : (isDark ? Colors.white : Colors.black),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 13,
          ),
          backgroundColor: isDark ? const Color(0xFF1E1E22) : const Color(0xFFECECEF),
          selectedColor: isDark ? Colors.white : Colors.black,
          showCheckmark: false,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
            side: BorderSide(
              color: isSelected
                  ? (isDark ? Colors.white : Colors.black)
                  : (isDark ? const Color(0xFF2E2E34) : const Color(0xFFD6D6DC)),
              width: 0.8,
            ),
          ),
          onSelected: (_) {
            if (cat.id != null) {
              onCategorySelected(cat.id!);
            }
          },
        );
      }).toList(),
    );
  }
}
