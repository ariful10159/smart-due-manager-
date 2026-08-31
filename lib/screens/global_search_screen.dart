import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' show Document;
import 'package:intl/intl.dart';

import '../l10n/app_localizations.dart';
import '../models/customer.dart';
import '../models/customer_repository.dart';
import '../models/notebook.dart';
import '../models/notebook_page.dart';
import '../models/notebook_repository.dart';
import '../models/payment.dart';
import '../theme/app_colors.dart';
import 'customer_detail_screen.dart';
import 'notebook_screen.dart';

class _PageWithText {
  _PageWithText(this.page, this.plainText);
  final NotebookPage page;
  final String plainText;
}

class _NotebookEntry {
  _NotebookEntry({required this.notebook, required this.pages});
  final Notebook notebook;
  final List<_PageWithText> pages;
}

class _PaymentEntry {
  _PaymentEntry({required this.payment, required this.customer});
  final Payment payment;
  final Customer customer;
}

class _NotebookMatch {
  _NotebookMatch({required this.notebook, this.page, this.snippet = ''});
  final Notebook notebook;
  final NotebookPage? page;
  final String snippet;
}

String _plainTextOf(NotebookPage page) {
  try {
    final document = Document.fromJson(jsonDecode(page.contentJson) as List);
    return document.toPlainText();
  } catch (_) {
    return '';
  }
}

String _snippetAround(String text, int index, int queryLen) {
  const radius = 40;
  final start = (index - radius).clamp(0, text.length);
  final end = (index + queryLen + radius).clamp(0, text.length);
  final snippet = text.substring(start, end).replaceAll('\n', ' ').trim();
  return '${start > 0 ? '…' : ''}$snippet${end < text.length ? '…' : ''}';
}

class GlobalSearchScreen extends StatefulWidget {
  const GlobalSearchScreen({super.key});

  @override
  State<GlobalSearchScreen> createState() => _GlobalSearchScreenState();
}

class _GlobalSearchScreenState extends State<GlobalSearchScreen> {
  final _customerRepo = CustomerRepository();
  final _notebookRepo = NotebookRepository();
  final _searchController = TextEditingController();

  bool _loading = true;
  bool _loadError = false;
  String _query = '';

  List<Customer> _customers = [];
  List<_PaymentEntry> _payments = [];
  List<_NotebookEntry> _notebookEntries = [];

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    setState(() {
      _loading = true;
      _loadError = false;
    });

    try {
      final customers = (await _customerRepo.fetchCustomersOnce())
          .where((c) => !c.isHidden)
          .toList();
      final notebooks = await _notebookRepo.fetchNotebooksOnce();

      final paymentLists = await Future.wait(
        customers.map((c) => _customerRepo.streamPayments(c.id).first),
      );
      final payments = <_PaymentEntry>[];
      for (var i = 0; i < customers.length; i++) {
        for (final payment in paymentLists[i]) {
          payments.add(_PaymentEntry(payment: payment, customer: customers[i]));
        }
      }

      final notebookEntries = await Future.wait(notebooks.map((notebook) async {
        final pages = await _notebookRepo.fetchPagesOnce(notebook.id);
        final pagesWithText = pages.map((p) => _PageWithText(p, _plainTextOf(p))).toList();
        return _NotebookEntry(notebook: notebook, pages: pagesWithText);
      }));

      if (!mounted) return;
      setState(() {
        _customers = customers;
        _payments = payments;
        _notebookEntries = notebookEntries;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadError = true;
      });
    }
  }

  List<Customer> get _matchedCustomers {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return [];
    final qDigits = q.replaceAll(RegExp(r'[\s\-]'), '');

    return _customers.where((c) {
      final nameMatch = c.name.toLowerCase().contains(q);
      final phoneMatch = c.phone.replaceAll(RegExp(r'[\s\-]'), '').contains(qDigits);
      final addressMatch = c.address?.toLowerCase().contains(q) ?? false;
      return nameMatch || phoneMatch || addressMatch;
    }).toList();
  }

  List<_PaymentEntry> get _matchedPayments {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return [];

    final matches = _payments.where((entry) {
      final p = entry.payment;
      final methodMatch = p.paymentMethod != null &&
          Payment.paymentMethodToString(p.paymentMethod!).toLowerCase().contains(q);
      return entry.customer.name.toLowerCase().contains(q) ||
          (p.description?.toLowerCase().contains(q) ?? false) ||
          (p.note?.toLowerCase().contains(q) ?? false) ||
          p.amount.toStringAsFixed(0).contains(q) ||
          methodMatch;
    }).toList()
      ..sort((a, b) => b.payment.date.compareTo(a.payment.date));

    return matches;
  }

  List<_NotebookMatch> get _matchedNotebooks {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return [];

    final results = <_NotebookMatch>[];

    for (final entry in _notebookEntries) {
      final notebook = entry.notebook;
      final titleMatch = notebook.title.toLowerCase().contains(q);
      final descMatch = notebook.description.toLowerCase().contains(q);

      if (titleMatch || descMatch) {
        results.add(_NotebookMatch(
          notebook: notebook,
          snippet: !titleMatch && descMatch ? notebook.description : '',
        ));
      }

      for (final pageEntry in entry.pages) {
        final page = pageEntry.page;
        final titleMatches = page.title.toLowerCase().contains(q);
        final bodyIndex = pageEntry.plainText.toLowerCase().indexOf(q);

        if (titleMatches || bodyIndex != -1) {
          results.add(_NotebookMatch(
            notebook: notebook,
            page: page,
            snippet: bodyIndex != -1 ? _snippetAround(pageEntry.plainText, bodyIndex, q.length) : '',
          ));
        }
      }
    }

    return results;
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final l10n = AppLocalizations.of(context)!;
    final hasQuery = _query.trim().isNotEmpty;

    final matchedCustomers = _matchedCustomers;
    final matchedPayments = _matchedPayments;
    final matchedNotebooks = _matchedNotebooks;
    final totalResults = matchedCustomers.length + matchedPayments.length + matchedNotebooks.length;

    return Scaffold(
      backgroundColor: colors.scaffoldBg,
      appBar: AppBar(
        title: Text(
          l10n.globalSearchTitle,
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: colors.textPrimary),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: colors.textPrimary),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              style: TextStyle(color: colors.textPrimary, fontSize: 14),
              decoration: InputDecoration(
                hintText: l10n.globalSearchHint,
                hintStyle: TextStyle(color: colors.hintColor, fontSize: 13.5),
                prefixIcon: Icon(Icons.search_rounded, color: colors.textSecondary),
                suffixIcon: hasQuery
                    ? IconButton(
                        icon: Icon(Icons.clear_rounded, color: colors.textSecondary),
                        onPressed: () {
                          setState(() {
                            _query = '';
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
              ),
              onChanged: (value) => setState(() => _query = value),
            ),
          ),
          Expanded(
            child: _loading
                ? Center(child: CircularProgressIndicator(color: colors.accent))
                : _loadError
                    ? _MessageState(
                        icon: Icons.error_outline_rounded,
                        title: l10n.dataLoadFailedShort,
                        subtitle: l10n.tryAgainMessage,
                        colors: colors,
                        actionLabel: l10n.retryAction,
                        onAction: _loadAll,
                      )
                    : !hasQuery
                        ? _MessageState(
                            icon: Icons.travel_explore_rounded,
                            title: l10n.startTypingToSearch,
                            subtitle: l10n.searchEverythingDesc,
                            colors: colors,
                          )
                        : totalResults == 0
                            ? _MessageState(
                                icon: Icons.search_off_rounded,
                                title: l10n.noResultsFound,
                                subtitle: l10n.noMatchesFor(_query),
                                colors: colors,
                              )
                            : ListView(
                                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                                children: [
                                  if (matchedCustomers.isNotEmpty) ...[
                                    _SectionLabel(label: l10n.customersSectionLabel, count: matchedCustomers.length, colors: colors),
                                    const SizedBox(height: 8),
                                    for (final customer in matchedCustomers) ...[
                                      _CustomerResultTile(customer: customer, colors: colors),
                                      const SizedBox(height: 8),
                                    ],
                                    const SizedBox(height: 12),
                                  ],
                                  if (matchedPayments.isNotEmpty) ...[
                                    _SectionLabel(label: l10n.paymentHistoryTitle, count: matchedPayments.length, colors: colors),
                                    const SizedBox(height: 8),
                                    for (final entry in matchedPayments) ...[
                                      _PaymentResultTile(entry: entry, colors: colors),
                                      const SizedBox(height: 8),
                                    ],
                                    const SizedBox(height: 12),
                                  ],
                                  if (matchedNotebooks.isNotEmpty) ...[
                                    _SectionLabel(label: l10n.drawerNotebooks, count: matchedNotebooks.length, colors: colors),
                                    const SizedBox(height: 8),
                                    for (final match in matchedNotebooks) ...[
                                      _NotebookResultTile(match: match, colors: colors),
                                      const SizedBox(height: 8),
                                    ],
                                  ],
                                ],
                              ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label, required this.count, required this.colors});

  final String label;
  final int count;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    return Text(
      "${label.toUpperCase()} ($count)",
      style: TextStyle(
        color: colors.textSecondary,
        fontWeight: FontWeight.w800,
        fontSize: 11.5,
        letterSpacing: 0.8,
      ),
    );
  }
}

class _CustomerResultTile extends StatelessWidget {
  const _CustomerResultTile({required this.customer, required this.colors});

  final Customer customer;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    final dueColor = customer.totalDue > 0 ? colors.due : colors.clear;

    return _ResultCard(
      colors: colors,
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => CustomerDetailScreen(customer: customer)),
        );
      },
      leading: Container(
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(color: colors.accent.withValues(alpha: 0.16), shape: BoxShape.circle),
        child: Icon(Icons.person_rounded, color: colors.accent, size: 18),
      ),
      title: customer.name,
      subtitle: customer.phone,
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(color: dueColor.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(9)),
        child: Text(
          customer.totalDue.toStringAsFixed(0),
          style: TextStyle(color: dueColor, fontWeight: FontWeight.w800, fontSize: 12),
        ),
      ),
    );
  }
}

class _PaymentResultTile extends StatelessWidget {
  const _PaymentResultTile({required this.entry, required this.colors});

  final _PaymentEntry entry;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    final payment = entry.payment;
    final isPayment = payment.type == PaymentType.payment;
    final amountColor = isPayment ? colors.clear : colors.due;

    return _ResultCard(
      colors: colors,
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => CustomerDetailScreen(customer: entry.customer)),
        );
      },
      leading: Container(
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(color: amountColor.withValues(alpha: 0.16), shape: BoxShape.circle),
        child: Icon(
          isPayment ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
          color: amountColor,
          size: 18,
        ),
      ),
      title: entry.customer.name,
      subtitle: payment.description?.isNotEmpty == true
          ? payment.description!
          : "${DateFormat('d MMM yyyy').format(payment.date)}${payment.paymentMethod != null ? ' · ${Payment.paymentMethodToString(payment.paymentMethod!)}' : ''}",
      trailing: Text(
        payment.amount.toStringAsFixed(0),
        style: TextStyle(color: amountColor, fontWeight: FontWeight.w800, fontSize: 13.5),
      ),
    );
  }
}

class _NotebookResultTile extends StatelessWidget {
  const _NotebookResultTile({required this.match, required this.colors});

  final _NotebookMatch match;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final coverColor = Color(match.notebook.coverColor);

    return _ResultCard(
      colors: colors,
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => NotebookScreen(notebookId: match.notebook.id, initialPageId: match.page?.id),
          ),
        );
      },
      leading: Container(
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(color: coverColor.withValues(alpha: 0.2), shape: BoxShape.circle),
        child: Icon(Icons.menu_book_rounded, color: coverColor, size: 18),
      ),
      title: match.page != null ? "${match.notebook.title} · ${match.page!.title}" : match.notebook.title,
      subtitle: match.snippet.isNotEmpty ? match.snippet : (match.page != null ? l10n.pageTitleMatched : l10n.notebookMatched),
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({
    required this.colors,
    required this.onTap,
    required this.leading,
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  final AppColors colors;
  final VoidCallback onTap;
  final Widget leading;
  final String title;
  final String subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(10),
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
              leading,
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, color: colors.textPrimary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11.5, color: colors.textSecondary),
                    ),
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 8),
                trailing!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _MessageState extends StatelessWidget {
  const _MessageState({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.colors,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final AppColors colors;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(color: colors.surface, shape: BoxShape.circle),
              child: Icon(icon, size: 36, color: colors.textSecondary),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: colors.textPrimary),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.textSecondary, fontSize: 12.5),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: onAction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.accent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                child: Text(actionLabel!, style: const TextStyle(fontWeight: FontWeight.w700)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
