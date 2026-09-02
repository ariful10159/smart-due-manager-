import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../l10n/app_localizations.dart';
import '../models/customer.dart';
import '../models/payment.dart';
import '../theme/app_colors.dart';
import '../widgets/app_settings_scope.dart';

class AddPaymentScreen extends StatefulWidget {
  const AddPaymentScreen({
    super.key,
    required this.customer,
    required this.type,
  });

  final Customer customer;
  final PaymentType type;

  @override
  State<AddPaymentScreen> createState() => _AddPaymentScreenState();
}

class _AddPaymentScreenState extends State<AddPaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _discountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _dateController = TextEditingController();

  PaymentMethod? _selectedMethod;
  DateTime _selectedDate = DateTime.now();
  File? _selectedImage;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _dateController.text =
        "${_selectedDate.day}-${_selectedDate.month}-${_selectedDate.year}";
  }

  @override
  void dispose() {
    _amountController.dispose();
    _discountController.dispose();
    _descriptionController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(AppColors colors) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme(
              brightness: colors.scaffoldBg.computeLuminance() < 0.5
                  ? Brightness.dark
                  : Brightness.light,
              primary: const Color(0xFF10B981),
              onPrimary: Colors.white,
              secondary: colors.accent,
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
        _selectedDate = pickedDate;
        _dateController.text =
            "${pickedDate.day}-${pickedDate.month}-${pickedDate.year}";
      });
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
      maxWidth: 800,
      maxHeight: 800,
    );

    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

  Future<String?> _encodeImageToBase64() async {
    if (_selectedImage == null) return null;

    final bytes = await _selectedImage!.readAsBytes();

    if (bytes.length > 700 * 1024) {
      if (!mounted) return null;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.photoTooLarge)),
      );
      return null;
    }

    return base64Encode(bytes);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final l10n = AppLocalizations.of(context)!;

    final amountText = _amountController.text.trim();
    final amount = amountText.isEmpty ? 0.0 : double.tryParse(amountText);
    if (amount == null || amount < 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.enterValidAmount)));
      return;
    }

    final isPayment = widget.type == PaymentType.payment;
    final discountText = _discountController.text.trim();
    final discount = isPayment && discountText.isNotEmpty
        ? double.tryParse(discountText) ?? -1
        : 0.0;

    if (discount < 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.discountAmountInvalid)));
      return;
    }

    if (amount <= 0 && discount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isPayment ? l10n.amountOrDiscountRequired : l10n.enterValidAmount,
          ),
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final receiptBase64 = await _encodeImageToBase64();

      final payment = Payment(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        customerId: widget.customer.id,
        amount: amount,
        discount: discount,
        type: widget.type,
        paymentMethod: _selectedMethod,
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        receiptImageUrl: receiptBase64,
        date: _selectedDate,
      );

      if (!mounted) return;
      Navigator.pop(context, payment);
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  // পেমেন্ট মেথড সিলেকশনের জন্য কাস্টম উইজেট মেকার
  Widget _buildMethodChip(
    AppColors colors,
    PaymentMethod method,
    String label,
    IconData icon,
    Color activeColor,
  ) {
    final isSelected = _selectedMethod == method;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      child: ChoiceChip(
        avatar: Icon(
          icon,
          size: 16,
          color: isSelected ? Colors.white : colors.textSecondary,
        ),
        label: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : colors.textPrimary,
          ),
        ),
        selected: isSelected,
        selectedColor: activeColor,
        backgroundColor: colors.surfaceAlt,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(
            color: isSelected ? activeColor : colors.borderColor,
            width: 1,
          ),
        ),
        onSelected: _isSaving
            ? null
            : (selected) {
                setState(() {
                  _selectedMethod = selected ? method : null;
                });
              },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context); // ✅ dynamic dark/light কালার
    final l10n = AppLocalizations.of(context)!;
    // ✅ আগে এই স্ক্রিনে সবজায়গায় সরাসরি hardcoded "৳" বসানো ছিল — ইউজার
    // Settings > Currency তে অন্য symbol বেছে নিলেও এই স্ক্রিন সবসময় ৳ দেখাত
    final currencySymbol = AppSettingsScope.of(context).settings.currencySymbol;
    final currencyFmt = NumberFormat('#,##0.00');

    final isPayment = widget.type == PaymentType.payment;
    final themeColor = isPayment
        ? const Color(0xFF10B981)
        : const Color(0xFFEF4444); // Emerald Green vs Crimson Red
    final title = isPayment ? l10n.recordPayment : l10n.addCharge;

    return Scaffold(
      backgroundColor: colors.scaffoldBg,
      appBar: AppBar(
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 20,
            letterSpacing: 0.5,
            color: colors.textPrimary,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: colors.textPrimary),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: colors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 👤 Customer Card (Glassmorphic Look)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [colors.surface, colors.surfaceAlt],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                    border: Border.all(
                      color: colors.borderColor,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: themeColor.withValues(alpha: 0.18),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.person_rounded, color: themeColor, size: 26),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.customer.name,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: colors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              l10n.currentDueLabel('$currencySymbol${currencyFmt.format(widget.customer.totalDue)}'),
                              style: TextStyle(
                                fontSize: 13,
                                color: colors.due,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // 💵 Big Bold Amount Input Box
                Center(
                  child: Column(
                    children: [
                      Text(
                        l10n.enterAmountLabel,
                        style: TextStyle(
                          fontSize: 12,
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.w900,
                          color: colors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        constraints: const BoxConstraints(maxWidth: 260),
                        alignment: Alignment.center,
                        child: TextFormField(
                          controller: _amountController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          style: TextStyle(
                            fontSize: 38,
                            fontWeight: FontWeight.w900,
                            color: themeColor,
                          ),
                          textAlign: TextAlign.center,
                          decoration: InputDecoration(
                            prefixText: '$currencySymbol ',
                            prefixStyle: TextStyle(
                              fontSize: 34,
                              fontWeight: FontWeight.w800,
                              color: themeColor,
                            ),
                            hintText: '0.00',
                            hintStyle: TextStyle(
                              fontSize: 38,
                              fontWeight: FontWeight.w900,
                              color: colors.hintColor,
                            ),
                            border: InputBorder.none,
                            errorStyle: const TextStyle(fontSize: 12),
                          ),
                          validator: (value) {
                            final trimmed = (value ?? '').trim();
                            if (trimmed.isEmpty) {
                              // ✅ amount ফাঁকা রাখা যাবে যদি Record Payment হয় এবং
                              // Discount Amount দেওয়া থাকে (শুধু discount দিয়েও সেভ করা যাবে)
                              final isPayment = widget.type == PaymentType.payment;
                              final discount = double.tryParse(_discountController.text.trim());
                              if (isPayment && discount != null && discount > 0) {
                                return null;
                              }
                              return l10n.amountOrDiscountRequired;
                            }
                            final amount = double.tryParse(trimmed);
                            if (amount == null || amount < 0) {
                              return l10n.invalidAmount;
                            }
                            return null;
                          },
                        ),
                      ),
                      Container(
                        width: 140,
                        height: 2.5,
                        decoration: BoxDecoration(
                          color: themeColor.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ],
                  ),
                ),

                // 🏷️ Discount Amount (শুধু Record Payment এ প্রযোজ্য) — এই পরিমাণও
                // বকেয়া থেকে বাদ যায়, কিন্তু নগদ হিসেবে গণ্য হয় না
                if (isPayment) ...[
                  const SizedBox(height: 20),
                  Text(
                    l10n.discountAmountOptional,
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: colors.textPrimary),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _discountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w700),
                    decoration: InputDecoration(
                      prefixText: '$currencySymbol ',
                      hintText: '0.00',
                      hintStyle: TextStyle(color: colors.hintColor),
                      filled: true,
                      fillColor: colors.surface,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: colors.borderColor),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: colors.borderColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: themeColor, width: 1.5),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) return null;
                      final discount = double.tryParse(value.trim());
                      if (discount == null || discount < 0) {
                        return l10n.invalidDiscountAmount;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.discountHelperText,
                    style: TextStyle(fontSize: 11.5, color: colors.textSecondary),
                  ),
                ],

                const SizedBox(height: 36),

                // 📅 Date Selection Field
                Text(
                  l10n.transactionDate,
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: colors.textPrimary),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () => _selectDate(colors),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: colors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: colors.borderColor),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.calendar_month_rounded, color: themeColor, size: 22),
                            const SizedBox(width: 12),
                            Text(
                              _dateController.text,
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: colors.textPrimary),
                            ),
                          ],
                        ),
                        Icon(Icons.keyboard_arrow_down_rounded, color: colors.textSecondary),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // 💳 Dynamic Selector Chips for Payment Method
                Text(
                  l10n.paymentMethod,
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: colors.textPrimary),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 6,
                  children: [
                    _buildMethodChip(colors, PaymentMethod.handCash, l10n.cashMethod, Icons.payments_rounded, themeColor),
                    _buildMethodChip(colors, PaymentMethod.bKash, 'bKash', Icons.account_balance_wallet, themeColor),
                    _buildMethodChip(colors, PaymentMethod.nagad, 'Nagad', Icons.phonelink_ring_rounded, themeColor),
                    _buildMethodChip(colors, PaymentMethod.bank, l10n.bankMethod, Icons.account_balance_rounded, themeColor),
                  ],
                ),
                const SizedBox(height: 24),

                // 📝 Note/Description Input Field
                Text(
                  l10n.descriptionNote,
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: colors.textPrimary),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 2,
                  style: TextStyle(color: colors.textPrimary),
                  decoration: InputDecoration(
                    hintText: l10n.addDetailsHint,
                    hintStyle: TextStyle(color: colors.hintColor, fontSize: 14),
                    filled: true,
                    fillColor: colors.surface,
                    contentPadding: const EdgeInsets.all(16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: colors.borderColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: colors.borderColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: themeColor, width: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // 📸 Receipt Upload Frame
                Text(
                  l10n.transactionReceiptOptional,
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: colors.textPrimary),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    height: 140,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: colors.surface,
                      border: Border.all(
                        color: colors.borderColor,
                        style: BorderStyle.solid,
                        width: 1.2,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: _selectedImage != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Stack(
                              children: [
                                Image.file(
                                  _selectedImage!,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: double.infinity,
                                ),
                                Container(
                                  color: Colors.black.withValues(alpha: 0.2),
                                ),
                                Center(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(alpha: 0.6),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.edit_rounded, color: Colors.white, size: 16),
                                        const SizedBox(width: 6),
                                        Text(
                                          l10n.changeReceipt,
                                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: themeColor.withValues(alpha: 0.12),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.add_a_photo_outlined,
                                    size: 26,
                                    color: themeColor,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  l10n.tapToUploadReceipt,
                                  style: TextStyle(
                                    color: colors.textSecondary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 38),

                // 💾 Action Button
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: themeColor,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: colors.surfaceAlt,
                      shadowColor: themeColor.withValues(alpha: 0.4),
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.check_circle_rounded, size: 20),
                              const SizedBox(width: 10),
                              Text(
                                l10n.confirmTransaction,
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 0.5),
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}