import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';

class UploadResult {
  final String downloadUrl;
  final String storagePath;
  final int fileSizeBytes;

  const UploadResult({
    required this.downloadUrl,
    required this.storagePath,
    required this.fileSizeBytes,
  });
}

class StorageService {
  final FirebaseStorage _storage;

  StorageService({FirebaseStorage? storage})
      : _storage = storage ?? FirebaseStorage.instance;

  /// Uploads document bytes (supported on Web, Desktop, Mobile) to Firebase Storage
  Future<UploadResult> uploadHealthRecord({
    required String memberId,
    required String recordId,
    required String fileName,
    required Uint8List bytes,
    required String mimeType,
  }) async {
    final cleanFileName = fileName.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    final storagePath = 'healthRecords/$memberId/$recordId/$cleanFileName';
    final ref = _storage.ref().child(storagePath);

    final metadata = SettableMetadata(
      contentType: mimeType,
      customMetadata: {
        'memberId': memberId,
        'recordId': recordId,
        'uploadedAt': DateTime.now().toIso8601String(),
      },
    );

    final uploadTask = ref.putData(bytes, metadata);
    final snapshot = await uploadTask;
    final downloadUrl = await snapshot.ref.getDownloadURL();

    return UploadResult(
      downloadUrl: downloadUrl,
      storagePath: storagePath,
      fileSizeBytes: bytes.length,
    );
  }

  /// Deletes a file from Firebase Storage
  Future<void> deleteFile(String storagePath) async {
    if (storagePath.isEmpty) return;
    try {
      final ref = _storage.ref().child(storagePath);
      await ref.delete();
    } catch (_) {
      // Ignore if file does not exist or already removed
    }
  }
}

