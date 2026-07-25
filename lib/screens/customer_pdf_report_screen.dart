import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

import '../models/customer.dart';
import '../models/customer_repository.dart';
import '../theme/app_colors.dart';

enum _ReportFilter { all, dueOnly }

enum _ReportSort {
  dueHighToLow,
  dueLowToHigh,
  nameAZ,
  dateNewestFirst,
  dateOldestFirst,
}

class CustomerPdfReportScreen extends StatefulWidget {
  const CustomerPdfReportScreen({super.key});

  @override
  State<CustomerPdfReportScreen> createState() => _CustomerPdfReportScreenState();
}

class _CustomerPdfReportScreenState extends State<CustomerPdfReportScreen> {
  final _repo = CustomerRepository();

  bool _loading = true;
  bool _generating = false;
  List<Customer> _allCustomers = [];

  _ReportFilter _filter = _ReportFilter.all;
  _ReportSort _sort = _ReportSort.dueHighToLow;

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  Future<void> _loadCustomers() async {
    setState(() => _loading = true);
    final customers = await _repo.fetchCustomersOnce();
    if (!mounted) return;
    setState(() {
      _allCustomers = customers;
      _loading = false;
    });
  }

  // ✅ Address safely resolve করার helper — null/empty হলে fallback দেখায়
  String _resolveAddress(Customer c, {String fallback = "-"}) {
    if (c.address != null && c.address!.trim().isNotEmpty) {
      return c.address!.trim();
    }
    return fallback;
  }

  List<Customer> get _filteredSorted {
    // ✅ আর্কাইভ করা কাস্টমারদের রিপোর্ট থেকে বাদ দেওয়া হচ্ছে
    var list = _allCustomers.where((c) => !c.isHidden).toList();

    if (_filter == _ReportFilter.dueOnly) {
      list = list.where((c) => c.totalDue > 0).toList();
    }

    switch (_sort) {
      case _ReportSort.dueHighToLow:
        list.sort((a, b) => b.totalDue.compareTo(a.totalDue));
        break;
      case _ReportSort.dueLowToHigh:
        list.sort((a, b) => a.totalDue.compareTo(b.totalDue));
        break;
      case _ReportSort.nameAZ:
        list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        break;
      case _ReportSort.dateNewestFirst:
        list.sort((a, b) => b.lastPaymentDate.compareTo(a.lastPaymentDate));
        break;
      case _ReportSort.dateOldestFirst:
        list.sort((a, b) => a.lastPaymentDate.compareTo(b.lastPaymentDate));
        break;
    }

    return list;
  }

  String _sortLabel(_ReportSort option) {
    switch (option) {
      case _ReportSort.dueHighToLow:
        return "Due: বেশি থেকে কম";
      case _ReportSort.dueLowToHigh:
        return "Due: কম থেকে বেশি";
      case _ReportSort.nameAZ:
        return "নাম: A - Z";
      case _ReportSort.dateNewestFirst:
        return "Due Date: নতুন থেকে পুরাতন";
      case _ReportSort.dateOldestFirst:
        return "Due Date: পুরাতন থেকে নতুন";
    }
  }

  // ✅ HTML এ ব্যবহারের জন্য বিশেষ ক্যারেক্টার escape করা (& < > " ইত্যাদি)
  String _escapeHtml(String input) {
    return input
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#39;');
  }

  // ✅ PDF বানানোর মূল ফাংশন — HTML দিয়ে (বাংলা text shaping সঠিকভাবে হওয়ার জন্য)
  Future<Uint8List> _buildPdf(List<Customer> customers, PdfPageFormat format) async {
    final currencyFmt = NumberFormat('#,##0.00');
    final dateFmt = DateFormat('d MMM yyyy');
    final now = DateTime.now();
    final totalDue = customers.fold<double>(0, (sum, c) => sum + c.totalDue);

    final rowsHtml = StringBuffer();
    for (var i = 0; i < customers.length; i++) {
      final c = customers[i];
      rowsHtml.write('''
        <tr>
          <td class="center">${i + 1}</td>
          <td>${_escapeHtml(c.name)}</td>
          <td>${_escapeHtml(c.phone.isNotEmpty ? c.phone : "-")}</td>
          <td>${_escapeHtml(_resolveAddress(c))}</td>
          <td>${dateFmt.format(c.lastPaymentDate)}</td>
          <td class="right">${currencyFmt.format(c.totalDue)}</td>
        </tr>
      ''');
    }

    final html = '''
<!DOCTYPE html>
<html lang="bn">
<head>
<meta charset="UTF-8" />
<style>
  * { box-sizing: border-box; }
  body {
    font-family: 'Noto Sans Bengali', 'Kalpurush', sans-serif;
    padding: 24px;
    color: #1a1a1a;
    font-size: 12px;
  }
  .header-row {
    display: flex;
    justify-content: space-between;
    align-items: flex-start;
    border-bottom: 1px solid #ccc;
    padding-bottom: 10px;
    margin-bottom: 6px;
  }
  .title {
    font-size: 18px;
    font-weight: 700;
    margin: 0;
  }
  .date {
    font-size: 10px;
    color: #555;
  }
  .summary-line {
    font-size: 11px;
    color: #333;
    margin: 6px 0 14px 0;
  }
  table {
    width: 100%;
    border-collapse: collapse;
  }
  thead tr {
    background-color: #6366F1;
    color: #ffffff;
  }
  th, td {
    border: 0.5px solid #ccc;
    padding: 6px 8px;
    text-align: left;
    font-size: 10.5px;
  }
  th {
    font-weight: 700;
    font-size: 10.5px;
  }
  td.center, th.center { text-align: center; }
  td.right, th.right { text-align: right; }
  tbody tr:nth-child(even) {
    background-color: #f7f7fb;
  }
  .total-box {
    margin-top: 16px;
    padding: 10px 14px;
    background-color: #f0f0f5;
    border-radius: 6px;
    display: flex;
    justify-content: space-between;
    align-items: center;
  }
  .total-label {
    font-weight: 700;
    font-size: 12px;
  }
  .total-value {
    font-weight: 700;
    font-size: 13px;
    color: #c0392b;
  }
</style>
</head>
<body>
  <div class="header-row">
    <p class="title">Smart Due — Customer Report</p>
    <p class="date">তারিখ: ${dateFmt.format(now)}</p>
  </div>
  <p class="summary-line">
    মোট কাস্টমার: ${customers.length} &nbsp;|&nbsp; মোট বকেয়া: ৳${currencyFmt.format(totalDue)}
  </p>
  <table>
    <thead>
      <tr>
        <th class="center">ক্র.</th>
        <th>নাম</th>
        <th>ফোন</th>
        <th>ঠিকানা</th>
        <th>Due Date</th>
        <th class="right">বকেয়া</th>
      </tr>
    </thead>
    <tbody>
      $rowsHtml
    </tbody>
  </table>
  <div class="total-box">
    <span class="total-label">সর্বমোট বকেয়া</span>
    <span class="total-value">৳${currencyFmt.format(totalDue)}</span>
  </div>
</body>
</html>
''';

    return Printing.convertHtml(format: format, html: html);
  }

  Future<void> _previewAndPrint() async {
    setState(() => _generating = true);
    try {
      final customers = _filteredSorted;
      await Printing.layoutPdf(
        onLayout: (format) => _buildPdf(customers, format),
        name: 'smart_due_customer_report.pdf',
      );
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  Future<void> _sharePdf() async {
    setState(() => _generating = true);
    try {
      final customers = _filteredSorted;
      final bytes = await _buildPdf(customers, PdfPageFormat.a4);
      await Printing.sharePdf(
        bytes: bytes,
        filename: 'smart_due_customer_report.pdf',
      );
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final result = _filteredSorted;
    final totalDue = result.fold<double>(0, (sum, c) => sum + c.totalDue);

    return Scaffold(
      backgroundColor: colors.scaffoldBg,
      appBar: AppBar(
        title: Text(
          "Customer PDF Report",
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: colors.textPrimary),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: colors.textPrimary),
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: colors.accent))
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Column(
                    children: [
                      // ✅ Summary card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [colors.accent, colors.accentAlt],
                          ),
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: colors.accent.withValues(alpha: 0.3),
                              blurRadius: 16,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "${result.length} জন কাস্টমার",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  "মোট বকেয়া: ৳${totalDue.toStringAsFixed(2)}",
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.9),
                                    fontSize: 12.5,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.picture_as_pdf_rounded, color: Colors.white, size: 26),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 14),

                      // ✅ Filter chips
                      Row(
                        children: [
                          Expanded(
                            child: _FilterChip(
                              label: "সব কাস্টমার",
                              selected: _filter == _ReportFilter.all,
                              colors: colors,
                              onTap: () => setState(() => _filter = _ReportFilter.all),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _FilterChip(
                              label: "শুধু বকেয়া",
                              selected: _filter == _ReportFilter.dueOnly,
                              colors: colors,
                              onTap: () => setState(() => _filter = _ReportFilter.dueOnly),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      // ✅ Sort dropdown
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: colors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: colors.borderColor),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<_ReportSort>(
                            value: _sort,
                            isExpanded: true,
                            dropdownColor: colors.surface,
                            icon: Icon(Icons.keyboard_arrow_down_rounded, color: colors.textSecondary),
                            style: TextStyle(color: colors.textPrimary, fontSize: 13.5, fontWeight: FontWeight.w600),
                            items: _ReportSort.values.map((option) {
                              return DropdownMenuItem(
                                value: option,
                                child: Text(_sortLabel(option)),
                              );
                            }).toList(),
                            onChanged: (value) {
                              if (value != null) setState(() => _sort = value);
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // ✅ Preview list (short summary rows)
                Expanded(
                  child: result.isEmpty
                      ? Center(
                          child: Text(
                            "কোনো কাস্টমার পাওয়া যায়নি",
                            style: TextStyle(color: colors.textSecondary, fontWeight: FontWeight.w600),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          itemCount: result.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final c = result[index];
                            final dueColor = c.totalDue > 0 ? colors.due : colors.clear;
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [colors.surface, colors.surfaceAlt],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: colors.borderColor),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 26,
                                    height: 26,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: colors.accent.withValues(alpha: 0.15),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Text(
                                      "${index + 1}",
                                      style: TextStyle(color: colors.accent, fontSize: 11, fontWeight: FontWeight.w800),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          c.name,
                                          style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w700, fontSize: 13.5),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          "${_resolveAddress(c, fallback: c.phone)}  •  ${DateFormat('d MMM yyyy').format(c.lastPaymentDate)}",
                                          style: TextStyle(color: colors.textSecondary, fontSize: 11),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    c.totalDue.toStringAsFixed(2),
                                    style: TextStyle(color: dueColor, fontWeight: FontWeight.w800, fontSize: 13),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),

                // ✅ Bottom action buttons
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    border: Border(top: BorderSide(color: colors.borderColor)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _generating || result.isEmpty ? null : _sharePdf,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: colors.textPrimary,
                            side: BorderSide(color: colors.borderColor),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: const Icon(Icons.share_rounded, size: 18),
                          label: const Text("Share", style: TextStyle(fontWeight: FontWeight.w700)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            gradient: LinearGradient(colors: [colors.accent, colors.accentAlt]),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: _generating || result.isEmpty ? null : _previewAndPrint,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                child: Center(
                                  child: _generating
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                        )
                                      : const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.print_rounded, color: Colors.white, size: 18),
                                            SizedBox(width: 8),
                                            Text(
                                              "Print / Preview",
                                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14),
                                            ),
                                          ],
                                        ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.colors,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final AppColors colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 11),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? colors.accent.withValues(alpha: 0.16) : colors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? colors.accent : colors.borderColor),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? colors.accent : colors.textSecondary,
            fontWeight: FontWeight.w700,
            fontSize: 12.5,
          ),
        ),
      ),
    );
  }
}