import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/family_model.dart';
import '../../../data/models/member_profile_model.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/family_repository.dart';
import '../../widgets/custom_text_field.dart';
import 'add_family_member_dialog.dart';
import 'member_health_profile_screen.dart';

class FamilyGroupTab extends StatefulWidget {
  final UserModel user;
  final MemberProfileModel? profile;
  final FamilyModel? family;
  final Future<void> Function(String familyId, String newName) onUpdateFamilyName;
  final Future<void> Function(MemberProfileModel updatedProfile)? onSaveProfile;
  final FamilyRepository? repository;
  final bool autoOpenAddMember;
  final VoidCallback? onAddMemberClosed;

  const FamilyGroupTab({
    super.key,
    required this.user,
    this.profile,
    this.family,
    required this.onUpdateFamilyName,
    this.onSaveProfile,
    this.repository,
    this.autoOpenAddMember = false,
    this.onAddMemberClosed,
  });

  @override
  State<FamilyGroupTab> createState() => _FamilyGroupTabState();
}

class _FamilyGroupTabState extends State<FamilyGroupTab> {
  late final FamilyRepository _repository;
  List<MemberProfileModel> _members = [];
  bool _isLoadingMembers = true;
  bool _hasTriggeredAutoOpen = false;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? FamilyRepository();
    _loadMembers();
  }

  @override
  void didUpdateWidget(covariant FamilyGroupTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.autoOpenAddMember && !oldWidget.autoOpenAddMember) {
      _openAddMemberDialog();
    }
    if (widget.profile != oldWidget.profile || widget.family != oldWidget.family) {
      _loadMembers();
    }
  }

  Future<void> _loadMembers() async {
    final famId = widget.family?.familyId ?? 'fam_${widget.user.uid}';
    try {
      final list = await _repository.getFamilyMembers(
        familyId: famId,
        adminProfile: widget.profile,
        adminUid: widget.user.uid,
      );

      if (mounted) {
        setState(() {
          _members = list;
          _isLoadingMembers = false;
        });

        // Trigger auto open if requested from FAB
        if (widget.autoOpenAddMember && !_hasTriggeredAutoOpen) {
          _hasTriggeredAutoOpen = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _openAddMemberDialog();
          });
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          // Fallback to admin profile only if offline or error
          if (widget.profile != null) {
            _members = [
              widget.profile!.copyWith(
                relationship: 'Self',
                householdId: famId,
              ),
            ];
          }
          _isLoadingMembers = false;
        });
      }
    }
  }

  void _openAddMemberDialog() {
    final famId = widget.family?.familyId ?? 'fam_${widget.user.uid}';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AddFamilyMemberDialog(
        familyId: famId,
        adminUid: widget.user.uid,
        defaultAddress: widget.profile?.address,
        repository: _repository,
        onMemberCreated: (newMember) {
          widget.onAddMemberClosed?.call();
          _loadMembers();
          // Immediately open newly created member's Health Profile
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _openMemberHealthProfile(newMember);
          });
        },
      ),
    ).then((_) {
      widget.onAddMemberClosed?.call();
    });
  }

  void _openMemberHealthProfile(MemberProfileModel member) async {
    final updated = await Navigator.push<MemberProfileModel>(
      context,
      MaterialPageRoute(
        builder: (ctx) => MemberHealthProfileScreen(
          member: member,
          repository: _repository,
          onProfileUpdated: (updatedMember) {
            _loadMembers();
            if (updatedMember.relationship.toLowerCase() == 'self' && widget.onSaveProfile != null) {
              widget.onSaveProfile!(updatedMember);
            }
          },
        ),
      ),
    );
    if (updated != null) {
      if (updated.relationship.toLowerCase() == 'self' && widget.onSaveProfile != null) {
        widget.onSaveProfile!(updated);
      }
    }
    _loadMembers();
  }

  void _showEditFamilyNameDialog() {
    final currentFamily = widget.family;
    if (currentFamily == null) return;

    final nameController = TextEditingController(text: currentFamily.familyName);
    final formKey = GlobalKey<FormState>();
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Row(
                children: [
                  Icon(Icons.edit_rounded, color: AppColors.primary, size: 22),
                  SizedBox(width: 8),
                  Text(
                    'Edit Family Name',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Update the display name of your household health care group.',
                      style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      label: 'Family Group Name',
                      controller: nameController,
                      validator: (value) {
                        final trimmed = value?.trim() ?? '';
                        if (trimmed.isEmpty) return 'Family name is required';
                        if (trimmed.length < 2) return 'Must be at least 2 characters';
                        if (trimmed.length > 100) return 'Cannot exceed 100 characters';
                        return null;
                      },
                      prefixIcon: Icons.people_outline,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving ? null : () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: isSaving
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) return;
                          setDialogState(() => isSaving = true);
                          try {
                            await widget.onUpdateFamilyName(
                              currentFamily.familyId,
                              nameController.text.trim(),
                            );
                            if (ctx.mounted) {
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Family name updated successfully!'),
                                  backgroundColor: AppColors.primary,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          } catch (e) {
                            if (ctx.mounted) {
                              setDialogState(() => isSaving = false);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Failed to update family name: $e'),
                                  backgroundColor: AppColors.error,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          }
                        },
                  child: Text(isSaving ? 'Saving...' : 'Save Name'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final family = widget.family;
    final user = widget.user;
    final createdDateText = family?.createdAt != null
        ? DateFormat('d MMMM yyyy').format(family!.createdAt!)
        : 'Initial registration';

    final memberCount = _members.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Family Summary Card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.primarySurface,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.family_restroom_rounded,
                              color: AppColors.primary,
                              size: 26,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  family?.familyName ?? '${user.fullName} Household',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  'Family ID: ${family?.familyId ?? 'fam_${user.uid}'}',
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
                    ),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.edit_rounded, size: 15),
                      label: const Text('Edit Name'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      ),
                      onPressed: _showEditFamilyNameDialog,
                    ),
                  ],
                ),
                const Divider(height: 24),
                _buildInfoRow('Family Admin', '${user.fullName} (${user.email})'),
                const SizedBox(height: 8),
                _buildInfoRow('Created Date', createdDateText),
                const SizedBox(height: 8),
                _buildInfoRow('Description', family?.description?.isNotEmpty == true ? family!.description! : 'Primary household care group'),
                const SizedBox(height: 8),
                _buildInfoRow('Active Members', '$memberCount enrolled ${memberCount == 1 ? 'member' : 'members'}'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),

        // 2. Household Members Roster
        Card(
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.people_outline_rounded, color: AppColors.primary, size: 22),
                        const SizedBox(width: 10),
                        const Text(
                          'Household Members Roster',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Chip(
                          label: Text(
                            '$memberCount ${memberCount == 1 ? 'Member' : 'Members'}',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primaryDark),
                          ),
                          backgroundColor: AppColors.primarySurface,
                          side: BorderSide.none,
                          padding: EdgeInsets.zero,
                        ),
                      ],
                    ),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.person_add_alt_1_rounded, size: 16),
                      label: const Text('Add Family Member'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: _openAddMemberDialog,
                    ),
                  ],
                ),
                const Divider(height: 20),

                if (_isLoadingMembers) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ] else if (_members.isEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Text('No family members found.', style: TextStyle(color: AppColors.textSecondary)),
                    ),
                  ),
                ] else ...[
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _members.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final m = _members[index];
                      return _buildMemberCard(m);
                    },
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildMemberCard(MemberProfileModel member) {
    final isSelf = member.relationship.toLowerCase() == 'self';
    final relationshipLabel = isSelf ? 'FAMILY ADMIN' : member.relationship.toUpperCase();
    final pct = member.completionPercentage;

    return Material(
      color: AppColors.scaffoldBg,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () => _openMemberHealthProfile(member),
        borderRadius: BorderRadius.circular(12),
        hoverColor: AppColors.primarySurface.withValues(alpha: 0.5),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: isSelf ? AppColors.primary : AppColors.info,
                    child: Text(
                      member.fullName.isNotEmpty ? member.fullName[0].toUpperCase() : 'M',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                member.fullName,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: isSelf ? AppColors.primary : AppColors.primarySurface,
                                borderRadius: BorderRadius.circular(10),
                                border: isSelf ? null : Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                              ),
                              child: Text(
                                relationshipLabel,
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  color: isSelf ? Colors.white : AppColors.primaryDark,
                                  letterSpacing: 0.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'ID: ${member.memberId} • ${member.ageDisplay} • ${member.gender}',
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            if (member.bloodGroup != null)
                              _buildMiniBadge('Blood: ${member.bloodGroup}', AppColors.primary),
                            _buildMiniBadge(
                              member.managementType == 'guardianManaged'
                                  ? 'Guardian Managed'
                                  : member.managementType == 'independentlyManaged'
                                      ? 'Independent'
                                      : 'Admin Managed',
                              AppColors.textSecondary,
                            ),
                            _buildProfileStatusBadge(member.profileStatus),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${pct.toStringAsFixed(0)}%',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Completed',
                        style: TextStyle(fontSize: 10, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Progress Bar
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (pct / 100).clamp(0.0, 1.0),
                  minHeight: 6,
                  backgroundColor: Colors.white,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),
              const SizedBox(height: 10),
              // Four-Tier Progress Pills
              Row(
                children: [
                  Expanded(child: _buildTierPill('T1 Safety', member.tier1Status)),
                  const SizedBox(width: 6),
                  Expanded(child: _buildTierPill('T2 Core', member.tier2Status)),
                  const SizedBox(width: 6),
                  Expanded(child: _buildTierPill('T3 Life', member.tier3Status)),
                  const SizedBox(width: 6),
                  Expanded(child: _buildTierPill('T4 Context', member.tier4Status)),
                ],
              ),
              const SizedBox(height: 8),
              const Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(Icons.touch_app_outlined, size: 13, color: AppColors.primary),
                  SizedBox(width: 4),
                  Text(
                    'Click card to view / edit health profile',
                    style: TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTierPill(String tierName, String status) {
    Color bg;
    Color fg;
    switch (status.toLowerCase()) {
      case 'completed':
        bg = AppColors.successBg;
        fg = AppColors.success;
        break;
      case 'in progress':
        bg = AppColors.warningBg;
        fg = AppColors.warning;
        break;
      default:
        bg = Colors.white;
        fg = AppColors.textSecondary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: fg.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            tierName,
            style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          ),
          Text(
            status,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 8, fontWeight: FontWeight.w600, color: fg),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: color),
      ),
    );
  }

  Widget _buildProfileStatusBadge(String status) {
    Color bg;
    Color fg;
    switch (status.toLowerCase()) {
      case 'completed':
        bg = AppColors.successBg;
        fg = AppColors.success;
        break;
      case 'in progress':
        bg = AppColors.warningBg;
        fg = AppColors.warning;
        break;
      default:
        bg = Colors.white;
        fg = AppColors.textSecondary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: fg.withValues(alpha: 0.3)),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: fg),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 130,
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
    );
  }
}
