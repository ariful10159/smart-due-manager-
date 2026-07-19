import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';

import '../models/customer.dart';
import '../models/customer_repository.dart';
import '../theme/app_colors.dart';
import '../widgets/custom_bottom_nav_bar.dart';
import 'archived_customers_screen.dart';
import 'customer_detail_screen.dart';

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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _callCustomer(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
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

    if (hasReminderSet) options.add("Reminder Set");
    if (hasNoReminder) options.add("No Reminder");

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

  String _sortLabel(CustomerSortOption option) {
    switch (option) {
      case CustomerSortOption.dueHighToLow:
        return "Due: High to Low";
      case CustomerSortOption.dueLowToHigh:
        return "Due: Low to High";
      case CustomerSortOption.nameAZ:
        return "Name: A to Z";
      case CustomerSortOption.nameZA:
        return "Name: Z to A";
      case CustomerSortOption.recentlyAdded:
        return "Recently Added";
      case CustomerSortOption.none:
        return "Default";
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

    return Scaffold(
      backgroundColor: colors.scaffoldBg,
      appBar: AppBar(
        title: Text(
          "All Customers",
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
            tooltip: "Sort",
            color: colors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(color: colors.borderColor),
            ),
            onSelected: (value) {
              setState(() => _sortOption = value);
            },
            itemBuilder: (context) => CustomerSortOption.values.map((option) {
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
                      _sortLabel(option),
                      style: TextStyle(
                        color: isSelected ? colors.accent : colors.textPrimary,
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
            icon: Icon(Icons.archive_outlined, color: colors.textPrimary),
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
            return Center(
              child: CircularProgressIndicator(color: colors.accent),
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

          return Column(
            children: [
              // ✅ SEARCH BOX
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: TextField(
                  controller: _searchController,
                  style: TextStyle(color: colors.textPrimary, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: "নাম বা ফোন নাম্বার দিয়ে খুঁজুন...",
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
                            value: availableYears.contains(_selectedYear)
                                ? _selectedYear
                                : null,
                            hint: Text(
                              "Year",
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
                            value: availableMonths.contains(_selectedMonth)
                                ? _selectedMonth
                                : null,
                            hint: Text(
                              "Month",
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
                            value:
                                availableReminderOptions.contains(
                                  _reminderFilter,
                                )
                                ? _reminderFilter
                                : null,
                            hint: Text(
                              "Reminder",
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
                          label: const Text(
                            "Clear All Filters",
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
                            "${result.length} customer(s) found",
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: colors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        "Total Due: ${totalDueInView.toStringAsFixed(2)}",
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
                                  ? "'$_searchQuery' এর সাথে মিলে এমন কেউ নেই"
                                  : "No customers found",
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

                          return Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(18),
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => CustomerDetailScreen(
                                      customer: customer,
                                    ),
                                  ),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [colors.surface, colors.surfaceAlt],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(color: colors.borderColor),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 12,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: colors.accent.withOpacity(0.16),
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
                                            "Due date: ${_formatDate(customer.lastPaymentDate)}",
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
                                            color: dueColor.withOpacity(0.14),
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
                                        InkWell(
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                          onTap: () =>
                                              _callCustomer(customer.phone),
                                          child: Container(
                                            padding: const EdgeInsets.all(7),
                                            decoration: BoxDecoration(
                                              color: colors.clear.withOpacity(0.14),
                                              shape: BoxShape.circle,
                                            ),
                                            child: Icon(
                                              Icons.call_rounded,
                                              color: colors.clear,
                                              size: 17,
                                            ),
                                          ),
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
          );
        },
      ),

      bottomNavigationBar: CustomBottomNavBar(
        selectedIndex: _selectedIndex,
      ),
    );
  }
}