import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class PaymentTransactionModel extends Equatable {
  final String transactionId;
  final String familyId;
  final String memberId;
  final String planId;
  final String planName;
  final double amount;
  final String currency;
  final String status; // 'SUCCESS', 'FAILED'
  final String paymentMode; // 'MOCK'
  final DateTime createdAt;

  const PaymentTransactionModel({
    required this.transactionId,
    required this.familyId,
    required this.memberId,
    required this.planId,
    required this.planName,
    required this.amount,
    this.currency = 'INR',
    required this.status,
    this.paymentMode = 'MOCK',
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'transactionId': transactionId,
      'familyId': familyId,
      'memberId': memberId,
      'planId': planId,
      'planName': planName,
      'amount': amount,
      'currency': currency,
      'status': status,
      'paymentMode': paymentMode,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory PaymentTransactionModel.fromMap(Map<String, dynamic> map, String transactionId) {
    DateTime parseDate(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
      return DateTime.now();
    }

    return PaymentTransactionModel(
      transactionId: transactionId,
      familyId: map['familyId'] as String? ?? '',
      memberId: map['memberId'] as String? ?? '',
      planId: map['planId'] as String? ?? 'family_basic',
      planName: map['planName'] as String? ?? 'Family Basic',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      currency: map['currency'] as String? ?? 'INR',
      status: map['status'] as String? ?? 'SUCCESS',
      paymentMode: map['paymentMode'] as String? ?? 'MOCK',
      createdAt: parseDate(map['createdAt']),
    );
  }

  @override
  List<Object?> get props => [
        transactionId,
        familyId,
        memberId,
        planId,
        planName,
        amount,
        currency,
        status,
        paymentMode,
        createdAt,
      ];
}
