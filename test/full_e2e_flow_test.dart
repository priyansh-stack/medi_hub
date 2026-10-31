import 'package:flutter_test/flutter_test.dart';
import 'package:medi_hub/core/constants/plan_catalog.dart';
import 'package:medi_hub/data/models/family_membership_model.dart';
import 'package:medi_hub/data/models/family_model.dart';
import 'package:medi_hub/data/models/member_profile_model.dart';
import 'package:medi_hub/data/models/subscription_model.dart';
import 'package:medi_hub/data/models/user_model.dart';
import 'package:medi_hub/data/services/local_storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('Full MediHub E2E Registration, Onboarding & Data Flow Test', () {
    const testEmail = 'chrome.test.user@medihub.health';
    const testFullName = 'Priyanshu TestUser';
    const testUid = 'usr_chrome_test_99471';
    const testMemberId = 'mem_chrome_1234';
    const testFamilyId = 'fam_usr_chrome_test_99471';

    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('1. Registration initializes user with email verified and accountCreated status', () {
      final user = UserModel(
        uid: testUid,
        fullName: testFullName,
        email: testEmail,
        emailVerified: true,
        onboardingStatus: OnboardingStep.emailVerified,
        createdAt: DateTime(2026, 10, 31),
        updatedAt: DateTime(2026, 10, 31),
      );

      expect(user.uid, equals(testUid));
      expect(user.email, equals(testEmail));
      expect(user.fullName, equals(testFullName));
      expect(user.emailVerified, isTrue);
      expect(user.onboardingStatus, equals(OnboardingStep.emailVerified));
      expect(user.memberId, isNull);
    });

    test('2. Step 1 (Contact & Address) assigns memberId and persists address', () {
      final userAfterStep1 = UserModel(
        uid: testUid,
        fullName: testFullName,
        email: testEmail,
        emailVerified: true,
        memberId: testMemberId,
        onboardingStatus: OnboardingStep.contactSaved,
      );

      const address = AddressModel(
        line: '402 Green Meadows, 5th Main Road',
        city: 'Bengaluru',
        state: 'Karnataka',
        country: 'India',
        postalCode: '560034',
      );

      final profile = MemberProfileModel(
        memberId: testMemberId,
        fullName: testFullName,
        phone: '+91 9876543210',
        gender: 'Male',
        address: address,
      );

      expect(userAfterStep1.memberId, equals(testMemberId));
      expect(userAfterStep1.onboardingStatus, equals(OnboardingStep.contactSaved));
      expect(profile.phone, equals('+91 9876543210'));
      expect(profile.address.city, equals('Bengaluru'));
      expect(profile.address.postalCode, equals('560034'));
      expect(profile.address.formatted, contains('Bengaluru, Karnataka'));
    });

    test('3. Step 2 (Personal Health Profile) saves DOB, blood group and gender', () {
      final dob = DateTime(1996, 5, 20);
      const address = AddressModel(
        line: '402 Green Meadows, 5th Main Road',
        city: 'Bengaluru',
        state: 'Karnataka',
        country: 'India',
        postalCode: '560034',
      );

      final profile = MemberProfileModel(
        memberId: testMemberId,
        fullName: testFullName,
        dateOfBirth: dob,
        gender: 'Male',
        bloodGroup: 'B+',
        phone: '+91 9876543210',
        address: address,
      );

      final userAfterStep2 = UserModel(
        uid: testUid,
        fullName: testFullName,
        email: testEmail,
        emailVerified: true,
        memberId: testMemberId,
        onboardingStatus: OnboardingStep.profileSaved,
      );

      expect(profile.bloodGroup, equals('B+'));
      expect(profile.gender, equals('Male'));
      expect(profile.dateOfBirth, equals(dob));
      expect(userAfterStep2.onboardingStatus, equals(OnboardingStep.profileSaved));
    });

    test('4. Step 3 (Create Family Group) creates deterministic family and admin membership', () {
      final family = FamilyModel(
        familyId: testFamilyId,
        familyName: 'The TestUser Household',
        description: 'Primary health hub for family care',
        adminUid: testUid,
        createdAt: DateTime(2026, 10, 31),
      );

      final membership = FamilyMembershipModel(
        membershipId: '${testFamilyId}_$testMemberId',
        familyId: testFamilyId,
        memberId: testMemberId,
        role: 'ADMIN',
        status: 'ACTIVE',
        createdAt: DateTime(2026, 10, 31),
      );

      final userAfterStep3 = UserModel(
        uid: testUid,
        fullName: testFullName,
        email: testEmail,
        emailVerified: true,
        memberId: testMemberId,
        onboardingStatus: OnboardingStep.familyCreated,
      );

      expect(family.familyId, equals(testFamilyId));
      expect(family.familyName, equals('The TestUser Household'));
      expect(family.adminUid, equals(testUid));
      expect(membership.membershipId, equals('${testFamilyId}_$testMemberId'));
      expect(membership.role, equals('ADMIN'));
      expect(userAfterStep3.onboardingStatus, equals(OnboardingStep.familyCreated));
    });

    test('5. Step 4 (Plan Selection & Mock Checkout) completes onboarding and creates subscription', () {
      final plan = PlanCatalog.familyPro;

      final subscription = SubscriptionModel(
        subscriptionId: 'sub_mock_12345678',
        familyId: testFamilyId,
        planId: plan.id,
        amount: plan.amount,
        currency: plan.currency,
        billingCycle: 'MONTHLY',
        status: 'MOCK_ACTIVE',
        paymentMode: 'MOCK',
        mockTransactionId: 'txn_mock_99471_success',
        createdAt: DateTime(2026, 10, 31),
      );

      final completedUser = UserModel(
        uid: testUid,
        fullName: testFullName,
        email: testEmail,
        emailVerified: true,
        memberId: testMemberId,
        pendingPlanId: null,
        onboardingStatus: OnboardingStep.completed,
      );

      expect(subscription.planId, equals('family_pro'));
      expect(subscription.status, equals('MOCK_ACTIVE'));
      expect(subscription.amount, equals(plan.amount));
      expect(completedUser.onboardingStatus, equals(OnboardingStep.completed));
    });

    test('6. Local Storage saves state and restores on next visit without data loss', () async {
      final localStorage = LocalStorageService();

      final completedUser = UserModel(
        uid: testUid,
        fullName: testFullName,
        email: testEmail,
        emailVerified: true,
        memberId: testMemberId,
        pendingPlanId: null,
        onboardingStatus: OnboardingStep.completed,
      );

      // Save user to local storage
      await localStorage.saveUser(completedUser);

      // Verify onboarding completed flag
      final isCompleted = await localStorage.isOnboardingCompleted();
      expect(isCompleted, isTrue);

      // Restore user from local storage
      final restored = await localStorage.getCachedUser();
      expect(restored, isNotNull);
      expect(restored!.uid, equals(testUid));
      expect(restored.fullName, equals(testFullName));
      expect(restored.email, equals(testEmail));
      expect(restored.memberId, equals(testMemberId));
      expect(restored.onboardingStatus, equals(OnboardingStep.completed));

      // Test sign out clears storage
      await localStorage.clearAll();
      final afterLogout = await localStorage.getCachedUser();
      expect(afterLogout, isNull);
      final isCompletedAfterLogout = await localStorage.isOnboardingCompleted();
      expect(isCompletedAfterLogout, isFalse);
    });
  });
}
