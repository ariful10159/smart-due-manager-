import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';

import '../l10n/app_localizations.dart';
import '../models/customer.dart';
import '../models/payment.dart';
import '../services/receipt_pdf_service.dart';
import '../theme/app_colors.dart';
import 'app_settings_scope.dart';

class PaymentHistoryTile extends StatelessWidget {
  const PaymentHistoryTile({super.key, required this.payment, required this.customer});

  final Payment payment;
  final Customer customer;

  String _formatDateTime(DateTime date) {
    return DateFormat('d MMMM yyyy • hh:mm a').format(date);
  }

  Future<void> _shareReceipt(BuildContext context, void Function(bool) setGenerating) async {
    final colors = AppColors.of(context);
    final settings = AppSettingsScope.of(context).settings;

    setGenerating(true);
    try {
      final bytes = await ReceiptPdfService.buildReceipt(
        customer: customer,
        payment: payment,
        settings: settings,
        languageCode: settings.languageCode,
      );

      await Printing.sharePdf(
        bytes: bytes,
        filename: '${customer.name.replaceAll(" ", "_")}_receipt_${payment.id}.pdf',
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: colors.due,
          content: Text(AppLocalizations.of(context)!.receiptGenerationFailed),
        ),
      );
    } finally {
      setGenerating(false);
    }
  }

  void _showPaymentDetail(BuildContext context) {
    final colors = AppColors.of(context);
    final l10n = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      useSafeArea: true,
      builder: (dialogContext) {
        var generating = false;

        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              backgroundColor: colors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: colors.borderColor),
              ),
              title: Text(
                payment.type == PaymentType.payment ? l10n.paymentTypeLabel : l10n.chargeAddedLabel,
                style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w800),
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (payment.receiptImageUrl != null &&
                          payment.receiptImageUrl!.isNotEmpty)
                        _buildReceiptImage(dialogContext, colors),
                      if (payment.receiptImageUrl != null &&
                          payment.receiptImageUrl!.isNotEmpty)
                        const SizedBox(height: 16),
                      Text(
                        l10n.amountColonLabel(payment.amount.toStringAsFixed(2)),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: colors.textPrimary,
                        ),
                      ),
                      if (payment.discount > 0) ...[
                        const SizedBox(height: 4),
                        Text(
                          l10n.discountColonLabel(payment.discount.toStringAsFixed(2)),
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13.5,
                            color: colors.clear,
                          ),
                        ),
                      ],
                      const SizedBox(height: 6),
                      Text(
                        l10n.dateColonLabel(_formatDateTime(payment.date)),
                        style: TextStyle(color: colors.textSecondary),
                      ),
                      if (payment.paymentMethod != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          l10n.methodColonLabel(Payment.paymentMethodToString(payment.paymentMethod!)),
                          style: TextStyle(color: colors.textSecondary),
                        ),
                      ],
                      if (payment.description != null &&
                          payment.description!.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(
                          l10n.descriptionColonLabel,
                          style: TextStyle(fontWeight: FontWeight.w600, color: colors.textPrimary),
                        ),
                        const SizedBox(height: 4),
                        Text(payment.description!, style: TextStyle(color: colors.textSecondary)),
                      ],
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton.icon(
                  onPressed: generating
                      ? null
                      : () => _shareReceipt(
                            dialogContext,
                            (value) => setDialogState(() => generating = value),
                          ),
                  icon: generating
                      ? SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2, color: colors.accent),
                        )
                      : Icon(Icons.share_rounded, size: 16, color: colors.accent),
                  label: Text(
                    generating ? l10n.generatingLabel : l10n.shareReceiptAction,
                    style: TextStyle(color: colors.accent, fontWeight: FontWeight.w700),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text(l10n.close, style: TextStyle(color: colors.textSecondary, fontWeight: FontWeight.w700)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildReceiptImage(BuildContext context, AppColors colors) {
    try {
      final bytes = base64Decode(payment.receiptImageUrl!);
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: GestureDetector(
          onTap: () => _openFullScreenImage(context, bytes),
          child: SizedBox(
            width: double.infinity,
            height: 200,
            child: Image.memory(
              bytes,
              fit: BoxFit.cover,
              gaplessPlayback: true,
              errorBuilder: (context, error, stackTrace) {
                return Center(
                  child: Text(AppLocalizations.of(context)!.imageLoadFailed, style: TextStyle(color: colors.textSecondary)),
                );
              },
            ),
          ),
        ),
      );
    } catch (e) {
      return const SizedBox.shrink();
    }
  }

  void _openFullScreenImage(BuildContext context, Uint8List bytes) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black,
        pageBuilder: (_, _, _) => _FullScreenImageViewer(bytes: bytes),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final l10n = AppLocalizations.of(context)!;
    final isPayment = payment.type == PaymentType.payment;
    final amountColor = isPayment ? colors.clear : colors.due;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colors.surface, colors.surfaceAlt],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.borderColor),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            // ✅ পরের frame এ dialog খোলা হচ্ছে, current build/layout এর সাথে conflict এড়াতে
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (context.mounted) {
                _showPaymentDetail(context);
              }
            });
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: amountColor.withValues(alpha: 0.14),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isPayment ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                    color: amountColor,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            payment.amount.toStringAsFixed(2),
                            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5, color: colors.textPrimary),
                          ),
                          if (payment.discount > 0) ...[
                            const SizedBox(width: 6),
                            Text(
                              l10n.discountAppliedLabel(payment.discount.toStringAsFixed(2)),
                              style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: colors.clear),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        payment.description?.isNotEmpty == true
                            ? payment.description!
                            : (isPayment ? l10n.paymentTypeLabel : l10n.chargeAddedLabel),
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12, color: colors.textSecondary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      DateFormat('d MMM yyyy').format(payment.date),
                      style: TextStyle(fontSize: 11.5, color: colors.hintColor),
                    ),
                    if (payment.receiptImageUrl != null &&
                        payment.receiptImageUrl!.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Icon(Icons.photo_rounded, size: 15, color: colors.textSecondary),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FullScreenImageViewer extends StatelessWidget {
  const _FullScreenImageViewer({required this.bytes});

  final Uint8List bytes;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Center(
            child: InteractiveViewer(
              minScale: 1,
              maxScale: 4,
              child: Image.memory(bytes, fit: BoxFit.contain),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Align(
                alignment: Alignment.topLeft,
                child: IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
