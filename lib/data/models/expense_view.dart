import 'expense.dart';

/// Denormalized view of an expense with JOINed matter title and category info.
/// Used by dashboard, reimbursement detail, and PDF generation.
class ExpenseView {
  final Expense expense;
  final String matterTitle;
  final String categoryName;
  final String categoryIcon;

  const ExpenseView({
    required this.expense,
    required this.matterTitle,
    required this.categoryName,
    required this.categoryIcon,
  });

  factory ExpenseView.fromMap(Map<String, dynamic> map) => ExpenseView(
        expense: Expense.fromMap(map),
        matterTitle: map['case_title'] as String,
        categoryName: map['category_name'] as String,
        categoryIcon: map['category_icon'] as String? ?? 'category',
      );
}
