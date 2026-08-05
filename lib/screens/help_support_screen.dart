import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/legal_content.dart';
import '../theme/app_colors.dart';

class _FaqItem {
  const _FaqItem(this.question, this.answer);

  final String question;
  final String answer;
}

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  static const List<_FaqItem> _faqs = [
    _FaqItem(
      'SMS রিমাইন্ডার কীভাবে কাজ করে?',
      'রিমাইন্ডার SMS আপনার ফোনের নিজস্ব SIM থেকে পাঠানো হয়। অ্যাপ প্রতিটা কাস্টমারের জন্য '
      'আলাদাভাবে SMS app খুলে মেসেজ prefilled অবস্থায় দেখায়, আপনাকে নিজে Send বাটনে চাপতে হয় '
      '— Play Store নীতি অনুযায়ী অ্যাপ নিজে থেকে bulk SMS পাঠাতে পারে না।',
    ),
    _FaqItem(
      'আমার ডেটা কি নিরাপদ?',
      'হ্যাঁ। সব ডেটা Firebase (Google Cloud) এ সংরক্ষিত হয়। App Lock এর জন্য ব্যবহৃত PIN '
      'ফোনেই সল্টেড হ্যাশ আকারে রাখা হয়, প্লেইনটেক্সটে কখনো সংরক্ষিত হয় না।',
    ),
    _FaqItem(
      'ডেটা ব্যাকআপ কীভাবে নেব?',
      'Settings → Data Backup এ গিয়ে আপনার কাস্টমার ও পেমেন্ট ডেটা CSV ফাইল হিসেবে '
      'এক্সপোর্ট করতে পারবেন।',
    ),
    _FaqItem(
      'App Lock কীভাবে চালু করব?',
      'Settings → App Lock এ গিয়ে একটা PIN সেট করুন। এরপর থেকে অ্যাপ ব্যাকগ্রাউন্ডে গেলে বা '
      'বন্ধ করে আবার খুললে PIN বা বায়োমেট্রিক দিয়ে আনলক করতে হবে।',
    ),
    _FaqItem(
      'কাস্টমার Archive করলে কী হয়?',
      'Archive করা কাস্টমার active list থেকে সরে যায় কিন্তু ডেটা মুছে যায় না। Drawer এর '
      '"Archived Customers" থেকে যেকোনো সময় আবার Restore করতে পারবেন, অথবা চাইলে স্থায়ীভাবে '
      'ডিলিট করতে পারবেন।',
    ),
    _FaqItem(
      'কারেন্সি বা থিম কালার পরিবর্তন করব কীভাবে?',
      'Settings → কারেন্সি থেকে টাকার চিহ্ন, আর Settings → থিম কালার থেকে অ্যাপের রঙ '
      'পরিবর্তন করা যাবে। Dark/Light মোডও Settings → অ্যাপ মোড থেকে বদলানো যায় (অথবা Drawer '
      'এর কুইক টগল থেকেও)।',
    ),
    _FaqItem(
      'Notebook ফিচারটা কী কাজে লাগে?',
      'হিসাব-নিকাশের বাইরেও যদি কোনো নোট, মনে রাখার তথ্য লিখে রাখতে চান, তার জন্যই Notebook '
      'ফিচার — এটি কাস্টমার ডেটা থেকে সম্পূর্ণ আলাদা।',
    ),
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
        const SnackBar(content: Text('ইমেইল অ্যাপ পাওয়া যায়নি')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Scaffold(
      backgroundColor: colors.scaffoldBg,
      appBar: AppBar(
        title: Text(
          "Help & Support",
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
            "প্রায়ই জিজ্ঞাসিত প্রশ্ন",
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
                  for (int i = 0; i < _faqs.length; i++) ...[
                    ExpansionTile(
                      iconColor: colors.accent,
                      collapsedIconColor: colors.textSecondary,
                      title: Text(
                        _faqs[i].question,
                        style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w700, fontSize: 13.5),
                      ),
                      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      expandedAlignment: Alignment.topLeft,
                      children: [
                        Text(
                          _faqs[i].answer,
                          style: TextStyle(color: colors.textSecondary, fontSize: 13, height: 1.55),
                        ),
                      ],
                    ),
                    if (i != _faqs.length - 1) Divider(color: colors.borderColor, height: 1, indent: 16, endIndent: 16),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          Text(
            "আরও সাহায্য দরকার?",
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
                        "সরাসরি যোগাযোগ করুন: ${LegalContent.supportEmail}",
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
