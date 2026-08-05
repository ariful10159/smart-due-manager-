import 'package:cloud_firestore/cloud_firestore.dart';

class Notebook {
  final String id;
  final String ownerId;
  final String title;
  final String description;
  final int coverColor;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Notebook({
    required this.id,
    required this.ownerId,
    required this.title,
    required this.description,
    required this.coverColor,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Notebook.fromMap(Map<String, dynamic> map) {
    return Notebook(
      id: map['id'] as String,
      ownerId: map['ownerId'] as String? ?? '',
      title: (map['title'] as String?)?.trim().isNotEmpty == true
          ? map['title'] as String
          : 'Untitled Notebook',
      description: map['description'] as String? ?? '',
      coverColor: map['coverColor'] as int? ?? 0xFF6C5CE7,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'ownerId': ownerId,
      'title': title,
      'description': description,
      'coverColor': coverColor,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  Notebook copyWith({
    String? title,
    String? description,
    int? coverColor,
    DateTime? updatedAt,
  }) {
    return Notebook(
      id: id,
      ownerId: ownerId,
      title: title ?? this.title,
      description: description ?? this.description,
      coverColor: coverColor ?? this.coverColor,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
