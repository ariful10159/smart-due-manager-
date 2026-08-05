import 'package:cloud_firestore/cloud_firestore.dart';

class Reminder {
  final String id;
  final DateTime reminderDate;
  final DateTime createdAt;
  final String status; // active, expired, completed
  final String note;

  Reminder({
    required this.id,
    required this.reminderDate,
    required this.createdAt,
    required this.status,
    this.note = '',
  });

  factory Reminder.fromMap(Map<String, dynamic> map) {
    return Reminder(
      id: map['id'],
      reminderDate:
          (map['reminderDate'] as Timestamp).toDate(),
      createdAt:
          (map['createdAt'] as Timestamp).toDate(),
      status: map['status'],
      note: map['note'] ?? '',
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
      'note': note,
    };
  }
}