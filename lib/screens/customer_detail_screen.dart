import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
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

    // ✅ নির্দিষ্ট সময়ে customer এর নাম্বারে SMS auto-send schedule করা
    final smsMessage =
        "প্রিয় ${customer.name}, আপনার বকেয়া পরিশোধের তারিখ। "
        "বর্তমান বকেয়া: ${customer.totalDue.toStringAsFixed(2)} টাকা। "
        "দয়া করে দ্রুত পরিশোধ করুন। ধন্যবাদ।";

    await NotificationService.scheduleSms(
      taskId: 'sms_${customer.id}',
      phoneNumber: customer.phone,
      message: smsMessage,
      scheduledDate: scheduledDateTime,
    );

    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Reminder Updated ✅")));
  }

  Future<void> _confirmClearReminder(Customer customer) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Cancel Reminder"),
        content: Text(
          "'${customer.name}' এর জন্য সেট করা reminder টা বাতিল করতে চান?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              "Remove Reminder",
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _clearReminder(customer);
    }
  }

  Future<void> _clearReminder(Customer customer) async {
    try {
      await _customerRepo.clearReminder(customer.id);

      // ✅ Reminder বাতিল করলে schedule করা SMS ও বাতিল হবে
      await NotificationService.cancelScheduledSms('sms_${customer.id}');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.green,
          content: Text("Reminder removed ✅"),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text("Failed to remove reminder: $e"),
        ),
      );
    }
  }

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

  // ✅ ছবিকে Base64 string এ কনভার্ট করা হচ্ছে (Firestore এ সেভ করার জন্য, Storage লাগবে না)
  Future<String?> _encodeImageToBase64(File imageFile) async {
    final bytes = await imageFile.readAsBytes();

    // Firestore এর 1MB document limit এর মধ্যে রাখার জন্য সাইজ চেক
    if (bytes.length > 700 * 1024) {
      if (!mounted) return null;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'ছবিটা বেশি বড়, দয়া করে আরেকটু ছোট/হালকা ছবি বেছে নিন',
          ),
        ),
      );
      return null;
    }

    return base64Encode(bytes);
  }

  Future<void> _editCustomer(Customer customer) async {
    final nameController = TextEditingController(text: customer.name);
    final phoneController = TextEditingController(text: customer.phone);
    final addressController = TextEditingController(
      text: customer.address ?? '',
    );
    final noteController = TextEditingController(text: customer.note ?? '');
    final dueAmountController = TextEditingController(
      text: customer.totalDue.toStringAsFixed(2),
    );
    final dateController = TextEditingController(
      text:
          "${customer.lastPaymentDate.day}-${customer.lastPaymentDate.month}-${customer.lastPaymentDate.year}",
    );

    File? newSelectedImage;
    bool isSavingEdit = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            Future<void> pickEditImage() async {
              final picker = ImagePicker();
              final image = await picker.pickImage(
                source: ImageSource.gallery,
                imageQuality: 70,
                maxWidth: 400,
                maxHeight: 400,
              );
              if (image != null) {
                setDialogState(() {
                  newSelectedImage = File(image.path);
                });
              }
            }

            return AlertDialog(
              title: const Text("Edit Customer"),
              content: SingleChildScrollView(
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: pickEditImage,
                      child: CircleAvatar(
                        radius: 40,
                        backgroundImage: newSelectedImage != null
                            ? FileImage(newSelectedImage!)
                            : (customer.photoUrl != null
                                  ? MemoryImage(
                                          base64Decode(customer.photoUrl!),
                                        )
                                        as ImageProvider
                                  : null),
                        child:
                            newSelectedImage == null &&
                                customer.photoUrl == null
                            ? const Icon(Icons.add_a_photo, size: 30)
                            : null,
                      ),
                    ),
                    const SizedBox(height: 16),

                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: "Name"),
                    ),
                    TextField(
                      controller: phoneController,
                      decoration: const InputDecoration(labelText: "Phone"),
                      keyboardType: TextInputType.phone,
                    ),
                    TextField(
                      controller: addressController,
                      decoration: const InputDecoration(labelText: "Address"),
                    ),
                    TextField(
                      controller: dueAmountController,
                      decoration: const InputDecoration(
                        labelText: "Due Amount",
                      ),
                      readOnly: true,
                      keyboardType: TextInputType.number,
                    ),
                    TextField(
                      controller: dateController,
                      readOnly: true,
                      enabled: false,
                      decoration: const InputDecoration(labelText: 'Date'),
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
                  onPressed: isSavingEdit
                      ? null
                      : () => Navigator.pop(dialogContext),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: isSavingEdit
                      ? null
                      : () async {
                          setDialogState(() {
                            isSavingEdit = true;
                          });

                          String? photoBase64;
                          if (newSelectedImage != null) {
                            photoBase64 = await _encodeImageToBase64(
                              newSelectedImage!,
                            );
                          }

                          final totalDue = double.tryParse(
                            dueAmountController.text.trim(),
                          );

                          DateTime? lastPaymentDate;
                          final dateText = dateController.text.trim();
                          if (dateText.isNotEmpty) {
                            final parts = dateText.split('-');
                            if (parts.length == 3) {
                              final day = int.tryParse(parts[0]);
                              final month = int.tryParse(parts[1]);
                              final year = int.tryParse(parts[2]);
                              if (day != null &&
                                  month != null &&
                                  year != null) {
                                lastPaymentDate = DateTime(year, month, day);
                              }
                            }
                          }

                          await _customerRepo.updateCustomerInfo(
                            customerId: customer.id,
                            name: nameController.text.trim(),
                            phone: phoneController.text.trim(),
                            address: addressController.text.trim(),
                            note: noteController.text.trim(),
                            totalDue: totalDue,
                            lastPaymentDate: lastPaymentDate,
                            photoUrl: photoBase64,
                          );

                          if (!mounted) return;
                          Navigator.pop(dialogContext);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              backgroundColor: Colors.green,
                              content: Text("Customer details updated ✅"),
                            ),
                          );
                        },
                  child: isSavingEdit
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text("Save"),
                ),
              ],
            );
          },
        );
      },
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
            icon: const Icon(Icons.edit),
            onPressed: () => _editCustomer(widget.customer),
          ),
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
                Center(
                  child: CircleAvatar(
                    radius: 45,
                    backgroundImage: customer.photoUrl != null
                        ? MemoryImage(base64Decode(customer.photoUrl!))
                              as ImageProvider
                        : null,
                    child: customer.photoUrl == null
                        ? const Icon(Icons.person, size: 40)
                        : null,
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: Text(
                    customer.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Center(
                  child: Text(
                    customer.phone,
                    style: const TextStyle(color: Colors.grey),
                  ),
                ),
                if (customer.address != null)
                  Center(
                    child: Text(
                      customer.address!,
                      style: const TextStyle(color: Colors.grey),
                    ),
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
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          "Next Reminder: ${_formatDateTime(customer.nextReminderDate!)}",
                          style: const TextStyle(color: Colors.orange),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.cancel,
                          color: Colors.red,
                          size: 20,
                        ),
                        tooltip: "Remove Reminder",
                        onPressed: () => _confirmClearReminder(customer),
                      ),
                    ],
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