import 'package:uuid/uuid.dart';
import '../../core/clinical/clinical_engine.dart';
import '../models/clinical_plan_model.dart';
import '../models/family_membership_model.dart';
import '../models/member_profile_model.dart';
import '../models/profile_completion_model.dart';
import '../services/firestore_service.dart';

class FamilyRepository {
  final FirestoreService? _firestoreService;
  final Uuid _uuid;

  // In-memory static cache to guarantee immediate persistence and consistency
  // across screen navigation, tab switching, and when working offline/with Firestore latency.
  static final Map<String, ProfileCompletionModel> _completionCache = {};
  static final Map<String, ClinicalCollectionPlanModel> _planCache = {};
  static final Map<String, MemberProfileModel> _profileCache = {};

  FamilyRepository({
    FirestoreService? firestoreService,
    Uuid? uuid,
  })  : _firestoreService = firestoreService ?? _resolveFirestoreService(),
        _uuid = uuid ?? const Uuid();

  static FirestoreService? _resolveFirestoreService() {
    try {
      return FirestoreService();
    } catch (_) {
      return null;
    }
  }

  /// Fetch all members belonging to a family, ensuring Admin profile is always included
  Future<List<MemberProfileModel>> getFamilyMembers({
    required String familyId,
    required MemberProfileModel? adminProfile,
    required String adminUid,
  }) async {
    final memberList = <MemberProfileModel>[];

    final fs = _firestoreService;
    if (fs != null) {
      try {
        final members = await fs.getMemberProfilesForFamily(familyId);
        memberList.addAll(members);
      } catch (_) {}
    }

    // Merge in-memory cached profiles
    for (final cached in _profileCache.values) {
      final idx = memberList.indexWhere((m) => m.memberId == cached.memberId);
      if (idx >= 0) {
        memberList[idx] = cached;
      } else if (cached.householdId == familyId || cached.memberId.contains(adminUid)) {
        memberList.add(cached);
      }
    }

    // Ensure the admin's profile is always present and marked as Self / Admin
    final adminMemberId = adminProfile?.memberId ?? 'mem_$adminUid';
    final adminIndex = memberList.indexWhere((m) => m.memberId == adminMemberId);

    if (adminIndex >= 0) {
      // Admin is present, ensure relationship and managementType reflect admin
      final existingAdmin = memberList[adminIndex];
      memberList[adminIndex] = existingAdmin.copyWith(
        relationship: 'Self',
        householdId: familyId,
        managementType: 'adminManaged',
      );
    } else if (adminProfile != null) {
      // Check cache for admin profile
      final cachedAdmin = _profileCache[adminMemberId];
      final normalizedAdmin = (cachedAdmin ?? adminProfile).copyWith(
        relationship: 'Self',
        householdId: familyId,
        managementType: 'adminManaged',
      );
      memberList.insert(0, normalizedAdmin);
      _profileCache[adminMemberId] = normalizedAdmin;

      // Also persist to Firestore so future queries find it immediately
      if (fs != null) {
        try {
          await fs.saveMemberProfile(normalizedAdmin);
          await fs.saveMembership(FamilyMembershipModel(
            membershipId: '${familyId}_${normalizedAdmin.memberId}',
            familyId: familyId,
            memberId: normalizedAdmin.memberId,
            role: 'ADMIN',
            status: 'ACTIVE',
            createdAt: DateTime.now(),
          ));
        } catch (_) {}
      }
    }

    // Attach up-to-date completion status for each member
    for (int i = 0; i < memberList.length; i++) {
      final m = memberList[i];
      ProfileCompletionModel? completion = _completionCache[m.memberId];

      if (completion == null && fs != null) {
        try {
          completion = await fs.getProfileCompletion(m.memberId);
          if (completion != null) {
            _completionCache[m.memberId] = completion;
          }
        } catch (_) {}
      }

      if (completion != null) {
        final cached = _profileCache[m.memberId];
        memberList[i] = m.copyWith(
          bloodGroup: cached?.bloodGroup ?? m.bloodGroup,
          emergencyContactName: cached?.emergencyContactName ?? m.emergencyContactName,
          emergencyContactPhone: cached?.emergencyContactPhone ?? m.emergencyContactPhone,
          emergencyContactRelationship: cached?.emergencyContactRelationship ?? m.emergencyContactRelationship,
          completionPercentage: completion.overallPercentage,
          tier1Status: completion.tier1Status,
          tier2Status: completion.tier2Status,
          tier3Status: completion.tier3Status,
          tier4Status: completion.tier4Status,
          profileStatus: completion.overallPercentage >= 100.0
              ? 'Completed'
              : completion.overallPercentage > 0.0
                  ? 'In Progress'
                  : 'Not Started',
        );
      }
    }

    return memberList;
  }

  /// Create a new family member profile with clinical plan and completion record
  Future<MemberProfileModel> addFamilyMember({
    required String familyId,
    required String adminUid,
    required String fullName,
    required DateTime dateOfBirth,
    required String gender,
    required String relationship,
    required String managementType,
    String? bloodGroup,
    String? phone,
    AddressModel? address,
  }) async {
    final generatedMemberId =
        'mem_${DateTime.now().millisecondsSinceEpoch.toRadixString(36)}_${_uuid.v4().substring(0, 4)}';

    final member = MemberProfileModel(
      memberId: generatedMemberId,
      householdId: familyId,
      fullName: fullName,
      dateOfBirth: dateOfBirth,
      gender: gender,
      relationship: relationship,
      profileOwnerUserId: adminUid,
      managementType: managementType,
      profileStatus: 'Not Started',
      completionPercentage: 0.0,
      tier1Status: 'Not Started',
      tier2Status: 'Not Started',
      tier3Status: 'Not Started',
      tier4Status: 'Not Started',
      bloodGroup: bloodGroup,
      phone: phone,
      address: address ?? const AddressModel(line: '', city: '', state: '', country: 'India', postalCode: ''),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    _profileCache[generatedMemberId] = member;

    // 1. Generate plan and initial completion
    final isMinor = member.isMinor;
    final plan = ClinicalEngine.generatePlan(
      memberId: generatedMemberId,
      householdId: familyId,
      dateOfBirth: dateOfBirth,
      gender: gender,
      relationship: relationship,
      managementType: managementType,
    );
    _planCache[generatedMemberId] = plan;

    final initialCompletion = ClinicalEngine.calculateCompletion(
      plan: plan,
      tierData: const {},
      consentGiven: const {},
      memberId: generatedMemberId,
      householdId: familyId,
    );
    _completionCache[generatedMemberId] = initialCompletion;

    final fs = _firestoreService;
    if (fs != null) {
      try {
        await fs.saveMemberProfile(member);
        await fs.saveMembership(FamilyMembershipModel(
          membershipId: '${familyId}_$generatedMemberId',
          familyId: familyId,
          memberId: generatedMemberId,
          role: isMinor ? 'DEPENDENT' : 'MEMBER',
          status: 'ACTIVE',
          createdAt: DateTime.now(),
        ));
        await fs.saveClinicalPlan(plan);
        await fs.saveProfileCompletion(initialCompletion);
      } catch (_) {}
    }

    return member;
  }

  /// Ensure member has a Clinical Collection Plan (generates if missing)
  Future<ClinicalCollectionPlanModel> ensureClinicalPlan(MemberProfileModel member) async {
    if (_planCache.containsKey(member.memberId)) {
      return _planCache[member.memberId]!;
    }

    final fs = _firestoreService;
    if (fs != null) {
      try {
        final existing = await fs.getClinicalPlan(member.memberId);
        if (existing != null) {
          _planCache[member.memberId] = existing;
          return existing;
        }
      } catch (_) {}
    }

    final plan = ClinicalEngine.generatePlan(
      memberId: member.memberId,
      householdId: member.householdId ?? 'fam_${member.memberId}',
      dateOfBirth: member.dateOfBirth,
      gender: member.gender,
      relationship: member.relationship,
      managementType: member.managementType,
    );
    _planCache[member.memberId] = plan;

    if (fs != null) {
      try {
        await fs.saveClinicalPlan(plan);
      } catch (_) {}
    }
    return plan;
  }

  /// Ensure member has a Profile Completion record (initializes if missing)
  Future<ProfileCompletionModel> ensureProfileCompletion(
    MemberProfileModel member,
    ClinicalCollectionPlanModel plan,
  ) async {
    if (_completionCache.containsKey(member.memberId)) {
      return _completionCache[member.memberId]!;
    }

    final fs = _firestoreService;
    if (fs != null) {
      try {
        final existing = await fs.getProfileCompletion(member.memberId);
        if (existing != null) {
          _completionCache[member.memberId] = existing;
          return existing;
        }
      } catch (_) {}
    }

    final initial = ClinicalEngine.calculateCompletion(
      plan: plan,
      tierData: const {},
      consentGiven: const {},
      memberId: member.memberId,
      householdId: member.householdId ?? 'fam_${member.memberId}',
    );
    _completionCache[member.memberId] = initial;

    if (fs != null) {
      try {
        await fs.saveProfileCompletion(initial);
      } catch (_) {}
    }
    return initial;
  }

  /// Save answers for a specific tier, update consent, recalculate progress, and persist
  Future<ProfileCompletionModel> saveTierAnswers({
    required MemberProfileModel member,
    required ClinicalCollectionPlanModel plan,
    required Map<String, dynamic> newSectionAnswers,
    Map<String, bool>? newConsentMap,
  }) async {
    final current = await ensureProfileCompletion(member, plan);

    final mergedTierData = Map<String, dynamic>.from(current.tierData);
    newSectionAnswers.forEach((k, v) {
      mergedTierData[k] = v;
    });

    final mergedConsent = Map<String, bool>.from(current.consentGiven);
    if (newConsentMap != null) {
      newConsentMap.forEach((k, v) {
        mergedConsent[k] = v;
      });
    }

    final updated = ClinicalEngine.calculateCompletion(
      plan: plan,
      tierData: mergedTierData,
      consentGiven: mergedConsent,
      memberId: member.memberId,
      householdId: member.householdId ?? 'fam_${member.memberId}',
    );

    _completionCache[member.memberId] = updated;

    // Check if blood group or emergency contact details were updated in Tier 1
    String? updatedBloodGroup = member.bloodGroup;
    if (newSectionAnswers.containsKey('t1_blood_group')) {
      final bgMap = newSectionAnswers['t1_blood_group'];
      if (bgMap is Map && bgMap['fields'] is Map) {
        final f = bgMap['fields'] as Map;
        final abo = f['bloodGroup']?.toString();
        final rh = f['rhFactor']?.toString();
        if (abo != null && abo.isNotEmpty && abo != 'Unknown') {
          final rhSign = rh == 'Positive' ? '+' : rh == 'Negative' ? '-' : '';
          updatedBloodGroup = '$abo$rhSign';
        }
      }
    }

    String? updatedEmergName = member.emergencyContactName;
    String? updatedEmergPhone = member.emergencyContactPhone;
    String? updatedEmergRel = member.emergencyContactRelationship;
    if (newSectionAnswers.containsKey('t1_emergency_contacts')) {
      final ecMap = newSectionAnswers['t1_emergency_contacts'];
      if (ecMap is Map && ecMap['fields'] is Map) {
        final f = ecMap['fields'] as Map;
        updatedEmergName = f['contact1Name']?.toString() ?? updatedEmergName;
        updatedEmergPhone = f['contact1Phone']?.toString() ?? updatedEmergPhone;
        updatedEmergRel = f['contact1Relationship']?.toString() ?? updatedEmergRel;
      }
    }

    final updatedProfile = member.copyWith(
      bloodGroup: updatedBloodGroup,
      emergencyContactName: updatedEmergName,
      emergencyContactPhone: updatedEmergPhone,
      emergencyContactRelationship: updatedEmergRel,
      completionPercentage: updated.overallPercentage,
      tier1Status: updated.tier1Status,
      tier2Status: updated.tier2Status,
      tier3Status: updated.tier3Status,
      tier4Status: updated.tier4Status,
      profileStatus: updated.overallPercentage >= 100.0
          ? 'Completed'
          : updated.overallPercentage > 0.0
              ? 'In Progress'
              : 'Not Started',
      updatedAt: DateTime.now(),
    );

    _profileCache[member.memberId] = updatedProfile;

    // Save updated completion and member profile status to Firestore
    final fs = _firestoreService;
    if (fs != null) {
      try {
        await fs.saveProfileCompletion(updated);
        await fs.saveMemberProfile(updatedProfile);
      } catch (_) {}
    }

    return updated;
  }
}
