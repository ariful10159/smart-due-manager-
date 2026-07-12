import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/customer.dart';
import '../models/payment.dart';
import '../models/customer_repository.dart';
import '../services/notification_service.dart';
import '../widgets/payment_history_tile.dart';
import 'add_payment_screen.dart';

class CustomerDetailScreen extends StatefulWidget {
  const CustomerDetailScreen({
    super.key,
    required this.customer,
  });

  final Customer customer;

  @override
  State<CustomerDetailScreen> createState() =>
      _CustomerDetailScreenState();
}

class _CustomerDetailScreenState
    extends State<CustomerDetailScreen> {
  final _customerRepo = CustomerRepository();

  Future<void> _editCustomer(Customer customer) async {
    final nameController =
        TextEditingController(text: customer.name);
    final phoneController =
        TextEditingController(text: customer.phone);
    final addressController =
        TextEditingController(text: customer.address ?? '');
    final noteController =
        TextEditingController(text: customer.note ?? '');

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Edit Customer"),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: nameController,
                decoration:
                    const InputDecoration(labelText: "Name"),
              ),
              TextField(
                controller: phoneController,
                decoration:
                    const InputDecoration(labelText: "Phone"),
              ),
              TextField(
                controller: addressController,
                decoration:
                    const InputDecoration(labelText: "Address"),
              ),
              TextField(
                controller: noteController,
                decoration:
                    const InputDecoration(labelText: "Note"),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              await _customerRepo.updateCustomerInfo(
                customerId: customer.id,
                name: nameController.text.trim(),
                phone: phoneController.text.trim(),
                address: addressController.text.trim(),
                note: noteController.text.trim(),
              );
              if (!mounted) return;
              Navigator.pop(context);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  Future<void> _addPayment(
      Customer currentCustomer,
      PaymentType type) async {
    final payment =
        await Navigator.of(context).push<Payment>(
      MaterialPageRoute(
        builder: (_) =>
            AddPaymentScreen(
                customer: currentCustomer,
                type: type),
      ),
    );

    if (payment == null) return;

    double updatedDue =
        type == PaymentType.payment
            ? currentCustomer.totalDue -
                payment.amount
            : currentCustomer.totalDue +
                payment.amount;

    if (updatedDue < 0) updatedDue = 0;

    await _customerRepo.updateCustomerDue(
      customerId: currentCustomer.id,
      newTotalDue: updatedDue,
      lastPaymentDate: DateTime.now(),
    );

    await _customerRepo.addPayment(
      customerId: currentCustomer.id,
      payment: payment,
    );
  }

  Future<void> _setReminder(Customer customer) async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate:
          DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );

    if (selectedDate == null) return;

    final selectedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (selectedTime == null) return;

    final scheduledDateTime = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      selectedTime.hour,
      selectedTime.minute,
    );

    if (scheduledDateTime.isBefore(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Select future time"),
        ),
      );
      return;
    }

    await _customerRepo.updateReminderDate(
      customerId: customer.id,
      reminderDate: scheduledDateTime,
    );

    await NotificationService.scheduleReminder(
      id: customer.hashCode,
      title: "Payment Reminder",
      body: "${customer.name} will pay now",
      scheduledDate: scheduledDateTime,
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Reminder Set ✅"),
      ),
    );
  }

  String _formatDateTime(DateTime date) {
    return DateFormat('d MMMM yyyy • hh:mm a')
        .format(date);
  }

  String _formatDateOnly(DateTime date) {
    return DateFormat('d MMMM yyyy')
        .format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.customer.name),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () =>
                _editCustomer(widget.customer),
          ),
        ],
      ),
      body: StreamBuilder<Customer>(
        stream: _customerRepo
            .streamCustomerById(widget.customer.id),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
                child:
                    CircularProgressIndicator());
          }

          final customer = snapshot.data!;

          return Padding(
            padding:
                const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [

                Text(
                  customer.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),

                Text(customer.phone,
                    style: const TextStyle(
                        color: Colors.grey)),

                if (customer.address != null) ...[
                  const SizedBox(height: 4),
                  Text(customer.address!,
                      style: const TextStyle(
                          color: Colors.grey)),
                ],

                const SizedBox(height: 6),

                // ✅ THIS IS THE DATE FROM ADD CUSTOMER SCREEN
                Text(
                  "Due date: ${_formatDateOnly(customer.lastPaymentDate)}",
                  style: const TextStyle(
                      color: Colors.grey),
                ),

                const SizedBox(height: 10),

                Text(
                  "Total Due: ${customer.totalDue.toStringAsFixed(2)}",
                  style: TextStyle(
                    fontWeight:
                        FontWeight.bold,
                    color: customer.totalDue >
                            0
                        ? Colors.red
                        : Colors.green,
                  ),
                ),

                if (customer.nextReminderDate != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    "Next Reminder: ${_formatDateTime(customer.nextReminderDate!)}",
                    style: const TextStyle(
                        color: Colors.orange),
                  ),
                ],

                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () =>
                            _addPayment(
                                customer,
                                PaymentType.payment),
                        child: const Text(
                            "Record Payment"),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () =>
                            _addPayment(
                                customer,
                                PaymentType.dueAdded),
                        child: const Text(
                            "Add Charge"),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () =>
                        _setReminder(customer),
                    icon:
                        const Icon(Icons.alarm),
                    label: const Text(
                        "Set Reminder"),
                  ),
                ),

                const SizedBox(height: 20),

                const Text(
                  "Payment History",
                  style: TextStyle(
                      fontWeight:
                          FontWeight.bold),
                ),

                const SizedBox(height: 10),

                Expanded(
                  child:
                      StreamBuilder<
                          List<Payment>>(
                    stream: _customerRepo
                        .streamPayments(customer.id),
                    builder: (context,
                        paymentSnapshot) {
                      if (!paymentSnapshot.hasData) {
                        return const Center(
                            child:
                                CircularProgressIndicator());
                      }

                      final payments =
                          paymentSnapshot.data!;

                      if (payments.isEmpty) {
                        return const Center(
                          child: Text(
                              "No transactions yet"),
                        );
                      }

                      return ListView.separated(
                        itemCount: payments.length,
                        separatorBuilder:
                            (_, __) =>
                                const SizedBox(
                                    height: 8),
                        itemBuilder:
                            (context,
                                index) {
                          return PaymentHistoryTile(
                              payment:
                                  payments[index]);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}