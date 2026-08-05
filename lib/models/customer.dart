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
  final bool isHidden;
  final String? photoUrl;
  final String ownerId; // ✅ NEW — কোন user এই customer এর মালিক
  final Map<String, String> customFields;

  const Customer({
    required this.id,
    required this.name,
    required this.phone,
    required this.totalDue,
    required this.lastPaymentDate,
    required this.createdAt,
    required this.ownerId, // ✅ NEW
    this.note,
    this.nextReminderDate,
    this.address,
    this.isHidden = false,
    this.photoUrl,
    this.customFields = const {},
  });

  static String _asString(dynamic value, {String fallback = ''}) {
    if (value == null) return fallback;
    return value.toString();
  }

  static double _asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0.0;
  }

  static bool _asBool(dynamic value, {bool fallback = false}) {
    if (value is bool) return value;
    if (value == null) return fallback;
    return value.toString().toLowerCase() == 'true';
  }

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

  static DateTime? _asNullableDateTime(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    return DateTime.tryParse(value.toString());
  }

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
      isHidden: _asBool(map['isHidden']),
      photoUrl: map['photoUrl']?.toString(),
      ownerId: _asString(map['ownerId']), // ✅ NEW
      customFields: _asStringMap(map['customFields']),
    );
  }

  static Map<String, String> _asStringMap(dynamic value) {
    if (value is Map) {
      return value.map(
        (key, val) => MapEntry(key.toString(), val?.toString() ?? ''),
      );
    }
    return const {};
  }

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
      'isHidden': isHidden,
      'photoUrl': photoUrl,
      'ownerId': ownerId, // ✅ NEW
      'customFields': customFields,
    };
  }

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
    String? photoUrl,
    String? ownerId,
    Map<String, String>? customFields,
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
      photoUrl: photoUrl ?? this.photoUrl,
      ownerId: ownerId ?? this.ownerId,
      customFields: customFields ?? this.customFields,
    );
  }
}