import 'package:cloud_firestore/cloud_firestore.dart';

import 'customer.dart';
import 'payment.dart';

class CustomerRepository {
  CustomerRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference get _col =>
      _firestore.collection('customers');

  // ✅ Payments subcollection reference
  CollectionReference _paymentsCol(String customerId) {
    return _col.doc(customerId).collection('payments');
  }

  // ✅ Stream all customers
  Stream<List<Customer>> streamCustomers() {
    return _col.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return Customer.fromMap({
          ...data,
          'id': doc.id,
        });
      }).toList();
    });
  }

  // ✅ Stream single customer by id
  Stream<Customer> streamCustomerById(String id) {
    return _col.doc(id).snapshots().map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return Customer.fromMap({
        ...data,
        'id': doc.id,
      });
    });
  }

  // ✅ Fetch customers once
  Future<List<Customer>> fetchCustomersOnce() async {
    final snapshot = await _col.get();

    return snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return Customer.fromMap({
        ...data,
        'id': doc.id,
      });
    }).toList();
  }

  // ✅ Update customer due
  Future<void> updateCustomerDue({
    required String customerId,
    required double newTotalDue,
    required DateTime lastPaymentDate,
  }) async {
    await _col.doc(customerId).update({
      'totalDue': newTotalDue,
      'lastPaymentDate':
          Timestamp.fromDate(lastPaymentDate),
    });
  }

  // ✅ ✅ NEW: Update reminder date
  Future<void> updateReminderDate({
    required String customerId,
    required DateTime reminderDate,
  }) async {
    await _col.doc(customerId).update({
      'nextReminderDate':
          Timestamp.fromDate(reminderDate),
    });
  }

  // ✅ Add payment to subcollection
  Future<void> addPayment({
    required String customerId,
    required Payment payment,
  }) async {
    await _paymentsCol(customerId)
        .doc(payment.id)
        .set(payment.toMap());
  }

  // ✅ Stream payment history
  Stream<List<Payment>> streamPayments(
      String customerId) {
    return _paymentsCol(customerId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data =
            doc.data() as Map<String, dynamic>;
        return Payment.fromMap({
          ...data,
          'id': doc.id,
        });
      }).toList();
    });
  }
}