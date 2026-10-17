import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../core/utils/constants.dart';

/// Manages local receipt image files in app-private storage.
/// Images are copied into `<app_docs>/receipts/` and only the basename
/// is stored in the database.
class ReceiptStorageService {
  Future<Directory> _getReceiptsDir() async {
    final docsDir = await getApplicationDocumentsDirectory();
    final receiptsDir = Directory(p.join(docsDir.path, Constants.receiptsDirName));
    if (!await receiptsDir.exists()) {
      await receiptsDir.create(recursive: true);
    }
    return receiptsDir;
  }

  /// Copies an image file into the private receipts directory.
  /// Returns the stored file's name (basename only).
  Future<String> saveReceipt(File sourceImage) async {
    final dir = await _getReceiptsDir();
    final ext = p.extension(sourceImage.path).isNotEmpty
        ? p.extension(sourceImage.path)
        : '.jpg';
    final fileName = 'rcpt_${DateTime.now().millisecondsSinceEpoch}_${sourceImage.hashCode}$ext';
    final destinationPath = p.join(dir.path, fileName);
    
    await sourceImage.copy(destinationPath);
    return fileName;
  }

  /// Resolves the full path to a receipt file given its DB filename.
  Future<String> getReceiptPath(String fileName) async {
    final dir = await _getReceiptsDir();
    return p.join(dir.path, fileName);
  }

  /// Returns the [File] object for a receipt image.
  Future<File> getReceiptFile(String fileName) async {
    final fullPath = await getReceiptPath(fileName);
    return File(fullPath);
  }

  /// Deletes a receipt file from disk if it exists.
  Future<void> deleteReceipt(String fileName) async {
    final file = await getReceiptFile(fileName);
    if (await file.exists()) {
      await file.delete();
    }
  }
}
