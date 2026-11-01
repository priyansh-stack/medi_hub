import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class AddressModel extends Equatable {
  final String line;
  final String city;
  final String state;
  final String country;
  final String postalCode;

  const AddressModel({
    required this.line,
    required this.city,
    required this.state,
    required this.country,
    required this.postalCode,
  });

  Map<String, dynamic> toMap() {
    return {
      'line': line,
      'city': city,
      'state': state,
      'country': country,
      'postalCode': postalCode,
    };
  }

  factory AddressModel.fromMap(Map<String, dynamic>? map) {
    if (map == null) {
      return const AddressModel(
        line: '',
        city: '',
        state: '',
        country: '',
        postalCode: '',
      );
    }
    return AddressModel(
      line: map['line'] as String? ?? '',
      city: map['city'] as String? ?? '',
      state: map['state'] as String? ?? '',
      country: map['country'] as String? ?? '',
      postalCode: map['postalCode'] as String? ?? '',
    );
  }

  String get formatted {
    final parts = [line, city, state, country, postalCode]
        .where((p) => p.trim().isNotEmpty)
        .toList();
    return parts.isEmpty ? 'Not provided' : parts.join(', ');
  }

  @override
  List<Object?> get props => [line, city, state, country, postalCode];
}

class MemberProfileModel extends Equatable {
  final String memberId;
  final String? householdId;
  final String fullName;
  final DateTime? dateOfBirth;
  final String gender;
  final String relationship; // 'Self', 'Spouse', 'Child', 'Parent', 'Sibling', 'Grandparent', 'Other'
  final String? profileOwnerUserId;
  final String managementType; // 'adminManaged', 'independentlyManaged', 'guardianManaged'
  final String profileStatus; // 'Not Started', 'In Progress', 'Completed'
  final double completionPercentage;
  final String tier1Status; // 'Not Started', 'In Progress', 'Completed'
  final String tier2Status;
  final String tier3Status;
  final String tier4Status;
  final String? bloodGroup;
  final String? phone;
  final AddressModel address;
  final String? emergencyContactName;
  final String? emergencyContactRelationship;
  final String? emergencyContactPhone;
  final String? allergies;
  final String? medicalConditions;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const MemberProfileModel({
    required this.memberId,
    this.householdId,
    required this.fullName,
    this.dateOfBirth,
    required this.gender,
    this.relationship = 'Self',
    this.profileOwnerUserId,
    this.managementType = 'adminManaged',
    this.profileStatus = 'Not Started',
    this.completionPercentage = 0.0,
    this.tier1Status = 'Not Started',
    this.tier2Status = 'Not Started',
    this.tier3Status = 'Not Started',
    this.tier4Status = 'Not Started',
    this.bloodGroup,
    this.phone,
    required this.address,
    this.emergencyContactName,
    this.emergencyContactRelationship,
    this.emergencyContactPhone,
    this.allergies,
    this.medicalConditions,
    this.createdAt,
    this.updatedAt,
  });

  /// Computed age in years
  int? get age {
    if (dateOfBirth == null) return null;
    final now = DateTime.now();
    int years = now.year - dateOfBirth!.year;
    if (now.month < dateOfBirth!.month ||
        (now.month == dateOfBirth!.month && now.day < dateOfBirth!.day)) {
      years--;
    }
    return years >= 0 ? years : 0;
  }

  String get ageDisplay {
    final a = age;
    if (a == null) return 'Age not set';
    if (a == 0) return '< 1 yr';
    return '$a yrs';
  }

  bool get isMinor => age != null && age! < 18;

  MemberProfileModel copyWith({
    String? memberId,
    String? householdId,
    String? fullName,
    DateTime? dateOfBirth,
    String? gender,
    String? relationship,
    String? profileOwnerUserId,
    String? managementType,
    String? profileStatus,
    double? completionPercentage,
    String? tier1Status,
    String? tier2Status,
    String? tier3Status,
    String? tier4Status,
    String? bloodGroup,
    String? phone,
    AddressModel? address,
    String? emergencyContactName,
    String? emergencyContactRelationship,
    String? emergencyContactPhone,
    String? allergies,
    String? medicalConditions,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MemberProfileModel(
      memberId: memberId ?? this.memberId,
      householdId: householdId ?? this.householdId,
      fullName: fullName ?? this.fullName,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      relationship: relationship ?? this.relationship,
      profileOwnerUserId: profileOwnerUserId ?? this.profileOwnerUserId,
      managementType: managementType ?? this.managementType,
      profileStatus: profileStatus ?? this.profileStatus,
      completionPercentage: completionPercentage ?? this.completionPercentage,
      tier1Status: tier1Status ?? this.tier1Status,
      tier2Status: tier2Status ?? this.tier2Status,
      tier3Status: tier3Status ?? this.tier3Status,
      tier4Status: tier4Status ?? this.tier4Status,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      emergencyContactName: emergencyContactName ?? this.emergencyContactName,
      emergencyContactRelationship:
          emergencyContactRelationship ?? this.emergencyContactRelationship,
      emergencyContactPhone:
          emergencyContactPhone ?? this.emergencyContactPhone,
      allergies: allergies ?? this.allergies,
      medicalConditions: medicalConditions ?? this.medicalConditions,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'memberId': memberId,
      'householdId': householdId,
      'fullName': fullName,
      'name': fullName,
      'dateOfBirth': dateOfBirth != null ? Timestamp.fromDate(dateOfBirth!) : null,
      'gender': gender,
      'relationship': relationship,
      'profileOwnerUserId': profileOwnerUserId,
      'managementType': managementType,
      'profileStatus': profileStatus,
      'completionPercentage': completionPercentage,
      'tier1Status': tier1Status,
      'tier2Status': tier2Status,
      'tier3Status': tier3Status,
      'tier4Status': tier4Status,
      'bloodGroup': bloodGroup,
      'phone': phone,
      'address': address.toMap(),
      'emergencyContactName': emergencyContactName,
      'emergencyContactRelationship': emergencyContactRelationship,
      'emergencyContactPhone': emergencyContactPhone,
      'allergies': allergies,
      'medicalConditions': medicalConditions,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  factory MemberProfileModel.fromMap(Map<String, dynamic> map, String memberId) {
    DateTime? parseDate(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.tryParse(value);
      return null;
    }

    final name = (map['fullName'] ?? map['name']) as String? ?? '';
    final rel = map['relationship'] as String? ?? 'Self';
    final status = map['profileStatus'] as String? ?? 'Not Started';
    final pct = (map['completionPercentage'] as num?)?.toDouble() ?? 0.0;

    return MemberProfileModel(
      memberId: memberId,
      householdId: map['householdId'] as String?,
      fullName: name,
      dateOfBirth: parseDate(map['dateOfBirth']),
      gender: map['gender'] as String? ?? 'Not specified',
      relationship: rel,
      profileOwnerUserId: map['profileOwnerUserId'] as String?,
      managementType: map['managementType'] as String? ?? 'adminManaged',
      profileStatus: status,
      completionPercentage: pct,
      tier1Status: map['tier1Status'] as String? ?? 'Not Started',
      tier2Status: map['tier2Status'] as String? ?? 'Not Started',
      tier3Status: map['tier3Status'] as String? ?? 'Not Started',
      tier4Status: map['tier4Status'] as String? ?? 'Not Started',
      bloodGroup: map['bloodGroup'] as String?,
      phone: map['phone'] as String?,
      address: AddressModel.fromMap(map['address'] as Map<String, dynamic>?),
      emergencyContactName: map['emergencyContactName'] as String?,
      emergencyContactRelationship: map['emergencyContactRelationship'] as String?,
      emergencyContactPhone: map['emergencyContactPhone'] as String?,
      allergies: map['allergies'] as String?,
      medicalConditions: map['medicalConditions'] as String?,
      createdAt: parseDate(map['createdAt']),
      updatedAt: parseDate(map['updatedAt']),
    );
  }

  @override
  List<Object?> get props => [
        memberId,
        householdId,
        fullName,
        dateOfBirth,
        gender,
        relationship,
        profileOwnerUserId,
        managementType,
        profileStatus,
        completionPercentage,
        tier1Status,
        tier2Status,
        tier3Status,
        tier4Status,
        bloodGroup,
        phone,
        address,
        emergencyContactName,
        emergencyContactRelationship,
        emergencyContactPhone,
        allergies,
        medicalConditions,
        createdAt,
        updatedAt,
      ];
}
