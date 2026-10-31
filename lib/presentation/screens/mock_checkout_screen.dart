import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/family_model.dart';
import '../../data/models/plan_model.dart';
import '../../data/models/user_model.dart';
import '../../logic/auth/auth_bloc.dart';
import '../../logic/auth/auth_event.dart';
import '../../logic/checkout/checkout_cubit.dart';
import '../../logic/checkout/checkout_state.dart';
import '../../logic/onboarding/onboarding_cubit.dart';
import '../../logic/onboarding/onboarding_state.dart';
import '../widgets/custom_button.dart';
import '../widgets/mock_payment_banner.dart';
import '../widgets/step_progress_bar.dart';

class MockCheckoutScreen extends StatelessWidget {
  final UserModel user;
  final FamilyModel family;
  final PlanModel plan;
  final VoidCallback onPaymentCompleted;
  final VoidCallback onReturnToPlanSelection;

  const MockCheckoutScreen({
    super.key,
    required this.user,
    required this.family,
    required this.plan,
    required this.onPaymentCompleted,
    required this.onReturnToPlanSelection,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        title: const Text('Mock Checkout'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            context.read<CheckoutCubit>().cancelCheckout(currentUser: user);
          },
        ),
      ),
      body: BlocConsumer<CheckoutCubit, CheckoutState>(
        listener: (context, state) {
          if (state is CheckoutSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Mock Payment Approved! Activating subscription...'),
                backgroundColor: AppColors.success,
              ),
            );
            final obState = context.read<OnboardingCubit>().state;
            final currentUser = (obState is OnboardingLoaded) ? obState.bundle.user : user;
            final memberId = (currentUser.memberId != null && currentUser.memberId!.isNotEmpty)
                ? currentUser.memberId
                : 'mem_${user.uid}';
            final updatedUser = currentUser.copyWith(
              memberId: memberId,
              onboardingStatus: OnboardingStep.completed,
              pendingPlanId: null,
            );
            context.read<AuthBloc>().add(AuthUserUpdated(updatedUser));
            context.read<OnboardingCubit>().refreshBundle(user.uid);
            onPaymentCompleted();
          } else if (state is CheckoutCancelledState) {
            onReturnToPlanSelection();
          }
        },
        builder: (context, state) {
          final isProcessing = state is CheckoutProcessing;
          final isFailure = state is CheckoutFailureState;

          return SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 540),
                child: Column(
                  children: [
                    const StepProgressBar(
                      currentStep: 4,
                      totalSteps: 4,
                      title: 'Secure your Account',
                      subtitle: 'Simulate checkout for your family health plan without real credit cards.',
                      stepLabels: ['Contact', 'Profile', 'Family', 'Checkout'],
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Mock Banner
                            const MockPaymentBanner(),
                            const SizedBox(height: 20),

                            // Failure warning banner if simulation failed
                            if (isFailure) ...[
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppColors.errorBg,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: AppColors.error),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Row(
                                      children: [
                                        Icon(Icons.error_outline, color: AppColors.error, size: 20),
                                        SizedBox(width: 8),
                                        Text(
                                          'Simulated Payment Failed',
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.error,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      state.reason,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: AppColors.textPrimary,
                                        height: 1.35,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 20),
                            ],

                            // Invoice container matching s-3 mockup
                            Container(
                              padding: const EdgeInsets.all(22),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: AppColors.border),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.02),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'Subscription Summary',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: AppColors.primarySurface,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: const Text(
                                          'MOCK MODE',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w800,
                                            color: AppColors.primaryDark,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Divider(height: 22, color: AppColors.border),
                                  _buildInvoiceRow('Customer Name', user.fullName),
                                  const SizedBox(height: 10),
                                  _buildInvoiceRow('Customer Email', user.email),
                                  const SizedBox(height: 10),
                                  _buildInvoiceRow('Family Group', family.familyName),
                                  const SizedBox(height: 10),
                                  _buildInvoiceRow('Selected Plan', plan.name),
                                  const SizedBox(height: 10),
                                  _buildInvoiceRow('Billing Interval', 'Monthly (Mock)'),
                                  const SizedBox(height: 10),
                                  _buildInvoiceRow('Member Limit', plan.memberLimitDescription),
                                  const Divider(height: 22, color: AppColors.border),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'Total Mock Charge',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      Text(
                                        '₹${plan.amount.toInt()} / month',
                                        style: const TextStyle(
                                          fontSize: 19,
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

                            // Pill Action buttons
                            CustomButton(
                              text: 'Simulate Payment Success',
                              icon: Icons.check_circle_outline,
                              isLoading: isProcessing,
                              onPressed: () {
                                context.read<CheckoutCubit>().simulatePaymentSuccess(
                                      currentUser: user,
                                      familyId: family.familyId,
                                      plan: plan,
                                    );
                              },
                            ),

                            const SizedBox(height: 12),

                            CustomButton(
                              text: 'Simulate Payment Failure',
                              variant: ButtonVariant.danger,
                              icon: Icons.highlight_off_rounded,
                              isLoading: isProcessing,
                              onPressed: () {
                                context.read<CheckoutCubit>().simulatePaymentFailure(
                                      currentUser: user,
                                      familyId: family.familyId,
                                      plan: plan,
                                    );
                              },
                            ),

                            const SizedBox(height: 12),

                            CustomButton(
                              text: 'Cancel & Return to Plans',
                              variant: ButtonVariant.outline,
                              icon: Icons.arrow_back_rounded,
                              isLoading: isProcessing,
                              onPressed: () {
                                context.read<CheckoutCubit>().cancelCheckout(currentUser: user);
                              },
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

  Widget _buildInvoiceRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
