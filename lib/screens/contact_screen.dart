import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:url_launcher/url_launcher.dart';

import '../l10n/app_localizations.dart';
import '../services/app_config_service.dart';
import '../theme/app_colors.dart';

class ContactScreen extends StatelessWidget {
  const ContactScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: colors.scaffoldBg,
      appBar: AppBar(
        title: Text(
          l10n.contactTitle,
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: colors.textPrimary),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: colors.textPrimary),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: AppConfigService.fetchOnce(),
        builder: (context, snapshot) {
          final config = snapshot.data ?? {};
          final rows = [
            _ContactRow(
              icon: Icons.email_outlined,
              label: l10n.contactSupportEmail,
              value: (config['supportEmail'] as String? ?? '').trim(),
              onTap: (v) => launchUrl(Uri(scheme: 'mailto', path: v)),
            ),
            _ContactRow(
              icon: Icons.call_outlined,
              label: l10n.contactSupportPhone,
              value: (config['supportPhone'] as String? ?? '').trim(),
              onTap: (v) => launchUrl(Uri(scheme: 'tel', path: v)),
            ),
            _ContactRow(
              icon: Icons.chat_outlined,
              label: l10n.contactWhatsapp,
              value: (config['whatsapp'] as String? ?? '').trim(),
              onTap: (v) => launchUrl(
                Uri.parse('https://wa.me/${v.replaceAll(RegExp(r'[^0-9]'), '')}'),
                mode: LaunchMode.externalApplication,
              ),
            ),
            _ContactRow(
              icon: Icons.facebook_outlined,
              label: l10n.contactFacebook,
              value: (config['facebook'] as String? ?? '').trim(),
              onTap: (v) => launchUrl(Uri.parse(v), mode: LaunchMode.externalApplication),
            ),
            _ContactRow(
              icon: Icons.language_outlined,
              label: l10n.contactWebsite,
              value: (config['website'] as String? ?? '').trim(),
              onTap: (v) => launchUrl(Uri.parse(v), mode: LaunchMode.externalApplication),
            ),
          ].where((r) => r.value.isNotEmpty).toList();

          if (rows.isEmpty) {
            return Center(
              child: Text(l10n.noContactInfo, style: TextStyle(color: colors.textSecondary, fontSize: 13.5)),
            );
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
            children: [
              Container(
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: colors.borderColor),
                ),
                child: Column(
                  children: [
                    for (int i = 0; i < rows.length; i++) ...[
                      _buildRow(context, colors, rows[i]),
                      if (i != rows.length - 1) Divider(color: colors.borderColor, height: 1, indent: 16, endIndent: 16),
                    ],
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildRow(BuildContext context, AppColors colors, _ContactRow row) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => row.onTap(row.value),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
          children: [
            const SizedBox(width: 8),
            Icon(row.icon, color: colors.accent, size: 20),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(row.label, style: TextStyle(color: colors.textSecondary, fontSize: 12)),
                  const SizedBox(height: 2),
                  Text(
                    row.value,
                    style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(Icons.copy_rounded, color: colors.textSecondary, size: 19),
              tooltip: AppLocalizations.of(context)!.copyLabel,
              onPressed: () => _copyToClipboard(context, row.value),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _copyToClipboard(BuildContext context, String value) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context)!.copiedToClipboard), duration: const Duration(seconds: 2)),
    );
  }
}

class _ContactRow {
  const _ContactRow({required this.icon, required this.label, required this.value, required this.onTap});

  final IconData icon;
  final String label;
  final String value;
  final void Function(String value) onTap;
}
