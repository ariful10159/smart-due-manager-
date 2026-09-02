import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../models/customer_repository.dart';
import '../../services/account_deletion_service.dart';
import '../../theme/app_colors.dart';

class DeleteAccountScreen extends StatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  State<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends State<DeleteAccountScreen> {
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _acknowledged = false;
  bool _deleting = false;

  int? _customerCount;

  @override
  void initState() {
    super.initState();
    // ✅ কতজন কাস্টমারের ডেটা হারাবেন সেটা concrete সংখ্যায় দেখানোর জন্য —
    // fail করলেও ক্ষতি নেই, শুধু সংখ্যাটা না দেখিয়ে সাধারণ warning-ই থাকবে
    CustomerRepository().fetchCustomersOnce().then((customers) {
      if (mounted) setState(() => _customerCount = customers.length);
    }).catchError((_) {});
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _confirmAndDelete() async {
    final l10n = AppLocalizations.of(context)!;
    final colors = AppColors.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: colors.borderColor),
        ),
        title: Text(
          l10n.deleteAccountFinalConfirmTitle,
          style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w800),
        ),
        content: Text(
          l10n.deleteAccountFinalConfirmBody,
          style: TextStyle(color: colors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.cancel, style: TextStyle(color: colors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(
              l10n.deleteAccount,
              style: TextStyle(color: colors.due, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _deleting = true);
    final error = await AccountDeletionService.deleteAccountAndAllData(
      currentPassword: _passwordController.text,
    );

    if (!mounted) return;

    if (error != null) {
      setState(() => _deleting = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      return;
    }

    // ✅ user.delete() ইতিমধ্যে sign-out করে দিয়েছে। আগে এখানে সরাসরি LoginScreen()
    // push করে root route (AppConfigGate/AppLockGate/AuthWrapper সমেত) মুছে
    // ফেলা হতো — এখন root এ popUntil করে ফেরত যাওয়া হচ্ছে (এটাও পেছনের সব স্ক্রিন
    // stack থেকে সরায়, শুধু root-টা বাদে), AuthWrapper অক্ষত থেকে নিজে থেকেই
    // LoginScreen দেখায়
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final l10n = AppLocalizations.of(context)!;
    final canSubmit = _acknowledged && _passwordController.text.isNotEmpty && !_deleting;

    return Scaffold(
      backgroundColor: colors.scaffoldBg,
      appBar: AppBar(
        title: Text(
          l10n.deleteAccount,
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: colors.textPrimary),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: colors.textPrimary),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colors.due.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: colors.due.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: colors.due, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        l10n.deleteAccountWarningTitle,
                        style: TextStyle(color: colors.due, fontWeight: FontWeight.w800, fontSize: 14.5),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _customerCount != null
                        ? l10n.deleteAccountWarningBodyWithCount(_customerCount!)
                        : l10n.deleteAccountWarningBody,
                    style: TextStyle(color: colors.textSecondary, fontSize: 13, height: 1.4),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: _deleting ? null : () => setState(() => _acknowledged = !_acknowledged),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Checkbox(
                      value: _acknowledged,
                      activeColor: colors.due,
                      onChanged: _deleting ? null : (v) => setState(() => _acknowledged = v ?? false),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text(
                          l10n.deleteAccountAcknowledge,
                          style: TextStyle(color: colors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),

            TextField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              enabled: !_deleting,
              onChanged: (_) => setState(() {}),
              style: TextStyle(color: colors.textPrimary),
              decoration: InputDecoration(
                filled: true,
                fillColor: colors.surfaceAlt,
                labelText: l10n.currentPasswordLabel,
                labelStyle: TextStyle(color: colors.textSecondary),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                    color: colors.textSecondary,
                  ),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colors.borderColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colors.borderColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colors.due, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: canSubmit ? _confirmAndDelete : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.due,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: colors.due.withValues(alpha: 0.35),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _deleting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
                      )
                    : Text(l10n.deleteAccount, style: const TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
