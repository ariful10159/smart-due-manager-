import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../widgets/app_settings_scope.dart';

class AppModeScreen extends StatelessWidget {
  const AppModeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final controller = AppSettingsScope.of(context);
    final settings = controller.settings;

    return Scaffold(
      backgroundColor: colors.scaffoldBg,
      appBar: AppBar(
        title: Text(
          "অ্যাপ মোড",
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 19, color: colors.textPrimary),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: colors.textPrimary),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _ModeTile(
              label: "Dark",
              icon: Icons.dark_mode_rounded,
              selected: settings.isDarkMode,
              colors: colors,
              onTap: () => controller.updateDarkMode(true),
            ),
            const SizedBox(height: 12),
            _ModeTile(
              label: "Light",
              icon: Icons.light_mode_rounded,
              selected: !settings.isDarkMode,
              colors: colors,
              onTap: () => controller.updateDarkMode(false),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModeTile extends StatelessWidget {
  const _ModeTile({
    required this.label,
    required this.icon,
    required this.selected,
    required this.colors,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final AppColors colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        decoration: BoxDecoration(
          color: selected ? colors.accent.withValues(alpha: 0.14) : colors.surfaceAlt,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? colors.accent : colors.borderColor),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: selected ? colors.accent : colors.textSecondary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: selected ? colors.accent : colors.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 14.5,
                ),
              ),
            ),
            if (selected) Icon(Icons.check_circle_rounded, color: colors.accent, size: 20),
          ],
        ),
      ),
    );
  }
}
