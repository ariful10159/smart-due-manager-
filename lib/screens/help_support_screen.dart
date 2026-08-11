import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/app_localizations.dart';
import '../models/legal_content.dart';
import '../theme/app_colors.dart';

class _FaqItem {
  const _FaqItem(this.question, this.answer);

  final String question;
  final String answer;
}

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  List<_FaqItem> _faqs(AppLocalizations l10n) => [
        _FaqItem(l10n.faq1Q, l10n.faq1A),
        _FaqItem(l10n.faq2Q, l10n.faq2A),
        _FaqItem(l10n.faq3Q, l10n.faq3A),
        _FaqItem(l10n.faq4Q, l10n.faq4A),
        _FaqItem(l10n.faq5Q, l10n.faq5A),
        _FaqItem(l10n.faq6Q, l10n.faq6A),
        _FaqItem(l10n.faq7Q, l10n.faq7A),
      ];

  Future<void> _sendFeedback(BuildContext context) async {
    final uri = Uri(
      scheme: 'mailto',
      path: LegalContent.supportEmail,
      query: 'subject=${Uri.encodeComponent("${LegalContent.appName} - Feedback")}',
    );

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.emailAppNotFound)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final l10n = AppLocalizations.of(context)!;
    final faqs = _faqs(l10n);

    return Scaffold(
      backgroundColor: colors.scaffoldBg,
      appBar: AppBar(
        title: Text(
          l10n.drawerHelp,
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: colors.textPrimary),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: colors.textPrimary),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          Text(
            l10n.frequentlyAskedQuestions,
            style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w800, fontSize: 15),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [colors.surface, colors.surfaceAlt],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colors.borderColor),
            ),
            child: Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: Column(
                children: [
                  for (int i = 0; i < faqs.length; i++) ...[
                    ExpansionTile(
                      iconColor: colors.accent,
                      collapsedIconColor: colors.textSecondary,
                      title: Text(
                        faqs[i].question,
                        style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w700, fontSize: 13.5),
                      ),
                      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      expandedAlignment: Alignment.topLeft,
                      children: [
                        Text(
                          faqs[i].answer,
                          style: TextStyle(color: colors.textSecondary, fontSize: 13, height: 1.55),
                        ),
                      ],
                    ),
                    if (i != faqs.length - 1) Divider(color: colors.borderColor, height: 1, indent: 16, endIndent: 16),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          Text(
            l10n.needMoreHelp,
            style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w800, fontSize: 15),
          ),
          const SizedBox(height: 12),
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => _sendFeedback(context),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colors.surfaceAlt,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Icon(Icons.mail_outline_rounded, color: colors.info, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        l10n.contactDirectly(LegalContent.supportEmail),
                        style: TextStyle(color: colors.textSecondary, fontSize: 12.5, fontWeight: FontWeight.w600, height: 1.5),
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded, color: colors.textSecondary, size: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
