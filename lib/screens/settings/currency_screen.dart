import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../models/app_settings.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_settings_scope.dart';

class CurrencyScreen extends StatelessWidget {
  const CurrencyScreen({super.key});

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
          l10n.currency,
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
          spacing: 12,
          runSpacing: 12,
          children: AppSettings.currencyOptions.map((symbol) {
            final isSelected = settings.currencySymbol == symbol;
            return GestureDetector(
              onTap: () => controller.updateCurrency(symbol),
              child: Container(
                width: 60,
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected ? settings.accentColor.withValues(alpha: 0.16) : colors.surfaceAlt,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected ? settings.accentColor : colors.borderColor,
                  ),
                ),
                child: Text(
                  symbol,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: isSelected ? settings.accentColor : colors.textPrimary,
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
