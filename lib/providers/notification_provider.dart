import '../repositories/notification_service.dart';

class NotificationProvider {
  const NotificationProvider({required this.service});

  final NotificationService service;

  Future<void> notifyDue(String customerId, double amount) {
    return service.notifyDue(customerId, amount);
  }
}
