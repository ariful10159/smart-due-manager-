import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/app_localizations.dart';
import '../providers/app_settings_controller.dart';
import '../screens/archived_customers_screen.dart';
import '../screens/help_support_screen.dart';
import '../screens/home_screen.dart';
import '../screens/login_screen.dart';
import '../screens/notebook_list_screen.dart';
import '../screens/report_problem_screen.dart';
import '../screens/report_screen.dart';
import '../screens/settings_screen.dart';
import '../services/auth_service.dart';
import '../theme/app_colors.dart';
import 'app_settings_scope.dart';

const String _playStoreUrl =
    'https://play.google.com/store/apps/details?id=com.masum.smart_due_personal';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key, this.currentRoute = 'home'});

  final String currentRoute;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final l10n = AppLocalizations.of(context)!;
    // ✅ ফোন নম্বর দিয়ে লগইন করলে Firebase auth এ ইমেইল হিসেবে
    // "<phone>@smartdue.local" সেভ থাকে — এখানে শুধু ফোন নম্বর অংশটুকু দেখানো হয়
    final email = AuthService.currentUser?.email ?? '';
    final phone = email.split('@').first;

    return Drawer(
      backgroundColor: colors.scaffoldBg,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [colors.accent, colors.accentAlt],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.bolt_rounded, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "Smart Due",
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            color: colors.textPrimary,
                          ),
                        ),
                        if (phone.isNotEmpty)
                          Text(
                            phone,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 11.5, color: colors.textSecondary),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Divider(color: colors.borderColor, height: 1),
            const SizedBox(height: 8),
            _DrawerItem(
              icon: Icons.home_rounded,
              label: l10n.drawerHome,
              selected: currentRoute == 'home',
              onTap: () {
                Navigator.pop(context);
                if (currentRoute != 'home') {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const HomeScreen()),
                    (route) => false,
                  );
                }
              },
            ),
            _DrawerItem(
              icon: Icons.menu_book_rounded,
              label: l10n.drawerNotebooks,
              selected: currentRoute == 'notebooks',
              onTap: () {
                Navigator.pop(context);
                if (currentRoute != 'notebooks') {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const NotebookListScreen()),
                  );
                }
              },
            ),
            _DrawerItem(
              icon: Icons.bar_chart_rounded,
              label: l10n.drawerReports,
              selected: currentRoute == 'reports',
              onTap: () {
                Navigator.pop(context);
                if (currentRoute != 'reports') {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ReportScreen()),
                  );
                }
              },
            ),
            _DrawerItem(
              icon: Icons.archive_outlined,
              label: l10n.drawerArchived,
              selected: currentRoute == 'archived',
              onTap: () {
                Navigator.pop(context);
                if (currentRoute != 'archived') {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ArchivedCustomersScreen()),
                  );
                }
              },
            ),
            _DrawerItem(
              icon: Icons.settings_rounded,
              label: l10n.drawerSettings,
              selected: currentRoute == 'settings',
              onTap: () {
                Navigator.pop(context);
                if (currentRoute != 'settings') {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SettingsScreen()),
                  );
                }
              },
            ),
            _DarkModeToggle(colors: colors),

            Divider(color: colors.borderColor, height: 1),
            const SizedBox(height: 8),
            _DrawerItem(
              icon: Icons.help_outline_rounded,
              label: l10n.drawerHelp,
              selected: currentRoute == 'help',
              onTap: () {
                Navigator.pop(context);
                if (currentRoute != 'help') {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const HelpSupportScreen()),
                  );
                }
              },
            ),
            _DrawerItem(
              icon: Icons.bug_report_outlined,
              label: l10n.drawerReportProblem,
              selected: currentRoute == 'report_problem',
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ReportProblemScreen()),
                );
              },
            ),
            _DrawerItem(
              icon: Icons.star_outline_rounded,
              label: l10n.drawerRate,
              selected: false,
              onTap: () => _rateApp(context),
            ),

            Divider(color: colors.borderColor, height: 1),
            const SizedBox(height: 4),
            _DrawerItem(
              icon: Icons.logout_rounded,
              label: l10n.logout,
              selected: false,
              isDestructive: true,
              onTap: () => _confirmLogout(context, colors),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                "v1.0.0",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: colors.hintColor),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _rateApp(BuildContext context) async {
    Navigator.pop(context);

    final uri = Uri.parse(_playStoreUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.playStoreNotFound)),
      );
    }
  }

  Future<void> _confirmLogout(BuildContext context, AppColors colors) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: colors.borderColor),
        ),
        title: Text(
          l10n.logout,
          style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w800),
        ),
        content: Text(
          l10n.logoutConfirm,
          style: TextStyle(color: colors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel, style: TextStyle(color: colors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              l10n.logout,
              style: TextStyle(color: colors.due, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (!context.mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );

    await AuthService.logout();
  }
}

class _DrawerItem extends StatelessWidget {
  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.isDestructive = false,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final color = isDestructive
        ? colors.due
        : selected
            ? colors.accent
            : colors.textSecondary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      child: Material(
        color: selected ? colors.accent.withValues(alpha: 0.12) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 14),
                Text(
                  label,
                  style: TextStyle(
                    color: isDestructive
                        ? colors.due
                        : selected
                            ? colors.textPrimary
                            : colors.textSecondary,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DarkModeToggle extends StatelessWidget {
  const _DarkModeToggle({required this.colors});

  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    final AppSettingsController controller = AppSettingsScope.of(context);
    final l10n = AppLocalizations.of(context)!;
    final isDark = controller.settings.isDarkMode;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => controller.updateDarkMode(!isDark),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Icon(
                  isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                  color: colors.textSecondary,
                  size: 20,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    isDark ? l10n.darkMode : l10n.lightMode,
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                ),
                Switch(
                  value: isDark,
                  activeThumbColor: colors.accent,
                  onChanged: (value) => controller.updateDarkMode(value),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
