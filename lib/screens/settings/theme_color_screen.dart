import 'package:flutter/material.dart';

import '../../models/app_settings.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_settings_scope.dart';

class ThemeColorScreen extends StatelessWidget {
  const ThemeColorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final controller = AppSettingsScope.of(context);
    final settings = controller.settings;

    return Scaffold(
      backgroundColor: colors.scaffoldBg,
      appBar: AppBar(
        title: Text(
          "থিম কালার",
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 19, color: colors.textPrimary),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: colors.textPrimary),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          spacing: 16,
          runSpacing: 16,
          children: AppSettings.presetColors.map((colorValue) {
            final color = Color(colorValue);
            final isSelected = settings.accentColorValue == colorValue;
            return GestureDetector(
              onTap: () => controller.updateAccentColor(colorValue),
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? colors.textPrimary : Colors.transparent,
                    width: 3,
                  ),
                  boxShadow: isSelected
                      ? [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 12, spreadRadius: 1)]
                      : [],
                ),
                child: isSelected
                    ? const Icon(Icons.check_rounded, color: Colors.white, size: 22)
                    : null,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
