import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/customer.dart';
import '../models/customer_repository.dart';
import '../services/notification_service.dart';
import '../theme/app_colors.dart';
import '../widgets/app_settings_scope.dart';
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

  // ✅ Settings-এ সেভ করা SMS টেমপ্লেটের placeholder গুলো আসল ডেটা দিয়ে রিপ্লেস করা হচ্ছে
  String _buildReminderMessage(Customer customer) {
    final settings = AppSettingsScope.of(context).settings;
    final dateFmt = DateFormat('d MMM yyyy');
    final currencyFmt = NumberFormat('#,##0.00');

    return settings.smsReminderTemplate
        .replaceAll('{name}', customer.name)
        .replaceAll('{amount}', currencyFmt.format(customer.totalDue))
        .replaceAll('{due_date}', dateFmt.format(customer.lastPaymentDate))
        .replaceAll('{business_name}', settings.businessName)
        .replaceAll('{phone}', customer.phone);
  }

  Future<void> _callCustomer(Customer customer) async {
    final colors = AppColors.of(context);
    final uri = Uri(scheme: 'tel', path: customer.phone);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }

    if (!mounted) return;

    // ✅ Call করার পর জিজ্ঞাসা করা হচ্ছে reminder clear করবে কিনা
    final shouldClear = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: colors.borderColor),
        ),
        title: Text("Call Complete?", style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w800)),
        content: Text(
          "'${customer.name}' কে কল করা হয়েছে। এই reminder টা কি "
          "reminder list থেকে সরিয়ে দেবেন?",
          style: TextStyle(color: colors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text("Keep Reminder", style: TextStyle(color: colors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text("Remove Reminder", style: TextStyle(color: colors.due, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (shouldClear == true) {
      await _clearReminder(customer);
    }
  }

  Future<void> _clearReminder(Customer customer) async {
    final colors = AppColors.of(context);
    try {
      await _repo.clearReminder(customer.id);
      await NotificationService.cancelScheduledSms('sms_${customer.id}');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: colors.clear,
          content: Text("Reminder removed for ${customer.name}"),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: colors.due,
          content: Text("Failed to remove reminder: $e"),
        ),
      );
    }
  }

  Future<void> _confirmDelete(Customer customer) async {
    final colors = AppColors.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: colors.borderColor),
        ),
        title: Text("Delete Reminder", style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w800)),
        content: Text(
          "'${customer.name}' এর reminder টা মুছে দিতে চান?",
          style: TextStyle(color: colors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text("Cancel", style: TextStyle(color: colors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text("Delete", style: TextStyle(color: colors.due, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _clearReminder(customer);
    }
  }

  Future<void> _snoozeReminder(Customer customer) async {
    final colors = AppColors.of(context);

    final choice = await showModalBottomSheet<Duration?>(
      context: context,
      backgroundColor: colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  "Snooze Reminder",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: colors.textPrimary),
                ),
              ),
              ListTile(
                leading: Icon(Icons.snooze, color: colors.accent),
                title: Text("1 Hour", style: TextStyle(color: colors.textPrimary)),
                onTap: () => Navigator.pop(context, const Duration(hours: 1)),
              ),
              ListTile(
                leading: Icon(Icons.snooze, color: colors.accent),
                title: Text("Tomorrow (same time)", style: TextStyle(color: colors.textPrimary)),
                onTap: () => Navigator.pop(context, const Duration(days: 1)),
              ),
              ListTile(
                leading: Icon(Icons.snooze, color: colors.accent),
                title: Text("3 Days", style: TextStyle(color: colors.textPrimary)),
                onTap: () => Navigator.pop(context, const Duration(days: 3)),
              ),
              ListTile(
                leading: Icon(Icons.snooze, color: colors.accent),
                title: Text("1 Week", style: TextStyle(color: colors.textPrimary)),
                onTap: () => Navigator.pop(context, const Duration(days: 7)),
              ),
              ListTile(
                leading: Icon(Icons.edit_calendar, color: colors.accent),
                title: Text("Custom Date & Time", style: TextStyle(color: colors.textPrimary)),
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
          backgroundColor: colors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: colors.borderColor),
          ),
          title: Text("Set Custom Date", style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w800)),
          content: Text("তারিখ ও সময় বেছে নিন?", style: TextStyle(color: colors.textSecondary)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text("Cancel", style: TextStyle(color: colors.textSecondary)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text("Continue", style: TextStyle(color: colors.accent, fontWeight: FontWeight.w700)),
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
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: ColorScheme(
                brightness: colors.scaffoldBg.computeLuminance() < 0.5 ? Brightness.dark : Brightness.light,
                primary: colors.accent,
                onPrimary: Colors.white,
                secondary: colors.accentAlt,
                onSecondary: Colors.white,
                error: colors.due,
                onError: Colors.white,
                surface: colors.surface,
                onSurface: colors.textPrimary,
              ),
              dialogBackgroundColor: colors.surface,
            ),
            child: child!,
          );
        },
      );
      if (selectedDate == null) return;
      if (!mounted) return;

      final selectedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: ColorScheme(
                brightness: colors.scaffoldBg.computeLuminance() < 0.5 ? Brightness.dark : Brightness.light,
                primary: colors.accent,
                onPrimary: Colors.white,
                secondary: colors.accentAlt,
                onSecondary: Colors.white,
                error: colors.due,
                onError: Colors.white,
                surface: colors.surface,
                onSurface: colors.textPrimary,
              ),
              dialogBackgroundColor: colors.surface,
            ),
            child: child!,
          );
        },
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
    final colors = AppColors.of(context);
    try {
      await _repo.addReminder(customerId: customer.id, reminderDate: newDate);

      await NotificationService.scheduleReminder(
        id: customer.hashCode,
        title: "Payment Reminder",
        body: "${customer.name} will pay now",
        scheduledDate: newDate,
      );

      // ✅ এখন Settings-এ সেভ করা টেমপ্লেট থেকে SMS মেসেজ তৈরি হচ্ছে
      final smsMessage = _buildReminderMessage(customer);

      await NotificationService.scheduleSms(
        taskId: 'sms_${customer.id}',
        phoneNumber: customer.phone,
        message: smsMessage,
        scheduledDate: newDate,
        customerId: customer.id,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: colors.clear,
          content: Text(
            "Reminder snoozed to ${_formatDateTime(newDate)}",
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: colors.due,
          content: Text("Failed to snooze: $e"),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context); // ✅ dynamic dark/light কালার

    return Scaffold(
      backgroundColor: colors.scaffoldBg,
      appBar: AppBar(
        title: Text("Reminders", style: TextStyle(fontWeight: FontWeight.w800, color: colors.textPrimary)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: colors.textPrimary),
        actions: [
          PopupMenuButton<ReminderSortOption>(
            onSelected: (value) {
              setState(() {
                _selectedSort = value;
              });
            },
            color: colors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(color: colors.borderColor),
            ),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: ReminderSortOption.dateAscending,
                child: Text("Date ↑ (Nearest First)", style: TextStyle(color: colors.textPrimary)),
              ),
              PopupMenuItem(
                value: ReminderSortOption.dateDescending,
                child: Text("Date ↓ (Latest First)", style: TextStyle(color: colors.textPrimary)),
              ),
              PopupMenuItem(
                value: ReminderSortOption.overdueFirst,
                child: Text("Overdue First", style: TextStyle(color: colors.textPrimary)),
              ),
              PopupMenuItem(
                value: ReminderSortOption.upcomingFirst,
                child: Text("Upcoming First", style: TextStyle(color: colors.textPrimary)),
              ),
            ],
            icon: Icon(Icons.sort, color: colors.textPrimary),
          ),
        ],
      ),
      body: StreamBuilder<List<Customer>>(
        stream: _repo.streamCustomers(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator(color: colors.accent));
          }

          List<Customer> customers = snapshot.data!
              .where((c) => c.nextReminderDate != null)
              .toList();

          customers = _applySorting(customers);

          final overdueCount = customers
              .where((c) => c.nextReminderDate!.isBefore(DateTime.now()))
              .length;

          if (customers.isEmpty) {
            return Center(
              child: Text("No reminders set", style: TextStyle(color: colors.textSecondary)),
            );
          }

          return Column(
            children: [
              if (overdueCount > 0)
                Container(
                  width: double.infinity,
                  color: colors.due.withOpacity(0.15),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber, color: colors.due, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        "$overdueCount reminder(s) overdue",
                        style: TextStyle(
                          color: colors.due,
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
                          color: colors.due,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      confirmDismiss: (_) async {
                        return await showDialog<bool>(
                          context: context,
                          builder: (_) => AlertDialog(
                            backgroundColor: colors.surface,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(color: colors.borderColor),
                            ),
                            title: Text("Delete Reminder", style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w800)),
                            content: Text(
                              "'${customer.name}' এর reminder টা মুছে দিতে চান?",
                              style: TextStyle(color: colors.textSecondary),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: Text("Cancel", style: TextStyle(color: colors.textSecondary)),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: Text("Delete", style: TextStyle(color: colors.due, fontWeight: FontWeight.w700)),
                              ),
                            ],
                          ),
                        );
                      },
                      onDismissed: (_) => _clearReminder(customer),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [colors.surface, colors.surfaceAlt],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: colors.borderColor),
                        ),
                        child: Column(
                          children: [
                            ListTile(
                              leading: CircleAvatar(
                                backgroundColor: isOverdue ? colors.due : colors.warn,
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
                                      style: TextStyle(fontWeight: FontWeight.bold, color: colors.textPrimary),
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.call, color: colors.clear),
                                    onPressed: () => _callCustomer(customer),
                                  ),
                                ],
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text(
                                    _formatDateTime(reminderDate),
                                    style: TextStyle(
                                      color: isOverdue ? colors.due : colors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _countdownText(reminderDate),
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      color: isOverdue ? colors.due : colors.clear,
                                    ),
                                  ),
                                ],
                              ),
                              trailing: Text(
                                customer.totalDue.toStringAsFixed(2),
                                style: TextStyle(
                                  color: customer.totalDue > 0 ? colors.due : colors.clear,
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
                                      onPressed: () => _snoozeReminder(customer),
                                      icon: Icon(Icons.snooze, size: 18, color: colors.accent),
                                      label: Text("Snooze", style: TextStyle(color: colors.accent)),
                                    ),
                                  ),
                                  Expanded(
                                    child: TextButton.icon(
                                      onPressed: () => _confirmDelete(customer),
                                      icon: Icon(Icons.delete_outline, size: 18, color: colors.due),
                                      label: Text("Delete", style: TextStyle(color: colors.due)),
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