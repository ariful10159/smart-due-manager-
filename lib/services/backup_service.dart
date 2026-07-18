import 'dart:io';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';

import '../models/customer.dart';

class BackupService {
  static Future<void> exportCustomersToCsv(List<Customer> customers) async {
    final dateFmt = DateFormat('yyyy-MM-dd');

    final rows = <List<dynamic>>[
      ['ID', 'নাম', 'ফোন', 'ঠিকানা', 'বকেয়া', 'Due Date', 'তৈরি হয়েছে', 'আর্কাইভ'],
    ];

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
}