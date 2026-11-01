import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class ProfileCompletionModel extends Equatable {
  final String memberId;
  final String householdId;
  final double overallPercentage;
  final String tier1Status; // 'Not Started', 'In Progress', 'Completed'
  final String tier2Status;
  final String tier3Status;
  final String tier4Status;
  final List<String> completedSections;
  final List<String> pendingSections;
  final Map<String, dynamic> tierData;
  final Map<String, bool> consentGiven;
  final DateTime lastUpdatedAt;

  const ProfileCompletionModel({
    required this.memberId,
    required this.householdId,
    this.overallPercentage = 0.0,
    this.tier1Status = 'Not Started',
    this.tier2Status = 'Not Started',
    this.tier3Status = 'Not Started',
    this.tier4Status = 'Not Started',
    this.completedSections = const [],
    this.pendingSections = const [],
    this.tierData = const {},
    this.consentGiven = const {},
    required this.lastUpdatedAt,
  });

  ProfileCompletionModel copyWith({
    String? memberId,
    String? householdId,
    double? overallPercentage,
    String? tier1Status,
    String? tier2Status,
    String? tier3Status,
    String? tier4Status,
    List<String>? completedSections,
    List<String>? pendingSections,
    Map<String, dynamic>? tierData,
    Map<String, bool>? consentGiven,
    DateTime? lastUpdatedAt,
  }) {
    return ProfileCompletionModel(
      memberId: memberId ?? this.memberId,
      householdId: householdId ?? this.householdId,
      overallPercentage: overallPercentage ?? this.overallPercentage,
      tier1Status: tier1Status ?? this.tier1Status,
      tier2Status: tier2Status ?? this.tier2Status,
      tier3Status: tier3Status ?? this.tier3Status,
      tier4Status: tier4Status ?? this.tier4Status,
      completedSections: completedSections ?? this.completedSections,
      pendingSections: pendingSections ?? this.pendingSections,
      tierData: tierData ?? this.tierData,
      consentGiven: consentGiven ?? this.consentGiven,
      lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'memberId': memberId,
      'householdId': householdId,
      'overallPercentage': overallPercentage,
      'tier1Status': tier1Status,
      'tier2Status': tier2Status,
      'tier3Status': tier3Status,
      'tier4Status': tier4Status,
      'completedSections': completedSections,
      'pendingSections': pendingSections,
      'tierData': tierData,
      'consentGiven': consentGiven,
      'lastUpdatedAt': Timestamp.fromDate(lastUpdatedAt),
    };
  }

  factory ProfileCompletionModel.fromMap(Map<String, dynamic> map, String memberId) {
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    List<String> parseList(dynamic val) {
      if (val is List) return val.map((e) => e.toString()).toList();
      return const [];
    }

    Map<String, dynamic> parseMap(dynamic val) {
      if (val is Map) return Map<String, dynamic>.from(val);
      return const {};
    }

    Map<String, bool> parseConsentMap(dynamic val) {
      if (val is Map) {
        final result = <String, bool>{};
        val.forEach((k, v) {
          result[k.toString()] = v == true;
        });
        return result;
      }
      return const {};
    }

    return ProfileCompletionModel(
      memberId: memberId,
      householdId: map['householdId'] as String? ?? '',
      overallPercentage: (map['overallPercentage'] as num?)?.toDouble() ?? 0.0,
      tier1Status: map['tier1Status'] as String? ?? 'Not Started',
      tier2Status: map['tier2Status'] as String? ?? 'Not Started',
      tier3Status: map['tier3Status'] as String? ?? 'Not Started',
      tier4Status: map['tier4Status'] as String? ?? 'Not Started',
      completedSections: parseList(map['completedSections']),
      pendingSections: parseList(map['pendingSections']),
      tierData: parseMap(map['tierData']),
      consentGiven: parseConsentMap(map['consentGiven']),
      lastUpdatedAt: parseDate(map['lastUpdatedAt']),
    );
  }

  @override
  List<Object?> get props => [
        memberId,
        householdId,
        overallPercentage,
        tier1Status,
        tier2Status,
        tier3Status,
        tier4Status,
        completedSections,
        pendingSections,
        tierData,
        consentGiven,
        lastUpdatedAt,
      ];
}

