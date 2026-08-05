String formatCurrency(double amount) => '\$${amount.toStringAsFixed(2)}';

String formatPhoneNumber(String phone) => phone.trim();

/// ✅ Debug লগে পুরো ফোন নাম্বার প্লেইনটেক্সটে না রেখে শেষ ৩ ডিজিট ছাড়া বাকিটা মাস্ক করে
/// দেয় — লগ থেকে কাস্টমারের নাম্বার সরাসরি পড়া না যায়, তবু আলাদা এন্ট্রি চেনা যায়।
String maskPhone(String? phone) {
  if (phone == null || phone.isEmpty) return 'unknown';
  if (phone.length <= 3) return '*' * phone.length;
  return '${'*' * (phone.length - 3)}${phone.substring(phone.length - 3)}';
}

/// ✅ Play Store SMS/Call Log permission policy অনুযায়ী app নিজে SEND_SMS দিয়ে
/// SMS পাঠাতে পারে না — এর বদলে default SMS app কে prefilled message সহ খুলে
/// দেওয়া হয়, ব্যবহারকারী নিজে Send করবেন।
Uri buildSmsComposeUri(String phone, String message) {
  final cleanPhone = phone.replaceAll(RegExp(r'[\s\-]'), '');
  return Uri(
    scheme: 'sms',
    path: cleanPhone,
    queryParameters: {'body': message},
  );
}
