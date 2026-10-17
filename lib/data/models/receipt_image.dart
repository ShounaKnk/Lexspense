/// A receipt image associated with an expense.
/// Only the file name is stored; the full path is resolved at runtime
/// from the receipts directory.
class ReceiptImage {
  final int? id;
  final int expenseId;
  final String fileName;
  final String? createdAt;

  const ReceiptImage({
    this.id,
    required this.expenseId,
    required this.fileName,
    this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'expense_id': expenseId,
        'file_name': fileName,
      };

  factory ReceiptImage.fromMap(Map<String, dynamic> map) => ReceiptImage(
        id: map['id'] as int?,
        expenseId: map['expense_id'] as int,
        fileName: map['file_name'] as String,
        createdAt: map['created_at'] as String?,
      );
}
