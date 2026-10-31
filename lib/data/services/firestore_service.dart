import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/family_membership_model.dart';
import '../models/family_model.dart';
import '../models/member_profile_model.dart';
import '../models/subscription_model.dart';
import '../models/user_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore;

  FirestoreService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  // Collection references
  CollectionReference<Map<String, dynamic>> get _usersCol =>
      _firestore.collection('users');

  CollectionReference<Map<String, dynamic>> get _memberProfilesCol =>
      _firestore.collection('memberProfiles');

  CollectionReference<Map<String, dynamic>> get _familiesCol =>
      _firestore.collection('families');

  CollectionReference<Map<String, dynamic>> get _membershipsCol =>
      _firestore.collection('familyMemberships');

  CollectionReference<Map<String, dynamic>> get _subscriptionsCol =>
      _firestore.collection('subscriptions');

  // ================= USERS =================
  Future<UserModel?> getUser(String uid) async {
    final doc = await _usersCol.doc(uid).get();
    if (!doc.exists || doc.data() == null) return null;
    return UserModel.fromMap(doc.data()!, uid);
  }

  Future<void> createUser(UserModel user) async {
    // Set with merge to avoid overwriting existing data if re-entered
    await _usersCol.doc(user.uid).set(user.toMap(), SetOptions(merge: true));
  }

  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    data['updatedAt'] = FieldValue.serverTimestamp();
    await _usersCol.doc(uid).set(data, SetOptions(merge: true));
  }

  Future<void> updateOnboardingStatus(String uid, OnboardingStep status) async {
    await _usersCol.doc(uid).set({
      'onboardingStatus': status.toDbValue(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // ================= MEMBER PROFILES =================
  Future<MemberProfileModel?> getMemberProfile(String memberId) async {
    final doc = await _memberProfilesCol.doc(memberId).get();
    if (!doc.exists || doc.data() == null) return null;
    return MemberProfileModel.fromMap(doc.data()!, memberId);
  }

  Future<void> saveMemberProfile(MemberProfileModel profile) async {
    await _memberProfilesCol
        .doc(profile.memberId)
        .set(profile.toMap(), SetOptions(merge: true));
  }

  // ================= FAMILIES =================
  Future<FamilyModel?> getFamily(String familyId) async {
    final doc = await _familiesCol.doc(familyId).get();
    if (!doc.exists || doc.data() == null) return null;
    return FamilyModel.fromMap(doc.data()!, familyId);
  }

  Future<FamilyModel?> getFamilyByAdmin(String adminUid) async {
    final query = await _familiesCol
        .where('adminUid', isEqualTo: adminUid)
        .limit(1)
        .get();
    if (query.docs.isEmpty) return null;
    return FamilyModel.fromMap(query.docs.first.data(), query.docs.first.id);
  }

  Future<void> saveFamily(FamilyModel family) async {
    await _familiesCol
        .doc(family.familyId)
        .set(family.toMap(), SetOptions(merge: true));
  }

  // ================= FAMILY MEMBERSHIPS =================
  Future<void> saveMembership(FamilyMembershipModel membership) async {
    await _membershipsCol
        .doc(membership.membershipId)
        .set(membership.toMap(), SetOptions(merge: true));
  }

  Future<FamilyMembershipModel?> getAdminMembership(String familyId, String memberId) async {
    // 1. Direct deterministic document lookup (requires no query or index)
    final directDoc = await _membershipsCol.doc('${familyId}_$memberId').get();
    if (directDoc.exists && directDoc.data() != null) {
      return FamilyMembershipModel.fromMap(directDoc.data()!, directDoc.id);
    }

    // 2. Fallback: single-field query (built-in index), filter in-memory to prevent composite index requirement
    try {
      final query = await _membershipsCol
          .where('familyId', isEqualTo: familyId)
          .get();
      for (final d in query.docs) {
        if (d.data()['memberId'] == memberId) {
          return FamilyMembershipModel.fromMap(d.data(), d.id);
        }
      }
    } catch (_) {}

    return null;
  }

  // ================= SUBSCRIPTIONS =================
  Future<SubscriptionModel?> getSubscriptionForFamily(String familyId) async {
    try {
      // Query with single-field equality and sort in-memory to avoid requiring composite indexes
      final query = await _subscriptionsCol
          .where('familyId', isEqualTo: familyId)
          .get();
      if (query.docs.isEmpty) return null;
      final list = query.docs
          .map((doc) => SubscriptionModel.fromMap(doc.data(), doc.id))
          .toList();
      list.sort((a, b) => (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)));
      return list.first;
    } catch (_) {
      return null;
    }
  }

  Future<void> saveSubscription(SubscriptionModel subscription) async {
    await _subscriptionsCol
        .doc(subscription.subscriptionId)
        .set(subscription.toMap(), SetOptions(merge: true));
  }
}
