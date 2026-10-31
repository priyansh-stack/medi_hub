import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/validators.dart';
import '../../data/models/family_model.dart';
import '../../data/models/user_model.dart';
import '../../logic/auth/auth_bloc.dart';
import '../../logic/auth/auth_event.dart';
import '../../logic/onboarding/onboarding_cubit.dart';
import '../../logic/onboarding/onboarding_state.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/step_progress_bar.dart';

class CreateFamilyScreen extends StatefulWidget {
  final UserModel user;
  final FamilyModel? initialFamily;

  const CreateFamilyScreen({
    super.key,
    required this.user,
    this.initialFamily,
  });

  @override
  State<CreateFamilyScreen> createState() => _CreateFamilyScreenState();
}

class _CreateFamilyScreenState extends State<CreateFamilyScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _familyNameController;
  late final TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    final family = widget.initialFamily;
    _familyNameController = TextEditingController(
      text: family?.familyName ?? '${widget.user.fullName.split(' ').first} Household',
    );
    _descriptionController = TextEditingController(
      text: family?.description ?? '',
    );
  }

  @override
  void dispose() {
    _familyNameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final cubit = context.read<OnboardingCubit>();
    final activeUser = (cubit.state is OnboardingLoaded)
        ? (cubit.state as OnboardingLoaded).bundle.user
        : widget.user;

    cubit.createFamilyGroup(
          currentUser: activeUser,
          familyName: _familyNameController.text.trim(),
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
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
          } else if (state is OnboardingLoaded &&
              (state.currentStep == OnboardingStep.familyCreated ||
                  state.currentStep == OnboardingStep.planSelected ||
                  state.bundle.family != null)) {
            // Update AuthBloc with latest user and transition to step 4
            context.read<AuthBloc>().add(AuthUserUpdated(state.bundle.user));
            context.go('/plan');
          }
        },
        builder: (context, state) {
          final isLoading = state is OnboardingLoading;

          return SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 540),
                child: Column(
                  children: [
                    StepProgressBar(
                      currentStep: 3,
                      totalSteps: 4,
                      title: 'Create Your Family Group',
                      subtitle: 'Set up your household group. You will become the Family Admin.',
                      stepLabels: const ['Contact', 'Profile', 'Family', 'Plan'],
                      onBack: () => context.go('/profile'),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
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
                                    // Admin identity chip
                                    Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 20,
                                          backgroundColor: AppColors.primarySurface,
                                          child: const Icon(
                                            Icons.admin_panel_settings_rounded,
                                            color: AppColors.primary,
                                            size: 22,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Text(
                                                    widget.user.fullName,
                                                    style: const TextStyle(
                                                      fontSize: 15,
                                                      fontWeight: FontWeight.w700,
                                                      color: AppColors.textPrimary,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: AppColors.primary,
                                                      borderRadius: BorderRadius.circular(8),
                                                    ),
                                                    child: const Text(
                                                      'ADMIN',
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 9,
                                                        fontWeight: FontWeight.w800,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                'Member ID: ${widget.user.memberId ?? 'Auto-assigned'}',
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: AppColors.textSecondary,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 20),

                                    // Family Name
                                    CustomTextField(
                                      controller: _familyNameController,
                                      label: 'Family Group Name',
                                      hint: 'e.g. The Sharma Family',
                                      prefixIcon: Icons.diversity_1_outlined,
                                      validator: Validators.validateFamilyName,
                                    ),
                                    const SizedBox(height: 18),

                                    // Description
                                    CustomTextField(
                                      controller: _descriptionController,
                                      label: 'Description (Optional)',
                                      hint: 'Brief note for your household hub (e.g. Primary residence)',
                                      maxLines: 3,
                                      prefixIcon: Icons.notes_outlined,
                                      validator: Validators.validateFamilyDescription,
                                    ),
                                    const SizedBox(height: 16),

                                    // Scope note
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: AppColors.primarySurface,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Icon(Icons.info_outline, size: 18, color: AppColors.primary),
                                          SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              'MVP Scope Note: You will be the primary member. Additional family-member management is scheduled for the upcoming release phase.',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: AppColors.textSecondary,
                                                height: 1.35,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 24),

                              CustomButton(
                                text: 'Create Family & Select Plan',
                                icon: Icons.arrow_forward_rounded,
                                isLoading: isLoading,
                                onPressed: _submit,
                              ),
                              const SizedBox(height: 16),
                            ],
                          ),
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
