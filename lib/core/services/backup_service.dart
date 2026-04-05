import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:file_picker/file_picker.dart';
import 'package:get/get.dart';

class BackupService extends GetxService {
  final String dbName = 'stock_flow.db';

  Future<String> _getDbPath() async {
    final dbPath = await getDatabasesPath();
    return join(dbPath, dbName);
  }

  /// Exports the local database using save dialog
  Future<bool> exportDatabase() async {
    try {
      if (kIsWeb) return false;

      final sourcePath = await _getDbPath();
      final sourceFile = File(sourcePath);

      if (!await sourceFile.exists()) {
        return false;
      }

      final dateStr = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
      final backupFileName = 'stock_flow_backup_$dateStr.db';

      // Use saveFile instead of getDirectoryPath to avoid permission issues
      String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'حفظ النسخة الاحتياطية',
        fileName: backupFileName,
        type: FileType.custom,
        allowedExtensions: ['db'],
        bytes: await sourceFile.readAsBytes(),
      );

      if (outputFile != null) {
        // On Android, the bytes parameter already saved the file via native Storage Access Framework.
        // Trying to access the file again using dart:io File might throw a Permission Denied error.
        // We wrap this fallback in a try-catch so it won't crash the successful native save.
        try {
          final destFile = File(outputFile);
          if (!await destFile.exists() || (await destFile.length()) == 0) {
            await destFile.writeAsBytes(await sourceFile.readAsBytes(), flush: true);
          }
        } catch (e) {
          debugPrint('Manual file fallback check skipped (handled natively): $e');
        }
        return true;
      }
      return false; // User canceled
    } catch (e) {
      debugPrint('Backup export failed: $e');
      return false;
    }
  }

  /// Imports a selected database file and overwrites the local one
  Future<bool> importDatabase() async {
    try {
      if (kIsWeb) return false;

      // Let user pick a valid .db file
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['db'],
      );

      if (result != null && result.files.single.path != null) {
        final restorePath = result.files.single.path!;
        final sourceFile = File(restorePath);

        if (!await sourceFile.exists()) {
          return false;
        }

        final destinationPath = await _getDbPath();
        
        // Ensure database connections are closed by closing the current process or overriding safely
        // In our simple case, copying over the existing file replaces the un-locked DB.
        await sourceFile.copy(destinationPath);
        
        return true;
      }
      return false; // User canceled
    } catch (e) {
      debugPrint('Backup import failed: $e');
      return false;
    }
  }
}
