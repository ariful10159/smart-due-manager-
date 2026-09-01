import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../theme/app_colors.dart';
import '../widgets/app_settings_scope.dart';
import 'about_app_screen.dart';
import 'contact_screen.dart';
import 'privacy_policy_screen.dart';
import 'settings/app_lock_settings_screen.dart';
import 'settings/app_mode_screen.dart';
import 'settings/business_profile_screen.dart';
import 'settings/currency_screen.dart';
import 'settings/data_backup_screen.dart';
import 'settings/font_size_screen.dart' show FontSizeScreen, fontScaleLabel;
import 'settings/language_screen.dart';
import 'settings/sms_template_screen.dart';
import 'settings/theme_color_screen.dart';
import 'terms_of_service_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context); // ✅ dynamic dark/light কালার
    final l10n = AppLocalizations.of(context)!;
    final controller = AppSettingsScope.of(context);
    final settings = controller.settings;

    return Scaffold(
      backgroundColor: colors.scaffoldBg,
      appBar: AppBar(
        title: Text(
          l10n.settingsTitle,
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 19, color: colors.textPrimary),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: colors.textPrimary),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _GroupHeader(label: l10n.groupAppearance, colors: colors),
          _SettingsGroup(
            colors: colors,
            children: [
              _SettingsRow(
                icon: Icons.palette_rounded,
                title: l10n.themeColor,
                colors: colors,
                trailing: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(color: settings.accentColor, shape: BoxShape.circle),
                ),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ThemeColorScreen()),
                ),
              ),
              _SettingsRow(
                icon: Icons.dark_mode_rounded,
                title: l10n.appMode,
                subtitle: settings.isDarkMode ? "Dark" : "Light",
                colors: colors,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AppModeScreen()),
                ),
              ),
              _SettingsRow(
                icon: Icons.text_fields_rounded,
                title: l10n.fontSize,
                subtitle: fontScaleLabel(context, settings.fontScale),
                colors: colors,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const FontSizeScreen()),
                ),
              ),
              _SettingsRow(
                icon: Icons.language_rounded,
                title: l10n.language,
                subtitle: settings.languageCode == 'bn' ? l10n.bengali : l10n.english,
                colors: colors,
                isLast: true,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const LanguageScreen()),
                ),
              ),
            ],
          ),

          _GroupHeader(label: l10n.groupBusiness, colors: colors, topPadding: 24),
          _SettingsGroup(
            colors: colors,
            children: [
              _SettingsRow(
                icon: Icons.currency_exchange_rounded,
                title: l10n.currency,
                subtitle: settings.currencySymbol,
                colors: colors,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const CurrencyScreen()),
                ),
              ),
              _SettingsRow(
                icon: Icons.store_rounded,
                title: l10n.businessProfile,
                subtitle: settings.businessName,
                colors: colors,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const BusinessProfileScreen()),
                ),
              ),
              _SettingsRow(
                icon: Icons.sms_rounded,
                title: l10n.smsTemplate,
                colors: colors,
                isLast: true,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SmsTemplateScreen()),
                ),
              ),
            ],
          ),

          _GroupHeader(label: l10n.groupSecurity, colors: colors, topPadding: 24),
          _SettingsGroup(
            colors: colors,
            children: [
              _SettingsRow(
                icon: Icons.lock_rounded,
                title: l10n.appLock,
                subtitle: settings.appLockEnabled ? l10n.enabled : l10n.disabled,
                colors: colors,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AppLockSettingsScreen()),
                ),
              ),
              _SettingsRow(
                icon: Icons.backup_rounded,
                title: l10n.dataBackup,
                colors: colors,
                isLast: true,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const DataBackupScreen()),
                ),
              ),
            ],
          ),

          _GroupHeader(label: l10n.groupLegal, colors: colors, topPadding: 24),
          _SettingsGroup(
            colors: colors,
            children: [
              _SettingsRow(
                icon: Icons.privacy_tip_outlined,
                title: l10n.privacyPolicy,
                colors: colors,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()),
                ),
              ),
              _SettingsRow(
                icon: Icons.description_outlined,
                title: l10n.termsOfService,
                colors: colors,
                isLast: true,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const TermsOfServiceScreen()),
                ),
              ),
            ],
          ),

          _GroupHeader(label: l10n.groupAbout, colors: colors, topPadding: 24),
          _SettingsGroup(
            colors: colors,
            children: [
              _SettingsRow(
                icon: Icons.info_outline_rounded,
                title: l10n.aboutAppTitle,
                colors: colors,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AboutAppScreen()),
                ),
              ),
              _SettingsRow(
                icon: Icons.support_agent_rounded,
                title: l10n.contactTitle,
                colors: colors,
                isLast: true,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ContactScreen()),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.colors, required this.children});

  final AppColors colors;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colors.surface, colors.surfaceAlt],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.borderColor),
      ),
      child: Column(children: children),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.icon,
    required this.title,
    required this.colors,
    required this.onTap,
    this.subtitle,
    this.trailing,
    this.isLast = false,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final AppColors colors;
  final VoidCallback onTap;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(icon, color: colors.accent, size: 20),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w700, fontSize: 14.5),
                  ),
                ),
                if (subtitle != null) ...[
                  Text(
                    subtitle!,
                    style: TextStyle(color: colors.textSecondary, fontSize: 13),
                  ),
                  const SizedBox(width: 8),
                ],
                if (trailing != null) ...[
                  trailing!,
                  const SizedBox(width: 8),
                ],
                Icon(Icons.chevron_right_rounded, color: colors.textSecondary, size: 20),
              ],
            ),
          ),
        ),
        if (!isLast) Divider(color: colors.borderColor, height: 1, indent: 16, endIndent: 16),
      ],
    );
  }
}

class _GroupHeader extends StatelessWidget {
  const _GroupHeader({required this.label, required this.colors, this.topPadding = 0});

  final String label;
  final AppColors colors;
  final double topPadding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(4, topPadding, 4, 10),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: colors.textSecondary,
          fontWeight: FontWeight.w800,
          fontSize: 11.5,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}
