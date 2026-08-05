import 'package:cloud_firestore/cloud_firestore.dart';

/// Empty Quill delta JSON — a single trailing newline, matching what a
/// brand-new [QuillController.basic] document serializes to.
const String kEmptyQuillDelta = '[{"insert":"\\n"}]';

class NotebookPage {
  final String id;
  final String notebookId;
  final String title;
  final String contentJson;
  final int order;
  final DateTime createdAt;
  final DateTime updatedAt;

  const NotebookPage({
    required this.id,
    required this.notebookId,
    required this.title,
    required this.contentJson,
    required this.order,
    required this.createdAt,
    required this.updatedAt,
  });

  factory NotebookPage.fromMap(Map<String, dynamic> map) {
    return NotebookPage(
      id: map['id'] as String,
      notebookId: map['notebookId'] as String? ?? '',
      title: (map['title'] as String?)?.trim().isNotEmpty == true
          ? map['title'] as String
          : 'Untitled Page',
      contentJson: map['content'] as String? ?? kEmptyQuillDelta,
      order: map['order'] as int? ?? 0,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'notebookId': notebookId,
      'title': title,
      'content': contentJson,
      'order': order,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}
