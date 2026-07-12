import 'package:cloud_firestore/cloud_firestore.dart';

class Customer {
  final String id;
  final String name;
  final String phone;
  final double totalDue;
  final DateTime lastPaymentDate;
  final DateTime createdAt;
  final String? note;
  final DateTime? nextReminderDate;

  const Customer({
    required this.id,
    required this.name,
    required this.phone,
    required this.totalDue,
    required this.lastPaymentDate,
    required this.createdAt,
    this.note,
    this.nextReminderDate,
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
      totalDue: _asDouble(map['totalDue']),
      lastPaymentDate: _asDateTime(map['lastPaymentDate']),
      createdAt: _asDateTime(map['createdAt']),
      note: map['note']?.toString(),
      nextReminderDate:
          _asNullableDateTime(map['nextReminderDate']),
    );
  }

  // ✅ To Firestore Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'totalDue': totalDue,
      'lastPaymentDate':
          Timestamp.fromDate(lastPaymentDate),
      'createdAt':
          Timestamp.fromDate(createdAt),
      'note': note,
      'nextReminderDate': nextReminderDate != null
          ? Timestamp.fromDate(nextReminderDate!)
          : null,
    };
  }

  // ✅ CopyWith (very useful for future updates)
  Customer copyWith({
    String? id,
    String? name,
    String? phone,
    double? totalDue,
    DateTime? lastPaymentDate,
    DateTime? createdAt,
    String? note,
    DateTime? nextReminderDate,
  }) {
    return Customer(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      totalDue: totalDue ?? this.totalDue,
      lastPaymentDate:
          lastPaymentDate ?? this.lastPaymentDate,
      createdAt: createdAt ?? this.createdAt,
      note: note ?? this.note,
      nextReminderDate:
          nextReminderDate ?? this.nextReminderDate,
    );
  }
}