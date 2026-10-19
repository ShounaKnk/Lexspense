import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:printing/printing.dart';
import '../services/import_service.dart';
import 'database_provider.dart';
import 'expense_provider.dart';
import 'reimbursement_provider.dart';
import 'matter_provider.dart';
import 'forum_provider.dart';
import 'category_provider.dart';

enum ImportStatus {
  idle,
  picking,
  parsing,
  completed,
  error,
}

class ImportState {
  final ImportStatus status;
  final double progress; // 0.0 to 1.0
  final int currentItem;
  final int totalItems;
  final ImportResult? result;
  final String? errorMessage;
  final String? savedTemplatePath;

  const ImportState({
    this.status = ImportStatus.idle,
    this.progress = 0.0,
    this.currentItem = 0,
    this.totalItems = 0,
    this.result,
    this.errorMessage,
    this.savedTemplatePath,
  });

  ImportState copyWith({
    ImportStatus? status,
    double? progress,
    int? currentItem,
    int? totalItems,
    ImportResult? result,
    String? errorMessage,
    String? savedTemplatePath,
  }) {
    return ImportState(
      status: status ?? this.status,
      progress: progress ?? this.progress,
      currentItem: currentItem ?? this.currentItem,
      totalItems: totalItems ?? this.totalItems,
      result: result ?? this.result,
      errorMessage: errorMessage ?? this.errorMessage,
      savedTemplatePath: savedTemplatePath ?? this.savedTemplatePath,
    );
  }
}

class ImportNotifier extends Notifier<ImportState> {
  @override
  ImportState build() => const ImportState();

  void reset() {
    state = const ImportState();
  }

  /// Pick an Excel file and import its expenses.
  Future<void> pickAndImport() async {
    try {
      state = state.copyWith(status: ImportStatus.picking, errorMessage: null);

      final pickResult = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
        withData: true,
      );

      if (pickResult == null || pickResult.files.isEmpty) {
        state = state.copyWith(status: ImportStatus.idle);
        return;
      }

      final pickedFile = pickResult.files.first;
      List<int>? fileBytes = pickedFile.bytes;

      if (fileBytes == null && pickedFile.path != null) {
        final f = File(pickedFile.path!);
        if (await f.exists()) {
          fileBytes = await f.readAsBytes();
        }
      }

      if (fileBytes == null || fileBytes.isEmpty) {
        state = state.copyWith(
          status: ImportStatus.error,
          errorMessage: 'Could not read file data. Please try selecting the file again.',
        );
        return;
      }

      state = state.copyWith(
        status: ImportStatus.parsing,
        progress: 0.0,
        currentItem: 0,
        totalItems: 0,
      );

      final importService = ref.read(importServiceProvider);
      final result = await importService.importFromBytes(
        fileBytes,
        onProgress: (current, total) {
          final ratio = total > 0 ? (current / total).clamp(0.0, 1.0) : 0.0;
          state = state.copyWith(
            progress: ratio,
            currentItem: current,
            totalItems: total,
          );
        },
      );

      // Invalidate relevant providers to refresh the app UI
      ref.invalidate(unpaidExpensesProvider);
      ref.invalidate(reimbursementsListProvider);
      ref.invalidate(activeMattersProvider);
      ref.invalidate(allMattersProvider);
      ref.invalidate(activeForumsProvider);
      ref.invalidate(allForumsProvider);
      ref.invalidate(activeCategoriesProvider);
      ref.invalidate(allCategoriesProvider);

      // Sync Android home widget with new counts
      try {
        await ref.read(widgetSyncServiceProvider).updateWidgetData();
      } catch (_) {}

      state = state.copyWith(
        status: ImportStatus.completed,
        result: result,
      );
    } catch (e) {
      state = state.copyWith(
        status: ImportStatus.error,
        errorMessage: e is FormatException ? e.message : e.toString(),
      );
    }
  }

  /// Exports / saves the blank sample template spreadsheet to device storage.
  Future<String?> downloadTemplate() async {
    try {
      final templateBytes = ImportService.generateTemplateBytes();

      String? savePath;
      if (!Platform.isAndroid && !Platform.isIOS) {
        try {
          savePath = await FilePicker.platform.saveFile(
            dialogTitle: 'Save Sample Expense Template',
            fileName: 'lexspense_sample_template.xlsx',
            type: FileType.custom,
            allowedExtensions: ['xlsx'],
          );
        } catch (_) {}
      }

      if (savePath == null) {
        Directory? targetDir;
        if (Platform.isAndroid) {
          final extDir = await getExternalStorageDirectory();
          targetDir = extDir ?? await getApplicationDocumentsDirectory();
        } else {
          targetDir = await getDownloadsDirectory();
        }
        targetDir ??= await getApplicationDocumentsDirectory();
        savePath = p.join(targetDir.path, 'lexspense_sample_template.xlsx');
      }

      final file = File(savePath);
      await file.writeAsBytes(templateBytes);
      state = state.copyWith(savedTemplatePath: savePath);

      // On mobile devices, open share sheet so user can easily save to Drive, Files, or send to others
      if (Platform.isAndroid || Platform.isIOS) {
        try {
          await Printing.sharePdf(
            bytes: Uint8List.fromList(templateBytes),
            filename: 'lexspense_sample_template.xlsx',
          );
        } catch (_) {}
      }

      return savePath;
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to save template: $e',
      );
      return null;
    }
  }
}

final importProvider = NotifierProvider<ImportNotifier, ImportState>(
  ImportNotifier.new,
);
