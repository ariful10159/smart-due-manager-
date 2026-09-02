import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../l10n/app_localizations.dart';
import '../../services/auth_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_settings_scope.dart';

class BusinessProfileScreen extends StatefulWidget {
  const BusinessProfileScreen({super.key});

  @override
  State<BusinessProfileScreen> createState() => _BusinessProfileScreenState();
}

class _BusinessProfileScreenState extends State<BusinessProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _ownerNameController;
  late TextEditingController _addressController;
  late TextEditingController _businessPhoneController;
  late TextEditingController _bkashNumberController;
  bool _uploadingLogo = false;
  bool _initialized = false;

  @override
  void dispose() {
    _nameController.dispose();
    _ownerNameController.dispose();
    _addressController.dispose();
    _businessPhoneController.dispose();
    _bkashNumberController.dispose();
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

      if (!mounted) return;
      final controller = AppSettingsScope.of(context);
      await controller.updateBusinessInfo(
        name: _nameController.text.trim(),
        ownerName: _ownerNameController.text.trim(),
        address: _addressController.text.trim(),
        logoUrl: url,
        businessPhone: _businessPhoneController.text.trim(),
        bkashNumber: _bkashNumberController.text.trim(),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.logoUpdated)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.logoUploadFailed)),
      );
    } finally {
      if (mounted) setState(() => _uploadingLogo = false);
    }
  }

  // ✅ Business Phone/bKash Number দুটোই ঐচ্ছিক ফিল্ড — খালি রাখা যাবে, কিন্তু
  // কিছু লিখলে সেটা registration/forgot-password স্ক্রিনের মতোই ন্যূনতম
  // ১১-ডিজিট ফোন ফরম্যাট মেনে চলতে হবে (এলোমেলো টেক্সট SMS/PDF এ চলে যাওয়া
  // ঠেকাতে)
  String? _validateOptionalPhone(String? value, AppLocalizations l10n) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return null;
    final digitsOnly = trimmed.replaceAll(RegExp(r'[\s\-]'), '');
    if (digitsOnly.length < 11 || !RegExp(r'^\+?\d+$').hasMatch(digitsOnly)) {
      return l10n.enterValid11DigitPhone;
    }
    return null;
  }

  Future<void> _saveBusinessInfo() async {
    if (!_formKey.currentState!.validate()) return;

    final controller = AppSettingsScope.of(context);
    await controller.updateBusinessInfo(
      name: _nameController.text.trim(),
      ownerName: _ownerNameController.text.trim(),
      address: _addressController.text.trim(),
      logoUrl: controller.settings.businessLogoUrl,
      businessPhone: _businessPhoneController.text.trim(),
      bkashNumber: _bkashNumberController.text.trim(),
    );
    if (!mounted) return;
    await _showSuccessDialog(AppLocalizations.of(context)!.businessInfoSaved);
  }

  // ✅ নিচের SnackBar এর বদলে স্ক্রিনের মাঝখানে একটা চেকমার্ক পপআপ দেখানো হয়,
  // যেটা কিছুক্ষণ পর নিজে থেকেই বন্ধ হয়ে যায়
  Future<void> _showSuccessDialog(String message) async {
    final colors = AppColors.of(context);

    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        Future.delayed(const Duration(milliseconds: 1200), () {
          if (dialogContext.mounted) {
            Navigator.of(dialogContext).pop();
          }
        });

        return Dialog(
            backgroundColor: colors.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check_rounded, color: Colors.green, size: 36),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final l10n = AppLocalizations.of(context)!;
    final controller = AppSettingsScope.of(context);
    final settings = controller.settings;

    if (!_initialized) {
      _nameController = TextEditingController(text: settings.businessName);
      _ownerNameController = TextEditingController(text: settings.ownerName);
      _addressController = TextEditingController(text: settings.businessAddress);
      _businessPhoneController = TextEditingController(text: settings.businessPhone);
      _bkashNumberController = TextEditingController(text: settings.bkashNumber);
      _initialized = true;
    }

    return Scaffold(
      backgroundColor: colors.scaffoldBg,
      appBar: AppBar(
        title: Text(
          l10n.businessProfile,
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 19, color: colors.textPrimary),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: colors.textPrimary),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: GestureDetector(
              onTap: _uploadingLogo ? null : _pickAndUploadLogo,
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: 44,
                    backgroundColor: colors.surfaceAlt,
                    backgroundImage: settings.businessLogoUrl != null
                        ? NetworkImage(settings.businessLogoUrl!)
                        : null,
                    child: settings.businessLogoUrl == null
                        ? Icon(Icons.store_rounded, color: colors.textSecondary, size: 34)
                        : null,
                  ),
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: settings.accentColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: colors.surface, width: 2),
                    ),
                    child: _uploadingLogo
                        ? const SizedBox(
                            width: 13,
                            height: 13,
                            child: CircularProgressIndicator(strokeWidth: 1.5, color: Colors.white),
                          )
                        : const Icon(Icons.camera_alt_rounded, size: 15, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _nameController,
            style: TextStyle(color: colors.textPrimary),
            decoration: InputDecoration(
              labelText: l10n.businessShopName,
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
            controller: _ownerNameController,
            style: TextStyle(color: colors.textPrimary),
            decoration: InputDecoration(
              labelText: l10n.ownerNameLabel,
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
              labelText: l10n.addressLabel,
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
          TextFormField(
            controller: _businessPhoneController,
            keyboardType: TextInputType.phone,
            style: TextStyle(color: colors.textPrimary),
            validator: (v) => _validateOptionalPhone(v, l10n),
            decoration: InputDecoration(
              labelText: l10n.businessPhoneLabel,
              labelStyle: TextStyle(color: colors.textSecondary, fontSize: 13),
              prefixIcon: Icon(Icons.call_outlined, color: colors.textSecondary, size: 20),
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
          TextFormField(
            controller: _bkashNumberController,
            keyboardType: TextInputType.phone,
            style: TextStyle(color: colors.textPrimary),
            validator: (v) => _validateOptionalPhone(v, l10n),
            decoration: InputDecoration(
              labelText: l10n.bkashNumberLabel,
              helperText: l10n.bkashNumberDesc,
              helperStyle: TextStyle(color: colors.textSecondary, fontSize: 11.5),
              labelStyle: TextStyle(color: colors.textSecondary, fontSize: 13),
              prefixIcon: Icon(Icons.account_balance_wallet_outlined, color: colors.textSecondary, size: 20),
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
          const SizedBox(height: 16),
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
              child: Text(l10n.save, style: const TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
        ],
        ),
      ),
    );
  }
}
