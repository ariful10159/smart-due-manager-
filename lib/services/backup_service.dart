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

  /// ✅ exportCustomersToCsv এর ঠিক উল্টো — CSV কনটেন্ট থেকে Customer লিস্ট বানায়।
  /// প্রতিটা Customer এর `id` ও `ownerId` খালি স্ট্রিং থাকে — Firestore এ লেখার সময়
  /// (CustomerRepository.importCustomers) fresh id ও বর্তমান user এর ownerId বসানো হয়,
  /// যাতে কেউ এডিট করা CSV দিয়ে অন্য owner এর ডেটা স্পুফ করতে না পারে।
  /// নাম বা ফোন খালি থাকা row গুলো silently বাদ যায় (malformed row হিসেবে ধরা হয়)।
  static List<Customer> parseCustomersFromCsv(String csvContent) {
    final rows = const CsvToListConverter(eol: '\n').convert(csvContent);
    if (rows.length <= 1) return [];

    final dateFmt = DateFormat('yyyy-MM-dd');
    DateTime parseDate(dynamic value, DateTime fallback) {
      final text = value?.toString().trim() ?? '';
      if (text.isEmpty) return fallback;
      try {
        return dateFmt.parseStrict(text);
      } catch (_) {
        return fallback;
      }
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
        totalDue: double.tryParse(row[4].toString()) ?? 0.0,
        lastPaymentDate: parseDate(row[5], now),
        createdAt: parseDate(row[6], now),
        isHidden: row[7].toString().trim() == 'হ্যাঁ',
        ownerId: '',
      ));
    }

    return customers;
  }
}