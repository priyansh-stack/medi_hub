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
  final String fullName;
  final DateTime? dateOfBirth;
  final String gender;
  final String? bloodGroup;
  final String? phone;
  final AddressModel address;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const MemberProfileModel({
    required this.memberId,
    required this.fullName,
    this.dateOfBirth,
    required this.gender,
    this.bloodGroup,
    this.phone,
    required this.address,
    this.createdAt,
    this.updatedAt,
  });

  MemberProfileModel copyWith({
    String? memberId,
    String? fullName,
    DateTime? dateOfBirth,
    String? gender,
    String? bloodGroup,
    String? phone,
    AddressModel? address,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MemberProfileModel(
      memberId: memberId ?? this.memberId,
      fullName: fullName ?? this.fullName,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'memberId': memberId,
      'fullName': fullName,
      'dateOfBirth': dateOfBirth != null ? Timestamp.fromDate(dateOfBirth!) : null,
      'gender': gender,
      'bloodGroup': bloodGroup,
      'phone': phone,
      'address': address.toMap(),
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

    return MemberProfileModel(
      memberId: memberId,
      fullName: map['fullName'] as String? ?? '',
      dateOfBirth: parseDate(map['dateOfBirth']),
      gender: map['gender'] as String? ?? 'Not specified',
      bloodGroup: map['bloodGroup'] as String?,
      phone: map['phone'] as String?,
      address: AddressModel.fromMap(map['address'] as Map<String, dynamic>?),
      createdAt: parseDate(map['createdAt']),
      updatedAt: parseDate(map['updatedAt']),
    );
  }

  @override
  List<Object?> get props => [
        memberId,
        fullName,
        dateOfBirth,
        gender,
        bloodGroup,
        phone,
        address,
        createdAt,
        updatedAt,
      ];
}
