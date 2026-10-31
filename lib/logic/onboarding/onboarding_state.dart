import 'package:equatable/equatable.dart';
import '../../data/models/plan_model.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/onboarding_repository.dart';

abstract class OnboardingState extends Equatable {
  const OnboardingState();

  @override
  List<Object?> get props => [];
}

class OnboardingInitial extends OnboardingState {}

class OnboardingLoading extends OnboardingState {
  final String? message;
  const OnboardingLoading({this.message});

  @override
  List<Object?> get props => [message];
}

class OnboardingLoaded extends OnboardingState {
  final OnboardingBundle bundle;
  final OnboardingStep currentStep;
  final PlanModel? selectedPlan;

  const OnboardingLoaded({
    required this.bundle,
    required this.currentStep,
    this.selectedPlan,
  });

  OnboardingLoaded copyWith({
    OnboardingBundle? bundle,
    OnboardingStep? currentStep,
    PlanModel? selectedPlan,
  }) {
    return OnboardingLoaded(
      bundle: bundle ?? this.bundle,
      currentStep: currentStep ?? this.currentStep,
      selectedPlan: selectedPlan ?? this.selectedPlan,
    );
  }

  @override
  List<Object?> get props => [bundle, currentStep, selectedPlan];
}

class OnboardingOperationSuccess extends OnboardingState {
  final String message;
  final OnboardingBundle bundle;

  const OnboardingOperationSuccess(this.message, {required this.bundle});

  @override
  List<Object?> get props => [message, bundle];
}

class OnboardingError extends OnboardingState {
  final String message;
  final OnboardingBundle? currentBundle;

  const OnboardingError(this.message, {this.currentBundle});

  @override
  List<Object?> get props => [message, currentBundle];
}
