import 'package:cloud_firestore/cloud_firestore.dart';

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

  // ✅ Stream all customers
  Stream<List<Customer>> streamCustomers() {
    return _col.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return Customer.fromMap({...doc.data(), 'id': doc.id});
      }).toList();
    });
  }

  // ✅ Stream single customer by id
  Stream<Customer> streamCustomerById(String id) {
    return _col.doc(id).snapshots().map((doc) {
      return Customer.fromMap({...doc.data()!, 'id': doc.id});
    });
  }

  // ✅ Fetch once
  Future<List<Customer>> fetchCustomersOnce() async {
    final snapshot = await _col.get();

    return snapshot.docs.map((doc) {
      return Customer.fromMap({...doc.data(), 'id': doc.id});
    }).toList();
  }

  // ✅ Update customer basic info (EDIT SUPPORT)
  Future<void> updateCustomerInfo({
    required String customerId,
    required String name,
    required String phone,
    String? address,
    String? note,
  }) async {
    await _col.doc(customerId).update({
      'name': name,
      'phone': phone,
      'address': address,
      'note': note,
    });
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

  // ✅ Delete customer (BONUS)
  Future<void> deleteCustomer(String customerId) async {
    await _col.doc(customerId).delete();
  }
}
