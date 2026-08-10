import 'package:flutter/material.dart';

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
          "SMS টেমপ্লেট",
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
            "Due Reminder",
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: colors.textPrimary),
          ),
          const SizedBox(height: 4),
          Text(
            "কাস্টমারের বকেয়া ৳0 এর বেশি থাকলে এই টেমপ্লেট ব্যবহার হবে",
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
              hintText: 'আপনার SMS টেমপ্লেট লিখুন...',
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
            "Full Payment Thank You",
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: colors.textPrimary),
          ),
          const SizedBox(height: 4),
          Text(
            "কাস্টমারের বকেয়া সম্পূর্ণ পরিশোধ (৳0) হয়ে গেলে এই টেমপ্লেট ব্যবহার হবে",
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
              hintText: 'ধন্যবাদ জানানোর SMS টেমপ্লেট লিখুন...',
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
                  const SnackBar(content: Text('টেমপ্লেট সেভ হয়েছে')),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: settings.accentColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text("টেমপ্লেট সেভ করুন", style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}
