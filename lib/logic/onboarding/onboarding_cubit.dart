import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/member_profile_model.dart';
import '../../data/models/plan_model.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/onboarding_repository.dart';
import '../../data/repositories/subscription_repository.dart';
import 'onboarding_state.dart';

class OnboardingCubit extends Cubit<OnboardingState> {
  final OnboardingRepository onboardingRepository;
  final SubscriptionRepository subscriptionRepository;

  OnboardingCubit({
    required this.onboardingRepository,
    required this.subscriptionRepository,
  }) : super(OnboardingInitial());

  /// Loads full onboarding bundle and sets current active step
  Future<void> loadOnboarding(UserModel user) async {
    emit(const OnboardingLoading(message: 'Restoring onboarding progress...'));
    try {
      final bundle = await onboardingRepository.loadOnboardingBundle(user.uid);
      PlanModel? plan;
      if (bundle.user.pendingPlanId != null) {
        plan = subscriptionRepository.getPlanById(bundle.user.pendingPlanId!);
      } else if (bundle.subscription != null) {
        plan = subscriptionRepository.getPlanById(bundle.subscription!.planId);
      }

      emit(OnboardingLoaded(
        bundle: bundle,
        currentStep: bundle.user.onboardingStatus,
        selectedPlan: plan,
      ));
    } catch (e) {
      emit(OnboardingError('Failed to load progress: ${e.toString()}'));
    }
  }

  /// Step 4: Save Contact and Address
  Future<void> saveContactAndAddress({
    required UserModel currentUser,
    String? phone,
    required AddressModel address,
  }) async {
    emit(const OnboardingLoading(message: 'Saving contact & address details...'));
    try {
      final updatedUser = await onboardingRepository.saveContactAndAddress(
        currentUser: currentUser,
        phone: phone,
        address: address,
      );
      final bundle = await onboardingRepository.loadOnboardingBundle(updatedUser.uid);
      emit(OnboardingLoaded(
        bundle: bundle,
        currentStep: OnboardingStep.contactSaved,
      ));
    } catch (e) {
      emit(OnboardingError('Failed to save contact details: ${e.toString()}'));
    }
  }

  /// Step 5: Save Personal Health Profile
  Future<void> savePersonalHealthProfile({
    required UserModel currentUser,
    required String fullName,
    required DateTime dateOfBirth,
    required String gender,
    String? bloodGroup,
    String? phone,
    AddressModel? address,
  }) async {
    emit(const OnboardingLoading(message: 'Saving health profile...'));
    try {
      final updatedUser = await onboardingRepository.savePersonalHealthProfile(
        currentUser: currentUser,
        fullName: fullName,
        dateOfBirth: dateOfBirth,
        gender: gender,
        bloodGroup: bloodGroup,
        phone: phone,
        address: address,
      );
      final bundle = await onboardingRepository.loadOnboardingBundle(updatedUser.uid);
      emit(OnboardingLoaded(
        bundle: bundle,
        currentStep: OnboardingStep.profileSaved,
      ));
    } catch (e) {
      emit(OnboardingError('Failed to save personal profile: ${e.toString()}'));
    }
  }

  /// Step 6: Create Family Group
  Future<void> createFamilyGroup({
    required UserModel currentUser,
    required String familyName,
    String? description,
  }) async {
    emit(const OnboardingLoading(message: 'Creating family group...'));
    try {
      await onboardingRepository.createFamilyGroup(
        currentUser: currentUser,
        familyName: familyName,
        description: description,
      );
      final bundle = await onboardingRepository.loadOnboardingBundle(currentUser.uid);
      emit(OnboardingLoaded(
        bundle: bundle,
        currentStep: OnboardingStep.familyCreated,
      ));
    } catch (e) {
      emit(OnboardingError('Failed to create family group: ${e.toString()}'));
    }
  }

  /// Step 7: Select Plan
  Future<void> selectPlan({
    required UserModel currentUser,
    required String familyId,
    required PlanModel plan,
  }) async {
    emit(OnboardingLoading(
      message: plan.isFree ? 'Activating your Free Family Basic plan...' : 'Setting up plan checkout...',
    ));
    try {
      await subscriptionRepository.selectPlan(
        currentUser: currentUser,
        familyId: familyId,
        plan: plan,
      );
      final bundle = await onboardingRepository.loadOnboardingBundle(currentUser.uid);

      if (plan.isFree) {
        // Free plan goes straight to completed!
        emit(OnboardingLoaded(
          bundle: bundle,
          currentStep: OnboardingStep.completed,
          selectedPlan: plan,
        ));
      } else {
        // Paid plan moves to planSelected (Mock Checkout)
        emit(OnboardingLoaded(
          bundle: bundle,
          currentStep: OnboardingStep.planSelected,
          selectedPlan: plan,
        ));
      }
    } catch (e) {
      emit(OnboardingError('Failed to select plan: ${e.toString()}'));
    }
  }

  /// Change Plan (Return to step 7 from mock checkout)
  void returnToPlanSelection() {
    if (state is OnboardingLoaded) {
      final current = state as OnboardingLoaded;
      emit(current.copyWith(currentStep: OnboardingStep.familyCreated));
    }
  }

  /// Refresh Onboarding Bundle
  Future<void> refreshBundle(String uid) async {
    try {
      final bundle = await onboardingRepository.loadOnboardingBundle(uid);
      PlanModel? plan;
      if (bundle.user.pendingPlanId != null) {
        plan = subscriptionRepository.getPlanById(bundle.user.pendingPlanId!);
      } else if (bundle.subscription != null) {
        plan = subscriptionRepository.getPlanById(bundle.subscription!.planId);
      }
      emit(OnboardingLoaded(
        bundle: bundle,
        currentStep: bundle.user.onboardingStatus,
        selectedPlan: plan,
      ));
    } catch (e) {
      emit(OnboardingError('Failed to refresh data: ${e.toString()}'));
    }
  }
}
