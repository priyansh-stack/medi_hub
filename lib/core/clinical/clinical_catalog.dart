import 'clinical_field_definition.dart';

/// Master catalog of clinically validated medical terminology and options.
/// Sourced from WHO Essential Medicines, ICD-10/11, SNOMED CT, LOINC, and
/// Indian clinical guidelines (NBTC, ICMR, UIP MoHFW).
class ClinicalCatalog {
  ClinicalCatalog._();

  // ================= TIER 1: SAFETY-CRITICAL CATALOGS =================

  /// ABO Blood Group Options
  static const List<ClinicalFieldOption> bloodGroupsABO = [
    ClinicalFieldOption(id: 'A', label: 'Blood Group A', code: 'A', description: 'Antigen A present on RBCs'),
    ClinicalFieldOption(id: 'B', label: 'Blood Group B', code: 'B', description: 'Antigen B present on RBCs'),
    ClinicalFieldOption(id: 'AB', label: 'Blood Group AB', code: 'AB', description: 'Antigens A & B present (Universal RBC recipient)'),
    ClinicalFieldOption(id: 'O', label: 'Blood Group O', code: 'O', description: 'Neither A nor B antigen present (Universal RBC donor if Rh-)'),
    ClinicalFieldOption(id: 'Unknown', label: 'Unknown / Not Tested', code: 'UNK', description: 'Blood group not yet laboratory confirmed'),
  ];

  /// Rh Factor Options
  static const List<ClinicalFieldOption> rhFactors = [
    ClinicalFieldOption(id: 'Positive', label: 'Rh Positive (Rh+)', code: 'Rh+', description: 'Rhesus D antigen present'),
    ClinicalFieldOption(id: 'Negative', label: 'Rh Negative (Rh-)', code: 'Rh-', description: 'Rhesus D antigen absent'),
    ClinicalFieldOption(id: 'Unknown', label: 'Unknown / Not Tested', code: 'UNK', description: 'Rh factor not yet tested'),
  ];

  /// Blood Group Verification Status
  static const List<ClinicalFieldOption> bloodVerificationStatuses = [
    ClinicalFieldOption(id: 'lab_confirmed', label: 'Laboratory Confirmed', description: 'Verified via pathology diagnostic report'),
    ClinicalFieldOption(id: 'donor_card', label: 'Govt / Blood Donor Card', description: 'Issued by licensed blood bank or hospital'),
    ClinicalFieldOption(id: 'hospital_discharge', label: 'Hospital Discharge Summary', description: 'Documented during clinical encounter'),
    ClinicalFieldOption(id: 'self_reported', label: 'Self Reported / Family Known', description: 'Known by individual, awaiting lab confirmation'),
    ClinicalFieldOption(id: 'unverified', label: 'Unverified / Preliminary', description: 'Needs lab verification before emergency procedure'),
  ];

  /// Allergy Categories
  static const List<ClinicalFieldOption> allergyCategories = [
    ClinicalFieldOption(id: 'medication', label: 'Medication / Drug Allergy', description: 'Antibiotics, NSAIDs, anesthetics, etc.'),
    ClinicalFieldOption(id: 'food', label: 'Food Allergy', description: 'Nuts, dairy, seafood, eggs, etc.'),
    ClinicalFieldOption(id: 'environmental', label: 'Environmental / Inhalant Allergy', description: 'Pollen, dust mites, mold, animal dander'),
    ClinicalFieldOption(id: 'insect_venom', label: 'Insect Venom Allergy', description: 'Bee sting, wasp venom, hornet'),
    ClinicalFieldOption(id: 'latex', label: 'Latex / Contact Allergy', description: 'Natural rubber latex, nickel, chemical contact'),
    ClinicalFieldOption(id: 'other', label: 'Other Specified Allergy', description: 'Requires additional detail specification'),
  ];

  /// Common Predefined Allergens (Searchable with SNOMED CT codes)
  static const List<ClinicalFieldOption> allergens = [
    // Medications
    ClinicalFieldOption(id: 'penicillin', label: 'Penicillin', code: '70618006', description: 'Beta-lactam antibiotic allergy'),
    ClinicalFieldOption(id: 'amoxicillin', label: 'Amoxicillin', code: '372687004', description: 'Aminopenicillin antibiotic'),
    ClinicalFieldOption(id: 'cephalosporins', label: 'Cephalosporins (Cefixime, Ceftriaxone)', code: '372833007', description: 'Cephalosporin class'),
    ClinicalFieldOption(id: 'sulfa_drugs', label: 'Sulfonamides / Sulfa Drugs (Co-trimoxazole)', code: '91175000', description: 'Sulfa antibiotic allergy'),
    ClinicalFieldOption(id: 'nsaids_aspirin', label: 'Aspirin & NSAIDs (Ibuprofen, Diclofenac)', code: '387458008', description: 'Non-steroidal anti-inflammatory drugs'),
    ClinicalFieldOption(id: 'fluoroquinolones', label: 'Fluoroquinolones (Ciprofloxacin, Levofloxacin)', code: '372836004', description: 'Quinolone antibiotic class'),
    ClinicalFieldOption(id: 'contrast_media', label: 'Radiological Iodinated Contrast Media', code: '293637006', description: 'CT / angiography contrast reactions'),
    ClinicalFieldOption(id: 'local_anesthetics', label: 'Local Anesthetics (Lignocaine, Bupivacaine)', code: '387207008', description: 'Local anesthetic agents'),

    // Foods
    ClinicalFieldOption(id: 'peanuts', label: 'Peanuts / Groundnuts', code: '256349002', description: 'Legume allergen with high anaphylaxis risk'),
    ClinicalFieldOption(id: 'tree_nuts', label: 'Tree Nuts (Almond, Walnut, Cashew, Pistachio)', code: '91935009', description: 'Arboreal nut allergens'),
    ClinicalFieldOption(id: 'shellfish', label: 'Shellfish & Crustaceans (Prawn, Crab, Shrimp)', code: '227037002', description: 'Marine invertebrate tropomyosin allergy'),
    ClinicalFieldOption(id: 'cows_milk', label: 'Cow\'s Milk Protein', code: '256329007', description: 'Casein and whey protein allergy'),
    ClinicalFieldOption(id: 'eggs', label: 'Hen\'s Eggs', code: '256345008', description: 'Ovalbumin / ovomucoid allergy'),
    ClinicalFieldOption(id: 'wheat_gluten', label: 'Wheat / Gluten', code: '256330002', description: 'Wheat IgE allergy (distinct from Celiac disease)'),
    ClinicalFieldOption(id: 'soy', label: 'Soybeans / Soy Products', code: '256350002', description: 'Soy protein allergen'),

    // Inhalant & Venom
    ClinicalFieldOption(id: 'dust_mites', label: 'House Dust Mites (Dermatophagoides)', code: '260147004', description: 'Perennial aeroallergen'),
    ClinicalFieldOption(id: 'pollen', label: 'Grass & Tree Pollen', code: '256259004', description: 'Seasonal allergic rhinitis / asthma trigger'),
    ClinicalFieldOption(id: 'bee_venom', label: 'Honeybee / Wasp Venom', code: '256440004', description: 'Hymenoptera sting severe anaphylaxis risk'),
    ClinicalFieldOption(id: 'latex_rubber', label: 'Natural Rubber Latex', code: '300916003', description: 'Contact and aerosolized latex allergy'),
  ];

  /// Allergy Reaction Manifestations
  static const List<ClinicalFieldOption> allergyReactions = [
    ClinicalFieldOption(id: 'anaphylaxis', label: 'Anaphylaxis (Systemic / Shock)', code: '39579001', description: 'Severe airway or circulatory compromise'),
    ClinicalFieldOption(id: 'angioedema', label: 'Angioedema (Lip, Tongue, Face Swelling)', code: '41291007', description: 'Submucosal / deep dermal swelling'),
    ClinicalFieldOption(id: 'urticaria', label: 'Urticaria / Hives / Intense Itching', code: '126485001', description: 'Pruritic erythematous wheals'),
    ClinicalFieldOption(id: 'bronchospasm', label: 'Bronchospasm / Wheezing / Shortness of Breath', code: '4386001', description: 'Acute lower airway constriction'),
    ClinicalFieldOption(id: 'rash', label: 'Maculopapular Skin Rash / Erythema', code: '271807003', description: 'Widespread non-wheal cutaneous eruption'),
    ClinicalFieldOption(id: 'gi_upset', label: 'Severe Vomiting, Diarrhea, Abdominal Cramps', code: '422400008', description: 'Acute gastrointestinal allergic response'),
    ClinicalFieldOption(id: 'rhinitis', label: 'Allergic Rhinitis / Sneezing / Watery Eyes', code: '82272006', description: 'Upper respiratory allergy manifestations'),
  ];

  /// Clinical Severity Scale
  static const List<ClinicalFieldOption> severities = [
    ClinicalFieldOption(id: 'mild', label: 'Mild', description: 'Transient, localized symptoms; minimal discomfort; no systemic effect'),
    ClinicalFieldOption(id: 'moderate', label: 'Moderate', description: 'Generalized symptoms; impairs normal activity; requires symptomatic medication'),
    ClinicalFieldOption(id: 'severe', label: 'Severe', description: 'Incapacitating; intense symptoms; potential organ involvement; emergency care indicated'),
    ClinicalFieldOption(id: 'life_threatening', label: 'Life-Threatening / Anaphylactic', description: 'Acute risk to life; airway constriction, hypotension, resuscitation required'),
  ];

  /// High-Risk / Emergency Critical Medications (WHO Essential Medicines & Indian NLEM)
  static const List<ClinicalFieldOption> criticalMedications = [
    ClinicalFieldOption(id: 'insulin_regular', label: 'Insulin (Regular / Soluble Human)', code: 'A10AB01', description: 'Short-acting pancreatic hormone'),
    ClinicalFieldOption(id: 'insulin_glargine', label: 'Insulin Glargine (Lantus / Basalog)', code: 'A10AE04', description: 'Long-acting basal analog'),
    ClinicalFieldOption(id: 'warfarin', label: 'Warfarin Sodium', code: 'B01AA03', description: 'Vitamin K antagonist anticoagulant (INR monitoring required)'),
    ClinicalFieldOption(id: 'apixaban', label: 'Apixaban (Eliquis)', code: 'B01AF02', description: 'Direct Factor Xa inhibitor DOAC'),
    ClinicalFieldOption(id: 'rivaroxaban', label: 'Rivaroxaban (Xarelto)', code: 'B01AF01', description: 'Direct Factor Xa inhibitor DOAC'),
    ClinicalFieldOption(id: 'clopidogrel', label: 'Clopidogrel (Plavix / Deplatt)', code: 'B01AC04', description: 'Antiplatelet agent for arterial thrombosis'),
    ClinicalFieldOption(id: 'aspirin_cardio', label: 'Aspirin (Ecosprin / Low Dose 75-150mg)', code: 'B01AC06', description: 'Cardioprotective antiplatelet'),
    ClinicalFieldOption(id: 'epinephrine_pen', label: 'Epinephrine Auto-Injector (EpiPen / Adrenaline)', code: 'C01CA24', description: 'Emergency sympathomimetic for anaphylaxis'),
    ClinicalFieldOption(id: 'digoxin', label: 'Digoxin', code: 'C01AA05', description: 'Cardiac glycoside for heart failure / atrial fibrillation'),
    ClinicalFieldOption(id: 'amiodarone', label: 'Amiodarone', code: 'C01BD01', description: 'Class III antiarrhythmic agent'),
    ClinicalFieldOption(id: 'nitroglycerin_sl', label: 'Glyceryl Trinitrate / Nitroglycerin (SL)', code: 'C01DA02', description: 'Sublingual vasodilator for acute angina'),
    ClinicalFieldOption(id: 'salbutamol_inh', label: 'Salbutamol / Albuterol Inhaler (Asthalin)', code: 'R03AC02', description: 'Short-acting beta-2 agonist bronchodilator'),
    ClinicalFieldOption(id: 'budesonide_formoterol', label: 'Budesonide + Formoterol (Budecort / Foracort)', code: 'R03AK07', description: 'Inhaled corticosteroid + LABA maintenance'),
    ClinicalFieldOption(id: 'levothyroxine', label: 'Levothyroxine Sodium (Thyronorm / Eltroxin)', code: 'H03AA01', description: 'Synthetic thyroid hormone replacement'),
    ClinicalFieldOption(id: 'phenytoin', label: 'Phenytoin Sodium (Eptoin)', code: 'N03AB02', description: 'Anticonvulsant for tonic-clonic seizures'),
    ClinicalFieldOption(id: 'levetiracetam', label: 'Levetiracetam (Keppra / Levera)', code: 'N03AX14', description: 'Second-generation broad-spectrum antiepileptic'),
    ClinicalFieldOption(id: 'prednisolone', label: 'Prednisolone / Methylprednisolone', code: 'H02AB06', description: 'Systemic glucocorticoid anti-inflammatory'),
    ClinicalFieldOption(id: 'amlodipine', label: 'Amlodipine (Norvasc / Stamlo)', code: 'C08CA01', description: 'Dihydropyridine calcium channel blocker'),
    ClinicalFieldOption(id: 'telmisartan', label: 'Telmisartan (Telma / Micardis)', code: 'C09CA07', description: 'Angiotensin II receptor blocker (ARB)'),
    ClinicalFieldOption(id: 'metformin', label: 'Metformin Hydrochloride (Glycomet)', code: 'A10BA02', description: 'Biguanide first-line oral antidiabetic'),
  ];

  /// Dosage Forms
  static const List<ClinicalFieldOption> dosageForms = [
    ClinicalFieldOption(id: 'tablet', label: 'Tablet (Oral)', description: 'Solid compressed dose'),
    ClinicalFieldOption(id: 'capsule', label: 'Capsule (Oral)', description: 'Gelatin/plant shell containing powder or oil'),
    ClinicalFieldOption(id: 'inhaler_mdi', label: 'Metered Dose Inhaler (MDI)', description: 'Pressurized aerosol for inhalation'),
    ClinicalFieldOption(id: 'inhaler_dpi', label: 'Dry Powder Inhaler (DPI / Rotahaler)', description: 'Breath-actuated dry powder'),
    ClinicalFieldOption(id: 'injection_sc', label: 'Subcutaneous Pen / Syringe', description: 'Injected into adipose layer'),
    ClinicalFieldOption(id: 'injection_iv', label: 'Intravenous (IV) Infusion / Injection', description: 'Direct vascular administration'),
    ClinicalFieldOption(id: 'syrup_liquid', label: 'Syrup / Oral Solution', description: 'Pediatric or liquid dosage form'),
    ClinicalFieldOption(id: 'sublingual_tab', label: 'Sublingual Tablet / Spray', description: 'Dissolved under tongue for rapid absorption'),
    ClinicalFieldOption(id: 'topical_cream', label: 'Topical Cream / Ointment', description: 'Applied to dermal area'),
    ClinicalFieldOption(id: 'transdermal_patch', label: 'Transdermal Patch', description: 'Systemic absorption through skin'),
    ClinicalFieldOption(id: 'eye_ear_drops', label: 'Ophthalmic / Otic Drops', description: 'Instilled into eye or ear canal'),
  ];

  /// Medication Routes
  static const List<ClinicalFieldOption> medicationRoutes = [
    ClinicalFieldOption(id: 'oral', label: 'Oral (PO)', description: 'By mouth'),
    ClinicalFieldOption(id: 'subcutaneous', label: 'Subcutaneous (SC)', description: 'Under skin layer'),
    ClinicalFieldOption(id: 'inhalation', label: 'Inhalation (INH)', description: 'Inhaled into lungs'),
    ClinicalFieldOption(id: 'sublingual', label: 'Sublingual (SL)', description: 'Under tongue'),
    ClinicalFieldOption(id: 'intravenous', label: 'Intravenous (IV)', description: 'Directly into vein'),
    ClinicalFieldOption(id: 'intramuscular', label: 'Intramuscular (IM)', description: 'Into muscle tissue'),
    ClinicalFieldOption(id: 'transdermal', label: 'Transdermal', description: 'Through skin patch'),
    ClinicalFieldOption(id: 'topical', label: 'Topical', description: 'Local skin application'),
    ClinicalFieldOption(id: 'ophthalmic', label: 'Ophthalmic', description: 'Ocular installation'),
  ];

  /// Medication Frequencies
  static const List<ClinicalFieldOption> medicationFrequencies = [
    ClinicalFieldOption(id: 'OD', label: 'Once Daily (OD)', description: 'Every 24 hours (morning or night)'),
    ClinicalFieldOption(id: 'BD', label: 'Twice Daily (BD / BID)', description: 'Every 12 hours (morning and evening)'),
    ClinicalFieldOption(id: 'TDS', label: 'Three Times Daily (TDS / TID)', description: 'Every 8 hours'),
    ClinicalFieldOption(id: 'QDS', label: 'Four Times Daily (QDS / QID)', description: 'Every 6 hours'),
    ClinicalFieldOption(id: 'PRN', label: 'As Needed (PRN)', description: 'Only when symptoms arise, respecting maximum daily dose'),
    ClinicalFieldOption(id: 'QWK', label: 'Once Weekly', description: 'One specific day per week (e.g. Methotrexate, Vitamin D)'),
    ClinicalFieldOption(id: 'STAT', label: 'Single Emergency Dose (STAT)', description: 'Immediate one-time administration'),
  ];

  /// Critical Medical Conditions (ICD-10 Coded)
  static const List<ClinicalFieldOption> criticalConditions = [
    ClinicalFieldOption(id: 't1dm', label: 'Type 1 Diabetes Mellitus', code: 'E10', description: 'Insulin-dependent; acute ketoacidosis risk'),
    ClinicalFieldOption(id: 'severe_asthma', label: 'Severe Persistent Asthma / Brittle Asthma', code: 'J45.5', description: 'Frequent acute exacerbations, emergency steroid/bronchodilator dependent'),
    ClinicalFieldOption(id: 'epilepsy', label: 'Epilepsy / Recurrent Seizure Disorder', code: 'G40', description: 'Risk of status epilepticus and post-ictal state'),
    ClinicalFieldOption(id: 'cad_angina', label: 'Coronary Artery Disease / Angina Pectoris', code: 'I25.1', description: 'Prior myocardial infarction or severe arterial occlusion'),
    ClinicalFieldOption(id: 'heart_failure', label: 'Congestive Heart Failure (NYHA Class II-IV)', code: 'I50', description: 'Reduced ejection fraction; acute pulmonary edema risk'),
    ClinicalFieldOption(id: 'ckd_severe', label: 'Chronic Kidney Disease (Stage 4 or 5 / Dialysis)', code: 'N18.5', description: 'eGFR < 30 mL/min; fluid & electrolyte sensitivity'),
    ClinicalFieldOption(id: 'stroke_tia', label: 'Prior Ischemic / Hemorrhagic Stroke or TIA', code: 'I63', description: 'Cerebrovascular event history; neurological deficits'),
    ClinicalFieldOption(id: 'adrenal_insufficiency', label: 'Severe Adrenal Insufficiency / Addison\'s Disease', code: 'E27.4', description: 'Adrenal crisis risk under physiologic stress; emergency hydrocortisone indication'),
    ClinicalFieldOption(id: 'bleeding_disorder', label: 'Hemophilia or Severe Coagulopathy', code: 'D66', description: 'Factor VIII/IX deficiency or severe thrombocytopenia'),
    ClinicalFieldOption(id: 'cardiac_arrhythmia', label: 'Ventricular Tachycardia / Long QT Syndrome', code: 'I49', description: 'High acuity malignant ventricular dysrhythmia risk'),
  ];

  /// Implanted Devices Categories (SNOMED CT Aligned)
  static const List<ClinicalFieldOption> deviceCategories = [
    ClinicalFieldOption(id: 'pacemaker', label: 'Cardiac Pacemaker (Single / Dual Chamber)', code: '257367000', description: 'Rhythm management implant'),
    ClinicalFieldOption(id: 'icd', label: 'Implantable Cardioverter Defibrillator (ICD / CRT-D)', code: '72506001', description: 'Sudden cardiac death prevention device'),
    ClinicalFieldOption(id: 'stent', label: 'Coronary / Vascular Stent (Drug-Eluting / Bare Metal)', code: '360046005', description: 'Endovascular arterial scaffolding'),
    ClinicalFieldOption(id: 'insulin_pump', label: 'Continuous Subcutaneous Insulin Pump (CSII)', code: '462529007', description: 'Continuous basal/bolus infusion device'),
    ClinicalFieldOption(id: 'vp_shunt', label: 'Ventriculoperitoneal (VP) Shunt', code: '257321008', description: 'Hydrocephalus CSF diversion device (magnetic valve risk)'),
    ClinicalFieldOption(id: 'cochlear', label: 'Cochlear Implant', code: '72506001', description: 'Auditory neuroprosthetic device'),
    ClinicalFieldOption(id: 'ortho_implant', label: 'Orthopedic Prosthesis (Hip / Knee Replacement, Rods, Plates)', code: '303619004', description: 'Joint replacement or internal fixation hardware'),
    ClinicalFieldOption(id: 'iud', label: 'Intrauterine Device (Copper / Levonorgestrel IUD)', code: '67956000', description: 'Intrauterine contraceptive implant'),
    ClinicalFieldOption(id: 'neurostimulator', label: 'Deep Brain / Spinal Cord Neurostimulator', code: '257388002', description: 'Implanted electrical neuromodulation device'),
    ClinicalFieldOption(id: 'heart_valve', label: 'Prosthetic Heart Valve (Mechanical / Tissue)', code: '399248000', description: 'Surgical or transcatheter valve replacement'),
    ClinicalFieldOption(id: 'other', label: 'Other Metallic or Electronic Implant', description: 'Specify manufacturer, model, and MRI conditionality'),
  ];

  /// Emergency Contact Relationships
  static const List<ClinicalFieldOption> contactRelationships = [
    ClinicalFieldOption(id: 'Spouse', label: 'Spouse / Partner'),
    ClinicalFieldOption(id: 'Parent', label: 'Parent / Mother / Father'),
    ClinicalFieldOption(id: 'Child', label: 'Son / Daughter'),
    ClinicalFieldOption(id: 'Sibling', label: 'Brother / Sister'),
    ClinicalFieldOption(id: 'Guardian', label: 'Legal Guardian'),
    ClinicalFieldOption(id: 'Caregiver', label: 'Primary Caregiver / Attendant'),
    ClinicalFieldOption(id: 'Friend', label: 'Close Friend / Neighbor'),
    ClinicalFieldOption(id: 'Colleague', label: 'Work Colleague'),
    ClinicalFieldOption(id: 'Other', label: 'Other Authorized Relative'),
  ];

  // ================= TIER 2: CORE HEALTH RECORD CATALOGS =================

  /// Chronic Conditions (ICD-10 Coded)
  static const List<ClinicalFieldOption> coreDiagnoses = [
    ClinicalFieldOption(id: 'hypertension', label: 'Essential Primary Hypertension', code: 'I10', description: 'Chronically elevated resting blood pressure'),
    ClinicalFieldOption(id: 't2dm', label: 'Type 2 Diabetes Mellitus', code: 'E11', description: 'Metabolic hyperglycemia with insulin resistance'),
    ClinicalFieldOption(id: 'hypothyroidism', label: 'Hypothyroidism (Underactive Thyroid)', code: 'E03.9', description: 'Thyroid hormone deficiency'),
    ClinicalFieldOption(id: 'dyslipidemia', label: 'Dyslipidemia / Hypercholesterolemia', code: 'E78.5', description: 'Elevated LDL cholesterol or triglycerides'),
    ClinicalFieldOption(id: 'gerd', label: 'Gastroesophageal Reflux Disease (GERD)', code: 'K21.9', description: 'Chronic acid reflux and heartburn'),
    ClinicalFieldOption(id: 'osteoarthritis', label: 'Osteoarthritis (Knee / Spine / Hip)', code: 'M19.9', description: 'Degenerative articular cartilage disorder'),
    ClinicalFieldOption(id: 'migraine', label: 'Migraine Headache', code: 'G43.9', description: 'Recurrent moderate-to-severe neurovascular headache'),
    ClinicalFieldOption(id: 'allergic_rhinitis', label: 'Allergic Rhinitis (Hay Fever)', code: 'J30.9', description: 'IgE-mediated nasal mucosal inflammation'),
    ClinicalFieldOption(id: 'copd', label: 'Chronic Obstructive Pulmonary Disease (COPD)', code: 'J44.9', description: 'Progressive airflow limitation, chronic bronchitis'),
    ClinicalFieldOption(id: 'pcos', label: 'Polycystic Ovary Syndrome (PCOS)', code: 'E28.2', description: 'Hyperandrogenism, ovulatory dysfunction'),
    ClinicalFieldOption(id: 'fatty_liver', label: 'Metabolic Dysfunction-Associated Steatotic Liver (MASLD)', code: 'K76.0', description: 'Hepatic steatosis without secondary cause'),
    ClinicalFieldOption(id: 'low_back_pain', label: 'Chronic Lumbago / Low Back Pain', code: 'M54.5', description: 'Musculoskeletal or disc-related chronic spinal discomfort'),
  ];

  /// Standard Universal Immunizations (UIP India & WHO Agenda 2030)
  static const List<ClinicalFieldOption> standardVaccines = [
    ClinicalFieldOption(id: 'bcg', label: 'BCG (Bacille Calmette-Guérin)', code: '03', description: 'Neonatal tuberculosis protection'),
    ClinicalFieldOption(id: 'hepb_birth', label: 'Hepatitis B (Birth / Primary Schedule)', code: '08', description: 'Viral hepatitis B protection'),
    ClinicalFieldOption(id: 'opv', label: 'Oral Polio Vaccine (bOPV)', code: '02', description: 'Live attenuated oral polio immunization'),
    ClinicalFieldOption(id: 'ipv', label: 'Inactivated Polio Vaccine (fIPV / IPV)', code: '10', description: 'Injectable fractional / full inactivated poliovirus'),
    ClinicalFieldOption(id: 'pentavalent', label: 'Pentavalent (DTP + HepB + Hib)', code: '107', description: 'Diphtheria, Tetanus, Pertussis, HepB, Haemophilus influenzae b'),
    ClinicalFieldOption(id: 'rotavirus', label: 'Rotavirus Vaccine (RV)', code: '122', description: 'Protection against severe pediatric diarrheal dehydration'),
    ClinicalFieldOption(id: 'pcv', label: 'Pneumococcal Conjugate Vaccine (PCV)', code: '133', description: 'Streptococcus pneumoniae invasive disease prevention'),
    ClinicalFieldOption(id: 'mr_mmr', label: 'Measles-Rubella (MR) / MMR', code: '05', description: 'Measles, Mumps, Rubella live attenuated protection'),
    ClinicalFieldOption(id: 'td_booster', label: 'Tetanus & adult Diphtheria (Td)', code: '09', description: 'Decennial booster & pregnant women immunization'),
    ClinicalFieldOption(id: 'hpv', label: 'Human Papillomavirus (HPV Cervical Cancer Vaccine)', code: '62', description: 'Oncogenic HPV serotypes 16 & 18 prevention'),
    ClinicalFieldOption(id: 'typhoid_tcv', label: 'Typhoid Conjugate Vaccine (TCV)', code: '91', description: 'Salmonella Typhi long-lasting polysaccharide conjugate'),
    ClinicalFieldOption(id: 'influenza_annual', label: 'Seasonal Influenza (Annual Quadrivalent Flu)', code: '141', description: 'Annual respiratory influenza protection'),
    ClinicalFieldOption(id: 'covid19', label: 'COVID-19 Vaccine (Primary / Booster)', code: '208', description: 'SARS-CoV-2 spike protein immunization'),
    ClinicalFieldOption(id: 'varicella', label: 'Varicella (Chickenpox)', code: '21', description: 'Varicella-zoster virus protection'),
  ];

  // ================= TIER 3: LONGITUDINAL & LIFE-STAGE =================

  /// Diet Categories
  static const List<ClinicalFieldOption> dietTypes = [
    ClinicalFieldOption(id: 'vegetarian', label: 'Vegetarian (Lacto / Lacto-Ovo)', description: 'Plant-based with dairy products'),
    ClinicalFieldOption(id: 'non_vegetarian', label: 'Non-Vegetarian (Omnivorous)', description: 'Includes poultry, meat, fish, and eggs'),
    ClinicalFieldOption(id: 'ovo_vegetarian', label: 'Ovo-Vegetarian', description: 'Vegetarian including eggs but no dairy'),
    ClinicalFieldOption(id: 'vegan', label: 'Vegan', description: 'Strictly plant-based without animal derivatives'),
    ClinicalFieldOption(id: 'jain_vegetarian', label: 'Jain Vegetarian', description: 'Strict vegetarian excluding root vegetables'),
    ClinicalFieldOption(id: 'mediterranean', label: 'Cardio-Protective / Mediterranean', description: 'Rich in whole grains, legumes, olive oil, nuts, and fish'),
  ];

  /// Physical Activity Levels (WHO 2020 Aligned)
  static const List<ClinicalFieldOption> activityLevels = [
    ClinicalFieldOption(id: 'sedentary', label: 'Sedentary (Little to no intentional exercise)', description: '< 30 minutes physical activity per week'),
    ClinicalFieldOption(id: 'light', label: 'Light Activity (1–2 days/week)', description: 'Walking, light yoga; approx. 60–90 min/week'),
    ClinicalFieldOption(id: 'moderate', label: 'Moderate Activity (3–4 days/week)', description: 'Meets WHO baseline: brisk walk, cycling 150 min/week'),
    ClinicalFieldOption(id: 'active', label: 'Active (5+ days/week)', description: '150–300 min moderate or 75 min vigorous aerobic activity'),
    ClinicalFieldOption(id: 'vigorous', label: 'Vigorous / Athlete (Daily intense training)', description: '> 300 minutes vigorous aerobic + resistance conditioning'),
  ];

  /// Geriatric Fall Risk Categories (World Guidelines for Falls Prevention 2022)
  static const List<ClinicalFieldOption> fallRiskLevels = [
    ClinicalFieldOption(id: 'low_risk', label: 'Low Fall Risk', description: '0 falls in past 12 months, independent gait, normal balance'),
    ClinicalFieldOption(id: 'moderate_risk', label: 'Moderate Fall Risk', description: '1 non-injurious fall, uses single-point cane, mild balance hesitancy'),
    ClinicalFieldOption(id: 'high_risk', label: 'High Fall Risk', description: '>= 2 falls, injurious fall, unsteady gait, requires walker / assistance'),
  ];

  /// Geriatric Assistive Devices
  static const List<ClinicalFieldOption> assistiveDevices = [
    ClinicalFieldOption(id: 'none', label: 'None (Walks Independently)'),
    ClinicalFieldOption(id: 'single_cane', label: 'Single Point Cane / Walking Stick'),
    ClinicalFieldOption(id: 'quad_cane', label: 'Quad Cane (Broad 4-point base)'),
    ClinicalFieldOption(id: 'walker', label: 'Walker / Rollator Frame'),
    ClinicalFieldOption(id: 'wheelchair', label: 'Wheelchair (Manual / Powered)'),
    ClinicalFieldOption(id: 'bedbound', label: 'Bedbound / Transfer dependent'),
  ];

  // ================= TIER 4: ADVANCED & CONTEXTUAL (SENSITIVE) =================

  /// Current Perceived Stress Scale
  static const List<ClinicalFieldOption> stressLevels = [
    ClinicalFieldOption(id: 'low', label: 'Low / Manageable Stress', description: 'Coping comfortably with daily routine'),
    ClinicalFieldOption(id: 'moderate', label: 'Moderate Stress', description: 'Occasional overwhelm; manageable with self-care'),
    ClinicalFieldOption(id: 'high', label: 'High Stress', description: 'Frequently overwhelmed; impacting sleep or focus'),
    ClinicalFieldOption(id: 'severe', label: 'Severe / Chronic Stress', description: 'Exhaustion, burnout; clinical counseling recommended'),
  ];

  /// Tobacco / Smoking Status (WHO FCTC Aligned)
  static const List<ClinicalFieldOption> tobaccoUseStatuses = [
    ClinicalFieldOption(id: 'never', label: 'Never Smoked / Never Used Tobacco', description: 'Lifetime non-user (< 100 cigarettes)'),
    ClinicalFieldOption(id: 'former', label: 'Former Smoker / Quitted User', description: 'Ceased all tobacco consumption > 6 months ago'),
    ClinicalFieldOption(id: 'current_light', label: 'Current Light User (< 10 cigarettes or bidi/day)', description: 'Active tobacco smoker'),
    ClinicalFieldOption(id: 'current_moderate', label: 'Current Moderate User (10–20 cigarettes/day)', description: 'Active moderate daily smoker'),
    ClinicalFieldOption(id: 'current_heavy', label: 'Current Heavy User (> 20 cigarettes or bidi/day)', description: 'High cardiovascular and oncological risk profile'),
    ClinicalFieldOption(id: 'smokeless_tobacco', label: 'Chewing / Smokeless Tobacco (Gutkha, Khaini, Paan)', description: 'High oral premalignancy and periodontitis risk'),
  ];

  /// Alcohol Frequency (WHO AUDIT-C Aligned)
  static const List<ClinicalFieldOption> alcoholFrequencies = [
    ClinicalFieldOption(id: 'never', label: 'Never / Abstinent', description: 'Consumes no alcoholic beverages'),
    ClinicalFieldOption(id: 'monthly_or_less', label: 'Monthly or Less', description: 'Occasional social consumption (1-2 drinks/month)'),
    ClinicalFieldOption(id: '2_to_4_monthly', label: '2 to 4 Times a Month', description: 'Light weekend social drinking'),
    ClinicalFieldOption(id: '2_to_3_weekly', label: '2 to 3 Times a Week', description: 'Regular consumption; moderate intake'),
    ClinicalFieldOption(id: '4_plus_weekly', label: '4 or More Times a Week', description: 'Frequent drinking; health guidance recommended'),
  ];

  /// Standard Clinical Repeating Section Choices
  static const List<ClinicalFieldOption> repeatingRecordChoices = [
    ClinicalFieldOption(id: 'yes', label: 'Yes, I have records to add', description: 'Opens the structured clinical data entry form'),
    ClinicalFieldOption(id: 'no_known', label: 'No known records / None', description: 'Records explicit verified absence of conditions/events'),
    ClinicalFieldOption(id: 'unknown', label: 'Unknown / Not sure', description: 'Preserves unknown status without forcing invented data'),
  ];
}

