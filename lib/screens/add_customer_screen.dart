import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/customer.dart';
import '../theme/app_colors.dart';
import '../widgets/custom_bottom_nav_bar.dart';
import 'home_screen.dart';

enum CustomFieldType {
  text,
  number,
  date,
  currency,
  multiline,
  photo,
}

extension CustomFieldTypeX on CustomFieldType {
  String get label {
    switch (this) {
      case CustomFieldType.text:
        return 'Text';
      case CustomFieldType.number:
        return 'Number';
      case CustomFieldType.date:
        return 'Date';
      case CustomFieldType.currency:
        return 'Amount';
      case CustomFieldType.multiline:
        return 'Long Text';
      case CustomFieldType.photo:
        return 'Photo';
    }
  }

  IconData get icon {
    switch (this) {
      case CustomFieldType.text:
        return Icons.short_text_rounded;
      case CustomFieldType.number:
        return Icons.numbers_rounded;
      case CustomFieldType.date:
        return Icons.calendar_today_rounded;
      case CustomFieldType.currency:
        return Icons.monetization_on_outlined;
      case CustomFieldType.multiline:
        return Icons.notes_rounded;
      case CustomFieldType.photo:
        return Icons.photo_camera_outlined;
    }
  }
}

class _CustomFieldEntry {
  _CustomFieldEntry({required this.label, required this.type})
      : controller = TextEditingController();

  String label;
  CustomFieldType type;
  final TextEditingController controller;
}

const _reservedFieldNames = [
  'name',
  'full name',
  'phone',
  'phone number',
  'address',
  'address location',
  'amount',
  'due amount',
  'initial due amount',
  'date',
  'select date',
  'notes',
  'note',
  'additional notes',
];

class AddCustomerScreen extends StatefulWidget {
  const AddCustomerScreen({super.key});

  @override
  State<AddCustomerScreen> createState() => _AddCustomerScreenState();
}

class _AddCustomerScreenState extends State<AddCustomerScreen> {
  final _formKey = GlobalKey<FormState>();

  final int _selectedIndex = 1;

  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _dueAmountController = TextEditingController();
  final _phoneController = TextEditingController();
  final _dateController = TextEditingController();
  final _noteController = TextEditingController();

  final _addressFocusNode = FocusNode();

  File? _selectedImage;
  bool _isSaving = false;
  List<String> _savedAddresses = [];
  double _addressFieldWidth = 0;
  final List<_CustomFieldEntry> _customFields = [];

  @override
  void initState() {
    super.initState();
    _loadSavedAddresses();
  }

  Future<void> _loadSavedAddresses() async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) return;

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('customers')
          .where('ownerId', isEqualTo: currentUserId)
          .get();

      final addresses = snapshot.docs
          .map((doc) => (doc.data()['address'] as String?)?.trim() ?? '')
          .where((address) => address.isNotEmpty)
          .toSet()
          .toList()
        ..sort();

      if (mounted) {
        setState(() {
          _savedAddresses = addresses;
        });
      }
    } catch (_) {
      // Suggestions are best-effort; ignore failures.
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _dueAmountController.dispose();
    _phoneController.dispose();
    _dateController.dispose();
    _noteController.dispose();
    _addressFocusNode.dispose();
    for (final field in _customFields) {
      field.controller.dispose();
    }
    super.dispose();
  }

  Future<void> _selectDate(AppColors colors) async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme(
              brightness: colors.scaffoldBg.computeLuminance() < 0.5
                  ? Brightness.dark
                  : Brightness.light,
              primary: colors.accent,
              onPrimary: Colors.white,
              secondary: colors.accentAlt,
              onSecondary: Colors.white,
              error: colors.due,
              onError: Colors.white,
              surface: colors.surface,
              onSurface: colors.textPrimary,
            ),
            dialogTheme: DialogThemeData(backgroundColor: colors.surface),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      setState(() {
        _dateController.text =
            "${pickedDate.day}-${pickedDate.month}-${pickedDate.year}";
      });
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

  Future<Map<String, dynamic>?> _showCustomFieldDialog(
    AppColors colors, {
    required String title,
    String initialLabel = '',
    CustomFieldType initialType = CustomFieldType.text,
    bool allowDelete = false,
  }) {
    final labelController = TextEditingController(text: initialLabel);
    CustomFieldType selectedType = initialType;

    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              backgroundColor: colors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: BorderSide(color: colors.borderColor),
              ),
              title: Text(
                title,
                style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w800),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: labelController,
                      autofocus: true,
                      style: TextStyle(color: colors.textPrimary),
                      decoration: InputDecoration(
                        hintText: 'e.g. NID Number, Shop Name, Reference',
                        hintStyle: TextStyle(color: colors.textSecondary),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Field Type',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: colors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<CustomFieldType>(
                      initialValue: selectedType,
                      isExpanded: true,
                      dropdownColor: colors.surface,
                      style: TextStyle(color: colors.textPrimary, fontSize: 14),
                      icon: Icon(Icons.keyboard_arrow_down_rounded, color: colors.textSecondary),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: colors.surfaceAlt,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: colors.borderColor),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: colors.borderColor),
                        ),
                      ),
                      items: CustomFieldType.values.map((type) {
                        return DropdownMenuItem(
                          value: type,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(type.icon, size: 18, color: colors.textSecondary),
                              const SizedBox(width: 10),
                              Text(type.label),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (type) {
                        if (type == null) return;
                        setDialogState(() {
                          selectedType = type;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actionsAlignment:
                  allowDelete ? MainAxisAlignment.spaceBetween : MainAxisAlignment.end,
              actions: [
                if (allowDelete)
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext, {'action': 'delete'}),
                    child: Text(
                      'Delete Field',
                      style: TextStyle(color: colors.due, fontWeight: FontWeight.w700),
                    ),
                  ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      child: Text('Cancel', style: TextStyle(color: colors.textSecondary)),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext, {
                        'action': 'save',
                        'label': labelController.text,
                        'type': selectedType,
                      }),
                      child: Text(
                        allowDelete ? 'Save' : 'Add',
                        style: TextStyle(color: colors.accent, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _addCustomField(AppColors colors) async {
    final result = await _showCustomFieldDialog(colors, title: 'Add Custom Field');
    if (result == null || result['action'] != 'save') return;

    final trimmedLabel = (result['label'] as String).trim();
    if (trimmedLabel.isEmpty) return;

    if (_reservedFieldNames.contains(trimmedLabel.toLowerCase())) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('"$trimmedLabel" is already a default field')),
      );
      return;
    }

    final alreadyExists = _customFields.any(
      (field) => field.label.toLowerCase() == trimmedLabel.toLowerCase(),
    );

    if (alreadyExists) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('"$trimmedLabel" is already added')),
      );
      return;
    }

    setState(() {
      _customFields.add(
        _CustomFieldEntry(
          label: trimmedLabel,
          type: result['type'] as CustomFieldType,
        ),
      );
    });
  }

  Future<void> _editCustomField(_CustomFieldEntry field, AppColors colors) async {
    final result = await _showCustomFieldDialog(
      colors,
      title: 'Edit Custom Field',
      initialLabel: field.label,
      initialType: field.type,
      allowDelete: true,
    );

    if (result == null) return;

    if (result['action'] == 'delete') {
      _removeCustomField(field);
      return;
    }

    final trimmedLabel = (result['label'] as String).trim();
    if (trimmedLabel.isEmpty) return;

    if (_reservedFieldNames.contains(trimmedLabel.toLowerCase())) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('"$trimmedLabel" is already a default field')),
      );
      return;
    }

    final duplicateExists = _customFields.any(
      (other) => other != field && other.label.toLowerCase() == trimmedLabel.toLowerCase(),
    );

    if (duplicateExists) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('"$trimmedLabel" is already added')),
      );
      return;
    }

    final newType = result['type'] as CustomFieldType;

    setState(() {
      field.label = trimmedLabel;
      if (newType != field.type) {
        field.controller.clear();
      }
      field.type = newType;
    });
  }

  void _removeCustomField(_CustomFieldEntry field) {
    setState(() {
      _customFields.remove(field);
    });
    field.controller.dispose();
  }

  Future<void> _pickCustomFieldDate(
    TextEditingController controller,
    AppColors colors,
  ) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme(
              brightness: colors.scaffoldBg.computeLuminance() < 0.5
                  ? Brightness.dark
                  : Brightness.light,
              primary: colors.accent,
              onPrimary: Colors.white,
              secondary: colors.accentAlt,
              onSecondary: Colors.white,
              error: colors.due,
              onError: Colors.white,
              surface: colors.surface,
              onSurface: colors.textPrimary,
            ),
            dialogTheme: DialogThemeData(backgroundColor: colors.surface),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      controller.text = "${pickedDate.day}-${pickedDate.month}-${pickedDate.year}";
    }
  }

  Future<void> _pickCustomFieldPhoto(_CustomFieldEntry field) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
      maxWidth: 800,
      maxHeight: 800,
    );

    if (image == null) return;

    final bytes = await File(image.path).readAsBytes();

    if (bytes.length > 700 * 1024) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ছবিটা বেশি বড়, দয়া করে আরেকটু ছোট/হালকা ছবি বেছে নিন'),
        ),
      );
      return;
    }

    setState(() {
      field.controller.text = base64Encode(bytes);
    });
  }

  // ✨ ফর্মের সব ডেটা রিসেট করার জন্য নতুন মেথড
  void _resetForm() {
    _nameController.clear();
    _phoneController.clear();
    _addressController.clear();
    _dueAmountController.clear();
    _dateController.clear();
    _noteController.clear();
    for (final field in _customFields) {
      field.controller.dispose();
    }
    setState(() {
      _customFields.clear();
      _selectedImage = null;
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    if (currentUserId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User not logged in')),
        );
      }
      return;
    }

    final totalDue = double.tryParse(_dueAmountController.text.trim()) ?? 0.0;

    DateTime? lastPaymentDate;
    final dateText = _dateController.text.trim();

    if (dateText.isNotEmpty) {
      final parts = dateText.split('-');
      if (parts.length == 3) {
        final day = int.tryParse(parts[0]);
        final month = int.tryParse(parts[1]);
        final year = int.tryParse(parts[2]);

        if (day != null && month != null && year != null) {
          lastPaymentDate = DateTime(year, month, day);
        }
      }
    }

    final customer = Customer(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text.trim(),
      address: _addressController.text.trim().isEmpty
          ? null
          : _addressController.text.trim(),
      phone: _phoneController.text.trim(),
      totalDue: totalDue,
      lastPaymentDate: lastPaymentDate ?? DateTime.now(),
      createdAt: DateTime.now(),
      note: _noteController.text.trim().isEmpty
          ? null
          : _noteController.text.trim(),
      ownerId: currentUserId,
      customFields: {
        for (final field in _customFields)
          field.label: field.controller.text.trim(),
      },
    );

    setState(() {
      _isSaving = true;
    });

    try {
      await FirebaseFirestore.instance
          .collection('customers')
          .doc(customer.id)
          .set(customer.toMap());

      if (!mounted) return;

      // ✅ সুন্দর সাকসেস মেসেজ দেখানো হচ্ছে
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Success!',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                    ),
                    Text(
                      '${customer.name} has been added successfully.',
                      style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.9)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          backgroundColor: Colors.green[700],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          duration: const Duration(seconds: 2),
        ),
      );

      // ✅ হোম স্ক্রিনে যাওয়ার কোডটি বাদ দিয়ে ফর্মটি রিসেট করা হয়েছে যাতে ইউজার এই স্ক্রিনেই থাকেন
      _resetForm();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Failed to save, please try again'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  InputDecoration _buildInputDecoration({
    required AppColors colors,
    required String labelText,
    required IconData prefixIcon,
  }) {
    return InputDecoration(
      labelText: labelText,
      labelStyle: TextStyle(
        color: colors.textSecondary,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      prefixIcon: Icon(prefixIcon, color: colors.accent, size: 22),
      filled: true,
      fillColor: colors.surfaceAlt,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: colors.borderColor, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: colors.accent, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: colors.due, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: colors.due, width: 2),
      ),
    );
  }

  Widget _buildTypeBadge(CustomFieldType type, AppColors colors) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: colors.accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(type.icon, size: 11, color: colors.accent),
          const SizedBox(width: 4),
          Text(
            type.label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: colors.accent,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomFieldCard(_CustomFieldEntry field, AppColors colors) {
    if (field.type == CustomFieldType.photo) {
      final hasPhoto = field.controller.text.isNotEmpty;
      return Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colors.surfaceAlt,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.borderColor),
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => _pickCustomFieldPhoto(field),
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(12),
                  image: hasPhoto
                      ? DecorationImage(
                          image: MemoryImage(base64Decode(field.controller.text)),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: !hasPhoto
                    ? Icon(Icons.add_a_photo_rounded, color: colors.accent, size: 20)
                    : null,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTypeBadge(field.type, colors),
                  const SizedBox(height: 6),
                  Text(
                    field.label,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: colors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(Icons.edit_outlined, size: 18, color: colors.textSecondary),
              onPressed: () => _editCustomField(field, colors),
            ),
          ],
        ),
      );
    }

    final isPickerField = field.type == CustomFieldType.date;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.fromLTRB(14, 12, 6, 4),
      decoration: BoxDecoration(
        color: colors.surfaceAlt,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTypeBadge(field.type, colors),
                const SizedBox(height: 6),
                TextFormField(
                  controller: field.controller,
                  readOnly: isPickerField,
                  maxLines: field.type == CustomFieldType.multiline ? 3 : 1,
                  onTap: switch (field.type) {
                    CustomFieldType.date =>
                      () => _pickCustomFieldDate(field.controller, colors),
                    _ => null,
                  },
                  keyboardType: switch (field.type) {
                    CustomFieldType.number => TextInputType.number,
                    CustomFieldType.currency =>
                      const TextInputType.numberWithOptions(decimal: true),
                    _ => TextInputType.text,
                  },
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: colors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    labelText: field.label,
                    labelStyle: TextStyle(
                      color: colors.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.edit_outlined, size: 18, color: colors.textSecondary),
            onPressed: () => _editCustomField(field, colors),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context); // ✅ dynamic dark/light কালার

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Navigator.of(context).pushAndRemoveUntil(
          tabTransitionRoute(const HomeScreen(), false),
          (route) => false,
        );
      },
      child: Scaffold(
      backgroundColor: colors.scaffoldBg,
      appBar: AppBar(
        title: Text(
          'Create Customer',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 20,
            letterSpacing: 0.5,
            color: colors.textPrimary,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        iconTheme: IconThemeData(color: colors.textPrimary),
        actions: [
          IconButton(
            tooltip: 'Add Custom Field',
            icon: Badge(
              label: Text('${_customFields.length}'),
              isLabelVisible: _customFields.isNotEmpty,
              child: Icon(Icons.playlist_add_rounded, color: colors.accent),
            ),
            onPressed: () => _addCustomField(colors),
          ),
        ],
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Stack(
                    children: [
                      Container(
                        height: 110,
                        width: 110,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(28),
                          gradient: LinearGradient(
                            colors: [
                              colors.accent.withValues(alpha: 0.35),
                              colors.accentAlt.withValues(alpha: 0.15),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: colors.accent.withValues(alpha: 0.2),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            )
                          ],
                        ),
                        padding: const EdgeInsets.all(3),
                        child: Container(
                          decoration: BoxDecoration(
                            color: colors.surface,
                            borderRadius: BorderRadius.circular(25),
                            image: _selectedImage != null
                                ? DecorationImage(image: FileImage(_selectedImage!), fit: BoxFit.cover)
                                : null,
                          ),
                          child: _selectedImage == null
                              ? Icon(Icons.blur_on_rounded, size: 48, color: colors.accent)
                              : null,
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: _pickImage,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: colors.accent,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: colors.accent.withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                )
                              ],
                            ),
                            child: const Icon(Icons.add_a_photo_rounded, size: 16, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [colors.surface, colors.surfaceAlt],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: colors.borderColor),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      )
                    ],
                  ),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _nameController,
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: colors.textPrimary),
                        decoration: _buildInputDecoration(
                          colors: colors,
                          labelText: 'Full Name',
                          prefixIcon: Icons.badge_outlined,
                        ),
                        validator: (value) =>
                            value == null || value.trim().isEmpty ? 'Please enter name' : null,
                      ),
                      const SizedBox(height: 20),

                      TextFormField(
                        controller: _phoneController,
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: colors.textPrimary),
                        decoration: _buildInputDecoration(
                          colors: colors,
                          labelText: 'Phone Number',
                          prefixIcon: Icons.phone_android_rounded,
                        ),
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 20),

                      RawAutocomplete<String>(
                        textEditingController: _addressController,
                        focusNode: _addressFocusNode,
                        optionsBuilder: (textEditingValue) {
                          final query = textEditingValue.text.toLowerCase().trim();
                          if (query.isEmpty) {
                            return _savedAddresses;
                          }
                          final firstWordMatches = <String>[];
                          final otherWordMatches = <String>[];
                          for (final address in _savedAddresses) {
                            final words = address.toLowerCase().split(RegExp(r'\s+'));
                            if (words.isEmpty) continue;
                            if (words.first.startsWith(query)) {
                              firstWordMatches.add(address);
                            } else if (words.skip(1).any((word) => word.startsWith(query))) {
                              otherWordMatches.add(address);
                            }
                          }
                          return [...firstWordMatches, ...otherWordMatches];
                        },
                        onSelected: (selection) {
                          _addressController.text = selection;
                        },
                        fieldViewBuilder:
                            (context, controller, focusNode, onFieldSubmitted) {
                          return LayoutBuilder(
                            builder: (context, constraints) {
                              _addressFieldWidth = constraints.maxWidth;
                              return TextFormField(
                                controller: controller,
                                focusNode: focusNode,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                  color: colors.textPrimary,
                                ),
                                decoration: _buildInputDecoration(
                                  colors: colors,
                                  labelText: 'Address Location',
                                  prefixIcon: Icons.map_outlined,
                                ),
                              );
                            },
                          );
                        },
                        optionsViewBuilder: (context, onSelected, options) {
                          return Align(
                            alignment: Alignment.topLeft,
                            child: SizedBox(
                              width: _addressFieldWidth,
                              child: Material(
                                elevation: 8,
                                borderRadius: BorderRadius.circular(16),
                                color: colors.surface,
                                shadowColor: Colors.black.withValues(alpha: 0.3),
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: colors.borderColor),
                                  ),
                                  constraints: const BoxConstraints(maxHeight: 260),
                                  child: ListView.separated(
                                    padding: const EdgeInsets.symmetric(vertical: 6),
                                    shrinkWrap: true,
                                    itemCount: options.length,
                                    separatorBuilder: (_, _) => Divider(
                                      height: 1,
                                      indent: 16,
                                      endIndent: 16,
                                      color: colors.borderColor,
                                    ),
                                    itemBuilder: (context, index) {
                                      final option = options.elementAt(index);
                                      return Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          onTap: () => onSelected(option),
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 16,
                                            ),
                                            child: Row(
                                              children: [
                                                Icon(
                                                  Icons.location_on_rounded,
                                                  size: 20,
                                                  color: colors.accent,
                                                ),
                                                const SizedBox(width: 12),
                                                Expanded(
                                                  child: Text(
                                                    option,
                                                    style: TextStyle(
                                                      color: colors.textPrimary,
                                                      fontSize: 15,
                                                      fontWeight: FontWeight.w500,
                                                    ),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 20),

                      TextFormField(
                        controller: _dueAmountController,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: colors.due,
                        ),
                        decoration: _buildInputDecoration(
                          colors: colors,
                          labelText: 'Initial Due Amount',
                          prefixIcon: Icons.monetization_on_outlined,
                        ),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 20),

                      TextFormField(
                        controller: _dateController,
                        readOnly: true,
                        onTap: () => _selectDate(colors),
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: colors.textPrimary),
                        decoration: _buildInputDecoration(
                          colors: colors,
                          labelText: 'Select Date',
                          prefixIcon: Icons.calendar_today_rounded,
                        ),
                      ),
                      const SizedBox(height: 20),

                      TextFormField(
                        controller: _noteController,
                        maxLines: 3,
                        style: TextStyle(fontSize: 14, color: colors.textPrimary),
                        decoration: _buildInputDecoration(
                          colors: colors,
                          labelText: 'Additional Notes',
                          prefixIcon: Icons.description_outlined,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                if (_customFields.isNotEmpty)
                  ..._customFields.map((field) => _buildCustomFieldCard(field, colors)),
                InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => _addCustomField(colors),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Icon(Icons.add_rounded, size: 18, color: colors.accent),
                        const SizedBox(width: 6),
                        Text(
                          _customFields.isEmpty ? 'Add custom field' : 'Add another field',
                          style: TextStyle(
                            color: colors.accent,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                _isSaving
                    ? Center(child: CircularProgressIndicator(color: colors.accent))
                    : Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: LinearGradient(colors: [colors.accent, colors.accentAlt]),
                          boxShadow: [
                            BoxShadow(
                              color: colors.accent.withValues(alpha: 0.35),
                              blurRadius: 15,
                              offset: const Offset(0, 6),
                            )
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: _save,
                            child: const Padding(
                              padding: EdgeInsets.symmetric(vertical: 18),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.person_add_alt_1_rounded, size: 20, color: Colors.white),
                                  SizedBox(width: 8),
                                  Text(
                                    'Save Customer Account',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.3,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: CustomBottomNavBar(
        selectedIndex: _selectedIndex,
      ),
      ),
    );
  }
}