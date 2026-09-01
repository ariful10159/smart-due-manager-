import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/legal_content.dart';
import '../services/app_config_service.dart';
import '../widgets/app_settings_scope.dart';
import '../widgets/legal_document_view.dart';

// ✅ Admin panel এর App Config > Terms & Conditions কার্ড থেকে plain-text override
// পাবলিশ করা থাকলে সেটা দেখায়; নাহলে অ্যাপের বিল্ট-ইন, sectioned bilingual
// কনটেন্ট (legal_content.dart) fallback হিসেবে দেখায়।
class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final languageCode = AppSettingsScope.settingsOf(context).languageCode;
    final title = AppLocalizations.of(context)!.termsOfServiceTitle;

    return FutureBuilder<Map<String, dynamic>>(
      future: AppConfigService.fetchOnce(),
      builder: (context, snapshot) {
        final config = snapshot.data ?? {};
        final override = (languageCode == 'en' ? config['termsEn'] : config['termsBn']) as String?;

        final sections = (override?.trim().isNotEmpty ?? false)
            ? [LegalSection(title, override!.trim())]
            : LegalContent.termsOfService(languageCode);

        return LegalDocumentView(title: title, sections: sections, icon: Icons.gavel_rounded);
      },
    );
  }
}
