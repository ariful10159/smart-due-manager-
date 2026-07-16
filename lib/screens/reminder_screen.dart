import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/customer.dart';
import '../models/customer_repository.dart';
import '../services/notification_service.dart';
import 'customer_detail_screen.dart';

enum ReminderSortOption {
  dateAscending,
  dateDescending,
  overdueFirst,
  upcomingFirst,
}

class ReminderScreen extends StatefulWidget {
  const ReminderScreen({super.key});

  @override
  State<ReminderScreen> createState() => _ReminderScreenState();
}

class _ReminderScreenState extends State<ReminderScreen> {
  final _repo = CustomerRepository();

  ReminderSortOption _selectedSort = ReminderSortOption.dateAscending;

  Timer? _timer;

  @override
  void initState() {
    super.initState();

    // ✅ Refresh countdown every minute
    _timer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => setState(() {}),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _callCustomer(Customer customer) async {
    final uri = Uri(scheme: 'tel', path: customer.phone);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }

    if (!mounted) return;

    // ✅ Call করার পর জিজ্ঞাসা করা হচ্ছে reminder clear করবে কিনা
    final shouldClear = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Call Complete?"),
        content: Text(
          "'${customer.name}' কে কল করা হয়েছে। এই reminder টা কি "
          "reminder list থেকে সরিয়ে দেবেন?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Keep Reminder"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Remove Reminder"),
          ),
        ],
      ),
    );

    if (shouldClear == true) {
      await _clearReminder(customer);
    }
  }

  Future<void> _clearReminder(Customer customer) async {
    try {
      await _repo.clearReminder(customer.id);
      await NotificationService.cancelScheduledSms('sms_${customer.id}');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.green,
          content: Text("Reminder removed for ${customer.name}"),
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

  Future<void> _confirmDelete(Customer customer) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Reminder"),
        content: Text(
          "'${customer.name}' এর reminder টা মুছে দিতে চান?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _clearReminder(customer);
    }
  }

  Future<void> _snoozeReminder(Customer customer) async {
    final choice = await showModalBottomSheet<Duration?>(
      context: context,
      builder: (_) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  "Snooze Reminder",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.snooze),
                title: const Text("1 Hour"),
                onTap: () => Navigator.pop(context, const Duration(hours: 1)),
              ),
              ListTile(
                leading: const Icon(Icons.snooze),
                title: const Text("Tomorrow (same time)"),
                onTap: () => Navigator.pop(context, const Duration(days: 1)),
              ),
              ListTile(
                leading: const Icon(Icons.snooze),
                title: const Text("3 Days"),
                onTap: () => Navigator.pop(context, const Duration(days: 3)),
              ),
              ListTile(
                leading: const Icon(Icons.snooze),
                title: const Text("1 Week"),
                onTap: () => Navigator.pop(context, const Duration(days: 7)),
              ),
              ListTile(
                leading: const Icon(Icons.edit_calendar),
                title: const Text("Custom Date & Time"),
                onTap: () => Navigator.pop(context, null),
              ),
            ],
          ),
        );
      },
    );

    if (!mounted) return;

    DateTime? newReminderDate;

    if (choice != null) {
      newReminderDate = DateTime.now().add(choice);
    } else {
      final wantsCustom = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Set Custom Date"),
          content: const Text("তারিখ ও সময় বেছে নিন?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Continue"),
            ),
          ],
        ),
      );

      if (wantsCustom != true) return;
      if (!mounted) return;

      final selectedDate = await showDatePicker(
        context: context,
        initialDate: DateTime.now().add(const Duration(days: 1)),
        firstDate: DateTime.now(),
        lastDate: DateTime(2100),
      );
      if (selectedDate == null) return;
      if (!mounted) return;

      final selectedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );
      if (selectedTime == null) return;

      newReminderDate = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
        selectedTime.hour,
        selectedTime.minute,
      );
    }

    if (newReminderDate == null) return;

    await _applySnooze(customer, newReminderDate);
  }

  Future<void> _applySnooze(Customer customer, DateTime newDate) async {
    try {
      await _repo.addReminder(customerId: customer.id, reminderDate: newDate);

      await NotificationService.scheduleReminder(
        id: customer.hashCode,
        title: "Payment Reminder",
        body: "${customer.name} will pay now",
        scheduledDate: newDate,
      );

      final smsMessage =
          "প্রিয় ${customer.name}, আপনার বকেয়া পরিশোধের তারিখ। "
          "বর্তমান বকেয়া: ${customer.totalDue.toStringAsFixed(2)} টাকা। "
          "দয়া করে দ্রুত পরিশোধ করুন। ধন্যবাদ।";

      await NotificationService.scheduleSms(
        taskId: 'sms_${customer.id}',
        phoneNumber: customer.phone,
        message: smsMessage,
        scheduledDate: newDate,
        customerId: customer.id, // ✅ NEW — SMS log এর জন্য
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.green,
          content: Text(
            "Reminder snoozed to ${_formatDateTime(newDate)}",
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text("Failed to snooze: $e"),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Reminders"),
        centerTitle: true,
        actions: [
          PopupMenuButton<ReminderSortOption>(
            onSelected: (value) {
              setState(() {
                _selectedSort = value;
              });
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: ReminderSortOption.dateAscending,
                child: Text("Date ↑ (Nearest First)"),
              ),
              PopupMenuItem(
                value: ReminderSortOption.dateDescending,
                child: Text("Date ↓ (Latest First)"),
              ),
              PopupMenuItem(
                value: ReminderSortOption.overdueFirst,
                child: Text("Overdue First"),
              ),
              PopupMenuItem(
                value: ReminderSortOption.upcomingFirst,
                child: Text("Upcoming First"),
              ),
            ],
            icon: const Icon(Icons.sort),
          ),
        ],
      ),
      body: StreamBuilder<List<Customer>>(
        stream: _repo.streamCustomers(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          List<Customer> customers = snapshot.data!
              .where((c) => c.nextReminderDate != null)
              .toList();

          customers = _applySorting(customers);

          final overdueCount = customers
              .where((c) => c.nextReminderDate!.isBefore(DateTime.now()))
              .length;

          if (customers.isEmpty) {
            return const Center(child: Text("No reminders set"));
          }

          return Column(
            children: [
              if (overdueCount > 0)
                Container(
                  width: double.infinity,
                  color: Colors.red.withValues(alpha: 0.15),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber,
                          color: Colors.red, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        "$overdueCount reminder(s) overdue",
                        style: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: customers.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final customer = customers[index];
                    final reminderDate = customer.nextReminderDate!;
                    final isOverdue = reminderDate.isBefore(DateTime.now());

                    return Dismissible(
                      key: ValueKey(customer.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      confirmDismiss: (_) async {
                        return await showDialog<bool>(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const Text("Delete Reminder"),
                            content: Text(
                              "'${customer.name}' এর reminder টা মুছে দিতে চান?",
                            ),
                            actions: [
                              TextButton(
                                onPressed: () =>
                                    Navigator.pop(context, false),
                                child: const Text("Cancel"),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text(
                                  "Delete",
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                      onDismissed: (_) => _clearReminder(customer),
                      child: Card(
                        child: Column(
                          children: [
                            ListTile(
                              leading: CircleAvatar(
                                backgroundColor:
                                    isOverdue ? Colors.red : Colors.orange,
                                child: Icon(
                                  isOverdue ? Icons.alarm_off : Icons.alarm,
                                  color: Colors.white,
                                ),
                              ),
                              title: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      customer.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.call,
                                      color: Colors.green,
                                    ),
                                    onPressed: () => _callCustomer(customer),
                                  ),
                                ],
                              ),
                              subtitle: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text(
                                    _formatDateTime(reminderDate),
                                    style: TextStyle(
                                      color:
                                          isOverdue ? Colors.red : Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _countdownText(reminderDate),
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      color: isOverdue
                                          ? Colors.red
                                          : Colors.green,
                                    ),
                                  ),
                                ],
                              ),
                              trailing: Text(
                                customer.totalDue.toStringAsFixed(2),
                                style: TextStyle(
                                  color: customer.totalDue > 0
                                      ? Colors.red
                                      : Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => CustomerDetailScreen(
                                      customer: customer,
                                    ),
                                  ),
                                );
                              },
                            ),

                            Padding(
                              padding: const EdgeInsets.only(
                                left: 8,
                                right: 8,
                                bottom: 8,
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: TextButton.icon(
                                      onPressed: () =>
                                          _snoozeReminder(customer),
                                      icon: const Icon(
                                        Icons.snooze,
                                        size: 18,
                                      ),
                                      label: const Text("Snooze"),
                                    ),
                                  ),
                                  Expanded(
                                    child: TextButton.icon(
                                      onPressed: () =>
                                          _confirmDelete(customer),
                                      icon: const Icon(
                                        Icons.delete_outline,
                                        size: 18,
                                        color: Colors.red,
                                      ),
                                      label: const Text(
                                        "Delete",
                                        style: TextStyle(color: Colors.red),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _formatDateTime(DateTime date) {
    final formatter = DateFormat('d MMMM yyyy • hh:mm a');
    return formatter.format(date);
  }

  String _countdownText(DateTime reminderDate) {
    final now = DateTime.now();
    final difference = reminderDate.difference(now);

    if (difference.isNegative) {
      return "⚠️ Overdue";
    }

    if (difference.inDays > 0) {
      return "${difference.inDays} day(s) left";
    }

    if (difference.inHours > 0) {
      return "${difference.inHours} hour(s) left";
    }

    return "${difference.inMinutes} minute(s) left";
  }

  List<Customer> _applySorting(List<Customer> customers) {
    switch (_selectedSort) {
      case ReminderSortOption.dateAscending:
        customers.sort(
          (a, b) => a.nextReminderDate!.compareTo(b.nextReminderDate!),
        );
        break;

      case ReminderSortOption.dateDescending:
        customers.sort(
          (a, b) => b.nextReminderDate!.compareTo(a.nextReminderDate!),
        );
        break;

      case ReminderSortOption.overdueFirst:
        customers.sort((a, b) {
          final now = DateTime.now();
          final aOverdue = a.nextReminderDate!.isBefore(now);
          final bOverdue = b.nextReminderDate!.isBefore(now);

          if (aOverdue == bOverdue) {
            return a.nextReminderDate!.compareTo(b.nextReminderDate!);
          }
          return aOverdue ? -1 : 1;
        });
        break;

      case ReminderSortOption.upcomingFirst:
        customers.sort((a, b) {
          final now = DateTime.now();
          final aUpcoming = a.nextReminderDate!.isAfter(now);
          final bUpcoming = b.nextReminderDate!.isAfter(now);

          if (aUpcoming == bUpcoming) {
            return a.nextReminderDate!.compareTo(b.nextReminderDate!);
          }
          return aUpcoming ? -1 : 1;
        });
        break;
    }

    return customers;
  }
}