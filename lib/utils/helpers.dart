String formatCurrency(double amount) => '\$${amount.toStringAsFixed(2)}';

String formatPhoneNumber(String phone) => phone.trim();

/// ✅ Debug লগে পুরো ফোন নাম্বার প্লেইনটেক্সটে না রেখে শেষ ৩ ডিজিট ছাড়া বাকিটা মাস্ক করে
/// দেয় — লগ থেকে কাস্টমারের নাম্বার সরাসরি পড়া না যায়, তবু আলাদা এন্ট্রি চেনা যায়।
String maskPhone(String? phone) {
  if (phone == null || phone.isEmpty) return 'unknown';
  if (phone.length <= 3) return '*' * phone.length;
  return '${'*' * (phone.length - 3)}${phone.substring(phone.length - 3)}';
}
