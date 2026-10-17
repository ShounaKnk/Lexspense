import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import '../core/utils/currency_utils.dart';
import '../data/repositories/expense_repository.dart';

/// Syncs pending expenses summary with the Home Screen Widget.
class WidgetSyncService {
  final ExpenseRepository _expenseRepository;

  WidgetSyncService(this._expenseRepository);

  /// Reads current unpaid totals from the DB and updates widget data.
  Future<void> updateWidgetData() async {
    try {
      final (totalPaise, count) = await _expenseRepository.getUnpaidSummary();
      final formattedAmount = CurrencyUtils.formatRupees(totalPaise);

      await HomeWidget.saveWidgetData<String>('pending_amount', formattedAmount);
      await HomeWidget.saveWidgetData<int>('pending_count', count);

      await HomeWidget.updateWidget(
        androidName: 'LexLedgerWidgetProvider',
        iOSName: 'LexLedgerWidget',
      );
    } catch (e, st) {
      // Graceful fallback if widget provider is not registered or running on unsupported platforms
      if (kDebugMode) {
        developer.log('WidgetSyncService error: $e', error: e, stackTrace: st);
      }
    }
  }
}
