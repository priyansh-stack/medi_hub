import 'package:equatable/equatable.dart';

class PlanModel extends Equatable {
  final String id;
  final String name;
  final double amount;
  final String currency;
  final String billingPeriod; // e.g. "month"
  final String formattedPrice;
  final String memberLimitDescription;
  final int? maxMembers; // null means unlimited
  final String description;
  final List<String> features;
  final bool isPopular;

  const PlanModel({
    required this.id,
    required this.name,
    required this.amount,
    required this.currency,
    required this.billingPeriod,
    required this.formattedPrice,
    required this.memberLimitDescription,
    this.maxMembers,
    required this.description,
    required this.features,
    this.isPopular = false,
  });

  bool get isFree => amount == 0;
  String get memberLimit => memberLimitDescription;

  @override
  List<Object?> get props => [
        id,
        name,
        amount,
        currency,
        billingPeriod,
        formattedPrice,
        memberLimitDescription,
        maxMembers,
        description,
        features,
        isPopular,
      ];
}
