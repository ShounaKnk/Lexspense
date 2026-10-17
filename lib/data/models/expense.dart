/// A single expense entry.
///
/// If [reimbursementId] is null, the expense is unpaid (appears on dashboard).
/// If it has a value, the expense belongs to a reimbursement batch.
class Expense {
  final int? id;
  final int matterId;
  final int categoryId;
  final int? reimbursementId;
  final int amountPaise;
  final String expenseDate;   // 'YYYY-MM-DD'
  final String? notes;
  final String? createdAt;

  const Expense({
    this.id,
    required this.matterId,
    required this.categoryId,
    this.reimbursementId,
    required this.amountPaise,
    required this.expenseDate,
    this.notes,
    this.createdAt,
  });

  /// Whether this expense has been reimbursed.
  bool get isPaid => reimbursementId != null;

  /// Display only. Never do arithmetic on doubles.
  double get amountRupees => amountPaise / 100.0;

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'matter_id': matterId,
        'category_id': categoryId,
        'reimbursement_id': reimbursementId,
        'amount_paise': amountPaise,
        'expense_date': expenseDate,
        'notes': notes,
      };

  factory Expense.fromMap(Map<String, dynamic> map) => Expense(
        id: map['id'] as int?,
        matterId: map['matter_id'] as int,
        categoryId: map['category_id'] as int,
        reimbursementId: map['reimbursement_id'] as int?,
        amountPaise: map['amount_paise'] as int,
        expenseDate: map['expense_date'] as String,
        notes: map['notes'] as String?,
        createdAt: map['created_at'] as String?,
      );

  Expense copyWith({
    int? id,
    int? matterId,
    int? categoryId,
    int? reimbursementId,
    int? amountPaise,
    String? expenseDate,
    String? notes,
  }) =>
      Expense(
        id: id ?? this.id,
        matterId: matterId ?? this.matterId,
        categoryId: categoryId ?? this.categoryId,
        reimbursementId: reimbursementId ?? this.reimbursementId,
        amountPaise: amountPaise ?? this.amountPaise,
        expenseDate: expenseDate ?? this.expenseDate,
        notes: notes ?? this.notes,
        createdAt: createdAt,
      );
}
