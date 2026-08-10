import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../models/app_settings.dart';
import '../../providers/app_settings_controller.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_settings_scope.dart';

class SmsTemplateScreen extends StatefulWidget {
  const SmsTemplateScreen({super.key});

  @override
  State<SmsTemplateScreen> createState() => _SmsTemplateScreenState();
}

class _SmsTemplateScreenState extends State<SmsTemplateScreen> {
  late TextEditingController _dueTemplateController;
  late TextEditingController _thankYouTemplateController;
  bool _initialized = false;

  @override
  void dispose() {
    _dueTemplateController.dispose();
    _thankYouTemplateController.dispose();
    super.dispose();
  }

  void _insertTag(TextEditingController controller, String tag) {
    final text = controller.text;
    final selection = controller.selection;
    final insertPos = selection.start >= 0 ? selection.start : text.length;
    final newText = text.replaceRange(insertPos, insertPos, tag);
    controller.text = newText;
    controller.selection = TextSelection.collapsed(offset: insertPos + tag.length);
  }

  Widget _buildPlaceholderChips(
    AppColors colors,
    TextEditingController controller,
    List<String> tags,
  ) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: tags.map((tag) {
        return GestureDetector(
          onTap: () => setState(() => _insertTag(controller, tag)),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: colors.accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: colors.accent.withValues(alpha: 0.3)),
            ),
            child: Text(tag, style: TextStyle(color: colors.accent, fontSize: 11.5, fontWeight: FontWeight.w700)),
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final l10n = AppLocalizations.of(context)!;
    final AppSettingsController controller = AppSettingsScope.of(context);
    final AppSettings settings = controller.settings;

    if (!_initialized) {
      _dueTemplateController = TextEditingController(text: settings.smsReminderTemplate);
      _thankYouTemplateController = TextEditingController(text: settings.fullPaymentThankYouTemplate);
      _initialized = true;
    }

    return Scaffold(
      backgroundColor: colors.scaffoldBg,
      appBar: AppBar(
        title: Text(
          l10n.smsTemplate,
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: colors.textPrimary),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: colors.textPrimary),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            l10n.dueReminderLabel,
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: colors.textPrimary),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.dueReminderDesc,
            style: TextStyle(fontSize: 12, color: colors.textSecondary),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _dueTemplateController,
            maxLines: 5,
            style: TextStyle(color: colors.textPrimary, fontSize: 13.5),
            decoration: InputDecoration(
              filled: true,
              fillColor: colors.surfaceAlt,
              hintText: l10n.smsTemplateHint,
              hintStyle: TextStyle(color: colors.hintColor),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: colors.borderColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: colors.borderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: settings.accentColor, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 10),
          _buildPlaceholderChips(colors, _dueTemplateController, AppSettings.smsPlaceholders),

          const SizedBox(height: 28),
          Divider(color: colors.borderColor, height: 1),
          const SizedBox(height: 24),

          Text(
            l10n.fullPaymentThankYouLabel,
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: colors.textPrimary),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.fullPaymentThankYouDesc,
            style: TextStyle(fontSize: 12, color: colors.textSecondary),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _thankYouTemplateController,
            maxLines: 5,
            style: TextStyle(color: colors.textPrimary, fontSize: 13.5),
            decoration: InputDecoration(
              filled: true,
              fillColor: colors.surfaceAlt,
              hintText: l10n.thankYouTemplateHint,
              hintStyle: TextStyle(color: colors.hintColor),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: colors.borderColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: colors.borderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: settings.accentColor, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 10),
          _buildPlaceholderChips(colors, _thankYouTemplateController, AppSettings.thankYouPlaceholders),

          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                controller.update(
                  settings.copyWith(
                    smsReminderTemplate: _dueTemplateController.text.trim(),
                    fullPaymentThankYouTemplate: _thankYouTemplateController.text.trim(),
                  ),
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.templateSaved)),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: settings.accentColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(l10n.saveTemplate, style: const TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}
