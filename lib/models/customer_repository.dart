import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'customer.dart';
import 'payment.dart';

class CustomerRepository {
  CustomerRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _col =>
      _firestore.collection('customers');

  CollectionReference<Map<String, dynamic>> _reminderCol(String customerId) {
    return _col.doc(customerId).collection('reminders');
  }

  // ✅ Payments subcollection reference
  CollectionReference<Map<String, dynamic>> _paymentsCol(String customerId) {
    return _col.doc(customerId).collection('payments');
  }

  // ✅ SMS log subcollection reference  
  CollectionReference<Map<String, dynamic>> _smsLogsCol(String customerId) {    
    return _col.doc(customerId).collection('smsLogs');  
  }

  // ✅ বর্তমান login করা user এর ID
  String get _currentUserId {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      throw Exception('User not logged in');
    }
    return uid;
  }

  // ✅ Stream all VISIBLE customers — শুধু বর্তমান user এর নিজের customer
  Stream<List<Customer>> streamCustomers() {
    return _col
        .where('ownerId', isEqualTo: _currentUserId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Customer.fromMap({...doc.data(), 'id': doc.id}))
          .where((customer) => !customer.isHidden)
          .toList();
    });
  }

  // ✅ Stream all HIDDEN/Archived customers — শুধু বর্তমান user এর
  Stream<List<Customer>> streamHiddenCustomers() {
    return _col
        .where('ownerId', isEqualTo: _currentUserId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Customer.fromMap({...doc.data(), 'id': doc.id}))
          .where((customer) => customer.isHidden)
          .toList();
    });
  }

  // ✅ Stream single customer by id
  Stream<Customer> streamCustomerById(String id) {
    return _col.doc(id).snapshots().map((doc) {
      return Customer.fromMap({...doc.data()!, 'id': doc.id});
    });
  }

  // ✅ Fetch once — শুধু বর্তমান user এর customer
  Future<List<Customer>> fetchCustomersOnce() async {
    final snapshot =
        await _col.where('ownerId', isEqualTo: _currentUserId).get();

    return snapshot.docs.map((doc) {
      return Customer.fromMap({...doc.data(), 'id': doc.id});
    }).toList();
  }

  // ✅ Update customer basic info (EDIT SUPPORT) - সুরক্ষিত ও ডাইনামিক
  Future<void> updateCustomerInfo({
    required String customerId,
    String? name,
    String? phone,
    String? address,
    String? note,
    double? totalDue,
    DateTime? lastPaymentDate, // null মানে "পরিবর্তন করো না", আগের তারিখ সুরক্ষিত থাকবে
    String? photoUrl,
  }) async {
    final data = <String, dynamic>{};

    // শুধু যে ফিল্ডগুলোতে নতুন ডেটা পাঠানো হয়েছে, সেগুলোই আপডেট হবে
    if (name != null) data['name'] = name;
    if (phone != null) data['phone'] = phone;
    if (address != null) data['address'] = address;
    if (note != null) data['note'] = note;
    if (totalDue != null) data['totalDue'] = totalDue;
    if (lastPaymentDate != null) data['lastPaymentDate'] = Timestamp.fromDate(lastPaymentDate);
    if (photoUrl != null) data['photoUrl'] = photoUrl;

    // যদি আপডেট করার মতো কোনো ফিল্ড না থাকে, তবে ফাংশন এখানেই শেষ হবে
    if (data.isEmpty) return;

    await _col.doc(customerId).update(data);
  }

  // ✅ Update due
  Future<void> updateCustomerDue({
    required String customerId,
    required double newTotalDue,
    required DateTime lastPaymentDate,
  }) async {
    await _col.doc(customerId).update({
      'totalDue': newTotalDue,
      'lastPaymentDate': Timestamp.fromDate(lastPaymentDate),
    });
  }

  // ✅ Update reminder date
  Future<void> updateReminderDate({
    required String customerId,
    required DateTime reminderDate,
  }) async {
    await _col.doc(customerId).update({
      'nextReminderDate': Timestamp.fromDate(reminderDate),
    });
  }

  // ✅ Cancel reminder
  Future<void> clearReminder(String customerId) async {
    await _col.doc(customerId).update({'nextReminderDate': null});
  }

  // ✅ Add payment
  Future<void> addPayment({
    required String customerId,
    required Payment payment,
  }) async {
    await _paymentsCol(customerId).doc(payment.id).set(payment.toMap());
  }

  // ✅ প্রতিবার SMS পাঠানোর পর একটা log entry যোগ করা  
  Future<void> logSmsSent({    
    required String customerId,    
    required String type, // 'manual' অথবা 'reminder'  
  }) async {    
    await _smsLogsCol(customerId).add({      
      'sentAt': Timestamp.now(),      
      'type': type,    
    });  
  }  

  // ✅ SMS history stream (সময় অনুযায়ী নতুন আগে)  
  Stream<List<Map<String, dynamic>>> streamSmsLogs(String customerId) {    
    return _smsLogsCol(customerId)        
        .orderBy('sentAt', descending: true)        
        .snapshots()        
        .map((snapshot) => snapshot.docs.map((e) => e.data()).toList());  
  }

  // ✅ Add new reminder
  Future<void> addReminder({
    required String customerId,
    required DateTime reminderDate,
  }) async {
    final reminderId = DateTime.now().millisecondsSinceEpoch.toString();

    // 1️⃣ Save old active reminder to history (if exists)
    final customerDoc = await _col.doc(customerId).get();
    final oldReminder = customerDoc.data()?['nextReminderDate'];

    if (oldReminder != null) {
      await _reminderCol(customerId).doc('${reminderId}_old').set({
        'id': '${reminderId}_old',
        'reminderDate': oldReminder,
        'createdAt': Timestamp.now(),
        'status': 'expired',
      });
    }

    // 2️⃣ Set new active reminder
    await _col.doc(customerId).update({
      'nextReminderDate': Timestamp.fromDate(reminderDate),
    });

    // 3️⃣ Save new reminder to history
    await _reminderCol(customerId).doc(reminderId).set({
      'id': reminderId,
      'reminderDate': Timestamp.fromDate(reminderDate),
      'createdAt': Timestamp.now(),
      'status': 'active',
    });
  }

  // ✅ Stream reminder history
  Stream<List<Map<String, dynamic>>> streamReminderHistory(String customerId) {
    return _reminderCol(customerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((e) => e.data()).toList());
  }

  // ✅ Stream payments
  Stream<List<Payment>> streamPayments(String customerId) {
    return _paymentsCol(
      customerId,
    ).orderBy('date', descending: true).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return Payment.fromMap({...doc.data(), 'id': doc.id});
      }).toList();
    });
  }

  // ✅ Hide customer (SOFT DELETE)
  Future<void> hideCustomer(String customerId) async {
    await _col.doc(customerId).update({'isHidden': true});
  }

  // ✅ Restore customer (Hidden থেকে আবার Visible করা)
  Future<void> restoreCustomer(String customerId) async {
    await _col.doc(customerId).update({'isHidden': false});
  }

  // ✅ CSV থেকে parse করা customer গুলো import করা — ফোন নাম্বার দিয়ে duplicate
  // detect করে skip করে (বর্তমান user এর existing customer দের সাথে, এবং একই CSV
  // এর মধ্যেও), বাকিদের fresh doc id ও বর্তমান user এর ownerId দিয়ে ব্যাচে লেখে।
  Future<({int imported, int skipped})> importCustomers(
    List<Customer> parsedRows,
  ) async {
    final existing = await fetchCustomersOnce();
    final seenPhones = existing
        .map((c) => c.phone.trim())
        .where((p) => p.isNotEmpty)
        .toSet();

    final toImport = <Customer>[];
    var skipped = 0;

    for (final row in parsedRows) {
      final phone = row.phone.trim();
      if (phone.isNotEmpty && seenPhones.contains(phone)) {
        skipped++;
        continue;
      }
      if (phone.isNotEmpty) seenPhones.add(phone);
      toImport.add(row);
    }

    const chunkSize = 450; // Firestore batch limit ৫০০ অপারেশন, buffer রাখা হলো
    for (var i = 0; i < toImport.length; i += chunkSize) {
      final chunk = toImport.sublist(
        i,
        (i + chunkSize) > toImport.length ? toImport.length : i + chunkSize,
      );
      final batch = _firestore.batch();
      for (final row in chunk) {
        final docRef = _col.doc();
        batch.set(
          docRef,
          row.copyWith(id: docRef.id, ownerId: _currentUserId).toMap(),
        );
      }
      await batch.commit();
    }

    return (imported: toImport.length, skipped: skipped);
  }

  // ✅ Permanently delete customer (with all subcollections)
  Future<void> deleteCustomerPermanently(String customerId) async {
    final paymentsSnapshot = await _paymentsCol(customerId).get();
    for (final doc in paymentsSnapshot.docs) {
      await doc.reference.delete();
    }

    final remindersSnapshot = await _reminderCol(customerId).get();
    for (final doc in remindersSnapshot.docs) {
      await doc.reference.delete();
    }

    await _col.doc(customerId).delete();
  }
}