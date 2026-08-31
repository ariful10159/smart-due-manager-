import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/app_settings.dart';
import '../models/customer.dart';
import '../models/legal_content.dart';
import '../models/payment.dart';
import '../utils/pdf_bengali_text.dart';

/// ✅ একটা নির্দিষ্ট payment এর জন্য ছোট, শেয়ারযোগ্য রিসিট PDF — পুরো
/// customer statement এর মতো বড় রিপোর্ট না, বরং সেই মুহূর্তেই কাস্টমারকে
/// দেওয়ার মতো এক পাতার রিসিট। ইনভয়েস-স্টাইল লেআউট (header/BILL TO/টেবিল/
/// total-paid-balance) অনুসরণ করা হয়েছে।
class ReceiptPdfService {
  static final _navy = PdfColor.fromHex('27296D');
  static final _orange = PdfColor.fromHex('F0653C');

  static Future<Uint8List> buildReceipt({
    required Customer customer,
    required Payment payment,
    required AppSettings settings,
    String languageCode = 'bn',
  }) async {
    final isBn = languageCode != 'en';
    // ✅ ভাষা অনুযায়ী লেবেল বেছে নেওয়ার ছোট হেল্পার — PDF widget tree-এর ভেতর
    // BuildContext না থাকায় AppLocalizations ব্যবহার করা যায় না
    String t(String bn, String en) => isBn ? bn : en;

    final bengaliRegular = await rootBundle.load(
      'assets/fonts/NotoSerifBengali_Condensed-Regular.ttf',
    );
    final bengaliBold = await rootBundle.load(
      'assets/fonts/NotoSerifBengali-Bold.ttf',
    );

    final regularFont = pw.Font.ttf(bengaliRegular);
    final boldFont = pw.Font.ttf(bengaliBold);

    final isPayment = payment.type == PaymentType.payment;
    final currencyFmt = NumberFormat('#,##0.00');
    final dateFmt = DateFormat('d/M/yyyy');
    final isFullyPaid = customer.totalDue <= 0;

    // ✅ আগের বকেয়া (এই transaction এর আগে ব্যালেন্স কত ছিল)
    final previousDue = isPayment
        ? customer.totalDue + payment.amount + payment.discount
        : customer.totalDue - payment.amount;

    // ✅ বাংলা টেক্সট হতে পারে এমন সব field আগে থেকেই ছবি বানিয়ে রাখা হচ্ছে
    final businessNameImg = await bengaliTextImage(
      settings.businessName,
      fontSize: 19,
      fontWeight: FontWeight.bold,
      color: Color(_navy.toInt()),
    );
    final businessAddressImg = settings.businessAddress.isNotEmpty
        ? await bengaliTextImage(settings.businessAddress, fontSize: 9, color: const Color(0xFF6B7280))
        : null;
    final ownerNameImg = settings.ownerName.trim().isNotEmpty
        ? await bengaliTextImage('Owner: ${settings.ownerName.trim()}', fontSize: 9, color: const Color(0xFF6B7280))
        : null;
    final customerNameImg = await bengaliTextImage(customer.name, fontSize: 12.5, fontWeight: FontWeight.bold);
    final customerAddressImg = (customer.address != null && customer.address!.trim().isNotEmpty)
        ? await bengaliTextImage(customer.address!.trim(), fontSize: 9.5, color: const Color(0xFF6B7280))
        : null;

    final descriptionText = (payment.description != null && payment.description!.trim().isNotEmpty)
        ? payment.description!.trim()
        : (isPayment ? t('পেমেন্ট গৃহীত', 'Payment Received') : t('চার্জ যোগ হয়েছে', 'Charge Added'));
    final descriptionImg = await bengaliTextImage(descriptionText, fontSize: 10.5);

    final noteImg = (payment.note != null && payment.note!.trim().isNotEmpty)
        ? await bengaliTextImage(payment.note!.trim(), fontSize: 9.5, color: const Color(0xFF6B7280))
        : null;

    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(36, 40, 36, 32),
        theme: pw.ThemeData.withFont(base: regularFont, bold: boldFont),
        build: (context) {
          return pw.Column(
            mainAxisSize: pw.MainAxisSize.max,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // ───── Header: Business name (left) + Receipt title (right) ─────
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        businessNameImg,
                        if (ownerNameImg != null) ...[
                          pw.SizedBox(height: 2),
                          ownerNameImg,
                        ],
                        if (businessAddressImg != null) ...[
                          pw.SizedBox(height: 3),
                          businessAddressImg,
                        ],
                      ],
                    ),
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        isPayment ? t('রিসিট', 'RECEIPT') : t('ডেবিট নোট', 'DEBIT NOTE'),
                        style: pw.TextStyle(font: boldFont, fontSize: 20, color: _navy),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        'RCPT-${_shortId(payment.id)}',
                        style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 10),
              pw.Divider(thickness: 1, color: PdfColors.grey400),
              pw.SizedBox(height: 10),

              // ───── BILL TO (left) + Date / status badge (right) ─────
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          t('যাকে দেওয়া হলো', 'BILL TO'),
                          style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey500, letterSpacing: 1),
                        ),
                        pw.SizedBox(height: 3),
                        customerNameImg,
                        if (customerAddressImg != null) ...[
                          pw.SizedBox(height: 2),
                          customerAddressImg,
                        ],
                        pw.SizedBox(height: 2),
                        pw.Text(
                          customer.phone,
                          style: const pw.TextStyle(fontSize: 9.5, color: PdfColors.grey600),
                        ),
                      ],
                    ),
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Row(
                        children: [
                          pw.Text(t('তারিখ: ', 'Date: '), style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey500)),
                          pw.Text(
                            dateFmt.format(payment.date),
                            style: pw.TextStyle(font: boldFont, fontSize: 9.5),
                          ),
                        ],
                      ),
                      pw.SizedBox(height: 6),
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: pw.BoxDecoration(
                          color: PdfColor.fromHex('FFF1E9'),
                          borderRadius: pw.BorderRadius.circular(4),
                          border: pw.Border.all(color: _orange, width: 0.75),
                        ),
                        child: pw.Row(
                          children: [
                            pw.Text(
                              t('বকেয়ার তারিখ: ', 'Due Date: '),
                              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
                            ),
                            pw.Text(
                              dateFmt.format(customer.lastPaymentDate),
                              style: pw.TextStyle(font: boldFont, fontSize: 9.5, color: _orange),
                            ),
                          ],
                        ),
                      ),
                      pw.SizedBox(height: 8),
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: pw.BoxDecoration(
                          color: isFullyPaid ? PdfColors.green700 : _orange,
                          borderRadius: pw.BorderRadius.circular(4),
                        ),
                        child: pw.Text(
                          isFullyPaid ? t('পরিশোধিত', 'PAID') : t('বকেয়া', 'DUE'),
                          style: pw.TextStyle(font: boldFont, fontSize: 9, color: PdfColors.white),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 20),

              // ───── Table ─────
              pw.Container(
                width: double.infinity,
                color: _navy,
                padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                child: pw.Row(
                  children: [
                    pw.Expanded(
                      child: pw.Text(
                        t('বিবরণ', 'Description'),
                        style: pw.TextStyle(font: boldFont, fontSize: 10, color: PdfColors.white),
                      ),
                    ),
                    pw.Text(
                      '${t('পরিমাণ', 'Amount')} (${settings.currencySymbol})',
                      style: pw.TextStyle(font: boldFont, fontSize: 10, color: PdfColors.white),
                    ),
                  ],
                ),
              ),
              _receiptRow(description: descriptionImg, amount: currencyFmt.format(payment.amount), boldFont: regularFont),
              if (payment.paymentMethod != null)
                _receiptRow(
                  description: pw.Text(
                    '${t('পেমেন্ট মাধ্যম', 'Payment Method')}: ${Payment.paymentMethodToString(payment.paymentMethod!)}',
                    style: const pw.TextStyle(fontSize: 9.5, color: PdfColors.grey600),
                  ),
                  amount: '',
                  boldFont: regularFont,
                ),
              if (noteImg != null)
                _receiptRow(
                  description: pw.Row(
                    children: [
                      pw.Text(t('নোট: ', 'Note: '), style: const pw.TextStyle(fontSize: 9.5, color: PdfColors.grey600)),
                      noteImg,
                    ],
                  ),
                  amount: '',
                  boldFont: regularFont,
                ),

              pw.SizedBox(height: 20),

              // ───── Total / Paid / Balance Due summary (right aligned) ─────
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.SizedBox(
                    width: 220,
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text(t('আগের বকেয়া', 'Previous Due'), style: pw.TextStyle(font: boldFont, fontSize: 10.5)),
                            pw.Text(
                              '${settings.currencySymbol}${currencyFmt.format(previousDue < 0 ? 0 : previousDue)}',
                              style: pw.TextStyle(font: boldFont, fontSize: 10.5),
                            ),
                          ],
                        ),
                        pw.SizedBox(height: 6),
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text(
                              isPayment ? t('পেমেন্ট গৃহীত', 'Payment Received') : t('চার্জ যোগ হয়েছে', 'Charge Added'),
                              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                            ),
                            pw.Text(
                              '${isPayment ? '-' : '+'}${settings.currencySymbol}${currencyFmt.format(payment.amount)}',
                              style: pw.TextStyle(
                                fontSize: 10,
                                color: isPayment ? PdfColors.green700 : _orange,
                              ),
                            ),
                          ],
                        ),
                        if (isPayment && payment.discount > 0) ...[
                          pw.SizedBox(height: 6),
                          pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Text(
                                t('ডিসকাউন্ট', 'Discount'),
                                style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                              ),
                              pw.Text(
                                '-${settings.currencySymbol}${currencyFmt.format(payment.discount)}',
                                style: const pw.TextStyle(fontSize: 10, color: PdfColors.green700),
                              ),
                            ],
                          ),
                        ],
                        pw.SizedBox(height: 8),
                        pw.Divider(thickness: 1, color: PdfColors.grey400),
                        pw.SizedBox(height: 4),
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text(t('বাকি বকেয়া', 'Balance Due'), style: pw.TextStyle(font: boldFont, fontSize: 13)),
                            pw.Text(
                              '${settings.currencySymbol}${currencyFmt.format(customer.totalDue)}',
                              style: pw.TextStyle(
                                font: boldFont,
                                fontSize: 14,
                                color: isFullyPaid ? PdfColors.green700 : _orange,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              pw.Expanded(child: pw.SizedBox()),
              pw.Divider(thickness: 1, color: PdfColors.grey300),
              pw.SizedBox(height: 8),
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text(
                      isPayment
                          ? t('আপনার পেমেন্টের জন্য ধন্যবাদ।', 'Thank you for your payment.')
                          : t('এই চার্জটি আপনার অ্যাকাউন্টে যোগ হয়েছে।', 'This charge has been added to your account.'),
                      style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
                    ),
                    pw.SizedBox(height: 3),
                    pw.Text(
                      'Powered by ${LegalContent.appName}',
                      style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _receiptRow({
    required pw.Widget description,
    required String amount,
    required pw.Font boldFont,
  }) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.75)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(child: description),
          if (amount.isNotEmpty) ...[
            pw.SizedBox(width: 10),
            pw.Text(amount, style: pw.TextStyle(font: boldFont, fontSize: 10)),
          ],
        ],
      ),
    );
  }

  static String _shortId(String id) {
    final digitsOnly = id.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitsOnly.length <= 6) return digitsOnly;
    return digitsOnly.substring(digitsOnly.length - 6);
  }
}
