import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/customer.dart';
import '../models/customer_repository.dart';
import '../models/payment.dart';

enum ReportPeriod { weekly, monthly }

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final _repo = CustomerRepository();

  ReportPeriod _period = ReportPeriod.weekly;
  int _offset = 0; // 0 = current period, -1 = আগের period, ইত্যাদি

  bool _loading = true;
  List<Customer> _customers = [];
  List<Payment> _payments = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final customers = await _repo.fetchCustomersOnce();
      final payments = await _repo.fetchAllPaymentsOnce();
      if (!mounted) return;
      setState(() {
        _customers = customers;
        _payments = payments;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load report: $e')),
      );
    }
  }

  // ✅ বর্তমান period এর start/end date বের করা
  (DateTime, DateTime) _dateRange() {
    final now = DateTime.now();

    if (_period == ReportPeriod.weekly) {
      final currentWeekStart = DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(Duration(days: now.weekday - 1));
      final start = currentWeekStart.add(Duration(days: 7 * _offset));
      final end = start.add(const Duration(days: 6));
      return (start, DateTime(end.year, end.month, end.day, 23, 59, 59));
    } else {
      final targetMonth = DateTime(now.year, now.month + _offset, 1);
      final start = DateTime(targetMonth.year, targetMonth.month, 1);
      final end = DateTime(targetMonth.year, targetMonth.month + 1, 0, 23, 59, 59);
      return (start, end);
    }
  }

  String _periodLabel() {
    final (start, end) = _dateRange();
    if (_period == ReportPeriod.weekly) {
      return "${DateFormat('d MMM').format(start)} - ${DateFormat('d MMM yyyy').format(end)}";
    } else {
      return DateFormat('MMMM yyyy').format(start);
    }
  }

  List<Payment> _paymentsInRange(DateTime start, DateTime end) {
    return _payments
        .where((p) => !p.date.isBefore(start) && !p.date.isAfter(end))
        .toList();
  }

  List<Customer> _newCustomersInRange(DateTime start, DateTime end) {
    return _customers
        .where((c) => !c.createdAt.isBefore(start) && !c.createdAt.isAfter(end))
        .toList();
  }

  // ✅ Bar chart এর জন্য দিন-ভিত্তিক নেট collection হিসাব
  List<MapEntry<String, double>> _dailyBreakdown(DateTime start, DateTime end) {
    final dayCount = end.difference(start).inDays + 1;
    final result = <MapEntry<String, double>>[];

    for (int i = 0; i < dayCount; i++) {
      final day = DateTime(start.year, start.month, start.day + i);
      final dayEnd = DateTime(day.year, day.month, day.day, 23, 59, 59);

      final dayPayments = _payments.where(
        (p) => !p.date.isBefore(day) && !p.date.isAfter(dayEnd),
      );

      final collection = dayPayments
          .where((p) => p.type == PaymentType.payment)
          .fold<double>(0, (sum, p) => sum + p.amount);
      final charges = dayPayments
          .where((p) => p.type == PaymentType.dueAdded)
          .fold<double>(0, (sum, p) => sum + p.amount);

      final label = _period == ReportPeriod.weekly
          ? DateFormat('E').format(day) // Mon, Tue...
          : day.day.toString();

      result.add(MapEntry(label, collection - charges));
    }

    return result;
  }

  Future<void> _exportPdf() async {
    final (start, end) = _dateRange();
    final rangePayments = _paymentsInRange(start, end);
    final newCustomers = _newCustomersInRange(start, end);

    final collection = rangePayments
        .where((p) => p.type == PaymentType.payment)
        .fold<double>(0, (sum, p) => sum + p.amount);
    final charges = rangePayments
        .where((p) => p.type == PaymentType.dueAdded)
        .fold<double>(0, (sum, p) => sum + p.amount);
    final net = collection - charges;

    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        build: (context) => [
          pw.Text(
            'Business Report',
            style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
          ),
          pw.Text(_periodLabel()),
          pw.SizedBox(height: 20),
          pw.Text(
            'Summary',
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          pw.Bullet(text: 'Total Collection: ${collection.toStringAsFixed(2)}'),
          pw.Bullet(text: 'Total Charges Added: ${charges.toStringAsFixed(2)}'),
          pw.Bullet(text: 'Net: ${net.toStringAsFixed(2)}'),
          pw.Bullet(text: 'New Customers: ${newCustomers.length}'),
          pw.Bullet(text: 'Total Transactions: ${rangePayments.length}'),
          pw.SizedBox(height: 20),
          pw.Text(
            'Transaction Details',
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          if (rangePayments.isEmpty)
            pw.Text('No transactions in this period')
          else
            pw.TableHelper.fromTextArray(
              headers: const ['Date', 'Type', 'Amount'],
              data: rangePayments.map((p) {
                return [
                  DateFormat('d MMM, hh:mm a').format(p.date),
                  p.type == PaymentType.payment ? 'Collection' : 'Charge',
                  p.amount.toStringAsFixed(2),
                ];
              }).toList(),
            ),
          if (newCustomers.isNotEmpty) ...[
            pw.SizedBox(height: 20),
            pw.Text(
              'New Customers',
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 8),
            pw.TableHelper.fromTextArray(
              headers: const ['Name', 'Phone', 'Joined'],
              data: newCustomers.map((c) {
                return [
                  c.name,
                  c.phone,
                  DateFormat('d MMM yyyy').format(c.createdAt),
                ];
              }).toList(),
            ),
          ],
        ],
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Reports"),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: "Export PDF",
            onPressed: _loading ? null : _exportPdf,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: _buildContent(),
            ),
    );
  }

  Widget _buildContent() {
    final (start, end) = _dateRange();
    final rangePayments = _paymentsInRange(start, end);
    final newCustomers = _newCustomersInRange(start, end);

    final collection = rangePayments
        .where((p) => p.type == PaymentType.payment)
        .fold<double>(0, (sum, p) => sum + p.amount);
    final charges = rangePayments
        .where((p) => p.type == PaymentType.dueAdded)
        .fold<double>(0, (sum, p) => sum + p.amount);
    final net = collection - charges;

    final dailyData = _dailyBreakdown(start, end);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ✅ Weekly/Monthly Toggle
        SegmentedButton<ReportPeriod>(
          segments: const [
            ButtonSegment(
              value: ReportPeriod.weekly,
              label: Text("Weekly"),
              icon: Icon(Icons.view_week),
            ),
            ButtonSegment(
              value: ReportPeriod.monthly,
              label: Text("Monthly"),
              icon: Icon(Icons.calendar_view_month),
            ),
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

        // ✅ Period Navigation
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: () => setState(() => _offset -= 1),
            ),
            Text(
              _periodLabel(),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: _offset >= 0
                  ? null
                  : () => setState(() => _offset += 1),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // ✅ Summary Cards
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.6,
          children: [
            _SummaryCard(
              icon: Icons.arrow_downward,
              label: "Collection",
              value: collection.toStringAsFixed(0),
              color: Colors.green,
            ),
            _SummaryCard(
              icon: Icons.arrow_upward,
              label: "Charges Added",
              value: charges.toStringAsFixed(0),
              color: Colors.red,
            ),
            _SummaryCard(
              icon: Icons.account_balance,
              label: "Net",
              value: net.toStringAsFixed(0),
              color: net >= 0 ? Colors.blue : Colors.orange,
            ),
            _SummaryCard(
              icon: Icons.person_add,
              label: "New Customers",
              value: newCustomers.length.toString(),
              color: Colors.teal,
            ),
          ],
        ),

        const SizedBox(height: 24),

        // ✅ Bar Chart
        const Text(
          "Daily Net Collection",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        const SizedBox(height: 12),
        _BarChart(data: dailyData),

        const SizedBox(height: 24),

        // ✅ Transaction count summary line
        Text(
          "${rangePayments.length} transaction(s) in this period",
          style: const TextStyle(color: Colors.grey),
        ),

        const SizedBox(height: 80),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
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
          Icon(icon, color: color, size: 22),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        ],
      ),
    );
  }
}

// ✅ কোনো external chart package ছাড়াই বানানো সাধারণ Bar Chart
class _BarChart extends StatelessWidget {
  const _BarChart({required this.data});

  final List<MapEntry<String, double>> data;

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const SizedBox(
        height: 150,
        child: Center(child: Text("No data")),
      );
    }

    final maxAbsValue = data
        .map((e) => e.value.abs())
        .fold<double>(1, (max, v) => v > max ? v : max);

    return SizedBox(
      height: 180,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: data.map((entry) {
          final isPositive = entry.value >= 0;
          final barHeight = (entry.value.abs() / maxAbsValue) * 120;

          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    entry.value == 0 ? '' : entry.value.toStringAsFixed(0),
                    style: const TextStyle(fontSize: 9, color: Colors.grey),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    height: barHeight < 4 ? 4 : barHeight,
                    decoration: BoxDecoration(
                      color: isPositive ? Colors.green : Colors.red,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    entry.key,
                    style: const TextStyle(fontSize: 10),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}