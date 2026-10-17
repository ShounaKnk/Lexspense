import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/database/database_helper.dart';
import '../data/repositories/matter_repository.dart';
import '../data/repositories/category_repository.dart';
import '../data/repositories/court_forum_repository.dart';
import '../data/repositories/expense_repository.dart';
import '../data/repositories/reimbursement_repository.dart';
import '../data/repositories/receipt_repository.dart';
import '../services/receipt_storage_service.dart';
import '../services/widget_sync_service.dart';
import '../services/pdf_service.dart';

/// Core database helper provider.
final databaseHelperProvider = Provider<DatabaseHelper>(
  (ref) => DatabaseHelper.instance,
);

/// Repository providers — single source of truth for all DB access.
final matterRepositoryProvider = Provider<MatterRepository>(
  (ref) => MatterRepository(ref.watch(databaseHelperProvider)),
);

final categoryRepositoryProvider = Provider<CategoryRepository>(
  (ref) => CategoryRepository(ref.watch(databaseHelperProvider)),
);

final courtForumRepositoryProvider = Provider<CourtForumRepository>(
  (ref) => CourtForumRepository(ref.watch(databaseHelperProvider)),
);

final expenseRepositoryProvider = Provider<ExpenseRepository>(
  (ref) => ExpenseRepository(ref.watch(databaseHelperProvider)),
);

final reimbursementRepositoryProvider = Provider<ReimbursementRepository>(
  (ref) => ReimbursementRepository(ref.watch(databaseHelperProvider)),
);

final receiptRepositoryProvider = Provider<ReceiptRepository>(
  (ref) => ReceiptRepository(ref.watch(databaseHelperProvider)),
);

/// Service providers.
final receiptStorageServiceProvider = Provider<ReceiptStorageService>(
  (ref) => ReceiptStorageService(),
);

final widgetSyncServiceProvider = Provider<WidgetSyncService>(
  (ref) => WidgetSyncService(ref.watch(expenseRepositoryProvider)),
);

final pdfServiceProvider = Provider<PdfService>(
  (ref) => PdfService(ref.watch(receiptStorageServiceProvider)),
);

