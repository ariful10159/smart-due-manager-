import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/legal_content.dart';
import '../widgets/app_settings_scope.dart';
import '../widgets/legal_document_view.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final languageCode = AppSettingsScope.settingsOf(context).languageCode;
    return LegalDocumentView(
      title: AppLocalizations.of(context)!.privacyPolicyTitle,
      sections: LegalContent.privacyPolicy(languageCode),
      icon: Icons.privacy_tip_rounded,
    );
  }
}
