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
          MaterialPageRoute(
              builder: (_) => const HomeScreen()),
          (route) => false,
        );
        break;
      case 1:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (_) =>
                  const AddCustomerScreen()),
        );
        break;
      case 3:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (_) =>
                  const ReminderScreen()),
        );
        break;
    }
  }

  String _formatDate(DateTime date) {
    return DateFormat('d MMM yyyy')
        .format(date);
  }

  @override
  Widget build(BuildContext context) {
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
              child:
                  CircularProgressIndicator(),
            );
          }

          final customers = snapshot.data!;

          if (customers.isEmpty) {
            return const Center(
              child:
                  Text("No customers found"),
            );
          }

          return ListView.separated(
            padding:
                const EdgeInsets.all(16),
            itemCount:
                customers.length,
            separatorBuilder:
                (_, __) =>
                    const SizedBox(
                        height: 8),
            itemBuilder:
                (context, index) {
              final customer =
                  customers[index];

              return Card(
                child: ListTile(
                  leading:
                      const CircleAvatar(
                    child:
                        Icon(Icons.person),
                  ),

                  // ✅ NAME
                  title: Text(
                    customer.name,
                    style:
                        const TextStyle(
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  // ✅ PHONE + DUE DATE (NEW ADDED)
                  subtitle: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(customer.phone),
                      const SizedBox(height: 2),
                      Text(
                        "Due date: ${_formatDate(customer.lastPaymentDate)}",
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
                        style:
                            TextStyle(
                          color: customer
                                      .totalDue >
                                  0
                              ? Colors.red
                              : Colors.green,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                      const SizedBox(
                          width: 8),
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
          );
        },
      ),

      bottomNavigationBar:
          NavigationBar(
        selectedIndex:
            _selectedIndex,
        onDestinationSelected:
            _onDestinationSelected,
        destinations: const [
          NavigationDestination(
            icon: Icon(
                Icons.home_outlined),
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
            label:
                'Add Customer',
          ),
          NavigationDestination(
            icon: Icon(
                Icons.people_outline),
            selectedIcon:
                Icon(Icons.people),
            label:
                'All Customers',
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