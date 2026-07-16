import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/payment.dart';

class ReportRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// বর্তমান লগইন করা ইউজারের (Owner) আইডি রিটার্ন করে
  String? get _currentUserId => _auth.currentUser?.uid;

  /// নির্দিষ্ট ডেট রেঞ্জের (Start Date থেকে End Date) মধ্যে
  /// এই ইউজারের সমস্ত কাস্টমারদের পেমেন্ট হিস্ট্রি ও নতুন কাস্টমার তৈরির ডেটা ফেচ করে।
  Future<Map<String, dynamic>> fetchReportData({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final ownerId = _currentUserId;
    if (ownerId == null) {
      throw Exception("User not authenticated.");
    }

    double totalCollection = 0.0;
    double totalChargesAdded = 0.0;
    int newCustomersCount = 0;
    List<Payment> periodPayments = [];

    try {
      // ১. প্রথমে এই Owner-এর সমস্ত Customers-এর ডকুমেন্ট ফেচ করা হচ্ছে
      final customersSnapshot = await _firestore
          .collection('customers')
          .where('ownerId', isEqualTo: ownerId)
          .get();

      final customerDocs = customersSnapshot.docs;

      // ২. নির্দিষ্ট পিরিয়ডের মধ্যে কতজন নতুন কাস্টমার জয়েন করেছে তা গণনা
      for (var doc in customerDocs) {
        final data = doc.data();
        if (data['createdAt'] != null) {
          final DateTime createdAt = (data['createdAt'] as Timestamp).toDate();
          if (createdAt.isAfter(startDate) && createdAt.isBefore(endDate)) {
            newCustomersCount++;
          }
        }

        final customerId = doc.id;

        // ৩. প্রতিটি কাস্টমারের 'payments' সাব-কালেকশন থেকে নির্দিষ্ট ডেট রেঞ্জের ডেটা কুয়েরি
        final paymentsSnapshot = await _firestore
            .collection('customers')
            .doc(customerId)
            .collection('payments')
            .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
            .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
            .get();

        for (var payDoc in paymentsSnapshot.docs) {
          final paymentData = payDoc.data();
          final payment = Payment.fromMap(paymentData);
          periodPayments.add(payment);

          // কালেকশন এবং অ্যাড চার্জ হিসাব করা
          if (payment.type == PaymentType.payment) {
            totalCollection += payment.amount;
          } else if (payment.type == PaymentType.dueAdded) {
            totalChargesAdded += payment.amount;
          }
        }
      }

      // ৪. পেমেন্টগুলোকে তারিখ অনুযায়ী সাজানো (সরাসরি গ্রাফে দেখানোর সুবিধার্থে)
      periodPayments.sort((a, b) => a.date.compareTo(b.date));

      final double netCollection = totalCollection - totalChargesAdded;

      return {
        'collection': totalCollection,
        'chargesAdded': totalChargesAdded,
        'net': netCollection,
        'newCustomers': newCustomersCount,
        'payments': periodPayments,
      };
    } catch (e) {
      print("Error fetching report data: $e");
      rethrow;
    }
  }
}