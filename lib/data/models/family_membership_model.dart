import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class FamilyMembershipModel extends Equatable {
  final String membershipId;
  final String familyId;
  final String memberId;
  final String role; // 'ADMIN'
  final String status; // 'ACTIVE'
  final DateTime? createdAt;

  const FamilyMembershipModel({
    required this.membershipId,
    required this.familyId,
    required this.memberId,
    this.role = 'ADMIN',
    this.status = 'ACTIVE',
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'membershipId': membershipId,
      'familyId': familyId,
      'memberId': memberId,
      'role': role,
      'status': status,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
    };
  }

  factory FamilyMembershipModel.fromMap(Map<String, dynamic> map, String membershipId) {
    DateTime? parseDate(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.tryParse(value);
      return null;
    }

    return FamilyMembershipModel(
      membershipId: membershipId,
      familyId: map['familyId'] as String? ?? '',
      memberId: map['memberId'] as String? ?? '',
      role: map['role'] as String? ?? 'ADMIN',
      status: map['status'] as String? ?? 'ACTIVE',
      createdAt: parseDate(map['createdAt']),
    );
  }

  @override
  List<Object?> get props => [
        membershipId,
        familyId,
        memberId,
        role,
        status,
        createdAt,
      ];
}
