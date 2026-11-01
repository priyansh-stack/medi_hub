import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/appointment_model.dart';
import '../models/clinical_plan_model.dart';
import '../models/family_membership_model.dart';
import '../models/family_model.dart';
import '../models/health_record_model.dart';
import '../models/member_profile_model.dart';
import '../models/payment_transaction_model.dart';
import '../models/profile_completion_model.dart';
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

  CollectionReference<Map<String, dynamic>> get _healthRecordsCol =>
      _firestore.collection('healthRecords');

  CollectionReference<Map<String, dynamic>> get _appointmentsCol =>
      _firestore.collection('appointments');

  CollectionReference<Map<String, dynamic>> get _paymentTransactionsCol =>
      _firestore.collection('paymentTransactions');

  CollectionReference<Map<String, dynamic>> get _clinicalPlansCol =>
      _firestore.collection('clinicalPlans');

  CollectionReference<Map<String, dynamic>> get _profileCompletionsCol =>
      _firestore.collection('profileCompletions');

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

  Future<void> updateFamilyName(String familyId, String familyName) async {
    await _familiesCol.doc(familyId).set({
      'familyName': familyName,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
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

  // ================= HEALTH RECORDS =================
  Future<List<HealthRecordModel>> getHealthRecordsForMember(String memberId) async {
    try {
      final query = await _healthRecordsCol
          .where('memberId', isEqualTo: memberId)
          .get();
      final list = query.docs
          .map((doc) => HealthRecordModel.fromMap(doc.data(), doc.id))
          .toList();
      // Sort in-memory by documentDate descending to avoid composite index requirements
      list.sort((a, b) => b.documentDate.compareTo(a.documentDate));
      return list;
    } catch (_) {
      return [];
    }
  }

  Future<void> saveHealthRecord(HealthRecordModel record) async {
    await _healthRecordsCol
        .doc(record.recordId)
        .set(record.toMap(), SetOptions(merge: true));
  }

  Future<void> deleteHealthRecord(String recordId) async {
    await _healthRecordsCol.doc(recordId).delete();
  }

  Future<void> updateHealthRecord(String recordId, Map<String, dynamic> data) async {
    data['updatedAt'] = FieldValue.serverTimestamp();
    await _healthRecordsCol.doc(recordId).set(data, SetOptions(merge: true));
  }

  // ================= APPOINTMENTS =================
  Future<List<AppointmentModel>> getAppointmentsForMember(String memberId) async {
    try {
      final query = await _appointmentsCol
          .where('memberId', isEqualTo: memberId)
          .get();
      final list = query.docs
          .map((doc) => AppointmentModel.fromMap(doc.data(), doc.id))
          .toList();
      // Sort in-memory by appointmentDate ascending/descending
      list.sort((a, b) => a.appointmentDate.compareTo(b.appointmentDate));
      return list;
    } catch (_) {
      return [];
    }
  }

  Future<void> saveAppointment(AppointmentModel appointment) async {
    await _appointmentsCol
        .doc(appointment.appointmentId)
        .set(appointment.toMap(), SetOptions(merge: true));
  }

  Future<void> updateAppointmentStatus(String appointmentId, String status) async {
    await _appointmentsCol.doc(appointmentId).set({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> rescheduleAppointment(
    String appointmentId,
    DateTime newDate,
    String newTime,
  ) async {
    await _appointmentsCol.doc(appointmentId).set({
      'appointmentDate': Timestamp.fromDate(newDate),
      'appointmentTime': newTime,
      'status': 'Upcoming',
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // ================= PAYMENT TRANSACTIONS =================
  Future<List<PaymentTransactionModel>> getPaymentTransactionsForFamily(String familyId) async {
    try {
      final query = await _paymentTransactionsCol
          .where('familyId', isEqualTo: familyId)
          .get();
      final list = query.docs
          .map((doc) => PaymentTransactionModel.fromMap(doc.data(), doc.id))
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    } catch (_) {
      return [];
    }
  }

  Future<void> savePaymentTransaction(PaymentTransactionModel transaction) async {
    await _paymentTransactionsCol
        .doc(transaction.transactionId)
        .set(transaction.toMap(), SetOptions(merge: true));
  }

  // ================= CLINICAL PLANS & PROFILE COMPLETION =================
  Future<void> saveClinicalPlan(ClinicalCollectionPlanModel plan) async {
    await _clinicalPlansCol
        .doc(plan.memberId)
        .set(plan.toMap(), SetOptions(merge: true));
  }

  Future<ClinicalCollectionPlanModel?> getClinicalPlan(String memberId) async {
    try {
      final doc = await _clinicalPlansCol.doc(memberId).get();
      if (!doc.exists || doc.data() == null) return null;
      return ClinicalCollectionPlanModel.fromMap(doc.data()!, doc.id);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveProfileCompletion(ProfileCompletionModel completion) async {
    await _profileCompletionsCol
        .doc(completion.memberId)
        .set(completion.toMap(), SetOptions(merge: true));
  }

  Future<ProfileCompletionModel?> getProfileCompletion(String memberId) async {
    try {
      final doc = await _profileCompletionsCol.doc(memberId).get();
      if (!doc.exists || doc.data() == null) return null;
      return ProfileCompletionModel.fromMap(doc.data()!, memberId);
    } catch (_) {
      return null;
    }
  }

  // ================= MULTI-MEMBER FAMILY QUERIES =================
  Future<List<FamilyMembershipModel>> getMembershipsForFamily(String familyId) async {
    try {
      final query = await _membershipsCol
          .where('familyId', isEqualTo: familyId)
          .get();
      return query.docs
          .map((d) => FamilyMembershipModel.fromMap(d.data(), d.id))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<MemberProfileModel>> getMemberProfilesForFamily(String familyId) async {
    try {
      // 1. Direct query by householdId
      final directDocs = await _memberProfilesCol
          .where('householdId', isEqualTo: familyId)
          .get();

      final list = <MemberProfileModel>[];
      for (final d in directDocs.docs) {
        list.add(MemberProfileModel.fromMap(d.data(), d.id));
      }

      // 2. Cross-check with memberships to ensure all family members are captured
      final memberships = await getMembershipsForFamily(familyId);
      final existingIds = list.map((m) => m.memberId).toSet();

      for (final m in memberships) {
        if (!existingIds.contains(m.memberId)) {
          final prof = await getMemberProfile(m.memberId);
          if (prof != null) {
            list.add(prof);
            existingIds.add(m.memberId);
          }
        }
      }

      return list;
    } catch (_) {
      return [];
    }
  }
}

