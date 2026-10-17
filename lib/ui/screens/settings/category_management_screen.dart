import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/icon_map.dart';
import '../../../data/models/expense_category.dart';
import '../../../providers/category_provider.dart';
import '../../../providers/database_provider.dart';

class CategoryManagementScreen extends ConsumerStatefulWidget {
  const CategoryManagementScreen({super.key});

  @override
  ConsumerState<CategoryManagementScreen> createState() => _CategoryManagementScreenState();
}

class _CategoryManagementScreenState extends ConsumerState<CategoryManagementScreen> {
  Future<void> _showAddCategoryDialog() async {
    final nameController = TextEditingController();
    String selectedIcon = IconMap.availableKeys.first;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add Expense Category'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: nameController,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Category Name *',
                  hintText: 'Enter category name',
                ),
              ),
              const SizedBox(height: 16),
              const Text('Select Icon:', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: IconMap.availableKeys.map((iconKey) {
                  final isSelected = iconKey == selectedIcon;
                  return InkWell(
                    onTap: () => setDialogState(() => selectedIcon = iconKey),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected
                              ? Theme.of(context).colorScheme.primary
                              : Colors.transparent,
                        ),
                      ),
                      child: Icon(
                        IconMap.fromKey(iconKey),
                        color: isSelected ? Colors.white : Theme.of(context).colorScheme.onSurface,
                        size: 22,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );

    if (result == true && nameController.text.trim().isNotEmpty) {
      try {
        final cat = ExpenseCategory(
          name: nameController.text.trim(),
          icon: selectedIcon,
          isActive: true,
        );
        await ref.read(categoryRepositoryProvider).insert(cat);
        ref.invalidate(activeCategoriesProvider);
        ref.invalidate(allCategoriesProvider);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to add category: $e')),
          );
        }
      }
    }
  }

  Future<void> _toggleCategory(ExpenseCategory category, bool active) async {
    final repo = ref.read(categoryRepositoryProvider);
    if (active) {
      await repo.activate(category.id!);
    } else {
      await repo.deactivate(category.id!);
    }
    ref.invalidate(activeCategoriesProvider);
    ref.invalidate(allCategoriesProvider);
  }

  @override
  Widget build(BuildContext context) {
    final allCategoriesAsync = ref.watch(allCategoriesProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense Categories'),
      ),
      body: allCategoriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error loading categories: $e')),
        data: (categories) {
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: categories.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final cat = categories[index];
              final iconData = IconMap.fromKey(cat.icon);

              return Card(
                elevation: 0.5,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(color: theme.dividerColor.withOpacity(0.1)),
                ),
                child: SwitchListTile(
                  secondary: CircleAvatar(
                    backgroundColor: cat.isActive
                        ? theme.colorScheme.primary.withOpacity(0.12)
                        : theme.dividerColor,
                    child: Icon(
                      iconData,
                      color: cat.isActive
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurfaceVariant,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    cat.name,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      decoration: !cat.isActive ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  subtitle: Text(
                    cat.isActive ? 'Active in expense picker' : 'Disabled / Hidden',
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  value: cat.isActive,
                  onChanged: (val) => _toggleCategory(cat, val),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddCategoryDialog,
        icon: const Icon(Icons.add),
        label: const Text('New Category'),
      ),
    );
  }
}
