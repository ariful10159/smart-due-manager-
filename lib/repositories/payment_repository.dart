import '../models/payment.dart';

class PaymentRepository {
  const PaymentRepository();

  Stream<List<Payment>> watchPayments(String customerId) {
    return const Stream<List<Payment>>.empty();
  }
}
