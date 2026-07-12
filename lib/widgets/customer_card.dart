import 'package:flutter/material.dart';

import '../models/customer.dart';

class CustomerCard extends StatelessWidget {
  const CustomerCard({super.key, required this.customer, this.onTap});

  final Customer customer;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: onTap,
        title: Text(customer.name),
        subtitle: Text(customer.phone),
        trailing: Text(customer.totalDue.toStringAsFixed(2)),
      ),
    );
  }
}
