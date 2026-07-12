import '../models/payment.dart';
import '../repositories/payment_repository.dart';

class PaymentProvider {
  const PaymentProvider({required this.repository});

  final PaymentRepository repository;

  Stream<List<Payment>> watchPayments(String customerId) {
    return repository.watchPayments(customerId);
  }
}
