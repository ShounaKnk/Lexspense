// ignore_for_file: prefer_const_constructors
import 'package:flutter_test/flutter_test.dart';
import 'package:lexledger/data/models/client_matter.dart';
import 'package:lexledger/data/models/expense.dart';
import 'package:lexledger/data/models/expense_category.dart';
import 'package:lexledger/data/models/receipt_image.dart';
import 'package:lexledger/data/models/reimbursement.dart';

void main() {
  group('Models Serialization Tests', () {
    test('ClientMatter toMap and fromMap round-trip', () {
      final matter = ClientMatter(
        id: 1,
        caseTitle: 'State v. Sharma',
        forumId: 10,
        forumName: 'Delhi High Court',
        status: 'Active',
      );
      final map = matter.toMap();
      expect(map['case_title'], 'State v. Sharma');
      expect(map['forum_id'], 10);
      expect(map['status'], 'Active');

      final fromMap = ClientMatter.fromMap({...map, 'id': 1, 'forum_name': 'Delhi High Court'});
      expect(fromMap.id, 1);
      expect(fromMap.caseTitle, 'State v. Sharma');
      expect(fromMap.forumId, 10);
      expect(fromMap.forum, 'Delhi High Court');
    });

    test('ExpenseCategory toMap and fromMap round-trip', () {
      const cat = ExpenseCategory(
        id: 2,
        name: 'Court Fees',
        icon: 'gavel',
        isActive: true,
      );
      final map = cat.toMap();
      expect(map['name'], 'Court Fees');
      expect(map['icon'], 'gavel');
      expect(map['is_active'], 1);

      final fromMap = ExpenseCategory.fromMap({...map, 'id': 2});
      expect(fromMap.name, 'Court Fees');
      expect(fromMap.isActive, isTrue);
    });

    test('Expense toMap and fromMap round-trip', () {
      final expense = Expense(
        id: 10,
        matterId: 1,
        categoryId: 2,
        reimbursementId: null,
        amountPaise: 45000, // 450.00
        expenseDate: '2026-10-14',
        notes: 'Stamp paper',
      );
      final map = expense.toMap();
      expect(map['amount_paise'], 45000);
      expect(map['reimbursement_id'], isNull);

      final fromMap = Expense.fromMap({...map, 'id': 10});
      expect(fromMap.amountPaise, 45000);
      expect(fromMap.isPaid, isFalse);
    });

    test('Reimbursement toMap and fromMap round-trip', () {
      final reimbursement = Reimbursement(
        id: 5,
        totalAmountPaise: 125000,
        datePaid: '2026-10-14',
        notes: 'Cheque 10293',
        itemCount: 3,
      );
      final map = reimbursement.toMap();
      expect(map['total_amount_paise'], 125000);
      expect(map['date_paid'], '2026-10-14');

      final fromMap = Reimbursement.fromMap({...map, 'id': 5, 'item_count': 3});
      expect(fromMap.id, 5);
      expect(fromMap.itemCount, 3);
    });

    test('ReceiptImage toMap and fromMap round-trip', () {
      final receipt = ReceiptImage(
        id: 7,
        expenseId: 10,
        fileName: 'rcpt_102938.jpg',
      );
      final map = receipt.toMap();
      expect(map['expense_id'], 10);
      expect(map['file_name'], 'rcpt_102938.jpg');

      final fromMap = ReceiptImage.fromMap({...map, 'id': 7});
      expect(fromMap.fileName, 'rcpt_102938.jpg');
    });
  });
}
