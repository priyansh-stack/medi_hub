import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/plan_catalog.dart';
import '../../data/models/family_model.dart';
import '../../data/models/plan_model.dart';
import '../../data/models/user_model.dart';
import '../../logic/auth/auth_bloc.dart';
import '../../logic/auth/auth_event.dart';
import '../../logic/onboarding/onboarding_cubit.dart';
import '../../logic/onboarding/onboarding_state.dart';
import '../widgets/custom_button.dart';
import '../widgets/plan_card.dart';
import '../widgets/step_progress_bar.dart';

class SelectPlanScreen extends StatefulWidget {
  final UserModel user;
  final FamilyModel family;
  final PlanModel? initialSelectedPlan;

  const SelectPlanScreen({
    super.key,
    required this.user,
    required this.family,
    this.initialSelectedPlan,
  });

  @override
  State<SelectPlanScreen> createState() => _SelectPlanScreenState();
}

class _SelectPlanScreenState extends State<SelectPlanScreen> {
  late PlanModel _selectedPlan;

  @override
  void initState() {
    super.initState();
    _selectedPlan = widget.initialSelectedPlan ?? PlanCatalog.familyPro;
  }

  void _onContinue() {
    final cubit = context.read<OnboardingCubit>();
    final activeUser = (cubit.state is OnboardingLoaded)
        ? (cubit.state as OnboardingLoaded).bundle.user
        : widget.user;
    final activeFamily = (cubit.state is OnboardingLoaded && (cubit.state as OnboardingLoaded).bundle.family != null)
        ? (cubit.state as OnboardingLoaded).bundle.family!
        : widget.family;

    cubit.selectPlan(
          currentUser: activeUser,
          familyId: activeFamily.familyId,
          plan: _selectedPlan,
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        title: const Text('MediHub Onboarding'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Log out',
            onPressed: () {
              context.read<AuthBloc>().add(AuthLogoutRequested());
            },
          ),
        ],
      ),
      body: BlocConsumer<OnboardingCubit, OnboardingState>(
        listener: (context, state) {
          if (state is OnboardingError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
              ),
            );
          } else if (state is OnboardingLoaded) {
            context.read<AuthBloc>().add(AuthUserUpdated(state.bundle.user));
            if (state.currentStep == OnboardingStep.completed) {
              context.go('/dashboard');
            } else if (state.currentStep == OnboardingStep.planSelected) {
              context.go('/checkout');
            }
          }
        },
        builder: (context, state) {
          final isLoading = state is OnboardingLoading;

          return SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 580),
                child: Column(
                  children: [
                    StepProgressBar(
                      currentStep: 4,
                      totalSteps: 4,
                      title: 'Select Your Family Plan',
                      subtitle: "Choose the plan that best fits your family's health needs (mock billing enabled).",
                      stepLabels: const ['Contact', 'Profile', 'Family', 'Plan'],
                      onBack: () => context.go('/family'),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Household chip
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.family_restroom, color: AppColors.primary, size: 20),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'Subscribing for: ${widget.family.familyName}',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Plans
                            ...PlanCatalog.plans.map(
                              (plan) => PlanCard(
                                plan: plan,
                                isSelected: _selectedPlan.id == plan.id,
                                onSelect: () {
                                  setState(() {
                                    _selectedPlan = plan;
                                  });
                                },
                              ),
                            ),

                            const SizedBox(height: 12),

                            // Order Summary
                            Container(
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Order Summary',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(_selectedPlan.name, style: const TextStyle(color: AppColors.textSecondary)),
                                      Text(_selectedPlan.formattedPrice, style: const TextStyle(fontWeight: FontWeight.w600)),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text('Billing Interval', style: TextStyle(color: AppColors.textSecondary)),
                                      Text(_selectedPlan.isFree ? 'Indefinite' : 'Monthly Recurring'),
                                    ],
                                  ),
                                  const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 8),
                                    child: Divider(color: AppColors.border),
                                  ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text('Total Due Today', style: TextStyle(fontWeight: FontWeight.w700)),
                                      Text(
                                        _selectedPlan.isFree ? '₹0 (Free)' : '₹${_selectedPlan.amount.toInt()}',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 24),

                            CustomButton(
                              text: _selectedPlan.isFree
                                  ? 'Activate Free Plan & Finish'
                                  : 'Proceed to Mock Checkout',
                              icon: Icons.arrow_forward_rounded,
                              isLoading: isLoading,
                              onPressed: _onContinue,
                            ),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
