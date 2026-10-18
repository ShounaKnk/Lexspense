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
        final catColor = IconMap.colorFor(cat.icon, isDark: isDark);
        final catBg = IconMap.backgroundFor(cat.icon, isDark: isDark);

        return FilterChip(
          selected: isSelected,
          avatar: Icon(
            iconData,
            size: 18,
            color: isSelected ? Colors.white : catColor,
          ),
          label: Text(cat.name),
          labelStyle: TextStyle(
            color: isSelected ? Colors.white : theme.colorScheme.onSurface,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
          backgroundColor: catBg,
          selectedColor: catColor,
          checkmarkColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: isSelected ? catColor : catColor.withOpacity(0.3),
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
