// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Smart Due';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get seeAll => 'See All';

  @override
  String get logout => 'Logout';

  @override
  String get logoutConfirm => 'Are you sure you want to logout?';

  @override
  String get greetingMorning => 'Good Morning';

  @override
  String get greetingAfternoon => 'Good Afternoon';

  @override
  String get greetingEvening => 'Good Evening';

  @override
  String get dataLoadError => 'Failed to load data, please login again';

  @override
  String get todaysCollection => 'Today\'s Collection';

  @override
  String get weeksCollection => 'This Week\'s Collection';

  @override
  String get totalDue => 'Total Due';

  @override
  String get totalCustomers => 'Total Customers';

  @override
  String get overdueReminders => 'Overdue Reminders';

  @override
  String get fullyPaid => 'Fully Paid';

  @override
  String get withDue => 'With Due';

  @override
  String get upcomingReminders => 'Upcoming Reminders';

  @override
  String get topDueCustomers => 'Top Due Customers';

  @override
  String get noOutstandingDues => 'No outstanding dues — all clear! 🎉';

  @override
  String get noUpcomingReminders => 'No upcoming reminders';

  @override
  String get navHome => 'Home';

  @override
  String get navAddCustomer => 'Add Customer';

  @override
  String get navAllCustomers => 'All Customers';

  @override
  String get navReminders => 'Reminders';

  @override
  String get drawerHome => 'Home';

  @override
  String get drawerNotebooks => 'Notebooks';

  @override
  String get drawerReports => 'Reports';

  @override
  String get drawerArchived => 'Archived Customers';

  @override
  String get drawerSettings => 'Settings';

  @override
  String get drawerHelp => 'Help & Support';

  @override
  String get drawerFeedback => 'Send Feedback';

  @override
  String get drawerRate => 'Rate the App';

  @override
  String get darkMode => 'Dark Mode';

  @override
  String get lightMode => 'Light Mode';

  @override
  String get emailAppNotFound => 'No email app found';

  @override
  String get playStoreNotFound => 'Could not open Play Store';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get groupAppearance => 'Appearance';

  @override
  String get themeColor => 'Theme Color';

  @override
  String get appMode => 'App Mode';

  @override
  String get fontSize => 'Font Size';

  @override
  String get fontScaleSmall => 'Small';

  @override
  String get fontScaleNormal => 'Normal';

  @override
  String get fontScaleMedium => 'Medium';

  @override
  String get fontScaleLarge => 'Large';

  @override
  String get fontScaleExtraLarge => 'Extra Large';

  @override
  String get language => 'Language';

  @override
  String get groupBusiness => 'Business';

  @override
  String get currency => 'Currency';

  @override
  String get businessProfile => 'Business Profile';

  @override
  String get logoUpdated => 'Logo updated';

  @override
  String get logoUploadFailed => 'Logo upload failed, please try again';

  @override
  String get businessInfoSaved => 'Business info saved';

  @override
  String get businessShopName => 'Business/Shop Name';

  @override
  String get ownerNameLabel => 'Owner Name';

  @override
  String get addressLabel => 'Address';

  @override
  String get smsTemplate => 'SMS Template';

  @override
  String get dueReminderLabel => 'Due Reminder';

  @override
  String get dueReminderDesc => 'Used when the customer\'s due is more than ৳0';

  @override
  String get smsTemplateHint => 'Write your SMS template...';

  @override
  String get fullPaymentThankYouLabel => 'Full Payment Thank You';

  @override
  String get fullPaymentThankYouDesc =>
      'Used when the customer\'s due becomes fully paid (৳0)';

  @override
  String get thankYouTemplateHint => 'Write your thank-you SMS template...';

  @override
  String get templateSaved => 'Template saved';

  @override
  String get saveTemplate => 'Save Template';

  @override
  String get groupSecurity => 'Security & Data';

  @override
  String get appLock => 'App Lock (Security)';

  @override
  String get appLockEnabledStatus => 'App Lock is enabled';

  @override
  String get appLockDisabledStatus => 'App Lock is disabled';

  @override
  String get changePin => 'Change PIN';

  @override
  String get enabled => 'Enabled';

  @override
  String get disabled => 'Disabled';

  @override
  String get dataBackup => 'Data Backup';

  @override
  String get exportFailed => 'Export failed, please try again';

  @override
  String get noValidCustomersFound => 'No valid customers found in the file';

  @override
  String get confirmImportTitle => 'Confirm Import';

  @override
  String confirmImportBody(int count) {
    return '$count customers found. They\'ll be added to your account (numbers that already exist will be skipped as duplicates). Continue?';
  }

  @override
  String get importAction => 'Import';

  @override
  String importedResult(int imported) {
    return '$imported imported';
  }

  @override
  String skippedSuffix(int skipped) {
    return ', $skipped skipped as duplicates';
  }

  @override
  String get importFailed => 'Import failed, please try again';

  @override
  String get dataBackupDesc =>
      'Export all customer data as a CSV file — openable in Excel/Google Sheets. You can also restore customers from a previously exported CSV file.';

  @override
  String get exportingLabel => 'Exporting...';

  @override
  String get exportCsv => 'Export CSV';

  @override
  String get importingLabel => 'Importing...';

  @override
  String get restoreCsv => 'Restore from CSV';

  @override
  String get groupLegal => 'Legal';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get termsOfService => 'Terms of Service';

  @override
  String get languageTitle => 'Language';

  @override
  String get english => 'English';

  @override
  String get bengali => 'বাংলা (Bengali)';

  @override
  String get createCustomer => 'Create Customer';

  @override
  String get addCustomField => 'Add Custom Field';

  @override
  String get editCustomField => 'Edit Custom Field';

  @override
  String get customFieldLabelHint => 'e.g. NID Number, Shop Name, Reference';

  @override
  String get fieldType => 'Field Type';

  @override
  String get deleteField => 'Delete Field';

  @override
  String get add => 'Add';

  @override
  String alreadyDefaultField(String label) {
    return '\"$label\" is already a default field';
  }

  @override
  String alreadyAdded(String label) {
    return '\"$label\" is already added';
  }

  @override
  String get photoTooLarge =>
      'Photo is too large, please choose a smaller/lighter photo';

  @override
  String get userNotLoggedIn => 'User not logged in';

  @override
  String get successTitle => 'Success!';

  @override
  String customerAddedSuccess(String name) {
    return '$name has been added successfully.';
  }

  @override
  String get saveFailed => 'Failed to save, please try again';

  @override
  String get fullName => 'Full Name';

  @override
  String get pleaseEnterName => 'Please enter name';

  @override
  String get phoneNumber => 'Phone Number';

  @override
  String get addressLocation => 'Address Location';

  @override
  String get initialDueAmount => 'Initial Due Amount';

  @override
  String get selectDate => 'Select Date';

  @override
  String get additionalNotes => 'Additional Notes';

  @override
  String get addAnotherField => 'Add another field';

  @override
  String get saveCustomerAccount => 'Save Customer Account';

  @override
  String get fieldTypeText => 'Text';

  @override
  String get fieldTypeNumber => 'Number';

  @override
  String get fieldTypeDate => 'Date';

  @override
  String get fieldTypeAmount => 'Amount';

  @override
  String get fieldTypeLongText => 'Long Text';

  @override
  String get fieldTypePhoto => 'Photo';

  @override
  String get callFailed => 'Could not call, no dialer app found';

  @override
  String get sendSms => 'Send SMS';

  @override
  String bulkSmsConfirmBody(int count) {
    return 'The SMS app will open one by one for the selected $count customers. You\'ll need to press Send yourself for each customer.';
  }

  @override
  String get start => 'Start';

  @override
  String smsAppOpenedResult(int opened, int total) {
    return 'SMS app opened for $opened/$total customers';
  }

  @override
  String sendingSmsProgress(int current, int total) {
    return 'Send SMS ($current/$total)';
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
  String get searchNamePhoneHint => 'Search by name or phone number...';

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
    return 'No one matches \'$query\'';
  }

  @override
  String get noCustomersFound => 'No customers found';

  @override
  String dueDateLabel(String date) {
    return 'Due date: $date';
  }

  @override
  String get enterValidAmount => 'Enter a valid amount';

  @override
  String get discountAmountInvalid => 'Discount amount is not valid';

  @override
  String get amountOrDiscountRequired => 'Enter Amount or Discount amount';

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
      'If given, this amount will also be deducted from due, but won\'t count as cash';

  @override
  String get invalidDiscountAmount => 'Enter a valid discount amount';

  @override
  String get invalidAmount => 'Enter a valid amount';

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
  String get pdfSavedOpened => 'PDF saved and opened';

  @override
  String get downloadFailed => 'Download failed, please try again';

  @override
  String get repeatReminderQuestion => 'Repeat Reminder?';

  @override
  String get repeatReminderDesc =>
      'Turn on auto-repeat for installment-style dues';

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
    return 'Next reminder set: $date';
  }

  @override
  String get advanceReminderFailed =>
      'Failed to advance reminder, please try again';

  @override
  String get addNoteOptional => 'Add Note (Optional)';

  @override
  String get reminderNoteHint => 'Write a note about this reminder...';

  @override
  String get reminderUpdatedSuccess => 'Reminder Updated';

  @override
  String reminderUpdatedWithRepeat(String label) {
    return 'Reminder Updated (auto-repeats $label)';
  }

  @override
  String get stopRecurringReminderTitle => 'Stop Recurring Reminder';

  @override
  String get cancelReminderTitle => 'Cancel Reminder';

  @override
  String stopRecurringConfirmBody(String label, String name) {
    return 'Stop the $label auto-repeat reminder for \'$name\' completely? To skip just this cycle, use \'Mark Done\' instead.';
  }

  @override
  String cancelReminderConfirmBody(String name) {
    return 'Cancel the reminder set for \'$name\'?';
  }

  @override
  String get stopRecurringAction => 'Stop Recurring';

  @override
  String get removeReminderAction => 'Remove Reminder';

  @override
  String get reminderRemovedSuccess => 'Reminder removed';

  @override
  String get removeReminderFailed =>
      'Failed to remove reminder, please try again';

  @override
  String get smsAppNotOpened => 'Could not open SMS app';

  @override
  String get hideCustomerTitle => 'Hide Customer';

  @override
  String hideCustomerConfirmBody(String name) {
    return 'Are you sure you want to hide \'$name\'? It will be removed from the main list, but all data and payment history will be preserved. You can bring it back later from the Archived section.';
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
  String get dueDateEditable => 'Due Date (editable)';

  @override
  String tapsToUnlock(int count) {
    return 'Tap $count more times to unlock';
  }

  @override
  String get dateEditableWarning =>
      'Date is now editable — this won\'t directly affect payment/charge records';

  @override
  String get noteLabel => 'Note';

  @override
  String get customerUpdatedSuccess => 'Customer details updated';

  @override
  String get smsSentHistoryTitle => 'SMS Sent History';

  @override
  String get noSmsSentYet => 'No SMS sent yet';

  @override
  String get reminderAutoSend => 'Auto-sent via reminder';

  @override
  String get manuallySent => 'Sent manually';

  @override
  String get callFailedShort => 'Could not make call';

  @override
  String get whatsappNotOpened => 'Could not open WhatsApp';

  @override
  String dueDateWithDays(String date, String days) {
    return 'Due date: $date ($days)';
  }

  @override
  String smsSentCount(int count) {
    return 'SMS sent: $count times';
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
  String get todayLabel => 'Today';

  @override
  String get yesterdayLabel => 'Yesterday';

  @override
  String daysAgoLabel(int days) {
    return '$days days ago';
  }

  @override
  String thankYouSmsConfirm(String name, String phone) {
    return 'Send a thank-you SMS to \'$name\' ($phone)?';
  }

  @override
  String dueReminderSmsConfirm(String name, String phone) {
    return 'Send a due reminder SMS to \'$name\' ($phone)?';
  }

  @override
  String get send => 'Send';

  @override
  String get callCompleteTitle => 'Call Complete?';

  @override
  String callCompleteBody(String name) {
    return 'You called \'$name\'. Do you want to remove this reminder from the list?';
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
    return 'Delete the reminder for \'$name\'?';
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
  String get chooseDateTimeQuestion => 'Choose date and time?';

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
}
