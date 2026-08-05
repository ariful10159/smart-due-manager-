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
  late TextEditingController _templateController;
  bool _initialized = false;

  @override
  void dispose() {
    _templateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final AppSettingsController controller = AppSettingsScope.of(context);
    final AppSettings settings = controller.settings;

    if (!_initialized) {
      _templateController = TextEditingController(text: settings.smsReminderTemplate);
      _initialized = true;
    }

    return Scaffold(
      backgroundColor: colors.scaffoldBg,
      appBar: AppBar(
        title: Text(
          "SMS রিমাইন্ডার টেমপ্লেট",
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
          TextField(
            controller: _templateController,
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
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              '{name}',
              '{amount}',
              '{due_date}',
              '{business_name}',
              '{phone}',
            ].map((tag) {
              return GestureDetector(
                onTap: () {
                  final text = _templateController.text;
                  final selection = _templateController.selection;
                  final insertPos = selection.start >= 0 ? selection.start : text.length;
                  final newText = text.replaceRange(insertPos, insertPos, tag);
                  _templateController.text = newText;
                  _templateController.selection =
                      TextSelection.collapsed(offset: insertPos + tag.length);
                },
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
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                controller.update(
                  settings.copyWith(smsReminderTemplate: _templateController.text.trim()),
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
