import 'package:equatable/equatable.dart';
import '../../data/models/plan_model.dart';
import '../../data/models/subscription_model.dart';

abstract class CheckoutState extends Equatable {
  const CheckoutState();

  @override
  List<Object?> get props => [];
}

class CheckoutInitial extends CheckoutState {
  final PlanModel plan;
  final String familyId;
  final String userEmail;
  final String userName;

  const CheckoutInitial({
    required this.plan,
    required this.familyId,
    required this.userEmail,
    required this.userName,
  });

  @override
  List<Object?> get props => [plan, familyId, userEmail, userName];
}

class CheckoutProcessing extends CheckoutState {
  final String message;

  const CheckoutProcessing({this.message = 'Simulating payment processing...'});

  @override
  List<Object?> get props => [message];
}

class CheckoutSuccess extends CheckoutState {
  final SubscriptionModel subscription;
  final PlanModel plan;

  const CheckoutSuccess({
    required this.subscription,
    required this.plan,
  });

  @override
  List<Object?> get props => [subscription, plan];
}

class CheckoutFailureState extends CheckoutState {
  final String reason;
  final PlanModel plan;
  final String familyId;

  const CheckoutFailureState({
    required this.reason,
    required this.plan,
    required this.familyId,
  });

  @override
  List<Object?> get props => [reason, plan, familyId];
}

class CheckoutCancelledState extends CheckoutState {}
