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
  final _noteController = TextEditingController();
  final _descriptionController = TextEditingController();

  // ✅ Payment Method
  PaymentMethod? _selectedPaymentMethod;

  // ✅ Image
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  // ✅ Image Picker Bottom Sheet
  Future<void> _pickImage() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Select Image Source',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const CircleAvatar(
                child: Icon(Icons.camera_alt),
              ),
              title: const Text('Camera'),
              onTap: () async {
                Navigator.pop(context);
                final XFile? image = await _picker.pickImage(
                  source: ImageSource.camera,
                  imageQuality: 70,
                );
                if (image != null) {
                  setState(() {
                    _selectedImage = File(image.path);
                  });
                }
              },
            ),
            ListTile(
              leading: const CircleAvatar(
                child: Icon(Icons.photo_library),
              ),
              title: const Text('Gallery'),
              onTap: () async {
                Navigator.pop(context);
                final XFile? image = await _picker.pickImage(
                  source: ImageSource.gallery,
                  imageQuality: 70,
                );
                if (image != null) {
                  setState(() {
                    _selectedImage = File(image.path);
                  });
                }
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // ✅ Remove Image
  void _removeImage() {
    setState(() {
      _selectedImage = null;
    });
  }

  // ✅ Save Payment
  void _savePayment() {
    if (!_formKey.currentState!.validate()) return;

    final payment = Payment(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      customerId: widget.customer.id,
      amount: double.parse(_amountController.text.trim()),
      type: widget.type,
      paymentMethod: _selectedPaymentMethod,
      note: _noteController.text.trim().isEmpty
          ? null
          : _noteController.text.trim(),
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      receiptImageUrl: null,
      receiptImageFile: _selectedImage,
      date: DateTime.now(),
    );

    Navigator.of(context).pop(payment);
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.type == PaymentType.payment
        ? 'Record Payment'
        : 'Add Charge';

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [

              // ✅ Amount Field
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(
                  labelText: 'Amount *',
                  prefixIcon: Icon(Icons.attach_money),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Amount is required';
                  }
                  if (double.tryParse(value.trim()) == null) {
                    return 'Enter a valid number';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // ✅ Payment Method Dropdown
              DropdownButtonFormField<PaymentMethod>(
                value: _selectedPaymentMethod,
                decoration: const InputDecoration(
                  labelText: 'Payment Method (Optional)',
                  prefixIcon: Icon(Icons.payment),
                  border: OutlineInputBorder(),
                ),
                items: PaymentMethod.values.map((method) {
                  return DropdownMenuItem<PaymentMethod>(
                    value: method,
                    child: Row(
                      children: [
                        Icon(_getPaymentMethodIcon(method)),
                        const SizedBox(width: 8),
                        Text(Payment.paymentMethodToString(method)),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedPaymentMethod = value;
                  });
                },
                hint: const Text('Select Payment Method'),
              ),

              const SizedBox(height: 16),

              // ✅ Note Field
              TextFormField(
                controller: _noteController,
                decoration: const InputDecoration(
                  labelText: 'Note (Optional)',
                  prefixIcon: Icon(Icons.note),
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 16),

              // ✅ Description Field
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (Optional)',
                  prefixIcon: Icon(Icons.description),
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: 3,
              ),

              const SizedBox(height: 16),

              // ✅ Image Picker Section
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.receipt_long, color: Colors.grey),
                        SizedBox(width: 8),
                        Text(
                          'Receipt Image (Optional)',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // ✅ Image Preview or Add Button
                    if (_selectedImage == null)
                      OutlinedButton.icon(
                        onPressed: _pickImage,
                        icon: const Icon(Icons.add_a_photo),
                        label: const Text('Add Receipt Image'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          minimumSize: const Size(double.infinity, 0),
                        ),
                      )
                    else
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              _selectedImage!,
                              height: 200,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                          // ✅ Remove Button
                          Positioned(
                            top: 8,
                            right: 8,
                            child: GestureDetector(
                              onTap: _removeImage,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                          // ✅ Change Button
                          Positioned(
                            bottom: 8,
                            right: 8,
                            child: GestureDetector(
                              onTap: _pickImage,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(
                                      Icons.edit,
                                      color: Colors.white,
                                      size: 14,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'Change',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ✅ Save Button
              ElevatedButton(
                onPressed: _savePayment,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 16),
                ),
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  // ✅ Payment Method Icon
  IconData _getPaymentMethodIcon(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.bKash:
        return Icons.phone_android;
      case PaymentMethod.nagad:
        return Icons.phone_android;
      case PaymentMethod.handCash:
        return Icons.money;
      case PaymentMethod.bank:
        return Icons.account_balance;
    }
  }
}