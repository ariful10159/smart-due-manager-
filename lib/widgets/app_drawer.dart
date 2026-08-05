import 'package:flutter/material.dart';

import '../screens/home_screen.dart';
import '../screens/notebook_list_screen.dart';
import '../screens/settings_screen.dart';
import '../services/auth_service.dart';
import '../theme/app_colors.dart';

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
}

class _DrawerItem extends StatelessWidget {
  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final color = selected ? colors.accent : colors.textSecondary;

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
                    color: selected ? colors.textPrimary : colors.textSecondary,
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
