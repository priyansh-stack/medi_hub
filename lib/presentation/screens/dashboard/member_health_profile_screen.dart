import 'package:flutter/material.dart';
import '../../../core/clinical/clinical_engine.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/clinical_plan_model.dart';
import '../../../data/models/member_profile_model.dart';
import '../../../data/models/profile_completion_model.dart';
import '../../../data/repositories/family_repository.dart';
import '../../widgets/clinical/clinical_field_renderer.dart';
import '../../widgets/custom_button.dart';

class MemberHealthProfileScreen extends StatefulWidget {
  final MemberProfileModel member;
  final FamilyRepository repository;
  final Function(MemberProfileModel updatedMember)? onProfileUpdated;

  const MemberHealthProfileScreen({
    super.key,
    required this.member,
    required this.repository,
    this.onProfileUpdated,
  });

  @override
  State<MemberHealthProfileScreen> createState() => _MemberHealthProfileScreenState();
}

class _MemberHealthProfileScreenState extends State<MemberHealthProfileScreen> {
  late MemberProfileModel _member;
  ClinicalCollectionPlanModel? _clinicalPlan;
  ProfileCompletionModel? _completion;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _member = widget.member;
    _loadPlanAndCompletion();
  }

  Future<void> _loadPlanAndCompletion() async {
    setState(() => _isLoading = true);
    try {
      final plan = await widget.repository.ensureClinicalPlan(_member);
      final completion = await widget.repository.ensureProfileCompletion(_member, plan);
      if (mounted) {
        setState(() {
          _clinicalPlan = plan;
          _completion = completion;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _openTierQuestionnaire(int tier) {
    if (_clinicalPlan == null || _completion == null) return;

    final applicableSections = ClinicalEngine.getSectionsForTier(
      tier: tier,
      plan: _clinicalPlan!,
    );

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _TierQuestionnaireDialog(
        tier: tier,
        member: _member,
        plan: _clinicalPlan!,
        completion: _completion!,
        sections: applicableSections,
        onSave: (newAnswers, newConsent) async {
          final updatedCompletion = await widget.repository.saveTierAnswers(
            member: _member,
            plan: _clinicalPlan!,
            newSectionAnswers: newAnswers,
            newConsentMap: newConsent,
          );

          if (mounted) {
            final updatedMember = _member.copyWith(
              completionPercentage: updatedCompletion.overallPercentage,
              tier1Status: updatedCompletion.tier1Status,
              tier2Status: updatedCompletion.tier2Status,
              tier3Status: updatedCompletion.tier3Status,
              tier4Status: updatedCompletion.tier4Status,
              profileStatus: updatedCompletion.overallPercentage >= 100.0
                  ? 'Completed'
                  : updatedCompletion.overallPercentage > 0.0
                      ? 'In Progress'
                      : 'Not Started',
            );
            setState(() {
              _completion = updatedCompletion;
              _member = updatedMember;
            });
            widget.onProfileUpdated?.call(updatedMember);
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        title: Text('${_member.fullName} — Health Profile'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context, _member),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 860),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Member Demographics Header Card
                        _buildMemberHeaderCard(),
                        const SizedBox(height: 20),

                        // Overall Completion Progress Card
                        _buildOverallProgressCard(),
                        const SizedBox(height: 24),

                        // Section Heading
                        Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            const Text(
                              'Four-Tier Clinical Profile Collection',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                                letterSpacing: -0.3,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.successBg,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.verified, size: 12, color: AppColors.success),
                                  SizedBox(width: 4),
                                  Text(
                                    'WHO & ICMR Aligned',
                                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.success),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Clinical Engine ${ClinicalEngine.engineVersion} generated individualized health tiers for ${_member.fullName} (${_clinicalPlan?.ageBand.toUpperCase() ?? 'ADULT'}).',
                          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 16),

                        // Tier 1 Card
                        _buildTierCard(
                          tier: 1,
                          title: 'Tier 1 — Safety-Critical',
                          description:
                              'Blood group & Rh typing, emergency contacts, high-risk allergies (anaphylaxis triggers), critical medications (insulin/anticoagulants), implanted devices, and acute condition alerts.',
                          status: _completion?.tier1Status ?? 'Not Started',
                          icon: Icons.health_and_safety_rounded,
                          accentColor: AppColors.error,
                        ),
                        const SizedBox(height: 14),

                        // Tier 2 Card
                        _buildTierCard(
                          tier: 2,
                          title: 'Tier 2 — Core Health Record',
                          description:
                              'Chronic diagnoses (hypertension/diabetes), routine allergies, current medications, immunization schedule, surgeries, vitals baseline (BP/BMI/blood glucose), and care team.',
                          status: _completion?.tier2Status ?? 'Not Started',
                          icon: Icons.medical_services_outlined,
                          accentColor: AppColors.primary,
                        ),
                        const SizedBox(height: 14),

                        // Tier 3 Card
                        _buildTierCard(
                          tier: 3,
                          title: 'Tier 3 — Longitudinal & Life-Stage',
                          description:
                              'Family medical history, lifestyle & wellbeing (sleep/activity), social determinants, pediatric birth milestones, adolescent school health, or geriatric fall risk & mobility.',
                          status: _completion?.tier3Status ?? 'Not Started',
                          icon: Icons.timeline_rounded,
                          accentColor: AppColors.info,
                        ),
                        const SizedBox(height: 14),

                        // Tier 4 Card
                        _buildTierCard(
                          tier: 4,
                          title: 'Tier 4 — Advanced & Contextual',
                          description:
                              'Mental health & mood screening, consent-gated sensitive details, substance & tobacco history, sensory & oral health, genetics, and clinical research interests.',
                          status: _completion?.tier4Status ?? 'Not Started',
                          icon: Icons.psychology_outlined,
                          accentColor: const Color(0xFF8E24AA),
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildMemberHeaderCard() {
    final relationship = _member.relationship;
    final isSelf = relationship.toLowerCase() == 'self';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: AppColors.primary,
              child: Text(
                _member.fullName.isNotEmpty ? _member.fullName[0].toUpperCase() : 'M',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          _member.fullName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                        decoration: BoxDecoration(
                          color: isSelf ? AppColors.primary : AppColors.primarySurface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelf ? AppColors.primary : AppColors.primary.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          isSelf ? 'FAMILY ADMIN' : relationship.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: isSelf ? Colors.white : AppColors.primaryDark,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Member ID: ${_member.memberId} • ${_member.ageDisplay} • ${_member.gender}',
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      if (_member.bloodGroup != null && _member.bloodGroup!.isNotEmpty)
                        _buildPillBadge('Blood: ${_member.bloodGroup}', AppColors.primary),
                      _buildPillBadge(
                        _member.managementType == 'guardianManaged'
                            ? 'Guardian Managed'
                            : _member.managementType == 'independentlyManaged'
                                ? 'Self Governed'
                                : 'Admin Managed',
                        AppColors.textSecondary,
                      ),
                      _buildPillBadge(
                        'Engine: ${_clinicalPlan?.ageBand.toUpperCase() ?? 'ADULT'}',
                        AppColors.info,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPillBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color),
      ),
    );
  }

  Widget _buildOverallProgressCard() {
    final pct = _completion?.overallPercentage ?? 0.0;
    final completedCount = _completion?.completedSections.length ?? 0;
    final pendingCount = _completion?.pendingSections.length ?? 0;
    final totalSections = completedCount + pendingCount;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Overall Profile Completion',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Progress across all applicable clinical sections',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
              Text(
                '${pct.toStringAsFixed(0)}%',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: (pct / 100).clamp(0.0, 1.0),
              minHeight: 10,
              backgroundColor: AppColors.scaffoldBg,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$completedCount of $totalSections applicable sections completed',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textSecondary),
              ),
              _buildTierStatusBadge(pct >= 100.0 ? 'Completed' : pct > 0.0 ? 'In Progress' : 'Not Started'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTierCard({
    required int tier,
    required String title,
    required String description,
    required String status,
    required IconData icon,
    required Color accentColor,
  }) {
    final sections = _clinicalPlan != null
        ? ClinicalEngine.getSectionsForTier(tier: tier, plan: _clinicalPlan!)
        : <ClinicalSectionDefinition>[];

    final isCompleted = status.toLowerCase() == 'completed';
    final actionLabel = isCompleted ? 'Review Tier' : status.toLowerCase() == 'in progress' ? 'Continue Tier' : 'Start Tier';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: accentColor, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${sections.length} applicable clinical modules for this member',
                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                _buildTierStatusBadge(status),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              description,
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.35),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: Icon(isCompleted ? Icons.check_circle_outline : Icons.edit_note_rounded, size: 18),
                label: Text(actionLabel),
                style: OutlinedButton.styleFrom(
                  foregroundColor: accentColor,
                  side: BorderSide(color: accentColor.withValues(alpha: 0.5)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () => _openTierQuestionnaire(tier),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTierStatusBadge(String status) {
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
        bg = AppColors.scaffoldBg;
        fg = AppColors.textSecondary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: fg.withValues(alpha: 0.3)),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: fg, letterSpacing: 0.4),
      ),
    );
  }
}

// ================= COMPREHENSIVE DYNAMIC TIER QUESTIONNAIRE =================
class _TierQuestionnaireDialog extends StatefulWidget {
  final int tier;
  final MemberProfileModel member;
  final ClinicalCollectionPlanModel plan;
  final ProfileCompletionModel completion;
  final List<ClinicalSectionDefinition> sections;
  final Function(Map<String, dynamic> answers, Map<String, bool> consent) onSave;

  const _TierQuestionnaireDialog({
    required this.tier,
    required this.member,
    required this.plan,
    required this.completion,
    required this.sections,
    required this.onSave,
  });

  @override
  State<_TierQuestionnaireDialog> createState() => _TierQuestionnaireDialogState();
}

class _TierQuestionnaireDialogState extends State<_TierQuestionnaireDialog> {
  late Map<String, dynamic> _answers;
  late Map<String, bool> _consent;
  final Map<String, String> _validationErrors = {};
  bool _isSaving = false;
  String _filterQuery = '';
  String _activeTabFilter = 'all'; // 'all', 'pending', 'completed'

  @override
  void initState() {
    super.initState();
    _answers = Map<String, dynamic>.from(widget.completion.tierData);
    _consent = Map<String, bool>.from(widget.completion.consentGiven);

    _prepopulateFromMemberProfile();
  }

  void _prepopulateFromMemberProfile() {
    // Tier 1 Blood Group pre-fill if not already documented
    if (widget.tier == 1 && !_answers.containsKey('t1_blood_group')) {
      final bg = widget.member.bloodGroup;
      if (bg != null && bg.isNotEmpty) {
        String abo = 'Unknown';
        String rh = 'Unknown';
        if (bg.contains('+')) {
          rh = 'Positive';
          abo = bg.replaceAll('+', '').trim();
        } else if (bg.contains('-')) {
          rh = 'Negative';
          abo = bg.replaceAll('-', '').trim();
        } else {
          abo = bg;
        }

        _answers['t1_blood_group'] = {
          'state': 'completed',
          'value': bg,
          'fields': {
            'bloodGroup': abo,
            'rhFactor': rh,
            'verificationStatus': 'self_reported',
          },
          'summary': '$bg (Self Reported)',
        };
      }
    }

    // Tier 1 Emergency Contacts pre-fill if available in Member profile
    if (widget.tier == 1 && !_answers.containsKey('t1_emergency_contacts')) {
      final eName = widget.member.emergencyContactName;
      final ePhone = widget.member.emergencyContactPhone;
      final eRel = widget.member.emergencyContactRelationship;
      if (eName != null && eName.isNotEmpty) {
        _answers['t1_emergency_contacts'] = {
          'state': 'completed',
          'value': '$eName ($ePhone)',
          'fields': {
            'contact1Name': eName,
            'contact1Relationship': eRel ?? 'Family',
            'contact1Phone': ePhone ?? '',
            'contact1Priority': 'Primary',
            'contact1Details': '',
          },
          'summary': '$eName ($eRel) - $ePhone',
        };
      }
    }
  }

  AgeBand get _ageBand => ClinicalEngine.determineAgeBand(widget.member.dateOfBirth);

  void _handleFieldChanged(String sectionId, String fieldId, dynamic val) {
    setState(() {
      _validationErrors.remove('$sectionId.$fieldId');

      final currentSec = _answers[sectionId] is Map
          ? Map<String, dynamic>.from(_answers[sectionId])
          : <String, dynamic>{'fields': <String, dynamic>{}};

      final fieldsMap = currentSec['fields'] is Map
          ? Map<String, dynamic>.from(currentSec['fields'])
          : <String, dynamic>{};

      if (val == null) {
        fieldsMap.remove(fieldId);
      } else if (val is Map && val.containsKey('state')) {
        // Field marked as explicit state
        fieldsMap[fieldId] = val;
      } else {
        fieldsMap[fieldId] = val;
      }

      currentSec['fields'] = fieldsMap;

      // Special handling for BMI live calculation in Tier 2 Vitals
      if (sectionId == 't2_vitals') {
        final hStr = _extractFieldValue(fieldsMap['heightCm']);
        final wStr = _extractFieldValue(fieldsMap['weightKg']);
        final h = double.tryParse(hStr ?? '');
        final w = double.tryParse(wStr ?? '');
        if (h != null && w != null && h > 0) {
          final bmi = w / ((h / 100) * (h / 100));
          fieldsMap['bodyMassIndex'] = {
            'value': bmi.toStringAsFixed(1),
            'state': 'completed',
          };
        }
      }

      // Generate human-readable summary
      final summary = _generateSectionSummary(sectionId, fieldsMap);
      currentSec['summary'] = summary;
      currentSec['value'] = summary;
      currentSec['state'] = fieldsMap.isEmpty ? 'notyetcollected' : 'completed';
      currentSec['lastUpdated'] = DateTime.now().toIso8601String();

      _answers[sectionId] = currentSec;
    });
  }

  String? _extractFieldValue(dynamic raw) {
    if (raw == null) return null;
    if (raw is Map) return raw['value']?.toString();
    return raw.toString();
  }

  String _generateSectionSummary(String sectionId, Map<String, dynamic> fields) {
    final recordState = _extractFieldValue(fields['recordState'])?.toLowerCase();
    if (recordState == 'no_known') {
      return 'No known records / None documented';
    } else if (recordState == 'unknown') {
      return 'Unknown / Not sure';
    }

    switch (sectionId) {
      case 't1_blood_group':
        final abo = _extractFieldValue(fields['bloodGroup']) ?? 'Unknown';
        final rh = _extractFieldValue(fields['rhFactor']);
        final rhText = rh == 'Positive' ? '+' : rh == 'Negative' ? '-' : '';
        final ver = _extractFieldValue(fields['verificationStatus']) ?? 'Unverified';
        return '$abo$rhText ($ver)';

      case 't1_emergency_contacts':
        final name = _extractFieldValue(fields['contact1Name']) ?? '';
        final rel = _extractFieldValue(fields['contact1Relationship']) ?? '';
        final phone = _extractFieldValue(fields['contact1Phone']) ?? '';
        return '$name ($rel) • $phone';

      case 't1_critical_allergies':
        final allergen = _extractFieldValue(fields['allergenName']) ?? 'Allergy';
        final reaction = _extractFieldValue(fields['allergyReaction']) ?? '';
        final sev = _extractFieldValue(fields['allergySeverity']) ?? '';
        return '$allergen — $reaction ($sev)';

      case 't1_critical_medications':
        final med = _extractFieldValue(fields['medicationName']) ?? 'Medication';
        final str = _extractFieldValue(fields['strength']) ?? '';
        final freq = _extractFieldValue(fields['frequency']) ?? '';
        return '$med $str ($freq)';

      case 't1_critical_conditions':
        final cond = _extractFieldValue(fields['conditionName']) ?? 'Condition';
        final stat = _extractFieldValue(fields['conditionStatus']) ?? '';
        return '$cond ($stat)';

      case 't1_implanted_devices':
        final dev = _extractFieldValue(fields['deviceName']) ?? _extractFieldValue(fields['deviceCategory']) ?? 'Device';
        final mri = _extractFieldValue(fields['mriSafetyStatus']) ?? '';
        return '$dev ($mri)';

      case 't2_vitals':
        final sys = _extractFieldValue(fields['systolicBp']) ?? '--';
        final dia = _extractFieldValue(fields['diastolicBp']) ?? '--';
        final hr = _extractFieldValue(fields['heartRate']) ?? '--';
        final bmi = _extractFieldValue(fields['bodyMassIndex']) ?? '--';
        return 'BP: $sys/$dia mmHg • Pulse: $hr bpm • BMI: $bmi';

      default:
        // Generic fallback summary from first available field value
        for (final entry in fields.entries) {
          final val = _extractFieldValue(entry.value);
          if (val != null && val.isNotEmpty) {
            return '${entry.key}: $val';
          }
        }
        return 'Documented';
    }
  }

  void _markSectionExplicitState(String sectionId, String stateKey) {
    setState(() {
      final currentSec = _answers[sectionId] is Map ? Map<String, dynamic>.from(_answers[sectionId]) : <String, dynamic>{};
      final currentState = currentSec['state']?.toString().toLowerCase();

      if (currentState == stateKey) {
        // Toggle off
        _answers.remove(sectionId);
      } else {
        _answers[sectionId] = {
          'state': stateKey,
          'value': stateKey.toUpperCase(),
          'summary': 'Marked as ${stateKey.toUpperCase()}',
          'fields': <String, dynamic>{},
          'lastUpdated': DateTime.now().toIso8601String(),
        };
      }
    });
  }

  bool _validateAllFields() {
    _validationErrors.clear();
    bool hasErrors = false;

    for (final sec in widget.sections) {
      final secData = _answers[sec.id];
      if (secData == null) {
        // Unstarted section remains pending, does not block saving progress
        continue;
      }

      if (secData is Map) {
        final secState = secData['state']?.toString().toLowerCase();
        if (secState == 'unknown' || secState == 'notapplicable' || secState == 'declined') {
          continue;
        }

        final secMap = secData['fields'] is Map
            ? Map<String, dynamic>.from(secData['fields'])
            : const <String, dynamic>{};

        if (secMap.isEmpty) {
          continue; // No fields entered in this section yet
        }

        final fields = ClinicalEngine.getFieldsForSection(
          sec.id,
          ageBand: _ageBand,
          gender: widget.member.gender,
        );

        final recordState = _extractFieldValue(secMap['recordState'])?.toLowerCase();
        final isRecordNegativeOrUnknown = recordState == 'no_known' || recordState == 'unknown';

        for (final field in fields) {
          // If field has conditional visibility that isn't met, skip
          if (field.conditionalParentId != null) {
            final parentVal = _extractFieldValue(secMap[field.conditionalParentId])?.toLowerCase();
            if (parentVal != field.conditionalValue.toString().toLowerCase()) {
              continue;
            }
          }

          if (isRecordNegativeOrUnknown && field.fieldId != 'recordState') {
            continue;
          }

          final fieldVal = secMap[field.fieldId];
          final error = ClinicalEngine.validateFieldValue(
            field,
            fieldVal,
            memberDob: widget.member.dateOfBirth,
          );

          if (error != null) {
            _validationErrors['${sec.id}.${field.fieldId}'] = error;
            hasErrors = true;
          }
        }
      }
    }

    setState(() {});
    return !hasErrors;
  }

  Future<void> _handleSave() async {
    final isValid = _validateAllFields();
    if (!isValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please correct the ${_validationErrors.length} highlighted clinical field error(s) before saving.'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      await widget.onSave(_answers, _consent);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Tier ${widget.tier} clinical progress saved successfully!'),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save tier data: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Filter sections based on search query and active status tab
    final filteredSections = widget.sections.where((sec) {
      if (_filterQuery.isNotEmpty) {
        final q = _filterQuery.toLowerCase();
        final matchesTitle = sec.title.toLowerCase().contains(q);
        final matchesSub = sec.subtitle.toLowerCase().contains(q);
        if (!matchesTitle && !matchesSub) return false;
      }

      final isAnswered = _answers.containsKey(sec.id) && _answers[sec.id] != null;
      if (_activeTabFilter == 'pending' && isAnswered) return false;
      if (_activeTabFilter == 'completed' && !isAnswered) return false;

      return true;
    }).toList();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 820, maxHeight: 880),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Scaffold(
            appBar: AppBar(
              title: Text('Tier ${widget.tier} Clinical Questionnaire'),
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
              actions: [
                TextButton(
                  onPressed: _isSaving ? null : _handleSave,
                  child: Text(
                    _isSaving ? 'Saving...' : 'Save & Exit',
                    style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary),
                  ),
                ),
              ],
            ),
            body: Column(
              children: [
                // Questionnaire Header
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  color: AppColors.scaffoldBg,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Clinical Protocol for ${widget.member.fullName}',
                                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Age Band: ${_ageBand.name.toUpperCase()} • All health fields require verified values or explicit clinical states.',
                                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primarySurface,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${widget.sections.where((s) => _answers.containsKey(s.id)).length} of ${widget.sections.length} Answered',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primaryDark),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Search bar & status filter chips
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              decoration: InputDecoration(
                                hintText: 'Search modules in this tier (e.g. allergies, vitals)...',
                                prefixIcon: const Icon(Icons.search, size: 18, color: AppColors.textSecondary),
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              onChanged: (val) {
                                setState(() {
                                  _filterQuery = val.trim();
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          _buildFilterTabChip('all', 'All'),
                          const SizedBox(width: 4),
                          _buildFilterTabChip('pending', 'Pending'),
                          const SizedBox(width: 4),
                          _buildFilterTabChip('completed', 'Completed'),
                        ],
                      ),
                    ],
                  ),
                ),

                // Main Sections List
                Expanded(
                  child: filteredSections.isEmpty
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(32),
                            child: Text(
                              'No matching clinical modules found.',
                              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: filteredSections.length,
                          itemBuilder: (ctx, index) {
                            final sec = filteredSections[index];
                            return _buildSectionCard(sec);
                          },
                        ),
                ),

                // Bottom Save Action Bar
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(top: BorderSide(color: AppColors.border)),
                  ),
                  child: CustomButton(
                    text: 'Save Tier ${widget.tier} Progress',
                    icon: Icons.check_circle_outline,
                    isLoading: _isSaving,
                    onPressed: _handleSave,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterTabChip(String key, String label) {
    final isSelected = _activeTabFilter == key;
    return ChoiceChip(
      label: Text(label, style: TextStyle(fontSize: 10, fontWeight: isSelected ? FontWeight.bold : FontWeight.w500)),
      selected: isSelected,
      selectedColor: AppColors.primarySurface,
      labelStyle: TextStyle(color: isSelected ? AppColors.primaryDark : AppColors.textPrimary),
      onSelected: (_) => setState(() => _activeTabFilter = key),
    );
  }

  Widget _buildSectionCard(ClinicalSectionDefinition sec) {
    final isGated = sec.isGated;
    final hasConsent = _consent[sec.id] == true;
    final secData = _answers[sec.id];
    final isAnswered = secData != null;
    String secState = '';
    String summary = '';
    Map<String, dynamic> fieldsMap = {};

    if (secData is Map) {
      secState = secData['state']?.toString().toLowerCase() ?? '';
      summary = secData['summary']?.toString() ?? secData['value']?.toString() ?? '';
      if (secData['fields'] is Map) {
        fieldsMap = Map<String, dynamic>.from(secData['fields']);
      }
    }

    final fields = ClinicalEngine.getFieldsForSection(
      sec.id,
      ageBand: _ageBand,
      gender: widget.member.gender,
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isAnswered ? AppColors.primary.withValues(alpha: 0.3) : AppColors.border,
          width: isAnswered ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isAnswered ? AppColors.primarySurface.withValues(alpha: 0.4) : AppColors.scaffoldBg.withValues(alpha: 0.5),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(13)),
              border: const Border(bottom: BorderSide(color: AppColors.border, width: 0.5)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              sec.title,
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                            ),
                          ),
                          if (sec.isRequired) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: AppColors.errorBg,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'REQUIRED',
                                style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: AppColors.error),
                              ),
                            ),
                          ],
                          if (isGated) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: AppColors.warningBg,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'CONSENT GATED',
                                style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: AppColors.warning),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        sec.subtitle,
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.3),
                      ),
                      if (summary.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                          ),
                          child: Text(
                            'Recorded: $summary',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primaryDark),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 10),

                // Quick Section State Dropdown / Action
                PopupMenuButton<String>(
                  icon: Icon(
                    isAnswered ? Icons.check_circle : Icons.more_vert,
                    color: isAnswered ? AppColors.success : AppColors.textSecondary,
                  ),
                  tooltip: 'Mark Module State',
                  onSelected: (val) {
                    if (val == 'clear') {
                      setState(() => _answers.remove(sec.id));
                    } else {
                      _markSectionExplicitState(sec.id, val);
                    }
                  },
                  itemBuilder: (ctx) => [
                    const PopupMenuItem(value: 'unknown', child: Text('Mark Entire Module as Unknown')),
                    const PopupMenuItem(value: 'notapplicable', child: Text('Mark Module as Not Applicable')),
                    if (isGated || sec.tier >= 3)
                      const PopupMenuItem(value: 'declined', child: Text('Mark Module as Declined')),
                    if (isAnswered)
                      const PopupMenuItem(value: 'clear', child: Text('Clear Module Answers', style: TextStyle(color: AppColors.error))),
                  ],
                ),
              ],
            ),
          ),

          // Section Body: Consent Gate or Dynamic Structured Fields
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isGated && !hasConsent) ...[
                  // Neutral Consent Banner for Sensitive Modules
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.warningBg.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.warning.withValues(alpha: 0.5)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.lock_outline, size: 20, color: AppColors.warning),
                            SizedBox(width: 8),
                            Text(
                              'Explicit Consent Required',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'This module gathers sensitive clinical and lifestyle information under strict confidentiality guidelines. You may choose to authorize collection, or decline without any impact on record validity.',
                          style: TextStyle(fontSize: 12, color: AppColors.textPrimary, height: 1.35),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              ),
                              icon: const Icon(Icons.check, size: 16),
                              label: const Text('Authorize & Collect', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              onPressed: () {
                                setState(() {
                                  _consent[sec.id] = true;
                                });
                              },
                            ),
                            const SizedBox(width: 10),
                            OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                              child: const Text('Decline to Answer', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                              onPressed: () {
                                _markSectionExplicitState(sec.id, 'declined');
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  // Render all structured fields for this section
                  if (secState == 'unknown' || secState == 'notapplicable' || secState == 'declined') ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.scaffoldBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle_outline, size: 16, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Module explicitly recorded as ${secState.toUpperCase()}. No further details required.',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                            ),
                          ),
                          TextButton(
                            child: const Text('Edit Details', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                            onPressed: () {
                              setState(() {
                                final cur = _answers[sec.id] is Map ? Map<String, dynamic>.from(_answers[sec.id]) : <String, dynamic>{};
                                cur['state'] = 'completed';
                                _answers[sec.id] = cur;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    // Structured Fields
                    ...fields.map((field) {
                      // Check conditional visibility
                      if (field.conditionalParentId != null) {
                        final parentVal = _extractFieldValue(fieldsMap[field.conditionalParentId])?.toLowerCase();
                        if (parentVal != field.conditionalValue.toString().toLowerCase()) {
                          return const SizedBox.shrink();
                        }
                      }

                      final error = _validationErrors['${sec.id}.${field.fieldId}'];

                      return ClinicalFieldRenderer(
                        key: ValueKey('${sec.id}_${field.fieldId}'),
                        field: field,
                        initialValue: fieldsMap[field.fieldId],
                        errorMessage: error,
                        memberDob: widget.member.dateOfBirth,
                        onChanged: (val) {
                          _handleFieldChanged(sec.id, field.fieldId, val);
                        },
                      );
                    }),
                  ],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
