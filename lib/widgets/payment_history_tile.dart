import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';

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
          content: const Text("Receipt তৈরি করা যায়নি, আবার চেষ্টা করুন"),
        ),
      );
    } finally {
      setGenerating(false);
    }
  }

  void _showPaymentDetail(BuildContext context) {
    final colors = AppColors.of(context);

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
                payment.type == PaymentType.payment ? 'Payment' : 'Charge Added',
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
                        _buildReceiptImage(colors),
                      if (payment.receiptImageUrl != null &&
                          payment.receiptImageUrl!.isNotEmpty)
                        const SizedBox(height: 16),
                      Text(
                        "Amount: ${payment.amount.toStringAsFixed(2)}",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: colors.textPrimary,
                        ),
                      ),
                      if (payment.discount > 0) ...[
                        const SizedBox(height: 4),
                        Text(
                          "Discount: ${payment.discount.toStringAsFixed(2)}",
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13.5,
                            color: colors.clear,
                          ),
                        ),
                      ],
                      const SizedBox(height: 6),
                      Text(
                        "Date: ${_formatDateTime(payment.date)}",
                        style: TextStyle(color: colors.textSecondary),
                      ),
                      if (payment.paymentMethod != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          "Method: ${Payment.paymentMethodToString(payment.paymentMethod!)}",
                          style: TextStyle(color: colors.textSecondary),
                        ),
                      ],
                      if (payment.description != null &&
                          payment.description!.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(
                          "Description:",
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
                    generating ? "তৈরি হচ্ছে..." : "Share Receipt",
                    style: TextStyle(color: colors.accent, fontWeight: FontWeight.w700),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text("Close", style: TextStyle(color: colors.textSecondary, fontWeight: FontWeight.w700)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildReceiptImage(AppColors colors) {
    try {
      final bytes = base64Decode(payment.receiptImageUrl!);
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: double.infinity,
          height: 200,
          child: Image.memory(
            bytes,
            fit: BoxFit.cover,
            gaplessPlayback: true,
            errorBuilder: (context, error, stackTrace) {
              return Center(
                child: Text('ছবি লোড করা যায়নি', style: TextStyle(color: colors.textSecondary)),
              );
            },
          ),
        ),
      );
    } catch (e) {
      return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
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
                              "-${payment.discount.toStringAsFixed(2)} discount",
                              style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: colors.clear),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        payment.description?.isNotEmpty == true
                            ? payment.description!
                            : (isPayment ? 'Payment' : 'Charge Added'),
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
