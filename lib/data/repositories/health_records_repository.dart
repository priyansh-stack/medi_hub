import 'dart:typed_data';
import 'package:uuid/uuid.dart';
import '../models/health_record_model.dart';
import '../services/firestore_service.dart';
import '../services/storage_service.dart';

class HealthRecordsRepository {
  final FirestoreService _firestoreService;
  final StorageService _storageService;
  final Uuid _uuid;

  HealthRecordsRepository({
    FirestoreService? firestoreService,
    StorageService? storageService,
    Uuid? uuid,
  })  : _firestoreService = firestoreService ?? FirestoreService(),
        _storageService = storageService ?? StorageService(),
        _uuid = uuid ?? const Uuid();

  Future<List<HealthRecordModel>> getHealthRecords(String memberId) async {
    return await _firestoreService.getHealthRecordsForMember(memberId);
  }

  Future<HealthRecordModel> uploadRecord({
    required String memberId,
    required String familyId,
    required String title,
    required String category,
    required DateTime documentDate,
    String? doctorOrHospital,
    String? description,
    required String fileName,
    required Uint8List bytes,
    required String mimeType,
    required String uploadedBy,
  }) async {
    final recordId = 'rec_${_uuid.v4().substring(0, 8)}';

    // 1. Upload file bytes to Firebase Storage
    final uploadResult = await _storageService.uploadHealthRecord(
      memberId: memberId,
      recordId: recordId,
      fileName: fileName,
      bytes: bytes,
      mimeType: mimeType,
    );

    // Determine extension/type
    final ext = fileName.contains('.') ? fileName.split('.').last.toLowerCase() : 'pdf';

    final record = HealthRecordModel(
      recordId: recordId,
      memberId: memberId,
      familyId: familyId,
      title: title,
      category: category,
      documentUrl: uploadResult.downloadUrl,
      storagePath: uploadResult.storagePath,
      documentDate: documentDate,
      doctorOrHospital: doctorOrHospital,
      description: description,
      fileName: fileName,
      fileType: ext,
      fileSizeBytes: uploadResult.fileSizeBytes,
      uploadedAt: DateTime.now(),
      uploadedBy: uploadedBy,
    );

    // 2. Persist metadata in Cloud Firestore
    await _firestoreService.saveHealthRecord(record);

    return record;
  }

  Future<void> editRecordMetadata({
    required String recordId,
    required String title,
    required String category,
    required DateTime documentDate,
    String? doctorOrHospital,
    String? description,
  }) async {
    await _firestoreService.updateHealthRecord(recordId, {
      'title': title,
      'category': category,
      'documentDate': documentDate,
      'doctorOrHospital': doctorOrHospital,
      'description': description,
    });
  }

  Future<void> deleteRecord(HealthRecordModel record) async {
    // 1. Remove file from Firebase Storage
    if (record.storagePath.isNotEmpty) {
      await _storageService.deleteFile(record.storagePath);
    }
    // 2. Delete metadata doc from Cloud Firestore
    await _firestoreService.deleteHealthRecord(record.recordId);
  }
}

