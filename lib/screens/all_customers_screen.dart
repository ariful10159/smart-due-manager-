import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';

import '../l10n/app_localizations.dart';
import '../models/customer.dart';
import '../models/customer_repository.dart';
import '../theme/app_colors.dart';
import '../utils/helpers.dart';
import '../widgets/app_settings_scope.dart';
import '../widgets/call_button.dart';
import '../widgets/custom_bottom_nav_bar.dart';
import 'archived_customers_screen.dart';
import 'customer_detail_screen.dart';
import 'home_screen.dart';

enum CustomerSortOption {
  none,
  dueHighToLow,
  dueLowToHigh,
  nameAZ,
  nameZA,
  recentlyAdded,
}

class AllCustomersScreen extends StatefulWidget {
  const AllCustomersScreen({super.key});

  @override
  State<AllCustomersScreen> createState() => _AllCustomersScreenState();
}

class _AllCustomersScreenState extends State<AllCustomersScreen> {
  final _repo = CustomerRepository();
  final _searchController = TextEditingController();

  final int _selectedIndex = 2;

  int? _selectedYear;
  int? _selectedMonth;
  String? _reminderFilter;
  String _searchQuery = '';
  CustomerSortOption _sortOption = CustomerSortOption.none;

  bool _selectionMode = false;
  final Set<String> _selectedIds = {};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _callCustomer(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.callFailed)),
      );
    }
  }

  String _buildDueMessage(Customer customer) {
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
                                _buildDueMessage(customer),
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

  String _formatDate(DateTime date) {
    return DateFormat('d MMM yyyy').format(date);
  }

  List<int> _availableYears(List<Customer> customers) {
    final years = customers.map((c) => c.lastPaymentDate.year).toSet().toList();
    years.sort((a, b) => b.compareTo(a));
    return years;
  }

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

    final l10n = AppLocalizations.of(context)!;
    if (hasReminderSet) options.add(l10n.reminderSet);
    if (hasNoReminder) options.add(l10n.noReminder);

    return options;
  }

  // ✅ Search filter — নাম অথবা ফোন নাম্বার দিয়ে
  List<Customer> _applySearch(List<Customer> customers) {
    if (_searchQuery.trim().isEmpty) return customers;

    final query = _searchQuery.trim().toLowerCase();
    return customers.where((c) {
      final nameMatch = c.name.toLowerCase().contains(query);
      final phoneMatch = c.phone
          .replaceAll(RegExp(r'[\s\-]'), '')
          .contains(query.replaceAll(RegExp(r'[\s\-]'), ''));
      return nameMatch || phoneMatch;
    }).toList();
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

  // ✅ Sort apply করা
  List<Customer> _applySort(List<Customer> customers) {
    final sorted = [...customers];

    switch (_sortOption) {
      case CustomerSortOption.dueHighToLow:
        sorted.sort((a, b) => b.totalDue.compareTo(a.totalDue));
        break;
      case CustomerSortOption.dueLowToHigh:
        sorted.sort((a, b) => a.totalDue.compareTo(b.totalDue));
        break;
      case CustomerSortOption.nameAZ:
        sorted.sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        );
        break;
      case CustomerSortOption.nameZA:
        sorted.sort(
          (a, b) => b.name.toLowerCase().compareTo(a.name.toLowerCase()),
        );
        break;
      case CustomerSortOption.recentlyAdded:
        sorted.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case CustomerSortOption.none:
        break;
    }

    return sorted;
  }

  String _sortLabel(BuildContext context, CustomerSortOption option) {
    final l10n = AppLocalizations.of(context)!;
    switch (option) {
      case CustomerSortOption.dueHighToLow:
        return l10n.sortDueHighLow;
      case CustomerSortOption.dueLowToHigh:
        return l10n.sortDueLowHigh;
      case CustomerSortOption.nameAZ:
        return l10n.sortNameAZ;
      case CustomerSortOption.nameZA:
        return l10n.sortNameZA;
      case CustomerSortOption.recentlyAdded:
        return l10n.sortRecentlyAdded;
      case CustomerSortOption.none:
        return l10n.sortDefault;
    }
  }

  bool get _hasActiveFilters =>
      _selectedYear != null ||
      _selectedMonth != null ||
      _reminderFilter != null ||
      _searchQuery.trim().isNotEmpty ||
      _sortOption != CustomerSortOption.none;

  void _clearAllFilters() {
    setState(() {
      _selectedYear = null;
      _selectedMonth = null;
      _reminderFilter = null;
      _searchQuery = '';
      _searchController.clear();
      _sortOption = CustomerSortOption.none;
    });
  }

  InputDecoration _dropdownDecoration(AppColors colors, {Widget? suffixIcon}) {
    return InputDecoration(
      suffixIcon: suffixIcon,
      suffixIconConstraints: const BoxConstraints(
        minWidth: 28,
        minHeight: 28,
      ),
      filled: true,
      fillColor: colors.surface,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 12,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colors.borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colors.borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colors.accent, width: 1.4),
      ),
    );
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
              title: Text(
                l10n.navAllCustomers,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                  letterSpacing: 0.3,
                  color: colors.textPrimary,
                ),
              ),
              centerTitle: true,
              backgroundColor: Colors.transparent,
              elevation: 0,
              iconTheme: IconThemeData(color: colors.textPrimary),
            ),
            body: Center(
              child: CircularProgressIndicator(color: colors.accent),
            ),
            bottomNavigationBar: CustomBottomNavBar(
              selectedIndex: _selectedIndex,
            ),
          );
        }

        final allCustomers = snapshot.data!;

        // ✅ ধাপে ধাপে filter/search/sort apply করা হচ্ছে
          var result = _applyFilters(allCustomers);
          result = _applySearch(result);
          result = _applySort(result);

          final availableYears = _availableYears(allCustomers);
          final availableMonths = _availableMonths(allCustomers);
          final availableReminderOptions = _availableReminderOptions(
            allCustomers,
          );

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

          final totalDueInView = result.fold<double>(
            0,
            (sum, c) => sum + c.totalDue,
          );

          return Scaffold(
            backgroundColor: colors.scaffoldBg,
            appBar: _selectionMode
                ? AppBar(
                    title: Text(
                      l10n.selectedCount(_selectedIds.length),
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                        color: colors.textPrimary,
                      ),
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
                        onPressed: () => _selectAll(result),
                      ),
                      IconButton(
                        icon: Icon(Icons.sms_rounded, color: colors.info),
                        tooltip: l10n.sendSms,
                        onPressed: _selectedIds.isEmpty
                            ? null
                            : () => _confirmSendBulkSms(result),
                      ),
                    ],
                  )
                : AppBar(
                    title: Text(
                      l10n.navAllCustomers,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 20,
                        letterSpacing: 0.3,
                        color: colors.textPrimary,
                      ),
                    ),
                    centerTitle: true,
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    iconTheme: IconThemeData(color: colors.textPrimary),
                    actions: [
                      // ✅ Sort menu
                      PopupMenuButton<CustomerSortOption>(
                        icon: Icon(Icons.sort_rounded, color: colors.textPrimary),
                        tooltip: l10n.sort,
                        color: colors.surface,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: BorderSide(color: colors.borderColor),
                        ),
                        onSelected: (value) {
                          setState(() => _sortOption = value);
                        },
                        itemBuilder: (context) =>
                            CustomerSortOption.values.map((option) {
                          final isSelected = _sortOption == option;
                          return PopupMenuItem(
                            value: option,
                            child: Row(
                              children: [
                                if (isSelected)
                                  Icon(Icons.check, size: 18, color: colors.accent)
                                else
                                  const SizedBox(width: 18),
                                const SizedBox(width: 8),
                                Text(
                                  _sortLabel(context, option),
                                  style: TextStyle(
                                    color: isSelected
                                        ? colors.accent
                                        : colors.textPrimary,
                                    fontWeight: isSelected
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                      IconButton(
                        icon: Icon(Icons.checklist_rounded, color: colors.textPrimary),
                        tooltip: l10n.selectCustomers,
                        onPressed: result.isEmpty
                            ? null
                            : () => _enterSelectionMode(result.first.id),
                      ),
                      IconButton(
                        icon: Icon(Icons.archive_outlined, color: colors.textPrimary),
                        tooltip: l10n.drawerArchived,
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
            bottomNavigationBar: CustomBottomNavBar(
              selectedIndex: _selectedIndex,
            ),
            body: Column(
              children: [
              // ✅ SEARCH BOX
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: TextField(
                  controller: _searchController,
                  style: TextStyle(color: colors.textPrimary, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: l10n.searchNamePhoneHint,
                    hintStyle: TextStyle(
                      color: colors.hintColor,
                      fontSize: 13.5,
                    ),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: colors.textSecondary,
                    ),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: Icon(
                              Icons.clear_rounded,
                              color: colors.textSecondary,
                            ),
                            onPressed: () {
                              setState(() {
                                _searchQuery = '';
                                _searchController.clear();
                              });
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: colors.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: colors.borderColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: colors.borderColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: colors.accent, width: 1.4),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  ),
                  onChanged: (value) {
                    setState(() => _searchQuery = value);
                  },
                ),
              ),

              // ✅ FILTER DROPDOWNS
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            isExpanded: true,
                            initialValue: availableYears.contains(_selectedYear)
                                ? _selectedYear
                                : null,
                            hint: Text(
                              l10n.yearLabel,
                              style: TextStyle(color: colors.hintColor, fontSize: 13),
                            ),
                            dropdownColor: colors.surface,
                            style: TextStyle(
                              color: colors.textPrimary,
                              fontSize: 13,
                            ),
                            icon: Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: colors.textSecondary,
                            ),
                            decoration: _dropdownDecoration(
                              colors,
                              suffixIcon: _selectedYear != null
                                  ? IconButton(
                                      icon: Icon(
                                        Icons.clear,
                                        size: 16,
                                        color: colors.textSecondary,
                                      ),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      visualDensity: VisualDensity.compact,
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
                                      _selectedMonth = null;
                                    });
                                  },
                          ),
                        ),

                        const SizedBox(width: 8),

                        Expanded(
                          child: DropdownButtonFormField<int>(
                            isExpanded: true,
                            initialValue: availableMonths.contains(_selectedMonth)
                                ? _selectedMonth
                                : null,
                            hint: Text(
                              l10n.monthLabel,
                              style: TextStyle(color: colors.hintColor, fontSize: 13),
                            ),
                            dropdownColor: colors.surface,
                            style: TextStyle(
                              color: colors.textPrimary,
                              fontSize: 13,
                            ),
                            icon: Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: colors.textSecondary,
                            ),
                            decoration: _dropdownDecoration(
                              colors,
                              suffixIcon: _selectedMonth != null
                                  ? IconButton(
                                      icon: Icon(
                                        Icons.clear,
                                        size: 16,
                                        color: colors.textSecondary,
                                      ),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      visualDensity: VisualDensity.compact,
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

                        Expanded(
                          child: DropdownButtonFormField<String>(
                            isExpanded: true,
                            initialValue:
                                availableReminderOptions.contains(
                                  _reminderFilter,
                                )
                                ? _reminderFilter
                                : null,
                            hint: Text(
                              l10n.reminderLabel,
                              style: TextStyle(color: colors.hintColor, fontSize: 13),
                            ),
                            dropdownColor: colors.surface,
                            style: TextStyle(
                              color: colors.textPrimary,
                              fontSize: 13,
                            ),
                            icon: Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: colors.textSecondary,
                            ),
                            decoration: _dropdownDecoration(
                              colors,
                              suffixIcon: _reminderFilter != null
                                  ? IconButton(
                                      icon: Icon(
                                        Icons.clear,
                                        size: 16,
                                        color: colors.textSecondary,
                                      ),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      visualDensity: VisualDensity.compact,
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

                    if (_hasActiveFilters)
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: _clearAllFilters,
                          style: TextButton.styleFrom(foregroundColor: colors.due),
                          icon: const Icon(
                            Icons.filter_alt_off_rounded,
                            size: 17,
                          ),
                          label: Text(
                            l10n.clearAllFilters,
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // ✅ Filtered Summary Bar — কতজন দেখাচ্ছে + মোট বকেয়া
              if (_hasActiveFilters || result.isNotEmpty)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
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
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.groups_rounded,
                            size: 16,
                            color: colors.textSecondary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            l10n.customersFoundCount(result.length),
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: colors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        l10n.totalDueColon(totalDueInView.toStringAsFixed(2)),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: totalDueInView > 0 ? colors.due : colors.clear,
                        ),
                      ),
                    ],
                  ),
                ),

              // ✅ CUSTOMER LIST
              Expanded(
                child: result.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                color: colors.surface,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                _searchQuery.isNotEmpty
                                    ? Icons.search_off_rounded
                                    : Icons.people_outline_rounded,
                                size: 40,
                                color: colors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              _searchQuery.isNotEmpty
                                  ? l10n.noSearchResults(_searchQuery)
                                  : l10n.noCustomersFound,
                              style: TextStyle(
                                color: colors.textSecondary,
                                fontWeight: FontWeight.w600,
                                fontSize: 13.5,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        itemCount: result.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final customer = result[index];
                          final hasActiveReminder =
                              customer.nextReminderDate != null &&
                              customer.nextReminderDate!.isAfter(
                                DateTime.now(),
                              );
                          final dueColor = customer.totalDue > 0
                              ? colors.due
                              : colors.clear;
                          final isSelected = _selectedIds.contains(customer.id);

                          return Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(18),
                              onTap: () {
                                if (_selectionMode) {
                                  _toggleSelection(customer.id);
                                  return;
                                }
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => CustomerDetailScreen(
                                      customer: customer,
                                    ),
                                  ),
                                );
                              },
                              onLongPress: _selectionMode
                                  ? null
                                  : () => _enterSelectionMode(customer.id),
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [colors.surface, colors.surfaceAlt],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: isSelected
                                        ? colors.accent
                                        : colors.borderColor,
                                    width: isSelected ? 1.6 : 1,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.2),
                                      blurRadius: 12,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    if (_selectionMode)
                                      Padding(
                                        padding: const EdgeInsets.only(right: 4),
                                        child: Icon(
                                          isSelected
                                              ? Icons.check_circle_rounded
                                              : Icons.radio_button_unchecked_rounded,
                                          color: isSelected
                                              ? colors.accent
                                              : colors.textSecondary,
                                          size: 24,
                                        ),
                                      )
                                    else
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: colors.accent.withValues(alpha: 0.16),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.person_rounded,
                                          color: colors.accent,
                                          size: 24,
                                        ),
                                      ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  customer.name,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.w800,
                                                    fontSize: 15.5,
                                                    color: colors.textPrimary,
                                                  ),
                                                ),
                                              ),
                                              if (hasActiveReminder) ...[
                                                const SizedBox(width: 6),
                                                Icon(
                                                  Icons
                                                      .notifications_active_rounded,
                                                  color: colors.warn,
                                                  size: 17,
                                                ),
                                              ],
                                            ],
                                          ),
                                          const SizedBox(height: 5),
                                          Text(
                                            customer.phone,
                                            style: TextStyle(
                                              fontSize: 12.5,
                                              color: colors.textSecondary,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            l10n.dueDateLabel(_formatDate(customer.lastPaymentDate)),
                                            style: TextStyle(
                                              fontSize: 11.5,
                                              color: colors.hintColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 5,
                                          ),
                                          decoration: BoxDecoration(
                                            color: dueColor.withValues(alpha: 0.14),
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                          child: Text(
                                            customer.totalDue.toStringAsFixed(
                                              2,
                                            ),
                                            style: TextStyle(
                                              color: dueColor,
                                              fontWeight: FontWeight.w800,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        CallButton(
                                          onTap: () => _callCustomer(customer.phone),
                                          colors: colors,
                                          compact: true,
                                        ),
                                      ],
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
}