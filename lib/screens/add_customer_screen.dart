import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/customer.dart';

class AddCustomerScreen extends StatefulWidget {
  const AddCustomerScreen({super.key});

  @override
  State<AddCustomerScreen> createState() => _AddCustomerScreenState();
}

class _AddCustomerScreenState extends State<AddCustomerScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _dueAmountController = TextEditingController();
  final _phoneController = TextEditingController();
  final _dateController = TextEditingController();
  final _noteController = TextEditingController();

  File? _selectedImage;
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _dueAmountController.dispose();
    _phoneController.dispose();
    _dateController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null) {
      setState(() {
        _dateController.text =
            "${pickedDate.day}-${pickedDate.month}-${pickedDate.year}";
      });
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

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
      phone: _phoneController.text.trim(),
      totalDue: totalDue,
      lastPaymentDate: lastPaymentDate ?? DateTime.now(),
      createdAt: DateTime.now(),
      note: _noteController.text.trim().isEmpty
          ? null
          : _noteController.text.trim(),
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
      Navigator.of(context).pop(customer);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to save customer: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Customer')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                GestureDetector(
                  onTap: _pickImage,
                  child: CircleAvatar(
                    radius: 45,
                    backgroundImage: _selectedImage != null
                        ? FileImage(_selectedImage!)
                        : null,
                    child: _selectedImage == null
                        ? const Icon(Icons.add_a_photo, size: 35)
                        : null,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  "Add Photo (Optional)",
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Name'),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Enter a name'
                      : null,
                ),
                TextFormField(
                  controller: _dueAmountController,
                  decoration: const InputDecoration(labelText: 'Due Amount'),
                  keyboardType: TextInputType.number,
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Enter a due amount'
                      : null,
                ),
                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(labelText: 'Phone'),
                  keyboardType: TextInputType.phone,
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Enter a phone number'
                      : null,
                ),
                TextFormField(
                  controller: _dateController,
                  readOnly: true,
                  decoration: const InputDecoration(
                    labelText: 'Date',
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  onTap: _selectDate,
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Select a date'
                      : null,
                ),
                TextFormField(
                  controller: _noteController,
                  decoration: const InputDecoration(labelText: 'Note'),
                ),
                const SizedBox(height: 25),
                _isSaving
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: _save,
                        child: const Text('Save Customer'),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
