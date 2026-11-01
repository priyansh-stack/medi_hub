import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class HealthRecordModel extends Equatable {
  final String recordId;
  final String memberId;
  final String familyId;
  final String title;
  final String category;
  final String documentUrl;
  final String storagePath;
  final DateTime documentDate;
  final String? doctorOrHospital;
  final String? description;
  final String fileName;
  final String fileType;
  final int fileSizeBytes;
  final DateTime? uploadedAt;
  final String uploadedBy;

  const HealthRecordModel({
    required this.recordId,
    required this.memberId,
    required this.familyId,
    required this.title,
    required this.category,
    required this.documentUrl,
    required this.storagePath,
    required this.documentDate,
    this.doctorOrHospital,
    this.description,
    required this.fileName,
    required this.fileType,
    required this.fileSizeBytes,
    this.uploadedAt,
    required this.uploadedBy,
  });

  static const List<String> categories = [
    'Prescriptions',
    'Lab Reports',
    'Immunization',
    'Medical Conditions',
    'Allergies',
    'Medications',
    'Other Documents',
  ];

  HealthRecordModel copyWith({
    String? recordId,
    String? memberId,
    String? familyId,
    String? title,
    String? category,
    String? documentUrl,
    String? storagePath,
    DateTime? documentDate,
    String? doctorOrHospital,
    String? description,
    String? fileName,
    String? fileType,
    int? fileSizeBytes,
    DateTime? uploadedAt,
    String? uploadedBy,
  }) {
    return HealthRecordModel(
      recordId: recordId ?? this.recordId,
      memberId: memberId ?? this.memberId,
      familyId: familyId ?? this.familyId,
      title: title ?? this.title,
      category: category ?? this.category,
      documentUrl: documentUrl ?? this.documentUrl,
      storagePath: storagePath ?? this.storagePath,
      documentDate: documentDate ?? this.documentDate,
      doctorOrHospital: doctorOrHospital ?? this.doctorOrHospital,
      description: description ?? this.description,
      fileName: fileName ?? this.fileName,
      fileType: fileType ?? this.fileType,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
      uploadedAt: uploadedAt ?? this.uploadedAt,
      uploadedBy: uploadedBy ?? this.uploadedBy,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'recordId': recordId,
      'memberId': memberId,
      'familyId': familyId,
      'title': title,
      'category': category,
      'documentUrl': documentUrl,
      'storagePath': storagePath,
      'documentDate': Timestamp.fromDate(documentDate),
      'doctorOrHospital': doctorOrHospital,
      'description': description,
      'fileName': fileName,
      'fileType': fileType,
      'fileSizeBytes': fileSizeBytes,
      'uploadedAt': uploadedAt != null ? Timestamp.fromDate(uploadedAt!) : FieldValue.serverTimestamp(),
      'uploadedBy': uploadedBy,
    };
  }

  factory HealthRecordModel.fromMap(Map<String, dynamic> map, String recordId) {
    DateTime parseDate(dynamic value, [DateTime? fallback]) {
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.tryParse(value) ?? fallback ?? DateTime.now();
      return fallback ?? DateTime.now();
    }

    return HealthRecordModel(
      recordId: recordId,
      memberId: map['memberId'] as String? ?? '',
      familyId: map['familyId'] as String? ?? '',
      title: map['title'] as String? ?? '',
      category: map['category'] as String? ?? 'Other Documents',
      documentUrl: map['documentUrl'] as String? ?? '',
      storagePath: map['storagePath'] as String? ?? '',
      documentDate: parseDate(map['documentDate']),
      doctorOrHospital: map['doctorOrHospital'] as String?,
      description: map['description'] as String?,
      fileName: map['fileName'] as String? ?? 'document',
      fileType: map['fileType'] as String? ?? 'pdf',
      fileSizeBytes: (map['fileSizeBytes'] as num?)?.toInt() ?? 0,
      uploadedAt: map['uploadedAt'] != null ? parseDate(map['uploadedAt']) : null,
      uploadedBy: map['uploadedBy'] as String? ?? '',
    );
  }

  @override
  List<Object?> get props => [
        recordId,
        memberId,
        familyId,
        title,
        category,
        documentUrl,
        storagePath,
        documentDate,
        doctorOrHospital,
        description,
        fileName,
        fileType,
        fileSizeBytes,
        uploadedAt,
        uploadedBy,
      ];
}

