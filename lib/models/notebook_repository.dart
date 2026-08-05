import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'notebook.dart';
import 'notebook_page.dart';

class NotebookRepository {
  NotebookRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _col =>
      _firestore.collection('notebooks');

  CollectionReference<Map<String, dynamic>> _pagesCol(String notebookId) {
    return _col.doc(notebookId).collection('pages');
  }

  String get _currentUserId {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      throw Exception('User not logged in');
    }
    return uid;
  }

  // ✅ বর্তমান user এর সব notebook stream করা হচ্ছে
  Stream<List<Notebook>> streamNotebooks() {
    return _col
        .where('ownerId', isEqualTo: _currentUserId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Notebook.fromMap({...doc.data(), 'id': doc.id}))
          .toList();
    });
  }

  // ✅ নতুন notebook তৈরি + একটা ডিফল্ট প্রথম page সহ
  Future<Notebook> createNotebook({
    required String title,
    String description = '',
    int coverColor = 0xFF6C5CE7,
  }) async {
    final now = DateTime.now();
    final docRef = _col.doc();

    final notebook = Notebook(
      id: docRef.id,
      ownerId: _currentUserId,
      title: title.trim().isEmpty ? 'Untitled Notebook' : title.trim(),
      description: description.trim(),
      coverColor: coverColor,
      createdAt: now,
      updatedAt: now,
    );

    await docRef.set(notebook.toMap());
    await createPage(notebookId: notebook.id, title: 'Page 1');

    return notebook;
  }

  Future<void> updateNotebook({
    required String notebookId,
    String? title,
    String? description,
    int? coverColor,
  }) async {
    final data = <String, dynamic>{'updatedAt': Timestamp.now()};
    if (title != null) data['title'] = title.trim().isEmpty ? 'Untitled Notebook' : title.trim();
    if (description != null) data['description'] = description.trim();
    if (coverColor != null) data['coverColor'] = coverColor;

    await _col.doc(notebookId).update(data);
  }

  Future<void> touchNotebook(String notebookId) async {
    await _col.doc(notebookId).update({'updatedAt': Timestamp.now()});
  }

  Future<void> deleteNotebook(String notebookId) async {
    final pagesSnapshot = await _pagesCol(notebookId).get();
    final batch = _firestore.batch();
    for (final doc in pagesSnapshot.docs) {
      batch.delete(doc.reference);
    }
    batch.delete(_col.doc(notebookId));
    await batch.commit();
  }

  Future<Notebook> duplicateNotebook(Notebook source) async {
    final now = DateTime.now();
    final docRef = _col.doc();

    final copy = Notebook(
      id: docRef.id,
      ownerId: _currentUserId,
      title: '${source.title} (Copy)',
      description: source.description,
      coverColor: source.coverColor,
      createdAt: now,
      updatedAt: now,
    );

    await docRef.set(copy.toMap());

    final pagesSnapshot =
        await _pagesCol(source.id).orderBy('order').get();

    final batch = _firestore.batch();
    for (final doc in pagesSnapshot.docs) {
      final page = NotebookPage.fromMap({...doc.data(), 'id': doc.id});
      final newPageRef = _pagesCol(copy.id).doc();
      batch.set(newPageRef, {
        ...page.toMap(),
        'notebookId': copy.id,
      });
    }
    await batch.commit();

    return copy;
  }

  // ✅ একটা notebook এর সব page, order অনুযায়ী stream করা হচ্ছে
  Stream<List<NotebookPage>> streamPages(String notebookId) {
    return _pagesCol(notebookId).orderBy('order').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => NotebookPage.fromMap({...doc.data(), 'id': doc.id}))
          .toList();
    });
  }

  Future<NotebookPage> createPage({
    required String notebookId,
    String title = 'Untitled Page',
  }) async {
    final existing = await _pagesCol(notebookId).get();
    final nextOrder = existing.docs.length;

    final now = DateTime.now();
    final docRef = _pagesCol(notebookId).doc();

    final page = NotebookPage(
      id: docRef.id,
      notebookId: notebookId,
      title: title,
      contentJson: kEmptyQuillDelta,
      order: nextOrder,
      createdAt: now,
      updatedAt: now,
    );

    await docRef.set(page.toMap());
    await touchNotebook(notebookId);

    return page;
  }

  Future<void> renamePage({
    required String notebookId,
    required String pageId,
    required String title,
  }) async {
    await _pagesCol(notebookId).doc(pageId).update({
      'title': title.trim().isEmpty ? 'Untitled Page' : title.trim(),
      'updatedAt': Timestamp.now(),
    });
    await touchNotebook(notebookId);
  }

  Future<void> deletePage({
    required String notebookId,
    required String pageId,
  }) async {
    await _pagesCol(notebookId).doc(pageId).delete();
    await touchNotebook(notebookId);
  }

  Future<NotebookPage> duplicatePage({
    required String notebookId,
    required NotebookPage source,
  }) async {
    final existing = await _pagesCol(notebookId).get();
    final nextOrder = existing.docs.length;

    final now = DateTime.now();
    final docRef = _pagesCol(notebookId).doc();

    final page = NotebookPage(
      id: docRef.id,
      notebookId: notebookId,
      title: '${source.title} (Copy)',
      contentJson: source.contentJson,
      order: nextOrder,
      createdAt: now,
      updatedAt: now,
    );

    await docRef.set(page.toMap());
    await touchNotebook(notebookId);

    return page;
  }

  Future<void> reorderPages({
    required String notebookId,
    required List<NotebookPage> orderedPages,
  }) async {
    final batch = _firestore.batch();
    for (var i = 0; i < orderedPages.length; i++) {
      batch.update(_pagesCol(notebookId).doc(orderedPages[i].id), {'order': i});
    }
    await batch.commit();
  }

  Future<void> updatePageContent({
    required String notebookId,
    required String pageId,
    required String contentJson,
  }) async {
    await _pagesCol(notebookId).doc(pageId).update({
      'content': contentJson,
      'updatedAt': Timestamp.now(),
    });
    await touchNotebook(notebookId);
  }

  // ✅ Editor এ ইনসার্ট করা ছবি Firebase Storage এ আপলোড করে URL রিটার্ন করে
  Future<String> uploadNotebookImage({
    required String notebookId,
    required File file,
  }) async {
    final uid = _currentUserId;
    final imageId = DateTime.now().millisecondsSinceEpoch.toString();
    final ext = file.path.split('.').last.toLowerCase();
    final ref = FirebaseStorage.instance
        .ref('notebook_images/$uid/$notebookId/$imageId.$ext');

    await ref.putFile(file);
    return ref.getDownloadURL();
  }
}
