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

        return FilterChip(
          selected: isSelected,
          avatar: Icon(
            iconData,
            size: 18,
            color: isSelected ? Colors.white : theme.colorScheme.primary,
          ),
          label: Text(cat.name),
          labelStyle: TextStyle(
            color: isSelected ? Colors.white : theme.colorScheme.onSurface,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
          backgroundColor: theme.colorScheme.surfaceVariant.withOpacity(0.3),
          selectedColor: theme.colorScheme.primary,
          checkmarkColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: isSelected ? theme.colorScheme.primary : theme.dividerColor.withOpacity(0.15),
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
