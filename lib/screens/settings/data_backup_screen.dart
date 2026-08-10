import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
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
        SnackBar(content: Text(AppLocalizations.of(context)!.exportFailed)),
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
        SnackBar(content: Text(AppLocalizations.of(context)!.noValidCustomersFound)),
      );
      return;
    }

    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.confirmImportTitle),
        content: Text(l10n.confirmImportBody(parsed.length)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.importAction),
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
            l10n.importedResult(result.imported) +
                (result.skipped > 0 ? l10n.skippedSuffix(result.skipped) : ''),
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.importFailed)),
      );
    } finally {
      if (mounted) setState(() => _importingBackup = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: colors.scaffoldBg,
      appBar: AppBar(
        title: Text(
          l10n.dataBackup,
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
            l10n.dataBackupDesc,
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
              label: Text(_exportingBackup ? l10n.exportingLabel : l10n.exportCsv, style: const TextStyle(fontWeight: FontWeight.w700)),
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
              label: Text(_importingBackup ? l10n.importingLabel : l10n.restoreCsv, style: const TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}
