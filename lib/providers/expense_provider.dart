import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/expense_view.dart';
import 'database_provider.dart';

/// All unpaid expenses for the dashboard.
final unpaidExpensesProvider = FutureProvider<List<ExpenseView>>((ref) {
  return ref.watch(expenseRepositoryProvider).getUnpaidExpenses();
});

/// Expenses linked to a specific reimbursement (for detail screen).
final reimbursementExpensesProvider =
    FutureProvider.family<List<ExpenseView>, int>((ref, reimbursementId) {
  return ref.watch(expenseRepositoryProvider).getExpensesByReimbursement(reimbursementId);
});
