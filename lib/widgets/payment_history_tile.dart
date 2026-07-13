import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/payment.dart';

class PaymentHistoryTile extends StatelessWidget {
  const PaymentHistoryTile({super.key, required this.payment});

  final Payment payment;

  String _formatDateTime(DateTime date) {
    return DateFormat('d MMMM yyyy • hh:mm a').format(date);
  }

  void _showPaymentDetail(BuildContext context) {
    showDialog(
      context: context,
      useSafeArea: true,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          payment.type == PaymentType.payment ? 'Payment' : 'Charge Added',
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
                  _buildReceiptImage(),
                if (payment.receiptImageUrl != null &&
                    payment.receiptImageUrl!.isNotEmpty)
                  const SizedBox(height: 16),
                Text(
                  "Amount: ${payment.amount.toStringAsFixed(2)}",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 6),
                Text("Date: ${_formatDateTime(payment.date)}"),
                if (payment.paymentMethod != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    "Method: ${Payment.paymentMethodToString(payment.paymentMethod!)}",
                  ),
                ],
                if (payment.description != null &&
                    payment.description!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Text(
                    "Description:",
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(payment.description!),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }

  Widget _buildReceiptImage() {
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
              return const Center(child: Text('ছবি লোড করা যায়নি'));
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
    final isPayment = payment.type == PaymentType.payment;

    return Card(
      child: ListTile(
        onTap: () {
          // ✅ পরের frame এ dialog খোলা হচ্ছে, current build/layout এর সাথে conflict এড়াতে
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) {
              _showPaymentDetail(context);
            }
          });
        },
        leading: Icon(
          isPayment ? Icons.arrow_downward : Icons.arrow_upward,
          color: isPayment ? Colors.green : Colors.red,
        ),
        title: Text(
          payment.amount.toStringAsFixed(2),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          payment.description?.isNotEmpty == true
              ? payment.description!
              : (isPayment ? 'Payment' : 'Charge Added'),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              DateFormat('d MMM yyyy').format(payment.date),
              style: const TextStyle(fontSize: 12),
            ),
            if (payment.receiptImageUrl != null &&
                payment.receiptImageUrl!.isNotEmpty)
              const Icon(Icons.photo, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}