import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/customer.dart';
import '../theme/app_colors.dart';
import '../widgets/custom_bottom_nav_bar.dart';

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

  File? _selectedImage;
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _dueAmountController.dispose();
    _phoneController.dispose();
    _dateController.dispose();
    _noteController.dispose();
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
            dialogBackgroundColor: colors.surface,
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

  // ✨ ফর্মের সব ডেটা রিসেট করার জন্য নতুন মেথড
  void _resetForm() {
    _nameController.clear();
    _phoneController.clear();
    _addressController.clear();
    _dueAmountController.clear();
    _dateController.clear();
    _noteController.clear();
    setState(() {
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
                      style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.9)),
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
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save: $e'),
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

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context); // ✅ dynamic dark/light কালার

    return Scaffold(
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
                              colors.accent.withOpacity(0.35),
                              colors.accentAlt.withOpacity(0.15),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: colors.accent.withOpacity(0.2),
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
                                  color: colors.accent.withOpacity(0.3),
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
                        color: Colors.black.withOpacity(0.15),
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

                      TextFormField(
                        controller: _addressController,
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: colors.textPrimary),
                        decoration: _buildInputDecoration(
                          colors: colors,
                          labelText: 'Address Location',
                          prefixIcon: Icons.map_outlined,
                        ),
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
                const SizedBox(height: 32),

                _isSaving
                    ? Center(child: CircularProgressIndicator(color: colors.accent))
                    : Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: LinearGradient(colors: [colors.accent, colors.accentAlt]),
                          boxShadow: [
                            BoxShadow(
                              color: colors.accent.withOpacity(0.35),
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
    );
  }
}