import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/customer.dart';
import '../models/customer_repository.dart';
import '../models/payment.dart';
import '../theme/app_colors.dart';
import 'customer_detail_screen.dart';
import 'customer_pdf_report_screen.dart';

enum ReportPeriod { daily, weekly, monthly }

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final _repo = CustomerRepository();

  ReportPeriod _period = ReportPeriod.daily; 
  int _offset = 0; 

  bool _loading = true;
  List<Customer> _customers = [];
  List<Payment> _payments = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // ✅ প্রতিটা কাস্টমারের payments subcollection আলাদাভাবে query করা হয় — Firestore
  // rule প্রতিটা read কে ownerId দিয়ে যাচাই করতে পারে বলেই এই approach নিরাপদ।
  // অনফিল্টার্ড collectionGroup('payments') query ব্যবহার করলে rule-level এ
  // filter করা যায় না (Firestore পুরো query-টাই প্রমাণযোগ্য হতে হয়), তাই সেই
  // rule শুধু `request.auth != null` চেক করত — যেকোনো লগইন করা ইউজার সব
  // ইউজারের পেমেন্ট ডেটা ডাউনলোড করতে পারত।
  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final customers = await _repo.fetchCustomersOnce();
      final List<Payment> allPayments = [];

      final snapshots = await Future.wait(
        customers.map(
          (c) => FirebaseFirestore.instance
              .collection('customers')
              .doc(c.id)
              .collection('payments')
              .get(),
        ),
      );

      for (final snapshot in snapshots) {
        for (final doc in snapshot.docs) {
          try {
            final payment = Payment.fromMap({...doc.data(), 'id': doc.id});
            allPayments.add(payment);
          } catch (e) {
            debugPrint("Error parsing payment ID ${doc.id}: $e");
          }
        }
      }

      if (!mounted) return;
      setState(() {
        _customers = customers;
        _payments = allPayments;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load report, please try again')),
      );
    }
  }

  (DateTime, DateTime) _dateRange() {
    final now = DateTime.now();

    if (_period == ReportPeriod.daily) {
      final targetDay = now.add(Duration(days: _offset));
      final start = DateTime(targetDay.year, targetDay.month, targetDay.day, 0, 0, 0);
      final end = DateTime(targetDay.year, targetDay.month, targetDay.day, 23, 59, 59);
      return (start, end);
    } else if (_period == ReportPeriod.weekly) {
      final currentWeekStart = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));
      final start = currentWeekStart.add(Duration(days: 7 * _offset));
      final end = start.add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));
      return (start, end);
    } else {
      final targetMonth = DateTime(now.year, now.month + _offset, 1);
      final start = DateTime(targetMonth.year, targetMonth.month, 1);
      final end = DateTime(targetMonth.year, targetMonth.month + 1, 0, 23, 59, 59);
      return (start, end);
    }
  }

  String _periodLabel() {
    final (start, end) = _dateRange();
    if (_period == ReportPeriod.daily) {
      return DateFormat('d MMMM yyyy').format(start);
    } else if (_period == ReportPeriod.weekly) {
      return "${DateFormat('d MMM').format(start)} - ${DateFormat('d MMM yyyy').format(end)}";
    } else {
      return DateFormat('MMMM yyyy').format(start);
    }
  }

  List<Payment> _paymentsInRange(DateTime start, DateTime end) {
    return _payments
        .where((p) => p.type == PaymentType.payment && !p.date.isBefore(start) && !p.date.isAfter(end))
        .toList();
  }

  List<Map<String, dynamic>> _getCustomerReportData(List<Payment> rangePayments) {
    final List<Map<String, dynamic>> reportRows = [];
    final Map<String, List<Payment>> customerPaymentsMap = {};
    
    for (var p in rangePayments) {
      customerPaymentsMap.putIfAbsent(p.customerId, () => []).add(p);
    }

    customerPaymentsMap.forEach((customerId, pList) {
      final customer = _customers.firstWhere(
        (c) => c.id == customerId,
        orElse: () => Customer(
          id: customerId, 
          name: 'Unknown', 
          phone: '', 
          totalDue: 0.0, 
          lastPaymentDate: DateTime.now(), 
          createdAt: DateTime.now(), 
          ownerId: ''
        ),
      );

      final totalPaidInPeriod = pList.fold<double>(0, (sum, p) => sum + p.amount);
      final totalDue = customer.totalDue + totalPaidInPeriod; 
      final remaining = customer.totalDue;

      reportRows.add({
        'name': customer.name,
        'phone': customer.phone,
        'totalDue': totalDue,
        'paid': totalPaidInPeriod,
        'remaining': remaining,
      });
    });

    return reportRows;
  }

  // ✅ গত ৬ মাসের (চলতি মাসসহ) মাসিক কালেকশন — Dashboard trend chart এর ডেটা
  List<(DateTime month, double total)> _monthlyTrend() {
    final now = DateTime.now();
    return List.generate(6, (i) {
      final month = DateTime(now.year, now.month - (5 - i), 1);
      final total = _payments
          .where((p) =>
              p.type == PaymentType.payment &&
              p.date.year == month.year &&
              p.date.month == month.month)
          .fold<double>(0, (runningTotal, p) => runningTotal + p.amount);
      return (month, total);
    });
  }

  // ✅ সবচেয়ে বেশি বকেয়া থাকা কাস্টমাররা — Dashboard "Top Defaulters" এর ডেটা
  List<Customer> _topDefaulters() {
    final withDue = _customers.where((c) => c.totalDue > 0).toList()
      ..sort((a, b) => b.totalDue.compareTo(a.totalDue));
    return withDue.take(5).toList();
  }

  Future<void> _exportPdf() async {
    final (start, end) = _dateRange();
    final rangePayments = _paymentsInRange(start, end);
    final reportData = _getCustomerReportData(rangePayments);
    final totalCollection = rangePayments.fold<double>(0, (sum, p) => sum + p.amount);

    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        build: (context) => [
          pw.Text('Collection Report (${_period.name.toUpperCase()})', style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
          pw.Text('Period: ${_periodLabel()}', style: pw.TextStyle(fontSize: 14)),
          pw.SizedBox(height: 15),
          pw.Text('Total Collection: ${totalCollection.toStringAsFixed(2)} TK', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 20),
          pw.Text('Customer Statement Table:', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          if (reportData.isEmpty)
            pw.Text('No payments received in this period.')
          else
            pw.TableHelper.fromTextArray(
              headers: const ['Customer', 'Total Due', 'Payment', 'Remaining'],
              data: reportData.map((row) {
                return [
                  "${row['name']} (${row['phone']})",
                  row['totalDue'].toStringAsFixed(0),
                  row['paid'].toStringAsFixed(0),
                  row['remaining'].toStringAsFixed(0),
                ];
              }).toList(),
            ),
        ],
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Scaffold(
      backgroundColor: colors.scaffoldBg,
      appBar: AppBar(
        title: Text(
          "Collection Reports",
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: colors.textPrimary),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: colors.textPrimary),
        actions: [
          // কাস্টম পিডিএফ স্ক্রিন বাটন
          IconButton(
            icon: Icon(Icons.picture_as_pdf_rounded, color: colors.textPrimary),
            tooltip: "Customer PDF Report",
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CustomerPdfReportScreen()),
              );
            },
          ),
          // ডাইরেক্ট এক্সপোর্ট পিডিএফ বাটন
          IconButton(
            icon: Icon(Icons.download_rounded, color: colors.textPrimary),
            tooltip: "Download PDF",
            onPressed: _loading ? null : _exportPdf,
          ),
        ],
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: colors.accent))
          : RefreshIndicator(
              onRefresh: _loadData,
              color: colors.accent,
              child: _buildContent(colors),
            ),
    );
  }

  Widget _buildContent(AppColors colors) {
    final (start, end) = _dateRange();
    final rangePayments = _paymentsInRange(start, end);
    final reportData = _getCustomerReportData(rangePayments);
    final totalCollection = rangePayments.fold<double>(0, (sum, p) => sum + p.amount);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          "Dashboard",
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: colors.textPrimary),
        ),
        const SizedBox(height: 12),
        _MonthlyTrendCard(trend: _monthlyTrend(), colors: colors),
        const SizedBox(height: 14),
        _TopDefaultersCard(
          defaulters: _topDefaulters(),
          colors: colors,
          onTapCustomer: (customer) {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => CustomerDetailScreen(customer: customer)),
            );
          },
        ),

        const SizedBox(height: 28),
        Divider(color: colors.borderColor),
        const SizedBox(height: 12),

        SegmentedButton<ReportPeriod>(
          style: SegmentedButton.styleFrom(
            backgroundColor: colors.surface,
            foregroundColor: colors.textSecondary,
            selectedBackgroundColor: colors.accent,
            selectedForegroundColor: Colors.white,
            side: BorderSide(color: colors.borderColor),
          ),
          segments: const [
            ButtonSegment(value: ReportPeriod.daily, label: Text("Daily"), icon: Icon(Icons.today)),
            ButtonSegment(value: ReportPeriod.weekly, label: Text("Weekly"), icon: Icon(Icons.view_week)),
            ButtonSegment(value: ReportPeriod.monthly, label: Text("Monthly"), icon: Icon(Icons.calendar_view_month)),
          ],
          selected: {_period},
          onSelectionChanged: (selection) {
            setState(() {
              _period = selection.first;
              _offset = 0;
            });
          },
        ),

        const SizedBox(height: 16),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: Icon(Icons.chevron_left, color: colors.textPrimary),
              onPressed: () => setState(() => _offset -= 1),
            ),
            Text(
              _periodLabel(),
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: colors.textPrimary),
            ),
            IconButton(
              icon: Icon(Icons.chevron_right, color: colors.textPrimary),
              onPressed: _offset >= 0 ? null : () => setState(() => _offset += 1),
            ),
          ],
        ),

        const SizedBox(height: 20),

        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [colors.clear.withValues(alpha: 0.16), colors.clear.withValues(alpha: 0.06)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colors.clear.withValues(alpha: 0.3)),
          ),
          child: Column(
            children: [
              Text("Total Collection", style: TextStyle(fontSize: 14, color: colors.textSecondary)),
              const SizedBox(height: 6),
              Text(
                "${totalCollection.toStringAsFixed(0)} TK",
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: colors.clear),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        Text(
          "Customer Payment Details",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: colors.textPrimary),
        ),
        const SizedBox(height: 12),

        if (reportData.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Center(
              child: Text(
                "No transactions found for this period.",
                style: TextStyle(color: colors.textSecondary),
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: reportData.length,
            separatorBuilder: (context, index) => Divider(color: colors.borderColor),
            itemBuilder: (context, index) {
              final row = reportData[index];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                key: ValueKey(row['phone']),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      row['name'],
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: colors.textPrimary),
                    ),
                    Text(row['phone'], style: TextStyle(color: colors.textSecondary, fontSize: 12)),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _AmountInfo(label: "Total Due", amount: row['totalDue'], color: colors.warn, textColor: colors.textSecondary),
                        _AmountInfo(label: "Payment", amount: row['paid'], color: colors.clear, textColor: colors.textSecondary),
                        _AmountInfo(label: "Remaining", amount: row['remaining'], color: colors.due, textColor: colors.textSecondary),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        const SizedBox(height: 100),
      ],
    );
  }
}

class _AmountInfo extends StatelessWidget {
  const _AmountInfo({
    required this.label,
    required this.amount,
    required this.color,
    required this.textColor,
  });
  final String label;
  final double amount;
  final Color color;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 11, color: textColor)),
        const SizedBox(height: 2),
        Text(
          "${amount.toStringAsFixed(0)} TK",
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }
}

// ✅ Y-axis এর জন্য "গোলগাল" সর্বোচ্চ মান বের করা (যেমন 4,300 হলে 5,000 দেখাবে)
// — এতে gridline গুলো পড়ার মতো ক্লিন সংখ্যায় থাকে
double _niceAxisMax(double rawMax) {
  if (rawMax <= 0) return 100;

  final magnitude = math.pow(10, (math.log(rawMax) / math.ln10).floor()).toDouble();
  final normalized = rawMax / magnitude;

  double niceNormalized;
  if (normalized <= 1) {
    niceNormalized = 1;
  } else if (normalized <= 2) {
    niceNormalized = 2;
  } else if (normalized <= 5) {
    niceNormalized = 5;
  } else {
    niceNormalized = 10;
  }

  return niceNormalized * magnitude;
}

class _MonthlyTrendCard extends StatelessWidget {
  const _MonthlyTrendCard({required this.trend, required this.colors});

  final List<(DateTime month, double total)> trend;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    final currencyFmt = NumberFormat('#,##0');
    final hasData = trend.any((entry) => entry.$2 > 0);
    final rawMax = trend.fold<double>(0, (m, e) => e.$2 > m ? e.$2 : m);
    final axisMax = _niceAxisMax(rawMax * 1.2);
    final latest = trend.last;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colors.surface, colors.surfaceAlt],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Monthly Collection Trend",
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5, color: colors.textPrimary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "Last 6 months",
                      style: TextStyle(fontSize: 11.5, color: colors.textSecondary),
                    ),
                  ],
                ),
              ),
              if (hasData)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      DateFormat('MMM').format(latest.$1),
                      style: TextStyle(fontSize: 11, color: colors.textSecondary, fontWeight: FontWeight.w600),
                    ),
                    Text(
                      "${currencyFmt.format(latest.$2)} TK",
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: colors.clear),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (!hasData)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 30),
              child: Center(
                child: Text(
                  "এই সময়ে কোনো পেমেন্ট রেকর্ড নেই",
                  style: TextStyle(color: colors.textSecondary, fontSize: 12.5),
                ),
              ),
            )
          else
            SizedBox(
              height: 180,
              child: BarChart(
                BarChartData(
                  maxY: axisMax,
                  minY: 0,
                  alignment: BarChartAlignment.spaceAround,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: axisMax / 4,
                    getDrawingHorizontalLine: (_) => FlLine(
                      color: colors.borderColor,
                      strokeWidth: 1,
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    show: true,
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        interval: axisMax / 4,
                        getTitlesWidget: (value, meta) => Text(
                          currencyFmt.format(value),
                          style: TextStyle(fontSize: 9.5, color: colors.hintColor),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 24,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < 0 || index >= trend.length) return const SizedBox.shrink();
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              DateFormat('MMM').format(trend[index].$1),
                              style: TextStyle(fontSize: 10.5, color: colors.textSecondary, fontWeight: FontWeight.w600),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (_) => colors.surfaceAlt,
                      tooltipBorder: BorderSide(color: colors.borderColor),
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final month = trend[group.x.toInt()].$1;
                        return BarTooltipItem(
                          "${DateFormat('MMM yyyy').format(month)}\n",
                          TextStyle(color: colors.textSecondary, fontWeight: FontWeight.w600, fontSize: 11),
                          children: [
                            TextSpan(
                              text: "${currencyFmt.format(rod.toY)} TK",
                              style: TextStyle(color: colors.clear, fontWeight: FontWeight.w800, fontSize: 12.5),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  barGroups: [
                    for (int i = 0; i < trend.length; i++)
                      BarChartGroupData(
                        x: i,
                        barRods: [
                          BarChartRodData(
                            toY: trend[i].$2,
                            color: colors.clear,
                            width: 18,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(4),
                              topRight: Radius.circular(4),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _TopDefaultersCard extends StatelessWidget {
  const _TopDefaultersCard({
    required this.defaulters,
    required this.colors,
    required this.onTapCustomer,
  });

  final List<Customer> defaulters;
  final AppColors colors;
  final ValueChanged<Customer> onTapCustomer;

  @override
  Widget build(BuildContext context) {
    final currencyFmt = NumberFormat('#,##0');
    final maxDue = defaulters.isEmpty
        ? 0.0
        : defaulters.fold<double>(0, (m, c) => c.totalDue > m ? c.totalDue : m);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colors.surface, colors.surfaceAlt],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Top Defaulters",
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5, color: colors.textPrimary),
          ),
          const SizedBox(height: 2),
          Text(
            "সবচেয়ে বেশি বকেয়া থাকা কাস্টমার",
            style: TextStyle(fontSize: 11.5, color: colors.textSecondary),
          ),
          const SizedBox(height: 16),
          if (defaulters.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  "🎉 কোনো বকেয়া নেই, সব কাস্টমার ক্লিয়ার",
                  style: TextStyle(color: colors.clear, fontSize: 12.5, fontWeight: FontWeight.w700),
                ),
              ),
            )
          else
            for (int i = 0; i < defaulters.length; i++) ...[
              _DefaulterRow(
                rank: i + 1,
                customer: defaulters[i],
                fraction: maxDue == 0 ? 0 : defaulters[i].totalDue / maxDue,
                currencyFmt: currencyFmt,
                colors: colors,
                onTap: () => onTapCustomer(defaulters[i]),
              ),
              if (i != defaulters.length - 1) const SizedBox(height: 12),
            ],
        ],
      ),
    );
  }
}

class _DefaulterRow extends StatelessWidget {
  const _DefaulterRow({
    required this.rank,
    required this.customer,
    required this.fraction,
    required this.currencyFmt,
    required this.colors,
    required this.onTap,
  });

  final int rank;
  final Customer customer;
  final double fraction;
  final NumberFormat currencyFmt;
  final AppColors colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    "#$rank",
                    style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: colors.hintColor),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      customer.name,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: colors.textPrimary),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "${currencyFmt.format(customer.totalDue)} TK",
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: colors.due),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return Stack(
                      children: [
                        Container(
                          height: 8,
                          width: double.infinity,
                          color: colors.due.withValues(alpha: 0.14),
                        ),
                        Container(
                          height: 8,
                          width: constraints.maxWidth * fraction.clamp(0.0, 1.0),
                          color: colors.due,
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}