import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

enum OnboardingStep {
  noAccount,
  accountCreated,
  emailVerified,
  contactSaved,
  profileSaved,
  familyCreated,
  planSelected,
  completed;

  static OnboardingStep fromString(String? value) {
    switch (value) {
      case 'accountCreated':
      case 'ACCOUNT_CREATED':
        return OnboardingStep.accountCreated;
      case 'emailVerified':
      case 'EMAIL_VERIFIED':
        return OnboardingStep.emailVerified;
      case 'contactSaved':
      case 'CONTACT_SAVED':
        return OnboardingStep.contactSaved;
      case 'profileSaved':
      case 'PROFILE_SAVED':
        return OnboardingStep.profileSaved;
      case 'familyCreated':
      case 'FAMILY_CREATED':
        return OnboardingStep.familyCreated;
      case 'planSelected':
      case 'PLAN_SELECTED':
        return OnboardingStep.planSelected;
      case 'completed':
      case 'COMPLETED':
        return OnboardingStep.completed;
      default:
        return OnboardingStep.noAccount;
    }
  }

  String toDbValue() {
    switch (this) {
      case OnboardingStep.noAccount:
        return 'NO_ACCOUNT';
      case OnboardingStep.accountCreated:
        return 'ACCOUNT_CREATED';
      case OnboardingStep.emailVerified:
        return 'EMAIL_VERIFIED';
      case OnboardingStep.contactSaved:
        return 'CONTACT_SAVED';
      case OnboardingStep.profileSaved:
        return 'PROFILE_SAVED';
      case OnboardingStep.familyCreated:
        return 'FAMILY_CREATED';
      case OnboardingStep.planSelected:
        return 'PLAN_SELECTED';
      case OnboardingStep.completed:
        return 'COMPLETED';
    }
  }
}

class UserModel extends Equatable {
  final String uid;
  final String fullName;
  final String email;
  final bool emailVerified;
  final String? memberId;
  final String? pendingPlanId;
  final OnboardingStep onboardingStatus;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const UserModel({
    required this.uid,
    required this.fullName,
    required this.email,
    required this.emailVerified,
    this.memberId,
    this.pendingPlanId,
    this.onboardingStatus = OnboardingStep.accountCreated,
    this.createdAt,
    this.updatedAt,
  });

  UserModel copyWith({
    String? uid,
    String? fullName,
    String? email,
    bool? emailVerified,
    String? memberId,
    String? pendingPlanId,
    OnboardingStep? onboardingStatus,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      emailVerified: emailVerified ?? this.emailVerified,
      memberId: memberId ?? this.memberId,
      pendingPlanId: pendingPlanId ?? this.pendingPlanId,
      onboardingStatus: onboardingStatus ?? this.onboardingStatus,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'fullName': fullName,
      'email': email,
      'emailVerified': emailVerified,
      'memberId': memberId,
      'pendingPlanId': pendingPlanId,
      'onboardingStatus': onboardingStatus.toDbValue(),
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  Map<String, dynamic> toJsonMap() {
    return {
      'uid': uid,
      'fullName': fullName,
      'email': email,
      'emailVerified': emailVerified,
      'memberId': memberId,
      'pendingPlanId': pendingPlanId,
      'onboardingStatus': onboardingStatus.toDbValue(),
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory UserModel.fromJsonMap(Map<String, dynamic> map) {
    return UserModel.fromMap(map, map['uid'] as String? ?? '');
  }

  factory UserModel.fromMap(Map<String, dynamic> map, String uid) {
    DateTime? parseDate(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.tryParse(value);
      return null;
    }

    return UserModel(
      uid: uid,
      fullName: map['fullName'] as String? ?? '',
      email: map['email'] as String? ?? '',
      emailVerified: map['emailVerified'] as bool? ?? false,
      memberId: map['memberId'] as String?,
      pendingPlanId: map['pendingPlanId'] as String?,
      onboardingStatus: OnboardingStep.fromString(map['onboardingStatus'] as String?),
      createdAt: parseDate(map['createdAt']),
      updatedAt: parseDate(map['updatedAt']),
    );
  }

  @override
  List<Object?> get props => [
        uid,
        fullName,
        email,
        emailVerified,
        memberId,
        pendingPlanId,
        onboardingStatus,
        createdAt,
        updatedAt,
      ];
}
