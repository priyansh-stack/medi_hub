import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medi_hub/core/constants/plan_catalog.dart';
import 'package:medi_hub/core/theme/app_theme.dart';
import 'package:medi_hub/data/models/family_membership_model.dart';
import 'package:medi_hub/data/models/family_model.dart';
import 'package:medi_hub/data/models/member_profile_model.dart';
import 'package:medi_hub/data/models/payment_transaction_model.dart';
import 'package:medi_hub/data/models/plan_model.dart';
import 'package:medi_hub/data/models/subscription_model.dart';
import 'package:medi_hub/data/models/user_model.dart';
import 'package:medi_hub/data/repositories/auth_repository.dart';
import 'package:medi_hub/data/repositories/onboarding_repository.dart';
import 'package:medi_hub/data/repositories/subscription_repository.dart';
import 'package:medi_hub/logic/auth/auth_bloc.dart';
import 'package:medi_hub/logic/checkout/checkout_cubit.dart';
import 'package:medi_hub/logic/onboarding/onboarding_cubit.dart';
import 'package:medi_hub/logic/onboarding/onboarding_state.dart';
import 'package:medi_hub/presentation/screens/dashboard_screen.dart';
import 'package:medi_hub/presentation/screens/mock_checkout_screen.dart';

class FakeSubscriptionRepository implements SubscriptionRepository {
  @override
  List<PlanModel> getAvailablePlans() => PlanCatalog.plans;

  @override
  PlanModel getPlanById(String planId) => PlanCatalog.findById(planId);

  @override
  Future<SubscriptionModel?> selectPlan({
    required UserModel currentUser,
    required String familyId,
    required PlanModel plan,
  }) async => null;

  @override
  Future<SubscriptionModel> processMockPaymentSuccess({
    required UserModel currentUser,
    required String familyId,
    required PlanModel plan,
  }) async {
    return SubscriptionModel(
      subscriptionId: 'sub_mock_pro',
      familyId: familyId,
      planId: plan.id,
      amount: plan.amount,
      currency: plan.currency,
      billingCycle: 'MONTHLY',
      status: 'MOCK_ACTIVE',
      paymentMode: 'MOCK',
      mockTransactionId: 'txn_mock_9999',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  @override
  Future<SubscriptionModel> processMockPaymentFailure({
    required UserModel currentUser,
    required String familyId,
    required PlanModel plan,
    String? reason,
  }) async {
    return SubscriptionModel(
      subscriptionId: 'sub_mock_fail',
      familyId: familyId,
      planId: plan.id,
      amount: plan.amount,
      currency: plan.currency,
      billingCycle: 'MONTHLY',
      status: 'FAILED',
      paymentMode: 'MOCK',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  @override
  Future<void> cancelCheckout({required UserModel currentUser}) async {}

  @override
  Future<SubscriptionModel?> getFamilySubscription(String familyId) async => null;

  @override
  Future<List<PaymentTransactionModel>> getPaymentHistory(String familyId) async => [];
}

class FakeOnboardingRepository implements OnboardingRepository {
  @override
  Future<UserModel> saveContactAndAddress({
    required UserModel currentUser,
    String? phone,
    required AddressModel address,
  }) async => currentUser;

  @override
  Future<UserModel> savePersonalHealthProfile({
    required UserModel currentUser,
    required String fullName,
    required DateTime dateOfBirth,
    required String gender,
    String? bloodGroup,
    String? phone,
    AddressModel? address,
  }) async => currentUser;

  Future<MemberProfileModel> saveMemberProfile({
    required UserModel currentUser,
    required MemberProfileModel profile,
  }) async => profile;

  @override
  Future<MemberProfileModel> updateMemberProfile(MemberProfileModel profile) async => profile;

  @override
  Future<FamilyModel> updateFamilyName({
    required String familyId,
    required String newName,
  }) async => FamilyModel(familyId: familyId, familyName: newName, adminUid: 'usr_test');

  @override
  Future<FamilyModel> createFamilyGroup({
    required UserModel currentUser,
    required String familyName,
    String? description,
  }) async => FamilyModel(
        familyId: 'fam_123',
        familyName: familyName,
        adminUid: currentUser.uid,
      );

  @override
  Future<OnboardingBundle> loadOnboardingBundle(String uid, [UserModel? fallbackUser]) async {
    return OnboardingBundle(
      user: UserModel(
        uid: uid,
        fullName: 'Vikram Mehta',
        email: 'vikram@medihub.health',
        emailVerified: true,
        memberId: 'mem_98765432',
        onboardingStatus: OnboardingStep.completed,
      ),
    );
  }

  Future<FamilyMembershipModel?> getAdminMembership(String familyId, String memberId) async => null;
}

class FakeAuthRepository implements AuthRepository {
  @override
  Stream<User?> get authStateChanges => const Stream.empty();

  @override
  User? get currentFirebaseUser => null;

  @override
  Future<UserModel> register({
    required String fullName,
    required String email,
    required String password,
  }) async => UserModel(
        uid: 'fake_uid',
        fullName: fullName,
        email: email,
        emailVerified: true,
        onboardingStatus: OnboardingStep.completed,
      );

  @override
  Future<UserModel?> login({required String email, required String password}) async => null;

  @override
  Future<UserModel?> getCurrentUserModel() async => null;

  @override
  Future<UserModel?> getLocallyStoredUser() async => null;

  @override
  Future<void> saveLocally(UserModel user) async {}

  @override
  Future<bool> checkEmailVerified(UserModel currentUser) async => true;

  Future<void> sendEmailVerification() async {}

  @override
  Future<void> resendVerificationEmail() async {}

  @override
  Future<void> sendPasswordReset(String email) async {}

  @override
  Future<void> correctEmailAndResend({required UserModel currentUser, required String newEmail}) async {}

  @override
  Future<void> signOut() async {}
}

void main() {
  group('Plan Change & Mock Checkout Flow Test', () {
    final testUser = UserModel(
      uid: 'usr_plan_test',
      fullName: 'Vikram Mehta',
      email: 'vikram@medihub.health',
      emailVerified: true,
      memberId: 'mem_98765432',
      onboardingStatus: OnboardingStep.completed,
    );

    final testProfile = MemberProfileModel(
      memberId: 'mem_98765432',
      fullName: 'Vikram Mehta',
      gender: 'Male',
      bloodGroup: 'B+',
      phone: '+91 9123456780',
      dateOfBirth: DateTime(1990, 4, 12),
      address: const AddressModel(
        line: 'A-42 Green Park',
        city: 'New Delhi',
        state: 'Delhi',
        country: 'India',
        postalCode: '110016',
      ),
    );

    final testFamily = FamilyModel(
      familyId: 'fam_usr_plan_test',
      familyName: 'Mehta Household',
      adminUid: 'usr_plan_test',
    );

    final initialSubscription = SubscriptionModel(
      subscriptionId: 'sub_free_001',
      familyId: 'fam_usr_plan_test',
      planId: 'family_basic',
      amount: 0,
      currency: 'INR',
      billingCycle: 'MONTHLY',
      status: 'FREE',
      paymentMode: 'MOCK',
    );

    testWidgets('Completed user can upgrade plan and passes mock checkout cleanly', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final subRepo = FakeSubscriptionRepository();
      final onboardingRepo = FakeOnboardingRepository();
      final authRepo = FakeAuthRepository();
      final checkoutCubit = CheckoutCubit(subscriptionRepository: subRepo);

      bool paymentCompleted = false;
      bool returnToPlans = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: MultiBlocProvider(
            providers: [
              BlocProvider<CheckoutCubit>.value(value: checkoutCubit),
              BlocProvider<OnboardingCubit>(
                create: (_) => OnboardingCubit(
                  onboardingRepository: onboardingRepo,
                  subscriptionRepository: subRepo,
                )..emit(
                    OnboardingLoaded(
                      bundle: OnboardingBundle(
                        user: testUser,
                        memberProfile: testProfile,
                        family: testFamily,
                        subscription: initialSubscription,
                      ),
                      currentStep: OnboardingStep.planSelected,
                      selectedPlan: PlanCatalog.familyPro,
                    ),
                  ),
              ),
              BlocProvider<AuthBloc>(
                create: (_) => AuthBloc(authRepository: authRepo),
              ),
            ],
            child: MockCheckoutScreen(
              user: testUser,
              family: testFamily,
              plan: PlanCatalog.familyPro,
              onPaymentCompleted: () {
                paymentCompleted = true;
              },
              onReturnToPlanSelection: () {
                returnToPlans = true;
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify Mock Checkout Screen rendered
      expect(find.text('Mock Checkout'), findsOneWidget);
      expect(find.text('Subscription Summary'), findsOneWidget);
      expect(find.text('Vikram Mehta'), findsOneWidget);
      expect(find.text('Mehta Household'), findsOneWidget);
      expect(find.text('Family Pro'), findsOneWidget);
      expect(find.text('Simulate Payment Success'), findsOneWidget);

      // Tap Simulate Payment Success
      await tester.tap(find.text('Simulate Payment Success'));
      await tester.pump(); // Start processing animation

      // Settle simulated network delay
      await tester.pump(const Duration(milliseconds: 1000));
      await tester.pumpAndSettle();

      // Verify paymentCompleted callback was triggered without freezing!
      expect(paymentCompleted, isTrue);
      expect(returnToPlans, isFalse);

      // Now verify Dashboard with upgraded plan renders Active (PRO) in footer
      final updatedSub = SubscriptionModel(
        subscriptionId: 'sub_mock_pro',
        familyId: 'fam_usr_plan_test',
        planId: 'family_pro',
        amount: 299,
        currency: 'INR',
        billingCycle: 'MONTHLY',
        status: 'MOCK_ACTIVE',
        paymentMode: 'MOCK',
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: DashboardScreen(
            user: testUser,
            memberProfile: testProfile,
            family: testFamily,
            subscription: updatedSub,
            plan: PlanCatalog.familyPro,
            onChangePlan: () {},
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify 5 tabs in sidebar
      expect(find.text('Dashboard'), findsWidgets);
      expect(find.text('Family Group'), findsWidgets);
      expect(find.text('Health Records'), findsWidgets);
      expect(find.text('Appointments'), findsWidgets);
      expect(find.text('Subscription'), findsWidgets);

      // Verify Bottom User Profile with Active (PRO) badge
      expect(find.text('Vikram Mehta'), findsOneWidget);
      expect(find.text('mem_98765432'), findsOneWidget);
      expect(find.text('Active (PRO)'), findsOneWidget);
    });
  });
}
