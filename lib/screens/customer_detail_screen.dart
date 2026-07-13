import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../models/customer.dart';
import '../models/payment.dart';
import '../models/customer_repository.dart';
import '../services/notification_service.dart';
import '../widgets/payment_history_tile.dart';
import 'add_payment_screen.dart';
import 'reminder_history_screen.dart';

class CustomerDetailScreen extends StatefulWidget {
  const CustomerDetailScreen({super.key, required this.customer});

  final Customer customer;

  @override
  State<CustomerDetailScreen> createState() => _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends State<CustomerDetailScreen> {
  final _customerRepo = CustomerRepository();

  String _formatDateTime(DateTime date) {
    return DateFormat('d MMMM yyyy • hh:mm a').format(date);
  }

  String _formatDateOnly(DateTime date) {
    return DateFormat('d MMMM yyyy').format(date);
  }

  Future<pw.Document> _generatePdf(Customer customer) async {
    final payments = await _customerRepo.streamPayments(customer.id).first;

    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        build: (context) => [
          pw.Text(
            'Customer Payment History',
            style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 16),
          pw.Text('Name: ${customer.name}'),
          pw.Text('Phone: ${customer.phone}'),
          if (customer.address != null) pw.Text('Address: ${customer.address}'),
          pw.Text('Due Date: ${_formatDateOnly(customer.lastPaymentDate)}'),
          pw.Text('Total Due: ${customer.totalDue.toStringAsFixed(2)}'),
          if (customer.nextReminderDate != null)
            pw.Text(
              'Next Reminder: ${_formatDateTime(customer.nextReminderDate!)}',
            ),
          pw.SizedBox(height: 20),
          pw.Text(
            'Payment History',
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 10),
          if (payments.isEmpty)
            pw.Text('No transactions yet')
          else
            pw.Table.fromTextArray(
              headers: const ['Date', 'Type', 'Amount', 'Note'],
              data: payments.map((payment) {
                return [
                  _formatDateTime(payment.date),
                  payment.type == PaymentType.payment
                      ? 'Record Payment'
                      : 'Add Charge',
                  payment.amount.toStringAsFixed(2),
                  payment.note ?? '',
                ];
              }).toList(),
            ),
        ],
      ),
    );

    return pdf;
  }

  Future<void> _printPdf(Customer customer) async {
    final pdf = await _generatePdf(customer);
    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  Future<void> _downloadPdf(Customer customer) async {
    try {
      final pdf = await _generatePdf(customer);
      final bytes = await pdf.save();

      final directory = Directory('/storage/emulated/0/Download');

      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }

      final fileName =
          "${customer.name.replaceAll(" ", "_")}_payment_history.pdf";

      final filePath = "${directory.path}/$fileName";
      final file = File(filePath);
      await file.writeAsBytes(bytes);

      if (!mounted) return;

      // ✅ Auto Open using Share Sheet
      await Share.shareXFiles([
        XFile(filePath),
      ], text: "${customer.name} - Payment History");

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.green,
          content: Text("PDF saved and opened ✅"),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text("Download failed: $e"),
        ),
      );
    }
  }

  Future<void> _addPayment(Customer currentCustomer, PaymentType type) async {
    final payment = await Navigator.of(context).push<Payment>(
      MaterialPageRoute(
        builder: (_) => AddPaymentScreen(customer: currentCustomer, type: type),
      ),
    );

    if (payment == null) return;

    double updatedDue = type == PaymentType.payment
        ? currentCustomer.totalDue - payment.amount
        : currentCustomer.totalDue + payment.amount;

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
      initialDate: DateTime.now().add(const Duration(days: 7)),
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

    await _customerRepo.addReminder(
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

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Reminder Updated ✅")));
  }

  // ignore: unused_element
  Future<void> _confirmDeleteCustomer(Customer customer) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Hide Customer"),
        content: Text(
          "আপনি কি নিশ্চিত '${customer.name}' কে হাইড করতে চান? "
          "এটি main list থেকে সরে যাবে, কিন্তু সব তথ্য ও payment history "
          "সংরক্ষিত থাকবে। প্রয়োজনে পরে Archived section থেকে আবার "
          "ফিরিয়ে আনা যাবে।",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Hide", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _hideCustomer(customer);
    }
  }

  Future<void> _hideCustomer(Customer customer) async {
    try {
      await _customerRepo.hideCustomer(customer.id);

      if (!mounted) return;

      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.green,
          content: Text("${customer.name} hidden successfully"),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(backgroundColor: Colors.red, content: Text("Hide failed: $e")),
      );
    }
  }

  // ignore: unused_element
  Future<void> _editCustomer(Customer customer) async {
    final nameController = TextEditingController(text: customer.name);
    final phoneController = TextEditingController(text: customer.phone);
    final addressController = TextEditingController(
      text: customer.address ?? '',
    );
    final noteController = TextEditingController(text: customer.note ?? '');

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Edit Customer"),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: "Name"),
              ),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(labelText: "Phone"),
              ),
              TextField(
                controller: addressController,
                decoration: const InputDecoration(labelText: "Address"),
              ),
              TextField(
                controller: noteController,
                decoration: const InputDecoration(labelText: "Note"),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.customer.name),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.visibility_off, color: Colors.orange),
            onPressed: () => _confirmDeleteCustomer(widget.customer),
          ),
        ],
      ),
      body: StreamBuilder<Customer>(
        stream: _customerRepo.streamCustomerById(widget.customer.id),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final customer = snapshot.data!;

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  customer.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  customer.phone,
                  style: const TextStyle(color: Colors.grey),
                ),
                if (customer.address != null)
                  Text(
                    customer.address!,
                    style: const TextStyle(color: Colors.grey),
                  ),
                const SizedBox(height: 6),
                Text(
                  "Due date: ${_formatDateOnly(customer.lastPaymentDate)}",
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 10),
                Text(
                  "Total Due: ${customer.totalDue.toStringAsFixed(2)}",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: customer.totalDue > 0 ? Colors.red : Colors.green,
                  ),
                ),
                if (customer.nextReminderDate != null)
                  Text(
                    "Next Reminder: ${_formatDateTime(customer.nextReminderDate!)}",
                    style: const TextStyle(color: Colors.orange),
                  ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () =>
                            _addPayment(customer, PaymentType.payment),
                        child: const Text("Record Payment"),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () =>
                            _addPayment(customer, PaymentType.dueAdded),
                        child: const Text("Add Charge"),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _setReminder(customer),
                    icon: const Icon(Icons.alarm),
                    label: const Text("Set Reminder"),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Payment History",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.print),
                          onPressed: () => _printPdf(customer),
                        ),
                        IconButton(
                          icon: const Icon(Icons.download),
                          onPressed: () => _downloadPdf(customer),
                        ),
                        IconButton(
                          icon: const Icon(Icons.history),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ReminderHistoryScreen(
                                  customerId: customer.id,
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: StreamBuilder<List<Payment>>(
                    stream: _customerRepo.streamPayments(customer.id),
                    builder: (context, paymentSnapshot) {
                      if (!paymentSnapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final payments = paymentSnapshot.data!;

                      if (payments.isEmpty) {
                        return const Center(child: Text("No transactions yet"));
                      }

                      return ListView.separated(
                        itemCount: payments.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          return PaymentHistoryTile(payment: payments[index]);
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
