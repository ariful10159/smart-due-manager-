import 'package:cloud_firestore/cloud_firestore.dart';

class Customer {
  final String id;
  final String name;
  final String phone;
  final String? address;
  final double totalDue;
  final DateTime lastPaymentDate;
  final DateTime createdAt;
  final String? note;
  final DateTime? nextReminderDate;
  final bool isHidden; // ✅ NEW — soft delete flag

  const Customer({
    required this.id,
    required this.name,
    required this.phone,
    required this.totalDue,
    required this.lastPaymentDate,
    required this.createdAt,
    this.note,
    this.nextReminderDate,
    this.address,
    this.isHidden = false, // ✅ NEW — default false (visible)
  });

  // ✅ Safe String parser
  static String _asString(dynamic value, {String fallback = ''}) {
    if (value == null) return fallback;
    return value.toString();
  }

  // ✅ Safe Double parser
  static double _asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0.0;
  }

  // ✅ Safe Bool parser
  static bool _asBool(dynamic value, {bool fallback = false}) {
    if (value is bool) return value;
    if (value == null) return fallback;
    return value.toString().toLowerCase() == 'true';
  }

  // ✅ Safe DateTime parser (non-nullable)
  static DateTime _asDateTime(dynamic value, {DateTime? fallback}) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    return DateTime.tryParse(value?.toString() ?? '') ??
        fallback ??
        DateTime.now();
  }

  // ✅ Safe DateTime parser (nullable)
  static DateTime? _asNullableDateTime(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    return DateTime.tryParse(value.toString());
  }

  // ✅ From Firestore Map
  factory Customer.fromMap(Map<String, dynamic> map) {
    return Customer(
      id: _asString(map['id']),
      name: _asString(map['name']),
      phone: _asString(map['phone']),
      address: map['address']?.toString(),
      totalDue: _asDouble(map['totalDue']),
      lastPaymentDate: _asDateTime(map['lastPaymentDate']),
      createdAt: _asDateTime(map['createdAt']),
      note: map['note']?.toString(),
      nextReminderDate: _asNullableDateTime(map['nextReminderDate']),
      isHidden: _asBool(map['isHidden']), // ✅ NEW
    );
  }

  // ✅ To Firestore Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'address': address,
      'totalDue': totalDue,
      'lastPaymentDate': Timestamp.fromDate(lastPaymentDate),
      'createdAt': Timestamp.fromDate(createdAt),
      'note': note,
      'nextReminderDate': nextReminderDate != null
          ? Timestamp.fromDate(nextReminderDate!)
          : null,
      'isHidden': isHidden, // ✅ NEW
    };
  }

  // ✅ CopyWith (Updated with isHidden)
  Customer copyWith({
    String? id,
    String? name,
    String? phone,
    String? address,
    double? totalDue,
    DateTime? lastPaymentDate,
    DateTime? createdAt,
    String? note,
    DateTime? nextReminderDate,
    bool? isHidden,
  }) {
    return Customer(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      totalDue: totalDue ?? this.totalDue,
      lastPaymentDate: lastPaymentDate ?? this.lastPaymentDate,
      createdAt: createdAt ?? this.createdAt,
      note: note ?? this.note,
      nextReminderDate: nextReminderDate ?? this.nextReminderDate,
      isHidden: isHidden ?? this.isHidden,
    );
  }
}