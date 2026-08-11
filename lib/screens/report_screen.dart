import 'dart:math' as math;
import 'dart:typed_data';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../l10n/app_localizations.dart';
import '../models/customer.dart';
import '../models/customer_repository.dart';
import '../models/legal_content.dart';
import '../models/payment.dart';
import '../theme/app_colors.dart';
import '../utils/html_escape.dart';
import '../widgets/app_settings_scope.dart';
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
        SnackBar(
          content: Text(AppLocalizations.of(context)!.failedToLoadReport),
        ),
      );
    }
  }

  (DateTime, DateTime) _dateRange() {
    final now = DateTime.now();

    if (_period == ReportPeriod.daily) {
      final targetDay = now.add(Duration(days: _offset));
      final start = DateTime(
        targetDay.year,
        targetDay.month,
        targetDay.day,
        0,
        0,
        0,
      );
      final end = DateTime(
        targetDay.year,
        targetDay.month,
        targetDay.day,
        23,
        59,
        59,
      );
      return (start, end);
    } else if (_period == ReportPeriod.weekly) {
      final currentWeekStart = DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(Duration(days: now.weekday - 1));
      final start = currentWeekStart.add(Duration(days: 7 * _offset));
      final end = start.add(
        const Duration(days: 6, hours: 23, minutes: 59, seconds: 59),
      );
      return (start, end);
    } else {
      final targetMonth = DateTime(now.year, now.month + _offset, 1);
      final start = DateTime(targetMonth.year, targetMonth.month, 1);
      final end = DateTime(
        targetMonth.year,
        targetMonth.month + 1,
        0,
        23,
        59,
        59,
      );
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
        .where(
          (p) =>
              p.type == PaymentType.payment &&
              !p.date.isBefore(start) &&
              !p.date.isAfter(end),
        )
        .toList();
  }

  // ✅ Cash (Hand Cash + অনির্দিষ্ট) বনাম bKash বনাম বাকি মেথড (Nagad/Bank) — এই
  // ব্রেকডাউনটাই কালেকশন রিপোর্টের মূল অংশ, দোকানদার কোন মাধ্যমে কত টাকা পেলো তা জানতে চায়
  Map<String, double> _methodTotals(List<Payment> payments) {
    double cash = 0, bkash = 0, other = 0;
    for (final p in payments) {
      switch (p.paymentMethod) {
        case PaymentMethod.bKash:
          bkash += p.amount;
          break;
        case PaymentMethod.nagad:
        case PaymentMethod.bank:
          other += p.amount;
          break;
        case PaymentMethod.handCash:
        case null:
          cash += p.amount;
          break;
      }
    }
    return {'cash': cash, 'bkash': bkash, 'other': other};
  }

  List<Map<String, dynamic>> _getCustomerReportData(
    List<Payment> rangePayments,
  ) {
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
          ownerId: '',
        ),
      );

      final totalPaidInPeriod = pList.fold<double>(
        0,
        (sum, p) => sum + p.amount,
      );
      final totalDue = customer.totalDue + totalPaidInPeriod;
      final remaining = customer.totalDue;
      final methodTotals = _methodTotals(pList);

      reportRows.add({
        'name': customer.name,
        'phone': customer.phone,
        'totalDue': totalDue,
        'paid': totalPaidInPeriod,
        'remaining': remaining,
        'cash': methodTotals['cash'] ?? 0,
        'bkash': methodTotals['bkash'] ?? 0,
        'other': methodTotals['other'] ?? 0,
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
          .where(
            (p) =>
                p.type == PaymentType.payment &&
                p.date.year == month.year &&
                p.date.month == month.month,
          )
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

  // ✅ প্রতি কাস্টমারের payment method breakdown — কোনটা cash, কোনটা bKash তা
  // statement table এ স্পষ্টভাবে দেখানোর জন্য (একই period এ একাধিক method এ
  // পেমেন্ট থাকলে সবগুলোই দেখাবে)
  String _methodBreakdownLabel(Map<String, dynamic> row) {
    final parts = <String>[];
    final cash = (row['cash'] as double?) ?? 0;
    final bkash = (row['bkash'] as double?) ?? 0;
    final other = (row['other'] as double?) ?? 0;
    if (cash > 0) parts.add('Cash');
    if (bkash > 0) parts.add('bKash');
    if (other > 0) parts.add('Other');
    return parts.isEmpty ? '-' : parts.join(' + ');
  }

  // ✅ HTML দিয়ে PDF বানানো হচ্ছে (আগে pdf প্যাকেজের সরাসরি pw.Text ব্যবহার হতো,
  // যেটা বাংলা কাস্টমারের নাম ঠিকভাবে shape করতে পারত না — শুধু ফাঁকা বক্স দেখাত।
  // HTML রেন্ডারার বাংলা text shaping সঠিকভাবে করে)
  Future<Uint8List> _buildReportPdf(
    List<Map<String, dynamic>> reportData,
    double totalCollection,
    Map<String, double> methodTotals,
    String businessName,
    String ownerName,
    PdfPageFormat format,
  ) async {
    final currencyFmt = NumberFormat('#,##0.00');
    final cashTotal = methodTotals['cash'] ?? 0;
    final bkashTotal = methodTotals['bkash'] ?? 0;
    final otherTotal = methodTotals['other'] ?? 0;

    final rowsHtml = StringBuffer();
    for (final row in reportData) {
      rowsHtml.write('''
        <tr>
          <td>${escapeHtml(row['name'] as String)}</td>
          <td>${escapeHtml(row['phone'] as String)}</td>
          <td>${escapeHtml(_methodBreakdownLabel(row))}</td>
          <td class="right">${currencyFmt.format(row['totalDue'])}</td>
          <td class="right">${currencyFmt.format(row['paid'])}</td>
          <td class="right">${currencyFmt.format(row['remaining'])}</td>
        </tr>
      ''');
    }

    final generatedAt = DateFormat(
      'd MMM yyyy, hh:mm a',
    ).format(DateTime.now());

    final html =
        '''
<!DOCTYPE html>
<html lang="bn">
<head>
<meta charset="UTF-8" />
<style>
  * { box-sizing: border-box; }
  body {
    font-family: 'Noto Sans Bengali', 'Kalpurush', sans-serif;
    padding: 28px;
    color: #1a1a1a;
    font-size: 12px;
  }
  .header {
    display: flex;
    justify-content: space-between;
    align-items: flex-start;
    border-bottom: 2px solid #6366F1;
    padding-bottom: 14px;
    margin-bottom: 22px;
  }
  .shop-name { font-size: 22px; font-weight: 800; margin: 0; }
  .owner-name { font-size: 11.5px; font-weight: 600; margin: 3px 0 0 0; color: #555; }
  .header-right { text-align: right; }
  .title {
    font-size: 11px;
    font-weight: 800;
    margin: 0;
    color: #6366F1;
    text-transform: uppercase;
    letter-spacing: 0.6px;
  }
  .period { font-size: 15px; font-weight: 800; margin: 4px 0 0 0; }
  .section-title {
    font-size: 12.5px;
    font-weight: 800;
    margin: 0 0 10px 0;
    padding-left: 8px;
    border-left: 3px solid #6366F1;
  }
  table { width: 100%; border-collapse: collapse; margin-bottom: 26px; }
  thead tr { background-color: #6366F1; color: #ffffff; }
  th, td {
    border: 0.5px solid #e0e0ea;
    padding: 7px 9px;
    text-align: left;
    font-size: 10.5px;
  }
  th { font-weight: 700; font-size: 10px; text-transform: uppercase; letter-spacing: 0.3px; }
  td.right, th.right { text-align: right; }
  tbody tr:nth-child(even) { background-color: #f7f7fb; }
  .empty { color: #777; font-size: 11px; padding: 14px 0; }
  .total-box {
    width: 260px;
    margin-left: auto;
    margin-bottom: 8px;
    padding: 12px 16px;
    background-color: #f7f7fb;
    border: 1px solid #e0e0ea;
    border-radius: 8px;
  }
  .breakdown-row {
    display: flex;
    justify-content: space-between;
    align-items: center;
    padding: 4px 0;
  }
  .breakdown-row + .breakdown-row { border-top: 0.5px solid #ddd; }
  .breakdown-row span:first-child { font-weight: 600; font-size: 11.5px; color: #444; }
  .breakdown-row span:last-child { font-weight: 700; font-size: 12px; }
  .breakdown-row.total-row { border-top: 1.5px solid #6366F1; margin-top: 6px; padding-top: 10px; }
  .breakdown-row.total-row span:first-child { font-weight: 800; font-size: 14px; color: #1a1a1a; }
  .breakdown-row.total-row span:last-child { font-weight: 800; font-size: 17px; color: #16a34a; }
  .footer {
    margin-top: 28px;
    padding-top: 12px;
    border-top: 0.5px solid #ddd;
    text-align: center;
  }
  .footer .brand { font-size: 10.5px; font-weight: 800; color: #6366F1; margin: 0; }
  .footer .generated { font-size: 8.5px; color: #999; margin: 3px 0 0 0; }
</style>
</head>
<body>
  <div class="header">
    <div>
      <p class="shop-name">${escapeHtml(businessName)}</p>
      ${ownerName.trim().isNotEmpty ? '<p class="owner-name">Owner: ${escapeHtml(ownerName)}</p>' : ''}
    </div>
    <div class="header-right">
      <p class="title">Collection Report &middot; ${_period.name.toUpperCase()}</p>
      <p class="period">${escapeHtml(_periodLabel())}</p>
    </div>
  </div>

  <p class="section-title">Customer Statement Table</p>
  ${reportData.isEmpty ? '<p class="empty">No payments received in this period.</p>' : '''
  <table>
    <thead>
      <tr>
        <th>Customer</th>
        <th>Phone</th>
        <th>Method</th>
        <th class="right">Total Due</th>
        <th class="right">Payment</th>
        <th class="right">Remaining</th>
      </tr>
    </thead>
    <tbody>
      $rowsHtml
    </tbody>
  </table>
  '''}

  <p class="section-title">Collection Summary</p>
  <div class="total-box">
    <div class="breakdown-row"><span>Cash</span><span>${currencyFmt.format(cashTotal)} TK</span></div>
    <div class="breakdown-row"><span>bKash</span><span>${currencyFmt.format(bkashTotal)} TK</span></div>
    ${otherTotal > 0 ? '<div class="breakdown-row"><span>Other (Nagad/Bank)</span><span>${currencyFmt.format(otherTotal)} TK</span></div>' : ''}
    <div class="breakdown-row total-row"><span>Total Collection</span><span>${currencyFmt.format(totalCollection)} TK</span></div>
  </div>

  <div class="footer">
    <p class="brand">Powered by ${LegalContent.appName}</p>
    <p class="generated">Generated on $generatedAt</p>
  </div>
</body>
</html>
''';

    return Printing.convertHtml(format: format, html: html);
  }

  Future<void> _exportPdf() async {
    final (start, end) = _dateRange();
    final rangePayments = _paymentsInRange(start, end);
    final reportData = _getCustomerReportData(rangePayments);
    final totalCollection = rangePayments.fold<double>(
      0,
      (runningTotal, p) => runningTotal + p.amount,
    );
    final methodTotals = _methodTotals(rangePayments);
    final settings = AppSettingsScope.settingsOf(context);

    await Printing.layoutPdf(
      onLayout: (format) => _buildReportPdf(
        reportData,
        totalCollection,
        methodTotals,
        settings.businessName,
        settings.ownerName,
        format,
      ),
      name: 'smart_due_collection_report.pdf',
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: colors.scaffoldBg,
      appBar: AppBar(
        title: Text(
          l10n.collectionReportsTitle,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            color: colors.textPrimary,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: colors.textPrimary),
        actions: [
          // কাস্টম পিডিএফ স্ক্রিন বাটন
          IconButton(
            icon: Icon(Icons.picture_as_pdf_rounded, color: colors.textPrimary),
            tooltip: l10n.customerPdfReportTooltip,
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const CustomerPdfReportScreen(),
                ),
              );
            },
          ),
          // ডাইরেক্ট এক্সপোর্ট পিডিএফ বাটন
          IconButton(
            icon: Icon(Icons.download_rounded, color: colors.textPrimary),
            tooltip: l10n.downloadPdfTooltip,
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
    final l10n = AppLocalizations.of(context)!;
    final (start, end) = _dateRange();
    final rangePayments = _paymentsInRange(start, end);
    final reportData = _getCustomerReportData(rangePayments);
    final totalCollection = rangePayments.fold<double>(
      0,
      (sum, p) => sum + p.amount,
    );
    final methodTotals = _methodTotals(rangePayments);
    final cashTotal = methodTotals['cash'] ?? 0;
    final bkashTotal = methodTotals['bkash'] ?? 0;
    final otherTotal = methodTotals['other'] ?? 0;
    final settings = AppSettingsScope.settingsOf(context);
    final businessName = settings.businessName;
    final ownerName = settings.ownerName;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          l10n.dashboardLabel,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 16,
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        _MonthlyTrendCard(trend: _monthlyTrend(), colors: colors),
        const SizedBox(height: 14),
        _TopDefaultersCard(
          defaulters: _topDefaulters(),
          colors: colors,
          onTapCustomer: (customer) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => CustomerDetailScreen(customer: customer),
              ),
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
          segments: [
            ButtonSegment(
              value: ReportPeriod.daily,
              label: Text(l10n.periodDaily),
              icon: const Icon(Icons.today),
            ),
            ButtonSegment(
              value: ReportPeriod.weekly,
              label: Text(l10n.periodWeekly),
              icon: const Icon(Icons.view_week),
            ),
            ButtonSegment(
              value: ReportPeriod.monthly,
              label: Text(l10n.periodMonthly),
              icon: const Icon(Icons.calendar_view_month),
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

        Center(
          child: Text(
            businessName,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 18,
              color: colors.textPrimary,
            ),
          ),
        ),
        if (ownerName.trim().isNotEmpty) ...[
          const SizedBox(height: 2),
          Center(
            child: Text(
              l10n.ownerLabel(ownerName),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12.5,
                color: colors.textSecondary,
              ),
            ),
          ),
        ],
        const SizedBox(height: 4),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: Icon(Icons.chevron_left, color: colors.textPrimary),
              onPressed: () => setState(() => _offset -= 1),
            ),
            Text(
              _periodLabel(),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: colors.textPrimary,
              ),
            ),
            IconButton(
              icon: Icon(Icons.chevron_right, color: colors.textPrimary),
              onPressed: _offset >= 0
                  ? null
                  : () => setState(() => _offset += 1),
            ),
          ],
        ),

        const SizedBox(height: 20),

        Text(
          l10n.customerPaymentDetails,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),

        if (reportData.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 40),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colors.borderColor),
            ),
            child: Center(
              child: Text(
                l10n.noTransactionsForPeriod,
                style: TextStyle(color: colors.textSecondary),
              ),
            ),
          )
        else
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [colors.surface, colors.surfaceAlt],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colors.borderColor),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: reportData.length,
              separatorBuilder: (context, index) =>
                  Divider(color: colors.borderColor),
              itemBuilder: (context, index) {
                final row = reportData[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                  key: ValueKey(row['phone']),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        row['name'],
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: colors.textPrimary,
                        ),
                      ),
                      Text(
                        row['phone'],
                        style: TextStyle(
                          color: colors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          if ((row['cash'] as double) > 0)
                            _MethodChip(label: l10n.cashMethod, color: colors.clear),
                          if ((row['bkash'] as double) > 0)
                            _MethodChip(
                              label: "bKash",
                              color: const Color(0xFFE2136E),
                            ),
                          if ((row['other'] as double) > 0)
                            _MethodChip(label: l10n.otherMethod, color: colors.warn),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _AmountInfo(
                            label: l10n.totalDue,
                            amount: row['totalDue'],
                            color: colors.warn,
                            textColor: colors.textSecondary,
                          ),
                          _AmountInfo(
                            label: l10n.paymentLabel,
                            amount: row['paid'],
                            color: colors.clear,
                            textColor: colors.textSecondary,
                          ),
                          _AmountInfo(
                            label: l10n.remainingLabel,
                            amount: row['remaining'],
                            color: colors.due,
                            textColor: colors.textSecondary,
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

        const SizedBox(height: 24),

        Text(
          l10n.collectionSummaryLabel,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),

        Align(
          alignment: Alignment.centerRight,
          child: Container(
            width: 240,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colors.clear.withValues(alpha: 0.16),
                  colors.clear.withValues(alpha: 0.06),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colors.clear.withValues(alpha: 0.3)),
            ),
            child: Column(
              children: [
                _BreakdownRow(label: l10n.cashMethod, amount: cashTotal, colors: colors),
                const SizedBox(height: 10),
                _BreakdownRow(
                  label: "bKash",
                  amount: bkashTotal,
                  colors: colors,
                ),
                if (otherTotal > 0) ...[
                  const SizedBox(height: 10),
                  _BreakdownRow(
                    label: l10n.otherNagadBank,
                    amount: otherTotal,
                    colors: colors,
                  ),
                ],
                const SizedBox(height: 14),
                Divider(color: colors.borderColor),
                const SizedBox(height: 6),
                Text(
                  l10n.totalCollectionLabel,
                  style: TextStyle(fontSize: 14, color: colors.textSecondary),
                ),
                const SizedBox(height: 6),
                Text(
                  "${totalCollection.toStringAsFixed(0)} TK",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: colors.clear,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 32),
        Center(
          child: Column(
            children: [
              Icon(
                Icons.verified_rounded,
                color: colors.textSecondary.withValues(alpha: 0.5),
                size: 16,
              ),
              const SizedBox(height: 6),
              Text(
                l10n.poweredByApp(LegalContent.appName),
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: colors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }
}

class _BreakdownRow extends StatelessWidget {
  const _BreakdownRow({
    required this.label,
    required this.amount,
    required this.colors,
  });

  final String label;
  final double amount;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
            color: colors.textPrimary,
          ),
        ),
        Text(
          "${amount.toStringAsFixed(0)} TK",
          style: TextStyle(
            fontSize: 14.5,
            fontWeight: FontWeight.w700,
            color: colors.textPrimary,
          ),
        ),
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
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _MethodChip extends StatelessWidget {
  const _MethodChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

// ✅ Y-axis এর জন্য "গোলগাল" সর্বোচ্চ মান বের করা (যেমন 4,300 হলে 5,000 দেখাবে)
// — এতে gridline গুলো পড়ার মতো ক্লিন সংখ্যায় থাকে
double _niceAxisMax(double rawMax) {
  if (rawMax <= 0) return 100;

  final magnitude = math
      .pow(10, (math.log(rawMax) / math.ln10).floor())
      .toDouble();
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
    final l10n = AppLocalizations.of(context)!;
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
                      l10n.monthlyCollectionTrend,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14.5,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.last6Months,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: colors.textSecondary,
                      ),
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
                      style: TextStyle(
                        fontSize: 11,
                        color: colors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      "${currencyFmt.format(latest.$2)} TK",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: colors.clear,
                      ),
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
                  l10n.noPaymentRecordsPeriod,
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
                    getDrawingHorizontalLine: (_) =>
                        FlLine(color: colors.borderColor, strokeWidth: 1),
                  ),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    show: true,
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        interval: axisMax / 4,
                        getTitlesWidget: (value, meta) => Text(
                          currencyFmt.format(value),
                          style: TextStyle(
                            fontSize: 9.5,
                            color: colors.hintColor,
                          ),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 24,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < 0 || index >= trend.length)
                            return const SizedBox.shrink();
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              DateFormat('MMM').format(trend[index].$1),
                              style: TextStyle(
                                fontSize: 10.5,
                                color: colors.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
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
                          TextStyle(
                            color: colors.textSecondary,
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                          ),
                          children: [
                            TextSpan(
                              text: "${currencyFmt.format(rod.toY)} TK",
                              style: TextStyle(
                                color: colors.clear,
                                fontWeight: FontWeight.w800,
                                fontSize: 12.5,
                              ),
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
    final l10n = AppLocalizations.of(context)!;
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
            l10n.topDefaultersLabel,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 14.5,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            l10n.topDefaultersDesc,
            style: TextStyle(fontSize: 11.5, color: colors.textSecondary),
          ),
          const SizedBox(height: 16),
          if (defaulters.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  l10n.allClearCelebration,
                  style: TextStyle(
                    color: colors.clear,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
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
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: colors.hintColor,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      customer.name,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: colors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "${currencyFmt.format(customer.totalDue)} TK",
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: colors.due,
                    ),
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
                          width:
                              constraints.maxWidth * fraction.clamp(0.0, 1.0),
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
