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
  late TextEditingController _nameController;
  late TextEditingController _ownerNameController;
  late TextEditingController _addressController;
  bool _uploadingLogo = false;
  bool _initialized = false;

  @override
  void dispose() {
    _nameController.dispose();
    _ownerNameController.dispose();
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

      if (!mounted) return;
      final controller = AppSettingsScope.of(context);
      await controller.updateBusinessInfo(
        name: _nameController.text.trim(),
        ownerName: _ownerNameController.text.trim(),
        address: _addressController.text.trim(),
        logoUrl: url,
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

  Future<void> _saveBusinessInfo() async {
    final controller = AppSettingsScope.of(context);
    await controller.updateBusinessInfo(
      name: _nameController.text.trim(),
      ownerName: _ownerNameController.text.trim(),
      address: _addressController.text.trim(),
      logoUrl: controller.settings.businessLogoUrl,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context)!.businessInfoSaved)),
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
      body: ListView(
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
    );
  }
}
