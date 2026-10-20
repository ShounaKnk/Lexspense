import 'package:flutter_test/flutter_test.dart';
import 'package:lexledger/core/utils/date_utils.dart';

void main() {
  group('Claim Date Validation Tests', () {
    test('Claim date cannot be older than expense date', () {
      final expenseDateStr = '2026-10-20';
      final expenseDate = AppDateUtils.fromDbString(expenseDateStr);

      final olderClaimDate = DateTime(2026, 10, 19);
      final sameDayClaimDate = DateTime(2026, 10, 20);
      final newerClaimDate = DateTime(2026, 10, 21);

      // Comparing day levels
      final minDay = DateTime(expenseDate.year, expenseDate.month, expenseDate.day);
      final olderDay = DateTime(olderClaimDate.year, olderClaimDate.month, olderClaimDate.day);
      final sameDay = DateTime(sameDayClaimDate.year, sameDayClaimDate.month, sameDayClaimDate.day);
      final newerDay = DateTime(newerClaimDate.year, newerClaimDate.month, newerClaimDate.day);

      expect(olderDay.isBefore(minDay), isTrue, reason: 'Older date should be rejected');
      expect(sameDay.isBefore(minDay), isFalse, reason: 'Same-day claim is valid');
      expect(newerDay.isBefore(minDay), isFalse, reason: 'Newer date claim is valid');

      // ISO string comparison in DB
      expect('2026-10-19'.compareTo(expenseDateStr) < 0, isTrue);
      expect('2026-10-20'.compareTo(expenseDateStr) >= 0, isTrue);
      expect('2026-10-21'.compareTo(expenseDateStr) > 0, isTrue);
    });

    test('Batch claim date must be on or after newest expense in batch', () {
      final batchExpenseDates = ['2026-10-15', '2026-10-18', '2026-10-20'];
      DateTime? maxExpenseDate;
      for (final dateStr in batchExpenseDates) {
        final d = AppDateUtils.fromDbString(dateStr);
        if (maxExpenseDate == null || d.isAfter(maxExpenseDate)) {
          maxExpenseDate = d;
        }
      }

      expect(maxExpenseDate, DateTime(2026, 10, 20));

      final invalidBatchClaimDate = DateTime(2026, 10, 19);
      final validBatchClaimDate = DateTime(2026, 10, 20);

      expect(invalidBatchClaimDate.isBefore(maxExpenseDate!), isTrue);
      expect(validBatchClaimDate.isBefore(maxExpenseDate), isFalse);
    });
  });
}
