import 'package:flutter/material.dart';
import '../models/payment.dart';

class PaymentHistoryTile extends StatelessWidget {
  const PaymentHistoryTile({super.key, required this.payment});

  final Payment payment;

  @override
  Widget build(BuildContext context) {
    final isPayment = payment.type == PaymentType.payment;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ✅ Top Row: Type + Amount
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor:
                          isPayment ? Colors.green : Colors.red,
                      child: Icon(
                        isPayment
                            ? Icons.arrow_downward
                            : Icons.arrow_upward,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isPayment ? 'Payment' : 'Charge Added',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isPayment ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
                Text(
                  '${isPayment ? '-' : '+'} ${payment.amount.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: isPayment ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),

            const Divider(height: 16),

            // ✅ Payment Method
            if (payment.paymentMethod != null) ...[
              Row(
                children: [
                  const Icon(Icons.payment, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    Payment.paymentMethodToString(payment.paymentMethod!),
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 4),
            ],

            // ✅ Note
            if (payment.note != null) ...[
              Row(
                children: [
                  const Icon(Icons.note, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    payment.note!,
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 4),
            ],

            // ✅ Description
            if (payment.description != null) ...[
              Row(
                children: [
                  const Icon(Icons.description,
                      size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      payment.description!,
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
            ],

            // ✅ Date
            Row(
              children: [
                const Icon(Icons.calendar_today,
                    size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  _formatDate(payment.date),
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ✅ Format Date
  String _formatDate(DateTime date) {
    return '${date.day}-${date.month}-${date.year} '
        '${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}