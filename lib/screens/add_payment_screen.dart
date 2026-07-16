import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/customer.dart';
import '../models/payment.dart';

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
  final _descriptionController = TextEditingController();
  final _dateController = TextEditingController();

  PaymentMethod? _selectedMethod;
  DateTime _selectedDate = DateTime.now();
  File? _selectedImage;
  bool _isSaving = false;

  // 🎨 Dark navy theme palette (matches rest of the app)
  static const Color _scaffoldBg = Color(0xFF0F0F14);
  static const Color _surface = Color(0xFF1B1B24);
  static const Color _surfaceAlt = Color(0xFF20202B);
  static const Color _borderColor = Color(0xFF2C2C3A);
  static const Color _textPrimary = Colors.white;
  static const Color _textSecondary = Color(0xFF9A9AAE);
  static const Color _hintColor = Color(0xFF5C5C6E);

  @override
  void initState() {
    super.initState();
    _dateController.text =
        "${_selectedDate.day}-${_selectedDate.month}-${_selectedDate.year}";
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF10B981),
              surface: _surface,
              onSurface: _textPrimary,
            ),
            dialogBackgroundColor: _surface,
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
        const SnackBar(
          content: Text(
            'ছবিটা বেশি বড়, দয়া করে আরেকটু ছোট/হালকা ছবি বেছে নিন',
          ),
        ),
      );
      return null;
    }

    return base64Encode(bytes);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Enter a valid amount')));
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
  Widget _buildMethodChip(PaymentMethod method, String label, IconData icon, Color activeColor) {
    final isSelected = _selectedMethod == method;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      child: ChoiceChip(
        avatar: Icon(
          icon, 
          size: 16, 
          color: isSelected ? Colors.white : _textSecondary,
        ),
        label: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : _textPrimary,
          ),
        ),
        selected: isSelected,
        selectedColor: activeColor,
        backgroundColor: _surfaceAlt,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(
            color: isSelected ? activeColor : _borderColor,
            width: 1,
          ),
        ),
        onSelected: _isSaving ? null : (selected) {
          setState(() {
            _selectedMethod = selected ? method : null;
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isPayment = widget.type == PaymentType.payment;
    final themeColor = isPayment ? const Color(0xFF10B981) : const Color(0xFFEF4444); // Emerald Green vs Crimson Red
    final title = isPayment ? 'Record Payment' : 'Add Charge';
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: _scaffoldBg,
      appBar: AppBar(
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 20,
            letterSpacing: 0.5,
            color: _textPrimary,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: _textPrimary),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: _textPrimary),
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
                // 👤 Customer Card (Dark Glassmorphic Look)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [_surface, _surfaceAlt],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.25),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                    border: Border.all(
                      color: _borderColor,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: themeColor.withOpacity(0.18),
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
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: _textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Current Due: ৳${widget.customer.totalDue.toStringAsFixed(2)}",
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.red.shade300,
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
                        'ENTER AMOUNT',
                        style: TextStyle(
                          fontSize: 12,
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.w900,
                          color: _textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        // ✅ ফিক্সড: maxWidth দিতে Container-এর ভেতর constraints ব্যবহার করা হয়েছে
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
                            prefixText: '৳ ',
                            prefixStyle: TextStyle(
                              fontSize: 34,
                              fontWeight: FontWeight.w800,
                              color: themeColor,
                            ),
                            hintText: '0.00',
                            hintStyle: const TextStyle(
                              fontSize: 38,
                              fontWeight: FontWeight.w900,
                              color: _hintColor,
                            ),
                            border: InputBorder.none,
                            errorStyle: const TextStyle(fontSize: 12),
                          ),
                          validator: (value) {
                            final amount = double.tryParse((value ?? '').trim());
                            if (amount == null || amount <= 0) {
                              return 'Please enter amount';
                            }
                            return null;
                          },
                        ),
                      ),
                      Container(
                        width: 140,
                        height: 2.5,
                        decoration: BoxDecoration(
                          color: themeColor.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 36),

                // 📅 Date Selection Field (Custom Rounded Field)
                const Text(
                  'Transaction Date',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: _textPrimary),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: _selectDate,
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: _surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: _borderColor),
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
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: _textPrimary),
                            ),
                          ],
                        ),
                        const Icon(Icons.keyboard_arrow_down_rounded, color: _textSecondary),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // 💳 Dynamic Selector Chips for Payment Method
                const Text(
                  'Payment Method',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: _textPrimary),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 6,
                  children: [
                    _buildMethodChip(PaymentMethod.handCash, 'Cash', Icons.payments_rounded, themeColor),
                    _buildMethodChip(PaymentMethod.bKash, 'bKash', Icons.account_balance_wallet, themeColor),
                    _buildMethodChip(PaymentMethod.nagad, 'Nagad', Icons.phonelink_ring_rounded, themeColor),
                    _buildMethodChip(PaymentMethod.bank, 'Bank', Icons.account_balance_rounded, themeColor),
                  ],
                ),
                const SizedBox(height: 24),

                // 📝 Note/Description Input Field (Sleek Material design)
                const Text(
                  'Description / Note',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: _textPrimary),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 2,
                  style: const TextStyle(color: _textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Add additional details here...',
                    hintStyle: const TextStyle(color: _hintColor, fontSize: 14),
                    filled: true,
                    fillColor: _surface,
                    contentPadding: const EdgeInsets.all(16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: _borderColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: _borderColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: themeColor, width: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // 📸 Receipt Upload Frame (Modern Dotted Area Style)
                const Text(
                  'Transaction Receipt (Optional)',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: _textPrimary),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    height: 140,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: _surface,
                      border: Border.all(
                        color: _borderColor,
                        style: BorderStyle.solid,
                        width: 1.2,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
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
                                  color: Colors.black.withOpacity(0.2),
                                ),
                                Center(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.6),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.edit_rounded, color: Colors.white, size: 16),
                                        SizedBox(width: 6),
                                        Text(
                                          'Change Receipt',
                                          style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
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
                                    color: themeColor.withOpacity(0.12),
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
                                  'Tap to upload billing paper/slip',
                                  style: TextStyle(
                                    color: _textSecondary,
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

                // 💾 Beautiful Neo-Brutalism/Flat Action Button
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: themeColor,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: _surfaceAlt,
                      shadowColor: themeColor.withOpacity(0.4),
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
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.check_circle_rounded, size: 20),
                              SizedBox(width: 10),
                              Text(
                                'Confirm Transaction',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 0.5),
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