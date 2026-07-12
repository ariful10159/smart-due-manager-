import 'package:flutter/material.dart';

import '../models/customer.dart';
import '../models/payment.dart';
import '../models/customer_repository.dart';
import '../services/notification_service.dart';
import '../widgets/payment_history_tile.dart';
import 'add_payment_screen.dart';

enum PaymentFilter { all, paymentOnly, chargeOnly }

class CustomerDetailScreen extends StatefulWidget {
  const CustomerDetailScreen({super.key, required this.customer});

  final Customer customer;

  @override
  State<CustomerDetailScreen> createState() =>
      _CustomerDetailScreenState();
}

class _CustomerDetailScreenState
    extends State<CustomerDetailScreen> {
  final _customerRepo = CustomerRepository();

  PaymentFilter _selectedFilter = PaymentFilter.all;

  Future<void> _addPayment(
      Customer currentCustomer, PaymentType type) async {
    final payment = await Navigator.of(context).push<Payment>(
      MaterialPageRoute(
        builder: (_) =>
            AddPaymentScreen(customer: currentCustomer, type: type),
      ),
    );

    if (payment == null) return;

    double updatedDue;

    if (type == PaymentType.payment) {
      updatedDue = currentCustomer.totalDue - payment.amount;
    } else {
      updatedDue = currentCustomer.totalDue + payment.amount;
    }

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

  // ✅ UPDATED REMINDER WITH TIME
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
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select a future time"),
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
        content: Text("Reminder set successfully ✅"),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.customer.name),
        centerTitle: true,
      ),
      body: StreamBuilder<Customer>(
        stream:
            _customerRepo.streamCustomerById(widget.customer.id),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
                child: CircularProgressIndicator());
          }

          final customer = snapshot.data!;

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [

                // ✅ Customer Info Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: Theme.of(context).cardColor,
                    boxShadow: [
                      BoxShadow(
                        color:
                            Colors.black.withOpacity(.05),
                        blurRadius: 10,
                        offset:
                            const Offset(0, 4),
                      )
                    ],
                  ),
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
                      const SizedBox(height: 6),
                      Text(
                        customer.phone,
                        style:
                            const TextStyle(
                                color:
                                    Colors.grey),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "Total Due: ${customer.totalDue.toStringAsFixed(2)}",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight:
                              FontWeight.bold,
                          color:
                              customer.totalDue > 0
                                  ? Colors.red
                                  : Colors.green,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "Last Payment: ${_formatDateTime(customer.lastPaymentDate)}",
                        style:
                            const TextStyle(
                                color:
                                    Colors.grey),
                      ),

                      if (customer.nextReminderDate !=
                          null) ...[
                        const SizedBox(height: 6),
                        Text(
                          "Next Reminder: ${_formatDateTime(customer.nextReminderDate!)}",
                          style: const TextStyle(
                              color:
                                  Colors.orange),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // ✅ Buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _addPayment(
                            customer,
                            PaymentType
                                .payment),
                        style: ElevatedButton
                            .styleFrom(
                          backgroundColor:
                              Colors.green,
                        ),
                        child: const Text(
                          "Record Payment",
                          style: TextStyle(
                              color:
                                  Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _addPayment(
                            customer,
                            PaymentType
                                .dueAdded),
                        style: ElevatedButton
                            .styleFrom(
                          backgroundColor:
                              Colors.red,
                        ),
                        child: const Text(
                          "Add Charge",
                          style: TextStyle(
                              color:
                                  Colors.white),
                        ),
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
                    icon: const Icon(Icons.alarm),
                    label:
                        const Text("Set Reminder"),
                    style:
                        ElevatedButton
                            .styleFrom(
                      backgroundColor:
                          Colors.orange,
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                Row(
                  children: [
                    _buildFilterChip(
                        "All",
                        PaymentFilter.all),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                        "Payments",
                        PaymentFilter
                            .paymentOnly),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                        "Charges",
                        PaymentFilter
                            .chargeOnly),
                  ],
                ),

                const SizedBox(height: 12),

                Expanded(
                  child: StreamBuilder<
                      List<Payment>>(
                    stream: _customerRepo
                        .streamPayments(
                            widget.customer
                                .id),
                    builder: (context,
                        paymentSnapshot) {
                      if (!paymentSnapshot
                          .hasData) {
                        return const Center(
                            child:
                                CircularProgressIndicator());
                      }

                      List<Payment>
                          payments =
                          paymentSnapshot
                              .data!;

                      if (_selectedFilter ==
                          PaymentFilter
                              .paymentOnly) {
                        payments =
                            payments
                                .where((p) =>
                                    p.type ==
                                    PaymentType
                                        .payment)
                                .toList();
                      } else if (_selectedFilter ==
                          PaymentFilter
                              .chargeOnly) {
                        payments =
                            payments
                                .where((p) =>
                                    p.type ==
                                    PaymentType
                                        .dueAdded)
                                .toList();
                      }

                      if (payments
                          .isEmpty) {
                        return const Center(
                          child: Text(
                              "No transactions yet"),
                        );
                      }

                      return ListView
                          .separated(
                        itemCount:
                            payments.length,
                        separatorBuilder:
                            (_, __) =>
                                const SizedBox(
                                    height: 8),
                        itemBuilder:
                            (context,
                                index) {
                          return PaymentHistoryTile(
                              payment:
                                  payments[
                                      index]);
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

  Widget _buildFilterChip(
      String label,
      PaymentFilter filter) {
    final isSelected =
        _selectedFilter == filter;

    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) {
        setState(() {
          _selectedFilter = filter;
        });
      },
      selectedColor:
          Theme.of(context)
              .primaryColor,
      labelStyle: TextStyle(
        color: isSelected
            ? Colors.white
            : Colors.black,
      ),
    );
  }

  String _formatDateTime(DateTime date) {
    return '${date.day}-${date.month}-${date.year} '
        '${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}