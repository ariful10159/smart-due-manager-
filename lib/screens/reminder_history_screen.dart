import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/customer_repository.dart';

class ReminderHistoryScreen extends StatelessWidget {
  final String customerId;

  const ReminderHistoryScreen({
    super.key,
    required this.customerId,
  });

  @override
  Widget build(BuildContext context) {
    final repo = CustomerRepository();

    return Scaffold(
      appBar: AppBar(
        title: const Text("রিমাইন্ডার হিস্ট্রি"),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: repo.streamReminderHistory(customerId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
                child: CircularProgressIndicator());
          }

          final reminders = snapshot.data!;

          if (reminders.isEmpty) {
            return const Center(
              child: Text("কোনো রিমাইন্ডার হিস্ট্রি নেই"),
            );
          }

          return ListView.builder(
            itemCount: reminders.length,
            itemBuilder: (context, index) {
              final reminder = reminders[index];

              final timestamp =
                  reminder['reminderDate'];

              final dateTime =
                  timestamp is Timestamp
                      ? timestamp.toDate()
                      : timestamp as DateTime;

              final formattedDate =
                  DateFormat(
                          'd MMM yyyy • hh:mm a')
                      .format(dateTime);

              final status = reminder['status'] == 'active'
                  ? 'সক্রিয়'
                  : reminder['status'] == 'expired'
                      ? 'মেয়াদোত্তীর্ণ'
                      : reminder['status'];

              return ListTile(
                title: Text(formattedDate),
                subtitle: Text("স্ট্যাটাস: $status"),
              );
            },
          );
        },
      ),
    );
  }
}