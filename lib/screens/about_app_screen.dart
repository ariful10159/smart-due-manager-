import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../l10n/app_localizations.dart';
import '../models/legal_content.dart';
import '../services/app_config_service.dart';
import '../theme/app_colors.dart';
import '../widgets/app_settings_scope.dart';

class AboutAppScreen extends StatelessWidget {
  const AboutAppScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final l10n = AppLocalizations.of(context)!;
    final languageCode = AppSettingsScope.settingsOf(context).languageCode;

    return Scaffold(
      backgroundColor: colors.scaffoldBg,
      appBar: AppBar(
        title: Text(
          l10n.aboutAppTitle,
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: colors.textPrimary),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: colors.textPrimary),
      ),
      body: FutureBuilder(
        future: Future.wait([AppConfigService.fetchOnce(), PackageInfo.fromPlatform()]),
        builder: (context, snapshot) {
          final config = (snapshot.data?[0] as Map<String, dynamic>?) ?? {};
          final packageInfo = snapshot.data?[1] as PackageInfo?;
          final suffix = languageCode == 'en' ? 'En' : 'Bn';
          final otherSuffix = suffix == 'En' ? 'Bn' : 'En';
          var aboutText = (config['aboutApp$suffix'] as String? ?? '').trim();
          if (aboutText.isEmpty) {
            aboutText = (config['aboutApp$otherSuffix'] as String? ?? '').trim();
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [colors.accent, colors.accentAlt],
                  ),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  children: [
                    Text(
                      LegalContent.appName,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 20),
                    ),
                    if (packageInfo != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        l10n.appVersionLabel(packageInfo.version),
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.88), fontSize: 13),
                      ),
                    ],
                  ],
                ),
              ),
              if (aboutText.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: colors.borderColor),
                  ),
                  child: Text(
                    aboutText,
                    style: TextStyle(color: colors.textSecondary, fontSize: 13.5, height: 1.65),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
