import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; 
import '../models/customer.dart';
import '../models/customer_repository.dart';
import '../models/payment.dart';
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

  // ✅ লুপ বর্জন করে collectionGroup এর মাধ্যমে সুপার-ফাস্ট ডাটা লোডিং লজিক
  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      // ১. প্যারালালি কাস্টমার লিস্ট লোড করা
      final customers = await _repo.fetchCustomersOnce();
      
      // কাস্টমার আইডিগুলো একটা সেট-এ রাখা যেন সহজে ফিল্টার করা যায়
      final myCustomerIds = customers.map((c) => c.id).toSet();
      final List<Payment> allPayments = [];

      // ২. ⚡ collectionGroup ব্যবহার করে এক ক্লিকে সব কাস্টমারের পেমেন্ট একসাথে আনা
      final snapshot = await FirebaseFirestore.instance
          .collectionGroup('payments')
          .get();

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final cId = data['customerId']?.toString() ?? '';
        
        // শুধু বর্তমান ইউজারের আওতাভুক্ত কাস্টমারদের পেমেন্টগুলোই ফিল্টার করে নেওয়া
        if (myCustomerIds.contains(cId)) {
          try {
            final payment = Payment.fromMap({...data, 'id': doc.id});
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
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load report: $e')),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text("Collection Reports"),
        centerTitle: true,
        actions: [
          // কাস্টম পিডিএফ স্ক্রিন বাটন
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_rounded),
            tooltip: "Customer PDF Report",
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CustomerPdfReportScreen()),
              );
            },
          ),
          // ডাইরেক্ট এক্সপোর্ট পিডিএফ বাটন
          IconButton(
            icon: const Icon(Icons.download_rounded),
            tooltip: "Download PDF",
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
    final reportData = _getCustomerReportData(rangePayments);
    final totalCollection = rangePayments.fold<double>(0, (sum, p) => sum + p.amount);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SegmentedButton<ReportPeriod>(
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
              icon: const Icon(Icons.chevron_left),
              onPressed: () => setState(() => _offset -= 1),
            ),
            Text(
              _periodLabel(),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: _offset >= 0 ? null : () => setState(() => _offset += 1),
            ),
          ],
        ),

        const SizedBox(height: 20),

        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.green.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              const Text("Total Collection", style: TextStyle(fontSize: 14, color: Colors.grey)),
              const SizedBox(height: 6),
              Text(
                "${totalCollection.toStringAsFixed(0)} TK",
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.green),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        const Text(
          "Customer Payment Details",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 12),

        if (reportData.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Center(child: Text("No transactions found for this period.", style: TextStyle(color: Colors.grey))),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: reportData.length,
            separatorBuilder: (context, index) => const Divider(),
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
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Text(row['phone'], style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _AmountInfo(label: "Total Due", amount: row['totalDue'], color: Colors.orange),
                        _AmountInfo(label: "Payment", amount: row['paid'], color: Colors.green),
                        _AmountInfo(label: "Remaining", amount: row['remaining'], color: Colors.red),
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
  const _AmountInfo({required this.label, required this.amount, required this.color});
  final String label;
  final double amount;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        const SizedBox(height: 2),
        Text(
          "${amount.toStringAsFixed(0)} TK",
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }
}