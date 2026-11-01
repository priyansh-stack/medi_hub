import 'package:flutter_test/flutter_test.dart';
import 'package:medi_hub/core/clinical/clinical_engine.dart';
import 'package:medi_hub/data/models/member_profile_model.dart';
import 'package:medi_hub/data/repositories/family_repository.dart';

void main() {
  group('ClinicalEngine Unit Tests', () {
    DateTime dobForAge(int age) {
      final now = DateTime.now();
      return DateTime(now.year - age, now.month, now.day);
    }

    test('determineAgeBand categorizes ages correctly', () {
      expect(ClinicalEngine.determineAgeBand(dobForAge(5)), AgeBand.pediatric);
      expect(ClinicalEngine.determineAgeBand(dobForAge(11)), AgeBand.pediatric);
      expect(ClinicalEngine.determineAgeBand(dobForAge(12)), AgeBand.adolescent);
      expect(ClinicalEngine.determineAgeBand(dobForAge(17)), AgeBand.adolescent);
      expect(ClinicalEngine.determineAgeBand(dobForAge(18)), AgeBand.adult);
      expect(ClinicalEngine.determineAgeBand(dobForAge(64)), AgeBand.adult);
      expect(ClinicalEngine.determineAgeBand(dobForAge(65)), AgeBand.geriatric);
      expect(ClinicalEngine.determineAgeBand(dobForAge(90)), AgeBand.geriatric);
    });

    test('generatePlan creates deterministic plan for pediatric member', () {
      final dob = dobForAge(6);
      final plan = ClinicalEngine.generatePlan(
        memberId: 'mem_ped_001',
        householdId: 'fam_123',
        dateOfBirth: dob,
        gender: 'Male',
        relationship: 'Child',
        managementType: 'guardianManaged',
      );

      expect(plan.memberId, 'mem_ped_001');
      expect(plan.householdId, 'fam_123');
      expect(plan.ageBand, AgeBand.pediatric.name);
      expect(plan.planHash.isNotEmpty, true);
      // Pediatric plan excludes adult-specific sections
      expect(plan.excludedFields.contains('t4_substance_use'), true);
      expect(plan.excludedFields.contains('t4_clinical_research'), true);
    });

    test('generatePlan includes sensitive sections as gated for adult member', () {
      final dob = dobForAge(30);
      final plan = ClinicalEngine.generatePlan(
        memberId: 'mem_adult_001',
        householdId: 'fam_123',
        dateOfBirth: dob,
        gender: 'Female',
        relationship: 'Spouse',
        managementType: 'independentlyManaged',
      );

      expect(plan.ageBand, AgeBand.adult.name);
      expect(plan.gatedFields.contains('t4_mental_health'), true);
      expect(plan.gatedFields.contains('t3_reproductive_health'), true);
      expect(plan.gatedFields.contains('t4_substance_use'), true);
    });

    test('calculateCompletion accurately scores data states including unknown and declined', () {
      final dob = dobForAge(25);
      final plan = ClinicalEngine.generatePlan(
        memberId: 'mem_adult_002',
        householdId: 'fam_123',
        dateOfBirth: dob,
        gender: 'Male',
        relationship: 'Self',
        managementType: 'adminManaged',
      );

      // Answers with clinical states for all Tier 1 sections
      final tierData = <String, dynamic>{
        't1_blood_group': {'state': 'completed', 'value': 'B+'},
        't1_emergency_contacts': {'state': 'completed', 'value': '9876543210'},
        't1_critical_allergies': {'state': 'unknown'}, // valid answer state
        't1_critical_medications': {'state': 'declined'}, // valid answer state
        't1_critical_conditions': {'state': 'completed', 'value': 'None'},
        't1_implanted_devices': {'state': 'notApplicable'}, // valid answer state
        't1_emergency_instructions': {'state': 'completed', 'value': 'Standard'},
        't1_organ_donor': {'state': 'completed', 'value': 'Yes'},
      };

      final completion = ClinicalEngine.calculateCompletion(
        plan: plan,
        tierData: tierData,
        consentGiven: {'t4_mental_health': true, 't4_substance_use': true},
        memberId: 'mem_adult_002',
        householdId: 'fam_123',
      );

      // Tier 1 sections answered
      expect(completion.tier1Status, 'Completed');
      expect(completion.overallPercentage, greaterThan(0));
    });
  });

  group('FamilyRepository Tier Persistence & Reflection Tests', () {
    test('saveTierAnswers updates repository cache and reflects in getFamilyMembers', () async {
      final repo = FamilyRepository();
      final adminMember = MemberProfileModel(
        memberId: 'mem_admin_persist_test',
        householdId: 'fam_persist_01',
        fullName: 'Dr. Test Admin',
        dateOfBirth: DateTime(1985, 5, 20),
        gender: 'Male',
        relationship: 'Self',
        managementType: 'adminManaged',
        profileOwnerUserId: 'admin_test_uid',
        address: const AddressModel(
          line: '123 Medical Enclave',
          city: 'New Delhi',
          state: 'Delhi',
          country: 'India',
          postalCode: '110001',
        ),
      );

      final plan = await repo.ensureClinicalPlan(adminMember);

      // Save complete Tier 1 answers with Blood Group and Emergency Contact
      final tier1Answers = <String, dynamic>{
        't1_blood_group': {
          'state': 'completed',
          'value': 'O+',
          'fields': {
            'bloodGroup': 'O',
            'rhFactor': 'Positive',
            'verificationStatus': 'Lab Tested',
          },
        },
        't1_emergency_contacts': {
          'state': 'completed',
          'value': '9876543210',
          'fields': {
            'contact1Name': 'Jane Admin',
            'contact1Relationship': 'Spouse',
            'contact1Phone': '9876543210',
          },
        },
        't1_critical_allergies': {'state': 'completed', 'value': 'None'},
        't1_critical_medications': {'state': 'completed', 'value': 'None'},
        't1_critical_conditions': {'state': 'completed', 'value': 'None'},
        't1_implanted_devices': {'state': 'notApplicable'},
        't1_emergency_instructions': {'state': 'completed', 'value': 'Standard'},
        't1_organ_donor': {'state': 'completed', 'value': 'Yes'},
      };

      final updatedCompletion = await repo.saveTierAnswers(
        member: adminMember,
        plan: plan,
        newSectionAnswers: tier1Answers,
      );

      expect(updatedCompletion.tier1Status, 'Completed');
      expect(updatedCompletion.overallPercentage, greaterThan(0.0));

      // Re-fetch family members to simulate returning to Family Health Group tab
      final members = await repo.getFamilyMembers(
        familyId: 'fam_persist_01',
        adminProfile: adminMember,
        adminUid: 'admin_test_uid',
      );

      final foundAdmin = members.firstWhere((m) => m.memberId == adminMember.memberId);

      // Assert that Blood Group, Emergency Contact, and completion metrics reflect cleanly
      expect(foundAdmin.bloodGroup, 'O+');
      expect(foundAdmin.emergencyContactName, 'Jane Admin');
      expect(foundAdmin.emergencyContactPhone, '9876543210');
      expect(foundAdmin.emergencyContactRelationship, 'Spouse');
      expect(foundAdmin.tier1Status, 'Completed');
      expect(foundAdmin.completionPercentage, updatedCompletion.overallPercentage);
      expect(foundAdmin.profileStatus, 'In Progress');
    });
  });
}
