import 'package:flutter/material.dart';

import '../models/payment.dart';

class PaymentHistoryTile extends StatelessWidget {
  const PaymentHistoryTile({super.key, required this.payment});

  final Payment payment;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(payment.amount.toStringAsFixed(2)),
        subtitle: Text(payment.note ?? payment.type.name),
        trailing: Text(payment.date.toLocal().toString()),
      ),
    );
  }
}
