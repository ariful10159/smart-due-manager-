class LegalSection {
  const LegalSection(this.heading, this.body);

  final String heading;
  final String body;
}

/// ✅ Privacy Policy ও Terms of Service এর কনটেন্ট — এই অ্যাপ আসলে যা যা করে
/// (Firebase Auth/Firestore ব্যবহার, রিমাইন্ডারে ফোনের নিজস্ব SMS app prefilled
/// অবস্থায় খোলা — app নিজে SMS পাঠায় না, কোনো third-party ad/analytics SDK নেই)
/// তার উপর ভিত্তি করে লেখা। bn ও en দুই ভাষাতেই আছে, App Settings-এর language
/// অনুযায়ী কোনটা দেখাতে হবে তা [privacyPolicy]/[termsOfService] ঠিক করে।
///
/// ⚠️ এটা একটা draft — আইনি পরামর্শ নয়। Play Store এ পাবলিশ করার আগে
/// [supportEmail] বাস্তব যোগাযোগ ইমেইল দিয়ে বদলে দিন, এবং সম্ভব হলে একজন
/// আইনজীবী দিয়ে একবার রিভিউ করিয়ে নিন।
class LegalContent {
  static const String appName = 'Smart Due';
  static const String supportEmail = 'arifulislammasum97@gmail.com';
  static const String _lastUpdatedBn = '৫ আগস্ট, ২০২৬';
  static const String _lastUpdatedEn = 'August 5, 2026';

  static String lastUpdated(String languageCode) =>
      languageCode == 'en' ? _lastUpdatedEn : _lastUpdatedBn;

  static List<LegalSection> privacyPolicy(String languageCode) =>
      languageCode == 'en' ? _privacyPolicyEn : _privacyPolicyBn;

  static List<LegalSection> termsOfService(String languageCode) =>
      languageCode == 'en' ? _termsOfServiceEn : _termsOfServiceBn;

  // ✅ Admin panel থেকে plain-text override পাবলিশ করা হলে সেটা এখানে পার্স হয়।
  // "## Heading" দিয়ে শুরু হওয়া লাইনগুলোকে আলাদা section হিসেবে ধরা হয় (LegalDocumentView
  // এর numbered-card UI বজায় থাকার জন্য) — কোনো "## " না পেলে পুরো টেক্সটটাই একটা
  // section হিসেবে দেখানো হয়।
  static List<LegalSection> parseSections(String raw, String fallbackHeading) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return [];

    final sections = <LegalSection>[];
    String? currentHeading;
    final bodyBuffer = StringBuffer();

    void flush() {
      final heading = currentHeading;
      if (heading != null) {
        sections.add(LegalSection(heading, bodyBuffer.toString().trim()));
      }
      bodyBuffer.clear();
    }

    for (final line in trimmed.split('\n')) {
      if (line.trimLeft().startsWith('## ')) {
        flush();
        currentHeading = line.trimLeft().substring(3).trim();
      } else {
        bodyBuffer.writeln(line);
      }
    }
    flush();

    return sections.isNotEmpty ? sections : [LegalSection(fallbackHeading, trimmed)];
  }

  static const List<LegalSection> _privacyPolicyBn = [
    LegalSection(
      'আমরা যা সংগ্রহ করি',
      'আপনার নাম, ফোন নাম্বার (লগইন হিসেবে ব্যবহৃত), এবং ইচ্ছে করলে বিজনেসের নাম, '
      'ঠিকানা ও লোগো। এছাড়া আপনি অ্যাপে যেসব কাস্টমারের তথ্য যোগ করেন — নাম, ফোন '
      'নাম্বার, ঠিকানা, বকেয়ার পরিমাণ, পেমেন্ট হিস্ট্রি — সেগুলোও সংরক্ষিত হয়।',
    ),
    LegalSection(
      'কাস্টমার ডেটার দায়িত্ব',
      'কাস্টমারের তথ্য আপনি নিজে ইনপুট দেন। এই তথ্য সঠিক কিনা এবং তা সংগ্রহ করার '
      'বৈধ অধিকার আপনার আছে কিনা, সেটার দায়িত্ব আপনার। $appName শুধু এই তথ্য '
      'সংরক্ষণ ও গোছানোর একটা টুল।',
    ),
    LegalSection(
      'SMS রিমাইন্ডার কীভাবে কাজ করে',
      'রিমাইন্ডারের সময় হলে অ্যাপ আপনার ফোনের নিজস্ব SMS app-টা প্রি-ফিলড মেসেজ '
      'সহ খুলে দেয় — Send বাটনে আপনি নিজে চাপেন। আমরা কোনো মেসেজ automatic ভাবে '
      'বা কোনো সার্ভার/third-party SMS gateway দিয়ে পাঠাই না। শুধু কখন কোন '
      'কাস্টমারের রিমাইন্ডার দেখাতে হবে, সেই সময়সূচি আপনার অ্যাকাউন্টে থাকে।',
    ),
    LegalSection(
      'ডেটা কোথায় থাকে',
      'সব ডেটা Google-এর Firebase প্ল্যাটফর্মে (Authentication, Cloud Firestore) '
      'সংরক্ষিত হয়, Google Cloud-এর নিরাপত্তা অবকাঠামো দিয়ে সুরক্ষিত। দ্রুত লোড '
      'হওয়ার জন্য কিছু সেটিংসের একটা কপি ফোনেও ক্যাশ থাকে। আমাদের নিজস্ব আলাদা '
      'কোনো সার্ভার নেই।',
    ),
    LegalSection(
      'ডেটা শেয়ারিং',
      'আপনার বা কাস্টমারের কোনো তথ্য আমরা বিক্রি করি না, বিজ্ঞাপনের জন্যও কারো '
      'সাথে শেয়ার করি না। এই অ্যাপে কোনো বিজ্ঞাপন বা analytics/tracking SDK নেই। '
      'শুধুমাত্র আইনি বাধ্যবাধকতা থাকলে (যেমন সরকারি নির্দেশ) প্রাসঙ্গিক তথ্য '
      'শেয়ার করা হতে পারে।',
    ),
    LegalSection(
      'অ্যাপ যেসব পারমিশন চায়',
      'Notification (রিমাইন্ডার দেখানোর জন্য), Exact Alarm (নির্দিষ্ট সময়ে '
      'রিমাইন্ডার দেওয়ার জন্য), Camera/Gallery (কাস্টমার ছবি বা বিজনেস লোগোর '
      'জন্য), এবং Biometric (ঐচ্ছিক App Lock ফিচারের জন্য)। এই অ্যাপ সরাসরি SMS '
      'পাঠানোর, কল লগ পড়ার, বা কন্টাক্ট লিস্ট অ্যাক্সেস করার কোনো পারমিশন নেয় না।',
    ),
    LegalSection(
      'নিরাপত্তা',
      'আপনার পাসওয়ার্ড Firebase Authentication দিয়ে সুরক্ষিত। App Lock-এর PIN '
      'ফোনেই লোকালি সল্টেড PBKDF2 দিয়ে হ্যাশ করে রাখা হয় — প্লেইনটেক্সটে কখনো '
      'সংরক্ষিত হয় না। তারপরও, ইন্টারনেটে ডেটা ট্রান্সমিশনের কোনো পদ্ধতিই ১০০% '
      'নিরাপদ — এই নিশ্চয়তা আমরা দিতে পারি না।',
    ),
    LegalSection(
      'আপনার ডেটা মুছে ফেলা',
      'Settings থেকে যেকোনো সময় আপনার সব কাস্টমার ডেটা CSV হিসেবে এক্সপোর্ট করতে '
      'পারেন। আপনার অ্যাকাউন্ট ও সম্পর্কিত সব ডেটা (কাস্টমার, পেমেন্ট হিস্ট্রি, '
      'নোটবুক, সেটিংস) স্থায়ীভাবে মুছে ফেলতে Settings > Delete Account এ যান। এই '
      'কাজ সাথে সাথে হয়ে যায় এবং আর ফিরিয়ে আনা যায় না। চাইলে নিচের ইমেইলেও '
      'যোগাযোগ করে ডিলিট করার অনুরোধ জানাতে পারেন।',
    ),
    LegalSection(
      'পরিবর্তন',
      'এই Privacy Policy সময়ে সময়ে পরিবর্তন হতে পারে। বড় কোনো পরিবর্তন হলে অ্যাপের '
      'মাধ্যমে জানানোর চেষ্টা করা হবে। উপরে "সর্বশেষ আপডেট" তারিখ দেখে বুঝতে পারবেন।',
    ),
    LegalSection(
      'যোগাযোগ',
      'কোনো প্রশ্ন বা ডেটা-সংক্রান্ত অনুরোধের জন্য যোগাযোগ করুন: $supportEmail',
    ),
  ];

  static const List<LegalSection> _privacyPolicyEn = [
    LegalSection(
      'What We Collect',
      'Your name, phone number (used as login), and optionally your business '
      'name, address, and logo. We also store the customer information you '
      'add in the app — name, phone number, address, due amount, and '
      'payment history.',
    ),
    LegalSection(
      'Responsibility for Customer Data',
      'You enter customer information yourself. It is your responsibility '
      'to ensure this information is accurate and that you have the lawful '
      'right to collect it. $appName is just a tool for storing and '
      'organizing this information.',
    ),
    LegalSection(
      'How SMS Reminders Work',
      'When a reminder is due, the app opens your phone\'s own SMS app with '
      'the message prefilled — you press Send yourself. We never send any '
      'message automatically or through any server/third-party SMS '
      'gateway. Only the schedule of when to show which customer\'s '
      'reminder is stored in your account.',
    ),
    LegalSection(
      'Where Your Data Is Stored',
      'All data is stored on Google\'s Firebase platform (Authentication, '
      'Cloud Firestore), protected by Google Cloud\'s security '
      'infrastructure. A copy of some settings is also cached on your '
      'phone for faster loading. We don\'t operate any separate server of '
      'our own.',
    ),
    LegalSection(
      'Data Sharing',
      'We never sell your or your customers\' information, nor share it '
      'with anyone for advertising. This app contains no ads or '
      'analytics/tracking SDKs. Relevant information may only be shared if '
      'legally required (such as a government order).',
    ),
    LegalSection(
      'Permissions This App Requests',
      'Notification (to show reminders), Exact Alarm (to trigger reminders '
      'at the exact time), Camera/Gallery (for customer photos or business '
      'logo), and Biometric (for the optional App Lock feature). This app '
      'never requests permission to directly send SMS, read call logs, or '
      'access your contact list.',
    ),
    LegalSection(
      'Security',
      'Your password is secured with Firebase Authentication. The App Lock '
      'PIN is hashed locally on your phone with salted PBKDF2 — it is '
      'never stored in plain text. That said, no method of data '
      'transmission over the internet is 100% secure — we cannot '
      'guarantee that.',
    ),
    LegalSection(
      'Deleting Your Data',
      'You can export all your customer data as CSV anytime from '
      'Settings. To permanently delete your account and all related data '
      '(customers, payment history, notebooks, and settings), go to '
      'Settings > Delete Account. This action is immediate and cannot be '
      'undone. You can also contact the email below to request deletion.',
    ),
    LegalSection(
      'Changes',
      'This Privacy Policy may change from time to time. We will try to '
      'notify you through the app for any major changes. You can check '
      'the "Last Updated" date above to see when it was last revised.',
    ),
    LegalSection(
      'Contact',
      'For any questions or data-related requests, contact: $supportEmail',
    ),
  ];

  static const List<LegalSection> _termsOfServiceBn = [
    LegalSection(
      'অ্যাপ ব্যবহারের শর্ত',
      '$appName ব্যবহার করে আপনি নিচের শর্তগুলোতে সম্মত হচ্ছেন। এই অ্যাপ ব্যবহার '
      'করার আগে পুরো শর্তাবলী মনোযোগ দিয়ে পড়ুন।',
    ),
    LegalSection(
      'অ্যাকাউন্টের দায়িত্ব',
      'আপনার লগইন পাসওয়ার্ড ও App Lock PIN গোপন রাখার দায়িত্ব সম্পূর্ণ আপনার। এই '
      'তথ্য ফাঁস হয়ে কোনো ক্ষতি হলে তার দায়ভার $appName নেবে না।',
    ),
    LegalSection(
      'কাস্টমার ডেটা ও SMS পাঠানোর দায়িত্ব',
      'আপনি যে কাস্টমারদের তথ্য অ্যাপে যোগ করছেন এবং যাদের কাছে SMS রিমাইন্ডার '
      'পাঠাচ্ছেন, তাদের কাছে যোগাযোগ করার বৈধ অধিকার আপনার আছে কিনা তা নিশ্চিত '
      'করার দায়িত্ব আপনার। ভুল/অননুমোদিত ব্যবহারের জন্য $appName দায়ী থাকবে না।',
    ),
    LegalSection(
      'সেবার নিশ্চয়তা নেই',
      'অ্যাপটি "যেমন আছে" (as-is) ভিত্তিতে দেওয়া হয়। নোটিফিকেশন সময়মতো আসবে বা '
      'অ্যাপ কখনো বিরতিহীনভাবে চলবে — এমন কোনো নিশ্চয়তা দেওয়া হয় না। এটি ডিভাইসের '
      'নেটওয়ার্ক, ব্যাটারি অপটিমাইজেশন সেটিংস, বা অপারেটরের উপর নির্ভরশীল।',
    ),
    LegalSection(
      'কোনো পেমেন্ট প্রসেসিং নেই',
      'এই অ্যাপ শুধু বকেয়া/পেমেন্ট হিসাব ট্র্যাক করে — এটি কোনো টাকা লেনদেন, '
      'পেমেন্ট গেটওয়ে, বা আর্থিক প্রতিষ্ঠান নয়। প্রকৃত টাকা আদান-প্রদান সম্পূর্ণ '
      'অ্যাপের বাইরে (নগদ, মোবাইল ব্যাংকিং ইত্যাদি) হয়, এবং তার সঠিকতা যাচাইয়ের '
      'দায়িত্ব ব্যবহারকারীর।',
    ),
    LegalSection(
      'দায়বদ্ধতার সীমা',
      'ডেটা হারানো, ভুল হিসাব, বা রিমাইন্ডার মিস হওয়ার কারণে সৃষ্ট কোনো প্রত্যক্ষ '
      'বা পরোক্ষ ক্ষতির জন্য $appName এবং এর ডেভেলপার দায়ী থাকবে না। গুরুত্বপূর্ণ '
      'ডেটার জন্য নিয়মিত CSV ব্যাকআপ নেওয়ার পরামর্শ দেওয়া হচ্ছে।',
    ),
    LegalSection(
      'সেবা পরিবর্তন বা বন্ধ',
      'আমরা যেকোনো সময় অ্যাপের ফিচার পরিবর্তন, যোগ বা বন্ধ করার অধিকার রাখি। বড় '
      'কোনো পরিবর্তনের ক্ষেত্রে যথাসম্ভব আগে থেকে জানানোর চেষ্টা করা হবে।',
    ),
    LegalSection(
      'যোগাযোগ',
      'এই শর্তাবলী সম্পর্কে কোনো প্রশ্ন থাকলে যোগাযোগ করুন: $supportEmail',
    ),
  ];

  static const List<LegalSection> _termsOfServiceEn = [
    LegalSection(
      'Terms of Use',
      'By using $appName, you agree to the terms below. Please read the '
      'entire terms carefully before using this app.',
    ),
    LegalSection(
      'Account Responsibility',
      'It is entirely your responsibility to keep your login password and '
      'App Lock PIN confidential. $appName will not be liable for any '
      'damage caused by this information being leaked.',
    ),
    LegalSection(
      'Responsibility for Customer Data and Sending SMS',
      'It is your responsibility to ensure you have the lawful right to '
      'contact the customers whose information you add to the app and to '
      'whom you send SMS reminders. $appName will not be liable for '
      'incorrect or unauthorized use.',
    ),
    LegalSection(
      'No Guarantee of Service',
      'The app is provided "as-is". No guarantee is given that '
      'notifications will arrive on time or that the app will run '
      'uninterrupted at all times. This depends on your device\'s network, '
      'battery optimization settings, or carrier.',
    ),
    LegalSection(
      'No Payment Processing',
      'This app only tracks due/payment records — it is not a money '
      'transfer service, payment gateway, or financial institution. The '
      'actual exchange of money happens entirely outside the app (cash, '
      'mobile banking, etc.), and verifying its accuracy is the user\'s '
      'responsibility.',
    ),
    LegalSection(
      'Limitation of Liability',
      '$appName and its developer will not be liable for any direct or '
      'indirect damage caused by data loss, incorrect calculations, or '
      'missed reminders. We recommend taking regular CSV backups for '
      'important data.',
    ),
    LegalSection(
      'Service Changes or Discontinuation',
      'We reserve the right to change, add, or discontinue app features '
      'at any time. For any major changes, we will try to notify you in '
      'advance as much as possible.',
    ),
    LegalSection(
      'Contact',
      'If you have any questions about these terms, contact: $supportEmail',
    ),
  ];
}
