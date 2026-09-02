import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../l10n/app_localizations.dart';
import 'settings_screen.dart';
import '../models/customer.dart';
import '../models/customer_repository.dart';
import '../models/payment.dart';
import '../theme/app_colors.dart';
import 'add_customer_screen.dart';
import 'customer_detail_screen.dart';
import 'all_customers_screen.dart';
import 'global_search_screen.dart';
import 'reminder_screen.dart';
import 'notifications_screen.dart';
import '../widgets/custom_bottom_nav_bar.dart';
import '../widgets/app_drawer.dart';
import '../widgets/app_settings_scope.dart';
import '../widgets/announcement_banner.dart';
import '../widgets/announcement_image_popup.dart';
import '../route_observer.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with RouteAware {
  final _repo = CustomerRepository();
  final _selectedIndex = 0; // ✅ Home সবসময় bottom nav-এর index 0, কখনো বদলায় না

  bool _loadingCollection = true;
  double _todayCollection = 0;
  double _weekCollection = 0;

  @override
  void initState() {
    super.initState();
    _loadCollectionStats();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkAnnouncementPopup());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) appRouteObserver.subscribe(this, route);
  }

  @override
  void dispose() {
    appRouteObserver.unsubscribe(this);
    super.dispose();
  }

  // ✅ Customer Detail (বা অন্য কোনো পুশ করা) স্ক্রিন থেকে payment যোগ করে Home এ
  // ফিরে এলে এটা কল হয় — আগে Today's/Week's Collection কার্ড শুধু initState এ
  // একবার লোড হতো, তাই back করে ফিরলেও নতুন payment ধরত না (customer list এর
  // মতো live stream না হওয়ায়), দেখাত পুরনো/০ সংখ্যা
  @override
  void didPopNext() {
    _loadCollectionStats();
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
      final now = DateTime.now().toLocal();
      final todayStart = DateTime(now.year, now.month, now.day);
      final weekStart = todayStart.subtract(Duration(days: now.weekday - 1));

      // ✅ আগে collectionGroup('payments') + where('ownerId', ...) দিয়ে একটা
      // মাত্র query চালানো হতো — এটা fast কিন্তু দুটো কারণে চুপচাপ ব্যর্থ হতে
      // পারত: (১) এই compound query এর জন্য দরকারি Firestore composite index
      // deploy করা না থাকলে, বা (২) পুরনো/অন্য কোনো path দিয়ে লেখা payment
      // ডকুমেন্টে 'ownerId' ফিল্ড না থাকলে — দুই ক্ষেত্রেই ফলাফল ছিল silent
      // ০ (এরর দেখা যেত না)। report_screen.dart ঠিক এই একই ডেটার জন্য প্রতিটা
      // কাস্টমারের payments subcollection সরাসরি (কোনো where filter ছাড়া)
      // fetch করে ক্লায়েন্ট-সাইডে ফিল্টার করে — এবং সেটা নির্ভরযোগ্যভাবে কাজ
      // করে। এখানেও সেই একই প্রমাণিত পদ্ধতি ব্যবহার করা হচ্ছে, index/ownerId
      // এর উপর নির্ভরতা সম্পূর্ণ বাদ দিয়ে।
      // ✅ আগে এখানে archived (isHidden) কাস্টমারদের বাদ দেওয়া হতো — কিন্তু
      // কেউ পুরো বকেয়া পরিশোধ করলে সেই payment টা সত্যিই আজ/এই সপ্তাহে হয়েছে,
      // পরে কাস্টমারকে archive করে দেওয়াটা শুধু active লিস্ট গোছানোর জন্য —
      // সেই payment টা historical collection থেকে বাদ যাওয়ার কথা না। report_screen.dart
      // এই একই হিসাবে কখনোই isHidden ফিল্টার করে না, তাই এখানেও সরানো হলো —
      // দুই স্ক্রিনের collection সংখ্যা এখন সামঞ্জস্যপূর্ণ থাকবে।
      // ⚠️ collectionGroup('payments') + composite index (ownerId+type+date)
      // পদ্ধতিটা চেষ্টা করা হয়েছিল, কিন্তু ওই composite index repo-র
      // firestore.indexes.json এ লেখা থাকলেও লাইভ Firestore project এ deploy
      // করা ছিল না — ফলে query FAILED_PRECONDITION এরর দিত এবং কার্ড ৳০ দেখিয়ে
      // "failed to load" snackbar আসত। তাই আপাতত আগের প্রমাণিত পদ্ধতিতে ফেরত
      // আনা হলো — প্রতি কাস্টমারের payments subcollection থেকে সরাসরি (কোনো
      // composite index ছাড়াই) এই সপ্তাহের payment আনা হচ্ছে। index deploy করা
      // হলে collectionGroup পদ্ধতিতে আবার যাওয়া যাবে (আরও দ্রুত, ১৯৪-টার বদলে
      // ১-টা request)।
      final customers = await _repo.fetchCustomersOnce();

      final snapshots = await Future.wait(
        customers.map(
          (c) => FirebaseFirestore.instance
              .collection('customers')
              .doc(c.id)
              .collection('payments')
              .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(weekStart))
              .get(),
        ),
      );

      double today = 0;
      double week = 0;

      for (final snapshot in snapshots) {
        for (final doc in snapshot.docs) {
          try {
            final payment = Payment.fromMap({...doc.data(), 'id': doc.id});
            if (payment.type != PaymentType.payment) continue;

            final paymentDateLocal = payment.date.toLocal();
            if (paymentDateLocal.isBefore(weekStart)) continue;

            week += payment.amount;
            if (!paymentDateLocal.isBefore(todayStart)) {
              today += payment.amount;
            }
          } catch (e) {
            debugPrint('Error parsing payment ID ${doc.id}: $e');
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
      // ✅ আগে এই এরর কোথাও log হতো না — কালেকশন কার্ড চুপচাপ ০ (বা আগের) ভ্যালু
      // দেখিয়ে যেত, ইউজার কিছুই বুঝতে পারত না। একই স্ক্রিনের customer stream
      // ব্যর্থ হলে l10n.dataLoadError দেখানো হয় (নিচের StreamBuilder), এখানেও
      // সেই একই consistency আনা হলো — শুধু পুরো ড্যাশবোর্ড ঢেকে না দিয়ে (বাকি
      // অংশ — Total Due, Top Due Customers ইত্যাদি — আলাদা স্ট্রিম থেকে আসে,
      // এখনও ঠিকঠাক কাজ করে) একটা হালকা SnackBar দিয়ে জানানো হচ্ছে
      debugPrint('Failed to load collection stats: $e');
      if (!mounted) return;
      setState(() => _loadingCollection = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.failedToLoadCollectionStats)),
      );
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

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context); // ✅ dynamic dark/light কালার
    final l10n = AppLocalizations.of(context)!;
    final settings = AppSettingsScope.of(context).settings;
    // ✅ ইউজার settings > Business Profile এ shop/business name সেভ করলে top bar এ
    // সেটাই দেখানো হয় — সেভ করা না থাকলে (খালি থাকলে) ডিফল্ট "Smart Due" দেখায়
    final businessName = settings.businessName.trim();
    final appBarTitle = businessName.isEmpty ? 'Smart Due' : businessName;
    // ✅ Settings > Currency তে বেছে নেওয়া symbol — আগে এই স্ক্রিনে টাকার
    // অ্যামাউন্টে কোনো currency indicator-ই ছিল না, শুধু raw সংখ্যা দেখাত
    final currencySymbol = settings.currencySymbol;

    return Scaffold(
        backgroundColor: colors.scaffoldBg,
        drawer: const AppDrawer(currentRoute: 'home'),
        appBar: AppBar(
          title: Text(
            appBarTitle,
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
              icon: Icons.settings_rounded,
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                );
              },
            ),
            const SizedBox(width: 4),
          ],
        ),
        body: Column(
          children: [
            const AnnouncementBanner(),
            Expanded(
              child: StreamBuilder<List<Customer>>(
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
                  final currencyFmt = NumberFormat('#,##0');

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
                    onRefresh: _loadCollectionStats,
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
                                value: _loadingCollection
                                    ? null
                                    : '$currencySymbol${currencyFmt.format(_todayCollection)}',
                                color: colors.accent,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _CollectionCard(
                                icon: Icons.calendar_view_week_rounded,
                                label: l10n.weeksCollection,
                                value: _loadingCollection
                                    ? null
                                    : '$currencySymbol${currencyFmt.format(_weekCollection)}',
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
                              value: '$currencySymbol${currencyFmt.format(totalDue)}',
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
                              currencySymbol: currencySymbol,
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
                              currencySymbol: currencySymbol,
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
        floatingActionButton: FloatingActionButton(
          onPressed: _openAddCustomer,
          backgroundColor: colors.accent,
          foregroundColor: Colors.white,
          elevation: 4,
          child: const Icon(Icons.add_rounded),
        ),
        bottomNavigationBar: CustomBottomNavBar(
          selectedIndex: _selectedIndex,
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
  });

  final IconData icon;
  final VoidCallback onPressed;

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
          icon: Icon(icon, size: 17, color: colors.textPrimary),
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
            color: colors.accent.withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.14),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
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
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.14),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
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
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
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
  const _CustomerDueTile({required this.customer, required this.onTap, required this.currencySymbol});

  final Customer customer;
  final VoidCallback onTap;
  final String currencySymbol;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final currencyFmt = NumberFormat('#,##0.00');
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
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 14,
                  offset: const Offset(0, 5),
                ),
              ],
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
                    '$currencySymbol${currencyFmt.format(customer.totalDue)}',
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
  const _ReminderTile({required this.customer, required this.onTap, required this.currencySymbol});

  final Customer customer;
  final VoidCallback onTap;
  final String currencySymbol;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final reminderDate = customer.nextReminderDate!;
    final formatted = DateFormat('d MMM, hh:mm a').format(reminderDate);
    final dueColor = customer.totalDue > 0 ? colors.due : colors.clear;
    final currencyFmt = NumberFormat('#,##0.00');

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
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 14,
                  offset: const Offset(0, 5),
                ),
              ],
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
                    '$currencySymbol${currencyFmt.format(customer.totalDue)}',
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
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