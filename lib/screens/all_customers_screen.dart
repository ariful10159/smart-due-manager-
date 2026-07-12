import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/customer.dart';
import '../models/customer_repository.dart';
import 'customer_detail_screen.dart';

class AllCustomersScreen extends StatelessWidget {
  const AllCustomersScreen({super.key, this.repository});

  final CustomerRepository? repository;

  Future<void> _callCustomer(
    BuildContext context,
    String phoneNumber,
  ) async {
    final phone = phoneNumber
        .trim()
        .replaceAll(RegExp(r'[\s()-]'), '');

    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Customer phone number is not available'),
        ),
      );
      return;
    }

    final phoneUri = Uri(
      scheme: 'tel',
      path: phone,
    );

    try {
      final launched = await launchUrl(
        phoneUri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open phone dialer'),
          ),
        );
      }
    } catch (error) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not make call: $error'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final repo = repository ?? CustomerRepository();

    return Scaffold(
      appBar: AppBar(
        title: const Text('All Customers'),
      ),
      body: StreamBuilder<List<Customer>>(
        stream: repo.streamCustomers(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          final customers = snapshot.data ?? [];

          if (customers.isEmpty) {
            return const Center(
              child: Text('No customers found'),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: customers.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final customer = customers[index];

              return Card(
                margin: EdgeInsets.zero,
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),

                  // Customer avatar
                  leading: const CircleAvatar(
                    child: Icon(Icons.person),
                  ),

                  // Customer name and phone
                  title: Text(
                    customer.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(customer.phone),

                  // Due amount + Call button
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        customer.totalDue.toStringAsFixed(2),
                        style: TextStyle(
                          color: customer.totalDue > 0
                              ? Colors.red
                              : Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        tooltip: 'Call customer',
                        onPressed: () {
                          _callCustomer(
                            context,
                            customer.phone,
                          );
                        },
                        icon: const Icon(
                          Icons.call,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),

                  // Customer details screen
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => CustomerDetailScreen(
                          customer: customer,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}