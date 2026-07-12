import 'package:flutter/material.dart';
import '../models/customer.dart';
import '../widgets/customer_card.dart';
import '../widgets/dashboard_summary_card.dart';
import 'add_customer_screen.dart';
import 'customer_detail_screen.dart';
import 'all_customers_screen.dart';
import 'reminder_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Customer> _customers = [
    Customer(
      id: '1',
      name: 'Rahim Uddin',
      phone: '01700000001',
      totalDue: 1250,
      lastPaymentDate: DateTime.now().subtract(const Duration(days: 8)),
      note: 'Regular customer',
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
    ),
    Customer(
      id: '2',
      name: 'Karim Khan',
      phone: '01700000002',
      totalDue: 860,
      lastPaymentDate: DateTime.now().subtract(const Duration(days: 3)),
      createdAt: DateTime.now().subtract(const Duration(days: 10)),
    ),
  ];

  Future<void> _openAddCustomer() async {
    final customer = await Navigator.of(context).push<Customer>(
      MaterialPageRoute(builder: (_) => const AddCustomerScreen()),
    );

    if (customer != null) {
      setState(() {
        _customers.insert(0, customer);
      });
    }
  }

  Future<void> _openReminderScreen() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ReminderScreen()),
    );
  }

  Future<void> _onDestinationSelected(int index) async {
    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 1:
        await _openAddCustomer();
        break;
      case 2:
        await Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const AllCustomersScreen()),
        );
        break;
      case 3:
        await _openReminderScreen();
        break;
    }

    if (!mounted) return;

    setState(() {
      _selectedIndex = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final totalDue = _customers.fold<double>(
      0,
      (sum, customer) => sum + customer.totalDue,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Due'),
        actions: [
          IconButton(
            onPressed: _openAddCustomer,
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: DashboardSummaryCard(
                    title: 'Total Due',
                    value: totalDue.toStringAsFixed(2),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DashboardSummaryCard(
                    title: 'Customers',
                    value: _customers.length.toString(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.separated(
                itemCount: _customers.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final customer = _customers[index];
                  return CustomerCard(
                    customer: customer,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              CustomerDetailScreen(customer: customer),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddCustomer,
        child: const Icon(Icons.add),
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