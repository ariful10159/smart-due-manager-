import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../l10n/app_localizations.dart';
import 'report_screen.dart';
import 'settings_screen.dart';
import 'login_screen.dart';
import '../models/customer.dart';
import '../models/customer_repository.dart';
import '../models/payment.dart';
import '../services/auth_service.dart';
import '../theme/app_colors.dart';
import 'add_customer_screen.dart';
import 'customer_detail_screen.dart';
import 'all_customers_screen.dart';
import 'global_search_screen.dart';
import 'reminder_screen.dart';
import 'notifications_screen.dart';
import '../widgets/custom_bottom_nav_bar.dart';
import '../widgets/app_drawer.dart';
import '../widgets/announcement_banner.dart';
import '../widgets/announcement_image_popup.dart';

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

  bool _isLoggingOut = false; // ✅ logout চলাকালীন ডাবল-ট্যাপ/back বাটন আটকানোর জন্য

  @override
  void initState() {
    super.initState();
    _loadCollectionStats();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkAnnouncementPopup());
  }

  // ✅ 'popup' টাইপ active announcement থাকলে (schedule window এর মধ্যে পড়লে)
  // অ্যাপ খোলার সময় একবার image popup দেখানো হয়। একটার বেশি match করলে
  // সবচেয়ে সাম্প্রতিক আপডেট হওয়াটা দেখানো হয়।
  Future<void> _checkAnnouncementPopup() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('announcements')
          .where('active', isEqualTo: true)
          .get();

      final now = DateTime.now();
      QueryDocumentSnapshot<Map<String, dynamic>>? best;
      DateTime? bestUpdatedAt;

      for (final candidate in snapshot.docs) {
        final data = candidate.data();
        if ((data['type'] as String?) != 'popup') continue;
        final imageUrl = (data['imageUrl'] as String? ?? '').trim();
        if (imageUrl.isEmpty) continue;

        final startAt = (data['startAt'] as Timestamp?)?.toDate();
        final endAt = (data['endAt'] as Timestamp?)?.toDate();
        if (startAt != null && now.isBefore(startAt)) continue;
        if (endAt != null && now.isAfter(endAt)) continue;

        final updatedAt = (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime(0);
        if (best == null || updatedAt.isAfter(bestUpdatedAt!)) {
          best = candidate;
          bestUpdatedAt = updatedAt;
        }
      }

      if (best == null || !mounted) return;

      final data = best.data();
      final frequency = (data['frequency'] as String?) ?? 'always';
      final prefKey = 'announcement_popup_last_shown_${best.id}';

      if (frequency != 'always') {
        final prefs = await SharedPreferences.getInstance();

        if (frequency == 'once') {
          if (prefs.getBool(prefKey) == true) return;
        } else {
          final lastShownMillis = prefs.getInt(prefKey);
          if (lastShownMillis != null) {
            final lastShown = DateTime.fromMillisecondsSinceEpoch(lastShownMillis);
            final minGap = frequency == 'weekly' ? const Duration(days: 7) : const Duration(days: 1);
            if (now.difference(lastShown) < minGap) return;
          }
        }

        if (frequency == 'once') {
          await prefs.setBool(prefKey, true);
        } else {
          await prefs.setInt(prefKey, now.millisecondsSinceEpoch);
        }
      }

      if (!mounted) return;
      showDialog(
        context: context,
        builder: (_) => AnnouncementImagePopup(
          imageUrl: data['imageUrl'] as String,
          title: data['title'] as String?,
          caption: data['message'] as String?,
        ),
      );
    } catch (_) {
      // ✅ Popup non-critical — কোনো এরর হলে চুপচাপ স্কিপ করা হয়, অ্যাপ ব্লক হবে না
    }
  }

  Future<void> _loadCollectionStats() async {
    setState(() => _loadingCollection = true);

    try {
      final customers = (await _repo.fetchCustomersOnce())
          .where((c) => !c.isHidden)
          .toList();

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

  String _greeting() {
    final l10n = AppLocalizations.of(context)!;
    final hour = DateTime.now().hour;
    if (hour < 12) return l10n.greetingMorning;
    if (hour < 17) return l10n.greetingAfternoon;
    return l10n.greetingEvening;
  }

  Future<void> _handleLogout() async {
    if (!mounted) return;
    final colors = AppColors.of(context);
    final l10n = AppLocalizations.of(context)!;

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: !_isLoggingOut,
      builder: (_) => AlertDialog(
        backgroundColor: colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: colors.borderColor),
        ),
        title: Text(
          l10n.logout,
          style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w800),
        ),
        content: Text(
          l10n.logoutConfirm,
          style: TextStyle(color: colors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel, style: TextStyle(color: colors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              l10n.logout,
              style: TextStyle(color: colors.due, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (!mounted) return;

    setState(() => _isLoggingOut = true);

    // ✅ প্রথমেই সরাসরি LoginScreen এ নিয়ে যাওয়া হচ্ছে, স্ট্রিম sync এর জন্য অপেক্ষা না করে।
    // Route stack পুরোপুরি ক্লিয়ার হয়ে যায়, তাই HomeScreen আর ব্যাক বাটনে ফিরে আসবে না।
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );

    // ✅ Firebase sign-out ব্যাকগ্রাউন্ডে সম্পন্ন হচ্ছে
    await AuthService.logout();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context); // ✅ dynamic dark/light কালার
    final l10n = AppLocalizations.of(context)!;

    return PopScope(
      // ✅ Logout প্রসেস চলাকালীন back বাটন সম্পূর্ণ ব্লক করা হচ্ছে
      canPop: !_isLoggingOut,
      child: Scaffold(
        backgroundColor: colors.scaffoldBg,
        drawer: const AppDrawer(currentRoute: 'home'),
        appBar: AppBar(
          title: Text(
            'Smart Due',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 20,
              letterSpacing: 0.3,
              color: colors.textPrimary,
            ),
          ),
          centerTitle: false,
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: IconThemeData(color: colors.textPrimary),
          actions: [
            _AppBarIconButton(
              icon: Icons.search_rounded,
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const GlobalSearchScreen()),
                );
              },
            ),
            _AppBarIconButton(
              icon: Icons.notifications_none_rounded,
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                );
              },
            ),
            _AppBarIconButton(
              icon: Icons.bar_chart_rounded,
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ReportScreen()),
                );
              },
            ),
            _AppBarIconButton(
              icon: Icons.settings_rounded,
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                );
              },
            ),
            _AppBarIconButton(
              icon: Icons.add_rounded,
              onPressed: _openAddCustomer,
            ),
            _AppBarIconButton(
              icon: Icons.logout_rounded,
              iconColor: colors.due,
              onPressed: _isLoggingOut ? () {} : _handleLogout,
            ),
            const SizedBox(width: 4),
          ],
        ),
        body: Column(
          children: [
            const AnnouncementBanner(),
            Expanded(
              child: _isLoggingOut
                  ? Center(
                      child: CircularProgressIndicator(color: colors.accent),
                    )
                  : StreamBuilder<List<Customer>>(
                stream: _repo.streamCustomers(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          l10n.dataLoadError,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: colors.textSecondary, fontWeight: FontWeight.w600),
                        ),
                      ),
                    );
                  }

                  if (!snapshot.hasData) {
                    return Center(
                      child: CircularProgressIndicator(color: colors.accent),
                    );
                  }

                  final customers = snapshot.data!;
                  final now = DateTime.now();

                  final totalDue = customers.fold<double>(0, (total, c) => total + c.totalDue);
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
                    color: colors.accent,
                    backgroundColor: colors.surface,
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
                                label: l10n.todaysCollection,
                                value: _loadingCollection ? null : _todayCollection.toStringAsFixed(0),
                                color: colors.accent,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _CollectionCard(
                                icon: Icons.calendar_view_week_rounded,
                                label: l10n.weeksCollection,
                                value: _loadingCollection ? null : _weekCollection.toStringAsFixed(0),
                                color: colors.accentAlt,
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
                              label: l10n.totalDue,
                              value: totalDue.toStringAsFixed(0),
                              color: colors.due,
                            ),
                            _StatCard(
                              icon: Icons.groups_rounded,
                              label: l10n.totalCustomers,
                              value: totalCustomers.toString(),
                              color: colors.info,
                            ),
                            _StatCard(
                              icon: Icons.warning_amber_rounded,
                              label: l10n.overdueReminders,
                              value: overdueReminders.toString(),
                              color: colors.warn,
                            ),
                            _StatCard(
                              icon: Icons.check_circle_rounded,
                              label: l10n.fullyPaid,
                              value: fullyPaidCustomers.toString(),
                              color: colors.clear,
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        Row(
                          children: [
                            Expanded(
                              child: _MiniStat(
                                label: l10n.withDue,
                                value: customersWithDue.toString(),
                                color: colors.due,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _MiniStat(
                                label: l10n.upcomingReminders,
                                value: upcomingReminders.toString(),
                                color: colors.accentAlt,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        _SectionHeader(
                          title: l10n.topDueCustomers,
                          onSeeAll: _openAllCustomers,
                        ),
                        const SizedBox(height: 8),

                        if (topFive.isEmpty)
                          _EmptyCard(
                            icon: Icons.celebration_rounded,
                            message: l10n.noOutstandingDues,
                            color: colors.clear,
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
                          title: l10n.upcomingReminders,
                          onSeeAll: _openReminderScreen,
                        ),
                        const SizedBox(height: 8),

                        if (upcomingPreview.isEmpty)
                          _EmptyCard(
                            icon: Icons.notifications_off_rounded,
                            message: l10n.noUpcomingReminders,
                            color: colors.textSecondary,
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
            ),
          ],
        ),
        floatingActionButton: _isLoggingOut
            ? null
            : FloatingActionButton(
                onPressed: _openAddCustomer,
                backgroundColor: colors.accent,
                foregroundColor: Colors.white,
                elevation: 4,
                child: const Icon(Icons.add_rounded),
              ),
        bottomNavigationBar: CustomBottomNavBar(
          selectedIndex: _selectedIndex,
          isDisabled: _isLoggingOut,
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

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: colors.surface,
          shape: BoxShape.circle,
          border: Border.all(color: colors.borderColor),
        ),
        child: IconButton(
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          icon: Icon(icon, size: 17, color: iconColor ?? colors.textPrimary),
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

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final today = DateFormat('EEEE, d MMMM yyyy').format(DateTime.now());

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colors.accent, colors.accentAlt],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colors.accent.withValues(alpha: 0.3),
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
                    color: Colors.white.withValues(alpha: 0.85),
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
              color: Colors.white.withValues(alpha: 0.15),
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

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colors.surface, colors.surfaceAlt],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: colors.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 15),
          ),
          const SizedBox(height: 7),
          value == null
              ? SizedBox(
                  height: 14,
                  width: 14,
                  child: CircularProgressIndicator(strokeWidth: 2, color: colors.accent),
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
            style: TextStyle(fontSize: 10, color: colors.textSecondary, fontWeight: FontWeight.w500),
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
    final colors = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colors.surface, colors.surfaceAlt],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: colors.borderColor),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
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
                  style: TextStyle(fontSize: 9.5, color: colors.textSecondary, fontWeight: FontWeight.w500),
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

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colors.surface, colors.surfaceAlt],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: colors.borderColor),
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
                BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 4, spreadRadius: 0.5),
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
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    color: colors.textPrimary,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(fontSize: 9.5, color: colors.textSecondary),
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

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final l10n = AppLocalizations.of(context)!;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 14.5,
            fontWeight: FontWeight.w800,
            color: colors.textPrimary,
            letterSpacing: 0.2,
          ),
        ),
        TextButton(
          onPressed: onSeeAll,
          style: TextButton.styleFrom(
            foregroundColor: colors.accent,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            l10n.seeAll,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
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

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
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
              gradient: LinearGradient(
                colors: [colors.surface, colors.surfaceAlt],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: colors.borderColor),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: colors.accent.withValues(alpha: 0.16),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.person_rounded, color: colors.accent, size: 16),
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
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13.5,
                          color: colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        customer.phone,
                        style: TextStyle(fontSize: 11, color: colors.textSecondary),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  decoration: BoxDecoration(
                    color: colors.due.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Text(
                    customer.totalDue.toStringAsFixed(2),
                    style: TextStyle(
                      color: colors.due,
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

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final reminderDate = customer.nextReminderDate!;
    final formatted = DateFormat('d MMM, hh:mm a').format(reminderDate);
    final dueColor = customer.totalDue > 0 ? colors.due : colors.clear;

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
              gradient: LinearGradient(
                colors: [colors.surface, colors.surfaceAlt],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: colors.borderColor),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: colors.warn.withValues(alpha: 0.16),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.alarm_rounded, color: colors.warn, size: 16),
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
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13.5,
                          color: colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        formatted,
                        style: TextStyle(fontSize: 11, color: colors.textSecondary),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  decoration: BoxDecoration(
                    color: dueColor.withValues(alpha: 0.14),
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

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colors.surface, colors.surfaceAlt],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.borderColor),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 22, color: color),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(color: colors.textSecondary, fontWeight: FontWeight.w600, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}