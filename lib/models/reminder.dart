import 'package:cloud_firestore/cloud_firestore.dart';

class Reminder {
  final String id;
  final DateTime reminderDate;
  final DateTime createdAt;
  final String status; // active, expired, completed

  Reminder({
    required this.id,
    required this.reminderDate,
    required this.createdAt,
    required this.status,
  });

  factory Reminder.fromMap(Map<String, dynamic> map) {
    return Reminder(
      id: map['id'],
      reminderDate:
          (map['reminderDate'] as Timestamp).toDate(),
      createdAt:
          (map['createdAt'] as Timestamp).toDate(),
      status: map['status'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'reminderDate':
          Timestamp.fromDate(reminderDate),
      'createdAt':
          Timestamp.fromDate(createdAt),
      'status': status,
    };
  }
}