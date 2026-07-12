import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';

import '../models/customer.dart';
import '../models/customer_repository.dart';
import 'add_customer_screen.dart';
import 'customer_detail_screen.dart';
import 'home_screen.dart';
import 'reminder_screen.dart';

class AllCustomersScreen extends StatefulWidget {
  const AllCustomersScreen({super.key});

  @override
  State<AllCustomersScreen> createState() =>
      _AllCustomersScreenState();
}

class _AllCustomersScreenState
    extends State<AllCustomersScreen> {
  final _repo = CustomerRepository();

  int _selectedIndex = 2;

  int? _selectedYear;
  int? _selectedMonth;
  String? _reminderFilter; // ✅ NULL SAFE

  Future<void> _callCustomer(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _onDestinationSelected(int index) {
    if (index == _selectedIndex) return;

    switch (index) {
      case 0:
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (route) => false,
        );
        break;
      case 1:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AddCustomerScreen()),
        );
        break;
      case 3:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const ReminderScreen()),
        );
        break;
    }
  }

  String _formatDate(DateTime date) {
    return DateFormat('d MMM yyyy').format(date);
  }

  List<Customer> _applyFilters(List<Customer> customers) {
    return customers.where((customer) {
      final date = customer.lastPaymentDate;

      if (_selectedYear != null &&
          date.year != _selectedYear) {
        return false;
      }

      if (_selectedMonth != null &&
          date.month != _selectedMonth) {
        return false;
      }

      if (_reminderFilter != null) {
        if (_reminderFilter == "Reminder Set" &&
            customer.nextReminderDate == null) {
          return false;
        }

        if (_reminderFilter == "No Reminder" &&
            customer.nextReminderDate != null) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final currentYear = DateTime.now().year;

    return Scaffold(
      appBar: AppBar(
        title: const Text("All Customers"),
        centerTitle: true,
      ),
      body: StreamBuilder<List<Customer>>(
        stream: _repo.streamCustomers(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
                child: CircularProgressIndicator());
          }

          final filteredCustomers =
              _applyFilters(snapshot.data!);

          return Column(
            children: [

              // ✅ FILTER DROPDOWNS
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                child: Row(
                  children: [

                    // ✅ Year
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        value: _selectedYear,
                        hint: const Text("Year"),
                        items: List.generate(
                          6,
                          (index) {
                            final year =
                                currentYear - index;
                            return DropdownMenuItem(
                              value: year,
                              child:
                                  Text(year.toString()),
                            );
                          },
                        ),
                        onChanged: (value) {
                          setState(() {
                            _selectedYear = value;
                          });
                        },
                      ),
                    ),

                    const SizedBox(width: 8),

                    // ✅ Month
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        value: _selectedMonth,
                        hint: const Text("Month"),
                        items: List.generate(
                          12,
                          (index) {
                            return DropdownMenuItem(
                              value: index + 1,
                              child: Text(
                                DateFormat.MMM().format(
                                  DateTime(0, index + 1),
                                ),
                              ),
                            );
                          },
                        ),
                        onChanged: (value) {
                          setState(() {
                            _selectedMonth = value;
                          });
                        },
                      ),
                    ),

                    const SizedBox(width: 8),

                    // ✅ Reminder Filter
                    Expanded(
                      child:
                          DropdownButtonFormField<String>(
                        value: _reminderFilter,
                        hint: const Text("Reminder"),
                        items: const [
                          DropdownMenuItem(
                            value: "Reminder Set",
                            child: Text("Reminder"),
                          ),
                          DropdownMenuItem(
                            value: "No Reminder",
                            child: Text("No Reminder"),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _reminderFilter =
                                value;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // ✅ CUSTOMER LIST
              Expanded(
                child: filteredCustomers.isEmpty
                    ? const Center(
                        child: Text(
                            "No customers found"),
                      )
                    : ListView.separated(
                        padding:
                            const EdgeInsets.all(16),
                        itemCount:
                            filteredCustomers.length,
                        separatorBuilder:
                            (_, __) =>
                                const SizedBox(
                                    height: 8),
                        itemBuilder:
                            (context, index) {
                          final customer =
                              filteredCustomers[
                                  index];

                          return Card(
                            child: ListTile(
                              leading:
                                  const CircleAvatar(
                                child: Icon(
                                    Icons.person),
                              ),

                              // ✅ NAME + REMINDER ICON
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
                                  if (customer
                                          .nextReminderDate !=
                                      null)
                                    const Icon(
                                      Icons
                                          .notifications_active,
                                      color:
                                          Colors.orange,
                                      size: 20,
                                    ),
                                ],
                              ),

                              subtitle: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment
                                        .start,
                                children: [
                                  Text(customer.phone),
                                  Text(
                                    "Baki From: ${_formatDate(customer.lastPaymentDate)}",
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color:
                                            Colors.grey),
                                  ),
                                ],
                              ),

                              trailing: Row(
                                mainAxisSize:
                                    MainAxisSize.min,
                                children: [
                                  Text(
                                    customer.totalDue
                                        .toStringAsFixed(
                                            2),
                                    style: TextStyle(
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
                                  const SizedBox(
                                      width: 8),
                                  IconButton(
                                    icon: const Icon(
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

                              onTap: () {
                                Navigator.of(
                                        context)
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
                      ),
              ),
            ],
          );
        },
      ),

      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected:
            _onDestinationSelected,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon:
                Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons
                .person_add_alt_1_outlined),
            selectedIcon:
                Icon(Icons
                    .person_add_alt_1),
            label: 'Add Customer',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon:
                Icon(Icons.people),
            label: 'All Customers',
          ),
          NavigationDestination(
            icon: Icon(Icons
                .notifications_outlined),
            selectedIcon:
                Icon(Icons
                    .notifications),
            label: 'Reminders',
          ),
        ],
      ),
    );
  }
}