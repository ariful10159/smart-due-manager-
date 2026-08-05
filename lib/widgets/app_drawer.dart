import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/legal_content.dart';
import '../providers/app_settings_controller.dart';
import '../screens/archived_customers_screen.dart';
import '../screens/help_support_screen.dart';
import '../screens/home_screen.dart';
import '../screens/login_screen.dart';
import '../screens/notebook_list_screen.dart';
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
    final email = AuthService.currentUser?.email ?? '';

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
                        if (email.isNotEmpty)
                          Text(
                            email,
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
              label: "Home",
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
              label: "Notebooks",
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
              label: "Reports",
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
              label: "Archived Customers",
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
              label: "Settings",
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
              label: "Help & Support",
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
              icon: Icons.feedback_outlined,
              label: "Send Feedback",
              selected: false,
              onTap: () => _sendFeedback(context),
            ),
            _DrawerItem(
              icon: Icons.star_outline_rounded,
              label: "Rate the App",
              selected: false,
              onTap: () => _rateApp(context),
            ),

            Divider(color: colors.borderColor, height: 1),
            const SizedBox(height: 4),
            _DrawerItem(
              icon: Icons.logout_rounded,
              label: "Logout",
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

  Future<void> _sendFeedback(BuildContext context) async {
    Navigator.pop(context);

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

  Future<void> _rateApp(BuildContext context) async {
    Navigator.pop(context);

    final uri = Uri.parse(_playStoreUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Play Store খোলা যায়নি')),
      );
    }
  }

  Future<void> _confirmLogout(BuildContext context, AppColors colors) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: colors.borderColor),
        ),
        title: Text(
          "Logout",
          style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w800),
        ),
        content: Text(
          "আপনি কি লগআউট করতে চান?",
          style: TextStyle(color: colors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text("Cancel", style: TextStyle(color: colors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              "Logout",
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
                    isDark ? "Dark Mode" : "Light Mode",
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
