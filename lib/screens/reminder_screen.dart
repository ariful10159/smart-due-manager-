import 'package:flutter/material.dart';
import '../models/customer.dart';
import '../models/customer_repository.dart';
import 'customer_detail_screen.dart';

class ReminderScreen extends StatelessWidget {
  const ReminderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = CustomerRepository();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Reminders"),
        centerTitle: true,
      ),
      body: StreamBuilder<List<Customer>>(
        stream: repo.streamCustomers(),
        builder: (context, snapshot) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          final allCustomers = snapshot.data ?? [];

          // ✅ Only customers with reminder date
          final remindedCustomers = allCustomers
              .where((c) => c.nextReminderDate != null)
              .toList();

          // ✅ Ascending order (nearest first)
          remindedCustomers.sort(
            (a, b) => a.nextReminderDate!
                .compareTo(b.nextReminderDate!),
          );

          if (remindedCustomers.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_off_outlined,
                    size: 64,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 12),
                  Text(
                    "No reminders set yet",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: remindedCustomers.length,
            separatorBuilder: (_, __) =>
                const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final customer = remindedCustomers[index];
              final reminderDate =
                  customer.nextReminderDate!;

              // ✅ Check overdue
              final isOverdue =
                  reminderDate.isBefore(DateTime.now());

              return Card(
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),

                  // ✅ Icon
                  leading: CircleAvatar(
                    backgroundColor: isOverdue
                        ? Colors.red
                        : Colors.orange,
                    child: Icon(
                      isOverdue
                          ? Icons.alarm_off
                          : Icons.alarm,
                      color: Colors.white,
                    ),
                  ),

                  // ✅ Customer name
                  title: Text(
                    customer.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  // ✅ Reminder date
                  subtitle: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.calendar_today,
                            size: 14,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatDateTime(reminderDate),
                            style: TextStyle(
                              color: isOverdue
                                  ? Colors.red
                                  : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isOverdue
                            ? "⚠️ Overdue"
                            : "✅ Upcoming",
                        style: TextStyle(
                          color: isOverdue
                              ? Colors.red
                              : Colors.green,
                          fontWeight:
                              FontWeight.w500,
                        ),
                      ),
                    ],
                  ),

                  // ✅ Total Due
                  trailing: Text(
                    customer.totalDue
                        .toStringAsFixed(2),
                    style: TextStyle(
                      color: customer.totalDue > 0
                          ? Colors.red
                          : Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  // ✅ Go to customer detail
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            CustomerDetailScreen(
                          customer: customer,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _formatDateTime(DateTime date) {
    return '${date.day}-${date.month}-${date.year} '
        '${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}