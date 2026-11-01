import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/location_catalog.dart';
import '../../../core/utils/validators.dart';
import '../../../data/models/member_profile_model.dart';
import '../../../data/models/user_model.dart';
import '../../widgets/custom_text_field.dart';

class MyHealthProfileTab extends StatefulWidget {
  final UserModel user;
  final MemberProfileModel? profile;
  final Future<void> Function(MemberProfileModel updatedProfile) onSaveProfile;

  const MyHealthProfileTab({
    super.key,
    required this.user,
    this.profile,
    required this.onSaveProfile,
  });

  @override
  State<MyHealthProfileTab> createState() => _MyHealthProfileTabState();
}

class _MyHealthProfileTabState extends State<MyHealthProfileTab> {
  bool _isEditing = false;
  bool _isSaving = false;
  final _formKey = GlobalKey<FormState>();

  // Controllers
  late final TextEditingController _nameController;
  late final TextEditingController _dobController;
  late final TextEditingController _phoneController;
  late final TextEditingController _addressLineController;
  late final TextEditingController _cityController;
  late final TextEditingController _pinController;
  late final TextEditingController _emergencyNameController;
  late final TextEditingController _emergencyRelationController;
  late final TextEditingController _emergencyPhoneController;
  late final TextEditingController _allergiesController;
  late final TextEditingController _conditionsController;

  String _gender = 'Male';
  String? _bloodGroup;
  String _country = 'India';
  String _state = 'Karnataka';
  List<String> _availableStates = [];

  static const List<String> _bloodGroups = [
    'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'
  ];

  static const List<String> _genderOptions = [
    'Male', 'Female', 'Other', 'Prefer not to say'
  ];

  @override
  void initState() {
    super.initState();
    _initControllersFromProfile();
  }

  void _initControllersFromProfile() {
    final p = widget.profile;
    _nameController = TextEditingController(text: p?.fullName ?? widget.user.fullName);
    _dobController = TextEditingController(
      text: p?.dateOfBirth != null ? DateFormat('dd/MM/yyyy').format(p!.dateOfBirth!) : '',
    );
    _phoneController = TextEditingController(text: p?.phone ?? '');
    _addressLineController = TextEditingController(text: p?.address.line ?? '');
    _cityController = TextEditingController(text: p?.address.city ?? '');
    _pinController = TextEditingController(text: p?.address.postalCode ?? '');
    _emergencyNameController = TextEditingController(text: p?.emergencyContactName ?? '');
    _emergencyRelationController = TextEditingController(text: p?.emergencyContactRelationship ?? '');
    _emergencyPhoneController = TextEditingController(text: p?.emergencyContactPhone ?? '');
    _allergiesController = TextEditingController(text: p?.allergies ?? '');
    _conditionsController = TextEditingController(text: p?.medicalConditions ?? '');

    _gender = p?.gender ?? 'Male';
    if (!_genderOptions.contains(_gender)) _gender = 'Male';

    _bloodGroup = p?.bloodGroup;
    if (_bloodGroup != null && !_bloodGroups.contains(_bloodGroup)) {
      _bloodGroup = null;
    }

    _country = LocationCatalog.isValidCountry(p?.address.country ?? '')
        ? p!.address.country
        : LocationCatalog.defaultCountry;
    _availableStates = LocationCatalog.getStatesForCountry(_country);

    _state = LocationCatalog.isValidState(_country, p?.address.state ?? '')
        ? p!.address.state
        : (_availableStates.isNotEmpty ? _availableStates.first : '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dobController.dispose();
    _phoneController.dispose();
    _addressLineController.dispose();
    _cityController.dispose();
    _pinController.dispose();
    _emergencyNameController.dispose();
    _emergencyRelationController.dispose();
    _emergencyPhoneController.dispose();
    _allergiesController.dispose();
    _conditionsController.dispose();
    super.dispose();
  }

  void _cancelEditing() {
    setState(() {
      _initControllersFromProfile();
      _isEditing = false;
    });
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      DateTime? parsedDob;
      if (_dobController.text.trim().isNotEmpty) {
        parsedDob = Validators.parseFlexibleDate(_dobController.text.trim());
      }

      final updatedProfile = (widget.profile ??
              MemberProfileModel(
                memberId: widget.user.memberId ?? 'mem_${widget.user.uid}',
                fullName: widget.user.fullName,
                gender: _gender,
                address: AddressModel(
                  line: _addressLineController.text.trim(),
                  city: _cityController.text.trim(),
                  state: _state,
                  country: _country,
                  postalCode: _pinController.text.trim(),
                ),
              ))
          .copyWith(
        fullName: _nameController.text.trim(),
        dateOfBirth: parsedDob,
        gender: _gender,
        bloodGroup: _bloodGroup,
        phone: _phoneController.text.trim(),
        address: AddressModel(
          line: _addressLineController.text.trim(),
          city: _cityController.text.trim(),
          state: _state,
          country: _country,
          postalCode: _pinController.text.trim(),
        ),
        emergencyContactName: _emergencyNameController.text.trim(),
        emergencyContactRelationship: _emergencyRelationController.text.trim(),
        emergencyContactPhone: _emergencyPhoneController.text.trim(),
        allergies: _allergiesController.text.trim(),
        medicalConditions: _conditionsController.text.trim(),
        updatedAt: DateTime.now(),
      );

      await widget.onSaveProfile(updatedProfile);

      if (mounted) {
        setState(() {
          _isEditing = false;
          _isSaving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Health profile updated successfully!'),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save profile: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _pickDateOfBirth() async {
    final now = DateTime.now();
    final initialDate = widget.profile?.dateOfBirth ?? DateTime(now.year - 25);
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
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
        _dobController.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = widget.profile;
    final memberId = widget.user.memberId ?? (profile?.memberId ?? 'mem_${widget.user.uid}');
    final updatedText = profile?.updatedAt != null
        ? DateFormat('d MMM yyyy, h:mm a').format(profile!.updatedAt!)
        : 'Initial registration';

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card with Actions & Status
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 14,
                runSpacing: 14,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircleAvatar(
                        radius: 26,
                        backgroundColor: AppColors.primarySurface,
                        child: Text(
                          widget.user.fullName.isNotEmpty ? widget.user.fullName[0].toUpperCase() : 'M',
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primary),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                widget.user.fullName,
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.primarySurface,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                                ),
                                child: Text(
                                  memberId,
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Last updated: $updatedText',
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (!_isEditing)
                    ElevatedButton.icon(
                      icon: const Icon(Icons.edit_rounded, size: 16),
                      label: const Text('Edit Profile'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                      onPressed: () => setState(() => _isEditing = true),
                    )
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        OutlinedButton(
                          onPressed: _isSaving ? null : _cancelEditing,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          ),
                          child: const Text('Cancel'),
                        ),
                        ElevatedButton.icon(
                          icon: _isSaving
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.save_rounded, size: 16),
                          label: Text(_isSaving ? 'Saving...' : 'Save Changes'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          ),
                          onPressed: _isSaving ? null : _saveChanges,
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Section 1: Personal Information
          _buildSectionCard(
            title: 'Personal Information',
            icon: Icons.person_outline_rounded,
            children: [
              if (!_isEditing) ...[
                _buildDisplayRow('Full Name', _nameController.text),
                _buildDisplayRow('Date of Birth', _dobController.text.isNotEmpty ? _dobController.text : 'Not specified'),
                _buildDisplayRow('Gender', _gender),
              ] else ...[
                CustomTextField(
                  label: 'Full Name',
                  controller: _nameController,
                  validator: Validators.validateFullName,
                  prefixIcon: Icons.person_outline,
                ),
                const SizedBox(height: 14),
                CustomTextField(
                  label: 'Date of Birth (DD/MM/YYYY)',
                  controller: _dobController,
                  validator: Validators.validateDob,
                  prefixIcon: Icons.calendar_today_outlined,
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.calendar_month, color: AppColors.primary),
                    onPressed: _pickDateOfBirth,
                  ),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  initialValue: _gender,
                  decoration: const InputDecoration(
                    labelText: 'Gender',
                    prefixIcon: Icon(Icons.transgender_rounded, size: 20),
                  ),
                  items: _genderOptions
                      .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _gender = val);
                  },
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),

          // Section 2: Health Identity
          _buildSectionCard(
            title: 'Health Identity',
            icon: Icons.badge_outlined,
            children: [
              if (!_isEditing) ...[
                _buildDisplayRow('Member ID', memberId),
                _buildDisplayRow('Blood Group', _bloodGroup ?? 'Not specified'),
                _buildDisplayRow('Allergies', _allergiesController.text.isNotEmpty ? _allergiesController.text : 'No known allergies'),
                _buildDisplayRow('Medical Conditions', _conditionsController.text.isNotEmpty ? _conditionsController.text : 'No chronic conditions'),
              ] else ...[
                _buildDisplayRow('Member ID (Permanent)', memberId),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  initialValue: _bloodGroup,
                  decoration: const InputDecoration(
                    labelText: 'Blood Group',
                    prefixIcon: Icon(Icons.bloodtype_outlined, size: 20),
                  ),
                  hint: const Text('Select Blood Group'),
                  items: _bloodGroups
                      .map((bg) => DropdownMenuItem(value: bg, child: Text(bg)))
                      .toList(),
                  onChanged: (val) => setState(() => _bloodGroup = val),
                ),
                const SizedBox(height: 14),
                CustomTextField(
                  label: 'Known Allergies (Optional)',
                  controller: _allergiesController,
                  prefixIcon: Icons.warning_amber_rounded,
                ),
                const SizedBox(height: 14),
                CustomTextField(
                  label: 'Medical Conditions / Notes (Optional)',
                  controller: _conditionsController,
                  prefixIcon: Icons.medical_information_outlined,
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),

          // Section 3: Contact & Address Information
          _buildSectionCard(
            title: 'Contact Information & Address',
            icon: Icons.location_on_outlined,
            children: [
              if (!_isEditing) ...[
                _buildDisplayRow('Registered Email', widget.user.email),
                _buildDisplayRow('Phone Number', _phoneController.text.isNotEmpty ? _phoneController.text : 'Not provided'),
                _buildDisplayRow('Address Line', _addressLineController.text.isNotEmpty ? _addressLineController.text : 'Not provided'),
                _buildDisplayRow('City', _cityController.text.isNotEmpty ? _cityController.text : 'Not provided'),
                _buildDisplayRow('State / Province', _state.isNotEmpty ? _state : 'Not provided'),
                _buildDisplayRow('Country', _country),
                _buildDisplayRow('Postal / PIN Code', _pinController.text.isNotEmpty ? _pinController.text : 'Not provided'),
              ] else ...[
                _buildDisplayRow('Registered Email (Auth Locked)', widget.user.email),
                const SizedBox(height: 14),
                CustomTextField(
                  label: 'Phone Number',
                  controller: _phoneController,
                  validator: Validators.validatePhone,
                  prefixIcon: Icons.phone_outlined,
                ),
                const SizedBox(height: 14),
                CustomTextField(
                  label: 'Street / House Address',
                  controller: _addressLineController,
                  validator: Validators.validateAddressLine,
                  prefixIcon: Icons.home_outlined,
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _country,
                        decoration: const InputDecoration(
                          labelText: 'Country',
                          prefixIcon: Icon(Icons.public_rounded, size: 20),
                        ),
                        items: LocationCatalog.countries
                            .map((c) => DropdownMenuItem(value: c, child: Text(c, overflow: TextOverflow.ellipsis)))
                            .toList(),
                        onChanged: (newCountry) {
                          if (newCountry != null && newCountry != _country) {
                            setState(() {
                              _country = newCountry;
                              _availableStates = LocationCatalog.getStatesForCountry(newCountry);
                              _state = _availableStates.isNotEmpty ? _availableStates.first : '';
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _availableStates.contains(_state) ? _state : (_availableStates.isNotEmpty ? _availableStates.first : null),
                        decoration: const InputDecoration(
                          labelText: 'State / Province',
                          prefixIcon: Icon(Icons.map_outlined, size: 20),
                        ),
                        items: _availableStates
                            .map((s) => DropdownMenuItem(value: s, child: Text(s, overflow: TextOverflow.ellipsis)))
                            .toList(),
                        onChanged: (newState) {
                          if (newState != null) setState(() => _state = newState);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: CustomTextField(
                        label: 'City',
                        controller: _cityController,
                        validator: Validators.validateCity,
                        prefixIcon: Icons.location_city_outlined,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: CustomTextField(
                        label: 'Postal / PIN Code',
                        controller: _pinController,
                        validator: Validators.validatePinCode,
                        prefixIcon: Icons.markunread_mailbox_outlined,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),

          // Section 4: Emergency Contact
          _buildSectionCard(
            title: 'Emergency Contact',
            icon: Icons.emergency_outlined,
            children: [
              if (!_isEditing) ...[
                _buildDisplayRow('Contact Name', _emergencyNameController.text.isNotEmpty ? _emergencyNameController.text : 'Not provided'),
                _buildDisplayRow('Relationship', _emergencyRelationController.text.isNotEmpty ? _emergencyRelationController.text : 'Not provided'),
                _buildDisplayRow('Emergency Phone', _emergencyPhoneController.text.isNotEmpty ? _emergencyPhoneController.text : 'Not provided'),
              ] else ...[
                CustomTextField(
                  label: 'Emergency Contact Name',
                  controller: _emergencyNameController,
                  prefixIcon: Icons.person_pin_circle_outlined,
                ),
                const SizedBox(height: 14),
                CustomTextField(
                  label: 'Relationship (e.g. Spouse, Parent, Sibling)',
                  controller: _emergencyRelationController,
                  prefixIcon: Icons.people_alt_outlined,
                ),
                const SizedBox(height: 14),
                CustomTextField(
                  label: 'Emergency Phone Number',
                  controller: _emergencyPhoneController,
                  prefixIcon: Icons.phone_in_talk_outlined,
                ),
              ],
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppColors.primary, size: 20),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const Divider(height: 22),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildDisplayRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
