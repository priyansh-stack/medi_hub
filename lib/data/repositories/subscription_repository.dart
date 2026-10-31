import 'package:uuid/uuid.dart';
import '../../core/constants/plan_catalog.dart';
import '../models/plan_model.dart';
import '../models/subscription_model.dart';
import '../models/user_model.dart';
import '../services/firestore_service.dart';
import '../services/local_storage_service.dart';

class SubscriptionRepository {
  final FirestoreService _firestoreService;
  final LocalStorageService _localStorageService;
  final Uuid _uuid;

  SubscriptionRepository({
    FirestoreService? firestoreService,
    LocalStorageService? localStorageService,
    Uuid? uuid,
  })  : _firestoreService = firestoreService ?? FirestoreService(),
        _localStorageService = localStorageService ?? LocalStorageService(),
        _uuid = uuid ?? const Uuid();

  List<PlanModel> getAvailablePlans() {
    return PlanCatalog.plans;
  }

  PlanModel getPlanById(String planId) {
    return PlanCatalog.findById(planId);
  }

  /// Selects a plan. If Free plan, creates Free subscription immediately and completes onboarding.
  /// If Paid plan, saves pendingPlanId and advances onboarding to planSelected (Mock Checkout).
  Future<SubscriptionModel?> selectPlan({
    required UserModel currentUser,
    required String familyId,
    required PlanModel plan,
  }) async {
    if (plan.isFree) {
      // Free plan: Skip checkout, activate subscription immediately
      final existingSub = await _firestoreService.getSubscriptionForFamily(familyId);
      final subId = existingSub?.subscriptionId ?? 'sub_free_${_uuid.v4().substring(0, 8)}';

      final subscription = SubscriptionModel(
        subscriptionId: subId,
        familyId: familyId,
        planId: plan.id,
        amount: 0,
        currency: plan.currency,
        billingCycle: 'MONTHLY',
        status: 'FREE',
        paymentMode: 'MOCK',
        mockTransactionId: 'txn_free_${DateTime.now().millisecondsSinceEpoch}',
        createdAt: existingSub?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _firestoreService.saveSubscription(subscription);

      // Mark onboarding complete
      await _firestoreService.updateUser(currentUser.uid, {
        'pendingPlanId': plan.id,
        'onboardingStatus': OnboardingStep.completed.toDbValue(),
      });

      final updatedUser = currentUser.copyWith(
        pendingPlanId: plan.id,
        onboardingStatus: OnboardingStep.completed,
        updatedAt: DateTime.now(),
      );
      await _localStorageService.saveUser(updatedUser);
      await _localStorageService.setOnboardingCompleted(true);

      return subscription;
    } else {
      // Paid plan: Mark planSelected, ready for Mock Checkout
      await _firestoreService.updateUser(currentUser.uid, {
        'pendingPlanId': plan.id,
        'onboardingStatus': OnboardingStep.planSelected.toDbValue(),
      });

      final updatedUser = currentUser.copyWith(
        pendingPlanId: plan.id,
        onboardingStatus: OnboardingStep.planSelected,
        updatedAt: DateTime.now(),
      );
      await _localStorageService.saveUser(updatedUser);

      return null;
    }
  }

  /// Process Mock Payment Success
  Future<SubscriptionModel> processMockPaymentSuccess({
    required UserModel currentUser,
    required String familyId,
    required PlanModel plan,
  }) async {
    final existingSub = await _firestoreService.getSubscriptionForFamily(familyId);
    final subId = existingSub?.subscriptionId ?? 'sub_mock_${_uuid.v4().substring(0, 8)}';

    final transactionId = 'txn_mock_${DateTime.now().millisecondsSinceEpoch}_${_uuid.v4().substring(0, 4)}';

    final subscription = SubscriptionModel(
      subscriptionId: subId,
      familyId: familyId,
      planId: plan.id,
      amount: plan.amount,
      currency: plan.currency,
      billingCycle: 'MONTHLY',
      status: 'MOCK_ACTIVE',
      paymentMode: 'MOCK',
      mockTransactionId: transactionId,
      createdAt: existingSub?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await _firestoreService.saveSubscription(subscription);

    // Mark onboarding complete
    await _firestoreService.updateUser(currentUser.uid, {
      'pendingPlanId': null,
      'onboardingStatus': OnboardingStep.completed.toDbValue(),
    });

    final updatedUser = currentUser.copyWith(
      pendingPlanId: null,
      onboardingStatus: OnboardingStep.completed,
      updatedAt: DateTime.now(),
    );
    await _localStorageService.saveUser(updatedUser);
    await _localStorageService.setOnboardingCompleted(true);

    return subscription;
  }

  /// Process Mock Payment Failure
  Future<SubscriptionModel> processMockPaymentFailure({
    required UserModel currentUser,
    required String familyId,
    required PlanModel plan,
    String? reason,
  }) async {
    final existingSub = await _firestoreService.getSubscriptionForFamily(familyId);
    final subId = existingSub?.subscriptionId ?? 'sub_mock_${_uuid.v4().substring(0, 8)}';

    final subscription = SubscriptionModel(
      subscriptionId: subId,
      familyId: familyId,
      planId: plan.id,
      amount: plan.amount,
      currency: plan.currency,
      billingCycle: 'MONTHLY',
      status: 'PAYMENT_FAILED',
      paymentMode: 'MOCK',
      mockTransactionId: 'txn_failed_${DateTime.now().millisecondsSinceEpoch}',
      createdAt: existingSub?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await _firestoreService.saveSubscription(subscription);

    // Keep onboardingStatus at planSelected so user can retry or change plan
    await _firestoreService.updateUser(currentUser.uid, {
      'pendingPlanId': plan.id,
      'onboardingStatus': OnboardingStep.planSelected.toDbValue(),
    });

    final updatedUser = currentUser.copyWith(
      pendingPlanId: plan.id,
      onboardingStatus: OnboardingStep.planSelected,
      updatedAt: DateTime.now(),
    );
    await _localStorageService.saveUser(updatedUser);

    return subscription;
  }

  /// Cancel Mock Checkout (return to plan selection)
  Future<void> cancelCheckout({
    required UserModel currentUser,
  }) async {
    // Return status to familyCreated so user is back at plan selection
    await _firestoreService.updateUser(currentUser.uid, {
      'onboardingStatus': OnboardingStep.familyCreated.toDbValue(),
    });

    final updatedUser = currentUser.copyWith(
      onboardingStatus: OnboardingStep.familyCreated,
      updatedAt: DateTime.now(),
    );
    await _localStorageService.saveUser(updatedUser);
  }

  Future<SubscriptionModel?> getFamilySubscription(String familyId) async {
    return await _firestoreService.getSubscriptionForFamily(familyId);
  }
}
