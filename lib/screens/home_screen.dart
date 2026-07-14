import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'report_screen.dart';
import '../models/customer.dart';
import '../models/customer_repository.dart';
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
  final _repo = CustomerRepository();
  int _selectedIndex = 0;

  Future<void> _openAddCustomer() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const AddCustomerScreen()));
  }

  Future<void> _openReminderScreen() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const ReminderScreen()));
  }

  Future<void> _openAllCustomers() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const AllCustomersScreen()));
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
        await _openAllCustomers();
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

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return "Good Morning";
    if (hour < 17) return "Good Afternoon";
    return "Good Evening";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Due'),
        actions: [
          // 📊 রিপোর্ট স্ক্রিনে যাওয়ার জন্য বাটন যোগ করা হয়েছে
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ReportScreen()),
              );
            },
            icon: const Icon(Icons.bar_chart),
          ),
          IconButton(
            onPressed: _openAddCustomer, 
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: StreamBuilder<List<Customer>>(
        stream: _repo.streamCustomers(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final customers = snapshot.data!;
          final now = DateTime.now();

          // ✅ সব হিসাব real Firestore data থেকে হচ্ছে
          final totalDue = customers.fold<double>(
            0,
            (sum, c) => sum + c.totalDue,
          );

          final totalCustomers = customers.length;

          final customersWithDue = customers
              .where((c) => c.totalDue > 0)
              .length;

          final fullyPaidCustomers = customers
              .where((c) => c.totalDue <= 0)
              .length;

          final overdueReminders = customers
              .where(
                (c) =>
                    c.nextReminderDate != null &&
                    c.nextReminderDate!.isBefore(now),
              )
              .length;

          final upcomingReminders = customers
              .where(
                (c) =>
                    c.nextReminderDate != null &&
                    c.nextReminderDate!.isAfter(now),
              )
              .length;

          final topDueCustomers = [...customers]
            ..sort((a, b) => b.totalDue.compareTo(a.totalDue));
          final topFive = topDueCustomers
              .where((c) => c.totalDue > 0)
              .take(5)
              .toList();

          final upcomingList =
              customers
                  .where(
                    (c) =>
                        c.nextReminderDate != null &&
                        c.nextReminderDate!.isAfter(now),
                  )
                  .toList()
                ..sort(
                  (a, b) =>
                      a.nextReminderDate!.compareTo(b.nextReminderDate!),
                );
          final upcomingPreview = upcomingList.take(3).toList();

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {});
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // ✅ Greeting Header
                _GreetingHeader(greeting: _greeting()),
                const SizedBox(height: 20),

                // ✅ Summary Stats Grid (2x2)
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.4,
                  children: [
                    _StatCard(
                      icon: Icons.account_balance_wallet,
                      label: "Total Due",
                      value: totalDue.toStringAsFixed(0),
                      color: Colors.red,
                    ),
                    _StatCard(
                      icon: Icons.people,
                      label: "Total Customers",
                      value: totalCustomers.toString(),
                      color: Colors.blue,
                    ),
                    _StatCard(
                      icon: Icons.warning_amber_rounded,
                      label: "Overdue Reminders",
                      value: overdueReminders.toString(),
                      color: Colors.orange,
                    ),
                    _StatCard(
                      icon: Icons.check_circle,
                      label: "Fully Paid",
                      value: fullyPaidCustomers.toString(),
                      color: Colors.green,
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // ✅ Secondary quick stats row
                Row(
                  children: [
                    Expanded(
                      child: _MiniStat(
                        label: "With Due",
                        value: customersWithDue.toString(),
                        color: Colors.red,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _MiniStat(
                        label: "Upcoming Reminders",
                        value: upcomingReminders.toString(),
                        color: Colors.teal,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // ✅ Top Due Customers Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Top Due Customers",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton(
                      onPressed: _openAllCustomers,
                      child: const Text("See All"),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                if (topFive.isEmpty)
                  _EmptyCard(
                    icon: Icons.celebration,
                    message: "কোনো বকেয়া নেই — সব পরিষ্কার! 🎉",
                  )
                else
                  ...topFive.map(
                    (customer) => _CustomerDueTile(
                      customer: customer,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                CustomerDetailScreen(customer: customer),
                          ),
                        );
                      },
                    ),
                  ),

                const SizedBox(height: 24),

                // ✅ Upcoming Reminders Preview
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Upcoming Reminders",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton(
                      onPressed: _openReminderScreen,
                      child: const Text("See All"),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                if (upcomingPreview.isEmpty)
                  _EmptyCard(
                    icon: Icons.notifications_off_outlined,
                    message: "কোনো upcoming reminder নেই",
                  )
                else
                  ...upcomingPreview.map(
                    (customer) => _ReminderTile(
                      customer: customer,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                CustomerDetailScreen(customer: customer),
                          ),
                        );
                      },
                    ),
                  ),

                const SizedBox(height: 80),
              ],
            ),
          );
        },
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

// ============================================================
// ✅ Dashboard Widgets — সব একই ফাইলে, কোনো external dependency নেই
// ============================================================

class _GreetingHeader extends StatelessWidget {
  const _GreetingHeader({required this.greeting});

  final String greeting;

  @override
  Widget build(BuildContext context) {
    final today = DateFormat('EEEE, d MMMM yyyy').format(DateTime.now());

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            greeting,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            today,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 26),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CustomerDueTile extends StatelessWidget {
  const _CustomerDueTile({required this.customer, required this.onTap});

  final Customer customer;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.person)),
        title: Text(
          customer.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(customer.phone),
        trailing: Text(
          customer.totalDue.toStringAsFixed(2),
          style: const TextStyle(
            color: Colors.red,
            fontWeight: FontWeight.bold,
          ),
        ),
        onTap: onTap,
      ),
    );
  }
}

class _ReminderTile extends StatelessWidget {
  const _ReminderTile({required this.customer, required this.onTap});

  final Customer customer;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final reminderDate = customer.nextReminderDate!;
    final formatted = DateFormat('d MMM, hh:mm a').format(reminderDate);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Colors.orange,
          child: Icon(Icons.alarm, color: Colors.white),
        ),
        title: Text(
          customer.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(formatted),
        trailing: Text(
          customer.totalDue.toStringAsFixed(2),
          style: TextStyle(
            color: customer.totalDue > 0 ? Colors.red : Colors.green,
            fontWeight: FontWeight.bold,
          ),
        ),
        onTap: onTap,
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, size: 36, color: Colors.grey),
          const SizedBox(height: 8),
          Text(
            message,
            style: const TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}