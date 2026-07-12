import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';

enum PaymentType { payment, dueAdded }

enum PaymentMethod { bKash, nagad, handCash, bank }

class Payment {
  final String id;
  final String customerId;
  final double amount;
  final PaymentType type;
  final PaymentMethod? paymentMethod;
  final String? note;
  final String? description;
  final String? receiptImageUrl;
  final File? receiptImageFile;
  final DateTime date;

  const Payment({
    required this.id,
    required this.customerId,
    required this.amount,
    required this.type,
    required this.date,
    this.paymentMethod,
    this.note,
    this.description,
    this.receiptImageUrl,
    this.receiptImageFile,
  });

  static String _asString(dynamic value, {String fallback = ''}) {
    if (value == null) return fallback;
    return value.toString();
  }

  static double _asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static DateTime _asDateTime(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    return DateTime.tryParse(value?.toString() ?? '') ?? DateTime.now();
  }

  // ✅ PaymentMethod enum → String
  static String paymentMethodToString(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.bKash:
        return 'bKash';
      case PaymentMethod.nagad:
        return 'Nagad';
      case PaymentMethod.handCash:
        return 'Hand Cash';
      case PaymentMethod.bank:
        return 'Bank';
    }
  }

  // ✅ String → PaymentMethod enum
  static PaymentMethod? paymentMethodFromString(String? value) {
    switch (value) {
      case 'bKash':
        return PaymentMethod.bKash;
      case 'Nagad':
        return PaymentMethod.nagad;
      case 'Hand Cash':
        return PaymentMethod.handCash;
      case 'Bank':
        return PaymentMethod.bank;
      default:
        return null;
    }
  }

  // ✅ To Firestore Map
  Map<String, dynamic> toMap() => {
    'id': id,
    'customerId': customerId,
    'amount': amount,
    'type': type.name,
    'paymentMethod': paymentMethod != null
        ? paymentMethodToString(paymentMethod!)
        : null,
    'note': note,
    'description': description,
    'receiptImageUrl': receiptImageUrl,
    'date': Timestamp.fromDate(date),
  };

  // ✅ From Firestore Map
  factory Payment.fromMap(Map<String, dynamic> map) {
    return Payment(
      id: _asString(map['id']),
      customerId: _asString(map['customerId']),
      amount: _asDouble(map['amount']),
      type: PaymentType.values.firstWhere(
        (value) => value.name == map['type'],
        orElse: () => PaymentType.payment,
      ),
      paymentMethod: Payment.paymentMethodFromString(
        map['paymentMethod']?.toString(),
      ),
      note: map['note']?.toString(),
      description: map['description']?.toString(),
      receiptImageUrl: map['receiptImageUrl']?.toString(),

      // ✅ Handle Timestamp OR String
      date: _asDateTime(map['date']),
    );
  }
}
