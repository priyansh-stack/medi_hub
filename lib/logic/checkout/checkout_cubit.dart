import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/plan_model.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/subscription_repository.dart';
import 'checkout_state.dart';

class CheckoutCubit extends Cubit<CheckoutState> {
  final SubscriptionRepository subscriptionRepository;

  CheckoutCubit({
    required this.subscriptionRepository,
  }) : super(const CheckoutProcessing(message: 'Initializing checkout...'));

  void initialize({
    required PlanModel plan,
    required String familyId,
    required String userEmail,
    required String userName,
  }) {
    emit(CheckoutInitial(
      plan: plan,
      familyId: familyId,
      userEmail: userEmail,
      userName: userName,
    ));
  }

  /// Simulate Successful Checkout
  Future<void> simulatePaymentSuccess({
    required UserModel currentUser,
    required String familyId,
    required PlanModel plan,
  }) async {
    emit(const CheckoutProcessing(
      message: 'Simulating transaction approval (MOCK PAYMENT)...',
    ));

    // Simulate minor network delay for realistic mock experience
    await Future.delayed(const Duration(milliseconds: 900));

    try {
      final subscription = await subscriptionRepository.processMockPaymentSuccess(
        currentUser: currentUser,
        familyId: familyId,
        plan: plan,
      );
      emit(CheckoutSuccess(subscription: subscription, plan: plan));
    } catch (e) {
      emit(CheckoutFailureState(
        reason: 'Payment simulation error: ${e.toString()}',
        plan: plan,
        familyId: familyId,
      ));
    }
  }

  /// Simulate Failed Checkout
  Future<void> simulatePaymentFailure({
    required UserModel currentUser,
    required String familyId,
    required PlanModel plan,
    String reason = 'Card declined: Simulated insufficient funds in mock payment environment.',
  }) async {
    emit(const CheckoutProcessing(
      message: 'Processing mock transaction...',
    ));

    await Future.delayed(const Duration(milliseconds: 700));

    try {
      await subscriptionRepository.processMockPaymentFailure(
        currentUser: currentUser,
        familyId: familyId,
        plan: plan,
        reason: reason,
      );
      emit(CheckoutFailureState(
        reason: reason,
        plan: plan,
        familyId: familyId,
      ));
    } catch (e) {
      emit(CheckoutFailureState(
        reason: 'Failed to record simulated failure: ${e.toString()}',
        plan: plan,
        familyId: familyId,
      ));
    }
  }

  /// Cancel Mock Checkout
  Future<void> cancelCheckout({
    required UserModel currentUser,
  }) async {
    emit(const CheckoutProcessing(message: 'Cancelling mock checkout...'));
    await subscriptionRepository.cancelCheckout(currentUser: currentUser);
    emit(CheckoutCancelledState());
  }

  /// Retry after failure
  void retry({
    required PlanModel plan,
    required String familyId,
    required String userEmail,
    required String userName,
  }) {
    emit(CheckoutInitial(
      plan: plan,
      familyId: familyId,
      userEmail: userEmail,
      userName: userName,
    ));
  }
}
