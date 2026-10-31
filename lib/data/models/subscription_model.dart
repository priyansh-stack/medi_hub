import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class SubscriptionModel extends Equatable {
  final String subscriptionId;
  final String familyId;
  final String planId;
  final double amount;
  final String currency;
  final String billingCycle; // 'MONTHLY', 'ANNUAL'
  final String status; // 'FREE', 'MOCK_ACTIVE', 'PAYMENT_FAILED', 'CANCELLED'
  final String paymentMode; // 'MOCK'
  final String? mockTransactionId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const SubscriptionModel({
    required this.subscriptionId,
    required this.familyId,
    required this.planId,
    required this.amount,
    this.currency = 'INR',
    this.billingCycle = 'MONTHLY',
    required this.status,
    this.paymentMode = 'MOCK',
    this.mockTransactionId,
    this.createdAt,
    this.updatedAt,
  });

  bool get isActive => status == 'MOCK_ACTIVE' || status == 'FREE';
  bool get isFree => status == 'FREE' || amount == 0;
  bool get isFailed => status == 'PAYMENT_FAILED';

  SubscriptionModel copyWith({
    String? subscriptionId,
    String? familyId,
    String? planId,
    double? amount,
    String? currency,
    String? billingCycle,
    String? status,
    String? paymentMode,
    String? mockTransactionId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SubscriptionModel(
      subscriptionId: subscriptionId ?? this.subscriptionId,
      familyId: familyId ?? this.familyId,
      planId: planId ?? this.planId,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      billingCycle: billingCycle ?? this.billingCycle,
      status: status ?? this.status,
      paymentMode: paymentMode ?? this.paymentMode,
      mockTransactionId: mockTransactionId ?? this.mockTransactionId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'subscriptionId': subscriptionId,
      'familyId': familyId,
      'planId': planId,
      'amount': amount,
      'currency': currency,
      'billingCycle': billingCycle,
      'status': status,
      'paymentMode': paymentMode,
      'mockTransactionId': mockTransactionId,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  factory SubscriptionModel.fromMap(Map<String, dynamic> map, String subscriptionId) {
    DateTime? parseDate(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.tryParse(value);
      return null;
    }

    return SubscriptionModel(
      subscriptionId: subscriptionId,
      familyId: map['familyId'] as String? ?? '',
      planId: map['planId'] as String? ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      currency: map['currency'] as String? ?? 'INR',
      billingCycle: map['billingCycle'] as String? ?? 'MONTHLY',
      status: map['status'] as String? ?? 'FREE',
      paymentMode: map['paymentMode'] as String? ?? 'MOCK',
      mockTransactionId: map['mockTransactionId'] as String?,
      createdAt: parseDate(map['createdAt']),
      updatedAt: parseDate(map['updatedAt']),
    );
  }

  @override
  List<Object?> get props => [
        subscriptionId,
        familyId,
        planId,
        amount,
        currency,
        billingCycle,
        status,
        paymentMode,
        mockTransactionId,
        createdAt,
        updatedAt,
      ];
}
