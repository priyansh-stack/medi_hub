import 'package:flutter_test/flutter_test.dart';
import 'package:medi_hub/core/constants/plan_catalog.dart';
import 'package:medi_hub/data/models/subscription_model.dart';

void main() {
  group('PlanCatalog and Subscription Tests', () {
    test('verifies provisional PRD plan details', () {
      expect(PlanCatalog.plans.length, equals(3));

      final basic = PlanCatalog.familyBasic;
      expect(basic.name, equals('Family Basic'));
      expect(basic.amount, equals(0));
      expect(basic.isFree, isTrue);
      expect(basic.memberLimitDescription, equals('Up to 3 family members'));
      expect(basic.maxMembers, equals(3));

      final pro = PlanCatalog.familyPro;
      expect(pro.name, equals('Family Pro'));
      expect(pro.amount, equals(299));
      expect(pro.isFree, isFalse);
      expect(pro.memberLimitDescription, equals('Up to 8 family members'));
      expect(pro.maxMembers, equals(8));
      expect(pro.isPopular, isTrue);

      final premium = PlanCatalog.familyPremium;
      expect(premium.name, equals('Family Premium'));
      expect(premium.amount, equals(599));
      expect(premium.isFree, isFalse);
      expect(premium.memberLimitDescription, equals('Unlimited family members'));
      expect(premium.maxMembers, isNull);
    });

    test('finds plan by id or falls back to family_basic', () {
      expect(PlanCatalog.findById('family_pro').name, equals('Family Pro'));
      expect(PlanCatalog.findById('family_premium').name, equals('Family Premium'));
      expect(PlanCatalog.findById('unknown_plan').name, equals('Family Basic'));
    });

    test('SubscriptionModel mock status and active check', () {
      final mockActiveSub = SubscriptionModel(
        subscriptionId: 'sub_123',
        familyId: 'fam_123',
        planId: 'family_pro',
        amount: 299,
        currency: 'INR',
        status: 'MOCK_ACTIVE',
        paymentMode: 'MOCK',
        mockTransactionId: 'txn_mock_999',
      );

      expect(mockActiveSub.isActive, isTrue);
      expect(mockActiveSub.isFree, isFalse);
      expect(mockActiveSub.isFailed, isFalse);
      expect(mockActiveSub.paymentMode, equals('MOCK'));

      final freeSub = SubscriptionModel(
        subscriptionId: 'sub_free',
        familyId: 'fam_123',
        planId: 'family_basic',
        amount: 0,
        currency: 'INR',
        status: 'FREE',
        paymentMode: 'MOCK',
      );

      expect(freeSub.isActive, isTrue);
      expect(freeSub.isFree, isTrue);
    });
  });
}
