import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/customer.dart';
import '../models/payment.dart';
import '../models/customer_repository.dart';
import '../services/notification_service.dart';
import '../theme/app_colors.dart';
import '../widgets/app_settings_scope.dart';
import '../widgets/payment_history_tile.dart';
import 'add_payment_screen.dart';
import 'reminder_history_screen.dart';

class CustomerDetailScreen extends StatefulWidget {
  const CustomerDetailScreen({super.key, required this.customer});

  final Customer customer;

  @override
  State<CustomerDetailScreen> createState() => _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends State<CustomerDetailScreen> {
  final _customerRepo = CustomerRepository();

  String _formatDateTime(DateTime date) {
    return DateFormat('d MMMM yyyy • hh:mm a').format(date);
  }

  String _formatDateOnly(DateTime date) {
    return DateFormat('d MMMM yyyy').format(date);
  }

  String _buildDueMessage(Customer customer) {
    final settings = AppSettingsScope.of(context).settings;
    final dateFmt = DateFormat('d MMM yyyy');
    final currencyFmt = NumberFormat('#,##0.00');

    return settings.smsReminderTemplate
        .replaceAll('{name}', customer.name)
        .replaceAll('{amount}', currencyFmt.format(customer.totalDue))
        .replaceAll('{due_date}', dateFmt.format(customer.lastPaymentDate))
        .replaceAll('{business_name}', settings.businessName)
        .replaceAll('{phone}', customer.phone);
  }

  String _daysSincePayment(DateTime lastPaymentDate) {
    final days = DateTime.now().difference(lastPaymentDate).inDays;
    if (days == 0) return "আজকে";
    if (days == 1) return "গতকাল";
    return "$days দিন আগে";
  }

  // ✅ বাংলা টেক্সট কে PDF এর জন্য ছবি বানানো হচ্ছে — pdf প্যাকেজ বাংলার
  // যুক্তাক্ষর/matra ঠিকভাবে shape করতে পারে না, কিন্তু Flutter এর নিজস্ব
  // rendering engine পারে। তাই Flutter দিয়ে রেন্ডার করে ছবি বানিয়ে PDF এ বসানো হচ্ছে।
  Future<pw.Widget> _bengaliText(
    String text, {
    double fontSize = 11,
    FontWeight fontWeight = FontWeight.normal,
    ui.Color color = const ui.Color(0xFF000000),
  }) async {
    const scale = 3.0; // ক্রিস্প রেজোলিউশনের জন্য বড় করে রেন্ডার করা হচ্ছে

    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontFamily: 'NotoSerifBengali',
          fontSize: fontSize * scale,
          fontWeight: fontWeight,
          color: color,
        ),
      ),
      textDirection: ui.TextDirection.ltr, // Fixed TextDirection reference
    );
    textPainter.layout();

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    textPainter.paint(canvas, Offset.zero);
    final picture = recorder.endRecording();

    final image = await picture.toImage(
      textPainter.width.ceil().clamp(1, 5000),
      textPainter.height.ceil().clamp(1, 500),
    );
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final bytes = byteData!.buffer.asUint8List();

    return pw.Image(
      pw.MemoryImage(bytes),
      width: textPainter.width / scale,
      height: textPainter.height / scale,
    );
  }

  Future<pw.Document> _generatePdf(Customer customer) async {
    final payments = await _customerRepo.streamPayments(customer.id).first;
    final settings = AppSettingsScope.of(context).settings;

    final bengaliRegular = await rootBundle.load(
      'assets/fonts/NotoSerifBengali_Condensed-Regular.ttf',
    );
    final bengaliBold = await rootBundle.load(
      'assets/fonts/NotoSerifBengali-Bold.ttf',
    );

    final regularFont = pw.Font.ttf(bengaliRegular);
    final boldFont = pw.Font.ttf(bengaliBold);

    // ✅ যেসব field এ বাংলা টেক্সট থাকতে পারে, সেগুলোকে আগে থেকেই
    // ছবি হিসেবে render করে রাখা হচ্ছে (async, PDF build শুরুর আগে)
    final businessNameImg = await _bengaliText(
      settings.businessName,
      fontSize: 16,
      fontWeight: FontWeight.bold,
    );

    final businessAddressImg = settings.businessAddress.isNotEmpty
        ? await _bengaliText(settings.businessAddress, fontSize: 10)
        : null;

    final customerNameImg = await _bengaliText(customer.name, fontSize: 11);

    final customerAddressImg = customer.address != null
        ? await _bengaliText(customer.address!, fontSize: 11)
        : null;

    // ✅ Payment history এর Note কলামে বাংলা থাকলে সেগুলোও ছবি বানানো হচ্ছে
    final noteImages = <int, pw.Widget>{};
    for (var i = 0; i < payments.length; i++) {
      final note = payments[i].note;
      if (note != null && note.trim().isNotEmpty) {
        noteImages[i] = await _bengaliText(note, fontSize: 9);
      }
    }

    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        theme: pw.ThemeData.withFont(base: regularFont, bold: boldFont),
        build: (context) => [
          businessNameImg,
          if (businessAddressImg != null) businessAddressImg,
          pw.SizedBox(height: 12),
          pw.Text(
            'Customer Payment History',
            style: pw.TextStyle(
              fontSize: 22,
              fontWeight: pw.FontWeight.bold,
              font: boldFont,
            ),
          ),
          pw.SizedBox(height: 16),

          pw.Row(
            children: [
              pw.Text('Name: ', style: pw.TextStyle(font: regularFont)),
              customerNameImg,
            ],
          ),
          pw.Text(
            'Phone: ${customer.phone}',
            style: pw.TextStyle(font: regularFont),
          ),
          if (customerAddressImg != null)
            pw.Row(
              children: [
                pw.Text('Address: ', style: pw.TextStyle(font: regularFont)),
                customerAddressImg,
              ],
            ),
          pw.Text(
            'Due Date: ${_formatDateOnly(customer.lastPaymentDate)}',
            style: pw.TextStyle(font: regularFont),
          ),
          pw.Text(
            'Total Due: ${settings.currencySymbol}${customer.totalDue.toStringAsFixed(2)}',
            style: pw.TextStyle(font: regularFont),
          ),
          if (customer.nextReminderDate != null)
            pw.Text(
              'Next Reminder: ${_formatDateTime(customer.nextReminderDate!)}',
              style: pw.TextStyle(font: regularFont),
            ),
          pw.SizedBox(height: 20),
          pw.Text(
            'Payment History',
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
              font: boldFont,
            ),
          ),
          pw.SizedBox(height: 10),

          if (payments.isEmpty)
            pw.Text(
              'No transactions yet',
              style: pw.TextStyle(font: regularFont),
            )
          else
            pw.Table(
              border: pw.TableBorder.all(width: 0.5),
              children: [
                pw.TableRow(
                  children: ['Date', 'Type', 'Amount', 'Note'].map((h) {
                    return pw.Padding(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Text(
                        h,
                        style: pw.TextStyle(font: boldFont, fontSize: 10),
                      ),
                    );
                  }).toList(),
                ),
                ...List.generate(payments.length, (i) {
                  final payment = payments[i];
                  return pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text(
                          _formatDateTime(payment.date),
                          style: pw.TextStyle(font: regularFont, fontSize: 9),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text(
                          payment.type == PaymentType.payment
                              ? 'Record Payment'
                              : 'Add Charge',
                          style: pw.TextStyle(font: regularFont, fontSize: 9),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text(
                          payment.amount.toStringAsFixed(2),
                          style: pw.TextStyle(font: regularFont, fontSize: 9),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: noteImages[i] ?? pw.SizedBox(),
                      ),
                    ],
                  );
                }),
              ],
            ),
        ],
      ),
    );

    return pdf;
  }

  Future<void> _printPdf(Customer customer) async {
    final pdf = await _generatePdf(customer);
    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  Future<void> _downloadPdf(Customer customer) async {
    final colors = AppColors.of(context);
    try {
      final pdf = await _generatePdf(customer);
      final bytes = await pdf.save();

      final directory = Directory('/storage/emulated/0/Download');

      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }

      final fileName =
          "${customer.name.replaceAll(" ", "_")}_payment_history.pdf";

      final filePath = "${directory.path}/$fileName";
      final file = File(filePath);
      await file.writeAsBytes(bytes);

      if (!mounted) return;

      await Share.shareXFiles([
        XFile(filePath),
      ], text: "${customer.name} - Payment History");

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: colors.clear,
          content: const Text("PDF saved and opened ✅"),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: colors.due,
          content: Text("Download failed: $e"),
        ),
      );
    }
  }

  Future<void> _addPayment(Customer currentCustomer, PaymentType type) async {
    final payment = await Navigator.of(context).push<Payment>(
      MaterialPageRoute(
        builder: (_) => AddPaymentScreen(customer: currentCustomer, type: type),
      ),
    );

    if (payment == null) return;

    double updatedDue = type == PaymentType.payment
        ? currentCustomer.totalDue - payment.amount
        : currentCustomer.totalDue + payment.amount;

    if (updatedDue < 0) updatedDue = 0;

    await _customerRepo.updateCustomerDue(
      customerId: currentCustomer.id,
      newTotalDue: updatedDue,
      lastPaymentDate: currentCustomer.lastPaymentDate,
    );

    await _customerRepo.addPayment(
      customerId: currentCustomer.id,
      payment: payment,
    );
  }

  Future<void> _setReminder(Customer customer) async {
    final colors = AppColors.of(context);

    final selectedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      builder: (context, child) => _themedPickerWrapper(context, child, colors),
    );

    if (selectedDate == null) return;
    if (!mounted) return;

    final selectedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) => _themedPickerWrapper(context, child, colors),
    );

    if (selectedTime == null) return;

    final scheduledDateTime = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      selectedTime.hour,
      selectedTime.minute,
    );

    await _customerRepo.addReminder(
      customerId: customer.id,
      reminderDate: scheduledDateTime,
    );

    await NotificationService.scheduleReminder(
      id: customer.hashCode,
      title: "Payment Reminder",
      body: "${customer.name} will pay now",
      scheduledDate: scheduledDateTime,
    );

    final smsMessage = _buildDueMessage(customer);

    await NotificationService.scheduleSms(
      taskId: 'sms_${customer.id}',
      phoneNumber: customer.phone,
      message: smsMessage,
      scheduledDate: scheduledDateTime,
      customerId: customer.id,
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Reminder Updated ✅")),
    );
  }

  Widget _themedPickerWrapper(BuildContext context, Widget? child, AppColors colors) {
    return Theme(
      data: Theme.of(context).copyWith(
        colorScheme: ColorScheme(
          brightness: colors.scaffoldBg.computeLuminance() < 0.5 ? Brightness.dark : Brightness.light,
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
  }

  Future<void> _confirmClearReminder(Customer customer) async {
    final colors = AppColors.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: colors.borderColor),
        ),
        title: Text("Cancel Reminder", style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w800)),
        content: Text(
          "'${customer.name}' এর জন্য সেট করা reminder টা বাতিল করতে চান?",
          style: TextStyle(color: colors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text("Cancel", style: TextStyle(color: colors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text("Remove Reminder", style: TextStyle(color: colors.due, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _clearReminder(customer);
    }
  }

  Future<void> _clearReminder(Customer customer) async {
    final colors = AppColors.of(context);
    try {
      await _customerRepo.clearReminder(customer.id);
      await NotificationService.cancelScheduledSms('sms_${customer.id}');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: colors.clear,
          content: const Text("Reminder removed ✅"),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: colors.due,
          content: Text("Failed to remove reminder: $e"),
        ),
      );
    }
  }

  Future<void> _confirmDeleteCustomer(Customer customer) async {
    final colors = AppColors.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: colors.borderColor),
        ),
        title: Text("Hide Customer", style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w800)),
        content: Text(
          "আপনি কি নিশ্চিত '${customer.name}' কে হাইড করতে চান? "
          "এটি main list থেকে সরে যাবে, কিন্তু সব তথ্য ও payment history "
          "সংরক্ষিত থাকবে। প্রয়োজনে পরে Archived section থেকে আবার "
          "ফিরিয়ে আনা যাবে।",
          style: TextStyle(color: colors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text("Cancel", style: TextStyle(color: colors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text("Hide", style: TextStyle(color: colors.due, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _hideCustomer(customer);
    }
  }

  Future<void> _hideCustomer(Customer customer) async {
    final colors = AppColors.of(context);
    try {
      await _customerRepo.hideCustomer(customer.id);

      if (!mounted) return;

      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: colors.clear,
          content: Text("${customer.name} hidden successfully"),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(backgroundColor: colors.due, content: Text("Hide failed: $e")),
      );
    }
  }

  Future<String?> _encodeImageToBase64(File imageFile) async {
    final bytes = await imageFile.readAsBytes();

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

  Future<void> _editCustomer(Customer customer) async {
    final colors = AppColors.of(context);

    final nameController = TextEditingController(text: customer.name);
    final phoneController = TextEditingController(text: customer.phone);
    final addressController = TextEditingController(
      text: customer.address ?? '',
    );
    final noteController = TextEditingController(text: customer.note ?? '');
    final dueAmountController = TextEditingController(
      text: customer.totalDue.toStringAsFixed(2),
    );
    final dateController = TextEditingController(
      text:
          "${customer.lastPaymentDate.day}-${customer.lastPaymentDate.month}-${customer.lastPaymentDate.year}",
    );

    File? newSelectedImage;
    bool isSavingEdit = false;

    int dateTapCount = 0;
    bool dateUnlocked = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            Future<void> pickEditImage() async {
              final picker = ImagePicker();
              final image = await picker.pickImage(
                source: ImageSource.gallery,
                imageQuality: 70,
                maxWidth: 400,
                maxHeight: 400,
              );
              if (image != null) {
                setDialogState(() {
                  newSelectedImage = File(image.path);
                });
              }
            }

            Future<void> handleDateTap() async {
              if (!dateUnlocked) {
                setDialogState(() {
                  dateTapCount++;
                  if (dateTapCount >= 7) {
                    dateUnlocked = true;
                  }
                });
                return;
              }

              final pickedDate = await showDatePicker(
                context: dialogContext,
                initialDate: customer.lastPaymentDate,
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
                builder: (ctx, child) => _themedPickerWrapper(ctx, child, colors),
              );

              if (pickedDate != null) {
                setDialogState(() {
                  dateController.text =
                      "${pickedDate.day}-${pickedDate.month}-${pickedDate.year}";
                });
              }
            }

            return AlertDialog(
              backgroundColor: colors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: BorderSide(color: colors.borderColor),
              ),
              title: Text("Edit Customer", style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w800)),
              content: SingleChildScrollView(
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: pickEditImage,
                      child: CircleAvatar(
                        radius: 40,
                        backgroundColor: colors.surfaceAlt,
                        backgroundImage: newSelectedImage != null
                            ? FileImage(newSelectedImage!)
                            : (customer.photoUrl != null
                                  ? MemoryImage(
                                          base64Decode(customer.photoUrl!),
                                        )
                                        as ImageProvider
                                  : null),
                        child:
                            newSelectedImage == null &&
                                customer.photoUrl == null
                            ? Icon(Icons.add_a_photo, size: 30, color: colors.textSecondary)
                            : null,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: nameController,
                      style: TextStyle(color: colors.textPrimary),
                      decoration: InputDecoration(
                        labelText: "Name",
                        labelStyle: TextStyle(color: colors.textSecondary),
                      ),
                    ),
                    TextField(
                      controller: phoneController,
                      style: TextStyle(color: colors.textPrimary),
                      decoration: InputDecoration(
                        labelText: "Phone",
                        labelStyle: TextStyle(color: colors.textSecondary),
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                    TextField(
                      controller: addressController,
                      style: TextStyle(color: colors.textPrimary),
                      decoration: InputDecoration(
                        labelText: "Address",
                        labelStyle: TextStyle(color: colors.textSecondary),
                      ),
                    ),
                    TextField(
                      controller: dueAmountController,
                      style: TextStyle(color: colors.textSecondary),
                      decoration: InputDecoration(
                        labelText: "Due Amount",
                        labelStyle: TextStyle(color: colors.textSecondary),
                      ),
                      readOnly: true,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 4),
                    TextField(
                      controller: dateController,
                      readOnly: true,
                      enabled: true,
                      onTap: handleDateTap,
                      style: TextStyle(
                        color: dateUnlocked ? colors.textPrimary : colors.textSecondary,
                      ),
                      decoration: InputDecoration(
                        labelText: dateUnlocked ? 'Due Date (এডিট করা যাবে)' : 'Due Date',
                        labelStyle: TextStyle(color: colors.textSecondary),
                        suffixIcon: Icon(
                          dateUnlocked ? Icons.lock_open_rounded : Icons.lock_outline_rounded,
                          color: dateUnlocked ? colors.clear : colors.textSecondary,
                          size: 18,
                        ),
                      ),
                    ),
                    if (!dateUnlocked && dateTapCount > 0)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            "আনলক করতে আরও ${7 - dateTapCount} বার ট্যাপ করুন",
                            style: TextStyle(fontSize: 11, color: colors.warn),
                          ),
                        ),
                      ),
                    if (dateUnlocked)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            "তারিখ পরিবর্তনযোগ্য — সরাসরি payment/charge এতে প্রভাব ফেলবে না",
                            style: TextStyle(fontSize: 11, color: colors.clear),
                          ),
                        ),
                      ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: noteController,
                      style: TextStyle(color: colors.textPrimary),
                      decoration: InputDecoration(
                        labelText: "Note",
                        labelStyle: TextStyle(color: colors.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSavingEdit
                      ? null
                      : () => Navigator.pop(dialogContext),
                  child: Text("Cancel", style: TextStyle(color: colors.textSecondary)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.accent,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: isSavingEdit
                      ? null
                      : () async {
                          setDialogState(() {
                            isSavingEdit = true;
                          });

                          String? photoBase64;
                          if (newSelectedImage != null) {
                            photoBase64 = await _encodeImageToBase64(
                              newSelectedImage!,
                            );
                          }

                          final totalDue = double.tryParse(
                            dueAmountController.text.trim(),
                          );

                          DateTime? lastPaymentDate;
                          final dateText = dateController.text.trim();
                          if (dateText.isNotEmpty) {
                            final parts = dateText.split('-');
                            if (parts.length == 3) {
                              final day = int.tryParse(parts[0]);
                              final month = int.tryParse(parts[1]);
                              final year = int.tryParse(parts[2]);
                              if (day != null &&
                                  month != null &&
                                  year != null) {
                                lastPaymentDate = DateTime(year, month, day);
                              }
                            }
                          }

                          await _customerRepo.updateCustomerInfo(
                            customerId: customer.id,
                            name: nameController.text.trim(),
                            phone: phoneController.text.trim(),
                            address: addressController.text.trim(),
                            note: noteController.text.trim(),
                            totalDue: totalDue,
                            lastPaymentDate: dateUnlocked ? lastPaymentDate : null,
                            photoUrl: photoBase64,
                          );

                          if (!mounted) return;
                          Navigator.pop(dialogContext);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: colors.clear,
                              content: const Text("Customer details updated ✅"),
                            ),
                          );
                        },
                  child: isSavingEdit
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text("Save"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showSmsHistory(Customer customer) {
    final colors = AppColors.of(context);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: colors.borderColor),
        ),
        title: Text("SMS Sent History", style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w800)),
        content: SizedBox(
          width: double.maxFinite,
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: _customerRepo.streamSmsLogs(customer.id),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return Center(
                  child: SizedBox(
                    height: 100,
                    child: CircularProgressIndicator(color: colors.accent),
                  ),
                );
              }

              final logs = snapshot.data!;

              if (logs.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Text("এখনো কোনো SMS পাঠানো হয়নি", style: TextStyle(color: colors.textSecondary)),
                );
              }

              return ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 350),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: logs.length,
                  separatorBuilder: (_, __) => Divider(height: 1, color: colors.borderColor),
                  itemBuilder: (context, index) {
                    final log = logs[index];
                    final sentAt = (log['sentAt'] as Timestamp).toDate();
                    final type = log['type'] as String? ?? 'manual';

                    return ListTile(
                      dense: true,
                      leading: Icon(
                        type == 'reminder' ? Icons.alarm : Icons.touch_app,
                        size: 18,
                        color: colors.info,
                      ),
                      title: Text(_formatDateTime(sentAt), style: TextStyle(color: colors.textPrimary)),
                      subtitle: Text(
                        type == 'reminder'
                            ? 'Reminder এর মাধ্যমে auto-send'
                            : 'ম্যানুয়ালি পাঠানো হয়েছে',
                        style: TextStyle(fontSize: 12, color: colors.textSecondary),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Close", style: TextStyle(color: colors.accent)),
          ),
        ],
      ),
    );
  }

  Future<void> _openWhatsApp(Customer customer) async {
    final cleanPhone = customer.phone.replaceAll(RegExp(r'[\s\-]'), '');
    final fullPhone = cleanPhone.startsWith('0')
        ? '88$cleanPhone'
        : cleanPhone.startsWith('+')
            ? cleanPhone.substring(1)
            : cleanPhone;

    final message = Uri.encodeComponent(_buildDueMessage(customer));
    final uri = Uri.parse('https://wa.me/$fullPhone?text=$message');

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('WhatsApp খোলা যায়নি')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Scaffold(
      backgroundColor: colors.scaffoldBg,
      appBar: AppBar(
        title: Text(widget.customer.name, style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w700)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: colors.textPrimary),
        actions: [
          IconButton(
            icon: Icon(Icons.sms, color: colors.info),
            onPressed: () async {
              await NotificationService.sendSmsNow(
                phoneNumber: widget.customer.phone,
                message: _buildDueMessage(widget.customer),
              );

              await _customerRepo.logSmsSent(
                customerId: widget.customer.id,
                type: 'manual',
              );

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('SMS send attempted')),
                );
              }
            },
          ),
          IconButton(
            icon: Icon(Icons.edit, color: colors.accent),
            onPressed: () => _editCustomer(widget.customer),
          ),
          IconButton(
            icon: Icon(Icons.visibility_off, color: colors.warn),
            onPressed: () => _confirmDeleteCustomer(widget.customer),
          ),
        ],
      ),
      body: StreamBuilder<Customer>(
        stream: _customerRepo.streamCustomerById(widget.customer.id),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator(color: colors.accent));
          }

          final customer = snapshot.data!;

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: CircleAvatar(
                    radius: 45,
                    backgroundColor: colors.surfaceAlt,
                    backgroundImage: customer.photoUrl != null
                        ? MemoryImage(base64Decode(customer.photoUrl!))
                              as ImageProvider
                        : null,
                    child: customer.photoUrl == null
                        ? Icon(Icons.person, size: 40, color: colors.textSecondary)
                        : null,
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: Text(
                    customer.name,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: colors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        customer.phone,
                        style: TextStyle(color: colors.textSecondary),
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: () => _openWhatsApp(customer),
                        borderRadius: BorderRadius.circular(20),
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Icon(
                            Icons.chat,
                            size: 18,
                            color: colors.clear,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                if (customer.address != null)
                  Center(
                    child: Text(
                      customer.address!,
                      style: TextStyle(color: colors.textSecondary),
                    ),
                  ),

                if (customer.note != null && customer.note!.trim().isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 10),
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: colors.surfaceAlt,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: colors.borderColor),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.sticky_note_2_outlined, size: 18, color: colors.textSecondary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            customer.note!,
                            style: TextStyle(fontSize: 13, color: colors.textPrimary),
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 10),
                Text(
                  "Due date: ${_formatDateOnly(customer.lastPaymentDate)} "
                  "(${_daysSincePayment(customer.lastPaymentDate)})",
                  style: TextStyle(color: colors.textSecondary),
                ),
                const SizedBox(height: 10),
                Text(
                  "Total Due: ${customer.totalDue.toStringAsFixed(2)}",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: customer.totalDue > 0 ? colors.due : colors.clear,
                  ),
                ),
                const SizedBox(height: 8),
                StreamBuilder<List<Map<String, dynamic>>>(
                  stream: _customerRepo.streamSmsLogs(customer.id),
                  builder: (context, smsSnapshot) {
                    final count = smsSnapshot.data?.length ?? 0;

                    return InkWell(
                      onTap: () => _showSmsHistory(customer),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: colors.info.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.sms_outlined, size: 16, color: colors.info),
                            const SizedBox(width: 6),
                            Text(
                              "SMS পাঠানো হয়েছে: $count বার",
                              style: TextStyle(
                                fontSize: 12,
                                color: colors.info,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(Icons.chevron_right, size: 16, color: colors.info),
                          ],
                        ),
                      ),
                    );
                  },
                ),

                if (customer.nextReminderDate != null)
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          "Next Reminder: ${_formatDateTime(customer.nextReminderDate!)}",
                          style: TextStyle(color: colors.warn),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.cancel, color: colors.due, size: 20),
                        tooltip: "Remove Reminder",
                        onPressed: () => _confirmClearReminder(customer),
                      ),
                    ],
                  ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colors.clear,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () =>
                            _addPayment(customer, PaymentType.payment),
                        child: const Text("Record Payment"),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colors.due,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () =>
                            _addPayment(customer, PaymentType.dueAdded),
                        child: const Text("Add Charge"),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.accent,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () => _setReminder(customer),
                    icon: const Icon(Icons.alarm),
                    label: const Text("Set Reminder"),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Payment History",
                      style: TextStyle(fontWeight: FontWeight.bold, color: colors.textPrimary),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.print, color: colors.textSecondary),
                          onPressed: () => _printPdf(customer),
                        ),
                        IconButton(
                          icon: Icon(Icons.download, color: colors.textSecondary),
                          onPressed: () => _downloadPdf(customer),
                        ),
                        IconButton(
                          icon: Icon(Icons.history, color: colors.textSecondary),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ReminderHistoryScreen(
                                  customerId: customer.id,
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: StreamBuilder<List<Payment>>(
                    stream: _customerRepo.streamPayments(customer.id),
                    builder: (context, paymentSnapshot) {
                      if (!paymentSnapshot.hasData) {
                        return Center(child: CircularProgressIndicator(color: colors.accent));
                      }

                      final payments = paymentSnapshot.data!;

                      if (payments.isEmpty) {
                        return Center(
                          child: Text("No transactions yet", style: TextStyle(color: colors.textSecondary)),
                        );
                      }

                      return ListView.separated(
                        itemCount: payments.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          return PaymentHistoryTile(payment: payments[index]);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}