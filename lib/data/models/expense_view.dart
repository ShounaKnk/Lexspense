import 'expense.dart';

/// Denormalized view of an expense with JOINed matter title and category info.
/// Used by dashboard, reimbursement detail, and PDF generation.
class ExpenseView {
  final Expense expense;
  final String matterTitle;
  final String? forumName;
  final String categoryName;
  final String categoryIcon;
  final String? reimbursementDatePaid;
  final String? reimbursementNotes;

  const ExpenseView({
    required this.expense,
    required this.matterTitle,
    this.forumName,
    required this.categoryName,
    required this.categoryIcon,
    this.reimbursementDatePaid,
    this.reimbursementNotes,
  });

  factory ExpenseView.fromMap(Map<String, dynamic> map) => ExpenseView(
        expense: Expense.fromMap(map),
        matterTitle: map['case_title'] as String,
        forumName: map['forum_name'] as String?,
        categoryName: map['category_name'] as String,
        categoryIcon: map['category_icon'] as String? ?? 'category',
        reimbursementDatePaid: map['reimbursement_date_paid'] as String?,
        reimbursementNotes: map['reimbursement_notes'] as String?,
      );
}
