import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/expense_category.dart';
import 'database_provider.dart';

/// Active categories for expense creation pickers.
final activeCategoriesProvider = FutureProvider<List<ExpenseCategory>>((ref) {
  return ref.watch(categoryRepositoryProvider).getActive();
});

/// All categories for the category management screen.
final allCategoriesProvider = FutureProvider<List<ExpenseCategory>>((ref) {
  return ref.watch(categoryRepositoryProvider).getAll();
});
