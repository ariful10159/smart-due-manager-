import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../l10n/app_localizations.dart';
import '../models/customer.dart';
import '../models/customer_repository.dart';
import '../theme/app_colors.dart';
import '../widgets/app_settings_scope.dart';

class ArchivedCustomersScreen extends StatefulWidget {
  const ArchivedCustomersScreen({super.key});

  @override
  State<ArchivedCustomersScreen> createState() =>
      _ArchivedCustomersScreenState();
}

class _ArchivedCustomersScreenState extends State<ArchivedCustomersScreen> {
  final _customerRepo = CustomerRepository();

  Future<void> _confirmRestore(Customer customer) async {
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
          l10n.restoreCustomerTitle,
          style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w800),
        ),
        content: Text(
          l10n.restoreConfirmBody(customer.name),
          style: TextStyle(color: colors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel, style: TextStyle(color: colors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.restoreAction, style: TextStyle(color: colors.clear, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _restoreCustomer(customer);
    }
  }

  Future<void> _restoreCustomer(Customer customer) async {
    final colors = AppColors.of(context);
    try {
      await _customerRepo.restoreCustomer(customer.id);

      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: colors.clear,
          content: Text(l10n.customerRestoredSuccess(customer.name)),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: colors.due,
          content: Text(AppLocalizations.of(context)!.restoreFailed),
        ),
      );
    }
  }

  Future<void> _confirmPermanentDelete(Customer customer) async {
    final colors = AppColors.of(context);
    final l10n = AppLocalizations.of(context)!;

    // ধাপ ১ — প্রথম confirmation
    final firstConfirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: colors.borderColor),
        ),
        title: Text(
          l10n.deletePermanentlyTitle,
          style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w800),
        ),
        content: Text(
          l10n.deletePermanentlyConfirmBody(customer.name),
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
              l10n.continueAction,
              style: TextStyle(color: colors.due, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );

    if (firstConfirm != true) return;
    if (!mounted) return;

    // ধাপ ২ — দ্বিতীয় (final) confirmation, extra safety এর জন্য
    final finalConfirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: colors.borderColor),
        ),
        title: Text(
          l10n.areYouAbsolutelySure,
          style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w800),
        ),
        content: Text(
          l10n.undoWarningBody,
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
              l10n.yesDeleteForever,
              style: TextStyle(color: colors.due, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );

    if (finalConfirm == true) {
      await _permanentlyDeleteCustomer(customer);
    }
  }

  Future<void> _permanentlyDeleteCustomer(Customer customer) async {
    final colors = AppColors.of(context);
    try {
      await _customerRepo.deleteCustomerPermanently(customer.id);

      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: colors.clear,
          content: Text(l10n.customerPermanentlyDeleted(customer.name)),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: colors.due,
          content: Text(AppLocalizations.of(context)!.deleteFailedGeneric),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final l10n = AppLocalizations.of(context)!;
    final currencySymbol = AppSettingsScope.of(context).settings.currencySymbol;
    final currencyFmt = NumberFormat('#,##0.00');

    return Scaffold(
      backgroundColor: colors.scaffoldBg,
      appBar: AppBar(
        title: Text(
          l10n.drawerArchived,
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: colors.textPrimary),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: colors.textPrimary),
      ),
      body: StreamBuilder<List<Customer>>(
        stream: _customerRepo.streamHiddenCustomers(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator(color: colors.accent));
          }

          final customers = snapshot.data!;

          if (customers.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(color: colors.surface, shape: BoxShape.circle),
                    child: Icon(Icons.inventory_2_outlined, size: 40, color: colors.textSecondary),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    l10n.noArchivedCustomers,
                    style: TextStyle(color: colors.textSecondary, fontWeight: FontWeight.w600, fontSize: 13.5),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: customers.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final customer = customers[index];

              return Container(
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
                      color: Colors.black.withValues(alpha: 0.2),
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
                        color: colors.hintColor.withValues(alpha: 0.16),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.archive_rounded, color: colors.textSecondary, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            customer.name,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15.5, color: colors.textPrimary),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            customer.phone,
                            style: TextStyle(fontSize: 12.5, color: colors.textSecondary, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: colors.due.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              l10n.totalDueColon('$currencySymbol${currencyFmt.format(customer.totalDue)}'),
                              style: TextStyle(color: colors.due, fontWeight: FontWeight.w800, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () => _confirmRestore(customer),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: colors.clear.withValues(alpha: 0.14),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.restore_rounded, color: colors.clear, size: 19),
                          ),
                        ),
                        const SizedBox(height: 8),
                        InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () => _confirmPermanentDelete(customer),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: colors.due.withValues(alpha: 0.14),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.delete_forever_rounded, color: colors.due, size: 19),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
