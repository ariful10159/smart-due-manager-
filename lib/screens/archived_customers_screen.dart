import 'package:flutter/material.dart';

import '../models/customer.dart';
import '../models/customer_repository.dart';

class ArchivedCustomersScreen extends StatefulWidget {
  const ArchivedCustomersScreen({super.key});

  @override
  State<ArchivedCustomersScreen> createState() =>
      _ArchivedCustomersScreenState();
}

class _ArchivedCustomersScreenState extends State<ArchivedCustomersScreen> {
  final _customerRepo = CustomerRepository();

  Future<void> _confirmRestore(Customer customer) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Restore Customer"),
        content: Text(
          "'${customer.name}' কে আবার active list এ ফিরিয়ে আনতে চান?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Restore"),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _restoreCustomer(customer);
    }
  }

  Future<void> _restoreCustomer(Customer customer) async {
    try {
      await _customerRepo.restoreCustomer(customer.id);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.green,
          content: Text("${customer.name} restored successfully"),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text("Restore failed: $e"),
        ),
      );
    }
  }

  Future<void> _confirmPermanentDelete(Customer customer) async {
    // ধাপ ১ — প্রথম confirmation
    final firstConfirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Permanently"),
        content: Text(
          "'${customer.name}' কে স্থায়ীভাবে ডিলিট করতে চান? "
          "এর সব payment history ও reminder ডেটা সম্পূর্ণ মুছে যাবে। "
          "এটি আর কখনো ফেরত পাওয়া যাবে না।",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              "Continue",
              style: TextStyle(color: Colors.red),
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
        title: const Text("একদম নিশ্চিত?"),
        content: const Text(
          "এই কাজটি Undo করা যাবে না। সত্যিই স্থায়ীভাবে ডিলিট করতে চান?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              "Yes, Delete Forever",
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
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
    try {
      await _customerRepo.deleteCustomerPermanently(customer.id);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.green,
          content: Text("${customer.name} permanently deleted"),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text("Delete failed: $e"),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Archived Customers"),
        centerTitle: true,
      ),
      body: StreamBuilder<List<Customer>>(
        stream: _customerRepo.streamHiddenCustomers(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final customers = snapshot.data!;

          if (customers.isEmpty) {
            return const Center(
              child: Text(
                "কোনো Archived customer নেই",
                style: TextStyle(color: Colors.grey),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: customers.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final customer = customers[index];

              return Card(
                child: ListTile(
                  title: Text(
                    customer.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    "${customer.phone}\nTotal Due: ${customer.totalDue.toStringAsFixed(2)}",
                  ),
                  isThreeLine: true,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.restore, color: Colors.green),
                        tooltip: "Restore",
                        onPressed: () => _confirmRestore(customer),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_forever, color: Colors.red),
                        tooltip: "Delete Permanently",
                        onPressed: () => _confirmPermanentDelete(customer),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}