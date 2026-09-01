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
  String get noPaymentRecordsPeriod => 'No payment records in this period';

  @override
  String get topDefaultersLabel => 'Top Defaulters';

  @override
  String get topDefaultersDesc => 'Customers with the highest outstanding dues';

  @override
  String get allClearCelebration => '🎉 No dues — all customers clear';

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
    return '\"$title\" and all its pages will be permanently deleted. Are you sure?';
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
  String get notebookLoadFailed => 'Could not load notebooks';

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
    return 'Updated $date';
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
    return 'Delete \"$title\"?';
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
    return 'Could not load page: $error';
  }

  @override
  String get pageTitleHint => 'Page title';

  @override
  String get startWritingPlaceholder => 'Start writing...';

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
  String get noPagesYet => 'No pages yet';

  @override
  String get renameAction => 'Rename';

  @override
  String get restoreCustomerTitle => 'Restore Customer';

  @override
  String restoreConfirmBody(String name) {
    return 'Do you want to restore \'$name\' to the active list?';
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
    return 'Permanently delete \'$name\'? All payment history and reminder data will be completely erased. This cannot be undone.';
  }

  @override
  String get areYouAbsolutelySure => 'Are you absolutely sure?';

  @override
  String get undoWarningBody =>
      'This action cannot be undone. Do you really want to delete it permanently?';

  @override
  String get yesDeleteForever => 'Yes, Delete Forever';

  @override
  String customerPermanentlyDeleted(String name) {
    return '$name permanently deleted';
  }

  @override
  String get deleteFailedGeneric => 'Delete failed, please try again';

  @override
  String get noArchivedCustomers => 'No archived customers';

  @override
  String get globalSearchTitle => 'Global Search';

  @override
  String get globalSearchHint => 'Search customers, payments or notebooks...';

  @override
  String get dataLoadFailedShort => 'Could not load data';

  @override
  String get tryAgainMessage => 'Please try again';

  @override
  String get retryAction => 'Retry';

  @override
  String get startTypingToSearch => 'Start typing to search';

  @override
  String get searchEverythingDesc =>
      'Customers, payment history and notebooks — everything is searched together';

  @override
  String get noResultsFound => 'No results found';

  @override
  String noMatchesFor(String query) {
    return 'Nothing matches \"$query\"';
  }

  @override
  String get customersSectionLabel => 'Customers';

  @override
  String get pageTitleMatched => 'Page title matched';

  @override
  String get notebookMatched => 'Notebook matched';

  @override
  String get reminderHistoryTitle => 'Reminder History';

  @override
  String get noReminderHistory => 'No reminder history';

  @override
  String get statusActive => 'Active';

  @override
  String get statusExpired => 'Expired';

  @override
  String recurringLabel(String label) {
    return 'Recurring · $label';
  }

  @override
  String get loginTagline => 'Your accounts, in your control';

  @override
  String get welcomeBack => 'Welcome Back';

  @override
  String get loginToContinue => 'Login to continue';

  @override
  String get phoneHintExample => '01XXXXXXXXX';

  @override
  String get enterPhoneNumber => 'Enter phone number';

  @override
  String get passwordLabel => 'Password';

  @override
  String get enterPassword => 'Enter password';

  @override
  String get forgotPassword => 'Forgot Password?';

  @override
  String get loginAction => 'Login';

  @override
  String get newAccountQuestion => 'New account? ';

  @override
  String get registerNow => 'Register';

  @override
  String get createAccountTitle => 'Create Account';

  @override
  String get joinUsDesc => 'Join us and manage your transactions smartly';

  @override
  String get enterYourName => 'Enter your name';

  @override
  String get enterValid11DigitPhone => 'Enter a valid 11-digit phone number';

  @override
  String get minSixCharacters => 'Enter at least 6 characters';

  @override
  String get confirmPasswordLabel => 'Confirm Password';

  @override
  String get passwordsDontMatch => 'Passwords do not match';

  @override
  String get getStarted => 'Get Started';

  @override
  String get alreadyHaveAccount => 'Already have an account? ';

  @override
  String get loginNow => 'Login';

  @override
  String get unlockToVerify => 'Verify to unlock the app';

  @override
  String get tooManyFailedPinAttempts =>
      'Too many wrong PIN attempts, please try again later';

  @override
  String get wrongPinTryAgain => 'Wrong PIN, please try again';

  @override
  String get pinMismatchTryAgain => 'PIN doesn\'t match, please try again';

  @override
  String lockoutSeconds(int n) {
    return '$n seconds';
  }

  @override
  String lockoutMinutes(int n) {
    return '$n minutes';
  }

  @override
  String lockoutMinutesSeconds(int n, int s) {
    return '$n minutes $s seconds';
  }

  @override
  String get setNewPinTitle => 'Set a new PIN';

  @override
  String get reEnterPinTitle => 'Re-enter PIN';

  @override
  String get unlockWithPinTitle => 'Unlock with PIN';

  @override
  String tooManyAttemptsCountdown(String remaining) {
    return 'Too many wrong attempts — try again after $remaining';
  }

  @override
  String get tryFingerprint => 'Try with Fingerprint';

  @override
  String get frequentlyAskedQuestions => 'Frequently Asked Questions';

  @override
  String get faq1Q => 'How do SMS reminders work?';

  @override
  String get faq1A =>
      'Reminder SMS are sent from your phone\'s own SIM. The app opens the SMS app separately for each customer with the message prefilled — you have to press Send yourself. This is because Play Store policy doesn\'t allow the app to send bulk SMS on its own.';

  @override
  String get faq2Q => 'Is my data safe?';

  @override
  String get faq2A =>
      'Yes. All data is stored in Firebase (Google Cloud). The PIN used for App Lock is kept on your phone as a salted hash, never stored in plain text.';

  @override
  String get faq3Q => 'How do I back up my data?';

  @override
  String get faq3A =>
      'Go to Settings → Data Backup to export your customer and payment data as a CSV file.';

  @override
  String get faq4Q => 'How do I turn on App Lock?';

  @override
  String get faq4A =>
      'Go to Settings → App Lock and set a PIN. After that, whenever the app goes to background or is reopened, you\'ll need to unlock it with your PIN or biometrics.';

  @override
  String get faq5Q => 'What happens when I archive a customer?';

  @override
  String get faq5A =>
      'An archived customer is removed from the active list but the data isn\'t deleted. You can restore it anytime from \"Archived Customers\" in the drawer, or permanently delete it if you want.';

  @override
  String get faq6Q => 'How do I change the currency or theme color?';

  @override
  String get faq6A =>
      'You can change the currency symbol from Settings → Currency, and the app\'s color from Settings → Theme Color. Dark/Light mode can also be switched from Settings → App Mode (or the quick toggle in the Drawer).';

  @override
  String get faq7Q => 'What is the Notebook feature for?';

  @override
  String get faq7A =>
      'The Notebook feature is for writing notes or things you want to remember, separate from your accounting — it\'s completely independent from customer data.';

  @override
  String get needMoreHelp => 'Need more help?';

  @override
  String contactDirectly(String email) {
    return 'Contact us directly: $email';
  }

  @override
  String get privacyPolicyTitle => 'Privacy Policy';

  @override
  String get termsOfServiceTitle => 'Terms of Service';

  @override
  String lastUpdatedLabel(String date) {
    return 'Last updated: $date';
  }

  @override
  String contactForQuestions(String email) {
    return 'Contact for questions: $email';
  }

  @override
  String get receiptGenerationFailed =>
      'Could not generate receipt, please try again';

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
  String get generatingLabel => 'Generating...';

  @override
  String get shareReceiptAction => 'Share Receipt';

  @override
  String get imageLoadFailed => 'Could not load image';

  @override
  String discountAppliedLabel(String amount) {
    return '-$amount discount';
  }

  @override
  String get accountDisabledTitle => 'Account Disabled';

  @override
  String get accountDisabledMessage =>
      'Your account has been disabled by the administrator. Please contact support if you believe this is a mistake.';

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String get noNotifications => 'No notifications yet';

  @override
  String get statusInactive => 'Inactive';

  @override
  String get noticeDetailTitle => 'Notice';

  @override
  String get scheduleLabel => 'Schedule';

  @override
  String get noScheduleWindow =>
      'No schedule window — always shown while active';

  @override
  String get maintenanceTitle => 'Under Maintenance';

  @override
  String get maintenanceDefaultMessage =>
      'We\'re doing some scheduled maintenance. Please check back soon.';

  @override
  String maintenanceEtaLabel(String date) {
    return 'Expected back around $date';
  }

  @override
  String get forceUpdateTitle => 'Update Required';

  @override
  String forceUpdateMessage(String version) {
    return 'A new version of the app is required to continue. Please update to version $version or later.';
  }

  @override
  String get updateNowButton => 'Update Now';

  @override
  String get groupAbout => 'About';

  @override
  String get aboutAppTitle => 'About App';

  @override
  String appVersionLabel(String version) {
    return 'Version $version';
  }

  @override
  String get contactTitle => 'Contact';

  @override
  String get contactSupportEmail => 'Support email';

  @override
  String get contactSupportPhone => 'Support phone';

  @override
  String get contactWhatsapp => 'WhatsApp';

  @override
  String get contactFacebook => 'Facebook page';

  @override
  String get contactWebsite => 'Website';

  @override
  String get noContactInfo => 'No contact info added yet';

  @override
  String get faqTitle => 'FAQ';

  @override
  String get noFaqItems => 'No FAQ items yet';
}
