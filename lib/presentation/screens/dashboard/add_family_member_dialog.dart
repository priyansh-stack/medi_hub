import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/validators.dart';
import '../../../data/models/member_profile_model.dart';
import '../../../data/repositories/family_repository.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class AddFamilyMemberDialog extends StatefulWidget {
  final String familyId;
  final String adminUid;
  final AddressModel? defaultAddress;
  final FamilyRepository repository;
  final Function(MemberProfileModel newMember) onMemberCreated;

  const AddFamilyMemberDialog({
    super.key,
    required this.familyId,
    required this.adminUid,
    this.defaultAddress,
    required this.repository,
    required this.onMemberCreated,
  });

  @override
  State<AddFamilyMemberDialog> createState() => _AddFamilyMemberDialogState();
}

class _AddFamilyMemberDialogState extends State<AddFamilyMemberDialog> {
  int _currentStep = 1; // 1: Personal Info, 2: Management & Consent, 3: Confirmation
  bool _isSubmitting = false;

  // Step 1 Controllers
  final _formKey1 = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  DateTime? _dateOfBirth = DateTime(2016, 5, 10);
  String _gender = 'Male';
  String _relationship = 'Child';
  String _bloodGroup = 'B+';

  // Step 2 Management
  String _managementType = 'guardianManaged'; // 'adminManaged', 'independentlyManaged', 'guardianManaged'
  bool _consentConfirmed = true;
  String? _consentError;

  final List<String> _genders = ['Male', 'Female', 'Other', 'Prefer not to say'];
  final List<String> _relationships = [
    'Spouse',
    'Child',
    'Parent',
    'Sibling',
    'Grandparent',
    'Relative',
    'Other',
  ];
  final List<String> _bloodGroups = [
    'A+',
    'A-',
    'B+',
    'B-',
    'AB+',
    'AB-',
    'O+',
    'O-',
    'Unknown',
  ];

  int? get _computedAge {
    if (_dateOfBirth == null) return null;
    final now = DateTime.now();
    int age = now.year - _dateOfBirth!.year;
    if (now.month < _dateOfBirth!.month ||
        (now.month == _dateOfBirth!.month && now.day < _dateOfBirth!.day)) {
      age--;
    }
    return age >= 0 ? age : 0;
  }

  bool get _isMinor => _computedAge != null && _computedAge! < 18;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickDateOfBirth() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth ?? DateTime(now.year - 15, 1, 1),
      firstDate: DateTime(1900),
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
        _dateOfBirth = picked;
        // Update management mode default according to age
        final age = _computedAge;
        if (age != null && age < 18) {
          _managementType = 'guardianManaged';
        } else if (_managementType == 'guardianManaged') {
          _managementType = 'adminManaged';
        }
      });
    }
  }

  void _goToStep2() {
    if (!_formKey1.currentState!.validate()) return;
    if (_dateOfBirth == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select Date of Birth.'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_isMinor) {
      _managementType = 'guardianManaged';
    } else if (_managementType == 'guardianManaged') {
      _managementType = 'adminManaged';
    }

    setState(() => _currentStep = 2);
  }

  Future<void> _submitAndCreate() async {
    if (!_consentConfirmed) {
      setState(() {
        _consentError = 'You must confirm authorization/consent to proceed.';
      });
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final newMember = await widget.repository.addFamilyMember(
        familyId: widget.familyId,
        adminUid: widget.adminUid,
        fullName: _nameController.text.trim(),
        dateOfBirth: _dateOfBirth!,
        gender: _gender,
        relationship: _relationship,
        managementType: _managementType,
        bloodGroup: _bloodGroup == 'Unknown' ? null : _bloodGroup,
        phone: _phoneController.text.trim().isNotEmpty ? _phoneController.text.trim() : null,
        address: widget.defaultAddress,
      );

      if (mounted) {
        Navigator.pop(context);
        widget.onMemberCreated(newMember);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add family member: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620, maxHeight: 780),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Scaffold(
            appBar: AppBar(
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.primarySurface,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.person_add_alt_1_rounded, color: AppColors.primary, size: 20),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Add Family Member',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              leading: IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.pop(context),
              ),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(40),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Row(
                    children: [
                      _buildStepIndicator(1, 'Personal Info'),
                      const Expanded(child: Divider(color: AppColors.border, thickness: 1)),
                      _buildStepIndicator(2, 'Management & Consent'),
                    ],
                  ),
                ),
              ),
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(22),
              child: _currentStep == 1 ? _buildStep1() : _buildStep2(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepIndicator(int step, String label) {
    final isActive = _currentStep >= step;
    return Row(
      children: [
        CircleAvatar(
          radius: 12,
          backgroundColor: isActive ? AppColors.primary : AppColors.border,
          child: Text(
            '$step',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isActive ? Colors.white : AppColors.textSecondary,
            ),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            color: isActive ? AppColors.primaryDark : AppColors.textSecondary,
          ),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  // ================= STEP 1: PERSONAL INFORMATION =================
  Widget _buildStep1() {
    final dobFormatted = _dateOfBirth != null
        ? DateFormat('d MMM yyyy').format(_dateOfBirth!)
        : 'Select date of birth';
    final ageText = _computedAge != null ? '($_computedAge years old)' : '';

    return Form(
      key: _formKey1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Step 1: Member Demographics',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 4),
          const Text(
            'Enter the personal details of the family member you wish to enroll in your household group.',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 18),

          // Full Name
          CustomTextField(
            label: 'Full Name *',
            hintText: 'e.g. Priya Sharma',
            controller: _nameController,
            prefixIcon: Icons.person_outline_rounded,
            validator: Validators.validateFullName,
          ),
          const SizedBox(height: 16),

          // Date of Birth & Age
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Date of Birth *',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 6),
              InkWell(
                onTap: _pickDateOfBirth,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_month_outlined, size: 20, color: AppColors.primary),
                      const SizedBox(width: 10),
                      Text(
                        dobFormatted,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: _dateOfBirth != null ? AppColors.textPrimary : AppColors.textSecondary,
                        ),
                      ),
                      if (ageText.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primarySurface,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            ageText,
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary),
                          ),
                        ),
                      ],
                      const Spacer(),
                      const Icon(Icons.arrow_drop_down, color: AppColors.textSecondary),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Gender & Relationship in Row
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Gender *',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue: _gender,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      items: _genders.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _gender = val);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Relationship *',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue: _relationship,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      items: _relationships.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _relationship = val);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Blood Group & Phone
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Blood Group',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue: _bloodGroup,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      items: _bloodGroups.map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _bloodGroup = val);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CustomTextField(
                  label: 'Phone (Optional)',
                  hintText: 'e.g. +91 9876543210',
                  controller: _phoneController,
                  prefixIcon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Next Button
          CustomButton(
            text: 'Continue to Profile Management',
            icon: Icons.arrow_forward_rounded,
            onPressed: _goToStep2,
          ),
        ],
      ),
    );
  }

  // ================= STEP 2: PROFILE MANAGEMENT & CONSENT =================
  Widget _buildStep2() {
    final isMinor = _isMinor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Step 2: Profile Management & Consent',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 4),
        const Text(
          'MediHub adheres to clinical governance and privacy standards. Specify how this profile will be administered.',
          style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 18),

        if (isMinor) ...[
          // Minor Guardian Notice
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.child_care_rounded, color: AppColors.primaryDark, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Authorized Guardian Management (Minor)',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.primaryDark),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_nameController.text.trim()} is $_computedAge years old (minor dependent). As the parent or legal guardian, you will manage their pediatric health records and clinical history.',
                        style: const TextStyle(fontSize: 12, color: AppColors.textPrimary, height: 1.35),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ] else ...[
          // Adult Member: Choice of management type
          const Text(
            'Select Adult Profile Administration Model:',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 8),

          // Option A: Admin Managed Caregiver
          _buildManagementOption(
            title: 'Admin Managed (Authorized Caregiver)',
            description:
                'The household admin manages records with the adult member\'s explicit authorization (ideal for dependent seniors or spouses).',
            value: 'adminManaged',
            icon: Icons.shield_outlined,
          ),
          const SizedBox(height: 10),

          // Option B: Independently Managed
          _buildManagementOption(
            title: 'Independently Managed (Self-Governed)',
            description:
                'The adult member retains direct privacy controls and will receive an invite to claim full ownership.',
            value: 'independentlyManaged',
            icon: Icons.vpn_key_outlined,
          ),
        ],

        const SizedBox(height: 20),

        // Consent and Authorization Confirmation
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _consentError != null ? AppColors.error : AppColors.border,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Checkbox(
                    value: _consentConfirmed,
                    activeColor: AppColors.primary,
                    onChanged: (val) {
                      setState(() {
                        _consentConfirmed = val ?? false;
                        if (_consentConfirmed) _consentError = null;
                      });
                    },
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Text(
                        isMinor
                            ? 'I certify that I am the parent or legally authorized guardian of ${_nameController.text.trim()} with full rights to manage their health records.'
                            : 'I confirm that I have obtained legal authorization and consent from ${_nameController.text.trim()} to create their MediHub profile and administer health records.',
                        style: const TextStyle(fontSize: 12, color: AppColors.textPrimary, height: 1.35),
                      ),
                    ),
                  ),
                ],
              ),
              if (_consentError != null) ...[
                Padding(
                  padding: const EdgeInsets.only(left: 48),
                  child: Text(
                    _consentError!,
                    style: const TextStyle(fontSize: 11, color: AppColors.error, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Action Buttons: Back + Submit
        Row(
          children: [
            Expanded(
              flex: 1,
              child: CustomButton(
                text: 'Back',
                variant: ButtonVariant.outline,
                onPressed: _isSubmitting ? null : () => setState(() => _currentStep = 1),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: CustomButton(
                text: 'Create Member Profile',
                icon: Icons.check_circle_outline_rounded,
                isLoading: _isSubmitting,
                onPressed: _submitAndCreate,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildManagementOption({
    required String title,
    required String description,
    required String value,
    required IconData icon,
  }) {
    final isSelected = _managementType == value;

    return InkWell(
      onTap: () => setState(() => _managementType = value),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primarySurface : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(icon, size: 16, color: isSelected ? AppColors.primaryDark : AppColors.textSecondary),
                      const SizedBox(width: 6),
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isSelected ? AppColors.primaryDark : AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, height: 1.3),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

