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

    testWidgets('Desktop view renders permanent sidebar and navigates between tabs', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      bool changePlanTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: DashboardScreen(
            user: testUser,
            memberProfile: testProfile,
            family: testFamily,
            subscription: testSubscription,
            plan: PlanCatalog.familyPro,
            onChangePlan: () {
              changePlanTapped = true;
            },
          ),
        ),
      );

      // Verify MediHub Branding in Sidebar
      expect(find.text('MediHub'), findsOneWidget);
      expect(find.text('Health & Family Portal'), findsOneWidget);

      // Verify Sidebar Navigation Items exist
      expect(find.text('Overview'), findsWidgets);
      expect(find.text('Family Group'), findsOneWidget);
      expect(find.text('Health Profile'), findsOneWidget);
      expect(find.text('Subscription'), findsOneWidget);
      expect(find.text('Medical Records'), findsOneWidget);
      expect(find.text('Consultations'), findsOneWidget);

      // Verify Overview content is displayed
      expect(find.text('Welcome, Priyanshu Sharma!'), findsOneWidget);
      expect(find.text('Sharma Household'), findsWidgets);

      // Navigate to 'Family Group' tab
      await tester.tap(find.text('Family Group'));
      await tester.pumpAndSettle();
      expect(find.text('Household Members Roster'), findsOneWidget);
      expect(find.text('FAMILY ADMIN'), findsOneWidget);

      // Navigate to 'Health Profile' tab
      await tester.tap(find.text('Health Profile'));
      await tester.pumpAndSettle();
      expect(find.text('Contact & Emergency Records'), findsOneWidget);
      expect(find.text('+91 9876543210'), findsWidgets);

      // Navigate to 'Subscription' tab
      await tester.tap(find.text('Subscription'));
      await tester.pumpAndSettle();
      expect(find.text('Included Plan Features'), findsOneWidget);
      expect(find.text('MOCK ACTIVE'), findsWidgets);

      // Navigate to 'Medical Records' tab
      await tester.tap(find.text('Medical Records'));
      await tester.pumpAndSettle();
      expect(find.text('Family Health Vault'), findsOneWidget);
      expect(find.text('Upload Record'), findsOneWidget);

      // Navigate to 'Consultations' tab
      await tester.tap(find.text('Consultations'));
      await tester.pumpAndSettle();
      expect(find.text('Doctor Consultations & Appointments'), findsOneWidget);
      expect(find.text('No upcoming appointments scheduled'), findsOneWidget);
    });
  });
}

