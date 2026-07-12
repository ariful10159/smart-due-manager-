import '../models/customer.dart';

class CustomerRepository {
  const CustomerRepository();

  Stream<List<Customer>> watchCustomers() =>
      const Stream<List<Customer>>.empty();
}
