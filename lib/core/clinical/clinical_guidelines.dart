import 'package:equatable/equatable.dart';

/// Represents a reliable clinical guideline or terminology reference
/// Aligned with WHO guidelines, Indian national clinical guidelines (ICMR, MoHFW, NBTC),
/// and standard medical coding systems (ICD-10/11, SNOMED CT, LOINC, ATC).
class ClinicalGuidelineReference extends Equatable {
  final String ruleId;
  final String fieldId;
  final String guidelineName;
  final String sourceRef;
  final String sourceUrl;
  final String version;
  final String publicationDate;
  final String codeSystem; // e.g. 'WHO Guideline', 'ICD-10', 'SNOMED CT', 'LOINC', 'ATC'
  final String terminologyCode;
  final String reviewStatus; // 'Approved' | 'Clinical Review Required'
  final String condition;
  final String acceptedRange;
  final String applicablePopulation;
  final String notes;

  const ClinicalGuidelineReference({
    required this.ruleId,
    required this.fieldId,
    required this.guidelineName,
    required this.sourceRef,
    this.sourceUrl = '',
    required this.version,
    required this.publicationDate,
    required this.codeSystem,
    this.terminologyCode = '',
    this.reviewStatus = 'Approved',
    required this.condition,
    required this.acceptedRange,
    this.applicablePopulation = 'All Populations',
    this.notes = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'ruleId': ruleId,
      'fieldId': fieldId,
      'guidelineName': guidelineName,
      'sourceRef': sourceRef,
      'sourceUrl': sourceUrl,
      'version': version,
      'publicationDate': publicationDate,
      'codeSystem': codeSystem,
      'terminologyCode': terminologyCode,
      'reviewStatus': reviewStatus,
      'condition': condition,
      'acceptedRange': acceptedRange,
      'applicablePopulation': applicablePopulation,
      'notes': notes,
    };
  }

  factory ClinicalGuidelineReference.fromMap(Map<String, dynamic> map) {
    return ClinicalGuidelineReference(
      ruleId: map['ruleId'] as String? ?? '',
      fieldId: map['fieldId'] as String? ?? '',
      guidelineName: map['guidelineName'] as String? ?? '',
      sourceRef: map['sourceRef'] as String? ?? '',
      sourceUrl: map['sourceUrl'] as String? ?? '',
      version: map['version'] as String? ?? '',
      publicationDate: map['publicationDate'] as String? ?? '',
      codeSystem: map['codeSystem'] as String? ?? '',
      terminologyCode: map['terminologyCode'] as String? ?? '',
      reviewStatus: map['reviewStatus'] as String? ?? 'Approved',
      condition: map['condition'] as String? ?? '',
      acceptedRange: map['acceptedRange'] as String? ?? '',
      applicablePopulation: map['applicablePopulation'] as String? ?? 'All Populations',
      notes: map['notes'] as String? ?? '',
    );
  }

  @override
  List<Object?> get props => [
        ruleId,
        fieldId,
        guidelineName,
        sourceRef,
        version,
        codeSystem,
        terminologyCode,
        reviewStatus,
      ];
}

/// Catalog of authoritative clinical guidelines and reference standards
class ClinicalGuidelinesCatalog {
  ClinicalGuidelinesCatalog._();

  static const List<ClinicalGuidelineReference> guidelines = [
    // --- TIER 1: SAFETY-CRITICAL ---
    ClinicalGuidelineReference(
      ruleId: 'GL-T1-ABO-01',
      fieldId: 'bloodGroup',
      guidelineName: 'WHO Guidelines on Blood Transfusion Services & NBTC National Standards',
      sourceRef: 'WHO Technical Report Series No. 961 & Indian NBTC Transfusion Protocol',
      sourceUrl: 'https://www.who.int/publications/i/item/9789241548090',
      version: '2021 Revision',
      publicationDate: '2021-06-15',
      codeSystem: 'LOINC',
      terminologyCode: '883-9', // ABO group [Type] in Blood
      reviewStatus: 'Approved',
      condition: 'ABO phenotyping must be verified before emergency administration',
      acceptedRange: 'A, B, AB, O, Unknown',
      applicablePopulation: 'All age groups',
      notes: 'Universal donor O-negative; universal recipient AB-positive for red blood cells.',
    ),
    ClinicalGuidelineReference(
      ruleId: 'GL-T1-RH-02',
      fieldId: 'rhFactor',
      guidelineName: 'NBTC & WHO Red Cell Antigen Standards',
      sourceRef: 'National Blood Transfusion Council Guidelines for Transfusion Safety',
      sourceUrl: 'http://nbtc.naco.gov.in',
      version: '4th Edition',
      publicationDate: '2020-03-10',
      codeSystem: 'LOINC',
      terminologyCode: '10331-7', // Rh [Type] in Blood
      reviewStatus: 'Approved',
      condition: 'Rhesus D antigen classification',
      acceptedRange: 'Positive, Negative, Unknown',
      applicablePopulation: 'All age groups',
      notes: 'Critical for transfusion compatibility and obstetrical Rh isoimmunization prevention.',
    ),
    ClinicalGuidelineReference(
      ruleId: 'GL-T1-ALL-03',
      fieldId: 'criticalAllergies',
      guidelineName: 'World Allergy Organization (WAO) Anaphylaxis Guidelines',
      sourceRef: 'WAO Journal 2020;13:100472',
      sourceUrl: 'https://www.worldallergy.org/education-and-programs/guidelines-and-consensus-statements',
      version: '2020 Update',
      publicationDate: '2020-10-30',
      codeSystem: 'SNOMED CT',
      terminologyCode: '39579001', // Anaphylaxis
      reviewStatus: 'Approved',
      condition: 'Identification of severe IgE-mediated or direct mast-cell degranulation triggers',
      acceptedRange: 'Medication, Food, Venom, Latex, Other',
      applicablePopulation: 'All age groups',
      notes: 'Emergency epinephrine auto-injector indication for anaphylactic history.',
    ),
    ClinicalGuidelineReference(
      ruleId: 'GL-T1-MED-04',
      fieldId: 'criticalMedications',
      guidelineName: 'ISMP & WHO List of High-Alert Medications',
      sourceRef: 'WHO Essential Medicines & Institute for Safe Medication Practices (ISMP)',
      sourceUrl: 'https://www.ismp.org/recommendations/high-alert-medications-acute-list',
      version: '2022 Edition',
      publicationDate: '2022-01-12',
      codeSystem: 'ATC',
      terminologyCode: 'A10A, B01A, C01', // Insulins, Antithrombotics, Cardiac therapy
      reviewStatus: 'Approved',
      condition: 'Prescription-only details: dosage, strength, route, frequency',
      acceptedRange: 'Active prescription details with valid clinical route',
      applicablePopulation: 'All age groups',
      notes: 'High-risk medications with heightened risk of significant patient harm when misused.',
    ),
    ClinicalGuidelineReference(
      ruleId: 'GL-T1-DEV-05',
      fieldId: 'implantedDevices',
      guidelineName: 'FDA & CDSCO Medical Device Safety & MRI Compatibility Guidelines',
      sourceRef: 'Central Drugs Standard Control Organisation (CDSCO) & FDA Safety Alerts',
      sourceUrl: 'https://cdsco.gov.in',
      version: '2021 Update',
      publicationDate: '2021-08-01',
      codeSystem: 'SNOMED CT',
      terminologyCode: '257367000', // Cardiac pacemaker
      reviewStatus: 'Approved',
      condition: 'Mandatory documentation for MRI conditioning and electromagnetic interference',
      acceptedRange: 'Pacemaker, ICD, Stent, Insulin pump, VP shunt, Metal implant, Other',
      applicablePopulation: 'All age groups',
      notes: 'Determines emergency defib placement and imaging contraindications.',
    ),

    // --- TIER 2: CORE HEALTH RECORD ---
    ClinicalGuidelineReference(
      ruleId: 'GL-T2-BP-01',
      fieldId: 'bloodPressureSystolic',
      guidelineName: 'WHO Guideline on Pharmacological Treatment of Hypertension & Indian Hypertension Guidelines (IHG-IV)',
      sourceRef: 'WHO Guidelines Approved by the Guidelines Review Committee (2021) & IHG-IV',
      sourceUrl: 'https://www.who.int/publications/i/item/9789240033986',
      version: '2021 Edition',
      publicationDate: '2021-08-25',
      codeSystem: 'LOINC',
      terminologyCode: '8480-6', // Systolic blood pressure
      reviewStatus: 'Approved',
      condition: 'Systolic blood pressure measurement in seated resting adult',
      acceptedRange: '70 - 250 mmHg (Optimal <120, Normal 120-129, Stage 1 HTN 130-139, Stage 2 >=140)',
      applicablePopulation: 'Adults and adolescents (12+)',
      notes: 'Values < 70 or > 250 require immediate clinical verification.',
    ),
    ClinicalGuidelineReference(
      ruleId: 'GL-T2-BP-02',
      fieldId: 'bloodPressureDiastolic',
      guidelineName: 'WHO Guideline on Hypertension & Indian Guidelines on Hypertension (IHG-IV)',
      sourceRef: 'WHO Guidelines (2021) & Journal of the Association of Physicians of India',
      sourceUrl: 'https://www.who.int/publications/i/item/9789240033986',
      version: '2021 Edition',
      publicationDate: '2021-08-25',
      codeSystem: 'LOINC',
      terminologyCode: '8462-4', // Diastolic blood pressure
      reviewStatus: 'Approved',
      condition: 'Diastolic blood pressure in resting subject',
      acceptedRange: '40 - 150 mmHg (Optimal <80, Normal 80-84, Stage 1 HTN 85-89, Stage 2 >=90)',
      applicablePopulation: 'Adults and adolescents (12+)',
      notes: 'Must be lower than systolic pressure.',
    ),
    ClinicalGuidelineReference(
      ruleId: 'GL-T2-HR-03',
      fieldId: 'restingHeartRate',
      guidelineName: 'AHA / WHO Clinical Guidelines on Resting Heart Rate Evaluation',
      sourceRef: 'American Heart Association / WHO Cardiovascular Risk Assessment',
      sourceUrl: 'https://www.heart.org/en/health-topics/high-blood-pressure',
      version: '2020 Update',
      publicationDate: '2020-05-18',
      codeSystem: 'LOINC',
      terminologyCode: '8867-4', // Heart rate
      reviewStatus: 'Approved',
      condition: 'Resting pulse rate taken over 60 seconds',
      acceptedRange: '40 - 200 bpm (Normal adult resting: 60 - 100 bpm)',
      applicablePopulation: 'All age groups (infants baseline 100-160, adults 60-100)',
      notes: 'Athletes may normally present with bradycardia (40-59 bpm).',
    ),
    ClinicalGuidelineReference(
      ruleId: 'GL-T2-BMI-04',
      fieldId: 'bodyMassIndex',
      guidelineName: 'WHO Asian & Global BMI Classification Criteria / ICMR Consensus Guidelines',
      sourceRef: 'WHO Expert Consultation & ICMR Guidelines for Prevention of Obesity in India',
      sourceUrl: 'https://www.who.int/europe/news-room/fact-sheets/detail/a-healthy-lifestyle---who-recommendations',
      version: '2020 Consensus',
      publicationDate: '2020-04-10',
      codeSystem: 'LOINC',
      terminologyCode: '39156-5', // Body mass index
      reviewStatus: 'Approved',
      condition: 'Calculated from verified height (cm) and weight (kg): Weight(kg) / [Height(m)]^2',
      acceptedRange: '10.0 - 70.0 kg/m² (Asian cutoffs: Normal 18.5-22.9, Overweight 23.0-24.9, Obese >=25.0)',
      applicablePopulation: 'Adults (18+)',
      notes: 'Lower BMI cut-offs apply to South Asian populations due to increased visceral adiposity.',
    ),
    ClinicalGuidelineReference(
      ruleId: 'GL-T2-IMM-05',
      fieldId: 'immunizations',
      guidelineName: 'WHO Immunization Agenda 2030 & National Immunization Schedule (UIP India)',
      sourceRef: 'Ministry of Health and Family Welfare (MoHFW) India & WHO Vaccine Protocols',
      sourceUrl: 'https://nhm.gov.in/index1.php?lang=1&level=2&sublinkid=824&lid=220',
      version: '2023 Guidelines',
      publicationDate: '2023-01-01',
      codeSystem: 'SNOMED CT',
      terminologyCode: '33879002', // Immunization
      reviewStatus: 'Approved',
      condition: 'Standard universal childhood & adult booster vaccines',
      acceptedRange: 'Recognized vaccines: BCG, HepB, OPV, Pentavalent, Rotavirus, PCV, MR, Td, HPV, Influenza, COVID-19',
      applicablePopulation: 'All age groups',
      notes: 'Aligned with Universal Immunization Programme (UIP) India and WHO recommendations.',
    ),
    ClinicalGuidelineReference(
      ruleId: 'GL-T2-GLU-06',
      fieldId: 'bloodGlucoseFasting',
      guidelineName: 'WHO / International Diabetes Federation (IDF) & ICMR Diabetes Guidelines',
      sourceRef: 'ICMR Guidelines for Management of Type 2 Diabetes 2023 & WHO Diagnostic Criteria',
      sourceUrl: 'https://www.icmr.nic.in',
      version: '2023 Edition',
      publicationDate: '2023-03-20',
      codeSystem: 'LOINC',
      terminologyCode: '1558-6', // Fasting glucose [Mass/volume] in Blood
      reviewStatus: 'Approved',
      condition: 'Plasma glucose measured after minimum 8-hour overnight fast',
      acceptedRange: '40 - 500 mg/dL (Normal <100, Impaired Fasting Glucose 100-125, Diabetes >=126)',
      applicablePopulation: 'All age groups',
      notes: 'Diagnostic criteria require confirmatory repeat testing.',
    ),

    // --- TIER 3: LONGITUDINAL & LIFE-STAGE ---
    ClinicalGuidelineReference(
      ruleId: 'GL-T3-PA-01',
      fieldId: 'physicalActivity',
      guidelineName: 'WHO Guidelines on Physical Activity and Sedentary Behaviour',
      sourceRef: 'WHO Guidelines Approved by the Guidelines Review Committee (2020)',
      sourceUrl: 'https://www.who.int/publications/i/item/9789240015128',
      version: '2020 Guidelines',
      publicationDate: '2020-11-25',
      codeSystem: 'LOINC',
      terminologyCode: '55423-8', // Physical activity
      reviewStatus: 'Approved',
      condition: 'Adult recommendation: at least 150-300 min moderate or 75-150 min vigorous aerobic activity/week',
      acceptedRange: 'Sedentary, Light (1-2 d/wk), Moderate (3-4 d/wk), Active (5+ d/wk), Vigorous daily',
      applicablePopulation: 'Adolescents, adults, and older adults',
      notes: 'Muscle-strengthening activities recommended on 2 or more days a week.',
    ),
    ClinicalGuidelineReference(
      ruleId: 'GL-T3-SLP-02',
      fieldId: 'sleepHours',
      guidelineName: 'AASM & National Sleep Foundation Clinical Recommendations',
      sourceRef: 'Journal of Clinical Sleep Medicine 2015;11(6):591–592',
      sourceUrl: 'https://aasm.org',
      version: 'Consensus Statement',
      publicationDate: '2015-06-15',
      codeSystem: 'LOINC',
      terminologyCode: '93832-4', // Sleep duration
      reviewStatus: 'Approved',
      condition: 'Self-reported nocturnal sleep duration',
      acceptedRange: '3.0 - 16.0 hours (Recommended adult: 7 - 9 hours; Adolescent: 8 - 10 hours)',
      applicablePopulation: 'All age groups',
      notes: 'Chronic sleep duration <6 or >10 hours associated with elevated cardiometabolic risk.',
    ),
    ClinicalGuidelineReference(
      ruleId: 'GL-T3-PED-03',
      fieldId: 'pediatricBirthWeight',
      guidelineName: 'WHO Child Growth Standards & Neonatal Health Guidelines',
      sourceRef: 'WHO Child Growth Standards: Methods and Development',
      sourceUrl: 'https://www.who.int/tools/child-growth-standards',
      version: '2022 Update',
      publicationDate: '2022-04-12',
      codeSystem: 'LOINC',
      terminologyCode: '8339-4', // Birth weight
      reviewStatus: 'Approved',
      condition: 'Weight documented within 1 hour of birth',
      acceptedRange: '0.5 - 6.5 kg (Low birth weight <2.5 kg, Normal 2.5 - 4.0 kg)',
      applicablePopulation: 'Pediatric (under 12 years)',
      notes: 'Key indicator of gestational growth and perinatal health.',
    ),
    ClinicalGuidelineReference(
      ruleId: 'GL-T3-GER-04',
      fieldId: 'geriatricFallRisk',
      guidelineName: 'World Guidelines for Falls Prevention and Management for Older Adults',
      sourceRef: 'Age and Ageing 2022; 51:1-36',
      sourceUrl: 'https://academic.oup.com/ageing/article/51/9/afac205/6730755',
      version: '2022 Global Guidelines',
      publicationDate: '2022-09-29',
      codeSystem: 'SNOMED CT',
      terminologyCode: '129839007', // At risk for falls
      reviewStatus: 'Approved',
      condition: 'Assessment of fall history in past 12 months, gait speed, and assistive device reliance',
      acceptedRange: 'Low Risk (0 falls), Moderate Risk (1 non-injurious fall), High Risk (>=2 falls or injurious fall)',
      applicablePopulation: 'Geriatric (65+ years)',
      notes: 'Universal screening recommendation for all adults aged 65 and older.',
    ),

    // --- TIER 4: ADVANCED & CONTEXTUAL (CONSENT-CONTROLLED) ---
    ClinicalGuidelineReference(
      ruleId: 'GL-T4-MH-01',
      fieldId: 'moodScreening',
      guidelineName: 'WHO Mental Health Gap Action Programme (mhGAP) & PHQ-2 Screening Standard',
      sourceRef: 'WHO mhGAP Intervention Guide Version 2.0 & Kroenke et al. Med Care 2003',
      sourceUrl: 'https://www.who.int/publications/i/item/9789241549790',
      version: 'mhGAP v2.0',
      publicationDate: '2019-10-10',
      codeSystem: 'LOINC',
      terminologyCode: '55758-7', // Patient Health Questionnaire 2 item (PHQ-2)
      reviewStatus: 'Approved',
      condition: 'Two-question screener for depressed mood and anhedonia in the past 2 weeks (Consent-Gated)',
      acceptedRange: 'Score 0 - 6 (Cut-off >=3 warrants comprehensive clinical assessment)',
      applicablePopulation: 'Adolescent, adult, geriatric',
      notes: 'Sensitive question requiring explicit user consent before rendering and collection.',
    ),
    ClinicalGuidelineReference(
      ruleId: 'GL-T4-SUB-02',
      fieldId: 'tobaccoUse',
      guidelineName: 'WHO Framework Convention on Tobacco Control (FCTC) Guidelines',
      sourceRef: 'WHO Report on the Global Tobacco Epidemic',
      sourceUrl: 'https://www.who.int/teams/health-promotion/tobacco-control',
      version: '2021 Edition',
      publicationDate: '2021-07-27',
      codeSystem: 'SNOMED CT',
      terminologyCode: '77176002', // Smoker
      reviewStatus: 'Approved',
      condition: 'Current, former, or never smoker classification and pack-year calculation',
      acceptedRange: 'Never, Former Smoker, Current Light (<10/day), Current Moderate (10-20/day), Current Heavy (>20/day)',
      applicablePopulation: 'Adults and adolescents (consented)',
      notes: 'Consent required; essential for cardiovascular and respiratory risk stratification.',
    ),
    ClinicalGuidelineReference(
      ruleId: 'GL-T4-AUD-03',
      fieldId: 'alcoholFrequency',
      guidelineName: 'WHO Alcohol Use Disorders Identification Test (AUDIT-C)',
      sourceRef: 'WHO The Alcohol Use Disorders Identification Test: Guidelines for Use in Primary Care',
      sourceUrl: 'https://www.who.int/publications/i/item/WHO-MSD-MSB-01.6a',
      version: '2nd Edition',
      publicationDate: '2020-02-15',
      codeSystem: 'LOINC',
      terminologyCode: '75626-2', // AUDIT-C score
      reviewStatus: 'Approved',
      condition: 'Brief screening for hazardous alcohol consumption (Consent-Gated)',
      acceptedRange: 'Never, Monthly or less, 2-4 times a month, 2-3 times a week, 4+ times a week',
      applicablePopulation: 'Adults (18+)',
      notes: 'Scores above clinical thresholds suggest advisory discussion with primary physician.',
    ),
  ];

  static ClinicalGuidelineReference? getGuidelineForField(String fieldId) {
    for (final g in guidelines) {
      if (g.fieldId.toLowerCase() == fieldId.toLowerCase()) {
        return g;
      }
    }
    return null;
  }

  static ClinicalGuidelineReference? getGuidelineByRuleId(String ruleId) {
    for (final g in guidelines) {
      if (g.ruleId.toLowerCase() == ruleId.toLowerCase()) {
        return g;
      }
    }
    return null;
  }
}

