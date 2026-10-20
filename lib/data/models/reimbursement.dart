/// A reimbursement batch — a payout that covers one or more expenses.
class Reimbursement {
  final int? id;
  final int totalAmountPaise;
  final String datePaid;      // 'YYYY-MM-DD'
  final String? notes;
  final String? createdAt;
  final int itemCount;        // COUNT() from the list query, avoids N+1
  final int? singleExpenseId;
  final String? singleCategoryName;
  final String? singleCategoryIcon;
  final String? singleMatterTitle;
  final String? singleExpenseDate;
  final String? allMatterTitles;
  final String? allMatterIds;
  final String? allCategoryNames;

  const Reimbursement({
    this.id,
    required this.totalAmountPaise,
    required this.datePaid,
    this.notes,
    this.createdAt,
    this.itemCount = 0,
    this.singleExpenseId,
    this.singleCategoryName,
    this.singleCategoryIcon,
    this.singleMatterTitle,
    this.singleExpenseDate,
    this.allMatterTitles,
    this.allMatterIds,
    this.allCategoryNames,
  });

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'total_amount_paise': totalAmountPaise,
        'date_paid': datePaid,
        'notes': notes,
      };

  factory Reimbursement.fromMap(Map<String, dynamic> map) => Reimbursement(
        id: map['id'] as int?,
        totalAmountPaise: map['total_amount_paise'] as int,
        datePaid: map['date_paid'] as String,
        notes: map['notes'] as String?,
        createdAt: map['created_at'] as String?,
        itemCount: map['item_count'] as int? ?? 0,
        singleExpenseId: map['single_expense_id'] as int?,
        singleCategoryName: map['single_category_name'] as String?,
        singleCategoryIcon: map['single_category_icon'] as String?,
        singleMatterTitle: map['single_matter_title'] as String?,
        singleExpenseDate: map['single_expense_date'] as String?,
        allMatterTitles: map['all_matter_titles'] as String?,
        allMatterIds: map['all_matter_ids']?.toString(),
        allCategoryNames: map['all_category_names'] as String?,
      );

  /// Check whether this reimbursement covers the given matter ID.
  bool matchesMatterId(int matterId) {
    if (allMatterIds != null && allMatterIds!.isNotEmpty) {
      final ids = allMatterIds!
          .split(',')
          .map((s) => int.tryParse(s.trim()))
          .whereType<int>();
      return ids.contains(matterId);
    }
    return false;
  }
}
