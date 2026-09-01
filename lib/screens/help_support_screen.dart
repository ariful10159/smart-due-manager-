import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/app_localizations.dart';
import '../models/legal_content.dart';
import '../services/app_config_service.dart';
import '../theme/app_colors.dart';
import '../widgets/app_settings_scope.dart';

class _FaqItem {
  const _FaqItem(this.question, this.answer);

  final String question;
  final String answer;
}

class _ContactChannel {
  const _ContactChannel({required this.icon, required this.label, required this.value, required this.onTap});

  final IconData icon;
  final String label;
  final String value;
  final void Function(String value) onTap;
}

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  // ✅ বিল্ট-ইন fallback — admin panel এর FAQ Management এ কিছু না থাকলে এই ৭টা দেখানো হয়।
  List<_FaqItem> _builtInFaqs(AppLocalizations l10n) => [
        _FaqItem(l10n.faq1Q, l10n.faq1A),
        _FaqItem(l10n.faq2Q, l10n.faq2A),
        _FaqItem(l10n.faq3Q, l10n.faq3A),
        _FaqItem(l10n.faq4Q, l10n.faq4A),
        _FaqItem(l10n.faq5Q, l10n.faq5A),
        _FaqItem(l10n.faq6Q, l10n.faq6A),
        _FaqItem(l10n.faq7Q, l10n.faq7A),
      ];

  List<_FaqItem> _faqsFromDocs(List<QueryDocumentSnapshot<Map<String, dynamic>>> docs, String languageCode) {
    final suffix = languageCode == 'en' ? 'En' : 'Bn';
    final otherSuffix = suffix == 'En' ? 'Bn' : 'En';
    final items = <_FaqItem>[];

    for (final doc in docs) {
      final data = doc.data();
      var question = (data['question$suffix'] as String? ?? '').trim();
      var answer = (data['answer$suffix'] as String? ?? '').trim();
      // ওই ভাষায় লেখা না থাকলে অন্য ভাষারটা fallback হিসেবে দেখানো হয়, খালি রাখার চেয়ে ভালো।
      if (question.isEmpty || answer.isEmpty) {
        question = (data['question$otherSuffix'] as String? ?? '').trim();
        answer = (data['answer$otherSuffix'] as String? ?? '').trim();
      }
      if (question.isNotEmpty && answer.isNotEmpty) {
        items.add(_FaqItem(question, answer));
      }
    }
    return items;
  }

  // ✅ App Config > Contact কার্ড থেকে admin যা যা সেট করেছে, শুধু সেই channel গুলোই
  // দেখানো হয়। কিছুই সেট না থাকলে সাপোর্ট ইমেইলে মেইল করার পুরনো ব্যবহার fallback থাকে।
  List<_ContactChannel> _contactChannels(AppLocalizations l10n, Map<String, dynamic> config) {
    final channels = [
      _ContactChannel(
        icon: Icons.email_outlined,
        label: l10n.contactSupportEmail,
        value: (config['supportEmail'] as String? ?? '').trim(),
        onTap: (v) => launchUrl(Uri(scheme: 'mailto', path: v)),
      ),
      _ContactChannel(
        icon: Icons.call_outlined,
        label: l10n.contactSupportPhone,
        value: (config['supportPhone'] as String? ?? '').trim(),
        onTap: (v) => launchUrl(Uri(scheme: 'tel', path: v)),
      ),
      _ContactChannel(
        icon: Icons.chat_outlined,
        label: l10n.contactWhatsapp,
        value: (config['whatsapp'] as String? ?? '').trim(),
        onTap: (v) => launchUrl(
          Uri.parse('https://wa.me/${v.replaceAll(RegExp(r'[^0-9]'), '')}'),
          mode: LaunchMode.externalApplication,
        ),
      ),
    ].where((c) => c.value.isNotEmpty).toList();

    if (channels.isNotEmpty) return channels;

    // Fallback — appConfig খালি থাকলে LegalContent এর হার্ডকোড করা সাপোর্ট ইমেইল
    return [
      _ContactChannel(
        icon: Icons.mail_outline_rounded,
        label: l10n.contactSupportEmail,
        value: LegalContent.supportEmail,
        onTap: (v) => launchUrl(Uri(scheme: 'mailto', path: v)),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final l10n = AppLocalizations.of(context)!;
    final languageCode = AppSettingsScope.settingsOf(context).languageCode;

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
      // ✅ .snapshots() (StreamBuilder) ব্যবহার করা হয়েছে .get() (FutureBuilder) এর
      // বদলে — Firestore এর লোকাল cache থেকে দ্বিতীয়বার থেকে প্রায় সাথে সাথেই ডেটা
      // দেখায়, প্রতিবার নতুন করে সার্ভার রাউন্ড-ট্রিপের অপেক্ষা করতে হয় না। আর প্রথমবার
      // লোড হওয়ার সময় সংক্ষিপ্ত loading দেখানো হয়, ভুল করে বিল্ট-ইন FAQ আগে দেখিয়ে
      // পরে বদলে ফেলার (flash) সমস্যা এড়াতে।
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('faqs').orderBy('order').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];
          final faqs = docs.isNotEmpty ? _faqsFromDocs(docs, languageCode) : _builtInFaqs(l10n);

          return FutureBuilder<Map<String, dynamic>>(
            future: AppConfigService.fetchOnce(),
            builder: (context, configSnapshot) {
              final channels = _contactChannels(l10n, configSnapshot.data ?? {});
              return _buildBody(context, colors, l10n, faqs, channels);
            },
          );
        },
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    AppColors colors,
    AppLocalizations l10n,
    List<_FaqItem> faqs,
    List<_ContactChannel> channels,
  ) {
    return ListView(
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
          Container(
            decoration: BoxDecoration(
              color: colors.surfaceAlt,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                for (int i = 0; i < channels.length; i++) ...[
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => channels[i].onTap(channels[i].value),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Icon(channels[i].icon, color: colors.info, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                '${channels[i].label}: ${channels[i].value}',
                                style: TextStyle(
                                  color: colors.textSecondary,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  height: 1.5,
                                ),
                              ),
                            ),
                            Icon(Icons.chevron_right_rounded, color: colors.textSecondary, size: 20),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (i != channels.length - 1)
                    Divider(color: colors.borderColor, height: 1, indent: 16, endIndent: 16),
                ],
              ],
            ),
          ),
        ],
    );
  }
}
