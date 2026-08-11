import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/legal_content.dart';
import '../widgets/app_settings_scope.dart';
import '../widgets/legal_document_view.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final languageCode = AppSettingsScope.settingsOf(context).languageCode;
    return LegalDocumentView(
      title: AppLocalizations.of(context)!.termsOfServiceTitle,
      sections: LegalContent.termsOfService(languageCode),
      icon: Icons.gavel_rounded,
    );
  }
}
