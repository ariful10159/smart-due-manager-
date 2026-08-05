import 'package:flutter/material.dart';

import '../models/legal_content.dart';
import '../widgets/legal_document_view.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const LegalDocumentView(
      title: "Privacy Policy",
      sections: LegalContent.privacyPolicy,
    );
  }
}
