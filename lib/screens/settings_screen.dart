import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/app_settings.dart';
import '../models/customer_repository.dart';
import '../services/auth_service.dart';
import '../services/backup_service.dart';
import '../theme/app_colors.dart';
import '../widgets/app_settings_scope.dart';
import 'app_lock_screen.dart';
import 'privacy_policy_screen.dart';
import 'terms_of_service_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _nameController;
  late TextEditingController _addressController;
  bool _uploadingLogo = false;
  bool _exportingBackup = false;
  bool _importingBackup = false;
  bool _initialized = false;

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadLogo() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked == null) return;

    setState(() => _uploadingLogo = true);
    try {
      final uid = AuthService.currentUser?.uid;
      if (uid == null) return;

      final ref = FirebaseStorage.instance.ref('business_logos/$uid.jpg');
      await ref.putFile(File(picked.path));
      final url = await ref.getDownloadURL();

      final controller = AppSettingsScope.of(context);
      await controller.updateBusinessInfo(
        name: _nameController.text.trim(),
        address: _addressController.text.trim(),
        logoUrl: url,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('লোগো আপডেট হয়েছে')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('লোগো আপলোড ব্যর্থ, আবার চেষ্টা করুন')),
      );
    } finally {
      if (mounted) setState(() => _uploadingLogo = false);
    }
  }

  Future<void> _saveBusinessInfo() async {
    final controller = AppSettingsScope.of(context);
    await controller.updateBusinessInfo(
      name: _nameController.text.trim(),
      address: _addressController.text.trim(),
      logoUrl: controller.settings.businessLogoUrl,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('বিজনেস তথ্য সেভ হয়েছে')),
    );
  }

  Future<void> _exportBackup() async {
    setState(() => _exportingBackup = true);
    try {
      final customers = await CustomerRepository().fetchCustomersOnce();
      await BackupService.exportCustomersToCsv(customers);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('এক্সপোর্ট ব্যর্থ, আবার চেষ্টা করুন')),
      );
    } finally {
      if (mounted) setState(() => _exportingBackup = false);
    }
  }

  Future<void> _importBackup() async {
    final csvContent = await BackupService.pickCsvFileContent();
    if (csvContent == null) return; // ইউজার বাতিল করেছে

    final parsed = BackupService.parseCustomersFromCsv(csvContent);
    if (parsed.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ফাইলে কোনো বৈধ কাস্টমার পাওয়া যায়নি')),
      );
      return;
    }

    if (!mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Import নিশ্চিত করুন'),
        content: Text(
          '${parsed.length} জন কাস্টমার পাওয়া গেছে। এগুলো আপনার অ্যাকাউন্টে যোগ করা হবে '
          '(যাদের ফোন নাম্বার ইতিমধ্যে আছে, তারা duplicate হিসেবে বাদ যাবে)। এগিয়ে যাবেন?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('বাতিল'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Import করুন'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _importingBackup = true);
    try {
      final result = await CustomerRepository().importCustomers(parsed);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${result.imported} জন import হয়েছে'
            '${result.skipped > 0 ? ', ${result.skipped} জন duplicate হিসেবে বাদ গেছে' : ''}',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Import ব্যর্থ, আবার চেষ্টা করুন')),
      );
    } finally {
      if (mounted) setState(() => _importingBackup = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context); // ✅ dynamic dark/light কালার
    final controller = AppSettingsScope.of(context);
    final settings = controller.settings;

    if (!_initialized) {
      _nameController = TextEditingController(text: settings.businessName);
      _addressController = TextEditingController(text: settings.businessAddress);
      _initialized = true;
    }

    return Scaffold(
      backgroundColor: colors.scaffoldBg,
      appBar: AppBar(
        title: Text(
          "Settings",
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 19, color: colors.textPrimary),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: colors.textPrimary),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _GroupHeader(label: "অ্যাপিয়ারেন্স", colors: colors),

          _SectionCard(
            title: "থিম কালার",
            icon: Icons.palette_rounded,
            colors: colors,
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: AppSettings.presetColors.map((colorValue) {
                final color = Color(colorValue);
                final isSelected = settings.accentColorValue == colorValue;
                return GestureDetector(
                  onTap: () => controller.updateAccentColor(colorValue),
                  child: Container(
                    width: 44,
                    height: 44,
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
                        ? const Icon(Icons.check_rounded, color: Colors.white, size: 20)
                        : null,
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 14),

          _SectionCard(
            title: "অ্যাপ মোড",
            icon: Icons.dark_mode_rounded,
            colors: colors,
            child: Row(
              children: [
                Expanded(
                  child: _ModeButton(
                    label: "Dark",
                    icon: Icons.dark_mode_rounded,
                    selected: settings.isDarkMode,
                    colors: colors,
                    onTap: () => controller.updateDarkMode(true),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ModeButton(
                    label: "Light",
                    icon: Icons.light_mode_rounded,
                    selected: !settings.isDarkMode,
                    colors: colors,
                    onTap: () => controller.updateDarkMode(false),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // ✅ Font Size
          _SectionCard(
            title: "Font Size",
            icon: Icons.text_fields_rounded,
            colors: colors,
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: AppSettings.fontScaleOptions.map((scale) {
                final isSelected = settings.fontScale == scale;
                final label = scale == 0.9
                    ? "ছোট"
                    : scale == 1.0
                        ? "নরমাল"
                        : scale == 1.1
                            ? "মাঝারি"
                            : scale == 1.2
                                ? "বড়"
                                : "অতি বড়";
                return GestureDetector(
                  onTap: () => controller.update(settings.copyWith(fontScale: scale)),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? settings.accentColor.withValues(alpha: 0.16) : colors.surfaceAlt,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: isSelected ? settings.accentColor : colors.borderColor),
                    ),
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 13 * scale,
                        fontWeight: FontWeight.w700,
                        color: isSelected ? settings.accentColor : colors.textPrimary,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          _GroupHeader(label: "বিজনেস", colors: colors, topPadding: 24),

          _SectionCard(
            title: "কারেন্সি",
            icon: Icons.currency_exchange_rounded,
            colors: colors,
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: AppSettings.currencyOptions.map((symbol) {
                final isSelected = settings.currencySymbol == symbol;
                return GestureDetector(
                  onTap: () => controller.updateCurrency(symbol),
                  child: Container(
                    width: 52,
                    height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isSelected ? settings.accentColor.withValues(alpha: 0.16) : colors.surfaceAlt,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? settings.accentColor : colors.borderColor,
                      ),
                    ),
                    child: Text(
                      symbol,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: isSelected ? settings.accentColor : colors.textPrimary,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 14),

          _SectionCard(
            title: "বিজনেস প্রোফাইল",
            icon: Icons.store_rounded,
            colors: colors,
            child: Column(
              children: [
                Center(
                  child: GestureDetector(
                    onTap: _uploadingLogo ? null : _pickAndUploadLogo,
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: colors.surfaceAlt,
                          backgroundImage: settings.businessLogoUrl != null
                              ? NetworkImage(settings.businessLogoUrl!)
                              : null,
                          child: settings.businessLogoUrl == null
                              ? Icon(Icons.store_rounded, color: colors.textSecondary, size: 32)
                              : null,
                        ),
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: settings.accentColor,
                            shape: BoxShape.circle,
                            border: Border.all(color: colors.surface, width: 2),
                          ),
                          child: _uploadingLogo
                              ? const SizedBox(
                                  width: 12,
                                  height: 12,
                                  child: CircularProgressIndicator(strokeWidth: 1.5, color: Colors.white),
                                )
                              : const Icon(Icons.camera_alt_rounded, size: 14, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _nameController,
                  style: TextStyle(color: colors.textPrimary),
                  decoration: InputDecoration(
                    labelText: "Business/Shop নাম",
                    labelStyle: TextStyle(color: colors.textSecondary, fontSize: 13),
                    filled: true,
                    fillColor: colors.surfaceAlt,
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
                TextField(
                  controller: _addressController,
                  maxLines: 2,
                  style: TextStyle(color: colors.textPrimary),
                  decoration: InputDecoration(
                    labelText: "ঠিকানা",
                    labelStyle: TextStyle(color: colors.textSecondary, fontSize: 13),
                    filled: true,
                    fillColor: colors.surfaceAlt,
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
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _saveBusinessInfo,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: settings.accentColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text("সেভ করুন", style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // ✅ SMS Template
          _SectionCard(
            title: "SMS রিমাইন্ডার টেমপ্লেট",
            icon: Icons.sms_rounded,
            colors: colors,
            child: _SmsTemplateEditor(colors: colors, settings: settings, controller: controller),
          ),

          _GroupHeader(label: "নিরাপত্তা ও ডেটা", colors: colors, topPadding: 24),

          // ✅ App Lock
          _SectionCard(
            title: "App Lock (নিরাপত্তা)",
            icon: Icons.lock_rounded,
            colors: colors,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        settings.appLockEnabled ? "App Lock চালু আছে" : "App Lock বন্ধ আছে",
                        style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 13.5),
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
                if (settings.appLockEnabled) ...[
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () async {
                        // ✅ নতুন PIN সেট করার আগে বর্তমান PIN/বায়োমেট্রিক দিয়ে
                        // যাচাই করা বাধ্যতামূলক — যাতে ফোন খোলা অবস্থায় পেলেই কেউ
                        // চুপচাপ PIN পাল্টে দিতে না পারে।
                        // ✅ async gap-এর আগেই এই স্ক্রিনের Navigator ক্যাপচার করা হচ্ছে
                        final settingsNavigator = Navigator.of(context);

                        final verified = await settingsNavigator.push<bool>(
                          MaterialPageRoute(
                            builder: (lockContext) => AppLockScreen(
                              mode: AppLockMode.unlock,
                              // ✅ pushed স্ক্রিনের নিজের context দিয়ে pop করা হচ্ছে,
                              // তাই বাইরের widget-এর context আর ব্যবহার করা লাগছে না
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
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 14),

          // ✅ Backup / Export / Restore
          _SectionCard(
            title: "Data Backup",
            icon: Icons.backup_rounded,
            colors: colors,
            child: Column(
              children: [
                Text(
                  "সব কাস্টমারের তথ্য CSV ফাইল হিসেবে এক্সপোর্ট করুন — Excel/Google Sheets এ খোলা যাবে। "
                  "আগে এক্সপোর্ট করা CSV ফাইল থেকে কাস্টমার ফিরিয়ে আনতেও (Restore) পারবেন।",
                  style: TextStyle(color: colors.textSecondary, fontSize: 12),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _exportingBackup ? null : _exportBackup,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colors.textPrimary,
                      side: BorderSide(color: colors.borderColor),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: _exportingBackup
                        ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: colors.accent))
                        : const Icon(Icons.file_download_rounded, size: 18),
                    label: Text(_exportingBackup ? "এক্সপোর্ট হচ্ছে..." : "CSV এক্সপোর্ট করুন", style: const TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _importingBackup ? null : _importBackup,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colors.textPrimary,
                      side: BorderSide(color: colors.borderColor),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: _importingBackup
                        ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: colors.accent))
                        : const Icon(Icons.file_upload_rounded, size: 18),
                    label: Text(_importingBackup ? "Import হচ্ছে..." : "CSV থেকে Restore করুন", style: const TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),

          _GroupHeader(label: "আইনি তথ্য", colors: colors, topPadding: 24),

          _SectionCard(
            title: "আইনি তথ্য",
            icon: Icons.privacy_tip_rounded,
            colors: colors,
            child: Column(
              children: [
                _LegalLinkRow(
                  label: "Privacy Policy",
                  colors: colors,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()),
                  ),
                ),
                Divider(color: colors.borderColor, height: 20),
                _LegalLinkRow(
                  label: "Terms of Service",
                  colors: colors,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const TermsOfServiceScreen()),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
    required this.colors,
  });

  final String title;
  final IconData icon;
  final Widget child;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colors.surface, colors.surfaceAlt],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: colors.accent, size: 18),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w800, fontSize: 14.5),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _GroupHeader extends StatelessWidget {
  const _GroupHeader({required this.label, required this.colors, this.topPadding = 0});

  final String label;
  final AppColors colors;
  final double topPadding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(4, topPadding, 4, 10),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: colors.textSecondary,
          fontWeight: FontWeight.w800,
          fontSize: 11.5,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _LegalLinkRow extends StatelessWidget {
  const _LegalLinkRow({required this.label, required this.colors, required this.onTap});

  final String label;
  final AppColors colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 13.5),
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: colors.textSecondary, size: 20),
          ],
        ),
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  const _ModeButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
    required this.colors,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 13),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? colors.accent.withValues(alpha: 0.16) : colors.surfaceAlt,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? colors.accent : colors.borderColor),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 17, color: selected ? colors.accent : colors.textSecondary),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: selected ? colors.accent : colors.textSecondary,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SmsTemplateEditor extends StatefulWidget {
  const _SmsTemplateEditor({
    required this.colors,
    required this.settings,
    required this.controller,
  });

  final AppColors colors;
  final dynamic settings;
  final dynamic controller;

  @override
  State<_SmsTemplateEditor> createState() => _SmsTemplateEditorState();
}

class _SmsTemplateEditorState extends State<_SmsTemplateEditor> {
  late TextEditingController _templateController;

  @override
  void initState() {
    super.initState();
    _templateController = TextEditingController(text: widget.settings.smsReminderTemplate);
  }

  @override
  void dispose() {
    _templateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = widget.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _templateController,
          maxLines: 4,
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
              borderSide: BorderSide(color: widget.settings.accentColor, width: 1.5),
            ),
          ),
        ),
        const SizedBox(height: 10),
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
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              widget.controller.update(
                widget.settings.copyWith(smsReminderTemplate: _templateController.text.trim()),
              );
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('টেমপ্লেট সেভ হয়েছে')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.settings.accentColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text("টেমপ্লেট সেভ করুন", style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ),
      ],
    );
  }
}