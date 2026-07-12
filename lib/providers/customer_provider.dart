import '../models/customer.dart';
import '../repositories/customer_repository.dart';

class CustomerProvider {
  const CustomerProvider({required this.repository});

  final CustomerRepository repository;

  Stream<List<Customer>> watchCustomers() => repository.watchCustomers();
}
