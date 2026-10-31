import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/validators.dart';
import '../../data/models/member_profile_model.dart';
import '../../data/models/user_model.dart';
import '../../logic/auth/auth_bloc.dart';
import '../../logic/auth/auth_event.dart';
import '../../logic/onboarding/onboarding_cubit.dart';
import '../../logic/onboarding/onboarding_state.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/step_progress_bar.dart';

class PersonalHealthProfileScreen extends StatefulWidget {
  final UserModel user;
  final MemberProfileModel? initialProfile;

  const PersonalHealthProfileScreen({
    super.key,
    required this.user,
    this.initialProfile,
  });

  @override
  State<PersonalHealthProfileScreen> createState() => _PersonalHealthProfileScreenState();
}

class _PersonalHealthProfileScreenState extends State<PersonalHealthProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _dobController;

  DateTime? _selectedDob;
  String? _selectedGender;
  String? _selectedBloodGroup;
  String? _dobError;

  static const List<String> _genders = [
    'Male',
    'Female',
    'Other / Non-binary',
    'Prefer not to say',
  ];

  static const List<String> _bloodGroups = [
    'A+',
    'A-',
    'B+',
    'B-',
    'AB+',
    'AB-',
    'O+',
    'O-',
  ];

  @override
  void initState() {
    super.initState();
    final profile = widget.initialProfile;
    _nameController = TextEditingController(
      text: (profile?.fullName.isNotEmpty ?? false) ? profile!.fullName : widget.user.fullName,
    );

    _selectedDob = profile?.dateOfBirth;
    _dobController = TextEditingController(
      text: _selectedDob != null ? DateFormat('dd/MM/yyyy').format(_selectedDob!) : '',
    );

    if (profile?.gender != null && _genders.contains(profile!.gender)) {
      _selectedGender = profile.gender;
    } else {
      _selectedGender = _genders.first;
    }

    _selectedBloodGroup = profile?.bloodGroup;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dobController.dispose();
    super.dispose();
  }

  Future<void> _pickDateOfBirth() async {
    final now = DateTime.now();
    final initial = _selectedDob ?? DateTime(now.year - 28, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 120),
      lastDate: now,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDob = picked;
        _dobController.text = DateFormat('dd/MM/yyyy').format(picked);
        _dobError = null;
      });
    }
  }

  void _submit() {
    if (_selectedDob == null && _dobController.text.trim().isNotEmpty) {
      try {
        final parts = _dobController.text.trim().split('/');
        if (parts.length == 3) {
          final d = int.parse(parts[0]);
          final m = int.parse(parts[1]);
          final y = int.parse(parts[2]);
          _selectedDob = DateTime(y, m, d);
        }
      } catch (_) {}
    }

    setState(() {
      _dobError = Validators.validateDateOfBirth(_selectedDob);
    });

    if (!_formKey.currentState!.validate() || _dobError != null) {
      return;
    }

    final cubit = context.read<OnboardingCubit>();
    final activeUser = (cubit.state is OnboardingLoaded)
        ? (cubit.state as OnboardingLoaded).bundle.user
        : widget.user;
    final activeProfile = (cubit.state is OnboardingLoaded)
        ? (cubit.state as OnboardingLoaded).bundle.memberProfile
        : widget.initialProfile;

    cubit.savePersonalHealthProfile(
          currentUser: activeUser,
          fullName: _nameController.text.trim(),
          dateOfBirth: _selectedDob!,
          gender: _selectedGender ?? 'Not specified',
          bloodGroup: _selectedBloodGroup,
          phone: activeProfile?.phone ?? widget.initialProfile?.phone,
          address: activeProfile?.address ?? widget.initialProfile?.address,
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
              (state.currentStep == OnboardingStep.profileSaved ||
                  state.currentStep == OnboardingStep.familyCreated)) {
            // Update AuthBloc with latest user and transition to step 3
            context.read<AuthBloc>().add(AuthUserUpdated(state.bundle.user));
            context.go('/family');
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
                      currentStep: 2,
                      totalSteps: 4,
                      title: 'Personal Health Profile',
                      subtitle: 'Set up your individual member profile to anchor family records.',
                      stepLabels: const ['Contact', 'Profile', 'Family', 'Plan'],
                      onBack: () => context.go('/contact'),
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
                                    // Notice
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: AppColors.primarySurface,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Row(
                                        children: [
                                          Icon(Icons.badge_outlined, color: AppColors.primary, size: 20),
                                          SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              'A unique Member ID will be generated and associated with your account as the first family member.',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: AppColors.primaryDark,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 20),

                                    // Full Name
                                    CustomTextField(
                                      controller: _nameController,
                                      label: 'Full Legal Name',
                                      hint: 'Pre-filled from account registration',
                                      prefixIcon: Icons.person_outline,
                                      validator: Validators.validateFullName,
                                    ),
                                    const SizedBox(height: 18),

                                    // Date of birth
                                    CustomTextField(
                                      controller: _dobController,
                                      label: 'Date of Birth',
                                      hint: 'DD/MM/YYYY',
                                      prefixIcon: Icons.calendar_today_outlined,
                                      errorText: _dobError,
                                      onChanged: (val) {
                                        if (val.trim().isNotEmpty) {
                                          try {
                                            final parts = val.trim().split('/');
                                            if (parts.length == 3) {
                                              final d = int.parse(parts[0]);
                                              final m = int.parse(parts[1]);
                                              final y = int.parse(parts[2]);
                                              if (y > 1900 && y <= DateTime.now().year && m >= 1 && m <= 12 && d >= 1 && d <= 31) {
                                                setState(() {
                                                  _selectedDob = DateTime(y, m, d);
                                                  _dobError = null;
                                                });
                                              }
                                            }
                                          } catch (_) {}
                                        }
                                      },
                                      suffixIcon: IconButton(
                                        icon: const Icon(Icons.date_range, color: AppColors.primary),
                                        onPressed: _pickDateOfBirth,
                                      ),
                                    ),
                                    const SizedBox(height: 18),

                                    // Gender
                                    const Text(
                                      'Gender',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    DropdownButtonFormField<String>(
                                      initialValue: _selectedGender,
                                      decoration: const InputDecoration(
                                        prefixIcon: Icon(Icons.wc_outlined, color: AppColors.textSecondary, size: 20),
                                      ),
                                      items: _genders.map((gender) {
                                        return DropdownMenuItem<String>(
                                          value: gender,
                                          child: Text(gender),
                                        );
                                      }).toList(),
                                      onChanged: (val) {
                                        setState(() {
                                          _selectedGender = val;
                                        });
                                      },
                                    ),
                                    const SizedBox(height: 18),

                                    // Blood Group
                                    const Text(
                                      'Blood Group (Optional)',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    DropdownButtonFormField<String>(
                                      initialValue: _selectedBloodGroup,
                                      decoration: const InputDecoration(
                                        hintText: 'Select blood group',
                                        prefixIcon: Icon(Icons.bloodtype_outlined, color: AppColors.error, size: 20),
                                      ),
                                      items: [
                                        const DropdownMenuItem<String>(
                                          value: null,
                                          child: Text('Prefer not to specify'),
                                        ),
                                        ..._bloodGroups.map((bg) {
                                          return DropdownMenuItem<String>(
                                            value: bg,
                                            child: Text(bg),
                                          );
                                        }),
                                      ],
                                      onChanged: (val) {
                                        setState(() {
                                          _selectedBloodGroup = val;
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 24),

                              CustomButton(
                                text: 'Continue to Family Setup',
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
