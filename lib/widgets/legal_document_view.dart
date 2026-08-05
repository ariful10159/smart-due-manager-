import 'package:flutter/material.dart';

import '../models/legal_content.dart';
import '../theme/app_colors.dart';

/// ✅ Privacy Policy ও Terms of Service — দুটো স্ক্রিনই এই একই লেআউট শেয়ার করে,
/// শুধু টাইটেল আর সেকশন কনটেন্ট আলাদা।
class LegalDocumentView extends StatelessWidget {
  const LegalDocumentView({
    super.key,
    required this.title,
    required this.sections,
  });

  final String title;
  final List<LegalSection> sections;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Scaffold(
      backgroundColor: colors.scaffoldBg,
      appBar: AppBar(
        title: Text(
          title,
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: colors.textPrimary),
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
            "সর্বশেষ আপডেট: ${LegalContent.lastUpdated}",
            style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 18),
          for (final section in sections) ...[
            Text(
              section.heading,
              style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w800, fontSize: 15),
            ),
            const SizedBox(height: 6),
            Text(
              section.body,
              style: TextStyle(color: colors.textSecondary, fontSize: 13.5, height: 1.5),
            ),
            const SizedBox(height: 20),
          ],
        ],
      ),
    );
  }
}
