import 'package:flutter/material.dart';

import '../models/legal_content.dart';
import '../widgets/legal_document_view.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const LegalDocumentView(
      title: "Terms of Service",
      sections: LegalContent.termsOfService,
      icon: Icons.gavel_rounded,
    );
  }
}
