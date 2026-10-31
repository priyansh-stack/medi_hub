import '../../data/models/plan_model.dart';

class PlanCatalog {
  PlanCatalog._();

  static const String currencySymbol = '₹';
  static const String currencyCode = 'INR';

  static const PlanModel familyBasic = PlanModel(
    id: 'family_basic',
    name: 'Family Basic',
    amount: 0,
    currency: currencyCode,
    billingPeriod: 'month',
    formattedPrice: 'Free',
    memberLimitDescription: 'Up to 3 family members',
    maxMembers: 3,
    description: 'Essential health record management for smaller families.',
    features: [
      'Up to 3 family members (PRD limit)',
      'Basic health record storage',
      'Standard immunization & vitals tracking',
      'Community support access',
    ],
    isPopular: false,
  );

  static const PlanModel familyPro = PlanModel(
    id: 'family_pro',
    name: 'Family Pro',
    amount: 299,
    currency: currencyCode,
    billingPeriod: 'month',
    formattedPrice: '₹299/month',
    memberLimitDescription: 'Up to 8 family members',
    maxMembers: 8,
    description: 'Advanced health intelligence and monitoring for larger households.',
    features: [
      'Up to 8 family members (PRD limit)',
      'Intelligent health trend analysis',
      'Emergency vitals card sharing',
      'Automated prescription reminders',
      'Priority customer care',
    ],
    isPopular: true,
  );

  static const PlanModel familyPremium = PlanModel(
    id: 'family_premium',
    name: 'Family Premium',
    amount: 599,
    currency: currencyCode,
    billingPeriod: 'month',
    formattedPrice: '₹599/month',
    memberLimitDescription: 'Unlimited family members',
    maxMembers: null,
    description: 'Comprehensive 360° health and wellness for your extended family.',
    features: [
      'Unlimited family members (PRD limit)',
      'Dedicated digital family health concierge',
      'Advanced medical timeline & document OCR',
      '24/7 Priority emergency assistance line',
      'Unlimited cloud vault storage',
    ],
    isPopular: false,
  );

  static const List<PlanModel> plans = [
    familyBasic,
    familyPro,
    familyPremium,
  ];

  static PlanModel findById(String id) {
    return plans.firstWhere(
      (plan) => plan.id == id,
      orElse: () => familyBasic,
    );
  }
}
