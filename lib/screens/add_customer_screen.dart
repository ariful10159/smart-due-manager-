import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/customer.dart';
import 'all_customers_screen.dart';
import 'home_screen.dart';
import 'reminder_screen.dart';

class AddCustomerScreen extends StatefulWidget {
  const AddCustomerScreen({super.key});

  @override
  State<AddCustomerScreen> createState() =>
      _AddCustomerScreenState();
}

class _AddCustomerScreenState
    extends State<AddCustomerScreen> {
  final _formKey = GlobalKey<FormState>();

  int _selectedIndex = 1;

  final _nameController = TextEditingController();
  final _addressController =
      TextEditingController(); // ✅ NEW
  final _dueAmountController =
      TextEditingController();
  final _phoneController =
      TextEditingController();
  final _dateController =
      TextEditingController();
  final _noteController =
      TextEditingController();

  File? _selectedImage;
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose(); // ✅ NEW
    _dueAmountController.dispose();
    _phoneController.dispose();
    _dateController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    DateTime? pickedDate =
        await showDatePicker(
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
    final picker = ImagePicker();
    final image =
        await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (image != null) {
      setState(() {
        _selectedImage =
            File(image.path);
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!
        .validate()) return;

    final totalDue =
        double.tryParse(
              _dueAmountController
                  .text
                  .trim(),
            ) ??
            0.0;

    DateTime? lastPaymentDate;
    final dateText =
        _dateController.text.trim();

    if (dateText.isNotEmpty) {
      final parts =
          dateText.split('-');
      if (parts.length == 3) {
        final day =
            int.tryParse(parts[0]);
        final month =
            int.tryParse(parts[1]);
        final year =
            int.tryParse(parts[2]);

        if (day != null &&
            month != null &&
            year != null) {
          lastPaymentDate =
              DateTime(year, month, day);
        }
      }
    }

    final customer =
        Customer(
      id: DateTime.now()
          .millisecondsSinceEpoch
          .toString(),
      name:
          _nameController.text.trim(),
      address: _addressController.text.trim().isEmpty
          ? null
          : _addressController.text.trim(), // ✅ NEW
      phone:
          _phoneController.text.trim(),
      totalDue: totalDue,
      lastPaymentDate:
          lastPaymentDate ??
              DateTime.now(),
      createdAt: DateTime.now(),
      note: _noteController
              .text
              .trim()
              .isEmpty
          ? null
          : _noteController.text
              .trim(),
    );

    setState(() {
      _isSaving = true;
    });

    try {
      await FirebaseFirestore
          .instance
          .collection(
              'customers')
          .doc(customer.id)
          .set(customer.toMap());

      if (!mounted) return;

      Navigator.of(context)
          .pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) =>
              const HomeScreen(),
        ),
        (route) => false,
      );
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
            content: Text(
                'Failed to save: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  // ✅ Bottom Navigation
  void _onDestinationSelected(
      int index) {
    if (index == _selectedIndex)
      return;

    switch (index) {
      case 0:
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
              builder: (_) =>
                  const HomeScreen()),
          (route) => false,
        );
        break;
      case 2:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (_) =>
                  const AllCustomersScreen()),
        );
        break;
      case 3:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (_) =>
                  const ReminderScreen()),
        );
        break;
    }
  }

  @override
  Widget build(
      BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title:
              const Text(
                  'Add Customer')),
      body: Padding(
        padding:
            const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child:
              SingleChildScrollView(
            child: Column(
              children: [
                GestureDetector(
                  onTap:
                      _pickImage,
                  child:
                      CircleAvatar(
                    radius: 45,
                    backgroundImage:
                        _selectedImage !=
                                null
                            ? FileImage(
                                _selectedImage!)
                            : null,
                    child:
                        _selectedImage ==
                                null
                            ? const Icon(
                                Icons
                                    .add_a_photo,
                                size: 35,
                              )
                            : null,
                  ),
                ),

                const SizedBox(height: 20),

                // ✅ Name
                TextFormField(
                  controller:
                      _nameController,
                  decoration:
                      const InputDecoration(
                          labelText:
                              'Name'),
                  validator: (value) =>
                      value ==
                                  null ||
                              value
                                  .trim()
                                  .isEmpty
                          ? 'Enter name'
                          : null,
                ),

                // ✅ Address (NEW FIELD)
                TextFormField(
                  controller:
                      _addressController,
                  decoration:
                      const InputDecoration(
                          labelText:
                              'Address'),
                ),

                TextFormField(
                  controller:
                      _dueAmountController,
                  decoration:
                      const InputDecoration(
                          labelText:
                              'Due Amount'),
                  keyboardType:
                      TextInputType
                          .number,
                ),

                TextFormField(
                  controller:
                      _phoneController,
                  decoration:
                      const InputDecoration(
                          labelText:
                              'Phone'),
                  keyboardType:
                      TextInputType
                          .phone,
                ),

                TextFormField(
                  controller:
                      _dateController,
                  readOnly: true,
                  decoration:
                      const InputDecoration(
                    labelText: 'Date',
                    suffixIcon:
                        Icon(Icons
                            .calendar_today),
                  ),
                  onTap:
                      _selectDate,
                ),

                TextFormField(
                  controller:
                      _noteController,
                  decoration:
                      const InputDecoration(
                          labelText:
                              'Note'),
                ),

                const SizedBox(height: 25),

                _isSaving
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed:
                            _save,
                        child:
                            const Text(
                                'Save Customer'),
                      ),
              ],
            ),
          ),
        ),
      ),

      // ✅ SAME NAVIGATION BAR
      bottomNavigationBar:
          NavigationBar(
        selectedIndex:
            _selectedIndex,
        onDestinationSelected:
            _onDestinationSelected,
        destinations: const [
          NavigationDestination(
            icon: Icon(
                Icons.home_outlined),
            selectedIcon:
                Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons
                .person_add_alt_1),
            label:
                'Add Customer',
          ),
          NavigationDestination(
            icon: Icon(
                Icons.people_outline),
            selectedIcon:
                Icon(Icons.people),
            label:
                'All Customers',
          ),
          NavigationDestination(
            icon: Icon(Icons
                .notifications_outlined),
            selectedIcon:
                Icon(Icons
                    .notifications),
            label: 'Reminders',
          ),
        ],
      ),
    );
  }
}