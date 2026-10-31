import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class FamilyModel extends Equatable {
  final String familyId;
  final String familyName;
  final String? description;
  final String adminUid;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const FamilyModel({
    required this.familyId,
    required this.familyName,
    this.description,
    required this.adminUid,
    this.createdAt,
    this.updatedAt,
  });

  FamilyModel copyWith({
    String? familyId,
    String? familyName,
    String? description,
    String? adminUid,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FamilyModel(
      familyId: familyId ?? this.familyId,
      familyName: familyName ?? this.familyName,
      description: description ?? this.description,
      adminUid: adminUid ?? this.adminUid,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'familyId': familyId,
      'familyName': familyName,
      'description': description,
      'adminUid': adminUid,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  factory FamilyModel.fromMap(Map<String, dynamic> map, String familyId) {
    DateTime? parseDate(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.tryParse(value);
      return null;
    }

    return FamilyModel(
      familyId: familyId,
      familyName: map['familyName'] as String? ?? '',
      description: map['description'] as String?,
      adminUid: map['adminUid'] as String? ?? '',
      createdAt: parseDate(map['createdAt']),
      updatedAt: parseDate(map['updatedAt']),
    );
  }

  @override
  List<Object?> get props => [
        familyId,
        familyName,
        description,
        adminUid,
        createdAt,
        updatedAt,
      ];
}
