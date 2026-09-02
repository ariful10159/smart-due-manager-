import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/problem_report_service.dart';
import '../theme/app_colors.dart';

class ReportProblemScreen extends StatefulWidget {
  const ReportProblemScreen({super.key});

  @override
  State<ReportProblemScreen> createState() => _ReportProblemScreenState();
}

class _ReportProblemScreenState extends State<ReportProblemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();

  late String _category;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _category = _categories.first;
  }

  List<String> get _categories => const [
        'Bug / App Crash',
        'Payment Issue',
        'Notification / Reminder Issue',
        'Feature Request',
        'Other',
      ];

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    try {
      await ProblemReportService.submit(
        category: _category,
        description: _descriptionController.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.reportProblemSubmitted)),
      );
      Navigator.pop(context);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.reportProblemFailed)),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  InputDecoration _decoration(AppColors colors, {required String labelText, required IconData icon}) {
    return InputDecoration(
      labelText: labelText,
      labelStyle: TextStyle(color: colors.textSecondary, fontSize: 14, fontWeight: FontWeight.w500),
      prefixIcon: Icon(icon, color: colors.accent, size: 22),
      filled: true,
      fillColor: colors.surfaceAlt,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: colors.borderColor, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: colors.accent, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: colors.due, width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: colors.scaffoldBg,
      appBar: AppBar(
        title: Text(
          l10n.reportProblemTitle,
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: colors.textPrimary),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: colors.textPrimary),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
          children: [
            Text(
              l10n.reportProblemSubtitle,
              style: TextStyle(color: colors.textSecondary, fontSize: 13, height: 1.5),
            ),
            const SizedBox(height: 20),

            Text(
              l10n.reportProblemCategory,
              style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w700, fontSize: 13.5),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _category,
              dropdownColor: colors.surface,
              style: TextStyle(color: colors.textPrimary, fontSize: 14),
              decoration: _decoration(colors, labelText: l10n.reportProblemCategory, icon: Icons.category_outlined),
              items: _categories
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (value) {
                if (value != null) setState(() => _category = value);
              },
            ),
            const SizedBox(height: 16),

            Text(
              l10n.reportProblemDescription,
              style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w700, fontSize: 13.5),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _descriptionController,
              style: TextStyle(color: colors.textPrimary, fontSize: 14),
              maxLines: 6,
              minLines: 5,
              decoration: _decoration(
                colors,
                labelText: l10n.reportProblemDescriptionHint,
                icon: Icons.notes_rounded,
              ),
              validator: (value) {
                if (value == null || value.trim().length < 10) {
                  return l10n.reportProblemDescriptionError;
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            _isSubmitting
                ? Center(child: CircularProgressIndicator(color: colors.accent))
                : Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(colors: [colors.accent, colors.accentAlt]),
                      boxShadow: [
                        BoxShadow(
                          color: colors.accent.withValues(alpha: 0.35),
                          blurRadius: 15,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: _submit,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.send_rounded, size: 20, color: Colors.white),
                              const SizedBox(width: 8),
                              Text(
                                l10n.reportProblemSubmit,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.3,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
