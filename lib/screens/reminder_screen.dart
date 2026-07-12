import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/customer.dart';
import '../models/customer_repository.dart';
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
  State<ReminderScreen> createState() =>
      _ReminderScreenState();
}

class _ReminderScreenState
    extends State<ReminderScreen> {
  final _repo = CustomerRepository();

  ReminderSortOption _selectedSort =
      ReminderSortOption.dateAscending;

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

  Future<void> _callCustomer(
      String phone) async {
    final uri =
        Uri(scheme: 'tel', path: phone);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
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
                value:
                    ReminderSortOption.dateAscending,
                child: Text(
                    "Date ↑ (Nearest First)"),
              ),
              PopupMenuItem(
                value:
                    ReminderSortOption.dateDescending,
                child: Text(
                    "Date ↓ (Latest First)"),
              ),
              PopupMenuItem(
                value:
                    ReminderSortOption.overdueFirst,
                child:
                    Text("Overdue First"),
              ),
              PopupMenuItem(
                value:
                    ReminderSortOption.upcomingFirst,
                child:
                    Text("Upcoming First"),
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
            return const Center(
                child:
                    CircularProgressIndicator());
          }

          List<Customer> customers =
              snapshot.data!
                  .where((c) =>
                      c.nextReminderDate != null)
                  .toList();

          customers = _applySorting(customers);

          if (customers.isEmpty) {
            return const Center(
              child:
                  Text("No reminders set"),
            );
          }

          return ListView.separated(
            padding:
                const EdgeInsets.all(16),
            itemCount: customers.length,
            separatorBuilder:
                (_, __) =>
                    const SizedBox(
                        height: 8),
            itemBuilder:
                (context, index) {
              final customer =
                  customers[index];
              final reminderDate =
                  customer.nextReminderDate!;
              final isOverdue =
                  reminderDate
                      .isBefore(
                          DateTime.now());

              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor:
                        isOverdue
                            ? Colors.red
                            : Colors.orange,
                    child: Icon(
                      isOverdue
                          ? Icons.alarm_off
                          : Icons.alarm,
                      color:
                          Colors.white,
                    ),
                  ),

                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          customer.name,
                          style:
                              const TextStyle(
                            fontWeight:
                                FontWeight
                                    .bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon:
                            const Icon(
                          Icons.call,
                          color:
                              Colors.green,
                        ),
                        onPressed: () =>
                            _callCustomer(
                                customer
                                    .phone),
                      ),
                    ],
                  ),

                  // ✅ NEW DATE FORMAT + COUNTDOWN
                  subtitle: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      const SizedBox(
                          height: 4),
                      Text(
                        _formatDateTime(
                            reminderDate),
                        style:
                            TextStyle(
                          color: isOverdue
                              ? Colors.red
                              : Colors.grey,
                        ),
                      ),
                      const SizedBox(
                          height: 4),
                      Text(
                        _countdownText(
                            reminderDate),
                        style:
                            TextStyle(
                          fontWeight:
                              FontWeight
                                  .w500,
                          color: isOverdue
                              ? Colors.red
                              : Colors.green,
                        ),
                      ),
                    ],
                  ),

                  trailing: Text(
                    customer.totalDue
                        .toStringAsFixed(2),
                    style:
                        TextStyle(
                      color: customer
                                  .totalDue >
                              0
                          ? Colors.red
                          : Colors.green,
                      fontWeight:
                          FontWeight
                              .bold,
                    ),
                  ),

                  onTap: () {
                    Navigator.of(context)
                        .push(
                      MaterialPageRoute(
                        builder: (_) =>
                            CustomerDetailScreen(
                          customer:
                              customer,
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

  // ✅ Pretty Date Format
  String _formatDateTime(DateTime date) {
    final formatter =
        DateFormat('d MMMM yyyy • hh:mm a');
    return formatter.format(date);
  }

  // ✅ Countdown Logic
  String _countdownText(
      DateTime reminderDate) {
    final now = DateTime.now();
    final difference =
        reminderDate.difference(now);

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

  List<Customer> _applySorting(
      List<Customer> customers) {
    switch (_selectedSort) {
      case ReminderSortOption
          .dateAscending:
        customers.sort((a, b) =>
            a.nextReminderDate!
                .compareTo(
                    b.nextReminderDate!));
        break;

      case ReminderSortOption
          .dateDescending:
        customers.sort((a, b) =>
            b.nextReminderDate!
                .compareTo(
                    a.nextReminderDate!));
        break;

      case ReminderSortOption
          .overdueFirst:
        customers.sort((a, b) {
          final now =
              DateTime.now();
          final aOverdue =
              a.nextReminderDate!
                  .isBefore(now);
          final bOverdue =
              b.nextReminderDate!
                  .isBefore(now);

          if (aOverdue ==
              bOverdue) {
            return a
                .nextReminderDate!
                .compareTo(b
                    .nextReminderDate!);
          }
          return aOverdue
              ? -1
              : 1;
        });
        break;

      case ReminderSortOption
          .upcomingFirst:
        customers.sort((a, b) {
          final now =
              DateTime.now();
          final aUpcoming =
              a.nextReminderDate!
                  .isAfter(now);
          final bUpcoming =
              b.nextReminderDate!
                  .isAfter(now);

          if (aUpcoming ==
              bUpcoming) {
            return a
                .nextReminderDate!
                .compareTo(b
                    .nextReminderDate!);
          }
          return aUpcoming
              ? -1
              : 1;
        });
        break;
    }

    return customers;
  }
}