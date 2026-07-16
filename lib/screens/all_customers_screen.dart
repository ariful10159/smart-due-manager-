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

  int _selectedIndex = 2;

  int? _selectedYear;
  int? _selectedMonth;
  String? _reminderFilter;
  String _searchQuery = '';
  CustomerSortOption _sortOption = CustomerSortOption.none;

  // 🎨 Dark navy palette — matches the rest of the app
  static const Color _scaffoldBg = Color(0xFF0F0F14);
  static const Color _surface = Color(0xFF1B1B24);
  static const Color _surfaceAlt = Color(0xFF20202B);
  static const Color _borderColor = Color(0xFF2C2C3A);
  static const Color _textPrimary = Colors.white;
  static const Color _textSecondary = Color(0xFF9A9AAE);
  static const Color _hintColor = Color(0xFF5C5C6E);
  static const Color _accent = Color(0xFF6366F1); // Indigo accent
  static const Color _due = Color(0xFFEF4444);
  static const Color _clear = Color(0xFF10B981);

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

  InputDecoration _dropdownDecoration({Widget? suffixIcon}) {
    return InputDecoration(
      suffixIcon: suffixIcon,
      suffixIconConstraints: const BoxConstraints(
        // 👈 add this
        minWidth: 28,
        minHeight: 28,
      ),
      filled: true,
      fillColor: _surface,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 12,
      ), // slightly tighter
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _accent, width: 1.4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _scaffoldBg,
      appBar: AppBar(
        title: const Text(
          "All Customers",
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 20,
            letterSpacing: 0.3,
            color: _textPrimary,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: _textPrimary),
        actions: [
          // ✅ Sort menu
          PopupMenuButton<CustomerSortOption>(
            icon: const Icon(Icons.sort_rounded, color: _textPrimary),
            tooltip: "Sort",
            color: _surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: const BorderSide(color: _borderColor),
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
                      const Icon(Icons.check, size: 18, color: _accent)
                    else
                      const SizedBox(width: 18),
                    const SizedBox(width: 8),
                    Text(
                      _sortLabel(option),
                      style: TextStyle(
                        color: isSelected ? _accent : _textPrimary,
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
            icon: const Icon(Icons.archive_outlined, color: _textPrimary),
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
            return const Center(
              child: CircularProgressIndicator(color: _accent),
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
                  style: const TextStyle(color: _textPrimary, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: "নাম বা ফোন নাম্বার দিয়ে খুঁজুন...",
                    hintStyle: const TextStyle(
                      color: _hintColor,
                      fontSize: 13.5,
                    ),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: _textSecondary,
                    ),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(
                              Icons.clear_rounded,
                              color: _textSecondary,
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
                    fillColor: _surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: _borderColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: _borderColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: _accent, width: 1.4),
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
                            hint: const Text(
                              "Year",
                              style: TextStyle(color: _hintColor, fontSize: 13),
                            ),
                            dropdownColor: _surface,
                            style: const TextStyle(
                              color: _textPrimary,
                              fontSize: 13,
                            ),
                            icon: const Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: _textSecondary,
                            ),
                            decoration: _dropdownDecoration(
                              suffixIcon: _selectedYear != null
                                  ? IconButton(
                                      icon: const Icon(
                                        Icons.clear,
                                        size: 16,
                                        color: _textSecondary,
                                      ),
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
                            hint: const Text(
                              "Month",
                              style: TextStyle(color: _hintColor, fontSize: 13),
                            ),
                            dropdownColor: _surface,
                            style: const TextStyle(
                              color: _textPrimary,
                              fontSize: 13,
                            ),
                            icon: const Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: _textSecondary,
                            ),
                            decoration: _dropdownDecoration(
                              suffixIcon: _selectedYear != null
                                  ? IconButton(
                                      icon: const Icon(
                                        Icons.clear,
                                        size: 16,
                                        color: _textSecondary,
                                      ),
                                      padding: EdgeInsets
                                          .zero, // 👈 remove default padding
                                      constraints:
                                          const BoxConstraints(), // 👈 remove 48x48 min size
                                      visualDensity: VisualDensity
                                          .compact, // 👈 extra safety
                                      onPressed: () {
                                        setState(() => _selectedYear = null);
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
                            hint: const Text(
                              "Reminder",
                              style: TextStyle(color: _hintColor, fontSize: 13),
                            ),
                            dropdownColor: _surface,
                            style: const TextStyle(
                              color: _textPrimary,
                              fontSize: 13,
                            ),
                            icon: const Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: _textSecondary,
                            ),
                            decoration: _dropdownDecoration(
                              suffixIcon: _reminderFilter != null
                                  ? IconButton(
                                      icon: const Icon(
                                        Icons.clear,
                                        size: 16,
                                        color: _textSecondary,
                                      ),
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
                          style: TextButton.styleFrom(foregroundColor: _due),
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
                    gradient: const LinearGradient(
                      colors: [_surface, _surfaceAlt],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _borderColor),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.groups_rounded,
                            size: 16,
                            color: _textSecondary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            "${result.length} customer(s) found",
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: _textSecondary,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        "Total Due: ${totalDueInView.toStringAsFixed(2)}",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: totalDueInView > 0 ? _due : _clear,
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
                                color: _surface,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                _searchQuery.isNotEmpty
                                    ? Icons.search_off_rounded
                                    : Icons.people_outline_rounded,
                                size: 40,
                                color: _textSecondary,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              _searchQuery.isNotEmpty
                                  ? "'$_searchQuery' এর সাথে মিলে এমন কেউ নেই"
                                  : "No customers found",
                              style: const TextStyle(
                                color: _textSecondary,
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
                              ? _due
                              : _clear;

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
                                  gradient: const LinearGradient(
                                    colors: [_surface, _surfaceAlt],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(color: _borderColor),
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
                                        color: _accent.withOpacity(0.16),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.person_rounded,
                                        color: _accent,
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
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w800,
                                                    fontSize: 15.5,
                                                    color: _textPrimary,
                                                  ),
                                                ),
                                              ),
                                              if (hasActiveReminder) ...[
                                                const SizedBox(width: 6),
                                                const Icon(
                                                  Icons
                                                      .notifications_active_rounded,
                                                  color: Color(0xFFF59E0B),
                                                  size: 17,
                                                ),
                                              ],
                                            ],
                                          ),
                                          const SizedBox(height: 5),
                                          Text(
                                            customer.phone,
                                            style: const TextStyle(
                                              fontSize: 12.5,
                                              color: _textSecondary,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            "Due date: ${_formatDate(customer.lastPaymentDate)}",
                                            style: const TextStyle(
                                              fontSize: 11.5,
                                              color: _hintColor,
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
                                              color: _clear.withOpacity(0.14),
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.call_rounded,
                                              color: _clear,
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

      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: _surface,
          border: const Border(top: BorderSide(color: _borderColor)),
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
