import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lexledger/core/utils/date_utils.dart';
import 'package:lexledger/data/models/reimbursement.dart';
import 'package:lexledger/ui/widgets/search_filter_bar.dart';

void main() {
  group('Search & Filter Helper Tests', () {
    test('DateFilterHelper.matchesDate handles all presets properly', () {
      final now = DateTime.now();
      final todayStr = AppDateUtils.toDbString(now);
      final yesterdayStr = AppDateUtils.toDbString(now.subtract(const Duration(days: 1)));
      const oldDateStr = '2020-01-01';

      // 1. All
      expect(DateFilterHelper.matchesDate(todayStr, DateFilterOption.all, null), isTrue);
      expect(DateFilterHelper.matchesDate(oldDateStr, DateFilterOption.all, null), isTrue);

      // 2. Today
      expect(DateFilterHelper.matchesDate(todayStr, DateFilterOption.today, null), isTrue);
      expect(DateFilterHelper.matchesDate(oldDateStr, DateFilterOption.today, null), isFalse);

      // 3. Custom Range
      final range = DateTimeRange(
        start: now.subtract(const Duration(days: 3)),
        end: now.add(const Duration(days: 1)),
      );
      expect(DateFilterHelper.matchesDate(todayStr, DateFilterOption.custom, range), isTrue);
      expect(DateFilterHelper.matchesDate(yesterdayStr, DateFilterOption.custom, range), isTrue);
      expect(DateFilterHelper.matchesDate(oldDateStr, DateFilterOption.custom, range), isFalse);
    });

    test('Reimbursement.matchesMatterId checks concatenated IDs correctly', () {
      const batchWithMultipleMatters = Reimbursement(
        id: 1,
        totalAmountPaise: 50000,
        datePaid: '2026-10-20',
        allMatterIds: '10, 25, 42',
        allMatterTitles: 'State v. Sharma, Mehta v. UOI, Tata v. Mistry',
      );

      expect(batchWithMultipleMatters.matchesMatterId(10), isTrue);
      expect(batchWithMultipleMatters.matchesMatterId(25), isTrue);
      expect(batchWithMultipleMatters.matchesMatterId(42), isTrue);
      expect(batchWithMultipleMatters.matchesMatterId(99), isFalse);
      expect(batchWithMultipleMatters.matchesMatterId(1), isFalse);

      const batchWithNoMatters = Reimbursement(
        id: 2,
        totalAmountPaise: 10000,
        datePaid: '2026-10-20',
      );
      expect(batchWithNoMatters.matchesMatterId(10), isFalse);
    });
  });
}
