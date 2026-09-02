// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Bengali Bangla (`bn`).
class AppLocalizationsBn extends AppLocalizations {
  AppLocalizationsBn([String locale = 'bn']) : super(locale);

  @override
  String get appTitle => 'Smart Due';

  @override
  String get cancel => 'বাতিল';

  @override
  String get save => 'সেভ করুন';

  @override
  String get seeAll => 'সব দেখুন';

  @override
  String get logout => 'লগআউট';

  @override
  String get logoutConfirm => 'আপনি কি লগআউট করতে চান?';

  @override
  String get greetingMorning => 'শুভ সকাল';

  @override
  String get greetingAfternoon => 'শুভ বিকাল';

  @override
  String get greetingEvening => 'শুভ সন্ধ্যা';

  @override
  String get dataLoadError => 'ডেটা লোড করতে সমস্যা হয়েছে, আবার লগইন করুন';

  @override
  String get todaysCollection => 'আজকের Collection';

  @override
  String get weeksCollection => 'এই সপ্তাহের Collection';

  @override
  String get totalDue => 'মোট বকেয়া';

  @override
  String get totalCustomers => 'মোট কাস্টমার';

  @override
  String get overdueReminders => 'মেয়াদোত্তীর্ণ রিমাইন্ডার';

  @override
  String get fullyPaid => 'সম্পূর্ণ পরিশোধিত';

  @override
  String get withDue => 'বকেয়া আছে';

  @override
  String get upcomingReminders => 'আসন্ন রিমাইন্ডার';

  @override
  String get topDueCustomers => 'সর্বোচ্চ বকেয়া কাস্টমার';

  @override
  String get noOutstandingDues => 'কোনো বকেয়া নেই — সব পরিষ্কার! 🎉';

  @override
  String get noUpcomingReminders => 'কোনো upcoming reminder নেই';

  @override
  String get navHome => 'হোম';

  @override
  String get navAddCustomer => 'কাস্টমার যোগ';

  @override
  String get navAllCustomers => 'সব কাস্টমার';

  @override
  String get navReminders => 'রিমাইন্ডার';

  @override
  String get drawerHome => 'হোম';

  @override
  String get drawerNotebooks => 'নোটবুক';

  @override
  String get drawerReports => 'রিপোর্ট';

  @override
  String get drawerArchived => 'আর্কাইভড কাস্টমার';

  @override
  String get drawerSettings => 'সেটিংস';

  @override
  String get drawerHelp => 'হেল্প ও সাপোর্ট';

  @override
  String get drawerFeedback => 'ফিডব্যাক পাঠান';

  @override
  String get drawerRate => 'অ্যাপ রেট করুন';

  @override
  String get darkMode => 'ডার্ক মোড';

  @override
  String get lightMode => 'লাইট মোড';

  @override
  String get emailAppNotFound => 'ইমেইল অ্যাপ পাওয়া যায়নি';

  @override
  String get playStoreNotFound => 'Play Store খোলা যায়নি';

  @override
  String get settingsTitle => 'সেটিংস';

  @override
  String get groupAppearance => 'অ্যাপিয়ারেন্স';

  @override
  String get themeColor => 'থিম কালার';

  @override
  String get appMode => 'অ্যাপ মোড';

  @override
  String get fontSize => 'ফন্ট সাইজ';

  @override
  String get fontScaleSmall => 'ছোট';

  @override
  String get fontScaleNormal => 'নরমাল';

  @override
  String get fontScaleMedium => 'মাঝারি';

  @override
  String get fontScaleLarge => 'বড়';

  @override
  String get fontScaleExtraLarge => 'অতি বড়';

  @override
  String get language => 'ভাষা';

  @override
  String get groupBusiness => 'বিজনেস';

  @override
  String get currency => 'কারেন্সি';

  @override
  String get businessProfile => 'বিজনেস প্রোফাইল';

  @override
  String get logoUpdated => 'লোগো আপডেট হয়েছে';

  @override
  String get logoUploadFailed => 'লোগো আপলোড ব্যর্থ, আবার চেষ্টা করুন';

  @override
  String get businessInfoSaved => 'বিজনেস তথ্য সেভ হয়েছে';

  @override
  String get businessShopName => 'Business/Shop নাম';

  @override
  String get ownerNameLabel => 'মালিকের নাম';

  @override
  String get addressLabel => 'ঠিকানা';

  @override
  String get smsTemplate => 'SMS টেমপ্লেট';

  @override
  String get dueReminderLabel => 'Due Reminder';

  @override
  String get dueReminderDesc =>
      'কাস্টমারের বকেয়া ৳0 এর বেশি থাকলে এই টেমপ্লেট ব্যবহার হবে';

  @override
  String get smsTemplateHint => 'আপনার SMS টেমপ্লেট লিখুন...';

  @override
  String get fullPaymentThankYouLabel => 'Full Payment Thank You';

  @override
  String get fullPaymentThankYouDesc =>
      'কাস্টমারের বকেয়া সম্পূর্ণ পরিশোধ (৳0) হয়ে গেলে এই টেমপ্লেট ব্যবহার হবে';

  @override
  String get thankYouTemplateHint => 'ধন্যবাদ জানানোর SMS টেমপ্লেট লিখুন...';

  @override
  String get partialPaymentLabel => 'আংশিক পেমেন্ট ধন্যবাদ';

  @override
  String get partialPaymentDesc =>
      'কাস্টমার বকেয়ার কিছু অংশ পরিশোধ করলে এবং কিছু বকেয়া থেকে গেলে এই টেমপ্লেট ব্যবহার হবে';

  @override
  String get partialPaymentTemplateHint =>
      'আংশিক পেমেন্টের SMS টেমপ্লেট লিখুন...';

  @override
  String get templateSaved => 'টেমপ্লেট সেভ হয়েছে';

  @override
  String get saveTemplate => 'টেমপ্লেট সেভ করুন';

  @override
  String get placeholderHelpLabel =>
      'প্লেসহোল্ডারগুলোর মানে কী? দেখতে ট্যাপ করুন';

  @override
  String get placeholderGuideTitle => 'প্লেসহোল্ডার গাইড';

  @override
  String get placeholderNameDesc => 'কাস্টমারের নাম';

  @override
  String get placeholderAmountDesc => 'কাস্টমারের বকেয়া পরিমাণ';

  @override
  String get placeholderDueDateDesc => 'পরিশোধের শেষ তারিখ';

  @override
  String get placeholderBusinessNameDesc => 'আপনার ব্যবসা/দোকানের নাম';

  @override
  String get placeholderPhoneDesc => 'কাস্টমারের ফোন নম্বর';

  @override
  String get placeholderPaidAmountDesc => 'এইমাত্র যে টাকা পরিশোধ হলো';

  @override
  String get placeholderRemainingDueDesc =>
      'এই পেমেন্টের পর যে বকেয়া বাকি রইল';

  @override
  String get groupSecurity => 'নিরাপত্তা ও ডেটা';

  @override
  String get appLock => 'App Lock (নিরাপত্তা)';

  @override
  String get appLockEnabledStatus => 'App Lock চালু আছে';

  @override
  String get appLockDisabledStatus => 'App Lock বন্ধ আছে';

  @override
  String get changePin => 'PIN পরিবর্তন করুন';

  @override
  String get enabled => 'চালু আছে';

  @override
  String get disabled => 'বন্ধ আছে';

  @override
  String get dataBackup => 'ডেটা ব্যাকআপ';

  @override
  String get exportFailed => 'এক্সপোর্ট ব্যর্থ, আবার চেষ্টা করুন';

  @override
  String get noValidCustomersFound => 'ফাইলে কোনো বৈধ কাস্টমার পাওয়া যায়নি';

  @override
  String get confirmImportTitle => 'Import নিশ্চিত করুন';

  @override
  String confirmImportBody(int count) {
    return '$count জন কাস্টমার পাওয়া গেছে। এগুলো আপনার অ্যাকাউন্টে যোগ করা হবে (যাদের ফোন নাম্বার ইতিমধ্যে আছে, তারা duplicate হিসেবে বাদ যাবে)। এগিয়ে যাবেন?';
  }

  @override
  String get importAction => 'Import করুন';

  @override
  String importedResult(int imported) {
    return '$imported জন import হয়েছে';
  }

  @override
  String skippedSuffix(int skipped) {
    return ', $skipped জন duplicate হিসেবে বাদ গেছে';
  }

  @override
  String get importFailed => 'Import ব্যর্থ, আবার চেষ্টা করুন';

  @override
  String get dataBackupDesc =>
      'সব কাস্টমারের তথ্য CSV ফাইল হিসেবে এক্সপোর্ট করুন — Excel/Google Sheets এ খোলা যাবে। আগে এক্সপোর্ট করা CSV ফাইল থেকে কাস্টমার ফিরিয়ে আনতেও (Restore) পারবেন।';

  @override
  String get exportingLabel => 'এক্সপোর্ট হচ্ছে...';

  @override
  String get exportCsv => 'CSV এক্সপোর্ট করুন';

  @override
  String get importingLabel => 'Import হচ্ছে...';

  @override
  String get restoreCsv => 'CSV থেকে Restore করুন';

  @override
  String get groupLegal => 'আইনি তথ্য';

  @override
  String get privacyPolicy => 'প্রাইভেসি পলিসি';

  @override
  String get termsOfService => 'শর্তাবলী';

  @override
  String get languageTitle => 'ভাষা';

  @override
  String get english => 'English (ইংরেজি)';

  @override
  String get bengali => 'বাংলা';

  @override
  String get createCustomer => 'কাস্টমার তৈরি করুন';

  @override
  String get addCustomField => 'কাস্টম ফিল্ড যোগ করুন';

  @override
  String get editCustomField => 'কাস্টম ফিল্ড এডিট করুন';

  @override
  String get customFieldLabelHint => 'যেমন NID নাম্বার, দোকানের নাম, রেফারেন্স';

  @override
  String get fieldType => 'ফিল্ড টাইপ';

  @override
  String get deleteField => 'ফিল্ড ডিলিট করুন';

  @override
  String get add => 'যোগ করুন';

  @override
  String alreadyDefaultField(String label) {
    return '\"$label\" আগে থেকেই একটি ডিফল্ট ফিল্ড';
  }

  @override
  String alreadyAdded(String label) {
    return '\"$label\" আগে থেকেই যোগ করা আছে';
  }

  @override
  String get photoTooLarge =>
      'ছবিটা বেশি বড়, দয়া করে আরেকটু ছোট/হালকা ছবি বেছে নিন';

  @override
  String get userNotLoggedIn => 'ইউজার লগইন করা নেই';

  @override
  String get successTitle => 'সফল!';

  @override
  String customerAddedSuccess(String name) {
    return '$name সফলভাবে যোগ করা হয়েছে।';
  }

  @override
  String get saveFailed => 'সেভ করতে ব্যর্থ, আবার চেষ্টা করুন';

  @override
  String get fullName => 'পূর্ণ নাম';

  @override
  String get pleaseEnterName => 'নাম লিখুন';

  @override
  String get phoneNumber => 'ফোন নাম্বার';

  @override
  String get addressLocation => 'ঠিকানা';

  @override
  String get initialDueAmount => 'প্রাথমিক বকেয়া পরিমাণ';

  @override
  String get selectDate => 'তারিখ নির্বাচন করুন';

  @override
  String get additionalNotes => 'অতিরিক্ত নোট';

  @override
  String get addAnotherField => 'আরেকটি ফিল্ড যোগ করুন';

  @override
  String get saveCustomerAccount => 'কাস্টমার একাউন্ট সেভ করুন';

  @override
  String get fieldTypeText => 'টেক্সট';

  @override
  String get fieldTypeNumber => 'সংখ্যা';

  @override
  String get fieldTypeDate => 'তারিখ';

  @override
  String get fieldTypeAmount => 'পরিমাণ';

  @override
  String get fieldTypeLongText => 'লম্বা টেক্সট';

  @override
  String get fieldTypePhoto => 'ছবি';

  @override
  String get callFailed => 'কল করা যায়নি, ডায়ালার পাওয়া যায়নি';

  @override
  String get sendSms => 'Send SMS';

  @override
  String bulkSmsConfirmBody(int count) {
    return 'নির্বাচিত $count জন কাস্টমারের জন্য একে একে SMS app খুলে দেওয়া হবে। প্রতিটা customer-এর জন্য আপনাকে নিজে Send বাটনে চাপতে হবে।';
  }

  @override
  String get start => 'Start';

  @override
  String smsAppOpenedResult(int opened, int total) {
    return '$opened/$total জনের জন্য SMS app খোলা হয়েছে';
  }

  @override
  String sendingSmsProgress(int current, int total) {
    return 'SMS পাঠান ($current/$total)';
  }

  @override
  String get close => 'Close';

  @override
  String get skip => 'Skip';

  @override
  String get openSmsApp => 'Open SMS App';

  @override
  String get reminderSet => 'Reminder Set';

  @override
  String get noReminder => 'No Reminder';

  @override
  String get sortDueHighLow => 'Due: High to Low';

  @override
  String get sortDueLowHigh => 'Due: Low to High';

  @override
  String get sortNameAZ => 'Name: A to Z';

  @override
  String get sortNameZA => 'Name: Z to A';

  @override
  String get sortRecentlyAdded => 'Recently Added';

  @override
  String get sortDefault => 'Default';

  @override
  String selectedCount(int count) {
    return '$count selected';
  }

  @override
  String get selectAll => 'Select All';

  @override
  String get sort => 'Sort';

  @override
  String get selectCustomers => 'Select customers';

  @override
  String get searchNamePhoneHint => 'নাম বা ফোন নাম্বার দিয়ে খুঁজুন...';

  @override
  String get yearLabel => 'Year';

  @override
  String get monthLabel => 'Month';

  @override
  String get reminderLabel => 'Reminder';

  @override
  String get clearAllFilters => 'Clear All Filters';

  @override
  String customersFoundCount(int count) {
    return '$count customer(s) found';
  }

  @override
  String totalDueColon(String amount) {
    return 'Total Due: $amount';
  }

  @override
  String noSearchResults(String query) {
    return '\'$query\' এর সাথে মিলে এমন কেউ নেই';
  }

  @override
  String get noCustomersFound => 'কোনো কাস্টমার পাওয়া যায়নি';

  @override
  String dueDateLabel(String date) {
    return 'Due date: $date';
  }

  @override
  String get enterValidAmount => 'Enter a valid amount';

  @override
  String get discountAmountInvalid => 'Discount amount সঠিক নয়';

  @override
  String get amountOrDiscountRequired => 'Amount অথবা Discount amount দিন';

  @override
  String get recordPayment => 'Record Payment';

  @override
  String get addCharge => 'Add Charge';

  @override
  String currentDueLabel(String amount) {
    return 'Current Due: $amount';
  }

  @override
  String get enterAmountLabel => 'ENTER AMOUNT';

  @override
  String get discountAmountOptional => 'Discount Amount (Optional)';

  @override
  String get discountHelperText =>
      'দিলে এই পরিমাণও বকেয়া থেকে বাদ যাবে, কিন্তু নগদ হিসেবে গণ্য হবে না';

  @override
  String get invalidDiscountAmount => 'সঠিক discount amount দিন';

  @override
  String get invalidAmount => 'সঠিক amount দিন';

  @override
  String get transactionDate => 'Transaction Date';

  @override
  String get paymentMethod => 'Payment Method';

  @override
  String get cashMethod => 'Cash';

  @override
  String get bankMethod => 'Bank';

  @override
  String get descriptionNote => 'Description / Note';

  @override
  String get addDetailsHint => 'Add additional details here...';

  @override
  String get transactionReceiptOptional => 'Transaction Receipt (Optional)';

  @override
  String get changeReceipt => 'Change Receipt';

  @override
  String get tapToUploadReceipt => 'Tap to upload billing paper/slip';

  @override
  String get confirmTransaction => 'Confirm Transaction';

  @override
  String get pdfSavedOpened => 'PDF saved and opened ✅';

  @override
  String get downloadFailed => 'Download failed, please try again';

  @override
  String get repeatReminderQuestion => 'Repeat Reminder?';

  @override
  String get repeatReminderDesc =>
      'মাসিক কিস্তির মতো বকেয়া হলে auto-repeat চালু করুন';

  @override
  String get recurrenceNone => 'None (one-time)';

  @override
  String get recurrenceWeekly => 'Weekly';

  @override
  String get recurrenceBiweekly => 'Bi-weekly (every 2 weeks)';

  @override
  String get recurrenceBiweeklyShort => 'Bi-weekly';

  @override
  String get recurrenceMonthlyFull => 'Monthly (installment)';

  @override
  String get recurrenceMonthlyShort => 'Monthly';

  @override
  String nextReminderSetResult(String date) {
    return 'পরের reminder সেট হয়েছে: $date';
  }

  @override
  String get advanceReminderFailed =>
      'Failed to advance reminder, please try again';

  @override
  String get addNoteOptional => 'Add Note (Optional)';

  @override
  String get reminderNoteHint => 'এই reminder নিয়ে কোনো নোট লিখুন...';

  @override
  String get reminderUpdatedSuccess => 'Reminder Updated ✅';

  @override
  String reminderUpdatedWithRepeat(String label) {
    return 'Reminder Updated ✅ ($label এ auto-repeat হবে)';
  }

  @override
  String get stopRecurringReminderTitle => 'Stop Recurring Reminder';

  @override
  String get cancelReminderTitle => 'Cancel Reminder';

  @override
  String stopRecurringConfirmBody(String label, String name) {
    return '\'$name\' এর $label auto-repeat reminder পুরোপুরি বন্ধ করতে চান? শুধু এই সাইকেলটা skip করতে চাইলে \'Mark Done\' ব্যবহার করুন।';
  }

  @override
  String cancelReminderConfirmBody(String name) {
    return '\'$name\' এর জন্য সেট করা reminder টা বাতিল করতে চান?';
  }

  @override
  String get stopRecurringAction => 'Stop Recurring';

  @override
  String get removeReminderAction => 'Remove Reminder';

  @override
  String get reminderRemovedSuccess => 'Reminder removed ✅';

  @override
  String get removeReminderFailed =>
      'Failed to remove reminder, please try again';

  @override
  String get smsAppNotOpened => 'SMS app খোলা যায়নি';

  @override
  String get hideCustomerTitle => 'Hide Customer';

  @override
  String hideCustomerConfirmBody(String name) {
    return 'আপনি কি নিশ্চিত \'$name\' কে হাইড করতে চান? এটি main list থেকে সরে যাবে, কিন্তু সব তথ্য ও payment history সংরক্ষিত থাকবে। প্রয়োজনে পরে Archived section থেকে আবার ফিরিয়ে আনা যাবে।';
  }

  @override
  String get hideAction => 'Hide';

  @override
  String customerHiddenSuccess(String name) {
    return '$name hidden successfully';
  }

  @override
  String get hideFailed => 'Hide failed, please try again';

  @override
  String get editCustomerTitle => 'Edit Customer';

  @override
  String get nameLabel => 'Name';

  @override
  String get phoneLabel => 'Phone';

  @override
  String get dueAmountLabel => 'Due Amount';

  @override
  String get dueDateFieldLabel => 'Due Date';

  @override
  String get dueDateEditable => 'Due Date (এডিট করা যাবে)';

  @override
  String tapsToUnlock(int count) {
    return 'আনলক করতে আরও $count বার ট্যাপ করুন';
  }

  @override
  String get dateEditableWarning =>
      'তারিখ পরিবর্তনযোগ্য — সরাসরি payment/charge এতে প্রভাব ফেলবে না';

  @override
  String get noteLabel => 'Note';

  @override
  String get customerUpdatedSuccess => 'Customer details updated ✅';

  @override
  String get smsSentHistoryTitle => 'SMS Sent History';

  @override
  String get noSmsSentYet => 'এখনো কোনো SMS পাঠানো হয়নি';

  @override
  String get reminderAutoSend => 'Reminder এর মাধ্যমে auto-send';

  @override
  String get manuallySent => 'ম্যানুয়ালি পাঠানো হয়েছে';

  @override
  String get callFailedShort => 'কল করা যায়নি';

  @override
  String get whatsappNotOpened => 'WhatsApp খোলা যায়নি';

  @override
  String dueDateWithDays(String date, String days) {
    return 'Due date: $date ($days)';
  }

  @override
  String smsSentCount(int count) {
    return 'SMS পাঠানো হয়েছে: $count বার';
  }

  @override
  String nextReminderLabel(String date) {
    return 'Next Reminder: $date';
  }

  @override
  String repeatsLabel(String label) {
    return 'Repeats $label';
  }

  @override
  String get markDoneTooltip => 'Mark Done (repeat continues)';

  @override
  String get setReminder => 'Set Reminder';

  @override
  String get paymentHistoryTitle => 'Payment History';

  @override
  String get noTransactionsYet => 'No transactions yet';

  @override
  String get todayLabel => 'আজকে';

  @override
  String get yesterdayLabel => 'গতকাল';

  @override
  String daysAgoLabel(int days) {
    return '$days দিন আগে';
  }

  @override
  String thankYouSmsConfirm(String name, String phone) {
    return '\'$name\' কে ($phone) ধন্যবাদ SMS পাঠাতে চান?';
  }

  @override
  String dueReminderSmsConfirm(String name, String phone) {
    return '\'$name\' কে ($phone) due reminder SMS পাঠাতে চান?';
  }

  @override
  String partialPaymentSmsConfirm(String name, String phone) {
    return '\'$name\' কে ($phone) পেমেন্ট-প্রাপ্তির SMS পাঠাতে চান?';
  }

  @override
  String get send => 'Send';

  @override
  String get callCompleteTitle => 'Call Complete?';

  @override
  String callCompleteBody(String name) {
    return '\'$name\' কে কল করা হয়েছে। এই reminder টা কি reminder list থেকে সরিয়ে দেবেন?';
  }

  @override
  String get keepReminder => 'Keep Reminder';

  @override
  String reminderRemovedFor(String name) {
    return 'Reminder removed for $name';
  }

  @override
  String get deleteReminderTitle => 'Delete Reminder';

  @override
  String deleteReminderConfirmBody(String name) {
    return '\'$name\' এর reminder টা মুছে দিতে চান?';
  }

  @override
  String get deleteAction => 'Delete';

  @override
  String get snoozeReminderTitle => 'Snooze Reminder';

  @override
  String get oneHour => '1 Hour';

  @override
  String get tomorrowSameTime => 'Tomorrow (same time)';

  @override
  String get threeDays => '3 Days';

  @override
  String get oneWeek => '1 Week';

  @override
  String get customDateTime => 'Custom Date & Time';

  @override
  String get setCustomDateTitle => 'Set Custom Date';

  @override
  String get chooseDateTimeQuestion => 'তারিখ ও সময় বেছে নিন?';

  @override
  String get continueAction => 'Continue';

  @override
  String reminderSnoozedTo(String date) {
    return 'Reminder snoozed to $date';
  }

  @override
  String failedToSnooze(String error) {
    return 'Failed to snooze: $error';
  }

  @override
  String get remindersTitle => 'Reminders';

  @override
  String get noRemindersSet => 'No reminders set';

  @override
  String get selectReminders => 'Select reminders';

  @override
  String get sortDateNearestFirst => 'Date ↑ (Nearest First)';

  @override
  String get sortDateLatestFirst => 'Date ↓ (Latest First)';

  @override
  String get sortOverdueFirst => 'Overdue First';

  @override
  String get sortUpcomingFirst => 'Upcoming First';

  @override
  String get overdueLabel => 'Overdue';

  @override
  String get upcomingLabel => 'Upcoming';

  @override
  String get totalLabel => 'Total';

  @override
  String get selectedLabel => 'Selected';

  @override
  String get tapToSelect => 'Tap to select';

  @override
  String get markDone => 'Mark Done';

  @override
  String get snoozeAction => 'Snooze';

  @override
  String get stopAction => 'Stop';

  @override
  String get overdueCountdown => '⚠️ Overdue';

  @override
  String daysLeft(int days) {
    return '$days day(s) left';
  }

  @override
  String hoursLeft(int hours) {
    return '$hours hour(s) left';
  }

  @override
  String minutesLeft(int minutes) {
    return '$minutes minute(s) left';
  }

  @override
  String get failedToLoadReport => 'Failed to load report, please try again';

  @override
  String get collectionReportsTitle => 'Collection Reports';

  @override
  String get customerPdfReportTooltip => 'Customer PDF Report';

  @override
  String get downloadPdfTooltip => 'Download PDF';

  @override
  String get dashboardLabel => 'Dashboard';

  @override
  String get periodDaily => 'Daily';

  @override
  String get periodWeekly => 'Weekly';

  @override
  String get periodMonthly => 'Monthly';

  @override
  String ownerLabel(String name) {
    return 'Owner: $name';
  }

  @override
  String get customerPaymentDetails => 'Customer Payment Details';

  @override
  String get noTransactionsForPeriod =>
      'No transactions found for this period.';

  @override
  String get otherMethod => 'Other';

  @override
  String get paymentLabel => 'Payment';

  @override
  String get remainingLabel => 'Remaining';

  @override
  String get collectionSummaryLabel => 'Collection Summary';

  @override
  String get otherNagadBank => 'Other (Nagad/Bank)';

  @override
  String get totalCollectionLabel => 'Total Collection';

  @override
  String get monthlyCollectionTrend => 'Monthly Collection Trend';

  @override
  String get last6Months => 'Last 6 months';

  @override
  String get noPaymentRecordsPeriod => 'এই সময়ে কোনো পেমেন্ট রেকর্ড নেই';

  @override
  String get topDefaultersLabel => 'Top Defaulters';

  @override
  String get topDefaultersDesc => 'সবচেয়ে বেশি বকেয়া থাকা কাস্টমার';

  @override
  String get allClearCelebration => '🎉 কোনো বকেয়া নেই, সব কাস্টমার ক্লিয়ার';

  @override
  String poweredByApp(String app) {
    return 'Powered by $app';
  }

  @override
  String notebookDuplicated(String title) {
    return '\"$title\" duplicated';
  }

  @override
  String get deleteNotebookTitle => 'Delete Notebook';

  @override
  String deleteNotebookConfirmBody(String title) {
    return '\"$title\" ও এর সব page স্থায়ীভাবে মুছে যাবে। আপনি কি নিশ্চিত?';
  }

  @override
  String get openAction => 'Open';

  @override
  String get renameEditAction => 'Rename / Edit';

  @override
  String get duplicateAction => 'Duplicate';

  @override
  String get sortRecentlyUpdated => 'Recently Updated';

  @override
  String get sortRecentlyCreated => 'Recently Created';

  @override
  String get notebookSortNameAZ => 'Name A-Z';

  @override
  String get notebookSortNameZA => 'Name Z-A';

  @override
  String get newNotebook => 'New Notebook';

  @override
  String get searchNotebooksHint => 'Search notebooks...';

  @override
  String get notebookLoadFailed => 'নোটবুক লোড করা যায়নি';

  @override
  String get createFirstNotebook => 'Create your first notebook';

  @override
  String get notebooksDesc =>
      'Notebooks let you write, organize and format notes freely.';

  @override
  String get newNotebookPlus => '+ New Notebook';

  @override
  String get noNotebooksFound => 'No notebooks found';

  @override
  String noResultsFor(String query) {
    return 'No results for \"$query\"';
  }

  @override
  String get newNotebookTitle => 'New Notebook';

  @override
  String get editNotebookTitle => 'Edit Notebook';

  @override
  String get notebookNameHint => 'Notebook name';

  @override
  String get descriptionOptionalHint => 'Description (optional)';

  @override
  String get coverColorLabel => 'Cover color';

  @override
  String get createAction => 'Create';

  @override
  String updatedOnLabel(String date) {
    return '$date এ আপডেট হয়েছে';
  }

  @override
  String get saveFailedLocalRetry =>
      'Save failed, your changes are kept locally — will retry';

  @override
  String get untitledPage => 'Untitled Page';

  @override
  String get deletePageTitle => 'Delete Page';

  @override
  String deletePageConfirmBody(String title) {
    return '\"$title\" মুছে দিতে চান?';
  }

  @override
  String get renamePageTitle => 'Rename Page';

  @override
  String get chooseFromGallery => 'Choose from Gallery';

  @override
  String get takeAPhoto => 'Take a Photo';

  @override
  String get uploadingImage => 'Uploading image...';

  @override
  String get imageUploadFailed => 'Image upload failed, please try again';

  @override
  String get notebookFallbackTitle => 'Notebook';

  @override
  String get pagesLabel => 'Pages';

  @override
  String pageLoadFailed(String error) {
    return 'Page লোড করা যায়নি: $error';
  }

  @override
  String get pageTitleHint => 'Page title';

  @override
  String get startWritingPlaceholder => 'লিখতে শুরু করুন...';

  @override
  String get savedStatus => 'Saved';

  @override
  String get savingStatus => 'Saving...';

  @override
  String get unsavedStatus => 'Unsaved changes';

  @override
  String get notebookEmptyTitle => 'This notebook is empty';

  @override
  String get createFirstPageDesc => 'Create your first page to start writing.';

  @override
  String get newPagePlus => '+ New Page';

  @override
  String get newPageTooltip => 'New Page';

  @override
  String get noPagesYet => 'কোনো page নেই';

  @override
  String get renameAction => 'Rename';

  @override
  String get restoreCustomerTitle => 'Restore Customer';

  @override
  String restoreConfirmBody(String name) {
    return '\'$name\' কে আবার active list এ ফিরিয়ে আনতে চান?';
  }

  @override
  String get restoreAction => 'Restore';

  @override
  String customerRestoredSuccess(String name) {
    return '$name restored successfully';
  }

  @override
  String get restoreFailed => 'Restore failed, please try again';

  @override
  String get deletePermanentlyTitle => 'Delete Permanently';

  @override
  String deletePermanentlyConfirmBody(String name) {
    return '\'$name\' কে স্থায়ীভাবে ডিলিট করতে চান? এর সব payment history ও reminder ডেটা সম্পূর্ণ মুছে যাবে। এটি আর কখনো ফেরত পাওয়া যাবে না।';
  }

  @override
  String get areYouAbsolutelySure => 'একদম নিশ্চিত?';

  @override
  String get undoWarningBody =>
      'এই কাজটি Undo করা যাবে না। সত্যিই স্থায়ীভাবে ডিলিট করতে চান?';

  @override
  String get yesDeleteForever => 'Yes, Delete Forever';

  @override
  String customerPermanentlyDeleted(String name) {
    return '$name permanently deleted';
  }

  @override
  String get deleteFailedGeneric => 'Delete failed, please try again';

  @override
  String get noArchivedCustomers => 'কোনো Archived customer নেই';

  @override
  String get globalSearchTitle => 'Global Search';

  @override
  String get globalSearchHint => 'কাস্টমার, পেমেন্ট বা নোটবুকে খুঁজুন...';

  @override
  String get dataLoadFailedShort => 'ডেটা লোড করা যায়নি';

  @override
  String get tryAgainMessage => 'আবার চেষ্টা করুন';

  @override
  String get retryAction => 'Retry';

  @override
  String get startTypingToSearch => 'টাইপ শুরু করুন খুঁজতে';

  @override
  String get searchEverythingDesc =>
      'কাস্টমার, পেমেন্ট হিস্ট্রি ও নোটবুক — সবকিছু একসাথে সার্চ হবে';

  @override
  String get noResultsFound => 'কোনো ফলাফল পাওয়া যায়নি';

  @override
  String noMatchesFor(String query) {
    return '\"$query\" এর সাথে মিলে এমন কিছু নেই';
  }

  @override
  String get customersSectionLabel => 'Customers';

  @override
  String get pageTitleMatched => 'Page title matched';

  @override
  String get notebookMatched => 'Notebook matched';

  @override
  String get reminderHistoryTitle => 'রিমাইন্ডার হিস্ট্রি';

  @override
  String get noReminderHistory => 'কোনো রিমাইন্ডার হিস্ট্রি নেই';

  @override
  String get statusUpcoming => 'আসন্ন';

  @override
  String get statusDueToday => 'আজই';

  @override
  String get statusOverdue => 'মেয়াদ পার হয়েছে';

  @override
  String get statusReplaced => 'প্রতিস্থাপিত';

  @override
  String recurringLabel(String label) {
    return 'Recurring · $label';
  }

  @override
  String reminderSetOnLabel(String date) {
    return 'সেট করা হয়েছে $date';
  }

  @override
  String reminderNextOnLabel(String date) {
    return 'পরবর্তী রিমাইন্ডার: $date';
  }

  @override
  String get reminderOverdueHint => 'এই রিমাইন্ডারের তারিখ পার হয়ে গেছে';

  @override
  String get reminderOverdueRecurringHint =>
      'মেয়াদ পার হয়েছে — পরের সাইকেলে যেতে ✓ চাপুন';

  @override
  String get totalRemindersLabel => 'মোট রিমাইন্ডার';

  @override
  String get daysSinceFirstReminderLabel => 'প্রথম থেকে দিন';

  @override
  String get loginTagline => 'আপনার হিসাব, আপনার নিয়ন্ত্রণে';

  @override
  String get welcomeBack => 'Welcome Back';

  @override
  String get loginToContinue => 'Login করে চালিয়ে যান';

  @override
  String get phoneHintExample => '01XXXXXXXXX';

  @override
  String get enterPhoneNumber => 'ফোন নাম্বার দিন';

  @override
  String get passwordLabel => 'Password';

  @override
  String get enterPassword => 'পাসওয়ার্ড দিন';

  @override
  String get forgotPassword => 'Forgot Password?';

  @override
  String get loginAction => 'Login';

  @override
  String get newAccountQuestion => 'নতুন অ্যাকাউন্ট? ';

  @override
  String get registerNow => 'Register করুন';

  @override
  String get createAccountTitle => 'Create Account';

  @override
  String get joinUsDesc => 'Join us and manage your transactions smartly';

  @override
  String get enterYourName => 'আপনার নাম দিন';

  @override
  String get enterValid11DigitPhone => 'সঠিক ১১ ডিজিটের ফোন নাম্বার দিন';

  @override
  String get minSixCharacters => 'কমপক্ষে ৬ ক্যারেক্টার দিন';

  @override
  String get confirmPasswordLabel => 'Confirm Password';

  @override
  String get passwordsDontMatch => 'পাসওয়ার্ড মিলছে না';

  @override
  String get getStarted => 'Get Started';

  @override
  String get alreadyHaveAccount => 'আগে থেকেই অ্যাকাউন্ট আছে? ';

  @override
  String get loginNow => 'Login করুন';

  @override
  String get otpVerificationTitle => 'ফোন নাম্বার ভেরিফাই করুন';

  @override
  String otpSentTo(String phone) {
    return 'আমরা $phone নাম্বারে ৬ ডিজিটের কোড পাঠিয়েছি';
  }

  @override
  String get otpCodeLabel => 'OTP কোড';

  @override
  String get otpCodeHint => '৬ ডিজিটের কোড';

  @override
  String get enterOtpCode => 'OTP কোড দিন';

  @override
  String get enterValid6DigitOtp => 'সঠিক ৬ ডিজিটের কোড দিন';

  @override
  String get verifyAndCreateAccount => 'ভেরিফাই করে অ্যাকাউন্ট তৈরি করুন';

  @override
  String get sendingOtp => 'OTP পাঠানো হচ্ছে...';

  @override
  String get autoVerifyingOtp => 'অটো-ভেরিফাই হচ্ছে...';

  @override
  String get resendCode => 'আবার কোড পাঠান';

  @override
  String resendCodeIn(int seconds) {
    return '$seconds সেকেন্ড পর আবার পাঠাতে পারবেন';
  }

  @override
  String get didntReceiveCode => 'কোড পাননি? ';

  @override
  String get changePhoneNumber => 'ফোন নাম্বার পরিবর্তন করুন';

  @override
  String get otpResentSuccess => 'নতুন OTP পাঠানো হয়েছে';

  @override
  String get forgotPasswordTitle => 'পাসওয়ার্ড রিসেট করুন';

  @override
  String get resetPasswordDesc =>
      'নতুন পাসওয়ার্ড সেট করতে ফোন নাম্বার ভেরিফাই করুন';

  @override
  String get newPasswordLabel => 'নতুন পাসওয়ার্ড';

  @override
  String get confirmNewPasswordLabel => 'নতুন পাসওয়ার্ড আবার দিন';

  @override
  String get verifyAndResetPassword => 'ভেরিফাই করে পাসওয়ার্ড রিসেট করুন';

  @override
  String get unlockToVerify => 'অ্যাপ আনলক করতে যাচাই করুন';

  @override
  String get tooManyFailedPinAttempts =>
      'অনেকবার ভুল PIN দেওয়া হয়েছে, কিছুক্ষণ পর আবার চেষ্টা করুন';

  @override
  String get wrongPinTryAgain => 'ভুল PIN, আবার চেষ্টা করুন';

  @override
  String get pinMismatchTryAgain => 'PIN মিলছে না, আবার চেষ্টা করুন';

  @override
  String lockoutSeconds(int n) {
    return '$n সেকেন্ড';
  }

  @override
  String lockoutMinutes(int n) {
    return '$n মিনিট';
  }

  @override
  String lockoutMinutesSeconds(int n, int s) {
    return '$n মিনিট $s সেকেন্ড';
  }

  @override
  String get setNewPinTitle => 'নতুন PIN সেট করুন';

  @override
  String get reEnterPinTitle => 'PIN আবার লিখুন';

  @override
  String get unlockWithPinTitle => 'PIN দিয়ে আনলক করুন';

  @override
  String tooManyAttemptsCountdown(String remaining) {
    return 'অনেকবার ভুল PIN — $remaining পর আবার চেষ্টা করুন';
  }

  @override
  String get tryFingerprint => 'Fingerprint দিয়ে চেষ্টা করুন';

  @override
  String get frequentlyAskedQuestions => 'প্রায়ই জিজ্ঞাসিত প্রশ্ন';

  @override
  String get faq1Q => 'SMS রিমাইন্ডার কীভাবে কাজ করে?';

  @override
  String get faq1A =>
      'রিমাইন্ডার SMS আপনার ফোনের নিজস্ব SIM থেকে পাঠানো হয়। অ্যাপ প্রতিটা কাস্টমারের জন্য আলাদাভাবে SMS app খুলে মেসেজ prefilled অবস্থায় দেখায়, আপনাকে নিজে Send বাটনে চাপতে হয় — Play Store নীতি অনুযায়ী অ্যাপ নিজে থেকে bulk SMS পাঠাতে পারে না।';

  @override
  String get faq2Q => 'আমার ডেটা কি নিরাপদ?';

  @override
  String get faq2A =>
      'হ্যাঁ। সব ডেটা Firebase (Google Cloud) এ সংরক্ষিত হয়। App Lock এর জন্য ব্যবহৃত PIN ফোনেই সল্টেড হ্যাশ আকারে রাখা হয়, প্লেইনটেক্সটে কখনো সংরক্ষিত হয় না।';

  @override
  String get faq3Q => 'ডেটা ব্যাকআপ কীভাবে নেব?';

  @override
  String get faq3A =>
      'Settings → Data Backup এ গিয়ে আপনার কাস্টমার ও পেমেন্ট ডেটা CSV ফাইল হিসেবে এক্সপোর্ট করতে পারবেন।';

  @override
  String get faq4Q => 'App Lock কীভাবে চালু করব?';

  @override
  String get faq4A =>
      'Settings → App Lock এ গিয়ে একটা PIN সেট করুন। এরপর থেকে অ্যাপ ব্যাকগ্রাউন্ডে গেলে বা বন্ধ করে আবার খুললে PIN বা বায়োমেট্রিক দিয়ে আনলক করতে হবে।';

  @override
  String get faq5Q => 'কাস্টমার Archive করলে কী হয়?';

  @override
  String get faq5A =>
      'Archive করা কাস্টমার active list থেকে সরে যায় কিন্তু ডেটা মুছে যায় না। Drawer এর \"Archived Customers\" থেকে যেকোনো সময় আবার Restore করতে পারবেন, অথবা চাইলে স্থায়ীভাবে ডিলিট করতে পারবেন।';

  @override
  String get faq6Q => 'কারেন্সি বা থিম কালার পরিবর্তন করব কীভাবে?';

  @override
  String get faq6A =>
      'Settings → কারেন্সি থেকে টাকার চিহ্ন, আর Settings → থিম কালার থেকে অ্যাপের রঙ পরিবর্তন করা যাবে। Dark/Light মোডও Settings → অ্যাপ মোড থেকে বদলানো যায় (অথবা Drawer এর কুইক টগল থেকেও)।';

  @override
  String get faq7Q => 'Notebook ফিচারটা কী কাজে লাগে?';

  @override
  String get faq7A =>
      'হিসাব-নিকাশের বাইরেও যদি কোনো নোট, মনে রাখার তথ্য লিখে রাখতে চান, তার জন্যই Notebook ফিচার — এটি কাস্টমার ডেটা থেকে সম্পূর্ণ আলাদা।';

  @override
  String get needMoreHelp => 'আরও সাহায্য দরকার?';

  @override
  String contactDirectly(String email) {
    return 'সরাসরি যোগাযোগ করুন: $email';
  }

  @override
  String get privacyPolicyTitle => 'Privacy Policy';

  @override
  String get termsOfServiceTitle => 'Terms of Service';

  @override
  String lastUpdatedLabel(String date) {
    return 'সর্বশেষ আপডেট: $date';
  }

  @override
  String contactForQuestions(String email) {
    return 'প্রশ্ন থাকলে যোগাযোগ করুন: $email';
  }

  @override
  String get receiptGenerationFailed =>
      'Receipt তৈরি করা যায়নি, আবার চেষ্টা করুন';

  @override
  String get paymentTypeLabel => 'Payment';

  @override
  String get chargeAddedLabel => 'Charge Added';

  @override
  String amountColonLabel(String amount) {
    return 'Amount: $amount';
  }

  @override
  String discountColonLabel(String amount) {
    return 'Discount: $amount';
  }

  @override
  String dateColonLabel(String date) {
    return 'Date: $date';
  }

  @override
  String methodColonLabel(String method) {
    return 'Method: $method';
  }

  @override
  String get descriptionColonLabel => 'Description:';

  @override
  String get generatingLabel => 'তৈরি হচ্ছে...';

  @override
  String get shareReceiptAction => 'Share Receipt';

  @override
  String get imageLoadFailed => 'ছবি লোড করা যায়নি';

  @override
  String discountAppliedLabel(String amount) {
    return '-$amount discount';
  }

  @override
  String get accountDisabledTitle => 'অ্যাকাউন্ট বন্ধ করা হয়েছে';

  @override
  String get accountDisabledMessage =>
      'আপনার অ্যাকাউন্টটি অ্যাডমিন কর্তৃক বন্ধ করে দেওয়া হয়েছে। এটি ভুল মনে হলে সাপোর্টের সাথে যোগাযোগ করুন।';

  @override
  String get notificationsTitle => 'নোটিফিকেশন';

  @override
  String get noNotifications => 'এখনো কোনো নোটিফিকেশন নেই';

  @override
  String get statusInactive => 'নিষ্ক্রিয়';

  @override
  String get noticeDetailTitle => 'নোটিশ';

  @override
  String get scheduleLabel => 'সময়সূচি';

  @override
  String get noScheduleWindow =>
      'কোনো সময়সীমা নেই — active থাকা পর্যন্ত সবসময় দেখাবে';

  @override
  String get maintenanceTitle => 'রক্ষণাবেক্ষণ চলছে';

  @override
  String get maintenanceDefaultMessage =>
      'আমরা কিছু নির্ধারিত রক্ষণাবেক্ষণের কাজ করছি। একটু পরে আবার চেষ্টা করুন।';

  @override
  String maintenanceEtaLabel(String date) {
    return 'প্রায় $date নাগাদ ফিরবে';
  }

  @override
  String get forceUpdateTitle => 'আপডেট প্রয়োজন';

  @override
  String forceUpdateMessage(String version) {
    return 'চালিয়ে যেতে অ্যাপের নতুন ভার্সন প্রয়োজন। দয়া করে $version বা তার পরের ভার্সনে আপডেট করুন।';
  }

  @override
  String get updateNowButton => 'এখনই আপডেট করুন';

  @override
  String get groupAbout => 'সম্পর্কে';

  @override
  String get aboutAppTitle => 'অ্যাপ সম্পর্কে';

  @override
  String appVersionLabel(String version) {
    return 'ভার্সন $version';
  }

  @override
  String get contactTitle => 'যোগাযোগ';

  @override
  String get contactSupportEmail => 'সাপোর্ট ইমেইল';

  @override
  String get contactSupportPhone => 'সাপোর্ট ফোন';

  @override
  String get contactWhatsapp => 'হোয়াটসঅ্যাপ';

  @override
  String get contactFacebook => 'ফেসবুক পেজ';

  @override
  String get contactWebsite => 'ওয়েবসাইট';

  @override
  String get noContactInfo => 'এখনো কোনো যোগাযোগের তথ্য যোগ করা হয়নি';

  @override
  String get faqTitle => 'সচরাচর জিজ্ঞাসা';

  @override
  String get noFaqItems => 'এখনো কোনো প্রশ্ন যোগ করা হয়নি';

  @override
  String get copyLabel => 'কপি করুন';

  @override
  String get copiedToClipboard => 'ক্লিপবোর্ডে কপি হয়েছে';

  @override
  String get agreementPrefix => 'আমি ';

  @override
  String get agreementConnector => ' ও ';

  @override
  String get agreementSuffix => ' এর সাথে সম্মত';

  @override
  String get agreeToTermsRequired =>
      'চালিয়ে যেতে Privacy Policy ও Terms of Service এর সাথে সম্মত হন';

  @override
  String get policyUpdatedTitle => 'আমাদের নীতিমালা আপডেট হয়েছে';

  @override
  String get policyUpdatedMessage =>
      'আমরা আমাদের Privacy Policy এবং/অথবা Terms of Service আপডেট করেছি। অ্যাপ ব্যবহার চালিয়ে যেতে দয়া করে পড়ে সম্মতি দিন।';

  @override
  String get reviewPrivacyPolicy => 'Privacy Policy দেখুন';

  @override
  String get reviewTermsOfService => 'Terms of Service দেখুন';

  @override
  String get iHaveReviewedAgreement =>
      'আমি আপডেট হওয়া Privacy Policy ও Terms of Service পড়েছি এবং সম্মত';

  @override
  String get acceptAndContinue => 'সম্মত হয়ে চালিয়ে যান';
}
