import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../widgets/app_settings_scope.dart';
import '../app_lock_screen.dart';

class AppLockSettingsScreen extends StatelessWidget {
  const AppLockSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final controller = AppSettingsScope.of(context);
    final settings = controller.settings;

    return Scaffold(
      backgroundColor: colors.scaffoldBg,
      appBar: AppBar(
        title: Text(
          "App Lock (নিরাপত্তা)",
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: colors.textPrimary),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: colors.textPrimary),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: colors.surfaceAlt,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: colors.borderColor),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      settings.appLockEnabled ? "App Lock চালু আছে" : "App Lock বন্ধ আছে",
                      style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                  ),
                  Switch(
                    value: settings.appLockEnabled,
                    activeThumbColor: settings.accentColor,
                    onChanged: (value) async {
                      if (value) {
                        final result = await Navigator.of(context).push<bool>(
                          MaterialPageRoute(builder: (_) => const AppLockScreen(mode: AppLockMode.setup)),
                        );
                        if (result != true) return; // সেটআপ বাতিল করলে টগল অন হবে না
                      } else {
                        // ✅ App Lock বন্ধ করার আগেও PIN/বায়োমেট্রিক দিয়ে যাচাই
                        // বাধ্যতামূলক — নাহলে ফোন খোলা অবস্থায় পেলেই কেউ চুপচাপ
                        // লক অফ করে দিতে পারত, "PIN পরিবর্তন করুন"-এর মতোই।
                        final settingsNavigator = Navigator.of(context);
                        final verified = await settingsNavigator.push<bool>(
                          MaterialPageRoute(
                            builder: (lockContext) => AppLockScreen(
                              mode: AppLockMode.unlock,
                              onUnlocked: () => Navigator.of(lockContext).pop(true),
                            ),
                          ),
                        );
                        if (verified != true) return;

                        await controller.update(settings.copyWith(appLockEnabled: false, clearPin: true));
                      }
                    },
                  ),
                ],
              ),
            ),
            if (settings.appLockEnabled) ...[
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: () async {
                  // ✅ নতুন PIN সেট করার আগে বর্তমান PIN/বায়োমেট্রিক দিয়ে
                  // যাচাই করা বাধ্যতামূলক — যাতে ফোন খোলা অবস্থায় পেলেই কেউ
                  // চুপচাপ PIN পাল্টে দিতে না পারে।
                  final settingsNavigator = Navigator.of(context);

                  final verified = await settingsNavigator.push<bool>(
                    MaterialPageRoute(
                      builder: (lockContext) => AppLockScreen(
                        mode: AppLockMode.unlock,
                        onUnlocked: () => Navigator.of(lockContext).pop(true),
                      ),
                    ),
                  );
                  if (verified != true) return;

                  await settingsNavigator.push(
                    MaterialPageRoute(builder: (_) => const AppLockScreen(mode: AppLockMode.setup)),
                  );
                },
                icon: Icon(Icons.password_rounded, color: settings.accentColor, size: 16),
                label: Text("PIN পরিবর্তন করুন", style: TextStyle(color: settings.accentColor, fontWeight: FontWeight.w700, fontSize: 12.5)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
