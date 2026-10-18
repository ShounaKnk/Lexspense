import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/expense_view.dart';
import '../data/models/receipt_image.dart';
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

/// Single expense view by ID with all joined details.
final singleExpenseProvider =
    FutureProvider.family<ExpenseView?, int>((ref, expenseId) {
  return ref.watch(expenseRepositoryProvider).getExpenseById(expenseId);
});

/// Receipts for a specific expense.
final expenseReceiptsProvider =
    FutureProvider.family<List<ReceiptImage>, int>((ref, expenseId) async {
  final map = await ref.watch(expenseRepositoryProvider).getReceiptsForExpenses([expenseId]);
  return map[expenseId] ?? [];
});
