import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'report_screen.dart';
import '../models/customer.dart';
import '../models/customer_repository.dart';
import '../models/payment.dart';
import '../services/auth_service.dart';
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

  bool _loadingCollection = true;
  double _todayCollection = 0;
  double _weekCollection = 0;

  // 🎨 Shared dark navy palette — matches the rest of the app
  static const Color _scaffoldBg = Color(0xFF0F0F14);
  static const Color _surface = Color(0xFF1B1B24);
  static const Color _surfaceAlt = Color(0xFF20202B);
  static const Color _borderColor = Color(0xFF2C2C3A);
  static const Color _textPrimary = Colors.white;
  static const Color _textSecondary = Color(0xFF9A9AAE);
  static const Color _accent = Color(0xFF6366F1); // Indigo
  static const Color _accentAlt = Color(0xFF8B5CF6); // Violet
  static const Color _due = Color(0xFFEF4444);
  static const Color _clear = Color(0xFF10B981);
  static const Color _warn = Color(0xFFF59E0B);
  static const Color _info = Color(0xFF3B82F6);

  @override
  void initState() {
    super.initState();
    _loadCollectionStats();
  }

  Future<void> _loadCollectionStats() async {
    setState(() => _loadingCollection = true);

    try {
      final customers = await _repo.fetchCustomersOnce();

      final now = DateTime.now().toLocal();
      final todayStart = DateTime(now.year, now.month, now.day);
      final weekStart = todayStart.subtract(Duration(days: now.weekday - 1));

      double today = 0;
      double week = 0;

      for (final customer in customers) {
        final paymentsSnapshot = await _repo.streamPayments(customer.id).first;

        for (final payment in paymentsSnapshot) {
          if (payment.type != PaymentType.payment) continue;

          final paymentDateLocal = payment.date.toLocal();

          if (!paymentDateLocal.isBefore(todayStart)) {
            today += payment.amount;
          }
          if (!paymentDateLocal.isBefore(weekStart)) {
            week += payment.amount;
          }
        }
      }

      if (!mounted) return;
      setState(() {
        _todayCollection = today;
        _weekCollection = week;
        _loadingCollection = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingCollection = false);
    }
  }

  Future<void> _openAddCustomer() async {
    await Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const AddCustomerScreen()));
  }

  Future<void> _openReminderScreen() async {
    await Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const ReminderScreen()));
  }

  Future<void> _openAllCustomers() async {
    await Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const AllCustomersScreen()));
  }

  Future<void> _onDestinationSelected(int index) async {
    setState(() => _selectedIndex = index);

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
    setState(() => _selectedIndex = 0);
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
      backgroundColor: _scaffoldBg,
      appBar: AppBar(
        title: const Text(
          'Smart Due',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 19,
            letterSpacing: 0.3,
            color: _textPrimary,
          ),
        ),
        centerTitle: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: _textPrimary),
        actions: [
          _AppBarIconButton(
            icon: Icons.bar_chart_rounded,
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ReportScreen()),
              );
            },
          ),
          _AppBarIconButton(
            icon: Icons.add_rounded,
            onPressed: _openAddCustomer,
          ),
          _AppBarIconButton(
            icon: Icons.logout_rounded,
            iconColor: _due,
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  backgroundColor: _surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: _borderColor),
                  ),
                  title: const Text(
                    "Logout",
                    style: TextStyle(color: _textPrimary, fontWeight: FontWeight.w800),
                  ),
                  content: const Text(
                    "আপনি কি লগআউট করতে চান?",
                    style: TextStyle(color: _textSecondary),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text("Cancel", style: TextStyle(color: _textSecondary)),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text(
                        "Logout",
                        style: TextStyle(color: _due, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              );
              if (confirmed == true) {
                await AuthService.logout();
                if (context.mounted) {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                }
              }
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: StreamBuilder<List<Customer>>(
        stream: _repo.streamCustomers(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: _accent),
            );
          }

          final customers = snapshot.data!;
          final now = DateTime.now();

          final totalDue = customers.fold<double>(0, (sum, c) => sum + c.totalDue);
          final totalCustomers = customers.length;
          final customersWithDue = customers.where((c) => c.totalDue > 0).length;
          final fullyPaidCustomers = customers.where((c) => c.totalDue <= 0).length;

          final overdueReminders = customers
              .where((c) => c.nextReminderDate != null && c.nextReminderDate!.isBefore(now))
              .length;

          final upcomingReminders = customers
              .where((c) => c.nextReminderDate != null && c.nextReminderDate!.isAfter(now))
              .length;

          final topDueCustomers = [...customers]..sort((a, b) => b.totalDue.compareTo(a.totalDue));
          final topFive = topDueCustomers.where((c) => c.totalDue > 0).take(5).toList();

          final upcomingList = customers
              .where((c) => c.nextReminderDate != null && c.nextReminderDate!.isAfter(now))
              .toList()
            ..sort((a, b) => a.nextReminderDate!.compareTo(b.nextReminderDate!));
          final upcomingPreview = upcomingList.take(3).toList();

          return RefreshIndicator(
            color: _accent,
            backgroundColor: _surface,
            onRefresh: () async {
              await _loadCollectionStats();
              setState(() {});
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 90),
              children: [
                _GreetingHeader(greeting: _greeting()),
                const SizedBox(height: 14),

                Row(
                  children: [
                    Expanded(
                      child: _CollectionCard(
                        icon: Icons.today_rounded,
                        label: "আজকের Collection",
                        value: _loadingCollection ? null : _todayCollection.toStringAsFixed(0),
                        color: _accent,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _CollectionCard(
                        icon: Icons.calendar_view_week_rounded,
                        label: "এই সপ্তাহের Collection",
                        value: _loadingCollection ? null : _weekCollection.toStringAsFixed(0),
                        color: _accentAlt,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 1.9,
                  children: [
                    _StatCard(
                      icon: Icons.account_balance_wallet_rounded,
                      label: "Total Due",
                      value: totalDue.toStringAsFixed(0),
                      color: _due,
                    ),
                    _StatCard(
                      icon: Icons.groups_rounded,
                      label: "Total Customers",
                      value: totalCustomers.toString(),
                      color: _info,
                    ),
                    _StatCard(
                      icon: Icons.warning_amber_rounded,
                      label: "Overdue Reminders",
                      value: overdueReminders.toString(),
                      color: _warn,
                    ),
                    _StatCard(
                      icon: Icons.check_circle_rounded,
                      label: "Fully Paid",
                      value: fullyPaidCustomers.toString(),
                      color: _clear,
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: _MiniStat(
                        label: "With Due",
                        value: customersWithDue.toString(),
                        color: _due,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _MiniStat(
                        label: "Upcoming Reminders",
                        value: upcomingReminders.toString(),
                        color: _accentAlt,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                _SectionHeader(
                  title: "Top Due Customers",
                  onSeeAll: _openAllCustomers,
                ),
                const SizedBox(height: 8),

                if (topFive.isEmpty)
                  _EmptyCard(
                    icon: Icons.celebration_rounded,
                    message: "কোনো বকেয়া নেই — সব পরিষ্কার! 🎉",
                    color: _clear,
                  )
                else
                  ...topFive.map(
                    (customer) => _CustomerDueTile(
                      customer: customer,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => CustomerDetailScreen(customer: customer),
                          ),
                        );
                      },
                    ),
                  ),

                const SizedBox(height: 20),

                _SectionHeader(
                  title: "Upcoming Reminders",
                  onSeeAll: _openReminderScreen,
                ),
                const SizedBox(height: 8),

                if (upcomingPreview.isEmpty)
                  _EmptyCard(
                    icon: Icons.notifications_off_rounded,
                    message: "কোনো upcoming reminder নেই",
                    color: _textSecondary,
                  )
                else
                  ...upcomingPreview.map(
                    (customer) => _ReminderTile(
                      customer: customer,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => CustomerDetailScreen(customer: customer),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddCustomer,
        backgroundColor: _accent,
        foregroundColor: Colors.white,
        elevation: 4,
        child: const Icon(Icons.add_rounded),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: _surface,
          border: Border(top: BorderSide(color: _borderColor)),
        ),
        child: NavigationBarTheme(
          data: NavigationBarThemeData(
            backgroundColor: Colors.transparent,
            indicatorColor: _accent.withOpacity(0.18),
            labelTextStyle: WidgetStateProperty.resolveWith((states) {
              final selected = states.contains(WidgetState.selected);
              return TextStyle(
                fontSize: 11.5,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                color: selected ? _accent : _textSecondary,
              );
            }),
            iconTheme: WidgetStateProperty.resolveWith((states) {
              final selected = states.contains(WidgetState.selected);
              return IconThemeData(color: selected ? _accent : _textSecondary);
            }),
          ),
          child: NavigationBar(
            selectedIndex: _selectedIndex,
            onDestinationSelected: _onDestinationSelected,
            backgroundColor: Colors.transparent,
            elevation: 0,
            height: 62,
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home_rounded),
                label: 'Home',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_add_alt_1_outlined),
                selectedIcon: Icon(Icons.person_add_alt_1_rounded),
                label: 'Add Customer',
              ),
              NavigationDestination(
                icon: Icon(Icons.people_outline_rounded),
                selectedIcon: Icon(Icons.people_rounded),
                label: 'All Customers',
              ),
              NavigationDestination(
                icon: Icon(Icons.notifications_outlined),
                selectedIcon: Icon(Icons.notifications_rounded),
                label: 'Reminders',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// Dashboard Widgets
// ============================================================

class _AppBarIconButton extends StatelessWidget {
  const _AppBarIconButton({
    required this.icon,
    required this.onPressed,
    this.iconColor,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final Color? iconColor;

  static const Color _surface = Color(0xFF1B1B24);
  static const Color _borderColor = Color(0xFF2C2C3A);
  static const Color _textPrimary = Colors.white;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: _surface,
          shape: BoxShape.circle,
          border: Border.all(color: _borderColor),
        ),
        child: IconButton(
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          icon: Icon(icon, size: 17, color: iconColor ?? _textPrimary),
          onPressed: onPressed,
          splashRadius: 18,
        ),
      ),
    );
  }
}

class _GreetingHeader extends StatelessWidget {
  const _GreetingHeader({required this.greeting});

  final String greeting;

  static const Color _accent = Color(0xFF6366F1);
  static const Color _accentAlt = Color(0xFF8B5CF6);

  @override
  Widget build(BuildContext context) {
    final today = DateFormat('EEEE, d MMMM yyyy').format(DateTime.now());

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_accent, _accentAlt],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _accent.withOpacity(0.3),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  greeting,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  today,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.85),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.waving_hand_rounded, color: Colors.white, size: 20),
          ),
        ],
      ),
    );
  }
}

class _CollectionCard extends StatelessWidget {
  const _CollectionCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String? value;
  final Color color;

  static const Color _surface = Color(0xFF1B1B24);
  static const Color _surfaceAlt = Color(0xFF20202B);
  static const Color _borderColor = Color(0xFF2C2C3A);
  static const Color _textSecondary = Color(0xFF9A9AAE);
  static const Color _accent = Color(0xFF6366F1);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_surface, _surfaceAlt],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: _borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 15),
          ),
          const SizedBox(height: 7),
          value == null
              ? const SizedBox(
                  height: 14,
                  width: 14,
                  child: CircularProgressIndicator(strokeWidth: 2, color: _accent),
                )
              : Text(
                  value!,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 10, color: _textSecondary, fontWeight: FontWeight.w500),
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

  static const Color _surface = Color(0xFF1B1B24);
  static const Color _surfaceAlt = Color(0xFF20202B);
  static const Color _borderColor = Color(0xFF2C2C3A);
  static const Color _textSecondary = Color(0xFF9A9AAE);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_surface, _surfaceAlt],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: _borderColor),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(fontSize: 9.5, color: _textSecondary, fontWeight: FontWeight.w500),
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

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  static const Color _surface = Color(0xFF1B1B24);
  static const Color _surfaceAlt = Color(0xFF20202B);
  static const Color _borderColor = Color(0xFF2C2C3A);
  static const Color _textSecondary = Color(0xFF9A9AAE);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_surface, _surfaceAlt],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: _borderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: color.withOpacity(0.5), blurRadius: 4, spreadRadius: 0.5),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    color: Colors.white,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(fontSize: 9.5, color: _textSecondary),
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

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.onSeeAll});

  final String title;
  final VoidCallback onSeeAll;

  static const Color _accent = Color(0xFF6366F1);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14.5,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: 0.2,
          ),
        ),
        TextButton(
          onPressed: onSeeAll,
          style: TextButton.styleFrom(
            foregroundColor: _accent,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: const Text(
            "See All",
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
          ),
        ),
      ],
    );
  }
}

class _CustomerDueTile extends StatelessWidget {
  const _CustomerDueTile({required this.customer, required this.onTap});

  final Customer customer;
  final VoidCallback onTap;

  static const Color _surface = Color(0xFF1B1B24);
  static const Color _surfaceAlt = Color(0xFF20202B);
  static const Color _borderColor = Color(0xFF2C2C3A);
  static const Color _textSecondary = Color(0xFF9A9AAE);
  static const Color _accent = Color(0xFF6366F1);
  static const Color _due = Color(0xFFEF4444);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_surface, _surfaceAlt],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _borderColor),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: _accent.withOpacity(0.16),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.person_rounded, color: _accent, size: 16),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        customer.name,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13.5,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        customer.phone,
                        style: const TextStyle(fontSize: 11, color: _textSecondary),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  decoration: BoxDecoration(
                    color: _due.withOpacity(0.14),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Text(
                    customer.totalDue.toStringAsFixed(2),
                    style: const TextStyle(
                      color: _due,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ReminderTile extends StatelessWidget {
  const _ReminderTile({required this.customer, required this.onTap});

  final Customer customer;
  final VoidCallback onTap;

  static const Color _surface = Color(0xFF1B1B24);
  static const Color _surfaceAlt = Color(0xFF20202B);
  static const Color _borderColor = Color(0xFF2C2C3A);
  static const Color _textSecondary = Color(0xFF9A9AAE);
  static const Color _warn = Color(0xFFF59E0B);
  static const Color _due = Color(0xFFEF4444);
  static const Color _clear = Color(0xFF10B981);

  @override
  Widget build(BuildContext context) {
    final reminderDate = customer.nextReminderDate!;
    final formatted = DateFormat('d MMM, hh:mm a').format(reminderDate);
    final dueColor = customer.totalDue > 0 ? _due : _clear;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_surface, _surfaceAlt],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _borderColor),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: _warn.withOpacity(0.16),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.alarm_rounded, color: _warn, size: 16),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        customer.name,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13.5,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        formatted,
                        style: const TextStyle(fontSize: 11, color: _textSecondary),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  decoration: BoxDecoration(
                    color: dueColor.withOpacity(0.14),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Text(
                    customer.totalDue.toStringAsFixed(2),
                    style: TextStyle(
                      color: dueColor,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.icon, required this.message, required this.color});

  final IconData icon;
  final String message;
  final Color color;

  static const Color _surface = Color(0xFF1B1B24);
  static const Color _surfaceAlt = Color(0xFF20202B);
  static const Color _borderColor = Color(0xFF2C2C3A);
  static const Color _textSecondary = Color(0xFF9A9AAE);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_surface, _surfaceAlt],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _borderColor),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 22, color: color),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: const TextStyle(color: _textSecondary, fontWeight: FontWeight.w600, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}