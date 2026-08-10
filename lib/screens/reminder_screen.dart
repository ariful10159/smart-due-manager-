import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../l10n/app_localizations.dart';
import '../models/customer.dart';
import '../models/customer_repository.dart';
import '../services/notification_service.dart';
import '../theme/app_colors.dart';
import '../utils/helpers.dart';
import '../widgets/app_settings_scope.dart';
import '../widgets/call_button.dart';
import '../widgets/custom_bottom_nav_bar.dart';
import 'customer_detail_screen.dart';
import 'home_screen.dart';

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

  final int _selectedIndex = 3;

  ReminderSortOption _selectedSort = ReminderSortOption.dateAscending;

  bool _selectionMode = false;
  final Set<String> _selectedIds = {};

  Timer? _timer;

  // ✅ যেসব recurring reminder এর তারিখ পার হয়ে গেছে (অ্যাপ কয়েকদিন না খোলার কারণে),
  // তাদের auto-advance ইন-ফ্লাইট থাকা অবস্থায় দ্বিতীয়বার ট্রিগার আটকাতে
  final Set<String> _autoAdvancing = {};

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

    // ✅ বকেয়া সম্পূর্ণ পরিশোধ হয়ে গেলে due-reminder এর বদলে thank-you টেমপ্লেট
    final template = customer.totalDue <= 0
        ? settings.fullPaymentThankYouTemplate
        : settings.smsReminderTemplate;

    return template
        .replaceAll('{name}', customer.name)
        .replaceAll('{amount}', currencyFmt.format(customer.totalDue))
        .replaceAll('{due_date}', dateFmt.format(customer.lastPaymentDate))
        .replaceAll('{business_name}', settings.businessName)
        .replaceAll('{phone}', customer.phone);
  }

  void _enterSelectionMode(String customerId) {
    setState(() {
      _selectionMode = true;
      _selectedIds.add(customerId);
    });
  }

  void _toggleSelection(String customerId) {
    setState(() {
      if (_selectedIds.contains(customerId)) {
        _selectedIds.remove(customerId);
      } else {
        _selectedIds.add(customerId);
      }
      if (_selectedIds.isEmpty) {
        _selectionMode = false;
      }
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _selectionMode = false;
      _selectedIds.clear();
    });
  }

  void _selectAll(List<Customer> customers) {
    setState(() {
      _selectedIds
        ..clear()
        ..addAll(customers.map((c) => c.id));
    });
  }

  // ✅ Play Store SMS policy অনুযায়ী app নিজে bulk SMS পাঠাতে পারে না — প্রতিটা
  // কাস্টমারের জন্য default SMS app আলাদাভাবে prefilled অবস্থায় খুলে দেওয়া হয়,
  // ব্যবহারকারী একে একে নিজে Send করবেন
  Future<void> _confirmSendBulkSms(List<Customer> customers) async {
    final colors = AppColors.of(context);
    final l10n = AppLocalizations.of(context)!;
    final selected = customers.where((c) => _selectedIds.contains(c.id)).toList();
    if (selected.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: colors.borderColor),
        ),
        title: Text(l10n.sendSms, style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w800)),
        content: Text(
          l10n.bulkSmsConfirmBody(selected.length),
          style: TextStyle(color: colors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel, style: TextStyle(color: colors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.start, style: TextStyle(color: colors.info, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _selectionMode = false);

    if (!mounted) return;
    final openedCount = await _runSmsQueue(selected);

    if (!mounted) return;
    setState(() => _selectedIds.clear());

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.smsAppOpenedResult(openedCount, selected.length))),
    );
  }

  Future<int> _runSmsQueue(List<Customer> queue) async {
    var index = 0;
    var openedCount = 0;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            final colors = AppColors.of(sheetContext);
            final l10n = AppLocalizations.of(sheetContext)!;
            final customer = queue[index];
            final isLast = index + 1 >= queue.length;

            Future<void> advance() {
              if (isLast) {
                Navigator.pop(sheetContext);
                return Future.value();
              }
              setSheetState(() => index++);
              return Future.value();
            }

            return Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                20,
                20,
                MediaQuery.of(sheetContext).viewInsets.bottom + 20,
              ),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  border: Border.all(color: colors.borderColor),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.sendingSmsProgress(index + 1, queue.length),
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      customer.name,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(customer.phone, style: TextStyle(color: colors.textSecondary)),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: advance,
                            child: Text(isLast ? l10n.close : l10n.skip),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colors.info,
                              foregroundColor: Colors.white,
                            ),
                            icon: const Icon(Icons.sms_rounded),
                            label: Text(l10n.openSmsApp),
                            onPressed: () async {
                              final uri = buildSmsComposeUri(
                                customer.phone,
                                _buildReminderMessage(customer),
                              );
                              if (await canLaunchUrl(uri)) {
                                await launchUrl(uri);
                                await _repo.logSmsSent(
                                  customerId: customer.id,
                                  type: 'manual',
                                );
                                openedCount++;
                              }
                              await advance();
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    return openedCount;
  }

  Future<void> _callCustomer(Customer customer) async {
    final colors = AppColors.of(context);
    final uri = Uri(scheme: 'tel', path: customer.phone);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.callFailed)),
      );
      return;
    }

    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;

    // ✅ Call করার পর জিজ্ঞাসা করা হচ্ছে reminder clear করবে কিনা
    final shouldClear = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: colors.borderColor),
        ),
        title: Text(l10n.callCompleteTitle, style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w800)),
        content: Text(
          l10n.callCompleteBody(customer.name),
          style: TextStyle(color: colors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.keepReminder, style: TextStyle(color: colors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.removeReminderAction, style: TextStyle(color: colors.due, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (shouldClear == true) {
      await _clearReminder(customer);
    }
  }

  // ✅ অ্যাপ কয়েক সাইকেল বন্ধ থাকলেও recurring reminder অতীতে আটকে না থেকে
  // নিজে থেকেই পরবর্তী ভবিষ্যৎ সাইকেলে চলে যায় — ম্যানুয়ালি রিসেট করা লাগে না
  Future<void> _autoAdvanceIfNeeded(Customer customer) async {
    if (_autoAdvancing.contains(customer.id)) return;
    _autoAdvancing.add(customer.id);

    try {
      final nextDate = await _repo.advanceRecurringReminder(customer);
      if (nextDate == null) return;
      if (!mounted) return;

      await NotificationService.scheduleReminder(
        id: customer.hashCode,
        title: "Payment Reminder",
        body: "${customer.name} will pay now",
        scheduledDate: nextDate,
        smsPhone: customer.phone,
        smsMessage: _buildReminderMessage(customer),
      );
    } finally {
      _autoAdvancing.remove(customer.id);
    }
  }

  Future<void> _markRecurringDone(Customer customer) async {
    final colors = AppColors.of(context);
    try {
      final nextDate = await _repo.advanceRecurringReminder(customer);
      if (nextDate == null) return;

      await NotificationService.scheduleReminder(
        id: customer.hashCode,
        title: "Payment Reminder",
        body: "${customer.name} will pay now",
        scheduledDate: nextDate,
        smsPhone: customer.phone,
        smsMessage: _buildReminderMessage(customer),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: colors.clear,
          content: Text(AppLocalizations.of(context)!.nextReminderSetResult(_formatDateTime(nextDate))),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: colors.due,
          content: Text(AppLocalizations.of(context)!.advanceReminderFailed),
        ),
      );
    }
  }

  String _recurrenceLabel(String recurrenceType) {
    final l10n = AppLocalizations.of(context)!;
    switch (recurrenceType) {
      case 'weekly':
        return l10n.recurrenceWeekly;
      case 'biweekly':
        return l10n.recurrenceBiweeklyShort;
      case 'monthly':
      default:
        return l10n.recurrenceMonthlyShort;
    }
  }

  Future<void> _clearReminder(Customer customer) async {
    final colors = AppColors.of(context);
    try {
      await _repo.clearReminder(customer.id);
      await NotificationService.cancelReminder(customer.hashCode);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: colors.clear,
          content: Text(AppLocalizations.of(context)!.reminderRemovedFor(customer.name)),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: colors.due,
          content: Text(AppLocalizations.of(context)!.removeReminderFailed),
        ),
      );
    }
  }

  Future<void> _confirmDelete(Customer customer) async {
    final colors = AppColors.of(context);
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: colors.borderColor),
        ),
        title: Text(
          customer.isRecurringReminder ? l10n.stopRecurringReminderTitle : l10n.deleteReminderTitle,
          style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w800),
        ),
        content: Text(
          customer.isRecurringReminder
              ? l10n.stopRecurringConfirmBody(
                  _recurrenceLabel(customer.recurrenceType ?? 'monthly'),
                  customer.name,
                )
              : l10n.deleteReminderConfirmBody(customer.name),
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
              customer.isRecurringReminder ? l10n.stopRecurringAction : l10n.deleteAction,
              style: TextStyle(color: colors.due, fontWeight: FontWeight.w700),
            ),
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
    final l10n = AppLocalizations.of(context)!;

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
                  l10n.snoozeReminderTitle,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: colors.textPrimary),
                ),
              ),
              ListTile(
                leading: Icon(Icons.snooze, color: colors.accent),
                title: Text(l10n.oneHour, style: TextStyle(color: colors.textPrimary)),
                onTap: () => Navigator.pop(context, const Duration(hours: 1)),
              ),
              ListTile(
                leading: Icon(Icons.snooze, color: colors.accent),
                title: Text(l10n.tomorrowSameTime, style: TextStyle(color: colors.textPrimary)),
                onTap: () => Navigator.pop(context, const Duration(days: 1)),
              ),
              ListTile(
                leading: Icon(Icons.snooze, color: colors.accent),
                title: Text(l10n.threeDays, style: TextStyle(color: colors.textPrimary)),
                onTap: () => Navigator.pop(context, const Duration(days: 3)),
              ),
              ListTile(
                leading: Icon(Icons.snooze, color: colors.accent),
                title: Text(l10n.oneWeek, style: TextStyle(color: colors.textPrimary)),
                onTap: () => Navigator.pop(context, const Duration(days: 7)),
              ),
              ListTile(
                leading: Icon(Icons.edit_calendar, color: colors.accent),
                title: Text(l10n.customDateTime, style: TextStyle(color: colors.textPrimary)),
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
          title: Text(l10n.setCustomDateTitle, style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w800)),
          content: Text(l10n.chooseDateTimeQuestion, style: TextStyle(color: colors.textSecondary)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.cancel, style: TextStyle(color: colors.textSecondary)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(l10n.continueAction, style: TextStyle(color: colors.accent, fontWeight: FontWeight.w700)),
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
              dialogTheme: DialogThemeData(backgroundColor: colors.surface),
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
              dialogTheme: DialogThemeData(backgroundColor: colors.surface),
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

    if (!mounted) return;
    final note = await _askReminderNote();

    await _applySnooze(customer, newReminderDate, note);
  }

  Future<String?> _askReminderNote() async {
    final colors = AppColors.of(context);
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController();

    return showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: colors.borderColor),
        ),
        title: Text(
          l10n.addNoteOptional,
          style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w800),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 3,
          style: TextStyle(color: colors.textPrimary),
          decoration: InputDecoration(
            hintText: l10n.reminderNoteHint,
            hintStyle: TextStyle(color: colors.textSecondary),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: colors.borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: colors.accent),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, ''),
            child: Text(l10n.skip, style: TextStyle(color: colors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: Text(l10n.save, style: TextStyle(color: colors.accent, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Future<void> _applySnooze(Customer customer, DateTime newDate, [String? note]) async {
    final colors = AppColors.of(context);
    try {
      await _repo.addReminder(customerId: customer.id, reminderDate: newDate, note: note);

      // ✅ এখন Settings-এ সেভ করা টেমপ্লেট থেকে SMS মেসেজ তৈরি হচ্ছে
      await NotificationService.scheduleReminder(
        id: customer.hashCode,
        title: "Payment Reminder",
        body: "${customer.name} will pay now",
        scheduledDate: newDate,
        smsPhone: customer.phone,
        smsMessage: _buildReminderMessage(customer),
      );

      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: colors.clear,
          content: Text(
            l10n.reminderSnoozedTo(_formatDateTime(newDate)),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: colors.due,
          content: Text(AppLocalizations.of(context)!.failedToSnooze('$e')),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context); // ✅ dynamic dark/light কালার
    final l10n = AppLocalizations.of(context)!;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_selectionMode) {
          _exitSelectionMode();
          return;
        }
        Navigator.of(context).pushAndRemoveUntil(
          tabTransitionRoute(const HomeScreen(), false),
          (route) => false,
        );
      },
      child: StreamBuilder<List<Customer>>(
      stream: _repo.streamCustomers(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Scaffold(
            backgroundColor: colors.scaffoldBg,
            appBar: AppBar(
              title: Text(l10n.remindersTitle, style: TextStyle(fontWeight: FontWeight.w800, color: colors.textPrimary)),
              centerTitle: true,
              backgroundColor: Colors.transparent,
              elevation: 0,
              iconTheme: IconThemeData(color: colors.textPrimary),
            ),
            body: Center(child: CircularProgressIndicator(color: colors.accent)),
            bottomNavigationBar: CustomBottomNavBar(selectedIndex: _selectedIndex),
          );
        }

          List<Customer> customers = snapshot.data!
              .where((c) => c.nextReminderDate != null)
              .toList();

          customers = _applySorting(customers);

          final overdueCustomers = customers
              .where((c) => c.nextReminderDate!.isBefore(DateTime.now()))
              .toList();
          final upcomingCustomers = customers
              .where((c) => !c.nextReminderDate!.isBefore(DateTime.now()))
              .toList();

          final overdueCount = overdueCustomers.length;
          final overdueAmount = overdueCustomers.fold<double>(0, (sum, c) => sum + c.totalDue);
          final upcomingAmount = upcomingCustomers.fold<double>(0, (sum, c) => sum + c.totalDue);
          final totalAmount = overdueAmount + upcomingAmount;

          // ✅ অ্যাপ খোলার সাথে সাথেই পার হয়ে যাওয়া recurring reminder গুলো
          // পরের ভবিষ্যৎ সাইকেলে auto-advance হয়ে যায়
          final overdueRecurring = customers
              .where((c) =>
                  c.isRecurringReminder &&
                  c.nextReminderDate!.isBefore(DateTime.now()) &&
                  !_autoAdvancing.contains(c.id))
              .toList();

          if (overdueRecurring.isNotEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              for (final c in overdueRecurring) {
                _autoAdvanceIfNeeded(c);
              }
            });
          }

          if (customers.isEmpty) {
            return Scaffold(
              backgroundColor: colors.scaffoldBg,
              appBar: AppBar(
                title: Text(l10n.remindersTitle, style: TextStyle(fontWeight: FontWeight.w800, color: colors.textPrimary)),
                centerTitle: true,
                backgroundColor: Colors.transparent,
                elevation: 0,
                iconTheme: IconThemeData(color: colors.textPrimary),
              ),
              body: Center(
                child: Text(l10n.noRemindersSet, style: TextStyle(color: colors.textSecondary)),
              ),
              bottomNavigationBar: CustomBottomNavBar(selectedIndex: _selectedIndex),
            );
          }

          return Scaffold(
            backgroundColor: colors.scaffoldBg,
            appBar: _selectionMode
                ? AppBar(
                    title: Text(
                      l10n.selectedCount(_selectedIds.length),
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: colors.textPrimary),
                    ),
                    centerTitle: false,
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    iconTheme: IconThemeData(color: colors.textPrimary),
                    leading: IconButton(
                      icon: const Icon(Icons.close_rounded),
                      tooltip: l10n.cancel,
                      onPressed: _exitSelectionMode,
                    ),
                    actions: [
                      IconButton(
                        icon: const Icon(Icons.select_all_rounded),
                        tooltip: l10n.selectAll,
                        onPressed: () => _selectAll(customers),
                      ),
                      IconButton(
                        icon: Icon(Icons.sms_rounded, color: colors.info),
                        tooltip: l10n.sendSms,
                        onPressed: _selectedIds.isEmpty
                            ? null
                            : () => _confirmSendBulkSms(customers),
                      ),
                    ],
                  )
                : AppBar(
                    title: Text(l10n.remindersTitle, style: TextStyle(fontWeight: FontWeight.w800, color: colors.textPrimary)),
                    centerTitle: true,
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    iconTheme: IconThemeData(color: colors.textPrimary),
                    actions: [
                      IconButton(
                        icon: Icon(Icons.checklist_rounded, color: colors.textPrimary),
                        tooltip: l10n.selectReminders,
                        onPressed: () => _enterSelectionMode(customers.first.id),
                      ),
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
                            child: Text(l10n.sortDateNearestFirst, style: TextStyle(color: colors.textPrimary)),
                          ),
                          PopupMenuItem(
                            value: ReminderSortOption.dateDescending,
                            child: Text(l10n.sortDateLatestFirst, style: TextStyle(color: colors.textPrimary)),
                          ),
                          PopupMenuItem(
                            value: ReminderSortOption.overdueFirst,
                            child: Text(l10n.sortOverdueFirst, style: TextStyle(color: colors.textPrimary)),
                          ),
                          PopupMenuItem(
                            value: ReminderSortOption.upcomingFirst,
                            child: Text(l10n.sortUpcomingFirst, style: TextStyle(color: colors.textPrimary)),
                          ),
                        ],
                        icon: Icon(Icons.sort, color: colors.textPrimary),
                      ),
                    ],
                  ),
            bottomNavigationBar: CustomBottomNavBar(selectedIndex: _selectedIndex),
            body: Column(
              children: [
              Container(
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
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
                    Expanded(
                      child: _ReminderStat(
                        label: l10n.overdueLabel,
                        count: overdueCount,
                        amount: overdueAmount,
                        color: colors.due,
                        colors: colors,
                      ),
                    ),
                    Container(width: 1, height: 34, color: colors.borderColor),
                    Expanded(
                      child: _ReminderStat(
                        label: l10n.upcomingLabel,
                        count: upcomingCustomers.length,
                        amount: upcomingAmount,
                        color: colors.warn,
                        colors: colors,
                      ),
                    ),
                    Container(width: 1, height: 34, color: colors.borderColor),
                    Expanded(
                      child: _ReminderStat(
                        label: l10n.totalLabel,
                        count: customers.length,
                        amount: totalAmount,
                        color: colors.textPrimary,
                        colors: colors,
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
                    final isSelected = _selectedIds.contains(customer.id);

                    return Dismissible(
                      key: ValueKey(customer.id),
                      direction: _selectionMode ? DismissDirection.none : DismissDirection.endToStart,
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
                            title: Text(l10n.deleteReminderTitle, style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w800)),
                            content: Text(
                              l10n.deleteReminderConfirmBody(customer.name),
                              style: TextStyle(color: colors.textSecondary),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: Text(l10n.cancel, style: TextStyle(color: colors.textSecondary)),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: Text(l10n.deleteAction, style: TextStyle(color: colors.due, fontWeight: FontWeight.w700)),
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
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: isSelected ? colors.accent : colors.borderColor,
                            width: isSelected ? 1.6 : 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.18),
                              blurRadius: 14,
                              offset: const Offset(0, 7),
                            ),
                          ],
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Container(width: 4, color: isOverdue ? colors.due : colors.warn),
                              Expanded(
                                child: Column(
                                  children: [
                                    Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap: () {
                                          if (_selectionMode) {
                                            _toggleSelection(customer.id);
                                            return;
                                          }
                                          Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: (_) => CustomerDetailScreen(customer: customer),
                                            ),
                                          );
                                        },
                                        onLongPress: _selectionMode
                                            ? null
                                            : () => _enterSelectionMode(customer.id),
                                        child: Padding(
                                          padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              if (_selectionMode)
                                                Padding(
                                                  padding: const EdgeInsets.only(bottom: 8),
                                                  child: Row(
                                                    children: [
                                                      Icon(
                                                        isSelected
                                                            ? Icons.check_circle_rounded
                                                            : Icons.radio_button_unchecked_rounded,
                                                        color: isSelected ? colors.accent : colors.textSecondary,
                                                        size: 20,
                                                      ),
                                                      const SizedBox(width: 8),
                                                      Text(
                                                        isSelected ? l10n.selectedLabel : l10n.tapToSelect,
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          fontWeight: FontWeight.w600,
                                                          color: isSelected ? colors.accent : colors.textSecondary,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              Row(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Container(
                                                    padding: const EdgeInsets.all(9),
                                                    decoration: BoxDecoration(
                                                      color: (isOverdue ? colors.due : colors.warn).withValues(alpha: 0.15),
                                                      shape: BoxShape.circle,
                                                    ),
                                                    child: Icon(
                                                      isOverdue ? Icons.alarm_off_rounded : Icons.alarm_rounded,
                                                      color: isOverdue ? colors.due : colors.warn,
                                                      size: 20,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 12),
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Text(
                                                          customer.name,
                                                          overflow: TextOverflow.ellipsis,
                                                          style: TextStyle(
                                                            fontWeight: FontWeight.w800,
                                                            fontSize: 15.5,
                                                            color: colors.textPrimary,
                                                          ),
                                                        ),
                                                        const SizedBox(height: 6),
                                                        Row(
                                                          children: [
                                                            Container(
                                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                              decoration: BoxDecoration(
                                                                color: (isOverdue ? colors.due : colors.clear).withValues(alpha: 0.14),
                                                                borderRadius: BorderRadius.circular(20),
                                                              ),
                                                              child: Text(
                                                                _countdownText(reminderDate),
                                                                style: TextStyle(
                                                                  fontSize: 10.5,
                                                                  fontWeight: FontWeight.w700,
                                                                  color: isOverdue ? colors.due : colors.clear,
                                                                ),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Column(
                                                    crossAxisAlignment: CrossAxisAlignment.end,
                                                    children: [
                                                      Container(
                                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                                        decoration: BoxDecoration(
                                                          color: (customer.totalDue > 0 ? colors.due : colors.clear).withValues(alpha: 0.14),
                                                          borderRadius: BorderRadius.circular(10),
                                                        ),
                                                        child: Text(
                                                          customer.totalDue.toStringAsFixed(2),
                                                          style: TextStyle(
                                                            color: customer.totalDue > 0 ? colors.due : colors.clear,
                                                            fontWeight: FontWeight.w800,
                                                            fontSize: 13,
                                                          ),
                                                        ),
                                                      ),
                                                      const SizedBox(height: 6),
                                                      CallButton(
                                                        onTap: () => _callCustomer(customer),
                                                        colors: colors,
                                                        compact: true,
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 10),
                                              Row(
                                                children: [
                                                  Icon(Icons.calendar_month_rounded, size: 13, color: colors.textSecondary),
                                                  const SizedBox(width: 6),
                                                  Expanded(
                                                    child: Text(
                                                      _formatDateTime(reminderDate),
                                                      overflow: TextOverflow.ellipsis,
                                                      style: TextStyle(fontSize: 11.5, color: colors.textSecondary),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              if (customer.isRecurringReminder) ...[
                                                const SizedBox(height: 6),
                                                Row(
                                                  children: [
                                                    Icon(Icons.repeat_rounded, size: 13, color: colors.accent),
                                                    const SizedBox(width: 6),
                                                    Text(
                                                      l10n.repeatsLabel(_recurrenceLabel(customer.recurrenceType ?? 'monthly')),
                                                      style: TextStyle(fontSize: 11.5, color: colors.accent, fontWeight: FontWeight.w600),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    Divider(color: colors.borderColor, height: 1),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                      child: Row(
                                        children: [
                                          if (customer.isRecurringReminder)
                                            Expanded(
                                              child: TextButton.icon(
                                                onPressed: () => _markRecurringDone(customer),
                                                icon: Icon(Icons.check_circle_outline_rounded, size: 18, color: colors.clear),
                                                label: Text(l10n.markDone, style: TextStyle(color: colors.clear, fontWeight: FontWeight.w600)),
                                              ),
                                            )
                                          else
                                            Expanded(
                                              child: TextButton.icon(
                                                onPressed: () => _snoozeReminder(customer),
                                                icon: Icon(Icons.snooze_rounded, size: 18, color: colors.accent),
                                                label: Text(l10n.snoozeAction, style: TextStyle(color: colors.accent, fontWeight: FontWeight.w600)),
                                              ),
                                            ),
                                          Expanded(
                                            child: TextButton.icon(
                                              onPressed: () => _confirmDelete(customer),
                                              icon: Icon(Icons.delete_outline_rounded, size: 18, color: colors.due),
                                              label: Text(
                                                customer.isRecurringReminder ? l10n.stopAction : l10n.deleteAction,
                                                style: TextStyle(color: colors.due, fontWeight: FontWeight.w600),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
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
      );
  }

  String _formatDateTime(DateTime date) {
    final formatter = DateFormat('d MMMM yyyy • hh:mm a');
    return formatter.format(date);
  }

  String _countdownText(DateTime reminderDate) {
    final l10n = AppLocalizations.of(context)!;
    final now = DateTime.now();
    final difference = reminderDate.difference(now);

    if (difference.isNegative) {
      return l10n.overdueCountdown;
    }

    if (difference.inDays > 0) {
      return l10n.daysLeft(difference.inDays);
    }

    if (difference.inHours > 0) {
      return l10n.hoursLeft(difference.inHours);
    }

    return l10n.minutesLeft(difference.inMinutes);
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

class _ReminderStat extends StatelessWidget {
  const _ReminderStat({
    required this.label,
    required this.count,
    required this.amount,
    required this.color,
    required this.colors,
  });

  final String label;
  final int count;
  final double amount;
  final Color color;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
            color: colors.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          amount.toStringAsFixed(2),
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          "$count",
          style: TextStyle(fontSize: 11, color: colors.hintColor),
        ),
      ],
    );
  }
}