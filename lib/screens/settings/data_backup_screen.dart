import 'package:flutter/material.dart';

import '../../models/customer_repository.dart';
import '../../services/backup_service.dart';
import '../../theme/app_colors.dart';

class DataBackupScreen extends StatefulWidget {
  const DataBackupScreen({super.key});

  @override
  State<DataBackupScreen> createState() => _DataBackupScreenState();
}

class _DataBackupScreenState extends State<DataBackupScreen> {
  bool _exportingBackup = false;
  bool _importingBackup = false;

  Future<void> _exportBackup() async {
    setState(() => _exportingBackup = true);
    try {
      final customers = await CustomerRepository().fetchCustomersOnce();
      await BackupService.exportCustomersToCsv(customers);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('এক্সপোর্ট ব্যর্থ, আবার চেষ্টা করুন')),
      );
    } finally {
      if (mounted) setState(() => _exportingBackup = false);
    }
  }

  Future<void> _importBackup() async {
    final csvContent = await BackupService.pickCsvFileContent();
    if (csvContent == null) return; // ইউজার বাতিল করেছে

    final parsed = BackupService.parseCustomersFromCsv(csvContent);
    if (parsed.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ফাইলে কোনো বৈধ কাস্টমার পাওয়া যায়নি')),
      );
      return;
    }

    if (!mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Import নিশ্চিত করুন'),
        content: Text(
          '${parsed.length} জন কাস্টমার পাওয়া গেছে। এগুলো আপনার অ্যাকাউন্টে যোগ করা হবে '
          '(যাদের ফোন নাম্বার ইতিমধ্যে আছে, তারা duplicate হিসেবে বাদ যাবে)। এগিয়ে যাবেন?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('বাতিল'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Import করুন'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _importingBackup = true);
    try {
      final result = await CustomerRepository().importCustomers(parsed);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${result.imported} জন import হয়েছে'
            '${result.skipped > 0 ? ', ${result.skipped} জন duplicate হিসেবে বাদ গেছে' : ''}',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Import ব্যর্থ, আবার চেষ্টা করুন')),
      );
    } finally {
      if (mounted) setState(() => _importingBackup = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Scaffold(
      backgroundColor: colors.scaffoldBg,
      appBar: AppBar(
        title: Text(
          "Data Backup",
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 19, color: colors.textPrimary),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: colors.textPrimary),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            "সব কাস্টমারের তথ্য CSV ফাইল হিসেবে এক্সপোর্ট করুন — Excel/Google Sheets এ খোলা যাবে। "
            "আগে এক্সপোর্ট করা CSV ফাইল থেকে কাস্টমার ফিরিয়ে আনতেও (Restore) পারবেন।",
            style: TextStyle(color: colors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _exportingBackup ? null : _exportBackup,
              style: OutlinedButton.styleFrom(
                foregroundColor: colors.textPrimary,
                side: BorderSide(color: colors.borderColor),
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: _exportingBackup
                  ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: colors.accent))
                  : const Icon(Icons.file_download_rounded, size: 18),
              label: Text(_exportingBackup ? "এক্সপোর্ট হচ্ছে..." : "CSV এক্সপোর্ট করুন", style: const TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _importingBackup ? null : _importBackup,
              style: OutlinedButton.styleFrom(
                foregroundColor: colors.textPrimary,
                side: BorderSide(color: colors.borderColor),
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: _importingBackup
                  ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: colors.accent))
                  : const Icon(Icons.file_upload_rounded, size: 18),
              label: Text(_importingBackup ? "Import হচ্ছে..." : "CSV থেকে Restore করুন", style: const TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}
