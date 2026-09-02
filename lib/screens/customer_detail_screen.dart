import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../l10n/app_localizations.dart';
import '../models/customer.dart';
import '../models/payment.dart';
import '../models/customer_repository.dart';
import '../services/notification_service.dart';
import '../theme/app_colors.dart';
import '../utils/helpers.dart';
import '../utils/pdf_bengali_text.dart';
import '../widgets/app_settings_scope.dart';
import '../widgets/call_button.dart';
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

    // ✅ বকেয়া সম্পূর্ণ পরিশোধ হয়ে গেলে due-reminder এর বদলে thank-you টেমপ্লেট
    final template = customer.totalDue <= 0
        ? settings.fullPaymentThankYouTemplate
        : settings.smsReminderTemplate;

    return template
        .replaceAll('{name}', customer.name)
        .replaceAll('{amount}', currencyFmt.format(customer.totalDue))
        .replaceAll('{due_date}', dateFmt.format(customer.lastPaymentDate))
        .replaceAll('{business_name}', settings.businessName)
        .replaceAll('{phone}', customer.phone);
  }

  String _daysSincePayment(DateTime lastPaymentDate) {
    final l10n = AppLocalizations.of(context)!;
    final days = DateTime.now().difference(lastPaymentDate).inDays;
    if (days == 0) return l10n.todayLabel;
    if (days == 1) return l10n.yesterdayLabel;
    return l10n.daysAgoLabel(days);
  }

  static final _base64Pattern = RegExp(r'^[A-Za-z0-9+/]+={0,2}$');

  bool _isLikelyBase64Photo(String value) {
    return value.length > 100 && _base64Pattern.hasMatch(value);
  }

  Future<pw.Document> _generatePdf(Customer customer) async {
    final payments = await _customerRepo.streamPayments(customer.id).first;
    final settings = AppSettingsScope.of(context).settings;
    final isBn = settings.languageCode != 'en';
    // ✅ PDF widget tree-এর ভেতর BuildContext না থাকায় AppLocalizations ব্যবহার
    // করা যায় না, তাই ভাষা অনুযায়ী লেবেল বেছে নেওয়ার ছোট হেল্পার
    String t(String bn, String en) => isBn ? bn : en;

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
    final businessNameImg = await bengaliTextImage(
      settings.businessName,
      fontSize: 16,
      fontWeight: FontWeight.bold,
    );

    final businessAddressImg = settings.businessAddress.isNotEmpty
        ? await bengaliTextImage(settings.businessAddress, fontSize: 10)
        : null;

    final customerNameImg = await bengaliTextImage(customer.name, fontSize: 11);

    final customerAddressImg = customer.address != null
        ? await bengaliTextImage(customer.address!, fontSize: 11)
        : null;

    // ✅ Payment history এর Note কলামে বাংলা থাকলে সেগুলোও ছবি বানানো হচ্ছে
    final noteImages = <int, pw.Widget>{};
    for (var i = 0; i < payments.length; i++) {
      final note = payments[i].note;
      if (note != null && note.trim().isNotEmpty) {
        noteImages[i] = await bengaliTextImage(note, fontSize: 9);
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
            t('কাস্টমার পেমেন্ট হিস্ট্রি', 'Customer Payment History'),
            style: pw.TextStyle(
              fontSize: 22,
              fontWeight: pw.FontWeight.bold,
              font: boldFont,
            ),
          ),
          pw.SizedBox(height: 16),

          pw.Row(
            children: [
              pw.Text(t('নাম: ', 'Name: '), style: pw.TextStyle(font: regularFont)),
              customerNameImg,
            ],
          ),
          pw.Text(
            '${t('ফোন', 'Phone')}: ${customer.phone}',
            style: pw.TextStyle(font: regularFont),
          ),
          if (customerAddressImg != null)
            pw.Row(
              children: [
                pw.Text(t('ঠিকানা: ', 'Address: '), style: pw.TextStyle(font: regularFont)),
                customerAddressImg,
              ],
            ),
          pw.Text(
            '${t('বকেয়ার তারিখ', 'Due Date')}: ${_formatDateOnly(customer.lastPaymentDate)}',
            style: pw.TextStyle(font: regularFont),
          ),
          pw.Text(
            '${t('মোট বকেয়া', 'Total Due')}: ${settings.currencySymbol}${customer.totalDue.toStringAsFixed(2)}',
            style: pw.TextStyle(font: regularFont),
          ),
          if (customer.nextReminderDate != null)
            pw.Text(
              '${t('পরবর্তী রিমাইন্ডার', 'Next Reminder')}: ${_formatDateTime(customer.nextReminderDate!)}',
              style: pw.TextStyle(font: regularFont),
            ),
          pw.SizedBox(height: 20),
          pw.Text(
            t('পেমেন্ট হিস্ট্রি', 'Payment History'),
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
              font: boldFont,
            ),
          ),
          pw.SizedBox(height: 10),

          if (payments.isEmpty)
            pw.Text(
              t('এখনো কোনো লেনদেন নেই', 'No transactions yet'),
              style: pw.TextStyle(font: regularFont),
            )
          else
            pw.Table(
              border: pw.TableBorder.all(width: 0.5),
              children: [
                pw.TableRow(
                  children: [
                    t('তারিখ', 'Date'),
                    t('ধরন', 'Type'),
                    t('পরিমাণ', 'Amount'),
                    t('নোট', 'Note'),
                  ].map((h) {
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
                              ? t('পেমেন্ট রেকর্ড', 'Record Payment')
                              : t('চার্জ যোগ', 'Add Charge'),
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
          content: Text(AppLocalizations.of(context)!.pdfSavedOpened),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: colors.due,
          content: Text(AppLocalizations.of(context)!.downloadFailed),
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
        ? currentCustomer.totalDue - payment.amount - payment.discount
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

    if (!mounted) return;
    final recurrenceType = await _askRecurrence();
    if (!mounted) return;
    final note = await _askReminderNote();

    await _customerRepo.addReminder(
      customerId: customer.id,
      reminderDate: scheduledDateTime,
      note: note,
      isRecurring: recurrenceType != null,
      recurrenceType: recurrenceType,
    );

    await NotificationService.scheduleReminder(
      id: customer.hashCode,
      title: "Payment Reminder",
      body: "${customer.name} will pay now",
      scheduledDate: scheduledDateTime,
      smsPhone: customer.phone,
      smsMessage: _buildDueMessage(customer),
    );

    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          recurrenceType == null
              ? l10n.reminderUpdatedSuccess
              : l10n.reminderUpdatedWithRepeat(_recurrenceLabel(recurrenceType)),
        ),
      ),
    );
  }

  // ✅ কিস্তিভিত্তিক বকেয়ার জন্য "Repeat" অপশন — বাছাই করা হলে প্রতি সাইকেলে
  // reminder ম্যানুয়ালি সেট না করেই নিজে থেকে পরের তারিখে চলে যাবে
  Future<String?> _askRecurrence() async {
    final colors = AppColors.of(context);
    final l10n = AppLocalizations.of(context)!;

    return showModalBottomSheet<String?>(
      context: context,
      backgroundColor: colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  l10n.repeatReminderQuestion,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: colors.textPrimary),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    l10n.repeatReminderDesc,
                    style: TextStyle(fontSize: 12, color: colors.textSecondary),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: Icon(Icons.event_busy_rounded, color: colors.textSecondary),
                title: Text(l10n.recurrenceNone, style: TextStyle(color: colors.textPrimary)),
                onTap: () => Navigator.pop(context, null),
              ),
              ListTile(
                leading: Icon(Icons.repeat_rounded, color: colors.accent),
                title: Text(l10n.recurrenceWeekly, style: TextStyle(color: colors.textPrimary)),
                onTap: () => Navigator.pop(context, 'weekly'),
              ),
              ListTile(
                leading: Icon(Icons.repeat_rounded, color: colors.accent),
                title: Text(l10n.recurrenceBiweekly, style: TextStyle(color: colors.textPrimary)),
                onTap: () => Navigator.pop(context, 'biweekly'),
              ),
              ListTile(
                leading: Icon(Icons.repeat_rounded, color: colors.accent),
                title: Text(l10n.recurrenceMonthlyFull, style: TextStyle(color: colors.textPrimary)),
                onTap: () => Navigator.pop(context, 'monthly'),
              ),
            ],
          ),
        );
      },
    );
  }

  bool _isReminderOverdue(Customer customer) {
    final nextReminderDate = customer.nextReminderDate;
    if (nextReminderDate == null) return false;
    return nextReminderDate.isBefore(DateTime.now());
  }

  String _recurrenceLabel(String recurrenceType) {
    final l10n = AppLocalizations.of(context)!;
    switch (recurrenceType) {
      case 'weekly':
        return l10n.recurrenceWeekly;
      case 'biweekly':
        return l10n.recurrenceBiweeklyShort;
      case 'monthly':
      default:
        return l10n.recurrenceMonthlyShort;
    }
  }

  Future<void> _markRecurringDone(Customer customer) async {
    final colors = AppColors.of(context);
    try {
      final nextDate = await _customerRepo.advanceRecurringReminder(customer);
      if (nextDate == null) return;

      await NotificationService.scheduleReminder(
        id: customer.hashCode,
        title: "Payment Reminder",
        body: "${customer.name} will pay now",
        scheduledDate: nextDate,
        smsPhone: customer.phone,
        smsMessage: _buildDueMessage(customer),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: colors.clear,
          content: Text(AppLocalizations.of(context)!.nextReminderSetResult(_formatDateTime(nextDate))),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: colors.due,
          content: Text(AppLocalizations.of(context)!.advanceReminderFailed),
        ),
      );
    }
  }

  Future<String?> _askReminderNote() async {
    final colors = AppColors.of(context);
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController();

    final note = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: colors.borderColor),
        ),
        title: Text(
          l10n.addNoteOptional,
          style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w800),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 3,
          style: TextStyle(color: colors.textPrimary),
          decoration: InputDecoration(
            hintText: l10n.reminderNoteHint,
            hintStyle: TextStyle(color: colors.textSecondary),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: colors.borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: colors.accent),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, ''),
            child: Text(l10n.skip, style: TextStyle(color: colors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: Text(l10n.save, style: TextStyle(color: colors.accent, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    return note;
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
        dialogTheme: DialogThemeData(backgroundColor: colors.surface),
      ),
      child: child!,
    );
  }

  Future<void> _confirmClearReminder(Customer customer) async {
    final colors = AppColors.of(context);
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: colors.borderColor),
        ),
        title: Text(
          customer.isRecurringReminder ? l10n.stopRecurringReminderTitle : l10n.cancelReminderTitle,
          style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w800),
        ),
        content: Text(
          customer.isRecurringReminder
              ? l10n.stopRecurringConfirmBody(
                  _recurrenceLabel(customer.recurrenceType ?? 'monthly'),
                  customer.name,
                )
              : l10n.cancelReminderConfirmBody(customer.name),
          style: TextStyle(color: colors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel, style: TextStyle(color: colors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              customer.isRecurringReminder ? l10n.stopRecurringAction : l10n.removeReminderAction,
              style: TextStyle(color: colors.due, fontWeight: FontWeight.w700),
            ),
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
      await NotificationService.cancelReminder(customer.hashCode);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: colors.clear,
          content: Text(AppLocalizations.of(context)!.reminderRemovedSuccess),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: colors.due,
          content: Text(AppLocalizations.of(context)!.removeReminderFailed),
        ),
      );
    }
  }

  Future<void> _confirmSendSms(Customer customer) async {
    final colors = AppColors.of(context);
    final l10n = AppLocalizations.of(context)!;
    final message = _buildDueMessage(customer);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: colors.borderColor),
        ),
        title: Text(l10n.sendSms, style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w800)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                customer.totalDue <= 0
                    ? l10n.thankYouSmsConfirm(customer.name, customer.phone)
                    : l10n.dueReminderSmsConfirm(customer.name, customer.phone),
                style: TextStyle(color: colors.textSecondary),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colors.surfaceAlt,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: colors.borderColor),
                ),
                child: Text(
                  message,
                  style: TextStyle(color: colors.textPrimary, fontSize: 13.5, height: 1.4),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel, style: TextStyle(color: colors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.send, style: TextStyle(color: colors.info, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // ✅ Play Store policy অনুযায়ী app নিজে SMS পাঠাতে পারে না — default SMS app
    // prefilled অবস্থায় খুলে দেওয়া হয়, ব্যবহারকারী নিজে Send করবেন
    final uri = buildSmsComposeUri(customer.phone, _buildDueMessage(customer));

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
      await _customerRepo.logSmsSent(
        customerId: customer.id,
        type: 'manual',
      );
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.smsAppNotOpened)),
        );
      }
    }
  }

  Future<void> _confirmDeleteCustomer(Customer customer) async {
    final colors = AppColors.of(context);
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: colors.borderColor),
        ),
        title: Text(l10n.hideCustomerTitle, style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w800)),
        content: Text(
          l10n.hideCustomerConfirmBody(customer.name),
          style: TextStyle(color: colors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel, style: TextStyle(color: colors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.hideAction, style: TextStyle(color: colors.due, fontWeight: FontWeight.w700)),
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
      final l10n = AppLocalizations.of(context)!;

      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: colors.clear,
          content: Text(l10n.customerHiddenSuccess(customer.name)),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(backgroundColor: colors.due, content: Text(AppLocalizations.of(context)!.hideFailed)),
      );
    }
  }

  Future<String?> _encodeImageToBase64(File imageFile) async {
    final bytes = await imageFile.readAsBytes();

    if (bytes.length > 700 * 1024) {
      if (!mounted) return null;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.photoTooLarge)),
      );
      return null;
    }

    return base64Encode(bytes);
  }

  Future<void> _editCustomer(Customer customer) async {
    final colors = AppColors.of(context);
    final l10n = AppLocalizations.of(context)!;

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

            // ✅ AlertDialog এর built-in title/content/actions ব্যবহার করলে content
            // অংশটা Column এ একটা সাধারণ (non-flex) child হিসেবে বসে — তাই সেটা
            // নিজের চাওয়া height এ রেন্ডার হতে চায়, আশেপাশে (title/actions/keyboard)
            // যতটুকু জায়গা আসলে অবশিষ্ট আছে তা মেনে ছোট হয় না, ফলে overflow হয়।
            // এখানে বদলে নিজে থেকে একটা height-bounded Dialog বানিয়ে ফর্মের
            // scrollable অংশটা Flexible দিয়ে মোড়ানো হয়েছে — তাই এটা যতটুকু জায়গা
            // পায় ঠিক ততটুকুতেই বসে যায় (ভেতরে দরকার হলে scroll করে), overflow
            // structurally সম্ভবই না, কীবোর্ড থাকুক বা না থাকুক।
            // ✅ Dialog নিজে থেকে কীবোর্ডের জন্য available height ঠিকমতো কমাবে —
            // এই ধারণার উপর নির্ভর না করে, এখানে সরাসরি MediaQuery থেকে
            // (screen height - keyboard height - insetPadding) হিসাব করে
            // পুরো dialog-টাকে একটা hard ConstrainedBox দিয়ে বেঁধে দেওয়া হয়েছে।
            // এর ভেতরে Flexible content-কে (এবং শুধু content-কেই, title/button না)
            // ছোট করে, তাই overflow structurally আর সম্ভব না।
            final mq = MediaQuery.of(dialogContext);
            const verticalInset = 48.0; // insetPadding: vertical 24 * 2
            final maxDialogHeight =
                (mq.size.height - mq.viewInsets.bottom - verticalInset).clamp(120.0, mq.size.height);

            return Dialog(
              backgroundColor: colors.surface,
              insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: BorderSide(color: colors.borderColor),
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: maxDialogHeight),
                child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.editCustomerTitle,
                      style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w800, fontSize: 19),
                    ),
                    const SizedBox(height: 12),
                    Flexible(
                      child: SingleChildScrollView(
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
                        labelText: l10n.nameLabel,
                        labelStyle: TextStyle(color: colors.textSecondary),
                      ),
                    ),
                    TextField(
                      controller: phoneController,
                      style: TextStyle(color: colors.textPrimary),
                      decoration: InputDecoration(
                        labelText: l10n.phoneLabel,
                        labelStyle: TextStyle(color: colors.textSecondary),
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                    TextField(
                      controller: addressController,
                      style: TextStyle(color: colors.textPrimary),
                      decoration: InputDecoration(
                        labelText: l10n.addressLabel,
                        labelStyle: TextStyle(color: colors.textSecondary),
                      ),
                    ),
                    TextField(
                      controller: dueAmountController,
                      style: TextStyle(color: colors.textSecondary),
                      decoration: InputDecoration(
                        labelText: l10n.dueAmountLabel,
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
                        labelText: dateUnlocked ? l10n.dueDateEditable : l10n.dueDateFieldLabel,
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
                            l10n.tapsToUnlock(7 - dateTapCount),
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
                            l10n.dateEditableWarning,
                            style: TextStyle(fontSize: 11, color: colors.clear),
                          ),
                        ),
                      ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: noteController,
                      style: TextStyle(color: colors.textPrimary),
                      decoration: InputDecoration(
                        labelText: l10n.noteLabel,
                        labelStyle: TextStyle(color: colors.textSecondary),
                      ),
                    ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                TextButton(
                  onPressed: isSavingEdit
                      ? null
                      : () => Navigator.pop(dialogContext),
                  child: Text(l10n.cancel, style: TextStyle(color: colors.textSecondary)),
                ),
                const SizedBox(width: 8),
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
                              content: Text(l10n.customerUpdatedSuccess),
                            ),
                          );
                        },
                  child: isSavingEdit
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text(l10n.save),
                ),
                  ],
                ),
              ],
            ),
              ),
              ),
            );
          },
        );
      },
    );
  }

  void _showSmsHistory(Customer customer) {
    final colors = AppColors.of(context);
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: colors.borderColor),
        ),
        title: Text(l10n.smsSentHistoryTitle, style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w800)),
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
                  child: Text(l10n.noSmsSentYet, style: TextStyle(color: colors.textSecondary)),
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
                            ? l10n.reminderAutoSend
                            : l10n.manuallySent,
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
            child: Text(l10n.close, style: TextStyle(color: colors.accent)),
          ),
        ],
      ),
    );
  }

  Future<void> _callCustomer(Customer customer) async {
    final uri = Uri(scheme: 'tel', path: customer.phone);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.callFailedShort)),
      );
    }
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
        SnackBar(content: Text(AppLocalizations.of(context)!.whatsappNotOpened)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: colors.scaffoldBg,
      // ✅ এই স্ক্রিনের নিজের কোনো text input নেই (সব এডিট modal dialog এ হয়,
      // যেটা নিজের কীবোর্ড-অ্যাভয়ডেন্স নিজেই হ্যান্ডেল করে) — কিন্তু dialog এর
      // ভেতরের কীবোর্ড খুললেও এই আন্ডারলাইং Scaffold ডিফল্টে resize করতে যায়,
      // আর body এর fixed-height profile header (Expanded payment list ছাড়া
      // বাকি অংশ) সেই কমে যাওয়া height এ আর ধরে না, ফলে overflow হয়। তাই এই
      // স্ক্রিনকে কীবোর্ডের জন্য resize করতে বারণ করা হয়েছে।
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: Text(widget.customer.name, style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w700)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: colors.textPrimary),
        actions: [
          IconButton(
            icon: Icon(Icons.sms, color: colors.info),
            onPressed: () => _confirmSendSms(widget.customer),
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
                      CallButton(
                        onTap: () => _callCustomer(customer),
                        colors: colors,
                        compact: true,
                      ),
                      const SizedBox(width: 4),
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

                if (customer.customFields.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 10),
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: colors.surfaceAlt,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: colors.borderColor),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: customer.customFields.entries.map((entry) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 3),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.label_outline_rounded, size: 16, color: colors.textSecondary),
                              const SizedBox(width: 8),
                              Text(
                                "${entry.key}: ",
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: colors.textSecondary,
                                ),
                              ),
                              Expanded(
                                child: _isLikelyBase64Photo(entry.value)
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.memory(
                                          base64Decode(entry.value),
                                          height: 64,
                                          width: 64,
                                          fit: BoxFit.cover,
                                        ),
                                      )
                                    : Text(
                                        entry.value.isEmpty ? '-' : entry.value,
                                        style: TextStyle(fontSize: 13, color: colors.textPrimary),
                                      ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                const SizedBox(height: 10),
                Text(
                  l10n.dueDateWithDays(
                    _formatDateOnly(customer.lastPaymentDate),
                    _daysSincePayment(customer.lastPaymentDate),
                  ),
                  style: TextStyle(color: colors.textSecondary),
                ),
                const SizedBox(height: 10),
                Text(
                  l10n.totalDueColon(customer.totalDue.toStringAsFixed(2)),
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
                          color: colors.info.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.sms_outlined, size: 16, color: colors.info),
                            const SizedBox(width: 6),
                            Text(
                              l10n.smsSentCount(count),
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.nextReminderLabel(_formatDateTime(customer.nextReminderDate!)),
                              style: TextStyle(
                                color: _isReminderOverdue(customer) ? colors.due : colors.warn,
                              ),
                            ),
                            if (customer.isRecurringReminder) ...[
                              const SizedBox(height: 3),
                              Row(
                                children: [
                                  Icon(Icons.repeat_rounded, size: 13, color: colors.accent),
                                  const SizedBox(width: 4),
                                  Text(
                                    l10n.repeatsLabel(_recurrenceLabel(customer.recurrenceType ?? 'monthly')),
                                    style: TextStyle(fontSize: 11.5, color: colors.accent, fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ],
                            // ✅ nextReminderDate পার হয়ে গেলে সেটা Firestore এ নিজে
                            // থেকে বদলায় না — তাই সময়ের সাথে তুলনা করে overdue দেখানো হয়
                            if (_isReminderOverdue(customer)) ...[
                              const SizedBox(height: 3),
                              Row(
                                children: [
                                  Icon(Icons.error_outline_rounded, size: 13, color: colors.due),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      customer.isRecurringReminder
                                          ? l10n.reminderOverdueRecurringHint
                                          : l10n.reminderOverdueHint,
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        color: colors.due,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (customer.isRecurringReminder)
                        IconButton(
                          icon: Icon(Icons.check_circle_outline_rounded, color: colors.clear, size: 20),
                          tooltip: l10n.markDoneTooltip,
                          onPressed: () => _markRecurringDone(customer),
                        ),
                      IconButton(
                        icon: Icon(Icons.cancel, color: colors.due, size: 20),
                        tooltip: customer.isRecurringReminder ? l10n.stopRecurringAction : l10n.removeReminderAction,
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
                        child: Text(l10n.recordPayment),
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
                        child: Text(l10n.addCharge),
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
                    label: Text(l10n.setReminder),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n.paymentHistoryTitle,
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
                          child: Text(l10n.noTransactionsYet, style: TextStyle(color: colors.textSecondary)),
                        );
                      }

                      return ListView.separated(
                        itemCount: payments.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          return PaymentHistoryTile(payment: payments[index], customer: customer);
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