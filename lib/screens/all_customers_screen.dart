import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';

import '../models/customer.dart';
import '../models/customer_repository.dart';
import 'add_customer_screen.dart';
import 'archived_customers_screen.dart';
import 'customer_detail_screen.dart';
import 'home_screen.dart';
import 'reminder_screen.dart';

class AllCustomersScreen extends StatefulWidget {
  const AllCustomersScreen({super.key});

  @override
  State<AllCustomersScreen> createState() => _AllCustomersScreenState();
}

class _AllCustomersScreenState extends State<AllCustomersScreen> {
  final _repo = CustomerRepository();

  int _selectedIndex = 2;

  int? _selectedYear;
  int? _selectedMonth;
  String? _reminderFilter;

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

  // ✅ Customer লিস্ট থেকে যেসব বছর সত্যিই আছে, শুধু সেগুলো বের করা হচ্ছে
  List<int> _availableYears(List<Customer> customers) {
    final years = customers.map((c) => c.lastPaymentDate.year).toSet().toList();
    years.sort((a, b) => b.compareTo(a)); // নতুন বছর আগে
    return years;
  }

  // ✅ যেসব মাসে সত্যিই customer আছে (যদি বছর সিলেক্ট করা থাকে, সেই বছরের মধ্যে)
  List<int> _availableMonths(List<Customer> customers) {
    final relevant = _selectedYear != null
        ? customers.where((c) => c.lastPaymentDate.year == _selectedYear)
        : customers;

    final months = relevant
        .map((c) => c.lastPaymentDate.month)
        .toSet()
        .toList();
    months.sort();
    return months;
  }

  // ✅ Reminder filter option — শুধু তখনই দেখাবে যদি সেই ধরনের customer থাকে
  List<String> _availableReminderOptions(List<Customer> customers) {
    final options = <String>[];

    final hasReminderSet = customers.any(
      (c) =>
          c.nextReminderDate != null &&
          c.nextReminderDate!.isAfter(DateTime.now()),
    );
    final hasNoReminder = customers.any(
      (c) =>
          c.nextReminderDate == null ||
          !c.nextReminderDate!.isAfter(DateTime.now()),
    );

    if (hasReminderSet) options.add("Reminder Set");
    if (hasNoReminder) options.add("No Reminder");

    return options;
  }

  List<Customer> _applyFilters(List<Customer> customers) {
    return customers.where((customer) {
      final date = customer.lastPaymentDate;

      if (_selectedYear != null && date.year != _selectedYear) {
        return false;
      }

      if (_selectedMonth != null && date.month != _selectedMonth) {
        return false;
      }

      if (_reminderFilter != null) {
        final hasActiveReminder =
            customer.nextReminderDate != null &&
            customer.nextReminderDate!.isAfter(DateTime.now());

        if (_reminderFilter == "Reminder Set" && !hasActiveReminder) {
          return false;
        }

        if (_reminderFilter == "No Reminder" && hasActiveReminder) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  bool get _hasActiveFilters =>
      _selectedYear != null ||
      _selectedMonth != null ||
      _reminderFilter != null;

  void _clearAllFilters() {
    setState(() {
      _selectedYear = null;
      _selectedMonth = null;
      _reminderFilter = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("All Customers"),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.archive),
            tooltip: "Archived Customers",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ArchivedCustomersScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<List<Customer>>(
        stream: _repo.streamCustomers(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final allCustomers = snapshot.data!;
          final filteredCustomers = _applyFilters(allCustomers);

          final availableYears = _availableYears(allCustomers);
          final availableMonths = _availableMonths(allCustomers);
          final availableReminderOptions = _availableReminderOptions(
            allCustomers,
          );

          // ✅ যদি সিলেক্ট করা year/month/reminder এখন আর available list এ না থাকে
          // (যেমন সব customer delete হয়ে গেছে), তাহলে filter নিজে থেকেই রিসেট হবে
          if (_selectedYear != null &&
              !availableYears.contains(_selectedYear)) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) setState(() => _selectedYear = null);
            });
          }
          if (_selectedMonth != null &&
              !availableMonths.contains(_selectedMonth)) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) setState(() => _selectedMonth = null);
            });
          }
          if (_reminderFilter != null &&
              !availableReminderOptions.contains(_reminderFilter)) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) setState(() => _reminderFilter = null);
            });
          }

          return Column(
            children: [
              // ✅ FILTER DROPDOWNS
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        // ✅ Year
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            value: availableYears.contains(_selectedYear)
                                ? _selectedYear
                                : null,
                            hint: const Text("Year"),
                            decoration: InputDecoration(
                              suffixIcon: _selectedYear != null
                                  ? IconButton(
                                      icon: const Icon(Icons.clear, size: 18),
                                      onPressed: () {
                                        setState(() => _selectedYear = null);
                                      },
                                    )
                                  : null,
                            ),
                            items: availableYears.map((year) {
                              return DropdownMenuItem(
                                value: year,
                                child: Text(year.toString()),
                              );
                            }).toList(),
                            onChanged: availableYears.isEmpty
                                ? null
                                : (value) {
                                    setState(() {
                                      _selectedYear = value;
                                      // ✅ বছর বদলালে মাস reset করা হচ্ছে,
                                      // কারণ নতুন বছরে আগের মাসের ডেটা নাও থাকতে পারে
                                      _selectedMonth = null;
                                    });
                                  },
                          ),
                        ),

                        const SizedBox(width: 8),

                        // ✅ Month
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            value: availableMonths.contains(_selectedMonth)
                                ? _selectedMonth
                                : null,
                            hint: const Text("Month"),
                            decoration: InputDecoration(
                              suffixIcon: _selectedMonth != null
                                  ? IconButton(
                                      icon: const Icon(Icons.clear, size: 18),
                                      onPressed: () {
                                        setState(() => _selectedMonth = null);
                                      },
                                    )
                                  : null,
                            ),
                            items: availableMonths.map((month) {
                              return DropdownMenuItem(
                                value: month,
                                child: Text(
                                  DateFormat.MMM().format(DateTime(0, month)),
                                ),
                              );
                            }).toList(),
                            onChanged: availableMonths.isEmpty
                                ? null
                                : (value) {
                                    setState(() {
                                      _selectedMonth = value;
                                    });
                                  },
                          ),
                        ),

                        const SizedBox(width: 8),

                        // ✅ Reminder Filter
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value:
                                availableReminderOptions.contains(
                                  _reminderFilter,
                                )
                                ? _reminderFilter
                                : null,
                            hint: const Text("Reminder"),
                            decoration: InputDecoration(
                              suffixIcon: _reminderFilter != null
                                  ? IconButton(
                                      icon: const Icon(Icons.clear, size: 18),
                                      onPressed: () {
                                        setState(() => _reminderFilter = null);
                                      },
                                    )
                                  : null,
                            ),
                            items: availableReminderOptions.map((option) {
                              return DropdownMenuItem(
                                value: option,
                                child: Text(
                                  option,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }).toList(),
                            onChanged: availableReminderOptions.isEmpty
                                ? null
                                : (value) {
                                    setState(() {
                                      _reminderFilter = value;
                                    });
                                  },
                          ),
                        ),
                      ],
                    ),

                    // ✅ Clear All Filters বাটন — শুধু কোনো filter active থাকলে দেখাবে
                    if (_hasActiveFilters)
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: _clearAllFilters,
                          icon: const Icon(Icons.filter_alt_off, size: 18),
                          label: const Text("Clear All Filters"),
                        ),
                      ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // ✅ CUSTOMER LIST
              Expanded(
                child: filteredCustomers.isEmpty
                    ? const Center(child: Text("No customers found"))
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredCustomers.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final customer = filteredCustomers[index];

                          return Card(
                            child: ListTile(
                              leading: const CircleAvatar(
                                child: Icon(Icons.person),
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
                                  if (customer.nextReminderDate != null &&
                                      customer.nextReminderDate!.isAfter(
                                        DateTime.now(),
                                      ))
                                    const Icon(
                                      Icons.notifications_active,
                                      color: Colors.orange,
                                      size: 20,
                                    ),
                                ],
                              ),

                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(customer.phone),
                                  Text(
                                    "Due date: ${_formatDate(customer.lastPaymentDate)}",
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),

                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    customer.totalDue.toStringAsFixed(2),
                                    style: TextStyle(
                                      color: customer.totalDue > 0
                                          ? Colors.red
                                          : Colors.green,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.call,
                                      color: Colors.green,
                                    ),
                                    onPressed: () =>
                                        _callCustomer(customer.phone),
                                  ),
                                ],
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
        onDestinationSelected: _onDestinationSelected,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_add_alt_1_outlined),
            selectedIcon: Icon(Icons.person_add_alt_1),
            label: 'Add Customer',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: 'All Customers',
          ),
          NavigationDestination(
            icon: Icon(Icons.notifications_outlined),
            selectedIcon: Icon(Icons.notifications),
            label: 'Reminders',
          ),
        ],
      ),
    );
  }
}
