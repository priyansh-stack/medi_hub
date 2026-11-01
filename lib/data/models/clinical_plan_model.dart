import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class ClinicalCollectionPlanModel extends Equatable {
  final String planId;
  final String memberId;
  final String householdId;
  final String ageBand; // 'pediatric', 'adolescent', 'adult', 'geriatric'
  final String rulesetVersions;
  final int memberContextVersion;
  final List<String> requiredFields;
  final List<String> onboardingFields;
  final List<String> progressiveFields;
  final List<String> eventTriggeredFields;
  final List<String> optionalFields;
  final List<String> gatedFields;
  final List<String> excludedFields;
  final DateTime generatedAt;
  final String planHash;

  const ClinicalCollectionPlanModel({
    required this.planId,
    required this.memberId,
    required this.householdId,
    this.ageBand = 'adult',
    this.rulesetVersions = 'v1.0.0',
    this.memberContextVersion = 1,
    this.requiredFields = const [],
    this.onboardingFields = const [],
    this.progressiveFields = const [],
    this.eventTriggeredFields = const [],
    this.optionalFields = const [],
    this.gatedFields = const [],
    this.excludedFields = const [],
    required this.generatedAt,
    required this.planHash,
  });

  Map<String, dynamic> toMap() {
    return {
      'planId': planId,
      'memberId': memberId,
      'householdId': householdId,
      'ageBand': ageBand,
      'rulesetVersions': rulesetVersions,
      'memberContextVersion': memberContextVersion,
      'requiredFields': requiredFields,
      'onboardingFields': onboardingFields,
      'progressiveFields': progressiveFields,
      'eventTriggeredFields': eventTriggeredFields,
      'optionalFields': optionalFields,
      'gatedFields': gatedFields,
      'excludedFields': excludedFields,
      'generatedAt': Timestamp.fromDate(generatedAt),
      'planHash': planHash,
    };
  }

  factory ClinicalCollectionPlanModel.fromMap(Map<String, dynamic> map, String planId) {
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    List<String> parseList(dynamic val) {
      if (val is List) return val.map((e) => e.toString()).toList();
      return const [];
    }

    return ClinicalCollectionPlanModel(
      planId: planId,
      memberId: map['memberId'] as String? ?? '',
      householdId: map['householdId'] as String? ?? '',
      ageBand: map['ageBand'] as String? ?? 'adult',
      rulesetVersions: map['rulesetVersions'] as String? ?? 'v1.0.0',
      memberContextVersion: (map['memberContextVersion'] as num?)?.toInt() ?? 1,
      requiredFields: parseList(map['requiredFields']),
      onboardingFields: parseList(map['onboardingFields']),
      progressiveFields: parseList(map['progressiveFields']),
      eventTriggeredFields: parseList(map['eventTriggeredFields']),
      optionalFields: parseList(map['optionalFields']),
      gatedFields: parseList(map['gatedFields']),
      excludedFields: parseList(map['excludedFields']),
      generatedAt: parseDate(map['generatedAt']),
      planHash: map['planHash'] as String? ?? '',
    );
  }

  @override
  List<Object?> get props => [
        planId,
        memberId,
        householdId,
        ageBand,
        rulesetVersions,
        memberContextVersion,
        requiredFields,
        onboardingFields,
        progressiveFields,
        eventTriggeredFields,
        optionalFields,
        gatedFields,
        excludedFields,
        generatedAt,
        planHash,
      ];
}

