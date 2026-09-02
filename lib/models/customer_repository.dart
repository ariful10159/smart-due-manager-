import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../services/activity_log_service.dart';
import 'customer.dart';
import 'payment.dart';

const List<String> kRecurrenceTypes = ['weekly', 'biweekly', 'monthly'];

// ✅ এক সাইকেল এগিয়ে দেওয়া — মাসিক হলে ক্যালেন্ডার মাস অনুযায়ী (তারিখ drift এড়াতে,
// মাসের শেষ দিনের বেশি হলে সেই মাসের শেষ দিনে ক্ল্যাম্প করা হয়)
DateTime _advanceOnce(DateTime date, String recurrenceType) {
  switch (recurrenceType) {
    case 'weekly':
      return date.add(const Duration(days: 7));
    case 'biweekly':
      return date.add(const Duration(days: 14));
    case 'monthly':
    default:
      final nextMonth = date.month == 12 ? 1 : date.month + 1;
      final nextYear = date.month == 12 ? date.year + 1 : date.year;
      final daysInNextMonth = DateTime(nextYear, nextMonth + 1, 0).day;
      final day = date.day > daysInNextMonth ? daysInNextMonth : date.day;
      return DateTime(nextYear, nextMonth, day, date.hour, date.minute);
  }
}

// ✅ পরবর্তী reminder এর তারিখ বের করা — অ্যাপ কয়েক সাইকেল বন্ধ থাকলেও (যেমন কয়েক
// মাস না খোলা হলে) অতীতে আটকে না থেকে সরাসরি পরবর্তী ভবিষ্যৎ তারিখে "ক্যাচ-আপ" করে
DateTime nextRecurrenceDate({required DateTime from, required String recurrenceType}) {
  var next = _advanceOnce(from, recurrenceType);
  final now = DateTime.now();
  while (next.isBefore(now)) {
    next = _advanceOnce(next, recurrenceType);
  }
  return next;
}

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
    unawaited(ActivityLogService.log('edit_customer', details: {'customerId': customerId}));
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

  // ✅ Cancel reminder — recurring হলে সাইকেলও পুরোপুরি বন্ধ হয়ে যায়
  Future<void> clearReminder(String customerId) async {
    await _col.doc(customerId).update({
      'nextReminderDate': null,
      'isRecurringReminder': false,
      'recurrenceType': null,
    });
  }

  // ✅ Add payment
  Future<void> addPayment({
    required String customerId,
    required Payment payment,
  }) async {
    // ✅ 'ownerId' এখানে লেখা হয় যাতে পরে collectionGroup query দিয়ে (সব
    // কাস্টমারের payments subcollection একসাথে) সরাসরি নিজের পেমেন্ট ফিল্টার
    // করা যায় — parent customer doc এর জন্য আলাদা get() লাগে না
    await _paymentsCol(customerId).doc(payment.id).set({
      ...payment.toMap(),
      'ownerId': _currentUserId,
    });
    unawaited(ActivityLogService.log('add_payment', details: {
      'customerId': customerId,
      'amount': payment.amount,
      'type': payment.type.name,
    }));
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

  // ✅ Add new reminder — isRecurring true হলে recurrenceType অনুযায়ী প্রতি সাইকেলে
  // (weekly/biweekly/monthly) নিজে থেকেই আবার শিডিউল হবে, ম্যানুয়ালি বারবার সেট করতে হবে না
  Future<void> addReminder({
    required String customerId,
    required DateTime reminderDate,
    String? note,
    bool isRecurring = false,
    String? recurrenceType,
  }) async {
    final reminderId = DateTime.now().millisecondsSinceEpoch.toString();

    // 1️⃣ Mark any previously active reminder(s) as expired, instead of
    // duplicating them into a separate history entry
    final activeReminders = await _reminderCol(customerId)
        .where('status', isEqualTo: 'active')
        .get();

    for (final doc in activeReminders.docs) {
      await doc.reference.update({'status': 'expired'});
    }

    // 2️⃣ Set new active reminder
    await _col.doc(customerId).update({
      'nextReminderDate': Timestamp.fromDate(reminderDate),
      'isRecurringReminder': isRecurring,
      'recurrenceType': isRecurring ? recurrenceType : null,
    });

    // 3️⃣ Save new reminder to history
    await _reminderCol(customerId).doc(reminderId).set({
      'id': reminderId,
      'reminderDate': Timestamp.fromDate(reminderDate),
      'createdAt': Timestamp.now(),
      'status': 'active',
      'note': note?.trim() ?? '',
      'isRecurring': isRecurring,
      'recurrenceType': isRecurring ? recurrenceType : null,
    });
  }

  // ✅ Recurring reminder এর বর্তমান সাইকেল "done" মার্ক করে পরের সাইকেলে auto-advance
  // করা হয় — recurrence বন্ধ না করে, শুধু পরবর্তী তারিখে reschedule করা হয়
  Future<DateTime?> advanceRecurringReminder(Customer customer) async {
    if (!customer.isRecurringReminder ||
        customer.recurrenceType == null ||
        customer.nextReminderDate == null) {
      return null;
    }

    final nextDate = nextRecurrenceDate(
      from: customer.nextReminderDate!,
      recurrenceType: customer.recurrenceType!,
    );

    await addReminder(
      customerId: customer.id,
      reminderDate: nextDate,
      isRecurring: true,
      recurrenceType: customer.recurrenceType,
    );

    return nextDate;
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

  // ✅ প্রতিটা কাস্টমারের payments subcollection আলাদা আলাদা query না করে
  // collectionGroup দিয়ে বর্তমান ইউজারের ALL payments একটা মাত্র query-তে আনা
  // হয় (home screen এর today/week collection স্ট্যাটের জন্য) — 193 আলাদা query
  // এর বদলে একটাই, আর প্রতিটার parent-customer ownership-চেক get() ও লাগে না
  Future<List<Payment>> fetchOwnPaymentsSince(DateTime since) async {
    final snapshot = await _firestore
        .collectionGroup('payments')
        .where('ownerId', isEqualTo: _currentUserId)
        .where('type', isEqualTo: PaymentType.payment.name)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(since))
        .get();

    return snapshot.docs
        .map((doc) => Payment.fromMap({...doc.data(), 'id': doc.id}))
        .toList();
  }

  // ✅ Hide customer (SOFT DELETE)
  Future<void> hideCustomer(String customerId) async {
    await _col.doc(customerId).update({'isHidden': true});
    unawaited(ActivityLogService.log('archive_customer', details: {'customerId': customerId}));
  }

  // ✅ Restore customer (Hidden থেকে আবার Visible করা)
  Future<void> restoreCustomer(String customerId) async {
    await _col.doc(customerId).update({'isHidden': false});
    unawaited(ActivityLogService.log('restore_customer', details: {'customerId': customerId}));
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
    unawaited(ActivityLogService.log('delete_customer', details: {'customerId': customerId}));
  }
}