import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medi_hub/core/constants/plan_catalog.dart';
import 'package:medi_hub/core/theme/app_theme.dart';
import 'package:medi_hub/data/models/family_model.dart';
import 'package:medi_hub/data/models/member_profile_model.dart';
import 'package:medi_hub/data/models/subscription_model.dart';
import 'package:medi_hub/data/models/user_model.dart';
import 'package:medi_hub/presentation/screens/dashboard_screen.dart';

void main() {
  group('DashboardScreen Sidebar & View Tests', () {
    final testUser = UserModel(
      uid: 'usr_test_123',
      fullName: 'Priyanshu Sharma',
      email: 'priyanshu@medihub.health',
      emailVerified: true,
      memberId: 'mem_12345678',
      onboardingStatus: OnboardingStep.completed,
    );

    final testProfile = MemberProfileModel(
      memberId: 'mem_12345678',
      fullName: 'Priyanshu Sharma',
      gender: 'Male',
      bloodGroup: 'O+',
      phone: '+91 9876543210',
      dateOfBirth: DateTime(1995, 6, 15),
      address: const AddressModel(
        line: 'Flat 302, Lotus Towers',
        city: 'Bengaluru',
        state: 'Karnataka',
        country: 'India',
        postalCode: '560001',
      ),
    );

    final testFamily = FamilyModel(
      familyId: 'fam_usr_test_123',
      familyName: 'Sharma Household',
      description: 'Primary health hub',
      adminUid: 'usr_test_123',
    );

    final testSubscription = SubscriptionModel(
      subscriptionId: 'sub_mock_001',
      familyId: 'fam_usr_test_123',
      planId: 'family_pro',
      amount: 499.0,
      currency: 'INR',
      billingCycle: 'MONTHLY',
      status: 'MOCK_ACTIVE',
      paymentMode: 'MOCK',
      mockTransactionId: 'txn_mock_9999',
    );

    testWidgets('Desktop view renders permanent sidebar and navigates between 5 tabs', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: DashboardScreen(
            user: testUser,
            memberProfile: testProfile,
            family: testFamily,
            subscription: testSubscription,
            plan: PlanCatalog.familyPro,
            onChangePlan: () {},
          ),
        ),
      );

      // Verify MediHub Branding in Sidebar
      expect(find.text('MediHub'), findsWidgets);
      expect(find.text('Health & Family Portal'), findsOneWidget);

      // Verify Sidebar Navigation Items exist (5 items canonical MediHub tabs)
      expect(find.text('Dashboard'), findsWidgets);
      expect(find.text('Family Group'), findsWidgets);
      expect(find.text('Health Records'), findsWidgets);
      expect(find.text('Appointments'), findsWidgets);
      expect(find.text('Subscription'), findsWidgets);
      expect(find.text('Settings'), findsNothing);

      // Verify User Details and Active Plan Tag in Sidebar Footer
      expect(find.text('Priyanshu Sharma'), findsOneWidget);
      expect(find.text('mem_12345678'), findsOneWidget);
      expect(find.text('Active (PRO)'), findsOneWidget);

      // Verify FAB 'Add Family Member' exists
      expect(find.widgetWithText(FloatingActionButton, 'Add Family Member'), findsOneWidget);

      // Verify Overview Welcome Banner and clean empty page placeholder
      expect(find.text('Welcome, Priyanshu Sharma!'), findsOneWidget);
      expect(find.text('Welcome to MediHub'), findsOneWidget);

      // Click the Floating Action Button -> Should navigate to Family Group & open Add Family Member Dialog
      await tester.tap(find.widgetWithText(FloatingActionButton, 'Add Family Member'));
      await tester.pumpAndSettle();

      // Verify Add Family Member Dialog is open
      expect(find.text('Step 1: Member Demographics'), findsOneWidget);
      expect(find.text('Full Name *'), findsOneWidget);

      // Close the Add Family Member dialog
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();

      // Now we are on 'Family Group' tab
      expect(find.text('Household Members Roster'), findsOneWidget);
      expect(find.text('FAMILY ADMIN'), findsOneWidget);
      expect(find.text('T1 Safety'), findsOneWidget);
      expect(find.text('T2 Core'), findsOneWidget);
      expect(find.text('Click card to view / edit health profile'), findsOneWidget);

      // Open Member Health Profile Screen by clicking the member card
      await tester.tap(find.text('Click card to view / edit health profile'));
      await tester.pumpAndSettle();

      // Verify Member Health Profile Screen & 4-Tier Collection Plan
      expect(find.textContaining('Health Profile'), findsWidgets);
      expect(find.textContaining('Tier 1'), findsOneWidget);
      expect(find.textContaining('Tier 2'), findsOneWidget);
      expect(find.textContaining('Tier 3'), findsOneWidget);
      expect(find.textContaining('Tier 4'), findsOneWidget);

      // Go back to Family Group tab
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      // Navigate to 'Health Records' tab
      await tester.tap(find.text('Health Records'));
      await tester.pumpAndSettle();
      expect(find.text('Personal Health Records Vault'), findsOneWidget);
      expect(find.text('Upload Record'), findsOneWidget);

      // Navigate to 'Appointments' tab
      await tester.tap(find.text('Appointments'));
      await tester.pumpAndSettle();
      expect(find.text('Doctor Appointments & Consultations'), findsOneWidget);
      expect(find.text('Book Appointment'), findsOneWidget);

      // Navigate to 'Subscription' tab
      await tester.tap(find.text('Subscription').first);
      await tester.pumpAndSettle();
      expect(find.text('Available Family Plans'), findsOneWidget);
      expect(find.text('Mock Payment History'), findsOneWidget);
    });
  });
}
