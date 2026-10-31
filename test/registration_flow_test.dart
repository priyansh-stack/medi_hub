import 'package:flutter_test/flutter_test.dart';
import 'package:medi_hub/core/constants/plan_catalog.dart';
import 'package:medi_hub/data/models/family_membership_model.dart';
import 'package:medi_hub/data/models/family_model.dart';
import 'package:medi_hub/data/models/member_profile_model.dart';
import 'package:medi_hub/data/models/subscription_model.dart';
import 'package:medi_hub/data/models/user_model.dart';

void main() {
  group('MediHub Registration & Mock Subscription Flow Test with Test Email', () {
    const testEmail = 'test.user@medihub.health';
    const testUid = 'usr_test_12345';
    const testFullName = 'Priyanshu TestUser';

    test('Step 2: Account creation initializes user model with test email', () {
      final user = UserModel(
        uid: testUid,
        fullName: testFullName,
        email: testEmail,
        emailVerified: false,
        onboardingStatus: OnboardingStep.accountCreated,
        createdAt: DateTime(2026, 10, 30),
      );

      expect(user.email, equals(testEmail));
      expect(user.fullName, equals(testFullName));
      expect(user.emailVerified, isFalse);
      expect(user.onboardingStatus, equals(OnboardingStep.accountCreated));
      expect(user.memberId, isNull);
    });

    test('Step 3: Email verification requirement and status transition', () {
      final unverifiedUser = UserModel(
        uid: testUid,
        fullName: testFullName,
        email: testEmail,
        emailVerified: false,
        onboardingStatus: OnboardingStep.accountCreated,
      );

      // Verify server-side verification check
      final verifiedUser = unverifiedUser.copyWith(
        emailVerified: true,
        onboardingStatus: OnboardingStep.emailVerified,
      );

      expect(verifiedUser.emailVerified, isTrue);
      expect(verifiedUser.onboardingStatus, equals(OnboardingStep.emailVerified));
    });

    test('Step 4 & 5: Contact details and Personal Member Profile with unique memberId', () {
      const generatedMemberId = 'mem_abc12345';

      final userWithProfile = UserModel(
        uid: testUid,
        fullName: testFullName,
        email: testEmail,
        emailVerified: true,
        memberId: generatedMemberId,
        onboardingStatus: OnboardingStep.profileSaved,
      );

      final profile = MemberProfileModel(
        memberId: generatedMemberId,
        fullName: testFullName,
        dateOfBirth: DateTime(1995, 8, 15),
        gender: 'Male',
        bloodGroup: 'O+',
        phone: '+91 9876543210',
        address: const AddressModel(
          line: 'Flat 101, Palm Residency',
          city: 'Bengaluru',
          state: 'Karnataka',
          country: 'India',
          postalCode: '560001',
        ),
      );

      expect(userWithProfile.memberId, equals(generatedMemberId));
      expect(profile.memberId, equals(generatedMemberId));
      expect(profile.bloodGroup, equals('O+'));
      expect(profile.address.city, equals('Bengaluru'));
      expect(profile.address.formatted, contains('Bengaluru, Karnataka'));
    });

    test('Step 6: Create Family Group and assign Family Admin membership', () {
      const familyId = 'fam_kumar_household';
      const memberId = 'mem_abc12345';

      final family = FamilyModel(
        familyId: familyId,
        familyName: 'The Kumar Family',
        description: 'Primary residence group',
        adminUid: testUid,
        createdAt: DateTime(2026, 10, 30),
      );

      final membership = FamilyMembershipModel(
        membershipId: 'mbr_001',
        familyId: familyId,
        memberId: memberId,
        role: 'ADMIN',
        status: 'ACTIVE',
      );

      expect(family.adminUid, equals(testUid));
      expect(membership.familyId, equals(familyId));
      expect(membership.memberId, equals(memberId));
      expect(membership.role, equals('ADMIN'));
      expect(membership.status, equals('ACTIVE'));
    });

    test('Step 7 & 8: Plan Selection & Mock Checkout with Test Email', () {
      const familyId = 'fam_kumar_household';
      final proPlan = PlanCatalog.familyPro;

      // Mock Checkout Success Scenario
      final successSubscription = SubscriptionModel(
        subscriptionId: 'sub_mock_888',
        familyId: familyId,
        planId: proPlan.id,
        amount: proPlan.amount,
        currency: 'INR',
        billingCycle: 'MONTHLY',
        status: 'MOCK_ACTIVE',
        paymentMode: 'MOCK',
        mockTransactionId: 'txn_mock_testuser_123',
        createdAt: DateTime.now(),
      );

      expect(successSubscription.status, equals('MOCK_ACTIVE'));
      expect(successSubscription.paymentMode, equals('MOCK'));
      expect(successSubscription.isActive, isTrue);
      expect(successSubscription.mockTransactionId, contains('txn_mock_'));

      // Mock Checkout Failure Scenario
      final failedSubscription = successSubscription.copyWith(
        status: 'PAYMENT_FAILED',
        mockTransactionId: 'txn_failed_declined',
      );

      expect(failedSubscription.status, equals('PAYMENT_FAILED'));
      expect(failedSubscription.isFailed, isTrue);
      expect(failedSubscription.isActive, isFalse);

      // Free Plan Scenario
      final freePlan = PlanCatalog.familyBasic;
      final freeSubscription = SubscriptionModel(
        subscriptionId: 'sub_free_001',
        familyId: familyId,
        planId: freePlan.id,
        amount: 0,
        currency: 'INR',
        billingCycle: 'MONTHLY',
        status: 'FREE',
        paymentMode: 'MOCK',
      );

      expect(freeSubscription.isFree, isTrue);
      expect(freeSubscription.isActive, isTrue);
    });

    test('Step 9: Onboarding completion and resume state persistence', () {
      final completedUser = UserModel(
        uid: testUid,
        fullName: testFullName,
        email: testEmail,
        emailVerified: true,
        memberId: 'mem_abc12345',
        onboardingStatus: OnboardingStep.completed,
      );

      expect(completedUser.onboardingStatus, equals(OnboardingStep.completed));
      expect(completedUser.onboardingStatus.toDbValue(), equals('COMPLETED'));

      // Test parsing back from Firestore Map
      final rawMap = completedUser.toMap();
      final restored = UserModel.fromMap(rawMap, testUid);

      expect(restored.uid, equals(testUid));
      expect(restored.email, equals(testEmail));
      expect(restored.memberId, equals('mem_abc12345'));
      expect(restored.onboardingStatus, equals(OnboardingStep.completed));
    });
  });
}
