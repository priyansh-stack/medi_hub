import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class AppointmentModel extends Equatable {
  final String appointmentId;
  final String memberId;
  final String familyId;
  final String patientName;
  final String doctorName;
  final String speciality;
  final DateTime appointmentDate;
  final String appointmentTime;
  final String appointmentType; // 'In-person' or 'Teleconsultation'
  final String? reason;
  final String status; // 'Upcoming', 'Completed', 'Cancelled'
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const AppointmentModel({
    required this.appointmentId,
    required this.memberId,
    required this.familyId,
    required this.patientName,
    required this.doctorName,
    required this.speciality,
    required this.appointmentDate,
    required this.appointmentTime,
    required this.appointmentType,
    this.reason,
    this.status = 'Upcoming',
    this.createdAt,
    this.updatedAt,
  });

  AppointmentModel copyWith({
    String? appointmentId,
    String? memberId,
    String? familyId,
    String? patientName,
    String? doctorName,
    String? speciality,
    DateTime? appointmentDate,
    String? appointmentTime,
    String? appointmentType,
    String? reason,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AppointmentModel(
      appointmentId: appointmentId ?? this.appointmentId,
      memberId: memberId ?? this.memberId,
      familyId: familyId ?? this.familyId,
      patientName: patientName ?? this.patientName,
      doctorName: doctorName ?? this.doctorName,
      speciality: speciality ?? this.speciality,
      appointmentDate: appointmentDate ?? this.appointmentDate,
      appointmentTime: appointmentTime ?? this.appointmentTime,
      appointmentType: appointmentType ?? this.appointmentType,
      reason: reason ?? this.reason,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'appointmentId': appointmentId,
      'memberId': memberId,
      'familyId': familyId,
      'patientName': patientName,
      'doctorName': doctorName,
      'speciality': speciality,
      'appointmentDate': Timestamp.fromDate(appointmentDate),
      'appointmentTime': appointmentTime,
      'appointmentType': appointmentType,
      'reason': reason,
      'status': status,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  factory AppointmentModel.fromMap(Map<String, dynamic> map, String appointmentId) {
    DateTime parseDate(dynamic value, [DateTime? fallback]) {
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.tryParse(value) ?? fallback ?? DateTime.now();
      return fallback ?? DateTime.now();
    }

    return AppointmentModel(
      appointmentId: appointmentId,
      memberId: map['memberId'] as String? ?? '',
      familyId: map['familyId'] as String? ?? '',
      patientName: map['patientName'] as String? ?? '',
      doctorName: map['doctorName'] as String? ?? '',
      speciality: map['speciality'] as String? ?? 'General Physician',
      appointmentDate: parseDate(map['appointmentDate']),
      appointmentTime: map['appointmentTime'] as String? ?? '10:00 AM',
      appointmentType: map['appointmentType'] as String? ?? 'In-person',
      reason: map['reason'] as String?,
      status: map['status'] as String? ?? 'Upcoming',
      createdAt: map['createdAt'] != null ? parseDate(map['createdAt']) : null,
      updatedAt: map['updatedAt'] != null ? parseDate(map['updatedAt']) : null,
    );
  }

  @override
  List<Object?> get props => [
        appointmentId,
        memberId,
        familyId,
        patientName,
        doctorName,
        speciality,
        appointmentDate,
        appointmentTime,
        appointmentType,
        reason,
        status,
        createdAt,
        updatedAt,
      ];
}

