import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medi_hub/core/clinical/clinical_catalog.dart';
import 'package:medi_hub/core/clinical/clinical_engine.dart';
import 'package:medi_hub/core/clinical/clinical_guidelines.dart';
import 'package:medi_hub/presentation/widgets/clinical/clinical_field_renderer.dart';
import 'package:medi_hub/presentation/widgets/clinical/clinical_guideline_dialog.dart';

void main() {
  group('Clinical Guidelines & Catalog Tests', () {
    test('ClinicalGuidelinesCatalog contains approved WHO & national guidelines', () {
      expect(ClinicalGuidelinesCatalog.guidelines.isNotEmpty, true);

      // Verify Tier 1 blood group ABO guideline
      final aboGl = ClinicalGuidelinesCatalog.getGuidelineByRuleId('GL-T1-ABO-01');
      expect(aboGl, isNotNull);
      expect(aboGl!.codeSystem, 'LOINC');
      expect(aboGl.terminologyCode, '883-9');
      expect(aboGl.reviewStatus, 'Approved');

      // Verify Tier 2 hypertension guideline
      final bpGl = ClinicalGuidelinesCatalog.getGuidelineByRuleId('GL-T2-BP-01');
      expect(bpGl, isNotNull);
      expect(bpGl!.guidelineName.contains('WHO'), true);
      expect(bpGl.reviewStatus, 'Approved');

      // Verify Tier 4 mental health guideline (mhGAP)
      final mhGl = ClinicalGuidelinesCatalog.getGuidelineByRuleId('GL-T4-MH-01');
      expect(mhGl, isNotNull);
      expect(mhGl!.sourceRef.contains('mhGAP'), true);
      expect(mhGl.reviewStatus, 'Approved');
    });

    test('ClinicalCatalog provides structured medical terminology', () {
      // ABO & Rh
      expect(ClinicalCatalog.bloodGroupsABO.length, 5);
      expect(ClinicalCatalog.rhFactors.length, 3);
      expect(ClinicalCatalog.bloodVerificationStatuses.length, 5);

      // Allergens with SNOMED CT codes
      expect(ClinicalCatalog.allergens.any((a) => a.id == 'penicillin' && a.code == '70618006'), true);
      expect(ClinicalCatalog.allergens.any((a) => a.id == 'peanuts' && a.code == '256349002'), true);

      // High-alert medications with ATC codes
      expect(ClinicalCatalog.criticalMedications.any((m) => m.id == 'insulin_regular' && m.code == 'A10AB01'), true);
      expect(ClinicalCatalog.criticalMedications.any((m) => m.id == 'warfarin' && m.code == 'B01AA03'), true);

      // Critical conditions with ICD-10 codes
      expect(ClinicalCatalog.criticalConditions.any((c) => c.id == 't1dm' && c.code == 'E10'), true);
      expect(ClinicalCatalog.criticalConditions.any((c) => c.id == 'epilepsy' && c.code == 'G40'), true);

      // Repeating record choices
      expect(ClinicalCatalog.repeatingRecordChoices.length, 3);
      expect(ClinicalCatalog.repeatingRecordChoices.map((c) => c.id), containsAll(['yes', 'no_known', 'unknown']));
    });
  });

  group('Field-Level Clinical Validation Tests', () {
    test('Validates numeric measurements according to WHO approved limits', () {
      final systolicField = ClinicalEngine.getFieldsForSection('t2_vitals')
          .firstWhere((f) => f.fieldId == 'systolicBp');

      // Technically valid readings
      expect(ClinicalEngine.validateFieldValue(systolicField, '120'), isNull);
      expect(ClinicalEngine.validateFieldValue(systolicField, '80'), isNull);
      expect(ClinicalEngine.validateFieldValue(systolicField, '240'), isNull);

      // Technically invalid / dangerous outliers
      expect(ClinicalEngine.validateFieldValue(systolicField, '45'), isNotNull);
      expect(ClinicalEngine.validateFieldValue(systolicField, '320'), isNotNull);
      expect(ClinicalEngine.validateFieldValue(systolicField, 'invalid_number'), isNotNull);

      // Diastolic check
      final diastolicField = ClinicalEngine.getFieldsForSection('t2_vitals')
          .firstWhere((f) => f.fieldId == 'diastolicBp');
      expect(ClinicalEngine.validateFieldValue(diastolicField, '80'), isNull);
      expect(ClinicalEngine.validateFieldValue(diastolicField, '30'), isNotNull);
      expect(ClinicalEngine.validateFieldValue(diastolicField, '180'), isNotNull);
    });

    test('Validates clinical date fields rejecting future events for historical records', () {
      final diagField = ClinicalEngine.getFieldsForSection('t1_critical_conditions')
          .firstWhere((f) => f.fieldId == 'dateDiagnosed');

      final pastDate = DateTime.now().subtract(const Duration(days: 300)).toIso8601String();
      final futureDate = DateTime.now().add(const Duration(days: 30)).toIso8601String();

      expect(ClinicalEngine.validateFieldValue(diagField, pastDate), isNull);
      final error = ClinicalEngine.validateFieldValue(diagField, futureDate);
      expect(error, isNotNull);
      expect(error, contains('future'));

      // Check birth date consistency: event cannot be earlier than DoB
      final dob = DateTime(2010, 5, 1);
      final beforeDob = DateTime(2005, 1, 1).toIso8601String();
      final afterDob = DateTime(2015, 1, 1).toIso8601String();

      expect(ClinicalEngine.validateFieldValue(diagField, afterDob, memberDob: dob), isNull);
      final dobError = ClinicalEngine.validateFieldValue(diagField, beforeDob, memberDob: dob);
      expect(dobError, isNotNull);
      expect(dobError, contains('date of birth'));
    });

    test('Validates phone numbers with country-aware formatting', () {
      final phoneField = ClinicalEngine.getFieldsForSection('t1_emergency_contacts')
          .firstWhere((f) => f.fieldId == 'contact1Phone');

      // Valid Indian 10-digit
      expect(ClinicalEngine.validateFieldValue(phoneField, '9876543210'), isNull);
      // Valid International with country code
      expect(ClinicalEngine.validateFieldValue(phoneField, '+1 415 555 2671'), isNull);
      expect(ClinicalEngine.validateFieldValue(phoneField, '+91 9876543210'), isNull);
      expect(ClinicalEngine.validateFieldValue(phoneField, '+44 20 7946 0991'), isNull);

      // Invalid short or non-standard numbers
      expect(ClinicalEngine.validateFieldValue(phoneField, '12345'), isNotNull);
      expect(ClinicalEngine.validateFieldValue(phoneField, '+12'), isNotNull);
    });

    test('Accepts explicit clinical states (Unknown, Not Applicable, Declined) as valid', () {
      final bloodField = ClinicalEngine.getFieldsForSection('t1_blood_group')
          .firstWhere((f) => f.fieldId == 'bloodGroup');

      // Plain empty triggers required error
      expect(ClinicalEngine.validateFieldValue(bloodField, ''), isNotNull);

      // Explicit states are valid responses without forcing invented medical data
      expect(ClinicalEngine.validateFieldValue(bloodField, {'state': 'unknown'}), isNull);
      expect(ClinicalEngine.validateFieldValue(bloodField, {'state': 'notApplicable'}), isNull);
      expect(ClinicalEngine.validateFieldValue(bloodField, {'state': 'declined'}), isNull);
    });
  });

  group('Dynamic Form Fields Per Tier', () {
    test('Tier 1 has all required structured fields', () {
      final bloodFields = ClinicalEngine.getFieldsForSection('t1_blood_group');
      expect(bloodFields.any((f) => f.fieldId == 'bloodGroup'), true);
      expect(bloodFields.any((f) => f.fieldId == 'rhFactor'), true);
      expect(bloodFields.any((f) => f.fieldId == 'verificationStatus'), true);

      final allergyFields = ClinicalEngine.getFieldsForSection('t1_critical_allergies');
      expect(allergyFields.any((f) => f.fieldId == 'allergenName'), true);
      expect(allergyFields.any((f) => f.fieldId == 'allergyReaction'), true);
      expect(allergyFields.any((f) => f.fieldId == 'allergySeverity'), true);
    });

    test('Tier 2 has vitals with units and guidelines', () {
      final vitalsFields = ClinicalEngine.getFieldsForSection('t2_vitals');
      expect(vitalsFields.any((f) => f.fieldId == 'systolicBp' && f.unit == 'mmHg'), true);
      expect(vitalsFields.any((f) => f.fieldId == 'diastolicBp' && f.unit == 'mmHg'), true);
      expect(vitalsFields.any((f) => f.fieldId == 'heartRate' && f.unit == 'bpm'), true);
      expect(vitalsFields.any((f) => f.fieldId == 'fastingBloodGlucose' && f.unit == 'mg/dL'), true);
    });

    test('Tier 3 generates age and gender specific modules', () {
      // Pediatric member gets birth milestones
      final pedFields = ClinicalEngine.getFieldsForSection('t3_pediatric_milestones', ageBand: AgeBand.pediatric);
      expect(pedFields.any((f) => f.fieldId == 'birthWeight' && f.unit == 'kg'), true);

      // Geriatric member gets fall risk
      final gerFields = ClinicalEngine.getFieldsForSection('t3_geriatric_assessment', ageBand: AgeBand.geriatric);
      expect(gerFields.any((f) => f.fieldId == 'fallRiskLevel'), true);

      // Female adult gets consented reproductive health
      final repFields = ClinicalEngine.getFieldsForSection('t3_reproductive_health', ageBand: AgeBand.adult, gender: 'Female');
      expect(repFields.any((f) => f.fieldId == 'menarcheAge'), true);
      expect(repFields.every((f) => f.isGated), true);
    });

    test('Tier 4 sensitive modules are consent-gated', () {
      final mhFields = ClinicalEngine.getFieldsForSection('t4_mental_health');
      expect(mhFields.every((f) => f.isGated), true);

      final subFields = ClinicalEngine.getFieldsForSection('t4_substance_use');
      expect(subFields.every((f) => f.isGated), true);
    });
  });

  group('Clinical Widget Tests', () {
    testWidgets('ClinicalFieldRenderer displays label, description, and input control', (tester) async {
      final field = ClinicalEngine.getFieldsForSection('t1_blood_group')
          .firstWhere((f) => f.fieldId == 'bloodGroup');

      dynamic updatedValue;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ClinicalFieldRenderer(
              field: field,
              initialValue: null,
              onChanged: (val) {
                updatedValue = val;
              },
            ),
          ),
        ),
      );

      expect(find.text('ABO Blood Group'), findsOneWidget);
      expect(find.textContaining('surface antigen'), findsOneWidget);
      expect(find.text('Unknown'), findsOneWidget); // Mark state chip

      // Tap Unknown state chip
      await tester.tap(find.text('Unknown'));
      await tester.pump();

      expect(updatedValue, isNotNull);
      expect(updatedValue['state'], 'unknown');
    });

    testWidgets('ClinicalGuidelineDialog displays rule ID and WHO authority details', (tester) async {
      final guideline = ClinicalGuidelinesCatalog.getGuidelineByRuleId('GL-T1-ABO-01')!;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => ClinicalGuidelineDialog.show(context, guideline),
                child: const Text('Open Guideline'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Guideline'));
      await tester.pumpAndSettle();

      expect(find.text('GL-T1-ABO-01'), findsOneWidget);
      expect(find.textContaining('WHO Guidelines on Blood Transfusion'), findsOneWidget);
      expect(find.textContaining('LOINC: 883-9'), findsOneWidget);
      expect(find.text('APPROVED'), findsOneWidget);

      await tester.tap(find.text('Close Rationale'));
      await tester.pumpAndSettle();

      expect(find.text('GL-T1-ABO-01'), findsNothing);
    });
  });
}

