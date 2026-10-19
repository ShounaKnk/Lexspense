import 'package:flutter/material.dart';
import '../../../../core/utils/currency_utils.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../widgets/category_icon_badge.dart';
import '../../../../data/models/expense_view.dart';

class ExpenseListTile extends StatelessWidget {
  final ExpenseView expenseView;
  final bool isSelected;
  final ValueChanged<bool?> onSelected;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  const ExpenseListTile({
    super.key,
    required this.expenseView,
    required this.isSelected,
    required this.onSelected,
    required this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final expense = expenseView.expense;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6),
        side: BorderSide(
          color: isSelected
              ? (theme.brightness == Brightness.dark ? Colors.white : Colors.black)
              : theme.dividerColor,
          width: isSelected ? 1.5 : 1.0,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: onTap,
        onLongPress: () => onSelected(!isSelected),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              // Selection Checkbox
              Transform.scale(
                scale: 1.0,
                child: Checkbox(
                  value: isSelected,
                  onChanged: onSelected,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              const SizedBox(width: 4),

              // Category Icon Badge
              CategoryIconBadge(
                iconKey: expenseView.categoryIcon,
                size: 42,
                iconSize: 20,
                borderRadius: 6,
              ),
              const SizedBox(width: 14),

              // Matter & Category Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      expenseView.categoryName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      expenseView.matterTitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      AppDateUtils.toDisplay(expense.expenseDate),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant.withOpacity(0.8),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),

              // Amount & Actions
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    CurrencyUtils.format(expense.amountPaise),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.primary,
                      fontSize: 16,
                    ),
                  ),
                  if (onDelete != null)
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, size: 18),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      color: theme.colorScheme.error.withOpacity(0.7),
                      onPressed: onDelete,
                      tooltip: 'Delete expense',
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
