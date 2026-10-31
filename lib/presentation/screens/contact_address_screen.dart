import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/location_catalog.dart';
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

class ContactAddressScreen extends StatefulWidget {
  final UserModel user;
  final MemberProfileModel? initialProfile;

  const ContactAddressScreen({
    super.key,
    required this.user,
    this.initialProfile,
  });

  @override
  State<ContactAddressScreen> createState() => _ContactAddressScreenState();
}

class _ContactAddressScreenState extends State<ContactAddressScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _phoneController;
  late final TextEditingController _addressLineController;
  late final TextEditingController _cityController;
  late final TextEditingController _postalCodeController;

  late String _selectedCountry;
  String? _selectedState;
  List<String> _availableStates = [];

  @override
  void initState() {
    super.initState();
    final address = widget.initialProfile?.address;
    _phoneController = TextEditingController(text: widget.initialProfile?.phone ?? '');
    _addressLineController = TextEditingController(text: address?.line ?? '');
    _cityController = TextEditingController(text: address?.city ?? '');
    _postalCodeController = TextEditingController(text: address?.postalCode ?? '');

    // Initialize country
    if (address != null && LocationCatalog.isValidCountry(address.country)) {
      _selectedCountry = address.country;
    } else {
      _selectedCountry = LocationCatalog.defaultCountry;
    }

    _availableStates = LocationCatalog.getStatesForCountry(_selectedCountry);

    // Initialize state
    if (address != null && LocationCatalog.isValidState(_selectedCountry, address.state)) {
      _selectedState = address.state;
    } else if (_availableStates.contains(LocationCatalog.defaultState)) {
      _selectedState = LocationCatalog.defaultState;
    } else if (_availableStates.isNotEmpty) {
      _selectedState = _availableStates.first;
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _addressLineController.dispose();
    _cityController.dispose();
    _postalCodeController.dispose();
    super.dispose();
  }

  void _onCountryChanged(String? newCountry) {
    if (newCountry == null || newCountry == _selectedCountry) return;
    setState(() {
      _selectedCountry = newCountry;
      _availableStates = LocationCatalog.getStatesForCountry(newCountry);
      if (_availableStates.isNotEmpty) {
        _selectedState = _availableStates.first;
      } else {
        _selectedState = null;
      }
    });
  }

  void _onStateChanged(String? newState) {
    setState(() {
      _selectedState = newState;
    });
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedState == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a valid registered state.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final address = AddressModel(
      line: _addressLineController.text.trim(),
      city: _cityController.text.trim(),
      state: _selectedState!,
      country: _selectedCountry,
      postalCode: _postalCodeController.text.trim(),
    );

    final cubit = context.read<OnboardingCubit>();
    final activeUser = (cubit.state is OnboardingLoaded)
        ? (cubit.state as OnboardingLoaded).bundle.user
        : widget.user;

    cubit.saveContactAndAddress(
          currentUser: activeUser,
          phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
          address: address,
        );
  }

  Widget _buildDropdownField({
    required String label,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    required IconData prefixIcon,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: (value != null && items.contains(value))
              ? value
              : (items.isNotEmpty ? items.first : null),
          isExpanded: true,
          decoration: InputDecoration(
            prefixIcon: Icon(prefixIcon, color: AppColors.textSecondary, size: 20),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          ),
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textSecondary),
          validator: validator,
          items: items.map((item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(
                item,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ],
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
              (state.currentStep == OnboardingStep.contactSaved ||
                  state.currentStep == OnboardingStep.profileSaved)) {
            // Update AuthBloc with latest user and transition to step 2
            context.read<AuthBloc>().add(AuthUserUpdated(state.bundle.user));
            context.go('/profile');
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
                      currentStep: 1,
                      totalSteps: 4,
                      title: 'Contact & Address Details',
                      subtitle: 'Help us connect with you for health alerts and emergency services.',
                      stepLabels: const ['Contact', 'Profile', 'Family', 'Plan'],
                      onBack: () => context.go('/'),
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
                                    // Phone Number
                                    CustomTextField(
                                      controller: _phoneController,
                                      label: 'Phone Number',
                                      hint: '+91 98765 43210',
                                      keyboardType: TextInputType.phone,
                                      prefixIcon: Icons.phone_outlined,
                                      helperText: 'Used for important health alerts and appointment updates',
                                      validator: Validators.validatePhone,
                                    ),
                                    const SizedBox(height: 18),

                                    // Street Address
                                    CustomTextField(
                                      controller: _addressLineController,
                                      label: 'Street / House Address',
                                      hint: 'Flat 402, Green Avenue, Main Road',
                                      prefixIcon: Icons.home_outlined,
                                      validator: Validators.validateAddressLine,
                                    ),
                                    const SizedBox(height: 18),

                                    // Country & State Dropdowns
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: _buildDropdownField(
                                            label: 'Country',
                                            value: _selectedCountry,
                                            items: LocationCatalog.countries,
                                            prefixIcon: Icons.public_outlined,
                                            onChanged: _onCountryChanged,
                                            validator: (val) => val == null || val.isEmpty ? 'Select Country' : null,
                                          ),
                                        ),
                                        const SizedBox(width: 14),
                                        Expanded(
                                          child: _buildDropdownField(
                                            label: 'State / Province',
                                            value: _selectedState,
                                            items: _availableStates,
                                            prefixIcon: Icons.map_outlined,
                                            onChanged: _onStateChanged,
                                            validator: (val) => val == null || val.isEmpty ? 'Select State' : null,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 18),

                                    // City & Postal Code
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: CustomTextField(
                                            controller: _cityController,
                                            label: 'City',
                                            hint: 'e.g. Bengaluru',
                                            prefixIcon: Icons.location_city_outlined,
                                            validator: Validators.validateCity,
                                          ),
                                        ),
                                        const SizedBox(width: 14),
                                        Expanded(
                                          child: CustomTextField(
                                            controller: _postalCodeController,
                                            label: 'Postal / PIN Code',
                                            hint: '560001',
                                            keyboardType: TextInputType.number,
                                            prefixIcon: Icons.markunread_mailbox_outlined,
                                            validator: Validators.validatePostalCode,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 24),

                              CustomButton(
                                text: 'Continue to Health Profile',
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
