import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

/// Lets the user choose where a backup is saved and which one to restore.
abstract class BackupFiles {
  /// Returns false when the user cancels.
  Future<bool> save(String fileName, Uint8List bytes);

  /// Returns null when the user cancels.
  Future<Uint8List?> pick();
}

/// Uses the system file dialogs (Android's Files app, iOS Files).
class SystemBackupFiles implements BackupFiles {
  @override
  Future<bool> save(String fileName, Uint8List bytes) async =>
      await FilePicker.saveFile(
        fileName: fileName,
        bytes: bytes,
        mimeType: 'application/octet-stream',
        dialogTitle: 'Save backup',
      ) !=
      null;

  @override
  Future<Uint8List?> pick() async {
    final files = await FilePicker.pickFiles(dialogTitle: 'Choose a backup');
    return files.isEmpty ? null : files.single.readAsBytes();
  }
}
