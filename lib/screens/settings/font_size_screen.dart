import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../models/app_settings.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_settings_scope.dart';

String fontScaleLabel(BuildContext context, double scale) {
  final l10n = AppLocalizations.of(context)!;
  if (scale == 0.9) return l10n.fontScaleSmall;
  if (scale == 1.0) return l10n.fontScaleNormal;
  if (scale == 1.1) return l10n.fontScaleMedium;
  if (scale == 1.2) return l10n.fontScaleLarge;
  return l10n.fontScaleExtraLarge;
}

class FontSizeScreen extends StatelessWidget {
  const FontSizeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final l10n = AppLocalizations.of(context)!;
    final controller = AppSettingsScope.of(context);
    final settings = controller.settings;

    return Scaffold(
      backgroundColor: colors.scaffoldBg,
      appBar: AppBar(
        title: Text(
          l10n.fontSize,
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
          children: AppSettings.fontScaleOptions.map((scale) {
            final isSelected = settings.fontScale == scale;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => controller.update(settings.copyWith(fontScale: scale)),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                  decoration: BoxDecoration(
                    color: isSelected ? settings.accentColor.withValues(alpha: 0.14) : colors.surfaceAlt,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: isSelected ? settings.accentColor : colors.borderColor),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          fontScaleLabel(context, scale),
                          style: TextStyle(
                            fontSize: 15 * scale,
                            fontWeight: FontWeight.w700,
                            color: isSelected ? settings.accentColor : colors.textPrimary,
                          ),
                        ),
                      ),
                      if (isSelected)
                        Icon(Icons.check_circle_rounded, color: settings.accentColor, size: 20),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
