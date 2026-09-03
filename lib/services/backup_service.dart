import 'dart:io';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';

import '../models/customer.dart';

class BackupService {
  // ✅ Export এ ব্যবহৃত কলাম অর্ডার — import parsing এর সাথে মিল রাখতে এখানেও রেফারেন্স
  static const List<String> _csvHeader = [
    'ID', 'নাম', 'ফোন', 'ঠিকানা', 'বকেয়া', 'Due Date', 'তৈরি হয়েছে', 'আর্কাইভ',
  ];

  static Future<void> exportCustomersToCsv(List<Customer> customers) async {
    final dateFmt = DateFormat('yyyy-MM-dd');

    final rows = <List<dynamic>>[_csvHeader];

    for (final c in customers) {
      rows.add([
        c.id,
        c.name,
        c.phone,
        c.address ?? '',
        c.totalDue,
        dateFmt.format(c.lastPaymentDate),
        dateFmt.format(c.createdAt),
        c.isHidden ? 'হ্যাঁ' : 'না',
      ]);
    }

    final csvData = const ListToCsvConverter().convert(rows);

    final dir = await getTemporaryDirectory();
    final fileName = 'smart_due_backup_${dateFmt.format(DateTime.now())}.csv';
    final file = File('${dir.path}/$fileName');
    await file.writeAsString(csvData, encoding: SystemEncoding());

    // ✅ ব্যাপকভাবে সাপোর্টেড পুরোনো API ব্যবহার করা হচ্ছে (সব share_plus ভার্সনে কাজ করে)
    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'Smart Due — Customer Backup (${customers.length} জন)',
    );
  }

  /// ✅ ইউজারকে ফাইল পিকার দেখিয়ে একটা .csv ফাইল বেছে নিতে বলে, কনটেন্ট স্ট্রিং হিসেবে রিটার্ন করে।
  /// ইউজার বাতিল করলে null রিটার্ন করে।
  static Future<String?> pickCsvFileContent() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );
    final path = result?.files.single.path;
    if (path == null) return null;
    return File(path).readAsString();
  }

  // ✅ কয়েকটা সবচেয়ে-সম্ভাব্য fallback date ফরম্যাট — Excel এ CSV খুলে সেভ
  // করলে প্রায়ই yyyy-MM-dd বদলে লোকাল ফরম্যাটে (slash-সহ) সেভ হয়ে যায়
  static final List<DateFormat> _dateFormats = [
    DateFormat('yyyy-MM-dd'),
    DateFormat('yyyy/MM/dd'),
    DateFormat('dd-MM-yyyy'),
    DateFormat('dd/MM/yyyy'),
  ];

  /// ✅ exportCustomersToCsv এর ঠিক উল্টো — CSV কনটেন্ট থেকে Customer লিস্ট বানায়।
  /// প্রতিটা Customer এর `id` ও `ownerId` খালি স্ট্রিং থাকে — Firestore এ লেখার সময়
  /// (CustomerRepository.importCustomers) fresh id ও বর্তমান user এর ownerId বসানো হয়,
  /// যাতে কেউ এডিট করা CSV দিয়ে অন্য owner এর ডেটা স্পুফ করতে না পারে।
  /// নাম বা ফোন খালি থাকা row গুলো silently বাদ যায় (malformed row হিসেবে ধরা হয়)।
  ///
  /// ✅ আগে বকেয়া amount বা তারিখ parse করতে ব্যর্থ হলে চুপচাপ ৳0 / আজকের
  /// তারিখ বসিয়ে দেওয়া হতো — কোনো সংকেত ছাড়াই। এই CSV সাধারণত Excel এ খুলে
  /// এডিট করা হয়, আর Excel সেভ করার সময় প্রায়ই সংখ্যায় কমা (1,500.00) বা
  /// তারিখের ফরম্যাট বদলে দেয় — ফলে re-import করলে customer-দের বকেয়া/তারিখ
  /// নিঃশব্দে ভুল হয়ে যেত। এখন এই ধরনের row গুলো গুনে রাখা হয় এবং
  /// DataBackupScreen সেটা confirm dialog এ ইউজারকে জানায়, যাতে ভুল ডেটা
  /// import হওয়ার আগেই বুঝে বাতিল/সংশোধন করা যায়।
  static ({List<Customer> customers, int amountWarnings, int dateWarnings})
      parseCustomersFromCsv(String csvContent) {
    final rows = const CsvToListConverter(eol: '\n').convert(csvContent);
    if (rows.length <= 1) {
      return (customers: <Customer>[], amountWarnings: 0, dateWarnings: 0);
    }

    var amountWarnings = 0;
    var dateWarnings = 0;

    double parseAmount(dynamic value) {
      final text = value?.toString().trim() ?? '';
      if (text.isEmpty) return 0.0;
      // ✅ Excel প্রায়ই সংখ্যায় থাউজেন্ড সেপারেটর (কমা) বা কারেন্সি সাইন যোগ
      // করে দেয় — সেগুলো বাদ দিয়ে চেষ্টা করা হচ্ছে, যাতে "1,500.00" এর মতো
      // আসলে বৈধ সংখ্যাকে অকারণে ব্যর্থ (এবং ৳0) না ধরা হয়
      final cleaned = text.replaceAll(RegExp(r'[^\d.\-]'), '');
      final parsed = double.tryParse(cleaned);
      if (parsed == null) {
        amountWarnings++;
        return 0.0;
      }
      return parsed;
    }

    DateTime parseDate(dynamic value, DateTime fallback) {
      final text = value?.toString().trim() ?? '';
      if (text.isEmpty) return fallback;
      for (final format in _dateFormats) {
        try {
          return format.parseStrict(text);
        } catch (_) {
          continue;
        }
      }
      dateWarnings++;
      return fallback;
    }

    final now = DateTime.now();
    final customers = <Customer>[];

    for (final row in rows.skip(1)) {
      if (row.length < 8) continue;

      final name = row[1].toString().trim();
      final phone = row[2].toString().trim();
      if (name.isEmpty || phone.isEmpty) continue;

      final address = row[3].toString().trim();

      customers.add(Customer(
        id: '',
        name: name,
        phone: phone,
        address: address.isEmpty ? null : address,
        totalDue: parseAmount(row[4]),
        lastPaymentDate: parseDate(row[5], now),
        createdAt: parseDate(row[6], now),
        isHidden: row[7].toString().trim() == 'হ্যাঁ',
        ownerId: '',
      ));
    }

    return (customers: customers, amountWarnings: amountWarnings, dateWarnings: dateWarnings);
  }
}