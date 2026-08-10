import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';

enum PaymentType { payment, dueAdded }

enum PaymentMethod { bKash, nagad, handCash, bank }

class Payment {
  final String id;
  final String customerId;
  final double amount;
  final double discount;
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
    this.discount = 0,
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

  // ✅ String → PaymentMethod enum (সম্পূর্ণ নিরাপদ এবং কেস-ইনসেন্সিটিভ করা হয়েছে)
  static PaymentMethod? paymentMethodFromString(dynamic value) {
    if (value == null) return null;
    
    // যদি অলরেডি অবজেক্টটি Enum টাইপই হয়ে থাকে
    if (value is PaymentMethod) return value;
    
    final String strValue = value.toString().trim().toLowerCase();
    
    // ১. সরাসরি ফায়ারবেস র-স্ট্রিং ভ্যালু ম্যাচিং (যেমন স্ক্রিনশটে: 'bkash')
    if (strValue == 'bkash') return PaymentMethod.bKash;
    if (strValue == 'nagad') return PaymentMethod.nagad;
    if (strValue == 'hand cash' || strValue == 'handcash') return PaymentMethod.handCash;
    if (strValue == 'bank') return PaymentMethod.bank;
    
    // ২. ডার্ট Enum ফুল নেম ম্যাচিং ব্যাকআপ (যেমন: 'paymentmethod.bkash' বা শুধু 'bkash')
    try {
      return PaymentMethod.values.firstWhere(
        (e) => e.name.toLowerCase() == strValue || e.toString().toLowerCase().split('.').last == strValue,
      );
    } catch (_) {
      return null;
    }
  }

  // ✅ To Firestore Map
  Map<String, dynamic> toMap() => {
    'id': id,
    'customerId': customerId,
    'amount': amount,
    'discount': discount,
    'type': type.name,
    'paymentMethod': paymentMethod != null
        ? paymentMethodToString(paymentMethod!)
        : null,
    'note': note,
    'description': description,
    'receiptImageUrl': receiptImageUrl,
    'date': Timestamp.fromDate(date),
  };

  // ✅ From Firestore Map (আপডেট ও সম্পূর্ণ সুরক্ষিত)
  factory Payment.fromMap(Map<String, dynamic> map) {
    return Payment(
      id: _asString(map['id']),
      customerId: _asString(map['customerId']),
      amount: _asDouble(map['amount']),
      discount: _asDouble(map['discount']),
      type: PaymentType.values.firstWhere(
        (value) => value.name == map['type'] || value.toString().split('.').last == map['type'],
        orElse: () => PaymentType.payment,
      ),
      // ✅ এখানে paymentMethodFromString এ সরাসরি ম্যাপ অবজেক্ট পাঠিয়ে ইন্টারনাল কাস্টিং হ্যান্ডেল করা হয়েছে
      paymentMethod: Payment.paymentMethodFromString(map['paymentMethod']),
      note: map['note']?.toString(),
      description: map['description']?.toString(),
      receiptImageUrl: map['receiptImageUrl']?.toString(),

      // ✅ Handle Timestamp OR String
      date: _asDateTime(map['date']),
    );
  }
}