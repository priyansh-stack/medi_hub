import '../../data/models/clinical_plan_model.dart';
import '../../data/models/profile_completion_model.dart';
import 'clinical_catalog.dart';
import 'clinical_field_definition.dart';
import 'clinical_guidelines.dart';

enum AgeBand {
  pediatric, // < 12 years
  adolescent, // 12 - 17 years
  adult, // 18 - 64 years
  geriatric, // >= 65 years
}

enum ClinicalDataState {
  known,
  unknown,
  notApplicable,
  declined,
  notYetCollected,
  completed,
}

class ClinicalSectionDefinition {
  final String id;
  final String title;
  final String subtitle;
  final int tier;
  final bool isRequired;
  final bool isGated; // Requires explicit consent
  final List<AgeBand> applicableAgeBands;
  final List<String> applicableGenders; // empty = all
  final List<String> fieldKeys;

  const ClinicalSectionDefinition({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.tier,
    this.isRequired = false,
    this.isGated = false,
    this.applicableAgeBands = const [
      AgeBand.pediatric,
      AgeBand.adolescent,
      AgeBand.adult,
      AgeBand.geriatric,
    ],
    this.applicableGenders = const [],
    this.fieldKeys = const [],
  });

  bool isApplicable(AgeBand band, String gender) {
    if (!applicableAgeBands.contains(band)) return false;
    if (applicableGenders.isNotEmpty) {
      final normalized = gender.trim().toLowerCase();
      final matches = applicableGenders.any((g) => g.toLowerCase() == normalized);
      if (!matches) return false;
    }
    return true;
  }
}

class ClinicalEngine {
  static const String engineVersion = 'v1.5.0';

  // Master catalog of all clinical section definitions across 4 tiers
  static const List<ClinicalSectionDefinition> allSections = [
    // ================= TIER 1: SAFETY-CRITICAL =================
    ClinicalSectionDefinition(
      id: 't1_blood_group',
      title: 'Blood Group & Rh Factor',
      subtitle: 'ABO typing, Rh factor, and transfusion compatibility requirements',
      tier: 1,
      isRequired: true,
      fieldKeys: ['bloodGroup', 'rhFactor', 'verificationStatus'],
    ),
    ClinicalSectionDefinition(
      id: 't1_emergency_contacts',
      title: 'Emergency Contacts',
      subtitle: 'Primary and secondary contacts for critical notifications',
      tier: 1,
      isRequired: true,
      fieldKeys: ['contact1Name', 'contact1Relationship', 'contact1Phone', 'contact1Priority', 'contact1Details'],
    ),
    ClinicalSectionDefinition(
      id: 't1_critical_allergies',
      title: 'Life-Threatening Allergies',
      subtitle: 'Anaphylactic risks: penicillin, latex, peanuts, bee venom',
      tier: 1,
      isRequired: true,
      fieldKeys: ['recordState', 'allergyCategory', 'allergenName', 'allergyReaction', 'allergySeverity', 'dateIdentified', 'allergyDetails'],
    ),
    ClinicalSectionDefinition(
      id: 't1_critical_medications',
      title: 'Critical Medications',
      subtitle: 'High-risk medications: insulin, anticoagulants, antiarrhythmics, epinephrine',
      tier: 1,
      isRequired: true,
      fieldKeys: ['recordState', 'medicationName', 'strength', 'dosageForm', 'prescribedDose', 'route', 'frequency', 'startDate', 'endDate', 'prescriberDetails', 'medicationStatus'],
    ),
    ClinicalSectionDefinition(
      id: 't1_critical_conditions',
      title: 'Critical Medical Conditions',
      subtitle: 'High-acuity conditions: Type 1 Diabetes, Epilepsy, Unstable Angina, Severe Asthma',
      tier: 1,
      isRequired: true,
      fieldKeys: ['recordState', 'conditionName', 'dateDiagnosed', 'conditionStatus', 'severity', 'conditionDetails'],
    ),
    ClinicalSectionDefinition(
      id: 't1_implanted_devices',
      title: 'Implanted Devices & Prosthetics',
      subtitle: 'Pacemakers, ICDs, stents, insulin pumps, VP shunts, metal implants',
      tier: 1,
      isRequired: false,
      fieldKeys: ['recordState', 'deviceCategory', 'deviceName', 'implantationDate', 'manufacturerModel', 'mriSafetyStatus', 'additionalNotes'],
    ),
    ClinicalSectionDefinition(
      id: 't1_emergency_instructions',
      title: 'Emergency Response Protocols',
      subtitle: 'Special paramedic instructions, MedicAlert identifiers, DNR preference if applicable',
      tier: 1,
      isRequired: false,
      fieldKeys: ['specialInstructions', 'medicAlertId'],
    ),
    ClinicalSectionDefinition(
      id: 't1_organ_donor',
      title: 'Organ Donor Status',
      subtitle: 'Registered organ and tissue donor preference',
      tier: 1,
      isRequired: false,
      applicableAgeBands: [AgeBand.adolescent, AgeBand.adult, AgeBand.geriatric],
      fieldKeys: ['organDonorStatus'],
    ),

    // ================= TIER 2: CORE HEALTH RECORD =================
    ClinicalSectionDefinition(
      id: 't2_diagnoses',
      title: 'Diagnoses & Chronic Conditions',
      subtitle: 'Active chronic conditions (hypertension, thyroid, arthritis, etc.)',
      tier: 2,
      isRequired: true,
      fieldKeys: ['recordState', 'conditionName', 'dateOfOnset', 'conditionStatus', 'treatingPhysician', 'additionalNotes'],
    ),
    ClinicalSectionDefinition(
      id: 't2_general_allergies',
      title: 'General Allergies & Adverse Reactions',
      subtitle: 'Drug intolerances, food allergies, environmental/seasonal allergies',
      tier: 2,
      isRequired: true,
      fieldKeys: ['recordState', 'allergyCategory', 'allergenName', 'reaction', 'severity', 'additionalNotes'],
    ),
    ClinicalSectionDefinition(
      id: 't2_medications',
      title: 'Current & Past Medications',
      subtitle: 'Prescriptions, over-the-counter supplements, dosages and schedules',
      tier: 2,
      isRequired: true,
      fieldKeys: ['recordState', 'medicationName', 'strength', 'dosageForm', 'prescribedDose', 'frequency', 'prescriberDetails', 'medicationStatus'],
    ),
    ClinicalSectionDefinition(
      id: 't2_immunizations',
      title: 'Immunizations & Vaccinations',
      subtitle: 'Age-appropriate immunization history and boosters',
      tier: 2,
      isRequired: true,
      fieldKeys: ['recordState', 'vaccineName', 'doseNumber', 'vaccinationDate', 'administeringFacility', 'batchLotNumber'],
    ),
    ClinicalSectionDefinition(
      id: 't2_surgeries',
      title: 'Surgeries & Medical Procedures',
      subtitle: 'Prior operations, major trauma, hospitalizations',
      tier: 2,
      isRequired: false,
      fieldKeys: ['recordState', 'procedureName', 'surgeryDate', 'hospitalSurgeon', 'indication', 'complicationsOrNotes'],
    ),
    ClinicalSectionDefinition(
      id: 't2_vitals',
      title: 'Baseline Vitals & Biometrics',
      subtitle: 'Blood pressure, resting heart rate, height, weight, BMI, blood glucose',
      tier: 2,
      isRequired: true,
      fieldKeys: ['systolicBp', 'diastolicBp', 'heartRate', 'heightCm', 'weightKg', 'bodyMassIndex', 'temperatureF', 'oxygenSaturation', 'fastingBloodGlucose', 'measurementNotes'],
    ),
    ClinicalSectionDefinition(
      id: 't2_screenings',
      title: 'Preventive Health Screenings',
      subtitle: 'Vision, dental, lipid panel, glucose, age-specific screenings',
      tier: 2,
      isRequired: false,
      fieldKeys: ['screeningType', 'completionDate', 'resultSummary', 'nextDueDate', 'screeningNotes'],
    ),
    ClinicalSectionDefinition(
      id: 't2_care_team',
      title: 'Primary Care Team & Facilities',
      subtitle: 'Family physician, specialists, preferred hospital/clinic',
      tier: 2,
      isRequired: false,
      fieldKeys: ['primaryPhysician', 'specialty', 'clinicHospital', 'contactPhone', 'email'],
    ),
    ClinicalSectionDefinition(
      id: 't2_insurance',
      title: 'Health Insurance Details',
      subtitle: 'Health insurance provider, policy ID, validity coverage',
      tier: 2,
      isRequired: false,
      fieldKeys: ['insuranceProvider', 'policyNumber', 'policyHolder', 'coverageExpiry', 'sumInsured', 'networkHospitalStatus'],
    ),

    // ================= TIER 3: LONGITUDINAL & LIFE-STAGE =================
    ClinicalSectionDefinition(
      id: 't3_family_history',
      title: 'Family Medical History',
      subtitle: 'Cardiovascular disease, diabetes, cancer, stroke in 1st-degree relatives',
      tier: 3,
      isRequired: true,
      fieldKeys: ['condition', 'relative', 'ageAtDiagnosis', 'notes'],
    ),
    ClinicalSectionDefinition(
      id: 't3_lifestyle',
      title: 'Lifestyle & Wellbeing',
      subtitle: 'Dietary habits, physical activity frequency, sleep duration',
      tier: 3,
      isRequired: false,
      applicableAgeBands: [AgeBand.adolescent, AgeBand.adult, AgeBand.geriatric],
      fieldKeys: ['dietType', 'physicalActivityLevel', 'sleepHours', 'waterIntakeLiters', 'lifestyleNotes'],
    ),
    ClinicalSectionDefinition(
      id: 't3_social_determinants',
      title: 'Social & Environmental Determinants',
      subtitle: 'Living conditions, mobility accessibility, home safety, support network',
      tier: 3,
      isRequired: false,
      fieldKeys: ['livingEnvironment', 'supportNetwork', 'mobilityAccessibility', 'socialNotes'],
    ),
    ClinicalSectionDefinition(
      id: 't3_pediatric_milestones',
      title: 'Birth & Developmental Milestones',
      subtitle: 'Birth weight, gestational age, motor/speech milestones, neonatal care',
      tier: 3,
      isRequired: true,
      applicableAgeBands: [AgeBand.pediatric],
      fieldKeys: ['birthWeight', 'gestationalWeeks', 'deliveryType', 'developmentalStatus', 'pediatricNotes'],
    ),
    ClinicalSectionDefinition(
      id: 't3_adolescent_growth',
      title: 'Adolescent Development & School Health',
      subtitle: 'Growth velocity, posture/scoliosis checks, school physicals',
      tier: 3,
      isRequired: false,
      applicableAgeBands: [AgeBand.adolescent],
      fieldKeys: ['growthProgression', 'postureScoliosisScreening', 'schoolActivityNotes'],
    ),
    ClinicalSectionDefinition(
      id: 't3_reproductive_health',
      title: 'Reproductive Life-Stage Details',
      subtitle: 'Pregnancy history, maternal health, or menopausal stages (Consented)',
      tier: 3,
      isRequired: false,
      isGated: true,
      applicableAgeBands: [AgeBand.adult],
      applicableGenders: ['Female'],
      fieldKeys: ['menarcheAge', 'cycleRegularity', 'lastMenstrualPeriod', 'gravidaPara', 'reproductiveNotes'],
    ),
    ClinicalSectionDefinition(
      id: 't3_geriatric_assessment',
      title: 'Geriatric Fall Risk & Mobility',
      subtitle: 'Balance assessment, assistive devices, ADL independence',
      tier: 3,
      isRequired: true,
      applicableAgeBands: [AgeBand.geriatric],
      fieldKeys: ['fallRiskLevel', 'fallCountLast12Months', 'assistiveDevice', 'adlIndependence', 'geriatricNotes'],
    ),
    ClinicalSectionDefinition(
      id: 't3_advance_care',
      title: 'Advance Care Directives',
      subtitle: 'Living will, healthcare proxy, durable power of attorney',
      tier: 3,
      isRequired: false,
      applicableAgeBands: [AgeBand.adult, AgeBand.geriatric],
      fieldKeys: ['hasLivingWill', 'proxyContactName', 'proxyContactPhone', 'resuscitationPreference'],
    ),

    // ================= TIER 4: ADVANCED & CONTEXTUAL =================
    ClinicalSectionDefinition(
      id: 't4_mental_health',
      title: 'Mental Health & Emotional Wellbeing',
      subtitle: 'Stress levels, mood screening, anxiety/depression history (Consent-Gated)',
      tier: 4,
      isRequired: false,
      isGated: true,
      applicableAgeBands: [AgeBand.adolescent, AgeBand.adult, AgeBand.geriatric],
      fieldKeys: ['stressLevel', 'phq2DepressionScreening', 'gad2AnxietyScreening', 'priorSupport', 'mentalHealthNotes'],
    ),
    ClinicalSectionDefinition(
      id: 't4_substance_use',
      title: 'Substance & Tobacco Use',
      subtitle: 'Nicotine/tobacco, alcohol consumption, substance history (Consent-Gated)',
      tier: 4,
      isRequired: false,
      isGated: true,
      applicableAgeBands: [AgeBand.adult, AgeBand.geriatric],
      fieldKeys: ['tobaccoStatus', 'alcoholFrequency', 'otherSubstances', 'substanceNotes'],
    ),
    ClinicalSectionDefinition(
      id: 't4_sensory_dental',
      title: 'Sensory & Oral Health',
      subtitle: 'Vision (glasses/contacts), hearing aids, dental appliances',
      tier: 4,
      isRequired: false,
      fieldKeys: ['correctiveLenses', 'hearingAids', 'dentalHealth', 'sensoryNotes'],
    ),
    ClinicalSectionDefinition(
      id: 't4_infectious_travel',
      title: 'Infectious Diseases & Travel Exposure',
      subtitle: 'Endemic disease exposure, travel prophylaxis, tuberculosis screening',
      tier: 4,
      isRequired: false,
      fieldKeys: ['tuberculosisScreening', 'hepatitisScreening', 'recentEndemicTravel', 'travelNotes'],
    ),
    ClinicalSectionDefinition(
      id: 't4_wellness_goals',
      title: 'Personal Wellness & Longevity Goals',
      subtitle: 'Target fitness goals, weight targets, stress-reduction plans',
      tier: 4,
      isRequired: false,
      fieldKeys: ['primaryGoal', 'dailyStepsTarget', 'actionPlanNotes'],
    ),
    ClinicalSectionDefinition(
      id: 't4_genetics_precision',
      title: 'Genetics & Precision Health',
      subtitle: 'Carrier screening results, known genetic markers, hereditary syndromes',
      tier: 4,
      isRequired: false,
      fieldKeys: ['geneticTestingDone', 'testType', 'resultsSummary'],
    ),
    ClinicalSectionDefinition(
      id: 't4_clinical_research',
      title: 'Clinical Research Preferences',
      subtitle: 'Willingness to participate in observational health studies or clinical trials',
      tier: 4,
      isRequired: false,
      applicableAgeBands: [AgeBand.adult, AgeBand.geriatric],
      fieldKeys: ['researchConsent', 'preferredAreas'],
    ),
  ];

  /// Determine age band deterministically from date of birth
  static AgeBand determineAgeBand(DateTime? dob) {
    if (dob == null) return AgeBand.adult;
    final now = DateTime.now();
    int age = now.year - dob.year;
    if (now.month < dob.month || (now.month == dob.month && now.day < dob.day)) {
      age--;
    }
    if (age < 12) return AgeBand.pediatric;
    if (age < 18) return AgeBand.adolescent;
    if (age < 65) return AgeBand.adult;
    return AgeBand.geriatric;
  }

  /// Generate deterministic collection plan for a specific member
  static ClinicalCollectionPlanModel generatePlan({
    required String memberId,
    required String householdId,
    required DateTime? dateOfBirth,
    required String gender,
    required String relationship,
    required String managementType,
  }) {
    final ageBand = determineAgeBand(dateOfBirth);

    final requiredFields = <String>[];
    final onboardingFields = <String>[];
    final progressiveFields = <String>[];
    final eventTriggeredFields = <String>[];
    final optionalFields = <String>[];
    final gatedFields = <String>[];
    final excludedFields = <String>[];

    for (final section in allSections) {
      final applicable = section.isApplicable(ageBand, gender);
      if (!applicable) {
        excludedFields.add(section.id);
        continue;
      }

      if (section.isGated) {
        gatedFields.add(section.id);
      }

      if (section.tier == 1) {
        onboardingFields.add(section.id);
      } else {
        progressiveFields.add(section.id);
      }

      if (section.isRequired) {
        requiredFields.add(section.id);
      } else {
        optionalFields.add(section.id);
      }
    }

    final hashInput = '$memberId-$householdId-${ageBand.name}-$gender-$engineVersion';
    final planHash = hashInput.hashCode.abs().toRadixString(16).padLeft(8, '0');

    return ClinicalCollectionPlanModel(
      planId: 'plan_${memberId}_${planHash.substring(0, 8)}',
      memberId: memberId,
      householdId: householdId,
      ageBand: ageBand.name,
      rulesetVersions: engineVersion,
      memberContextVersion: 1,
      requiredFields: requiredFields,
      onboardingFields: onboardingFields,
      progressiveFields: progressiveFields,
      eventTriggeredFields: eventTriggeredFields,
      optionalFields: optionalFields,
      gatedFields: gatedFields,
      excludedFields: excludedFields,
      generatedAt: DateTime.now(),
      planHash: planHash,
    );
  }

  /// Returns applicable sections for a given tier and member plan
  static List<ClinicalSectionDefinition> getSectionsForTier({
    required int tier,
    required ClinicalCollectionPlanModel plan,
  }) {
    return allSections.where((s) {
      if (s.tier != tier) return false;
      if (plan.excludedFields.contains(s.id)) return false;
      return true;
    }).toList();
  }

  // ================= DYNAMIC FIELD DEFINITIONS ENGINE =================

  /// Return all structured, clinically defined fields for a given section
  static List<ClinicalFieldDefinition> getFieldsForSection(
    String sectionId, {
    AgeBand ageBand = AgeBand.adult,
    String gender = 'Other',
  }) {
    switch (sectionId) {
      // --- TIER 1: SAFETY-CRITICAL ---
      case 't1_blood_group':
        return [
          ClinicalFieldDefinition(
            fieldId: 'bloodGroup',
            label: 'ABO Blood Group',
            description: 'Select verified ABO red blood cell surface antigen phenotype',
            healthTier: 1,
            moduleId: sectionId,
            inputType: ClinicalInputType.singleChoiceDropdown,
            options: ClinicalCatalog.bloodGroupsABO,
            requiredState: true,
            guidelineReference: ClinicalGuidelinesCatalog.getGuidelineByRuleId('GL-T1-ABO-01'),
            displayOrder: 1,
          ),
          ClinicalFieldDefinition(
            fieldId: 'rhFactor',
            label: 'Rh (Rhesus D) Factor',
            description: 'Rhesus D antigen status (+ or -) essential for transfusion compatibility',
            healthTier: 1,
            moduleId: sectionId,
            inputType: ClinicalInputType.singleChoiceRadio,
            options: ClinicalCatalog.rhFactors,
            requiredState: true,
            guidelineReference: ClinicalGuidelinesCatalog.getGuidelineByRuleId('GL-T1-RH-02'),
            displayOrder: 2,
          ),
          ClinicalFieldDefinition(
            fieldId: 'verificationStatus',
            label: 'Verification Level',
            description: 'Documentation status confirming blood typing reliability',
            healthTier: 1,
            moduleId: sectionId,
            inputType: ClinicalInputType.singleChoiceDropdown,
            options: ClinicalCatalog.bloodVerificationStatuses,
            requiredState: false,
            displayOrder: 3,
          ),
        ];

      case 't1_emergency_contacts':
        return [
          const ClinicalFieldDefinition(
            fieldId: 'contact1Name',
            label: 'Primary Emergency Contact Name',
            description: 'Full legal name of the person authorized to make emergency decisions',
            healthTier: 1,
            moduleId: 't1_emergency_contacts',
            inputType: ClinicalInputType.multilineText,
            characterLimit: 100,
            requiredState: true,
            displayOrder: 1,
          ),
          const ClinicalFieldDefinition(
            fieldId: 'contact1Relationship',
            label: 'Relationship to Member',
            description: 'Kinship or formal authority relationship',
            healthTier: 1,
            moduleId: 't1_emergency_contacts',
            inputType: ClinicalInputType.singleChoiceDropdown,
            options: ClinicalCatalog.contactRelationships,
            requiredState: true,
            displayOrder: 2,
          ),
          const ClinicalFieldDefinition(
            fieldId: 'contact1Phone',
            label: 'Emergency Phone Number',
            description: 'Country-aware primary phone number with country code (e.g. +91 9876543210)',
            healthTier: 1,
            moduleId: 't1_emergency_contacts',
            inputType: ClinicalInputType.multilineText,
            requiredState: true,
            displayOrder: 3,
            validationRules: [
              ClinicalValidationRule(
                ruleId: 'VAL-PHONE-01',
                errorMessage: 'Enter a valid country-aware phone number (7-15 digits, e.g. +91 9876543210)',
              ),
            ],
          ),
          const ClinicalFieldDefinition(
            fieldId: 'contact1Priority',
            label: 'Contact Notification Priority',
            description: 'Emergency routing priority',
            healthTier: 1,
            moduleId: 't1_emergency_contacts',
            inputType: ClinicalInputType.singleChoiceRadio,
            options: [
              ClinicalFieldOption(id: 'Primary', label: 'Primary Contact (1st Call)'),
              ClinicalFieldOption(id: 'Secondary', label: 'Secondary Contact (Backup)'),
            ],
            displayOrder: 4,
          ),
          const ClinicalFieldDefinition(
            fieldId: 'contact1Details',
            label: 'Additional Contact Details / Address',
            description: 'Alternative numbers, email, or physical home address note',
            healthTier: 1,
            moduleId: 't1_emergency_contacts',
            inputType: ClinicalInputType.multilineText,
            characterLimit: 250,
            displayOrder: 5,
          ),
        ];

      case 't1_critical_allergies':
        return [
          const ClinicalFieldDefinition(
            fieldId: 'recordState',
            label: 'Critical Allergy Status',
            description: 'Indicate whether member has known life-threatening/anaphylactic allergies',
            healthTier: 1,
            moduleId: 't1_critical_allergies',
            inputType: ClinicalInputType.singleChoiceRadio,
            options: ClinicalCatalog.repeatingRecordChoices,
            requiredState: true,
            displayOrder: 1,
          ),
          ClinicalFieldDefinition(
            fieldId: 'allergyCategory',
            label: 'Allergy Category',
            description: 'Clinical classification of the allergen',
            healthTier: 1,
            moduleId: 't1_critical_allergies',
            inputType: ClinicalInputType.singleChoiceDropdown,
            options: ClinicalCatalog.allergyCategories,
            conditionalParentId: 'recordState',
            conditionalValue: 'yes',
            guidelineReference: ClinicalGuidelinesCatalog.getGuidelineByRuleId('GL-T1-ALL-03'),
            displayOrder: 2,
          ),
          const ClinicalFieldDefinition(
            fieldId: 'allergenName',
            label: 'Allergen Name',
            description: 'Searchable substance that triggers anaphylactic / severe reaction',
            healthTier: 1,
            moduleId: 't1_critical_allergies',
            inputType: ClinicalInputType.allergySelector,
            options: ClinicalCatalog.allergens,
            hasOtherOption: true,
            conditionalParentId: 'recordState',
            conditionalValue: 'yes',
            displayOrder: 3,
          ),
          const ClinicalFieldDefinition(
            fieldId: 'allergyReaction',
            label: 'Observed Clinical Reaction',
            description: 'Acute clinical symptoms experienced on exposure',
            healthTier: 1,
            moduleId: 't1_critical_allergies',
            inputType: ClinicalInputType.singleChoiceDropdown,
            options: ClinicalCatalog.allergyReactions,
            conditionalParentId: 'recordState',
            conditionalValue: 'yes',
            displayOrder: 4,
          ),
          const ClinicalFieldDefinition(
            fieldId: 'allergySeverity',
            label: 'Reaction Severity',
            description: 'Acuity level of past reaction episodes',
            healthTier: 1,
            moduleId: 't1_critical_allergies',
            inputType: ClinicalInputType.severityDropdown,
            options: ClinicalCatalog.severities,
            conditionalParentId: 'recordState',
            conditionalValue: 'yes',
            displayOrder: 5,
          ),
          const ClinicalFieldDefinition(
            fieldId: 'dateIdentified',
            label: 'Date First Identified (if known)',
            description: 'Approximate past date or encounter when allergy was diagnosed',
            healthTier: 1,
            moduleId: 't1_critical_allergies',
            inputType: ClinicalInputType.datePicker,
            validationRules: [
              ClinicalValidationRule(
                ruleId: 'VAL-DATE-PAST',
                allowFutureDates: false,
                errorMessage: 'Date identified cannot be in the future',
              ),
            ],
            conditionalParentId: 'recordState',
            conditionalValue: 'yes',
            displayOrder: 6,
          ),
          const ClinicalFieldDefinition(
            fieldId: 'allergyDetails',
            label: 'Additional Reaction Details',
            description: 'Specific emergency instructions, prior EpiPen use, or hospitalizations',
            healthTier: 1,
            moduleId: 't1_critical_allergies',
            inputType: ClinicalInputType.multilineText,
            characterLimit: 400,
            conditionalParentId: 'recordState',
            conditionalValue: 'yes',
            displayOrder: 7,
          ),
        ];

      case 't1_critical_medications':
        return [
          const ClinicalFieldDefinition(
            fieldId: 'recordState',
            label: 'Critical Medications Status',
            description: 'Is member currently prescribed high-alert or emergency medications (e.g. insulin, blood thinners)?',
            healthTier: 1,
            moduleId: 't1_critical_medications',
            inputType: ClinicalInputType.singleChoiceRadio,
            options: ClinicalCatalog.repeatingRecordChoices,
            requiredState: true,
            displayOrder: 1,
          ),
          ClinicalFieldDefinition(
            fieldId: 'medicationName',
            label: 'Medication Name',
            description: 'Generic / brand pharmaceutical name (WHO Essential Medicines & NLEM)',
            healthTier: 1,
            moduleId: 't1_critical_medications',
            inputType: ClinicalInputType.medicationSelector,
            options: ClinicalCatalog.criticalMedications,
            hasOtherOption: true,
            guidelineReference: ClinicalGuidelinesCatalog.getGuidelineByRuleId('GL-T1-MED-04'),
            conditionalParentId: 'recordState',
            conditionalValue: 'yes',
            displayOrder: 2,
          ),
          const ClinicalFieldDefinition(
            fieldId: 'strength',
            label: 'Strength with Unit',
            description: 'Concentration or mass per unit (e.g. 500 mg, 100 IU/mL, 10 mg)',
            healthTier: 1,
            moduleId: 't1_critical_medications',
            inputType: ClinicalInputType.multilineText,
            characterLimit: 50,
            conditionalParentId: 'recordState',
            conditionalValue: 'yes',
            displayOrder: 3,
          ),
          const ClinicalFieldDefinition(
            fieldId: 'dosageForm',
            label: 'Dosage Form',
            description: 'Physical presentation of pharmaceutical formulation',
            healthTier: 1,
            moduleId: 't1_critical_medications',
            inputType: ClinicalInputType.singleChoiceDropdown,
            options: ClinicalCatalog.dosageForms,
            conditionalParentId: 'recordState',
            conditionalValue: 'yes',
            displayOrder: 4,
          ),
          const ClinicalFieldDefinition(
            fieldId: 'prescribedDose',
            label: 'Prescribed Dose Quantity',
            description: 'Dose per administration (e.g. 1 tablet, 2 puffs, 10 units)',
            healthTier: 1,
            moduleId: 't1_critical_medications',
            inputType: ClinicalInputType.multilineText,
            characterLimit: 60,
            conditionalParentId: 'recordState',
            conditionalValue: 'yes',
            displayOrder: 5,
          ),
          const ClinicalFieldDefinition(
            fieldId: 'route',
            label: 'Administration Route',
            description: 'Anatomical path for medication delivery',
            healthTier: 1,
            moduleId: 't1_critical_medications',
            inputType: ClinicalInputType.singleChoiceDropdown,
            options: ClinicalCatalog.medicationRoutes,
            conditionalParentId: 'recordState',
            conditionalValue: 'yes',
            displayOrder: 6,
          ),
          const ClinicalFieldDefinition(
            fieldId: 'frequency',
            label: 'Dosing Frequency',
            description: 'Prescription timing schedule',
            healthTier: 1,
            moduleId: 't1_critical_medications',
            inputType: ClinicalInputType.singleChoiceDropdown,
            options: ClinicalCatalog.medicationFrequencies,
            conditionalParentId: 'recordState',
            conditionalValue: 'yes',
            displayOrder: 7,
          ),
          const ClinicalFieldDefinition(
            fieldId: 'startDate',
            label: 'Prescription Start Date',
            description: 'Date treatment commenced',
            healthTier: 1,
            moduleId: 't1_critical_medications',
            inputType: ClinicalInputType.datePicker,
            conditionalParentId: 'recordState',
            conditionalValue: 'yes',
            displayOrder: 8,
          ),
          const ClinicalFieldDefinition(
            fieldId: 'endDate',
            label: 'End / Review Date (if applicable)',
            description: 'Expected completion date for fixed courses',
            healthTier: 1,
            moduleId: 't1_critical_medications',
            inputType: ClinicalInputType.datePicker,
            conditionalParentId: 'recordState',
            conditionalValue: 'yes',
            displayOrder: 9,
          ),
          const ClinicalFieldDefinition(
            fieldId: 'prescriberDetails',
            label: 'Prescriber Details (if known)',
            description: 'Name of prescribing physician or clinic',
            healthTier: 1,
            moduleId: 't1_critical_medications',
            inputType: ClinicalInputType.multilineText,
            characterLimit: 120,
            conditionalParentId: 'recordState',
            conditionalValue: 'yes',
            displayOrder: 10,
          ),
          const ClinicalFieldDefinition(
            fieldId: 'medicationStatus',
            label: 'Medication Status',
            description: 'Active ongoing therapy versus past discontinuation',
            healthTier: 1,
            moduleId: 't1_critical_medications',
            inputType: ClinicalInputType.singleChoiceRadio,
            options: [
              ClinicalFieldOption(id: 'active', label: 'Active Current Prescription'),
              ClinicalFieldOption(id: 'discontinued', label: 'Historical / Discontinued'),
              ClinicalFieldOption(id: 'on_hold', label: 'Temporarily On Hold'),
            ],
            conditionalParentId: 'recordState',
            conditionalValue: 'yes',
            displayOrder: 11,
          ),
        ];

      case 't1_critical_conditions':
        return [
          const ClinicalFieldDefinition(
            fieldId: 'recordState',
            label: 'Critical Condition Status',
            description: 'Does the member have any high-acuity medical condition (e.g. Type 1 diabetes, epilepsy, unstable heart condition)?',
            healthTier: 1,
            moduleId: 't1_critical_conditions',
            inputType: ClinicalInputType.singleChoiceRadio,
            options: ClinicalCatalog.repeatingRecordChoices,
            requiredState: true,
            displayOrder: 1,
          ),
          const ClinicalFieldDefinition(
            fieldId: 'conditionName',
            label: 'Condition / Diagnosis',
            description: 'ICD-10 aligned critical clinical condition',
            healthTier: 1,
            moduleId: 't1_critical_conditions',
            inputType: ClinicalInputType.clinicalConditionSelector,
            options: ClinicalCatalog.criticalConditions,
            hasOtherOption: true,
            conditionalParentId: 'recordState',
            conditionalValue: 'yes',
            displayOrder: 2,
          ),
          const ClinicalFieldDefinition(
            fieldId: 'dateDiagnosed',
            label: 'Date Diagnosed (if known)',
            description: 'Past date of initial formal clinical diagnosis',
            healthTier: 1,
            moduleId: 't1_critical_conditions',
            inputType: ClinicalInputType.datePicker,
            validationRules: [
              ClinicalValidationRule(
                ruleId: 'VAL-DIAG-PAST',
                allowFutureDates: false,
                errorMessage: 'Diagnosis date cannot be in the future',
              ),
            ],
            conditionalParentId: 'recordState',
            conditionalValue: 'yes',
            displayOrder: 3,
          ),
          const ClinicalFieldDefinition(
            fieldId: 'conditionStatus',
            label: 'Clinical Acuity Status',
            description: 'Current disease activity',
            healthTier: 1,
            moduleId: 't1_critical_conditions',
            inputType: ClinicalInputType.singleChoiceRadio,
            options: [
              ClinicalFieldOption(id: 'active', label: 'Active / Under Treatment'),
              ClinicalFieldOption(id: 'controlled', label: 'Well-Controlled with Therapy'),
              ClinicalFieldOption(id: 'remission', label: 'In Clinical Remission'),
              ClinicalFieldOption(id: 'resolved', label: 'Resolved / Past Event'),
            ],
            conditionalParentId: 'recordState',
            conditionalValue: 'yes',
            displayOrder: 4,
          ),
          const ClinicalFieldDefinition(
            fieldId: 'severity',
            label: 'Severity Level',
            description: 'Clinical severity classification',
            healthTier: 1,
            moduleId: 't1_critical_conditions',
            inputType: ClinicalInputType.severityDropdown,
            options: ClinicalCatalog.severities,
            conditionalParentId: 'recordState',
            conditionalValue: 'yes',
            displayOrder: 5,
          ),
          const ClinicalFieldDefinition(
            fieldId: 'conditionDetails',
            label: 'Clinical Summary / Emergency Flags',
            description: 'Specific emergency guidance (e.g. seizure protocol, diabetic glucagon emergency protocol)',
            healthTier: 1,
            moduleId: 't1_critical_conditions',
            inputType: ClinicalInputType.multilineText,
            characterLimit: 400,
            conditionalParentId: 'recordState',
            conditionalValue: 'yes',
            displayOrder: 6,
          ),
        ];

      case 't1_implanted_devices':
        return [
          const ClinicalFieldDefinition(
            fieldId: 'recordState',
            label: 'Implanted Device Status',
            description: 'Does the member have an implanted electronic or metallic medical device (e.g. pacemaker, stent)?',
            healthTier: 1,
            moduleId: 't1_implanted_devices',
            inputType: ClinicalInputType.singleChoiceRadio,
            options: ClinicalCatalog.repeatingRecordChoices,
            requiredState: false,
            displayOrder: 1,
          ),
          ClinicalFieldDefinition(
            fieldId: 'deviceCategory',
            label: 'Device Category',
            description: 'Type of implanted medical hardware',
            healthTier: 1,
            moduleId: 't1_implanted_devices',
            inputType: ClinicalInputType.singleChoiceDropdown,
            options: ClinicalCatalog.deviceCategories,
            guidelineReference: ClinicalGuidelinesCatalog.getGuidelineByRuleId('GL-T1-DEV-05'),
            conditionalParentId: 'recordState',
            conditionalValue: 'yes',
            displayOrder: 2,
          ),
          const ClinicalFieldDefinition(
            fieldId: 'deviceName',
            label: 'Device / Procedure Name',
            description: 'Specific device title (e.g. Dual-chamber Pacemaker, Drug-eluting Stent)',
            healthTier: 1,
            moduleId: 't1_implanted_devices',
            inputType: ClinicalInputType.multilineText,
            characterLimit: 120,
            conditionalParentId: 'recordState',
            conditionalValue: 'yes',
            displayOrder: 3,
          ),
          const ClinicalFieldDefinition(
            fieldId: 'implantationDate',
            label: 'Implantation Date',
            description: 'Date surgical placement took place',
            healthTier: 1,
            moduleId: 't1_implanted_devices',
            inputType: ClinicalInputType.datePicker,
            validationRules: [
              ClinicalValidationRule(
                ruleId: 'VAL-IMP-DATE',
                allowFutureDates: false,
                errorMessage: 'Implantation date cannot be in the future',
              ),
            ],
            conditionalParentId: 'recordState',
            conditionalValue: 'yes',
            displayOrder: 4,
          ),
          const ClinicalFieldDefinition(
            fieldId: 'manufacturerModel',
            label: 'Manufacturer & Model (if known)',
            description: 'Device vendor, model name, or serial number for surgical card identification',
            healthTier: 1,
            moduleId: 't1_implanted_devices',
            inputType: ClinicalInputType.multilineText,
            characterLimit: 150,
            conditionalParentId: 'recordState',
            conditionalValue: 'yes',
            displayOrder: 5,
          ),
          const ClinicalFieldDefinition(
            fieldId: 'mriSafetyStatus',
            label: 'MRI Safety Status',
            description: 'Critical safety indicator for magnetic resonance imaging scans',
            healthTier: 1,
            moduleId: 't1_implanted_devices',
            inputType: ClinicalInputType.singleChoiceDropdown,
            options: [
              ClinicalFieldOption(id: 'mri_conditional', label: 'MRI Conditional (Requires scan protocol compliance)'),
              ClinicalFieldOption(id: 'mri_safe', label: 'MRI Safe (Non-magnetic implant)'),
              ClinicalFieldOption(id: 'mri_unsafe', label: 'MRI Unsafe (Strictly contraindicated for MRI scans)'),
              ClinicalFieldOption(id: 'unknown', label: 'Safety Status Unknown (Consult cardiologist/surgeon)'),
            ],
            conditionalParentId: 'recordState',
            conditionalValue: 'yes',
            displayOrder: 6,
          ),
          const ClinicalFieldDefinition(
            fieldId: 'additionalNotes',
            label: 'Additional Information',
            description: 'Hospital where implanted, treating surgeon, replacement battery status',
            healthTier: 1,
            moduleId: 't1_implanted_devices',
            inputType: ClinicalInputType.multilineText,
            characterLimit: 300,
            conditionalParentId: 'recordState',
            conditionalValue: 'yes',
            displayOrder: 7,
          ),
        ];

      case 't1_emergency_instructions':
        return [
          const ClinicalFieldDefinition(
            fieldId: 'specialInstructions',
            label: 'Paramedic / First Responder Instructions',
            description: 'Vital critical notes for emergency resuscitation or triage encounters',
            healthTier: 1,
            moduleId: 't1_emergency_instructions',
            inputType: ClinicalInputType.multilineText,
            characterLimit: 500,
            displayOrder: 1,
          ),
          const ClinicalFieldDefinition(
            fieldId: 'medicAlertId',
            label: 'MedicAlert / National Health Identifier',
            description: 'Registry identification number or wearable bracelet ID',
            healthTier: 1,
            moduleId: 't1_emergency_instructions',
            inputType: ClinicalInputType.multilineText,
            characterLimit: 50,
            displayOrder: 2,
          ),
        ];

      case 't1_organ_donor':
        return [
          const ClinicalFieldDefinition(
            fieldId: 'organDonorStatus',
            label: 'Organ & Tissue Donor Preference',
            description: 'Indicates preference regarding organ and tissue donation after death',
            healthTier: 1,
            moduleId: 't1_organ_donor',
            inputType: ClinicalInputType.singleChoiceRadio,
            options: [
              ClinicalFieldOption(id: 'registered', label: 'Registered Donor (National / State Registry)'),
              ClinicalFieldOption(id: 'willing', label: 'Willing to Donate (Expressed family intent)'),
              ClinicalFieldOption(id: 'not_willing', label: 'Not Willing to Donate'),
              ClinicalFieldOption(id: 'undecided', label: 'Undecided / Discussing with Family'),
            ],
            displayOrder: 1,
          ),
        ];

      // --- TIER 2: CORE HEALTH RECORD ---
      case 't2_diagnoses':
        return [
          const ClinicalFieldDefinition(
            fieldId: 'recordState',
            label: 'Chronic Diagnoses Status',
            description: 'Does the member have any chronic health conditions or ongoing medical diagnoses?',
            healthTier: 2,
            moduleId: 't2_diagnoses',
            inputType: ClinicalInputType.singleChoiceRadio,
            options: ClinicalCatalog.repeatingRecordChoices,
            requiredState: true,
            displayOrder: 1,
          ),
          const ClinicalFieldDefinition(
            fieldId: 'conditionName',
            label: 'Condition / Diagnosis',
            description: 'ICD-10 aligned common chronic medical diagnosis',
            healthTier: 2,
            moduleId: 't2_diagnoses',
            inputType: ClinicalInputType.clinicalConditionSelector,
            options: ClinicalCatalog.coreDiagnoses,
            hasOtherOption: true,
            conditionalParentId: 'recordState',
            conditionalValue: 'yes',
            displayOrder: 2,
          ),
          const ClinicalFieldDefinition(
            fieldId: 'dateOfOnset',
            label: 'Date of Diagnosis / Onset',
            description: 'Past date when condition was first recognized',
            healthTier: 2,
            moduleId: 't2_diagnoses',
            inputType: ClinicalInputType.datePicker,
            validationRules: [
              ClinicalValidationRule(
                ruleId: 'VAL-ONSET-PAST',
                allowFutureDates: false,
                errorMessage: 'Onset date cannot be in the future',
              ),
            ],
            conditionalParentId: 'recordState',
            conditionalValue: 'yes',
            displayOrder: 3,
          ),
          const ClinicalFieldDefinition(
            fieldId: 'conditionStatus',
            label: 'Current Status',
            description: 'Management stage of this diagnosis',
            healthTier: 2,
            moduleId: 't2_diagnoses',
            inputType: ClinicalInputType.singleChoiceRadio,
            options: [
              ClinicalFieldOption(id: 'active', label: 'Active (Ongoing Management)'),
              ClinicalFieldOption(id: 'controlled', label: 'Controlled (Stable on Therapy)'),
              ClinicalFieldOption(id: 'resolved', label: 'Resolved (Past Occurrence)'),
            ],
            conditionalParentId: 'recordState',
            conditionalValue: 'yes',
            displayOrder: 4,
          ),
          const ClinicalFieldDefinition(
            fieldId: 'treatingPhysician',
            label: 'Treating Physician / Hospital',
            description: 'Doctor or healthcare facility supervising this condition',
            healthTier: 2,
            moduleId: 't2_diagnoses',
            inputType: ClinicalInputType.multilineText,
            characterLimit: 120,
            conditionalParentId: 'recordState',
            conditionalValue: 'yes',
            displayOrder: 5,
          ),
          const ClinicalFieldDefinition(
            fieldId: 'additionalNotes',
            label: 'Additional Clinical Notes',
            description: 'Diagnostic criteria, regular medications, or symptom stability',
            healthTier: 2,
            moduleId: 't2_diagnoses',
            inputType: ClinicalInputType.multilineText,
            characterLimit: 300,
            conditionalParentId: 'recordState',
            conditionalValue: 'yes',
            displayOrder: 6,
          ),
        ];

      case 't2_general_allergies':
        return [
          const ClinicalFieldDefinition(
            fieldId: 'recordState',
            label: 'General Allergies Status',
            description: 'Does the member have any mild, seasonal, or environmental allergies?',
            healthTier: 2,
            moduleId: 't2_general_allergies',
            inputType: ClinicalInputType.singleChoiceRadio,
            options: ClinicalCatalog.repeatingRecordChoices,
            requiredState: true,
            displayOrder: 1,
          ),
          const ClinicalFieldDefinition(
            fieldId: 'allergyCategory',
            label: 'Category',
            description: 'Classification of allergen',
            healthTier: 2,
            moduleId: 't2_general_allergies',
            inputType: ClinicalInputType.singleChoiceDropdown,
            options: ClinicalCatalog.allergyCategories,
            conditionalParentId: 'recordState',
            conditionalValue: 'yes',
            displayOrder: 2,
          ),
          const ClinicalFieldDefinition(
            fieldId: 'allergenName',
            label: 'Allergen / Substance',
            description: 'Specific trigger causing mild symptoms or intolerance',
            healthTier: 2,
            moduleId: 't2_general_allergies',
            inputType: ClinicalInputType.allergySelector,
            options: ClinicalCatalog.allergens,
            hasOtherOption: true,
            conditionalParentId: 'recordState',
            conditionalValue: 'yes',
            displayOrder: 3,
          ),
          const ClinicalFieldDefinition(
            fieldId: 'reaction',
            label: 'Reaction Observed',
            description: 'Symptoms experienced upon contact',
            healthTier: 2,
            moduleId: 't2_general_allergies',
            inputType: ClinicalInputType.singleChoiceDropdown,
            options: ClinicalCatalog.allergyReactions,
            conditionalParentId: 'recordState',
            conditionalValue: 'yes',
            displayOrder: 4,
          ),
          const ClinicalFieldDefinition(
            fieldId: 'severity',
            label: 'Severity Level',
            description: 'Clinical grade of severity',
            healthTier: 2,
            moduleId: 't2_general_allergies',
            inputType: ClinicalInputType.severityDropdown,
            options: ClinicalCatalog.severities,
            conditionalParentId: 'recordState',
            conditionalValue: 'yes',
            displayOrder: 5,
          ),
          const ClinicalFieldDefinition(
            fieldId: 'additionalNotes',
            label: 'Management Notes',
            description: 'Antihistamine use, seasonal timing, or avoidance advice',
            healthTier: 2,
            moduleId: 't2_general_allergies',
            inputType: ClinicalInputType.multilineText,
            characterLimit: 250,
            conditionalParentId: 'recordState',
            conditionalValue: 'yes',
            displayOrder: 6,
          ),
        ];

      case 't2_medications':
        return [
          const ClinicalFieldDefinition(
            fieldId: 'recordState',
            label: 'Routine Medications Status',
            description: 'Does the member take routine prescriptions, vitamins, or regular supplements?',
            healthTier: 2,
            moduleId: 't2_medications',
            inputType: ClinicalInputType.singleChoiceRadio,
            options: ClinicalCatalog.repeatingRecordChoices,
            requiredState: true,
            displayOrder: 1,
          ),
          const ClinicalFieldDefinition(
            fieldId: 'medicationName',
            label: 'Medication Name',
            description: 'Brand or generic name',
            healthTier: 2,
            moduleId: 't2_medications',
            inputType: ClinicalInputType.medicationSelector,
            options: ClinicalCatalog.criticalMedications,
            hasOtherOption: true,
            conditionalParentId: 'recordState',
            conditionalValue: 'yes',
            displayOrder: 2,
          ),
          const ClinicalFieldDefinition(
            fieldId: 'strength',
            label: 'Strength (e.g. 500mg, 10mg)',
            description: 'Formulation strength',
            healthTier: 2,
            moduleId: 't2_medications',
            inputType: ClinicalInputType.multilineText,
            characterLimit: 50,
            conditionalParentId: 'recordState',
            conditionalValue: 'yes',
            displayOrder: 3,
          ),
          const ClinicalFieldDefinition(
            fieldId: 'dosageForm',
            label: 'Dosage Form',
            description: 'Tablet, capsule, syrup, etc.',
            healthTier: 2,
            moduleId: 't2_medications',
            inputType: ClinicalInputType.singleChoiceDropdown,
            options: ClinicalCatalog.dosageForms,
            conditionalParentId: 'recordState',
            conditionalValue: 'yes',
            displayOrder: 4,
          ),
          const ClinicalFieldDefinition(
            fieldId: 'prescribedDose',
            label: 'Prescribed Dose',
            description: 'Dose quantity (e.g. 1 tablet)',
            healthTier: 2,
            moduleId: 't2_medications',
            inputType: ClinicalInputType.multilineText,
            characterLimit: 50,
            conditionalParentId: 'recordState',
            conditionalValue: 'yes',
            displayOrder: 5,
          ),
          const ClinicalFieldDefinition(
            fieldId: 'frequency',
            label: 'Frequency',
            description: 'Daily schedule timing',
            healthTier: 2,
            moduleId: 't2_medications',
            inputType: ClinicalInputType.singleChoiceDropdown,
            options: ClinicalCatalog.medicationFrequencies,
            conditionalParentId: 'recordState',
            conditionalValue: 'yes',
            displayOrder: 6,
          ),
          const ClinicalFieldDefinition(
            fieldId: 'prescriberDetails',
            label: 'Prescriber Details',
            description: 'Doctor name or clinic',
            healthTier: 2,
            moduleId: 't2_medications',
            inputType: ClinicalInputType.multilineText,
            characterLimit: 100,
            conditionalParentId: 'recordState',
            conditionalValue: 'yes',
            displayOrder: 7,
          ),
          const ClinicalFieldDefinition(
            fieldId: 'medicationStatus',
            label: 'Status',
            description: 'Current or past medication',
            healthTier: 2,
            moduleId: 't2_medications',
            inputType: ClinicalInputType.singleChoiceRadio,
            options: [
              ClinicalFieldOption(id: 'active', label: 'Active Current Medication'),
              ClinicalFieldOption(id: 'past', label: 'Past Completed Course'),
            ],
            conditionalParentId: 'recordState',
            conditionalValue: 'yes',
            displayOrder: 8,
          ),
        ];

      case 't2_immunizations':
        return [
          const ClinicalFieldDefinition(
            fieldId: 'recordState',
            label: 'Immunization Records Status',
            description: 'Do you have immunization and vaccination records to document?',
            healthTier: 2,
            moduleId: 't2_immunizations',
            inputType: ClinicalInputType.singleChoiceRadio,
            options: ClinicalCatalog.repeatingRecordChoices,
            requiredState: true,
            displayOrder: 1,
          ),
          ClinicalFieldDefinition(
            fieldId: 'vaccineName',
            label: 'Vaccine / Immunization',
            description: 'Universal Immunization Schedule (UIP) & WHO recommended vaccine',
            healthTier: 2,
            moduleId: 't2_immunizations',
            inputType: ClinicalInputType.singleChoiceDropdown,
            options: ClinicalCatalog.standardVaccines,
            hasOtherOption: true,
            guidelineReference: ClinicalGuidelinesCatalog.getGuidelineByRuleId('GL-T2-IMM-05'),
            conditionalParentId: 'recordState',
            conditionalValue: 'yes',
            displayOrder: 2,
          ),
          const ClinicalFieldDefinition(
            fieldId: 'doseNumber',
            label: 'Dose Number / Series',
            description: 'Sequence in immunization schedule',
            healthTier: 2,
            moduleId: 't2_immunizations',
            inputType: ClinicalInputType.singleChoiceDropdown,
            options: [
              ClinicalFieldOption(id: 'dose_1', label: 'Dose 1 (Primary)'),
              ClinicalFieldOption(id: 'dose_2', label: 'Dose 2'),
              ClinicalFieldOption(id: 'dose_3', label: 'Dose 3'),
              ClinicalFieldOption(id: 'booster_1', label: 'Booster 1'),
              ClinicalFieldOption(id: 'booster_annual', label: 'Annual Dose (e.g. Influenza)'),
            ],
            conditionalParentId: 'recordState',
            conditionalValue: 'yes',
            displayOrder: 3,
          ),
          const ClinicalFieldDefinition(
            fieldId: 'vaccinationDate',
            label: 'Date Administered',
            description: 'Date the vaccine was received',
            healthTier: 2,
            moduleId: 't2_immunizations',
            inputType: ClinicalInputType.datePicker,
            validationRules: [
              ClinicalValidationRule(
                ruleId: 'VAL-VAX-PAST',
                allowFutureDates: false,
                errorMessage: 'Vaccination date cannot be in the future',
              ),
            ],
            conditionalParentId: 'recordState',
            conditionalValue: 'yes',
            displayOrder: 4,
          ),
          const ClinicalFieldDefinition(
            fieldId: 'administeringFacility',
            label: 'Administering Clinic / Hospital',
            description: 'Healthcare facility or government center',
            healthTier: 2,
            moduleId: 't2_immunizations',
            inputType: ClinicalInputType.multilineText,
            characterLimit: 120,
            conditionalParentId: 'recordState',
            conditionalValue: 'yes',
            displayOrder: 5,
          ),
          const ClinicalFieldDefinition(
            fieldId: 'batchLotNumber',
            label: 'Batch / Lot Number (if available)',
            description: 'Found on vaccination certificate',
            healthTier: 2,
            moduleId: 't2_immunizations',
            inputType: ClinicalInputType.multilineText,
            characterLimit: 40,
            conditionalParentId: 'recordState',
            conditionalValue: 'yes',
            displayOrder: 6,
          ),
        ];

      case 't2_surgeries':
        return [
          const ClinicalFieldDefinition(
            fieldId: 'recordState',
            label: 'Surgeries & Hospitalizations Status',
            description: 'Has the member had any prior surgical procedures, major trauma, or hospital admissions?',
            healthTier: 2,
            moduleId: 't2_surgeries',
            inputType: ClinicalInputType.singleChoiceRadio,
            options: ClinicalCatalog.repeatingRecordChoices,
            requiredState: false,
            displayOrder: 1,
          ),
          const ClinicalFieldDefinition(
            fieldId: 'procedureName',
            label: 'Surgical Procedure / Operation Name',
            description: 'Name of surgery (e.g. Appendectomy, Cesarean Section, Cholecystectomy)',
            healthTier: 2,
            moduleId: 't2_surgeries',
            inputType: ClinicalInputType.multilineText,
            characterLimit: 150,
            conditionalParentId: 'recordState',
            conditionalValue: 'yes',
            displayOrder: 2,
          ),
          const ClinicalFieldDefinition(
            fieldId: 'surgeryDate',
            label: 'Date of Surgery',
            description: 'Past date operation was performed',
            healthTier: 2,
            moduleId: 't2_surgeries',
            inputType: ClinicalInputType.datePicker,
            validationRules: [
              ClinicalValidationRule(
                ruleId: 'VAL-SURG-PAST',
                allowFutureDates: false,
                errorMessage: 'Surgery date cannot be in the future',
              ),
            ],
            conditionalParentId: 'recordState',
            conditionalValue: 'yes',
            displayOrder: 3,
          ),
          const ClinicalFieldDefinition(
            fieldId: 'hospitalSurgeon',
            label: 'Hospital & Operating Surgeon',
            description: 'Facility and surgeon name',
            healthTier: 2,
            moduleId: 't2_surgeries',
            inputType: ClinicalInputType.multilineText,
            characterLimit: 120,
            conditionalParentId: 'recordState',
            conditionalValue: 'yes',
            displayOrder: 4,
          ),
          const ClinicalFieldDefinition(
            fieldId: 'indication',
            label: 'Clinical Indication / Diagnosis',
            description: 'Medical reason for undergoing procedure',
            healthTier: 2,
            moduleId: 't2_surgeries',
            inputType: ClinicalInputType.multilineText,
            characterLimit: 200,
            conditionalParentId: 'recordState',
            conditionalValue: 'yes',
            displayOrder: 5,
          ),
          const ClinicalFieldDefinition(
            fieldId: 'complicationsOrNotes',
            label: 'Complications or Follow-Up Notes',
            description: 'Postoperative complications, prosthesis implants, or discharge advice',
            healthTier: 2,
            moduleId: 't2_surgeries',
            inputType: ClinicalInputType.multilineText,
            characterLimit: 300,
            conditionalParentId: 'recordState',
            conditionalValue: 'yes',
            displayOrder: 6,
          ),
        ];

      case 't2_vitals':
        return [
          ClinicalFieldDefinition(
            fieldId: 'systolicBp',
            label: 'Systolic Blood Pressure',
            description: 'Seated resting pressure during heart contraction (WHO IHG-IV guideline)',
            healthTier: 2,
            moduleId: 't2_vitals',
            inputType: ClinicalInputType.numericMeasurement,
            unit: 'mmHg',
            requiredState: true,
            guidelineReference: ClinicalGuidelinesCatalog.getGuidelineByRuleId('GL-T2-BP-01'),
            validationRules: const [
              ClinicalValidationRule(
                ruleId: 'VAL-SYS-RANGE',
                min: 70,
                max: 250,
                errorMessage: 'Systolic BP must be between 70 and 250 mmHg (WHO Guidelines)',
              ),
            ],
            displayOrder: 1,
          ),
          ClinicalFieldDefinition(
            fieldId: 'diastolicBp',
            label: 'Diastolic Blood Pressure',
            description: 'Seated resting pressure between heart contractions',
            healthTier: 2,
            moduleId: 't2_vitals',
            inputType: ClinicalInputType.numericMeasurement,
            unit: 'mmHg',
            requiredState: true,
            guidelineReference: ClinicalGuidelinesCatalog.getGuidelineByRuleId('GL-T2-BP-02'),
            validationRules: const [
              ClinicalValidationRule(
                ruleId: 'VAL-DIA-RANGE',
                min: 40,
                max: 150,
                errorMessage: 'Diastolic BP must be between 40 and 150 mmHg (WHO Guidelines)',
              ),
            ],
            displayOrder: 2,
          ),
          ClinicalFieldDefinition(
            fieldId: 'heartRate',
            label: 'Resting Heart Rate (Pulse)',
            description: 'Resting pulse beats per minute measured over 60 seconds',
            healthTier: 2,
            moduleId: 't2_vitals',
            inputType: ClinicalInputType.numericMeasurement,
            unit: 'bpm',
            requiredState: true,
            guidelineReference: ClinicalGuidelinesCatalog.getGuidelineByRuleId('GL-T2-HR-03'),
            validationRules: const [
              ClinicalValidationRule(
                ruleId: 'VAL-HR-RANGE',
                min: 40,
                max: 200,
                errorMessage: 'Resting heart rate must be between 40 and 200 bpm',
              ),
            ],
            displayOrder: 3,
          ),
          const ClinicalFieldDefinition(
            fieldId: 'heightCm',
            label: 'Standing Height',
            description: 'Stature measured barefoot without footwear',
            healthTier: 2,
            moduleId: 't2_vitals',
            inputType: ClinicalInputType.numericMeasurement,
            unit: 'cm',
            requiredState: true,
            validationRules: [
              ClinicalValidationRule(
                ruleId: 'VAL-HT-RANGE',
                min: 30,
                max: 250,
                errorMessage: 'Height must be between 30 and 250 cm',
              ),
            ],
            displayOrder: 4,
          ),
          const ClinicalFieldDefinition(
            fieldId: 'weightKg',
            label: 'Body Weight',
            description: 'Weight in light clothing without shoes',
            healthTier: 2,
            moduleId: 't2_vitals',
            inputType: ClinicalInputType.numericMeasurement,
            unit: 'kg',
            requiredState: true,
            validationRules: [
              ClinicalValidationRule(
                ruleId: 'VAL-WT-RANGE',
                min: 1,
                max: 300,
                errorMessage: 'Weight must be between 1 and 300 kg',
              ),
            ],
            displayOrder: 5,
          ),
          ClinicalFieldDefinition(
            fieldId: 'bodyMassIndex',
            label: 'Calculated Body Mass Index (BMI)',
            description: 'Calculated from weight and height: Weight(kg) / [Height(m)]²',
            healthTier: 2,
            moduleId: 't2_vitals',
            inputType: ClinicalInputType.numericMeasurement,
            unit: 'kg/m²',
            guidelineReference: ClinicalGuidelinesCatalog.getGuidelineByRuleId('GL-T2-BMI-04'),
            displayOrder: 6,
          ),
          const ClinicalFieldDefinition(
            fieldId: 'temperatureF',
            label: 'Body Temperature',
            description: 'Oral, axillary, or tympanic temperature',
            healthTier: 2,
            moduleId: 't2_vitals',
            inputType: ClinicalInputType.numericMeasurement,
            unit: '°F',
            validationRules: [
              ClinicalValidationRule(
                ruleId: 'VAL-TEMP-RANGE',
                min: 94.0,
                max: 108.0,
                errorMessage: 'Temperature must be between 94.0°F and 108.0°F',
              ),
            ],
            displayOrder: 7,
          ),
          const ClinicalFieldDefinition(
            fieldId: 'oxygenSaturation',
            label: 'Oxygen Saturation (SpO₂)',
            description: 'Resting pulse oximetry percentage at room air',
            healthTier: 2,
            moduleId: 't2_vitals',
            inputType: ClinicalInputType.numericMeasurement,
            unit: '%',
            validationRules: [
              ClinicalValidationRule(
                ruleId: 'VAL-SPO2-RANGE',
                min: 70,
                max: 100,
                errorMessage: 'SpO₂ percentage must be between 70% and 100%',
              ),
            ],
            displayOrder: 8,
          ),
          ClinicalFieldDefinition(
            fieldId: 'fastingBloodGlucose',
            label: 'Fasting Blood Glucose',
            description: 'Plasma glucose measured after minimum 8-hour overnight fast',
            healthTier: 2,
            moduleId: 't2_vitals',
            inputType: ClinicalInputType.numericMeasurement,
            unit: 'mg/dL',
            guidelineReference: ClinicalGuidelinesCatalog.getGuidelineByRuleId('GL-T2-GLU-06'),
            validationRules: const [
              ClinicalValidationRule(
                ruleId: 'VAL-GLU-RANGE',
                min: 40,
                max: 500,
                errorMessage: 'Fasting glucose must be between 40 and 500 mg/dL',
              ),
            ],
            displayOrder: 9,
          ),
          const ClinicalFieldDefinition(
            fieldId: 'measurementNotes',
            label: 'Measurement Context / Notes',
            description: 'Time of day, home device calibration, or physician verified',
            healthTier: 2,
            moduleId: 't2_vitals',
            inputType: ClinicalInputType.multilineText,
            characterLimit: 200,
            displayOrder: 10,
          ),
        ];

      case 't2_screenings':
        return [
          const ClinicalFieldDefinition(
            fieldId: 'screeningType',
            label: 'Screening Type',
            description: 'Preventive health examination category',
            healthTier: 2,
            moduleId: 't2_screenings',
            inputType: ClinicalInputType.singleChoiceDropdown,
            options: [
              ClinicalFieldOption(id: 'blood_pressure', label: 'Hypertension Blood Pressure Screening'),
              ClinicalFieldOption(id: 'lipid_panel', label: 'Lipid Profile / Cholesterol Panel'),
              ClinicalFieldOption(id: 'diabetes_glucose', label: 'Fasting Blood Glucose / HbA1c'),
              ClinicalFieldOption(id: 'vision_exam', label: 'Comprehensive Eye & Vision Exam'),
              ClinicalFieldOption(id: 'dental_exam', label: 'Oral & Dental Health Checkup'),
              ClinicalFieldOption(id: 'mammogram', label: 'Breast Health / Mammography (Female 40+)'),
              ClinicalFieldOption(id: 'pap_smear', label: 'Cervical Cancer Screening / Pap Smear (Female 25+)'),
              ClinicalFieldOption(id: 'colonoscopy', label: 'Colorectal Cancer Screening (Age 45+)'),
            ],
            displayOrder: 1,
          ),
          const ClinicalFieldDefinition(
            fieldId: 'completionDate',
            label: 'Date Completed',
            description: 'Date exam was performed',
            healthTier: 2,
            moduleId: 't2_screenings',
            inputType: ClinicalInputType.datePicker,
            validationRules: [
              ClinicalValidationRule(
                ruleId: 'VAL-SCREEN-PAST',
                allowFutureDates: false,
                errorMessage: 'Screening completion date cannot be in the future',
              ),
            ],
            displayOrder: 2,
          ),
          const ClinicalFieldDefinition(
            fieldId: 'resultSummary',
            label: 'Screening Result',
            description: 'Clinical outcome classification',
            healthTier: 2,
            moduleId: 't2_screenings',
            inputType: ClinicalInputType.singleChoiceRadio,
            options: [
              ClinicalFieldOption(id: 'normal', label: 'Normal / Within Standard Limits'),
              ClinicalFieldOption(id: 'borderline', label: 'Borderline / Early Monitoring Required'),
              ClinicalFieldOption(id: 'abnormal', label: 'Abnormal / Action or Treatment Required'),
            ],
            displayOrder: 3,
          ),
          const ClinicalFieldDefinition(
            fieldId: 'nextDueDate',
            label: 'Next Recommended Screening Date',
            description: 'Target date for routine re-screening',
            healthTier: 2,
            moduleId: 't2_screenings',
            inputType: ClinicalInputType.datePicker,
            displayOrder: 4,
          ),
          const ClinicalFieldDefinition(
            fieldId: 'screeningNotes',
            label: 'Clinical Notes / Findings',
            description: 'Doctor advice or follow-up recommendations',
            healthTier: 2,
            moduleId: 't2_screenings',
            inputType: ClinicalInputType.multilineText,
            characterLimit: 250,
            displayOrder: 5,
          ),
        ];

      case 't2_care_team':
        return [
          const ClinicalFieldDefinition(
            fieldId: 'primaryPhysician',
            label: 'Primary Care Physician / Family Doctor',
            description: 'Main general practitioner or consultant',
            healthTier: 2,
            moduleId: 't2_care_team',
            inputType: ClinicalInputType.multilineText,
            characterLimit: 100,
            displayOrder: 1,
          ),
          const ClinicalFieldDefinition(
            fieldId: 'specialty',
            label: 'Medical Specialty',
            description: 'e.g. General Practice, Internal Medicine, Pediatrics, Cardiology',
            healthTier: 2,
            moduleId: 't2_care_team',
            inputType: ClinicalInputType.multilineText,
            characterLimit: 80,
            displayOrder: 2,
          ),
          const ClinicalFieldDefinition(
            fieldId: 'clinicHospital',
            label: 'Primary Clinic / Hospital Name',
            description: 'Name of the healthcare facility',
            healthTier: 2,
            moduleId: 't2_care_team',
            inputType: ClinicalInputType.multilineText,
            characterLimit: 120,
            displayOrder: 3,
          ),
          const ClinicalFieldDefinition(
            fieldId: 'contactPhone',
            label: 'Clinic / Physician Phone Number',
            description: 'Contact number for booking or consultation',
            healthTier: 2,
            moduleId: 't2_care_team',
            inputType: ClinicalInputType.multilineText,
            displayOrder: 4,
            validationRules: [
              ClinicalValidationRule(
                ruleId: 'VAL-CARE-PHONE',
                errorMessage: 'Enter a valid clinic phone number',
              ),
            ],
          ),
          const ClinicalFieldDefinition(
            fieldId: 'email',
            label: 'Clinic / Physician Email (Optional)',
            description: 'Email for reports and consultations',
            healthTier: 2,
            moduleId: 't2_care_team',
            inputType: ClinicalInputType.multilineText,
            displayOrder: 5,
          ),
        ];

      case 't2_insurance':
        return [
          const ClinicalFieldDefinition(
            fieldId: 'insuranceProvider',
            label: 'Insurance Provider / Company',
            description: 'Name of health insurance underwriter (e.g. Star Health, HDFC ERGO, Care, New India)',
            healthTier: 2,
            moduleId: 't2_insurance',
            inputType: ClinicalInputType.multilineText,
            characterLimit: 100,
            displayOrder: 1,
          ),
          const ClinicalFieldDefinition(
            fieldId: 'policyNumber',
            label: 'Policy Number / TPA Member ID',
            description: 'Unique member or group policy card number',
            healthTier: 2,
            moduleId: 't2_insurance',
            inputType: ClinicalInputType.multilineText,
            characterLimit: 60,
            displayOrder: 2,
          ),
          const ClinicalFieldDefinition(
            fieldId: 'policyHolder',
            label: 'Primary Policyholder Name',
            description: 'Name of the primary insured individual',
            healthTier: 2,
            moduleId: 't2_insurance',
            inputType: ClinicalInputType.multilineText,
            characterLimit: 100,
            displayOrder: 3,
          ),
          const ClinicalFieldDefinition(
            fieldId: 'coverageExpiry',
            label: 'Policy Expiry Date',
            description: 'End date of current coverage term',
            healthTier: 2,
            moduleId: 't2_insurance',
            inputType: ClinicalInputType.datePicker,
            displayOrder: 4,
          ),
          const ClinicalFieldDefinition(
            fieldId: 'sumInsured',
            label: 'Sum Insured (₹ Coverage Amount)',
            description: 'Total policy sum insured limit',
            healthTier: 2,
            moduleId: 't2_insurance',
            inputType: ClinicalInputType.multilineText,
            characterLimit: 50,
            displayOrder: 5,
          ),
          const ClinicalFieldDefinition(
            fieldId: 'networkHospitalStatus',
            label: 'Hospital Claim Model',
            description: 'Preferred billing and claim mechanism',
            healthTier: 2,
            moduleId: 't2_insurance',
            inputType: ClinicalInputType.singleChoiceRadio,
            options: [
              ClinicalFieldOption(id: 'cashless', label: 'Cashless Network Empanelled'),
              ClinicalFieldOption(id: 'reimbursement', label: 'Reimbursement Claim'),
              ClinicalFieldOption(id: 'govt_scheme', label: 'Govt Health Scheme (Ayushman Bharat / PMJAY)'),
            ],
            displayOrder: 6,
          ),
        ];

      // --- TIER 3: LONGITUDINAL & LIFE-STAGE ---
      case 't3_family_history':
        return [
          const ClinicalFieldDefinition(
            fieldId: 'condition',
            label: 'Hereditary / Familial Condition',
            description: 'Disease with established first-degree relative familial risk',
            healthTier: 3,
            moduleId: 't3_family_history',
            inputType: ClinicalInputType.singleChoiceDropdown,
            options: [
              ClinicalFieldOption(id: 'premature_cad', label: 'Premature Heart Attack / CAD (Male <55, Female <65)'),
              ClinicalFieldOption(id: 'type2_diabetes', label: 'Type 2 Diabetes Mellitus'),
              ClinicalFieldOption(id: 'hypertension', label: 'Essential Hypertension (High BP)'),
              ClinicalFieldOption(id: 'stroke', label: 'Ischemic or Hemorrhagic Stroke'),
              ClinicalFieldOption(id: 'breast_ovarian_cancer', label: 'Breast or Ovarian Cancer (BRCA familial)'),
              ClinicalFieldOption(id: 'colorectal_cancer', label: 'Colorectal Cancer / Polyposis'),
              ClinicalFieldOption(id: 'asthma_allergies', label: 'Severe Asthma / Atopy'),
              ClinicalFieldOption(id: 'other', label: 'Other Inherited Disease'),
            ],
            requiredState: true,
            displayOrder: 1,
          ),
          const ClinicalFieldDefinition(
            fieldId: 'relative',
            label: 'Affected First-Degree Relative',
            description: 'Family member affected',
            healthTier: 3,
            moduleId: 't3_family_history',
            inputType: ClinicalInputType.singleChoiceDropdown,
            options: [
              ClinicalFieldOption(id: 'father', label: 'Biological Father'),
              ClinicalFieldOption(id: 'mother', label: 'Biological Mother'),
              ClinicalFieldOption(id: 'brother', label: 'Brother (Full Sibling)'),
              ClinicalFieldOption(id: 'sister', label: 'Sister (Full Sibling)'),
              ClinicalFieldOption(id: 'grandparent', label: 'Grandparent (Maternal or Paternal)'),
            ],
            requiredState: true,
            displayOrder: 2,
          ),
          const ClinicalFieldDefinition(
            fieldId: 'ageAtDiagnosis',
            label: 'Approximate Age at Diagnosis (Years)',
            description: 'Age when the relative was first diagnosed',
            healthTier: 3,
            moduleId: 't3_family_history',
            inputType: ClinicalInputType.numericMeasurement,
            unit: 'years',
            validationRules: [
              ClinicalValidationRule(
                ruleId: 'VAL-FAM-AGE',
                min: 1,
                max: 110,
                errorMessage: 'Age must be between 1 and 110 years',
              ),
            ],
            displayOrder: 3,
          ),
          const ClinicalFieldDefinition(
            fieldId: 'notes',
            label: 'Additional Family Medical Notes',
            description: 'Genetic testing history or known familial mutations',
            healthTier: 3,
            moduleId: 't3_family_history',
            inputType: ClinicalInputType.multilineText,
            characterLimit: 250,
            displayOrder: 4,
          ),
        ];

      case 't3_lifestyle':
        return [
          const ClinicalFieldDefinition(
            fieldId: 'dietType',
            label: 'Primary Dietary Pattern',
            description: 'Dietary habits affecting cardiometabolic risk',
            healthTier: 3,
            moduleId: 't3_lifestyle',
            inputType: ClinicalInputType.singleChoiceDropdown,
            options: ClinicalCatalog.dietTypes,
            displayOrder: 1,
          ),
          ClinicalFieldDefinition(
            fieldId: 'physicalActivityLevel',
            label: 'Physical Activity Frequency',
            description: 'WHO 2020 Guidelines on Physical Activity (150-300 min moderate/week)',
            healthTier: 3,
            moduleId: 't3_lifestyle',
            inputType: ClinicalInputType.singleChoiceDropdown,
            options: ClinicalCatalog.activityLevels,
            guidelineReference: ClinicalGuidelinesCatalog.getGuidelineByRuleId('GL-T3-PA-01'),
            displayOrder: 2,
          ),
          ClinicalFieldDefinition(
            fieldId: 'sleepHours',
            label: 'Average Nightly Sleep Duration',
            description: 'Average sleep hours per 24-hour cycle (Recommended adult: 7-9 hours)',
            healthTier: 3,
            moduleId: 't3_lifestyle',
            inputType: ClinicalInputType.numericMeasurement,
            unit: 'hours/night',
            guidelineReference: ClinicalGuidelinesCatalog.getGuidelineByRuleId('GL-T3-SLP-02'),
            validationRules: const [
              ClinicalValidationRule(
                ruleId: 'VAL-SLEEP-RANGE',
                min: 3.0,
                max: 16.0,
                errorMessage: 'Sleep hours must be between 3.0 and 16.0 hours',
              ),
            ],
            displayOrder: 3,
          ),
          const ClinicalFieldDefinition(
            fieldId: 'waterIntakeLiters',
            label: 'Daily Water Consumption',
            description: 'Average daily fluid intake in liters',
            healthTier: 3,
            moduleId: 't3_lifestyle',
            inputType: ClinicalInputType.numericMeasurement,
            unit: 'liters/day',
            validationRules: [
              ClinicalValidationRule(
                ruleId: 'VAL-WATER-RANGE',
                min: 0.5,
                max: 10.0,
                errorMessage: 'Water intake must be between 0.5 and 10.0 liters/day',
              ),
            ],
            displayOrder: 4,
          ),
          const ClinicalFieldDefinition(
            fieldId: 'lifestyleNotes',
            label: 'Lifestyle Goals / Barriers',
            description: 'Work schedule, travel frequency, or physical fitness routine notes',
            healthTier: 3,
            moduleId: 't3_lifestyle',
            inputType: ClinicalInputType.multilineText,
            characterLimit: 250,
            displayOrder: 5,
          ),
        ];

      case 't3_social_determinants':
        return [
          const ClinicalFieldDefinition(
            fieldId: 'livingEnvironment',
            label: 'Living Environment',
            description: 'Residential setting influencing environmental health',
            healthTier: 3,
            moduleId: 't3_social_determinants',
            inputType: ClinicalInputType.singleChoiceDropdown,
            options: [
              ClinicalFieldOption(id: 'urban', label: 'Urban / City Apartment'),
              ClinicalFieldOption(id: 'semi_urban', label: 'Semi-Urban / Suburban House'),
              ClinicalFieldOption(id: 'rural', label: 'Rural / Agricultural Community'),
            ],
            displayOrder: 1,
          ),
          const ClinicalFieldDefinition(
            fieldId: 'supportNetwork',
            label: 'Physical & Social Support Network',
            description: 'Availability of family or caregiver support at home',
            healthTier: 3,
            moduleId: 't3_social_determinants',
            inputType: ClinicalInputType.singleChoiceRadio,
            options: [
              ClinicalFieldOption(id: 'family_home', label: 'Lives with Family / Active Support Network'),
              ClinicalFieldOption(id: 'caregiver', label: 'Lives with Dedicated Caregiver / Attendant'),
              ClinicalFieldOption(id: 'alone', label: 'Lives Alone (Requires periodic check-ins)'),
            ],
            displayOrder: 2,
          ),
          const ClinicalFieldDefinition(
            fieldId: 'mobilityAccessibility',
            label: 'Home Mobility Accessibility',
            description: 'Physical access constraints at residence',
            healthTier: 3,
            moduleId: 't3_social_determinants',
            inputType: ClinicalInputType.singleChoiceDropdown,
            options: [
              ClinicalFieldOption(id: 'ground_floor', label: 'Ground Floor / Elevator Accessible'),
              ClinicalFieldOption(id: 'stairs_only', label: 'Stairs Only (Elevator not available)'),
              ClinicalFieldOption(id: 'wheelchair_adapted', label: 'Wheelchair / Ramp Adapted'),
            ],
            displayOrder: 3,
          ),
          const ClinicalFieldDefinition(
            fieldId: 'socialNotes',
            label: 'Environmental / Social Notes',
            description: 'Occupational hazards, air quality concerns, or care assistance needs',
            healthTier: 3,
            moduleId: 't3_social_determinants',
            inputType: ClinicalInputType.multilineText,
            characterLimit: 250,
            displayOrder: 4,
          ),
        ];

      case 't3_pediatric_milestones':
        return [
          ClinicalFieldDefinition(
            fieldId: 'birthWeight',
            label: 'Birth Weight',
            description: 'Weight documented within 1 hour of birth (WHO Child Growth Standards)',
            healthTier: 3,
            moduleId: 't3_pediatric_milestones',
            inputType: ClinicalInputType.numericMeasurement,
            unit: 'kg',
            requiredState: true,
            guidelineReference: ClinicalGuidelinesCatalog.getGuidelineByRuleId('GL-T3-PED-03'),
            validationRules: const [
              ClinicalValidationRule(
                ruleId: 'VAL-BW-RANGE',
                min: 0.5,
                max: 6.5,
                errorMessage: 'Birth weight must be between 0.5 and 6.5 kg',
              ),
            ],
            displayOrder: 1,
          ),
          const ClinicalFieldDefinition(
            fieldId: 'gestationalWeeks',
            label: 'Gestational Age at Birth (Weeks)',
            description: 'Weeks of gestation at delivery (Full term: 37–42 weeks)',
            healthTier: 3,
            moduleId: 't3_pediatric_milestones',
            inputType: ClinicalInputType.numericMeasurement,
            unit: 'weeks',
            validationRules: [
              ClinicalValidationRule(
                ruleId: 'VAL-GA-RANGE',
                min: 24,
                max: 43,
                errorMessage: 'Gestational age must be between 24 and 43 weeks',
              ),
            ],
            displayOrder: 2,
          ),
          const ClinicalFieldDefinition(
            fieldId: 'deliveryType',
            label: 'Mode of Delivery',
            description: 'Method of child delivery',
            healthTier: 3,
            moduleId: 't3_pediatric_milestones',
            inputType: ClinicalInputType.singleChoiceRadio,
            options: [
              ClinicalFieldOption(id: 'vaginal', label: 'Normal Vaginal Delivery'),
              ClinicalFieldOption(id: 'c_section', label: 'Cesarean Section (C-Section)'),
              ClinicalFieldOption(id: 'assisted', label: 'Assisted Delivery (Forceps / Vacuum)'),
            ],
            displayOrder: 3,
          ),
          const ClinicalFieldDefinition(
            fieldId: 'developmentalStatus',
            label: 'Developmental Milestones Status',
            description: 'Motor, speech, and social milestone progression',
            healthTier: 3,
            moduleId: 't3_pediatric_milestones',
            inputType: ClinicalInputType.singleChoiceRadio,
            options: [
              ClinicalFieldOption(id: 'on_schedule', label: 'All Milestones on Schedule'),
              ClinicalFieldOption(id: 'mild_delay', label: 'Mild Delay (Speech or Motor)'),
              ClinicalFieldOption(id: 'pediatrician_eval', label: 'Under Active Pediatrician Evaluation'),
            ],
            displayOrder: 4,
          ),
          const ClinicalFieldDefinition(
            fieldId: 'pediatricNotes',
            label: 'Neonatal / Pediatric Notes',
            description: 'NICU stay, phototherapy for jaundice, or pediatrician recommendations',
            healthTier: 3,
            moduleId: 't3_pediatric_milestones',
            inputType: ClinicalInputType.multilineText,
            characterLimit: 300,
            displayOrder: 5,
          ),
        ];

      case 't3_adolescent_growth':
        return [
          const ClinicalFieldDefinition(
            fieldId: 'growthProgression',
            label: 'Pubertal Growth Velocity',
            description: 'Adolescent growth progression and height velocity',
            healthTier: 3,
            moduleId: 't3_adolescent_growth',
            inputType: ClinicalInputType.singleChoiceRadio,
            options: [
              ClinicalFieldOption(id: 'normal_spurt', label: 'Normal Expected Growth Spurt'),
              ClinicalFieldOption(id: 'under_eval', label: 'Growth Delay Under Evaluation'),
              ClinicalFieldOption(id: 'completed', label: 'Near Adult Stature Achieved'),
            ],
            displayOrder: 1,
          ),
          const ClinicalFieldDefinition(
            fieldId: 'postureScoliosisScreening',
            label: 'Spine & Posture Screening',
            description: 'Adam\'s forward bend test or school physical assessment',
            healthTier: 3,
            moduleId: 't3_adolescent_growth',
            inputType: ClinicalInputType.singleChoiceRadio,
            options: [
              ClinicalFieldOption(id: 'normal', label: 'Screened Normal (No curvature observed)'),
              ClinicalFieldOption(id: 'mild_scoliosis', label: 'Mild Curvature / Orthopedic Monitoring'),
              ClinicalFieldOption(id: 'not_screened', label: 'Not Yet Screened'),
            ],
            displayOrder: 2,
          ),
          const ClinicalFieldDefinition(
            fieldId: 'schoolActivityNotes',
            label: 'School Athletics & Physicals',
            description: 'Sports participation clearance, hydration, or backpack posture notes',
            healthTier: 3,
            moduleId: 't3_adolescent_growth',
            inputType: ClinicalInputType.multilineText,
            characterLimit: 250,
            displayOrder: 3,
          ),
        ];

      case 't3_reproductive_health':
        return [
          const ClinicalFieldDefinition(
            fieldId: 'menarcheAge',
            label: 'Age at Menarche (Years)',
            description: 'Age when menstrual cycles first commenced',
            healthTier: 3,
            moduleId: 't3_reproductive_health',
            inputType: ClinicalInputType.numericMeasurement,
            unit: 'years',
            sensitivityClass: SensitivityClass.sensitive,
            consentCategory: 'reproductive_health',
            validationRules: [
              ClinicalValidationRule(
                ruleId: 'VAL-MEN-AGE',
                min: 8,
                max: 20,
                errorMessage: 'Menarche age typically ranges between 8 and 20 years',
              ),
            ],
            displayOrder: 1,
          ),
          const ClinicalFieldDefinition(
            fieldId: 'cycleRegularity',
            label: 'Menstrual Cycle Regularity',
            description: 'Pattern and regularity of menstrual cycle',
            healthTier: 3,
            moduleId: 't3_reproductive_health',
            inputType: ClinicalInputType.singleChoiceRadio,
            options: [
              ClinicalFieldOption(id: 'regular', label: 'Regular (24–35 Days)'),
              ClinicalFieldOption(id: 'irregular', label: 'Irregular / Variable Length'),
              ClinicalFieldOption(id: 'perimenopausal', label: 'Perimenopausal Transitions'),
              ClinicalFieldOption(id: 'postmenopausal', label: 'Post-Menopausal (>= 12 months amenorrhea)'),
            ],
            sensitivityClass: SensitivityClass.sensitive,
            consentCategory: 'reproductive_health',
            displayOrder: 2,
          ),
          const ClinicalFieldDefinition(
            fieldId: 'lastMenstrualPeriod',
            label: 'Last Menstrual Period (LMP) Date',
            description: 'First day of the most recent menstrual period',
            healthTier: 3,
            moduleId: 't3_reproductive_health',
            inputType: ClinicalInputType.datePicker,
            sensitivityClass: SensitivityClass.sensitive,
            consentCategory: 'reproductive_health',
            validationRules: [
              ClinicalValidationRule(
                ruleId: 'VAL-LMP-PAST',
                allowFutureDates: false,
                errorMessage: 'LMP date cannot be in the future',
              ),
            ],
            displayOrder: 3,
          ),
          const ClinicalFieldDefinition(
            fieldId: 'gravidaPara',
            label: 'Obstetric History (Gravida / Para)',
            description: 'Total pregnancies and live births (e.g. G2P2: 2 pregnancies, 2 live births)',
            healthTier: 3,
            moduleId: 't3_reproductive_health',
            inputType: ClinicalInputType.multilineText,
            characterLimit: 100,
            sensitivityClass: SensitivityClass.sensitive,
            consentCategory: 'reproductive_health',
            displayOrder: 4,
          ),
          const ClinicalFieldDefinition(
            fieldId: 'reproductiveNotes',
            label: 'Maternal / Reproductive Health Notes',
            description: 'History of gestational diabetes, preeclampsia, or gynecological consultations',
            healthTier: 3,
            moduleId: 't3_reproductive_health',
            inputType: ClinicalInputType.multilineText,
            characterLimit: 300,
            sensitivityClass: SensitivityClass.sensitive,
            consentCategory: 'reproductive_health',
            displayOrder: 5,
          ),
        ];

      case 't3_geriatric_assessment':
        return [
          ClinicalFieldDefinition(
            fieldId: 'fallRiskLevel',
            label: 'Fall Risk Stratification',
            description: 'World Guidelines for Falls Prevention in Older Adults (2022)',
            healthTier: 3,
            moduleId: 't3_geriatric_assessment',
            inputType: ClinicalInputType.singleChoiceDropdown,
            options: ClinicalCatalog.fallRiskLevels,
            requiredState: true,
            guidelineReference: ClinicalGuidelinesCatalog.getGuidelineByRuleId('GL-T3-GER-04'),
            displayOrder: 1,
          ),
          const ClinicalFieldDefinition(
            fieldId: 'fallCountLast12Months',
            label: 'Number of Falls in Past 12 Months',
            description: 'Documented slips, trips, or falls',
            healthTier: 3,
            moduleId: 't3_geriatric_assessment',
            inputType: ClinicalInputType.numericMeasurement,
            unit: 'falls',
            validationRules: [
              ClinicalValidationRule(
                ruleId: 'VAL-FALLS-RANGE',
                min: 0,
                max: 30,
                errorMessage: 'Enter number of falls between 0 and 30',
              ),
            ],
            displayOrder: 2,
          ),
          const ClinicalFieldDefinition(
            fieldId: 'assistiveDevice',
            label: 'Mobility Assistive Device',
            description: 'Equipment utilized for ambulation',
            healthTier: 3,
            moduleId: 't3_geriatric_assessment',
            inputType: ClinicalInputType.singleChoiceDropdown,
            options: ClinicalCatalog.assistiveDevices,
            displayOrder: 3,
          ),
          const ClinicalFieldDefinition(
            fieldId: 'adlIndependence',
            label: 'Activities of Daily Living (ADL) Independence',
            description: 'Ability to independently manage bathing, dressing, eating, and transfers',
            healthTier: 3,
            moduleId: 't3_geriatric_assessment',
            inputType: ClinicalInputType.singleChoiceRadio,
            options: [
              ClinicalFieldOption(id: 'fully_independent', label: 'Fully Independent in all ADLs'),
              ClinicalFieldOption(id: 'needs_assistance', label: 'Needs Partial Caregiver Assistance'),
              ClinicalFieldOption(id: 'dependent', label: 'Substantially / Fully Caregiver Dependent'),
            ],
            displayOrder: 4,
          ),
          const ClinicalFieldDefinition(
            fieldId: 'geriatricNotes',
            label: 'Geriatric Care & Home Safety Notes',
            description: 'Grab bars installed, non-slip mats, night lights, or physiotherapy recommendations',
            healthTier: 3,
            moduleId: 't3_geriatric_assessment',
            inputType: ClinicalInputType.multilineText,
            characterLimit: 300,
            displayOrder: 5,
          ),
        ];

      case 't3_advance_care':
        return [
          const ClinicalFieldDefinition(
            fieldId: 'hasLivingWill',
            label: 'Advance Healthcare Directive / Living Will',
            description: 'Has the member executed a documented advance medical care directive?',
            healthTier: 3,
            moduleId: 't3_advance_care',
            inputType: ClinicalInputType.singleChoiceRadio,
            options: [
              ClinicalFieldOption(id: 'yes_executed', label: 'Yes, Documented Living Will Executed'),
              ClinicalFieldOption(id: 'no', label: 'No Formal Directive in Place'),
              ClinicalFieldOption(id: 'declined', label: 'Declined to State / Personal Preference'),
            ],
            displayOrder: 1,
          ),
          const ClinicalFieldDefinition(
            fieldId: 'proxyContactName',
            label: 'Designated Healthcare Proxy / Power of Attorney',
            description: 'Name of legally appointed healthcare surrogate',
            healthTier: 3,
            moduleId: 't3_advance_care',
            inputType: ClinicalInputType.multilineText,
            characterLimit: 100,
            displayOrder: 2,
          ),
          const ClinicalFieldDefinition(
            fieldId: 'proxyContactPhone',
            label: 'Proxy Contact Phone Number',
            description: 'Phone number with country code for emergency healthcare surrogate',
            healthTier: 3,
            moduleId: 't3_advance_care',
            inputType: ClinicalInputType.multilineText,
            displayOrder: 3,
          ),
          const ClinicalFieldDefinition(
            fieldId: 'resuscitationPreference',
            label: 'Resuscitation & Critical Care Preference',
            description: 'Preferences discussed with primary clinician and family',
            healthTier: 3,
            moduleId: 't3_advance_care',
            inputType: ClinicalInputType.singleChoiceDropdown,
            options: [
              ClinicalFieldOption(id: 'full_code', label: 'Full Resuscitation (All therapeutic measures)'),
              ClinicalFieldOption(id: 'dnr_specified', label: 'DNR / Comfort Measures Only (Formally documented)'),
              ClinicalFieldOption(id: 'family_decision', label: 'Surrogate / Family Decision at Time of Event'),
              ClinicalFieldOption(id: 'not_discussed', label: 'Not Yet Formally Discussed'),
            ],
            displayOrder: 4,
          ),
        ];

      // --- TIER 4: ADVANCED & CONTEXTUAL ---
      case 't4_mental_health':
        return [
          ClinicalFieldDefinition(
            fieldId: 'stressLevel',
            label: 'Current Perceived Stress Level',
            description: 'Self-reported stress over the past 4 weeks (Consent-Gated)',
            healthTier: 4,
            moduleId: 't4_mental_health',
            inputType: ClinicalInputType.singleChoiceDropdown,
            options: ClinicalCatalog.stressLevels,
            sensitivityClass: SensitivityClass.sensitive,
            consentCategory: 'mental_health',
            displayOrder: 1,
          ),
          ClinicalFieldDefinition(
            fieldId: 'phq2DepressionScreening',
            label: 'PHQ-2 Mood Screening (Past 2 Weeks)',
            description: 'WHO mhGAP standardized two-question mood screening indicator',
            healthTier: 4,
            moduleId: 't4_mental_health',
            inputType: ClinicalInputType.singleChoiceRadio,
            options: const [
              ClinicalFieldOption(id: 'not_at_all', label: 'Not at all (Score 0)'),
              ClinicalFieldOption(id: 'several_days', label: 'Several days (Score 1)'),
              ClinicalFieldOption(id: 'more_than_half', label: 'More than half the days (Score 2)'),
              ClinicalFieldOption(id: 'nearly_every_day', label: 'Nearly every day (Score 3)'),
            ],
            sensitivityClass: SensitivityClass.sensitive,
            consentCategory: 'mental_health',
            guidelineReference: ClinicalGuidelinesCatalog.getGuidelineByRuleId('GL-T4-MH-01'),
            displayOrder: 2,
          ),
          const ClinicalFieldDefinition(
            fieldId: 'gad2AnxietyScreening',
            label: 'GAD-2 Anxiety Screening (Past 2 Weeks)',
            description: 'Frequency of feeling nervous, anxious, or on edge',
            healthTier: 4,
            moduleId: 't4_mental_health',
            inputType: ClinicalInputType.singleChoiceRadio,
            options: [
              ClinicalFieldOption(id: 'not_at_all', label: 'Not at all (Score 0)'),
              ClinicalFieldOption(id: 'several_days', label: 'Several days (Score 1)'),
              ClinicalFieldOption(id: 'more_than_half', label: 'More than half the days (Score 2)'),
              ClinicalFieldOption(id: 'nearly_every_day', label: 'Nearly every day (Score 3)'),
            ],
            sensitivityClass: SensitivityClass.sensitive,
            consentCategory: 'mental_health',
            displayOrder: 3,
          ),
          const ClinicalFieldDefinition(
            fieldId: 'priorSupport',
            label: 'Professional Mental Health Counseling History',
            description: 'Prior engagement with professional psychological or psychiatric care',
            healthTier: 4,
            moduleId: 't4_mental_health',
            inputType: ClinicalInputType.singleChoiceRadio,
            options: [
              ClinicalFieldOption(id: 'currently_seeing', label: 'Currently Seeing Professional Counselor / Therapist'),
              ClinicalFieldOption(id: 'past_history', label: 'Past History of Professional Care (Now Resolved)'),
              ClinicalFieldOption(id: 'never', label: 'Never Consulted Mental Health Professional'),
              ClinicalFieldOption(id: 'declined', label: 'Declined to Disclose'),
            ],
            sensitivityClass: SensitivityClass.sensitive,
            consentCategory: 'mental_health',
            displayOrder: 4,
          ),
          const ClinicalFieldDefinition(
            fieldId: 'mentalHealthNotes',
            label: 'Personal Coping Notes & Wellness Insights',
            description: 'Mindfulness practices, counseling notes, or preferred stress relievers',
            healthTier: 4,
            moduleId: 't4_mental_health',
            inputType: ClinicalInputType.multilineText,
            characterLimit: 300,
            sensitivityClass: SensitivityClass.sensitive,
            consentCategory: 'mental_health',
            displayOrder: 5,
          ),
        ];

      case 't4_substance_use':
        return [
          ClinicalFieldDefinition(
            fieldId: 'tobaccoStatus',
            label: 'Tobacco & Nicotine Consumption',
            description: 'Smoking, bidi, or smokeless tobacco history (WHO FCTC Guidelines)',
            healthTier: 4,
            moduleId: 't4_substance_use',
            inputType: ClinicalInputType.singleChoiceDropdown,
            options: ClinicalCatalog.tobaccoUseStatuses,
            sensitivityClass: SensitivityClass.sensitive,
            consentCategory: 'substance_use',
            guidelineReference: ClinicalGuidelinesCatalog.getGuidelineByRuleId('GL-T4-SUB-02'),
            displayOrder: 1,
          ),
          ClinicalFieldDefinition(
            fieldId: 'alcoholFrequency',
            label: 'Alcohol Consumption Frequency',
            description: 'WHO AUDIT-C standardized primary care alcohol frequency screener',
            healthTier: 4,
            moduleId: 't4_substance_use',
            inputType: ClinicalInputType.singleChoiceDropdown,
            options: ClinicalCatalog.alcoholFrequencies,
            sensitivityClass: SensitivityClass.sensitive,
            consentCategory: 'substance_use',
            guidelineReference: ClinicalGuidelinesCatalog.getGuidelineByRuleId('GL-T4-AUD-03'),
            displayOrder: 2,
          ),
          const ClinicalFieldDefinition(
            fieldId: 'otherSubstances',
            label: 'Other Substance Use / Cessation History',
            description: 'History of prescription misuse or illicit substance exposure',
            healthTier: 4,
            moduleId: 't4_substance_use',
            inputType: ClinicalInputType.singleChoiceRadio,
            options: [
              ClinicalFieldOption(id: 'none', label: 'No Other Substance Use'),
              ClinicalFieldOption(id: 'in_recovery', label: 'In Active Recovery / Cessation Program'),
              ClinicalFieldOption(id: 'declined', label: 'Declined to Disclose'),
            ],
            sensitivityClass: SensitivityClass.sensitive,
            consentCategory: 'substance_use',
            displayOrder: 3,
          ),
          const ClinicalFieldDefinition(
            fieldId: 'substanceNotes',
            label: 'Cessation Support / Health Goals',
            description: 'Nicotine replacement therapy, cessation counseling, or alcohol abstinence goals',
            healthTier: 4,
            moduleId: 't4_substance_use',
            inputType: ClinicalInputType.multilineText,
            characterLimit: 250,
            sensitivityClass: SensitivityClass.sensitive,
            consentCategory: 'substance_use',
            displayOrder: 4,
          ),
        ];

      case 't4_sensory_dental':
        return [
          const ClinicalFieldDefinition(
            fieldId: 'correctiveLenses',
            label: 'Vision Correction & Refractive Aids',
            description: 'Optical correction devices in regular use',
            healthTier: 4,
            moduleId: 't4_sensory_dental',
            inputType: ClinicalInputType.singleChoiceDropdown,
            options: [
              ClinicalFieldOption(id: 'none', label: 'None (Uncorrected Normal Vision)'),
              ClinicalFieldOption(id: 'glasses', label: 'Prescription Eyeglasses (Distance or Reading)'),
              ClinicalFieldOption(id: 'contacts', label: 'Contact Lenses'),
              ClinicalFieldOption(id: 'both', label: 'Both Eyeglasses & Contact Lenses'),
              ClinicalFieldOption(id: 'lasik', label: 'Prior Refractive Surgery (LASIK / SMILE)'),
            ],
            displayOrder: 1,
          ),
          const ClinicalFieldDefinition(
            fieldId: 'hearingAids',
            label: 'Hearing Health & Assistive Aids',
            description: 'Auditory amplification devices',
            healthTier: 4,
            moduleId: 't4_sensory_dental',
            inputType: ClinicalInputType.singleChoiceRadio,
            options: [
              ClinicalFieldOption(id: 'none', label: 'None (Normal Hearing)'),
              ClinicalFieldOption(id: 'unilateral', label: 'Unilateral Hearing Aid (One Ear)'),
              ClinicalFieldOption(id: 'bilateral', label: 'Bilateral Hearing Aids (Both Ears)'),
              ClinicalFieldOption(id: 'tinnitus', label: 'Tinnitus / Under Audiology Evaluation'),
            ],
            displayOrder: 2,
          ),
          const ClinicalFieldDefinition(
            fieldId: 'dentalHealth',
            label: 'Oral Health & Dental Appliances',
            description: 'Dentures, orthodontic braces, implants, or crowns',
            healthTier: 4,
            moduleId: 't4_sensory_dental',
            inputType: ClinicalInputType.singleChoiceDropdown,
            options: [
              ClinicalFieldOption(id: 'natural', label: 'Natural Dentition / Good Hygiene'),
              ClinicalFieldOption(id: 'braces', label: 'Orthodontic Braces / Aligners in Place'),
              ClinicalFieldOption(id: 'dentures_partial', label: 'Partial Denture / Bridge'),
              ClinicalFieldOption(id: 'dentures_full', label: 'Complete Dentures (Upper and/or Lower)'),
              ClinicalFieldOption(id: 'implants', label: 'Dental Implants Installed'),
            ],
            displayOrder: 3,
          ),
          const ClinicalFieldDefinition(
            fieldId: 'sensoryNotes',
            label: 'Sensory / Dental Care Notes',
            description: 'Last optometrist or dental cleaning visit, prescription details',
            healthTier: 4,
            moduleId: 't4_sensory_dental',
            inputType: ClinicalInputType.multilineText,
            characterLimit: 250,
            displayOrder: 4,
          ),
        ];

      case 't4_infectious_travel':
        return [
          const ClinicalFieldDefinition(
            fieldId: 'tuberculosisScreening',
            label: 'Tuberculosis (TB) Screening / History',
            description: 'Prior active TB, latent infection, or household exposure',
            healthTier: 4,
            moduleId: 't4_infectious_travel',
            inputType: ClinicalInputType.singleChoiceRadio,
            options: [
              ClinicalFieldOption(id: 'no_history', label: 'No History / Screened Negative'),
              ClinicalFieldOption(id: 'treated_past', label: 'Completed Treatment in Past for Active TB'),
              ClinicalFieldOption(id: 'household_contact', label: 'Known Household Contact (Under Prophylaxis)'),
              ClinicalFieldOption(id: 'unknown', label: 'Unknown / Not Formally Screened'),
            ],
            displayOrder: 1,
          ),
          const ClinicalFieldDefinition(
            fieldId: 'hepatitisScreening',
            label: 'Viral Hepatitis (Hep B & C) Status',
            description: 'Diagnostic serology screening for viral hepatitis',
            healthTier: 4,
            moduleId: 't4_infectious_travel',
            inputType: ClinicalInputType.singleChoiceRadio,
            options: [
              ClinicalFieldOption(id: 'screened_negative', label: 'Screened Negative / Vaccinated for Hep B'),
              ClinicalFieldOption(id: 'chronic_carrier', label: 'Known Chronic Carrier Under Hepatology Care'),
              ClinicalFieldOption(id: 'unknown', label: 'Unknown / Not Tested'),
            ],
            displayOrder: 2,
          ),
          const ClinicalFieldDefinition(
            fieldId: 'recentEndemicTravel',
            label: 'Recent Travel to High-Risk Endemic Regions',
            description: 'International or regional travel to malaria, yellow fever, or dengue zones in last 12 months',
            healthTier: 4,
            moduleId: 't4_infectious_travel',
            inputType: ClinicalInputType.singleChoiceRadio,
            options: [
              ClinicalFieldOption(id: 'no', label: 'No Recent Endemic Exposure'),
              ClinicalFieldOption(id: 'yes_prophylaxis', label: 'Yes, Traveled with Recommended Prophylaxis'),
              ClinicalFieldOption(id: 'yes_unprotected', label: 'Yes, Traveled without Chemoprophylaxis'),
            ],
            displayOrder: 3,
          ),
          const ClinicalFieldDefinition(
            fieldId: 'travelNotes',
            label: 'Travel Destinations & Vaccines Taken',
            description: 'Countries visited, yellow fever card, or malaria prophylaxis details',
            healthTier: 4,
            moduleId: 't4_infectious_travel',
            inputType: ClinicalInputType.multilineText,
            characterLimit: 250,
            displayOrder: 4,
          ),
        ];

      case 't4_wellness_goals':
        return [
          const ClinicalFieldDefinition(
            fieldId: 'primaryGoal',
            label: 'Primary Health & Longevity Goal',
            description: 'Personal priority for wellness over the next 12 months',
            healthTier: 4,
            moduleId: 't4_wellness_goals',
            inputType: ClinicalInputType.singleChoiceDropdown,
            options: [
              ClinicalFieldOption(id: 'weight_loss', label: 'Weight Management & Fat Reduction'),
              ClinicalFieldOption(id: 'bp_control', label: 'Optimal Blood Pressure & Cardiovascular Control'),
              ClinicalFieldOption(id: 'glucose_control', label: 'Glycemic Control & HbA1c Reduction'),
              ClinicalFieldOption(id: 'fitness_strength', label: 'Functional Strength & Aerobic Endurance'),
              ClinicalFieldOption(id: 'sleep_quality', label: 'Restorative Sleep & Circadian Rhythm Improvement'),
              ClinicalFieldOption(id: 'stress_reduction', label: 'Stress Reduction & Mental Well-being'),
            ],
            displayOrder: 1,
          ),
          const ClinicalFieldDefinition(
            fieldId: 'dailyStepsTarget',
            label: 'Daily Physical Steps Target',
            description: 'Target daily ambulatory steps (e.g. 8000 steps/day)',
            healthTier: 4,
            moduleId: 't4_wellness_goals',
            inputType: ClinicalInputType.numericMeasurement,
            unit: 'steps/day',
            validationRules: [
              ClinicalValidationRule(
                ruleId: 'VAL-STEPS-RANGE',
                min: 1000,
                max: 40000,
                errorMessage: 'Daily step target must be between 1,000 and 40,000 steps',
              ),
            ],
            displayOrder: 2,
          ),
          const ClinicalFieldDefinition(
            fieldId: 'actionPlanNotes',
            label: 'Personal Action Plan',
            description: 'Habits to implement, daily gym routine, or dietary changes',
            healthTier: 4,
            moduleId: 't4_wellness_goals',
            inputType: ClinicalInputType.multilineText,
            characterLimit: 300,
            displayOrder: 3,
          ),
        ];

      case 't4_genetics_precision':
        return [
          const ClinicalFieldDefinition(
            fieldId: 'geneticTestingDone',
            label: 'Clinical Genetic Testing History',
            description: 'Has the member completed clinical genomic or carrier screening?',
            healthTier: 4,
            moduleId: 't4_genetics_precision',
            inputType: ClinicalInputType.singleChoiceRadio,
            options: [
              ClinicalFieldOption(id: 'yes', label: 'Yes, Clinical Genetic Test Performed'),
              ClinicalFieldOption(id: 'no', label: 'No Genetic Testing Performed'),
              ClinicalFieldOption(id: 'unknown', label: 'Unknown / Not Tested'),
            ],
            displayOrder: 1,
          ),
          const ClinicalFieldDefinition(
            fieldId: 'testType',
            label: 'Test Type / Methodology',
            description: 'Classification of genetic screening performed',
            healthTier: 4,
            moduleId: 't4_genetics_precision',
            inputType: ClinicalInputType.singleChoiceDropdown,
            options: [
              ClinicalFieldOption(id: 'carrier', label: 'Reproductive Carrier Screening'),
              ClinicalFieldOption(id: 'hereditary_cancer', label: 'Hereditary Cancer Panel (BRCA, Lynch, etc.)'),
              ClinicalFieldOption(id: 'cardiac_genetics', label: 'Familial Cardiomyopathy / Arrhythmia Panel'),
              ClinicalFieldOption(id: 'pharmacogenomics', label: 'Pharmacogenomics (Drug response profiling)'),
              ClinicalFieldOption(id: 'other', label: 'Whole Exome / Diagnostic Panel'),
            ],
            conditionalParentId: 'geneticTestingDone',
            conditionalValue: 'yes',
            displayOrder: 2,
          ),
          const ClinicalFieldDefinition(
            fieldId: 'resultsSummary',
            label: 'Significant Clinical Findings / Variants',
            description: 'Pathogenic or likely pathogenic variants identified (or benign/negative)',
            healthTier: 4,
            moduleId: 't4_genetics_precision',
            inputType: ClinicalInputType.multilineText,
            characterLimit: 400,
            conditionalParentId: 'geneticTestingDone',
            conditionalValue: 'yes',
            displayOrder: 3,
          ),
        ];

      case 't4_clinical_research':
        return [
          const ClinicalFieldDefinition(
            fieldId: 'researchConsent',
            label: 'Clinical Research & Trial Preferences',
            description: 'Willingness to be notified about observational registries or approved clinical trials',
            healthTier: 4,
            moduleId: 't4_clinical_research',
            inputType: ClinicalInputType.singleChoiceRadio,
            options: [
              ClinicalFieldOption(id: 'consented_all', label: 'Yes, Interested in Approved Observational & Trial Studies'),
              ClinicalFieldOption(id: 'registry_only', label: 'Interested in Observational Registries Only (No drug trials)'),
              ClinicalFieldOption(id: 'not_interested', label: 'Not Interested in Research Studies'),
            ],
            displayOrder: 1,
          ),
          const ClinicalFieldDefinition(
            fieldId: 'preferredAreas',
            label: 'Disease Areas of Research Interest',
            description: 'e.g. Cardiology, Oncology, Diabetes, Rare Diseases, Healthy Aging',
            healthTier: 4,
            moduleId: 't4_clinical_research',
            inputType: ClinicalInputType.multilineText,
            characterLimit: 150,
            conditionalParentId: 'researchConsent',
            conditionalValue: 'consented_all',
            displayOrder: 2,
          ),
        ];

      default:
        return const [];
    }
  }

  // ================= FIELD-LEVEL VALIDATION =================

  /// Validates a single field value against its clinical definition rules and member context.
  /// Returns null if valid, or an explicit clinical error message if invalid.
  static String? validateFieldValue(
    ClinicalFieldDefinition field,
    dynamic value, {
    DateTime? memberDob,
  }) {
    // If field is marked with an explicit data state (Unknown, Not Applicable, Declined), it is valid!
    if (value is Map && value.containsKey('state')) {
      final state = value['state']?.toString().toLowerCase();
      if (state == 'unknown' || state == 'notapplicable' || state == 'declined' || state == 'notyetcollected') {
        return null;
      }
    }

    final stringVal = value is Map ? (value['value']?.toString() ?? '') : value?.toString() ?? '';
    final trimmed = stringVal.trim();

    // Required check
    if (field.requiredState && trimmed.isEmpty) {
      return '${field.label} is required. Please provide a verified value or mark as Unknown.';
    }

    if (trimmed.isEmpty) {
      return null; // Empty non-required field is permitted
    }

    // Apply specific rules
    for (final rule in field.validationRules) {
      // 1. Numeric Range
      if (field.inputType == ClinicalInputType.numericMeasurement) {
        final parsedNum = num.tryParse(trimmed);
        if (parsedNum == null) {
          return 'Please enter a valid numeric value for ${field.label}';
        }
        if (rule.min != null && parsedNum < rule.min!) {
          return rule.errorMessage;
        }
        if (rule.max != null && parsedNum > rule.max!) {
          return rule.errorMessage;
        }
      }

      // 2. Date validations
      if (field.inputType == ClinicalInputType.datePicker) {
        final parsedDate = DateTime.tryParse(trimmed);
        if (parsedDate != null) {
          final now = DateTime.now();
          if (!rule.allowFutureDates && parsedDate.isAfter(now)) {
            return rule.errorMessage.isNotEmpty
                ? rule.errorMessage
                : '${field.label} represents a past clinical event and cannot be in the future.';
          }
          if (memberDob != null && parsedDate.isBefore(memberDob)) {
            return '${field.label} cannot be earlier than the member\'s date of birth.';
          }
        }
      }

      // 3. Pattern / Regex
      if (rule.pattern != null) {
        final regex = RegExp(rule.pattern!);
        if (!regex.hasMatch(trimmed)) {
          return rule.errorMessage;
        }
      }

      // 4. Character Limit
      if (rule.maxCharacters != null && trimmed.length > rule.maxCharacters!) {
        return '${field.label} exceeds maximum allowed length of ${rule.maxCharacters} characters.';
      }
    }

    // Country-aware phone validation
    if (field.fieldId.toLowerCase().contains('phone')) {
      final phoneDigits = trimmed.replaceAll(RegExp(r'\D'), '');
      if (trimmed.startsWith('+')) {
        if (phoneDigits.length < 7 || phoneDigits.length > 15) {
          return 'Enter a valid international phone number with country code (e.g. +91 9876543210)';
        }
      } else {
        if (phoneDigits.length != 10) {
          return 'Enter a valid 10-digit phone number, or include country code with +';
        }
      }
    }

    // General character limit check
    if (field.characterLimit != null && trimmed.length > field.characterLimit!) {
      return '${field.label} cannot exceed ${field.characterLimit} characters.';
    }

    return null;
  }

  // ================= COMPLETION CALCULATION =================

  /// Calculates completion status & overall percentage based on plan and answers
  static ProfileCompletionModel calculateCompletion({
    required ClinicalCollectionPlanModel plan,
    required Map<String, dynamic> tierData,
    required Map<String, bool> consentGiven,
    required String memberId,
    required String householdId,
  }) {
    final completedSections = <String>[];
    final pendingSections = <String>[];

    final tierCounts = {1: [0, 0], 2: [0, 0], 3: [0, 0], 4: [0, 0]}; // [completed, total]

    for (final section in allSections) {
      if (plan.excludedFields.contains(section.id)) continue;

      tierCounts[section.tier]![1] += 1; // total applicable

      final hasAnswer = _isSectionAnswered(section.id, tierData);
      if (hasAnswer) {
        completedSections.add(section.id);
        tierCounts[section.tier]![0] += 1;
      } else {
        pendingSections.add(section.id);
      }
    }

    String computeTierStatus(int tier) {
      final counts = tierCounts[tier]!;
      final completed = counts[0];
      final total = counts[1];
      if (total == 0 || completed == total) return 'Completed';
      if (completed > 0) return 'In Progress';
      return 'Not Started';
    }

    final t1Status = computeTierStatus(1);
    final t2Status = computeTierStatus(2);
    final t3Status = computeTierStatus(3);
    final t4Status = computeTierStatus(4);

    int totalApplicable = 0;
    int totalCompleted = 0;
    tierCounts.forEach((_, c) {
      totalCompleted += c[0];
      totalApplicable += c[1];
    });

    final overallPct = totalApplicable > 0
        ? ((totalCompleted / totalApplicable) * 100).clamp(0.0, 100.0)
        : 0.0;

    return ProfileCompletionModel(
      memberId: memberId,
      householdId: householdId,
      overallPercentage: double.parse(overallPct.toStringAsFixed(1)),
      tier1Status: t1Status,
      tier2Status: t2Status,
      tier3Status: t3Status,
      tier4Status: t4Status,
      completedSections: completedSections,
      pendingSections: pendingSections,
      tierData: tierData,
      consentGiven: consentGiven,
      lastUpdatedAt: DateTime.now(),
    );
  }

  static bool _isSectionAnswered(String sectionId, Map<String, dynamic> tierData) {
    if (!tierData.containsKey(sectionId)) return false;
    final val = tierData[sectionId];
    if (val == null) return false;
    if (val is Map) {
      if (val.isEmpty) return false;
      final state = val['state']?.toString().toLowerCase();
      if (state == 'unknown' || state == 'notapplicable' || state == 'declined' || state == 'completed') {
        return true;
      }
      return val.values.any((v) => v != null && v.toString().trim().isNotEmpty);
    }
    return val.toString().trim().isNotEmpty;
  }
}
