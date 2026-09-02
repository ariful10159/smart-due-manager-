import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_bn.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('bn'),
    Locale('en'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Smart Due'**
  String get appTitle;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @seeAll.
  ///
  /// In en, this message translates to:
  /// **'See All'**
  String get seeAll;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @logoutConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to logout?'**
  String get logoutConfirm;

  /// No description provided for @greetingMorning.
  ///
  /// In en, this message translates to:
  /// **'Good Morning'**
  String get greetingMorning;

  /// No description provided for @greetingAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good Afternoon'**
  String get greetingAfternoon;

  /// No description provided for @greetingEvening.
  ///
  /// In en, this message translates to:
  /// **'Good Evening'**
  String get greetingEvening;

  /// No description provided for @dataLoadError.
  ///
  /// In en, this message translates to:
  /// **'Failed to load data, please login again'**
  String get dataLoadError;

  /// No description provided for @todaysCollection.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Collection'**
  String get todaysCollection;

  /// No description provided for @weeksCollection.
  ///
  /// In en, this message translates to:
  /// **'This Week\'s Collection'**
  String get weeksCollection;

  /// No description provided for @totalDue.
  ///
  /// In en, this message translates to:
  /// **'Total Due'**
  String get totalDue;

  /// No description provided for @totalCustomers.
  ///
  /// In en, this message translates to:
  /// **'Total Customers'**
  String get totalCustomers;

  /// No description provided for @overdueReminders.
  ///
  /// In en, this message translates to:
  /// **'Overdue Reminders'**
  String get overdueReminders;

  /// No description provided for @fullyPaid.
  ///
  /// In en, this message translates to:
  /// **'Fully Paid'**
  String get fullyPaid;

  /// No description provided for @withDue.
  ///
  /// In en, this message translates to:
  /// **'With Due'**
  String get withDue;

  /// No description provided for @upcomingReminders.
  ///
  /// In en, this message translates to:
  /// **'Upcoming Reminders'**
  String get upcomingReminders;

  /// No description provided for @topDueCustomers.
  ///
  /// In en, this message translates to:
  /// **'Top Due Customers'**
  String get topDueCustomers;

  /// No description provided for @noOutstandingDues.
  ///
  /// In en, this message translates to:
  /// **'No outstanding dues — all clear! 🎉'**
  String get noOutstandingDues;

  /// No description provided for @noUpcomingReminders.
  ///
  /// In en, this message translates to:
  /// **'No upcoming reminders'**
  String get noUpcomingReminders;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navAddCustomer.
  ///
  /// In en, this message translates to:
  /// **'Add Customer'**
  String get navAddCustomer;

  /// No description provided for @navAllCustomers.
  ///
  /// In en, this message translates to:
  /// **'All Customers'**
  String get navAllCustomers;

  /// No description provided for @navReminders.
  ///
  /// In en, this message translates to:
  /// **'Reminders'**
  String get navReminders;

  /// No description provided for @drawerHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get drawerHome;

  /// No description provided for @drawerNotebooks.
  ///
  /// In en, this message translates to:
  /// **'Notebooks'**
  String get drawerNotebooks;

  /// No description provided for @drawerReports.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get drawerReports;

  /// No description provided for @drawerArchived.
  ///
  /// In en, this message translates to:
  /// **'Archived Customers'**
  String get drawerArchived;

  /// No description provided for @drawerSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get drawerSettings;

  /// No description provided for @drawerHelp.
  ///
  /// In en, this message translates to:
  /// **'Help & Support'**
  String get drawerHelp;

  /// No description provided for @drawerFeedback.
  ///
  /// In en, this message translates to:
  /// **'Send Feedback'**
  String get drawerFeedback;

  /// No description provided for @drawerRate.
  ///
  /// In en, this message translates to:
  /// **'Rate the App'**
  String get drawerRate;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get darkMode;

  /// No description provided for @lightMode.
  ///
  /// In en, this message translates to:
  /// **'Light Mode'**
  String get lightMode;

  /// No description provided for @emailAppNotFound.
  ///
  /// In en, this message translates to:
  /// **'No email app found'**
  String get emailAppNotFound;

  /// No description provided for @playStoreNotFound.
  ///
  /// In en, this message translates to:
  /// **'Could not open Play Store'**
  String get playStoreNotFound;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @groupAppearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get groupAppearance;

  /// No description provided for @themeColor.
  ///
  /// In en, this message translates to:
  /// **'Theme Color'**
  String get themeColor;

  /// No description provided for @appMode.
  ///
  /// In en, this message translates to:
  /// **'App Mode'**
  String get appMode;

  /// No description provided for @fontSize.
  ///
  /// In en, this message translates to:
  /// **'Font Size'**
  String get fontSize;

  /// No description provided for @fontScaleSmall.
  ///
  /// In en, this message translates to:
  /// **'Small'**
  String get fontScaleSmall;

  /// No description provided for @fontScaleNormal.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get fontScaleNormal;

  /// No description provided for @fontScaleMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get fontScaleMedium;

  /// No description provided for @fontScaleLarge.
  ///
  /// In en, this message translates to:
  /// **'Large'**
  String get fontScaleLarge;

  /// No description provided for @fontScaleExtraLarge.
  ///
  /// In en, this message translates to:
  /// **'Extra Large'**
  String get fontScaleExtraLarge;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @groupBusiness.
  ///
  /// In en, this message translates to:
  /// **'Business'**
  String get groupBusiness;

  /// No description provided for @currency.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get currency;

  /// No description provided for @businessProfile.
  ///
  /// In en, this message translates to:
  /// **'Business Profile'**
  String get businessProfile;

  /// No description provided for @logoUpdated.
  ///
  /// In en, this message translates to:
  /// **'Logo updated'**
  String get logoUpdated;

  /// No description provided for @logoUploadFailed.
  ///
  /// In en, this message translates to:
  /// **'Logo upload failed, please try again'**
  String get logoUploadFailed;

  /// No description provided for @businessInfoSaved.
  ///
  /// In en, this message translates to:
  /// **'Business info saved'**
  String get businessInfoSaved;

  /// No description provided for @businessShopName.
  ///
  /// In en, this message translates to:
  /// **'Business/Shop Name'**
  String get businessShopName;

  /// No description provided for @ownerNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Owner Name'**
  String get ownerNameLabel;

  /// No description provided for @addressLabel.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get addressLabel;

  /// No description provided for @businessPhoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Business Phone'**
  String get businessPhoneLabel;

  /// No description provided for @bkashNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'bKash/Nagad Number'**
  String get bkashNumberLabel;

  /// No description provided for @bkashNumberDesc.
  ///
  /// In en, this message translates to:
  /// **'Shown to customers so they know where to send payment'**
  String get bkashNumberDesc;

  /// No description provided for @smsTemplate.
  ///
  /// In en, this message translates to:
  /// **'SMS Template'**
  String get smsTemplate;

  /// No description provided for @dueReminderLabel.
  ///
  /// In en, this message translates to:
  /// **'Due Reminder'**
  String get dueReminderLabel;

  /// No description provided for @dueReminderDesc.
  ///
  /// In en, this message translates to:
  /// **'Used when the customer\'s due is more than ৳0'**
  String get dueReminderDesc;

  /// No description provided for @smsTemplateHint.
  ///
  /// In en, this message translates to:
  /// **'Write your SMS template...'**
  String get smsTemplateHint;

  /// No description provided for @fullPaymentThankYouLabel.
  ///
  /// In en, this message translates to:
  /// **'Full Payment Thank You'**
  String get fullPaymentThankYouLabel;

  /// No description provided for @fullPaymentThankYouDesc.
  ///
  /// In en, this message translates to:
  /// **'Used when the customer\'s due becomes fully paid (৳0)'**
  String get fullPaymentThankYouDesc;

  /// No description provided for @thankYouTemplateHint.
  ///
  /// In en, this message translates to:
  /// **'Write your thank-you SMS template...'**
  String get thankYouTemplateHint;

  /// No description provided for @partialPaymentLabel.
  ///
  /// In en, this message translates to:
  /// **'Partial Payment Thank You'**
  String get partialPaymentLabel;

  /// No description provided for @partialPaymentDesc.
  ///
  /// In en, this message translates to:
  /// **'Used when the customer pays part of the due and some due remains'**
  String get partialPaymentDesc;

  /// No description provided for @partialPaymentTemplateHint.
  ///
  /// In en, this message translates to:
  /// **'Write your partial-payment SMS template...'**
  String get partialPaymentTemplateHint;

  /// No description provided for @templateSaved.
  ///
  /// In en, this message translates to:
  /// **'Template saved'**
  String get templateSaved;

  /// No description provided for @saveTemplate.
  ///
  /// In en, this message translates to:
  /// **'Save Template'**
  String get saveTemplate;

  /// No description provided for @placeholderHelpLabel.
  ///
  /// In en, this message translates to:
  /// **'What do the placeholders mean? Tap to see'**
  String get placeholderHelpLabel;

  /// No description provided for @placeholderGuideTitle.
  ///
  /// In en, this message translates to:
  /// **'Placeholder Guide'**
  String get placeholderGuideTitle;

  /// No description provided for @placeholderNameDesc.
  ///
  /// In en, this message translates to:
  /// **'Customer\'s name'**
  String get placeholderNameDesc;

  /// No description provided for @placeholderAmountDesc.
  ///
  /// In en, this message translates to:
  /// **'Customer\'s due amount'**
  String get placeholderAmountDesc;

  /// No description provided for @placeholderDueDateDesc.
  ///
  /// In en, this message translates to:
  /// **'Payment due date'**
  String get placeholderDueDateDesc;

  /// No description provided for @placeholderBusinessNameDesc.
  ///
  /// In en, this message translates to:
  /// **'Your business/shop name'**
  String get placeholderBusinessNameDesc;

  /// No description provided for @placeholderPhoneDesc.
  ///
  /// In en, this message translates to:
  /// **'Customer\'s phone number'**
  String get placeholderPhoneDesc;

  /// No description provided for @placeholderPaidAmountDesc.
  ///
  /// In en, this message translates to:
  /// **'Amount just paid'**
  String get placeholderPaidAmountDesc;

  /// No description provided for @placeholderRemainingDueDesc.
  ///
  /// In en, this message translates to:
  /// **'Due remaining after this payment'**
  String get placeholderRemainingDueDesc;

  /// No description provided for @placeholderBusinessPhoneDesc.
  ///
  /// In en, this message translates to:
  /// **'Your business phone number'**
  String get placeholderBusinessPhoneDesc;

  /// No description provided for @placeholderBkashNumberDesc.
  ///
  /// In en, this message translates to:
  /// **'Your bKash/Nagad number to receive payment'**
  String get placeholderBkashNumberDesc;

  /// No description provided for @groupSecurity.
  ///
  /// In en, this message translates to:
  /// **'Security & Data'**
  String get groupSecurity;

  /// No description provided for @changePassword.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get changePassword;

  /// No description provided for @changePasswordDesc.
  ///
  /// In en, this message translates to:
  /// **'Update your account login password'**
  String get changePasswordDesc;

  /// No description provided for @changingPasswordForAccount.
  ///
  /// In en, this message translates to:
  /// **'Changing password for account: {phone}'**
  String changingPasswordForAccount(String phone);

  /// No description provided for @currentPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Current Password'**
  String get currentPasswordLabel;

  /// No description provided for @enterCurrentPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter your current password'**
  String get enterCurrentPassword;

  /// No description provided for @passwordChangedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Password changed successfully'**
  String get passwordChangedSuccess;

  /// No description provided for @appLock.
  ///
  /// In en, this message translates to:
  /// **'App Lock (Security)'**
  String get appLock;

  /// No description provided for @appLockEnabledStatus.
  ///
  /// In en, this message translates to:
  /// **'App Lock is enabled'**
  String get appLockEnabledStatus;

  /// No description provided for @appLockDisabledStatus.
  ///
  /// In en, this message translates to:
  /// **'App Lock is disabled'**
  String get appLockDisabledStatus;

  /// No description provided for @changePin.
  ///
  /// In en, this message translates to:
  /// **'Change PIN'**
  String get changePin;

  /// No description provided for @enabled.
  ///
  /// In en, this message translates to:
  /// **'Enabled'**
  String get enabled;

  /// No description provided for @disabled.
  ///
  /// In en, this message translates to:
  /// **'Disabled'**
  String get disabled;

  /// No description provided for @groupDangerZone.
  ///
  /// In en, this message translates to:
  /// **'Danger Zone'**
  String get groupDangerZone;

  /// No description provided for @deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get deleteAccount;

  /// No description provided for @deleteAccountDesc.
  ///
  /// In en, this message translates to:
  /// **'Permanently delete your account and all data'**
  String get deleteAccountDesc;

  /// No description provided for @deleteAccountWarningTitle.
  ///
  /// In en, this message translates to:
  /// **'This cannot be undone'**
  String get deleteAccountWarningTitle;

  /// No description provided for @deleteAccountWarningBody.
  ///
  /// In en, this message translates to:
  /// **'Deleting your account permanently removes all your customers, payment history, notebooks, and settings. This cannot be recovered.'**
  String get deleteAccountWarningBody;

  /// No description provided for @deleteAccountWarningBodyWithCount.
  ///
  /// In en, this message translates to:
  /// **'Deleting your account permanently removes all {count} customers, their full payment history, notebooks, and settings. This cannot be recovered.'**
  String deleteAccountWarningBodyWithCount(int count);

  /// No description provided for @deleteAccountAcknowledge.
  ///
  /// In en, this message translates to:
  /// **'I understand this action is permanent and cannot be undone'**
  String get deleteAccountAcknowledge;

  /// No description provided for @deleteAccountFinalConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete account permanently?'**
  String get deleteAccountFinalConfirmTitle;

  /// No description provided for @deleteAccountFinalConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'This is your last chance to cancel. All your data will be deleted right now and cannot be recovered.'**
  String get deleteAccountFinalConfirmBody;

  /// No description provided for @dataBackup.
  ///
  /// In en, this message translates to:
  /// **'Data Backup'**
  String get dataBackup;

  /// No description provided for @exportFailed.
  ///
  /// In en, this message translates to:
  /// **'Export failed, please try again'**
  String get exportFailed;

  /// No description provided for @noValidCustomersFound.
  ///
  /// In en, this message translates to:
  /// **'No valid customers found in the file'**
  String get noValidCustomersFound;

  /// No description provided for @confirmImportTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm Import'**
  String get confirmImportTitle;

  /// No description provided for @confirmImportBody.
  ///
  /// In en, this message translates to:
  /// **'{count} customers found. They\'ll be added to your account (numbers that already exist will be skipped as duplicates). Continue?'**
  String confirmImportBody(int count);

  /// No description provided for @importAction.
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get importAction;

  /// No description provided for @importedResult.
  ///
  /// In en, this message translates to:
  /// **'{imported} imported'**
  String importedResult(int imported);

  /// No description provided for @skippedSuffix.
  ///
  /// In en, this message translates to:
  /// **', {skipped} skipped as duplicates'**
  String skippedSuffix(int skipped);

  /// No description provided for @importFailed.
  ///
  /// In en, this message translates to:
  /// **'Import failed, please try again'**
  String get importFailed;

  /// No description provided for @dataBackupDesc.
  ///
  /// In en, this message translates to:
  /// **'Export all customer data as a CSV file — openable in Excel/Google Sheets. You can also restore customers from a previously exported CSV file.'**
  String get dataBackupDesc;

  /// No description provided for @exportingLabel.
  ///
  /// In en, this message translates to:
  /// **'Exporting...'**
  String get exportingLabel;

  /// No description provided for @exportCsv.
  ///
  /// In en, this message translates to:
  /// **'Export CSV'**
  String get exportCsv;

  /// No description provided for @importingLabel.
  ///
  /// In en, this message translates to:
  /// **'Importing...'**
  String get importingLabel;

  /// No description provided for @restoreCsv.
  ///
  /// In en, this message translates to:
  /// **'Restore from CSV'**
  String get restoreCsv;

  /// No description provided for @groupLegal.
  ///
  /// In en, this message translates to:
  /// **'Legal'**
  String get groupLegal;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @termsOfService.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get termsOfService;

  /// No description provided for @languageTitle.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageTitle;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @bengali.
  ///
  /// In en, this message translates to:
  /// **'বাংলা (Bengali)'**
  String get bengali;

  /// No description provided for @createCustomer.
  ///
  /// In en, this message translates to:
  /// **'Create Customer'**
  String get createCustomer;

  /// No description provided for @addCustomField.
  ///
  /// In en, this message translates to:
  /// **'Add Custom Field'**
  String get addCustomField;

  /// No description provided for @editCustomField.
  ///
  /// In en, this message translates to:
  /// **'Edit Custom Field'**
  String get editCustomField;

  /// No description provided for @customFieldLabelHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. NID Number, Shop Name, Reference'**
  String get customFieldLabelHint;

  /// No description provided for @fieldType.
  ///
  /// In en, this message translates to:
  /// **'Field Type'**
  String get fieldType;

  /// No description provided for @deleteField.
  ///
  /// In en, this message translates to:
  /// **'Delete Field'**
  String get deleteField;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @alreadyDefaultField.
  ///
  /// In en, this message translates to:
  /// **'\"{label}\" is already a default field'**
  String alreadyDefaultField(String label);

  /// No description provided for @alreadyAdded.
  ///
  /// In en, this message translates to:
  /// **'\"{label}\" is already added'**
  String alreadyAdded(String label);

  /// No description provided for @photoTooLarge.
  ///
  /// In en, this message translates to:
  /// **'Photo is too large, please choose a smaller/lighter photo'**
  String get photoTooLarge;

  /// No description provided for @userNotLoggedIn.
  ///
  /// In en, this message translates to:
  /// **'User not logged in'**
  String get userNotLoggedIn;

  /// No description provided for @successTitle.
  ///
  /// In en, this message translates to:
  /// **'Success!'**
  String get successTitle;

  /// No description provided for @customerAddedSuccess.
  ///
  /// In en, this message translates to:
  /// **'{name} has been added successfully.'**
  String customerAddedSuccess(String name);

  /// No description provided for @saveFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to save, please try again'**
  String get saveFailed;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullName;

  /// No description provided for @pleaseEnterName.
  ///
  /// In en, this message translates to:
  /// **'Please enter name'**
  String get pleaseEnterName;

  /// No description provided for @phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneNumber;

  /// No description provided for @addressLocation.
  ///
  /// In en, this message translates to:
  /// **'Address Location'**
  String get addressLocation;

  /// No description provided for @initialDueAmount.
  ///
  /// In en, this message translates to:
  /// **'Initial Due Amount'**
  String get initialDueAmount;

  /// No description provided for @selectDate.
  ///
  /// In en, this message translates to:
  /// **'Select Date'**
  String get selectDate;

  /// No description provided for @additionalNotes.
  ///
  /// In en, this message translates to:
  /// **'Additional Notes'**
  String get additionalNotes;

  /// No description provided for @addAnotherField.
  ///
  /// In en, this message translates to:
  /// **'Add another field'**
  String get addAnotherField;

  /// No description provided for @saveCustomerAccount.
  ///
  /// In en, this message translates to:
  /// **'Save Customer Account'**
  String get saveCustomerAccount;

  /// No description provided for @fieldTypeText.
  ///
  /// In en, this message translates to:
  /// **'Text'**
  String get fieldTypeText;

  /// No description provided for @fieldTypeNumber.
  ///
  /// In en, this message translates to:
  /// **'Number'**
  String get fieldTypeNumber;

  /// No description provided for @fieldTypeDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get fieldTypeDate;

  /// No description provided for @fieldTypeAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get fieldTypeAmount;

  /// No description provided for @fieldTypeLongText.
  ///
  /// In en, this message translates to:
  /// **'Long Text'**
  String get fieldTypeLongText;

  /// No description provided for @fieldTypePhoto.
  ///
  /// In en, this message translates to:
  /// **'Photo'**
  String get fieldTypePhoto;

  /// No description provided for @callFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not call, no dialer app found'**
  String get callFailed;

  /// No description provided for @sendSms.
  ///
  /// In en, this message translates to:
  /// **'Send SMS'**
  String get sendSms;

  /// No description provided for @bulkSmsConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'The SMS app will open one by one for the selected {count} customers. You\'ll need to press Send yourself for each customer.'**
  String bulkSmsConfirmBody(int count);

  /// No description provided for @start.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get start;

  /// No description provided for @smsAppOpenedResult.
  ///
  /// In en, this message translates to:
  /// **'SMS app opened for {opened}/{total} customers'**
  String smsAppOpenedResult(int opened, int total);

  /// No description provided for @sendingSmsProgress.
  ///
  /// In en, this message translates to:
  /// **'Send SMS ({current}/{total})'**
  String sendingSmsProgress(int current, int total);

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @openSmsApp.
  ///
  /// In en, this message translates to:
  /// **'Open SMS App'**
  String get openSmsApp;

  /// No description provided for @reminderSet.
  ///
  /// In en, this message translates to:
  /// **'Reminder Set'**
  String get reminderSet;

  /// No description provided for @noReminder.
  ///
  /// In en, this message translates to:
  /// **'No Reminder'**
  String get noReminder;

  /// No description provided for @sortDueHighLow.
  ///
  /// In en, this message translates to:
  /// **'Due: High to Low'**
  String get sortDueHighLow;

  /// No description provided for @sortDueLowHigh.
  ///
  /// In en, this message translates to:
  /// **'Due: Low to High'**
  String get sortDueLowHigh;

  /// No description provided for @sortNameAZ.
  ///
  /// In en, this message translates to:
  /// **'Name: A to Z'**
  String get sortNameAZ;

  /// No description provided for @sortNameZA.
  ///
  /// In en, this message translates to:
  /// **'Name: Z to A'**
  String get sortNameZA;

  /// No description provided for @sortRecentlyAdded.
  ///
  /// In en, this message translates to:
  /// **'Recently Added'**
  String get sortRecentlyAdded;

  /// No description provided for @sortDefault.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get sortDefault;

  /// No description provided for @selectedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} selected'**
  String selectedCount(int count);

  /// No description provided for @selectAll.
  ///
  /// In en, this message translates to:
  /// **'Select All'**
  String get selectAll;

  /// No description provided for @sort.
  ///
  /// In en, this message translates to:
  /// **'Sort'**
  String get sort;

  /// No description provided for @selectCustomers.
  ///
  /// In en, this message translates to:
  /// **'Select customers'**
  String get selectCustomers;

  /// No description provided for @searchNamePhoneHint.
  ///
  /// In en, this message translates to:
  /// **'Search by name or phone number...'**
  String get searchNamePhoneHint;

  /// No description provided for @yearLabel.
  ///
  /// In en, this message translates to:
  /// **'Year'**
  String get yearLabel;

  /// No description provided for @monthLabel.
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get monthLabel;

  /// No description provided for @reminderLabel.
  ///
  /// In en, this message translates to:
  /// **'Reminder'**
  String get reminderLabel;

  /// No description provided for @clearAllFilters.
  ///
  /// In en, this message translates to:
  /// **'Clear All Filters'**
  String get clearAllFilters;

  /// No description provided for @customersFoundCount.
  ///
  /// In en, this message translates to:
  /// **'{count} customer(s) found'**
  String customersFoundCount(int count);

  /// No description provided for @totalDueColon.
  ///
  /// In en, this message translates to:
  /// **'Total Due: {amount}'**
  String totalDueColon(String amount);

  /// No description provided for @noSearchResults.
  ///
  /// In en, this message translates to:
  /// **'No one matches \'{query}\''**
  String noSearchResults(String query);

  /// No description provided for @noCustomersFound.
  ///
  /// In en, this message translates to:
  /// **'No customers found'**
  String get noCustomersFound;

  /// No description provided for @dueDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Due date: {date}'**
  String dueDateLabel(String date);

  /// No description provided for @enterValidAmount.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid amount'**
  String get enterValidAmount;

  /// No description provided for @discountAmountInvalid.
  ///
  /// In en, this message translates to:
  /// **'Discount amount is not valid'**
  String get discountAmountInvalid;

  /// No description provided for @amountOrDiscountRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter Amount or Discount amount'**
  String get amountOrDiscountRequired;

  /// No description provided for @recordPayment.
  ///
  /// In en, this message translates to:
  /// **'Record Payment'**
  String get recordPayment;

  /// No description provided for @addCharge.
  ///
  /// In en, this message translates to:
  /// **'Add Charge'**
  String get addCharge;

  /// No description provided for @currentDueLabel.
  ///
  /// In en, this message translates to:
  /// **'Current Due: {amount}'**
  String currentDueLabel(String amount);

  /// No description provided for @enterAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'ENTER AMOUNT'**
  String get enterAmountLabel;

  /// No description provided for @discountAmountOptional.
  ///
  /// In en, this message translates to:
  /// **'Discount Amount (Optional)'**
  String get discountAmountOptional;

  /// No description provided for @discountHelperText.
  ///
  /// In en, this message translates to:
  /// **'If given, this amount will also be deducted from due, but won\'t count as cash'**
  String get discountHelperText;

  /// No description provided for @invalidDiscountAmount.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid discount amount'**
  String get invalidDiscountAmount;

  /// No description provided for @invalidAmount.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid amount'**
  String get invalidAmount;

  /// No description provided for @transactionDate.
  ///
  /// In en, this message translates to:
  /// **'Transaction Date'**
  String get transactionDate;

  /// No description provided for @paymentMethod.
  ///
  /// In en, this message translates to:
  /// **'Payment Method'**
  String get paymentMethod;

  /// No description provided for @cashMethod.
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get cashMethod;

  /// No description provided for @bankMethod.
  ///
  /// In en, this message translates to:
  /// **'Bank'**
  String get bankMethod;

  /// No description provided for @descriptionNote.
  ///
  /// In en, this message translates to:
  /// **'Description / Note'**
  String get descriptionNote;

  /// No description provided for @addDetailsHint.
  ///
  /// In en, this message translates to:
  /// **'Add additional details here...'**
  String get addDetailsHint;

  /// No description provided for @transactionReceiptOptional.
  ///
  /// In en, this message translates to:
  /// **'Transaction Receipt (Optional)'**
  String get transactionReceiptOptional;

  /// No description provided for @changeReceipt.
  ///
  /// In en, this message translates to:
  /// **'Change Receipt'**
  String get changeReceipt;

  /// No description provided for @tapToUploadReceipt.
  ///
  /// In en, this message translates to:
  /// **'Tap to upload billing paper/slip'**
  String get tapToUploadReceipt;

  /// No description provided for @confirmTransaction.
  ///
  /// In en, this message translates to:
  /// **'Confirm Transaction'**
  String get confirmTransaction;

  /// No description provided for @pdfSavedOpened.
  ///
  /// In en, this message translates to:
  /// **'PDF saved and opened'**
  String get pdfSavedOpened;

  /// No description provided for @downloadFailed.
  ///
  /// In en, this message translates to:
  /// **'Download failed, please try again'**
  String get downloadFailed;

  /// No description provided for @repeatReminderQuestion.
  ///
  /// In en, this message translates to:
  /// **'Repeat Reminder?'**
  String get repeatReminderQuestion;

  /// No description provided for @repeatReminderDesc.
  ///
  /// In en, this message translates to:
  /// **'Turn on auto-repeat for installment-style dues'**
  String get repeatReminderDesc;

  /// No description provided for @recurrenceNone.
  ///
  /// In en, this message translates to:
  /// **'None (one-time)'**
  String get recurrenceNone;

  /// No description provided for @recurrenceWeekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get recurrenceWeekly;

  /// No description provided for @recurrenceBiweekly.
  ///
  /// In en, this message translates to:
  /// **'Bi-weekly (every 2 weeks)'**
  String get recurrenceBiweekly;

  /// No description provided for @recurrenceBiweeklyShort.
  ///
  /// In en, this message translates to:
  /// **'Bi-weekly'**
  String get recurrenceBiweeklyShort;

  /// No description provided for @recurrenceMonthlyFull.
  ///
  /// In en, this message translates to:
  /// **'Monthly (installment)'**
  String get recurrenceMonthlyFull;

  /// No description provided for @recurrenceMonthlyShort.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get recurrenceMonthlyShort;

  /// No description provided for @nextReminderSetResult.
  ///
  /// In en, this message translates to:
  /// **'Next reminder set: {date}'**
  String nextReminderSetResult(String date);

  /// No description provided for @advanceReminderFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to advance reminder, please try again'**
  String get advanceReminderFailed;

  /// No description provided for @addNoteOptional.
  ///
  /// In en, this message translates to:
  /// **'Add Note (Optional)'**
  String get addNoteOptional;

  /// No description provided for @reminderNoteHint.
  ///
  /// In en, this message translates to:
  /// **'Write a note about this reminder...'**
  String get reminderNoteHint;

  /// No description provided for @reminderNotificationTitle.
  ///
  /// In en, this message translates to:
  /// **'Payment Reminder'**
  String get reminderNotificationTitle;

  /// No description provided for @reminderNotificationBody.
  ///
  /// In en, this message translates to:
  /// **'Time to collect payment from {name}'**
  String reminderNotificationBody(String name);

  /// No description provided for @reminderUpdatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Reminder Updated'**
  String get reminderUpdatedSuccess;

  /// No description provided for @reminderUpdatedWithRepeat.
  ///
  /// In en, this message translates to:
  /// **'Reminder Updated (auto-repeats {label})'**
  String reminderUpdatedWithRepeat(String label);

  /// No description provided for @stopRecurringReminderTitle.
  ///
  /// In en, this message translates to:
  /// **'Stop Recurring Reminder'**
  String get stopRecurringReminderTitle;

  /// No description provided for @cancelReminderTitle.
  ///
  /// In en, this message translates to:
  /// **'Cancel Reminder'**
  String get cancelReminderTitle;

  /// No description provided for @stopRecurringConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'Stop the {label} auto-repeat reminder for \'{name}\' completely? To skip just this cycle, use \'Mark Done\' instead.'**
  String stopRecurringConfirmBody(String label, String name);

  /// No description provided for @cancelReminderConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'Cancel the reminder set for \'{name}\'?'**
  String cancelReminderConfirmBody(String name);

  /// No description provided for @stopRecurringAction.
  ///
  /// In en, this message translates to:
  /// **'Stop Recurring'**
  String get stopRecurringAction;

  /// No description provided for @removeReminderAction.
  ///
  /// In en, this message translates to:
  /// **'Remove Reminder'**
  String get removeReminderAction;

  /// No description provided for @reminderRemovedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Reminder removed'**
  String get reminderRemovedSuccess;

  /// No description provided for @removeReminderFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to remove reminder, please try again'**
  String get removeReminderFailed;

  /// No description provided for @smsAppNotOpened.
  ///
  /// In en, this message translates to:
  /// **'Could not open SMS app'**
  String get smsAppNotOpened;

  /// No description provided for @hideCustomerTitle.
  ///
  /// In en, this message translates to:
  /// **'Hide Customer'**
  String get hideCustomerTitle;

  /// No description provided for @hideCustomerConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to hide \'{name}\'? It will be removed from the main list, but all data and payment history will be preserved. You can bring it back later from the Archived section.'**
  String hideCustomerConfirmBody(String name);

  /// No description provided for @hideAction.
  ///
  /// In en, this message translates to:
  /// **'Hide'**
  String get hideAction;

  /// No description provided for @customerHiddenSuccess.
  ///
  /// In en, this message translates to:
  /// **'{name} hidden successfully'**
  String customerHiddenSuccess(String name);

  /// No description provided for @hideFailed.
  ///
  /// In en, this message translates to:
  /// **'Hide failed, please try again'**
  String get hideFailed;

  /// No description provided for @editCustomerTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Customer'**
  String get editCustomerTitle;

  /// No description provided for @nameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get nameLabel;

  /// No description provided for @phoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phoneLabel;

  /// No description provided for @dueAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'Due Amount'**
  String get dueAmountLabel;

  /// No description provided for @dueDateFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'Due Date'**
  String get dueDateFieldLabel;

  /// No description provided for @dueDateEditable.
  ///
  /// In en, this message translates to:
  /// **'Due Date (editable)'**
  String get dueDateEditable;

  /// No description provided for @tapsToUnlock.
  ///
  /// In en, this message translates to:
  /// **'Tap {count} more times to unlock'**
  String tapsToUnlock(int count);

  /// No description provided for @dateEditableWarning.
  ///
  /// In en, this message translates to:
  /// **'Date is now editable — this won\'t directly affect payment/charge records'**
  String get dateEditableWarning;

  /// No description provided for @noteLabel.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get noteLabel;

  /// No description provided for @customerUpdatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Customer details updated'**
  String get customerUpdatedSuccess;

  /// No description provided for @smsSentHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'SMS Sent History'**
  String get smsSentHistoryTitle;

  /// No description provided for @noSmsSentYet.
  ///
  /// In en, this message translates to:
  /// **'No SMS sent yet'**
  String get noSmsSentYet;

  /// No description provided for @reminderAutoSend.
  ///
  /// In en, this message translates to:
  /// **'Auto-sent via reminder'**
  String get reminderAutoSend;

  /// No description provided for @manuallySent.
  ///
  /// In en, this message translates to:
  /// **'Sent manually'**
  String get manuallySent;

  /// No description provided for @callFailedShort.
  ///
  /// In en, this message translates to:
  /// **'Could not make call'**
  String get callFailedShort;

  /// No description provided for @whatsappNotOpened.
  ///
  /// In en, this message translates to:
  /// **'Could not open WhatsApp'**
  String get whatsappNotOpened;

  /// No description provided for @dueDateWithDays.
  ///
  /// In en, this message translates to:
  /// **'Due date: {date} ({days})'**
  String dueDateWithDays(String date, String days);

  /// No description provided for @smsSentCount.
  ///
  /// In en, this message translates to:
  /// **'SMS sent: {count} times'**
  String smsSentCount(int count);

  /// No description provided for @nextReminderLabel.
  ///
  /// In en, this message translates to:
  /// **'Next Reminder: {date}'**
  String nextReminderLabel(String date);

  /// No description provided for @repeatsLabel.
  ///
  /// In en, this message translates to:
  /// **'Repeats {label}'**
  String repeatsLabel(String label);

  /// No description provided for @markDoneTooltip.
  ///
  /// In en, this message translates to:
  /// **'Mark Done (repeat continues)'**
  String get markDoneTooltip;

  /// No description provided for @setReminder.
  ///
  /// In en, this message translates to:
  /// **'Set Reminder'**
  String get setReminder;

  /// No description provided for @paymentHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Payment History'**
  String get paymentHistoryTitle;

  /// No description provided for @noTransactionsYet.
  ///
  /// In en, this message translates to:
  /// **'No transactions yet'**
  String get noTransactionsYet;

  /// No description provided for @todayLabel.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get todayLabel;

  /// No description provided for @yesterdayLabel.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get yesterdayLabel;

  /// No description provided for @daysAgoLabel.
  ///
  /// In en, this message translates to:
  /// **'{days} days ago'**
  String daysAgoLabel(int days);

  /// No description provided for @thankYouSmsConfirm.
  ///
  /// In en, this message translates to:
  /// **'Send a thank-you SMS to \'{name}\' ({phone})?'**
  String thankYouSmsConfirm(String name, String phone);

  /// No description provided for @dueReminderSmsConfirm.
  ///
  /// In en, this message translates to:
  /// **'Send a due reminder SMS to \'{name}\' ({phone})?'**
  String dueReminderSmsConfirm(String name, String phone);

  /// No description provided for @partialPaymentSmsConfirm.
  ///
  /// In en, this message translates to:
  /// **'Send a payment-received SMS to \'{name}\' ({phone})?'**
  String partialPaymentSmsConfirm(String name, String phone);

  /// No description provided for @send.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get send;

  /// No description provided for @callCompleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Call Complete?'**
  String get callCompleteTitle;

  /// No description provided for @callCompleteBody.
  ///
  /// In en, this message translates to:
  /// **'You called \'{name}\'. Do you want to remove this reminder from the list?'**
  String callCompleteBody(String name);

  /// No description provided for @keepReminder.
  ///
  /// In en, this message translates to:
  /// **'Keep Reminder'**
  String get keepReminder;

  /// No description provided for @reminderRemovedFor.
  ///
  /// In en, this message translates to:
  /// **'Reminder removed for {name}'**
  String reminderRemovedFor(String name);

  /// No description provided for @deleteReminderTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Reminder'**
  String get deleteReminderTitle;

  /// No description provided for @deleteReminderConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'Delete the reminder for \'{name}\'?'**
  String deleteReminderConfirmBody(String name);

  /// No description provided for @deleteAction.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deleteAction;

  /// No description provided for @snoozeReminderTitle.
  ///
  /// In en, this message translates to:
  /// **'Snooze Reminder'**
  String get snoozeReminderTitle;

  /// No description provided for @oneHour.
  ///
  /// In en, this message translates to:
  /// **'1 Hour'**
  String get oneHour;

  /// No description provided for @tomorrowSameTime.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow (same time)'**
  String get tomorrowSameTime;

  /// No description provided for @threeDays.
  ///
  /// In en, this message translates to:
  /// **'3 Days'**
  String get threeDays;

  /// No description provided for @oneWeek.
  ///
  /// In en, this message translates to:
  /// **'1 Week'**
  String get oneWeek;

  /// No description provided for @customDateTime.
  ///
  /// In en, this message translates to:
  /// **'Custom Date & Time'**
  String get customDateTime;

  /// No description provided for @setCustomDateTitle.
  ///
  /// In en, this message translates to:
  /// **'Set Custom Date'**
  String get setCustomDateTitle;

  /// No description provided for @chooseDateTimeQuestion.
  ///
  /// In en, this message translates to:
  /// **'Choose date and time?'**
  String get chooseDateTimeQuestion;

  /// No description provided for @continueAction.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueAction;

  /// No description provided for @reminderSnoozedTo.
  ///
  /// In en, this message translates to:
  /// **'Reminder snoozed to {date}'**
  String reminderSnoozedTo(String date);

  /// No description provided for @failedToSnooze.
  ///
  /// In en, this message translates to:
  /// **'Failed to snooze: {error}'**
  String failedToSnooze(String error);

  /// No description provided for @remindersTitle.
  ///
  /// In en, this message translates to:
  /// **'Reminders'**
  String get remindersTitle;

  /// No description provided for @noRemindersSet.
  ///
  /// In en, this message translates to:
  /// **'No reminders set'**
  String get noRemindersSet;

  /// No description provided for @selectReminders.
  ///
  /// In en, this message translates to:
  /// **'Select reminders'**
  String get selectReminders;

  /// No description provided for @sortDateNearestFirst.
  ///
  /// In en, this message translates to:
  /// **'Date ↑ (Nearest First)'**
  String get sortDateNearestFirst;

  /// No description provided for @sortDateLatestFirst.
  ///
  /// In en, this message translates to:
  /// **'Date ↓ (Latest First)'**
  String get sortDateLatestFirst;

  /// No description provided for @sortOverdueFirst.
  ///
  /// In en, this message translates to:
  /// **'Overdue First'**
  String get sortOverdueFirst;

  /// No description provided for @sortUpcomingFirst.
  ///
  /// In en, this message translates to:
  /// **'Upcoming First'**
  String get sortUpcomingFirst;

  /// No description provided for @overdueLabel.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get overdueLabel;

  /// No description provided for @upcomingLabel.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get upcomingLabel;

  /// No description provided for @totalLabel.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get totalLabel;

  /// No description provided for @selectedLabel.
  ///
  /// In en, this message translates to:
  /// **'Selected'**
  String get selectedLabel;

  /// No description provided for @tapToSelect.
  ///
  /// In en, this message translates to:
  /// **'Tap to select'**
  String get tapToSelect;

  /// No description provided for @markDone.
  ///
  /// In en, this message translates to:
  /// **'Mark Done'**
  String get markDone;

  /// No description provided for @snoozeAction.
  ///
  /// In en, this message translates to:
  /// **'Snooze'**
  String get snoozeAction;

  /// No description provided for @stopAction.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get stopAction;

  /// No description provided for @overdueCountdown.
  ///
  /// In en, this message translates to:
  /// **'⚠️ Overdue'**
  String get overdueCountdown;

  /// No description provided for @daysLeft.
  ///
  /// In en, this message translates to:
  /// **'{days} day(s) left'**
  String daysLeft(int days);

  /// No description provided for @hoursLeft.
  ///
  /// In en, this message translates to:
  /// **'{hours} hour(s) left'**
  String hoursLeft(int hours);

  /// No description provided for @minutesLeft.
  ///
  /// In en, this message translates to:
  /// **'{minutes} minute(s) left'**
  String minutesLeft(int minutes);

  /// No description provided for @failedToLoadReport.
  ///
  /// In en, this message translates to:
  /// **'Failed to load report, please try again'**
  String get failedToLoadReport;

  /// No description provided for @failedToLoadCollectionStats.
  ///
  /// In en, this message translates to:
  /// **'Failed to load today\'s/week\'s collection, please try again'**
  String get failedToLoadCollectionStats;

  /// No description provided for @collectionReportsTitle.
  ///
  /// In en, this message translates to:
  /// **'Collection Reports'**
  String get collectionReportsTitle;

  /// No description provided for @customerPdfReportTooltip.
  ///
  /// In en, this message translates to:
  /// **'Customer PDF Report'**
  String get customerPdfReportTooltip;

  /// No description provided for @downloadPdfTooltip.
  ///
  /// In en, this message translates to:
  /// **'Download PDF'**
  String get downloadPdfTooltip;

  /// No description provided for @dashboardLabel.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboardLabel;

  /// No description provided for @periodDaily.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get periodDaily;

  /// No description provided for @periodWeekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get periodWeekly;

  /// No description provided for @periodMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get periodMonthly;

  /// No description provided for @ownerLabel.
  ///
  /// In en, this message translates to:
  /// **'Owner: {name}'**
  String ownerLabel(String name);

  /// No description provided for @customerPaymentDetails.
  ///
  /// In en, this message translates to:
  /// **'Customer Payment Details'**
  String get customerPaymentDetails;

  /// No description provided for @noTransactionsForPeriod.
  ///
  /// In en, this message translates to:
  /// **'No transactions found for this period.'**
  String get noTransactionsForPeriod;

  /// No description provided for @otherMethod.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get otherMethod;

  /// No description provided for @paymentLabel.
  ///
  /// In en, this message translates to:
  /// **'Payment'**
  String get paymentLabel;

  /// No description provided for @remainingLabel.
  ///
  /// In en, this message translates to:
  /// **'Remaining'**
  String get remainingLabel;

  /// No description provided for @collectionSummaryLabel.
  ///
  /// In en, this message translates to:
  /// **'Collection Summary'**
  String get collectionSummaryLabel;

  /// No description provided for @otherNagadBank.
  ///
  /// In en, this message translates to:
  /// **'Other (Nagad/Bank)'**
  String get otherNagadBank;

  /// No description provided for @totalCollectionLabel.
  ///
  /// In en, this message translates to:
  /// **'Total Collection'**
  String get totalCollectionLabel;

  /// No description provided for @monthlyCollectionTrend.
  ///
  /// In en, this message translates to:
  /// **'Monthly Collection Trend'**
  String get monthlyCollectionTrend;

  /// No description provided for @last6Months.
  ///
  /// In en, this message translates to:
  /// **'Last 6 months'**
  String get last6Months;

  /// No description provided for @noPaymentRecordsPeriod.
  ///
  /// In en, this message translates to:
  /// **'No payment records in this period'**
  String get noPaymentRecordsPeriod;

  /// No description provided for @topDefaultersLabel.
  ///
  /// In en, this message translates to:
  /// **'Top Defaulters'**
  String get topDefaultersLabel;

  /// No description provided for @topDefaultersDesc.
  ///
  /// In en, this message translates to:
  /// **'Customers with the highest outstanding dues'**
  String get topDefaultersDesc;

  /// No description provided for @allClearCelebration.
  ///
  /// In en, this message translates to:
  /// **'🎉 No dues — all customers clear'**
  String get allClearCelebration;

  /// No description provided for @poweredByApp.
  ///
  /// In en, this message translates to:
  /// **'Powered by {app}'**
  String poweredByApp(String app);

  /// No description provided for @notebookDuplicated.
  ///
  /// In en, this message translates to:
  /// **'\"{title}\" duplicated'**
  String notebookDuplicated(String title);

  /// No description provided for @deleteNotebookTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Notebook'**
  String get deleteNotebookTitle;

  /// No description provided for @deleteNotebookConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'\"{title}\" and all its pages will be permanently deleted. Are you sure?'**
  String deleteNotebookConfirmBody(String title);

  /// No description provided for @openAction.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get openAction;

  /// No description provided for @renameEditAction.
  ///
  /// In en, this message translates to:
  /// **'Rename / Edit'**
  String get renameEditAction;

  /// No description provided for @duplicateAction.
  ///
  /// In en, this message translates to:
  /// **'Duplicate'**
  String get duplicateAction;

  /// No description provided for @sortRecentlyUpdated.
  ///
  /// In en, this message translates to:
  /// **'Recently Updated'**
  String get sortRecentlyUpdated;

  /// No description provided for @sortRecentlyCreated.
  ///
  /// In en, this message translates to:
  /// **'Recently Created'**
  String get sortRecentlyCreated;

  /// No description provided for @notebookSortNameAZ.
  ///
  /// In en, this message translates to:
  /// **'Name A-Z'**
  String get notebookSortNameAZ;

  /// No description provided for @notebookSortNameZA.
  ///
  /// In en, this message translates to:
  /// **'Name Z-A'**
  String get notebookSortNameZA;

  /// No description provided for @newNotebook.
  ///
  /// In en, this message translates to:
  /// **'New Notebook'**
  String get newNotebook;

  /// No description provided for @searchNotebooksHint.
  ///
  /// In en, this message translates to:
  /// **'Search notebooks...'**
  String get searchNotebooksHint;

  /// No description provided for @notebookLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load notebooks'**
  String get notebookLoadFailed;

  /// No description provided for @createFirstNotebook.
  ///
  /// In en, this message translates to:
  /// **'Create your first notebook'**
  String get createFirstNotebook;

  /// No description provided for @notebooksDesc.
  ///
  /// In en, this message translates to:
  /// **'Notebooks let you write, organize and format notes freely.'**
  String get notebooksDesc;

  /// No description provided for @newNotebookPlus.
  ///
  /// In en, this message translates to:
  /// **'+ New Notebook'**
  String get newNotebookPlus;

  /// No description provided for @noNotebooksFound.
  ///
  /// In en, this message translates to:
  /// **'No notebooks found'**
  String get noNotebooksFound;

  /// No description provided for @noResultsFor.
  ///
  /// In en, this message translates to:
  /// **'No results for \"{query}\"'**
  String noResultsFor(String query);

  /// No description provided for @newNotebookTitle.
  ///
  /// In en, this message translates to:
  /// **'New Notebook'**
  String get newNotebookTitle;

  /// No description provided for @editNotebookTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Notebook'**
  String get editNotebookTitle;

  /// No description provided for @notebookNameHint.
  ///
  /// In en, this message translates to:
  /// **'Notebook name'**
  String get notebookNameHint;

  /// No description provided for @descriptionOptionalHint.
  ///
  /// In en, this message translates to:
  /// **'Description (optional)'**
  String get descriptionOptionalHint;

  /// No description provided for @coverColorLabel.
  ///
  /// In en, this message translates to:
  /// **'Cover color'**
  String get coverColorLabel;

  /// No description provided for @createAction.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get createAction;

  /// No description provided for @updatedOnLabel.
  ///
  /// In en, this message translates to:
  /// **'Updated {date}'**
  String updatedOnLabel(String date);

  /// No description provided for @saveFailedLocalRetry.
  ///
  /// In en, this message translates to:
  /// **'Save failed, your changes are kept locally — will retry'**
  String get saveFailedLocalRetry;

  /// No description provided for @untitledPage.
  ///
  /// In en, this message translates to:
  /// **'Untitled Page'**
  String get untitledPage;

  /// No description provided for @deletePageTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Page'**
  String get deletePageTitle;

  /// No description provided for @deletePageConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'Delete \"{title}\"?'**
  String deletePageConfirmBody(String title);

  /// No description provided for @renamePageTitle.
  ///
  /// In en, this message translates to:
  /// **'Rename Page'**
  String get renamePageTitle;

  /// No description provided for @chooseFromGallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from Gallery'**
  String get chooseFromGallery;

  /// No description provided for @takeAPhoto.
  ///
  /// In en, this message translates to:
  /// **'Take a Photo'**
  String get takeAPhoto;

  /// No description provided for @uploadingImage.
  ///
  /// In en, this message translates to:
  /// **'Uploading image...'**
  String get uploadingImage;

  /// No description provided for @imageUploadFailed.
  ///
  /// In en, this message translates to:
  /// **'Image upload failed, please try again'**
  String get imageUploadFailed;

  /// No description provided for @notebookFallbackTitle.
  ///
  /// In en, this message translates to:
  /// **'Notebook'**
  String get notebookFallbackTitle;

  /// No description provided for @pagesLabel.
  ///
  /// In en, this message translates to:
  /// **'Pages'**
  String get pagesLabel;

  /// No description provided for @pageLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load page: {error}'**
  String pageLoadFailed(String error);

  /// No description provided for @pageTitleHint.
  ///
  /// In en, this message translates to:
  /// **'Page title'**
  String get pageTitleHint;

  /// No description provided for @startWritingPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Start writing...'**
  String get startWritingPlaceholder;

  /// No description provided for @savedStatus.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get savedStatus;

  /// No description provided for @savingStatus.
  ///
  /// In en, this message translates to:
  /// **'Saving...'**
  String get savingStatus;

  /// No description provided for @unsavedStatus.
  ///
  /// In en, this message translates to:
  /// **'Unsaved changes'**
  String get unsavedStatus;

  /// No description provided for @notebookEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'This notebook is empty'**
  String get notebookEmptyTitle;

  /// No description provided for @createFirstPageDesc.
  ///
  /// In en, this message translates to:
  /// **'Create your first page to start writing.'**
  String get createFirstPageDesc;

  /// No description provided for @newPagePlus.
  ///
  /// In en, this message translates to:
  /// **'+ New Page'**
  String get newPagePlus;

  /// No description provided for @newPageTooltip.
  ///
  /// In en, this message translates to:
  /// **'New Page'**
  String get newPageTooltip;

  /// No description provided for @noPagesYet.
  ///
  /// In en, this message translates to:
  /// **'No pages yet'**
  String get noPagesYet;

  /// No description provided for @renameAction.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get renameAction;

  /// No description provided for @restoreCustomerTitle.
  ///
  /// In en, this message translates to:
  /// **'Restore Customer'**
  String get restoreCustomerTitle;

  /// No description provided for @restoreConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'Do you want to restore \'{name}\' to the active list?'**
  String restoreConfirmBody(String name);

  /// No description provided for @restoreAction.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get restoreAction;

  /// No description provided for @customerRestoredSuccess.
  ///
  /// In en, this message translates to:
  /// **'{name} restored successfully'**
  String customerRestoredSuccess(String name);

  /// No description provided for @restoreFailed.
  ///
  /// In en, this message translates to:
  /// **'Restore failed, please try again'**
  String get restoreFailed;

  /// No description provided for @deletePermanentlyTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Permanently'**
  String get deletePermanentlyTitle;

  /// No description provided for @deletePermanentlyConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'Permanently delete \'{name}\'? All payment history and reminder data will be completely erased. This cannot be undone.'**
  String deletePermanentlyConfirmBody(String name);

  /// No description provided for @areYouAbsolutelySure.
  ///
  /// In en, this message translates to:
  /// **'Are you absolutely sure?'**
  String get areYouAbsolutelySure;

  /// No description provided for @undoWarningBody.
  ///
  /// In en, this message translates to:
  /// **'This action cannot be undone. Do you really want to delete it permanently?'**
  String get undoWarningBody;

  /// No description provided for @yesDeleteForever.
  ///
  /// In en, this message translates to:
  /// **'Yes, Delete Forever'**
  String get yesDeleteForever;

  /// No description provided for @customerPermanentlyDeleted.
  ///
  /// In en, this message translates to:
  /// **'{name} permanently deleted'**
  String customerPermanentlyDeleted(String name);

  /// No description provided for @deleteFailedGeneric.
  ///
  /// In en, this message translates to:
  /// **'Delete failed, please try again'**
  String get deleteFailedGeneric;

  /// No description provided for @noArchivedCustomers.
  ///
  /// In en, this message translates to:
  /// **'No archived customers'**
  String get noArchivedCustomers;

  /// No description provided for @globalSearchTitle.
  ///
  /// In en, this message translates to:
  /// **'Global Search'**
  String get globalSearchTitle;

  /// No description provided for @globalSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search customers, payments or notebooks...'**
  String get globalSearchHint;

  /// No description provided for @dataLoadFailedShort.
  ///
  /// In en, this message translates to:
  /// **'Could not load data'**
  String get dataLoadFailedShort;

  /// No description provided for @tryAgainMessage.
  ///
  /// In en, this message translates to:
  /// **'Please try again'**
  String get tryAgainMessage;

  /// No description provided for @retryAction.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retryAction;

  /// No description provided for @startTypingToSearch.
  ///
  /// In en, this message translates to:
  /// **'Start typing to search'**
  String get startTypingToSearch;

  /// No description provided for @searchEverythingDesc.
  ///
  /// In en, this message translates to:
  /// **'Customers, payment history and notebooks — everything is searched together'**
  String get searchEverythingDesc;

  /// No description provided for @noResultsFound.
  ///
  /// In en, this message translates to:
  /// **'No results found'**
  String get noResultsFound;

  /// No description provided for @noMatchesFor.
  ///
  /// In en, this message translates to:
  /// **'Nothing matches \"{query}\"'**
  String noMatchesFor(String query);

  /// No description provided for @customersSectionLabel.
  ///
  /// In en, this message translates to:
  /// **'Customers'**
  String get customersSectionLabel;

  /// No description provided for @pageTitleMatched.
  ///
  /// In en, this message translates to:
  /// **'Page title matched'**
  String get pageTitleMatched;

  /// No description provided for @notebookMatched.
  ///
  /// In en, this message translates to:
  /// **'Notebook matched'**
  String get notebookMatched;

  /// No description provided for @reminderHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Reminder History'**
  String get reminderHistoryTitle;

  /// No description provided for @noReminderHistory.
  ///
  /// In en, this message translates to:
  /// **'No reminder history'**
  String get noReminderHistory;

  /// No description provided for @statusUpcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get statusUpcoming;

  /// No description provided for @statusDueToday.
  ///
  /// In en, this message translates to:
  /// **'Due Today'**
  String get statusDueToday;

  /// No description provided for @statusOverdue.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get statusOverdue;

  /// No description provided for @statusReplaced.
  ///
  /// In en, this message translates to:
  /// **'Replaced'**
  String get statusReplaced;

  /// No description provided for @statusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get statusCancelled;

  /// No description provided for @recurringLabel.
  ///
  /// In en, this message translates to:
  /// **'Recurring · {label}'**
  String recurringLabel(String label);

  /// No description provided for @reminderSetOnLabel.
  ///
  /// In en, this message translates to:
  /// **'Set on {date}'**
  String reminderSetOnLabel(String date);

  /// No description provided for @reminderNextOnLabel.
  ///
  /// In en, this message translates to:
  /// **'Next reminder: {date}'**
  String reminderNextOnLabel(String date);

  /// No description provided for @reminderOverdueHint.
  ///
  /// In en, this message translates to:
  /// **'This reminder date has passed'**
  String get reminderOverdueHint;

  /// No description provided for @reminderOverdueRecurringHint.
  ///
  /// In en, this message translates to:
  /// **'Overdue — tap ✓ to move to the next cycle'**
  String get reminderOverdueRecurringHint;

  /// No description provided for @totalRemindersLabel.
  ///
  /// In en, this message translates to:
  /// **'Total Reminders'**
  String get totalRemindersLabel;

  /// No description provided for @daysSinceFirstReminderLabel.
  ///
  /// In en, this message translates to:
  /// **'Days Since First'**
  String get daysSinceFirstReminderLabel;

  /// No description provided for @loginTagline.
  ///
  /// In en, this message translates to:
  /// **'Your accounts, in your control'**
  String get loginTagline;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome Back'**
  String get welcomeBack;

  /// No description provided for @loginToContinue.
  ///
  /// In en, this message translates to:
  /// **'Login to continue'**
  String get loginToContinue;

  /// No description provided for @phoneHintExample.
  ///
  /// In en, this message translates to:
  /// **'01XXXXXXXXX'**
  String get phoneHintExample;

  /// No description provided for @enterPhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter phone number'**
  String get enterPhoneNumber;

  /// No description provided for @passwordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordLabel;

  /// No description provided for @enterPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter password'**
  String get enterPassword;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPassword;

  /// No description provided for @loginAction.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get loginAction;

  /// No description provided for @newAccountQuestion.
  ///
  /// In en, this message translates to:
  /// **'New account? '**
  String get newAccountQuestion;

  /// No description provided for @registerNow.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get registerNow;

  /// No description provided for @createAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get createAccountTitle;

  /// No description provided for @joinUsDesc.
  ///
  /// In en, this message translates to:
  /// **'Join us and manage your transactions smartly'**
  String get joinUsDesc;

  /// No description provided for @enterYourName.
  ///
  /// In en, this message translates to:
  /// **'Enter your name'**
  String get enterYourName;

  /// No description provided for @enterValid11DigitPhone.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid 11-digit phone number'**
  String get enterValid11DigitPhone;

  /// No description provided for @minSixCharacters.
  ///
  /// In en, this message translates to:
  /// **'Enter at least 6 characters'**
  String get minSixCharacters;

  /// No description provided for @confirmPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPasswordLabel;

  /// No description provided for @passwordsDontMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsDontMatch;

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get getStarted;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? '**
  String get alreadyHaveAccount;

  /// No description provided for @loginNow.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get loginNow;

  /// No description provided for @otpVerificationTitle.
  ///
  /// In en, this message translates to:
  /// **'Verify Phone Number'**
  String get otpVerificationTitle;

  /// No description provided for @otpSentTo.
  ///
  /// In en, this message translates to:
  /// **'We sent a 6-digit code to {phone}'**
  String otpSentTo(String phone);

  /// No description provided for @otpCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'OTP Code'**
  String get otpCodeLabel;

  /// No description provided for @otpCodeHint.
  ///
  /// In en, this message translates to:
  /// **'6-digit code'**
  String get otpCodeHint;

  /// No description provided for @enterOtpCode.
  ///
  /// In en, this message translates to:
  /// **'Enter the OTP code'**
  String get enterOtpCode;

  /// No description provided for @enterValid6DigitOtp.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid 6-digit code'**
  String get enterValid6DigitOtp;

  /// No description provided for @verifyAndCreateAccount.
  ///
  /// In en, this message translates to:
  /// **'Verify & Create Account'**
  String get verifyAndCreateAccount;

  /// No description provided for @sendingOtp.
  ///
  /// In en, this message translates to:
  /// **'Sending OTP...'**
  String get sendingOtp;

  /// No description provided for @autoVerifyingOtp.
  ///
  /// In en, this message translates to:
  /// **'Auto-verifying...'**
  String get autoVerifyingOtp;

  /// No description provided for @resendCode.
  ///
  /// In en, this message translates to:
  /// **'Resend Code'**
  String get resendCode;

  /// No description provided for @resendCodeIn.
  ///
  /// In en, this message translates to:
  /// **'Resend code in {seconds}s'**
  String resendCodeIn(int seconds);

  /// No description provided for @didntReceiveCode.
  ///
  /// In en, this message translates to:
  /// **'Didn\'t receive the code? '**
  String get didntReceiveCode;

  /// No description provided for @changePhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Change phone number'**
  String get changePhoneNumber;

  /// No description provided for @otpResentSuccess.
  ///
  /// In en, this message translates to:
  /// **'New OTP sent'**
  String get otpResentSuccess;

  /// No description provided for @forgotPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset Password'**
  String get forgotPasswordTitle;

  /// No description provided for @resetPasswordDesc.
  ///
  /// In en, this message translates to:
  /// **'Verify your phone number to set a new password'**
  String get resetPasswordDesc;

  /// No description provided for @newPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'New Password'**
  String get newPasswordLabel;

  /// No description provided for @confirmNewPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirm New Password'**
  String get confirmNewPasswordLabel;

  /// No description provided for @verifyAndResetPassword.
  ///
  /// In en, this message translates to:
  /// **'Verify & Reset Password'**
  String get verifyAndResetPassword;

  /// No description provided for @unlockToVerify.
  ///
  /// In en, this message translates to:
  /// **'Verify to unlock the app'**
  String get unlockToVerify;

  /// No description provided for @tooManyFailedPinAttempts.
  ///
  /// In en, this message translates to:
  /// **'Too many wrong PIN attempts, please try again later'**
  String get tooManyFailedPinAttempts;

  /// No description provided for @wrongPinTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Wrong PIN, please try again'**
  String get wrongPinTryAgain;

  /// No description provided for @pinMismatchTryAgain.
  ///
  /// In en, this message translates to:
  /// **'PIN doesn\'t match, please try again'**
  String get pinMismatchTryAgain;

  /// No description provided for @lockoutSeconds.
  ///
  /// In en, this message translates to:
  /// **'{n} seconds'**
  String lockoutSeconds(int n);

  /// No description provided for @lockoutMinutes.
  ///
  /// In en, this message translates to:
  /// **'{n} minutes'**
  String lockoutMinutes(int n);

  /// No description provided for @lockoutMinutesSeconds.
  ///
  /// In en, this message translates to:
  /// **'{n} minutes {s} seconds'**
  String lockoutMinutesSeconds(int n, int s);

  /// No description provided for @setNewPinTitle.
  ///
  /// In en, this message translates to:
  /// **'Set a new PIN'**
  String get setNewPinTitle;

  /// No description provided for @reEnterPinTitle.
  ///
  /// In en, this message translates to:
  /// **'Re-enter PIN'**
  String get reEnterPinTitle;

  /// No description provided for @unlockWithPinTitle.
  ///
  /// In en, this message translates to:
  /// **'Unlock with PIN'**
  String get unlockWithPinTitle;

  /// No description provided for @tooManyAttemptsCountdown.
  ///
  /// In en, this message translates to:
  /// **'Too many wrong attempts — try again after {remaining}'**
  String tooManyAttemptsCountdown(String remaining);

  /// No description provided for @tryFingerprint.
  ///
  /// In en, this message translates to:
  /// **'Try with Fingerprint'**
  String get tryFingerprint;

  /// No description provided for @frequentlyAskedQuestions.
  ///
  /// In en, this message translates to:
  /// **'Frequently Asked Questions'**
  String get frequentlyAskedQuestions;

  /// No description provided for @faq1Q.
  ///
  /// In en, this message translates to:
  /// **'How do SMS reminders work?'**
  String get faq1Q;

  /// No description provided for @faq1A.
  ///
  /// In en, this message translates to:
  /// **'Reminder SMS are sent from your phone\'s own SIM. The app opens the SMS app separately for each customer with the message prefilled — you have to press Send yourself. This is because Play Store policy doesn\'t allow the app to send bulk SMS on its own.'**
  String get faq1A;

  /// No description provided for @faq2Q.
  ///
  /// In en, this message translates to:
  /// **'Is my data safe?'**
  String get faq2Q;

  /// No description provided for @faq2A.
  ///
  /// In en, this message translates to:
  /// **'Yes. All data is stored in Firebase (Google Cloud). The PIN used for App Lock is kept on your phone as a salted hash, never stored in plain text.'**
  String get faq2A;

  /// No description provided for @faq3Q.
  ///
  /// In en, this message translates to:
  /// **'How do I back up my data?'**
  String get faq3Q;

  /// No description provided for @faq3A.
  ///
  /// In en, this message translates to:
  /// **'Go to Settings → Data Backup to export your customer and payment data as a CSV file.'**
  String get faq3A;

  /// No description provided for @faq4Q.
  ///
  /// In en, this message translates to:
  /// **'How do I turn on App Lock?'**
  String get faq4Q;

  /// No description provided for @faq4A.
  ///
  /// In en, this message translates to:
  /// **'Go to Settings → App Lock and set a PIN. After that, whenever the app goes to background or is reopened, you\'ll need to unlock it with your PIN or biometrics.'**
  String get faq4A;

  /// No description provided for @faq5Q.
  ///
  /// In en, this message translates to:
  /// **'What happens when I archive a customer?'**
  String get faq5Q;

  /// No description provided for @faq5A.
  ///
  /// In en, this message translates to:
  /// **'An archived customer is removed from the active list but the data isn\'t deleted. You can restore it anytime from \"Archived Customers\" in the drawer, or permanently delete it if you want.'**
  String get faq5A;

  /// No description provided for @faq6Q.
  ///
  /// In en, this message translates to:
  /// **'How do I change the currency or theme color?'**
  String get faq6Q;

  /// No description provided for @faq6A.
  ///
  /// In en, this message translates to:
  /// **'You can change the currency symbol from Settings → Currency, and the app\'s color from Settings → Theme Color. Dark/Light mode can also be switched from Settings → App Mode (or the quick toggle in the Drawer).'**
  String get faq6A;

  /// No description provided for @faq7Q.
  ///
  /// In en, this message translates to:
  /// **'What is the Notebook feature for?'**
  String get faq7Q;

  /// No description provided for @faq7A.
  ///
  /// In en, this message translates to:
  /// **'The Notebook feature is for writing notes or things you want to remember, separate from your accounting — it\'s completely independent from customer data.'**
  String get faq7A;

  /// No description provided for @needMoreHelp.
  ///
  /// In en, this message translates to:
  /// **'Need more help?'**
  String get needMoreHelp;

  /// No description provided for @contactDirectly.
  ///
  /// In en, this message translates to:
  /// **'Contact us directly: {email}'**
  String contactDirectly(String email);

  /// No description provided for @privacyPolicyTitle.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicyTitle;

  /// No description provided for @termsOfServiceTitle.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get termsOfServiceTitle;

  /// No description provided for @lastUpdatedLabel.
  ///
  /// In en, this message translates to:
  /// **'Last updated: {date}'**
  String lastUpdatedLabel(String date);

  /// No description provided for @contactForQuestions.
  ///
  /// In en, this message translates to:
  /// **'Contact for questions: {email}'**
  String contactForQuestions(String email);

  /// No description provided for @receiptGenerationFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not generate receipt, please try again'**
  String get receiptGenerationFailed;

  /// No description provided for @paymentTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Payment'**
  String get paymentTypeLabel;

  /// No description provided for @chargeAddedLabel.
  ///
  /// In en, this message translates to:
  /// **'Charge Added'**
  String get chargeAddedLabel;

  /// No description provided for @amountColonLabel.
  ///
  /// In en, this message translates to:
  /// **'Amount: {amount}'**
  String amountColonLabel(String amount);

  /// No description provided for @discountColonLabel.
  ///
  /// In en, this message translates to:
  /// **'Discount: {amount}'**
  String discountColonLabel(String amount);

  /// No description provided for @dateColonLabel.
  ///
  /// In en, this message translates to:
  /// **'Date: {date}'**
  String dateColonLabel(String date);

  /// No description provided for @methodColonLabel.
  ///
  /// In en, this message translates to:
  /// **'Method: {method}'**
  String methodColonLabel(String method);

  /// No description provided for @descriptionColonLabel.
  ///
  /// In en, this message translates to:
  /// **'Description:'**
  String get descriptionColonLabel;

  /// No description provided for @generatingLabel.
  ///
  /// In en, this message translates to:
  /// **'Generating...'**
  String get generatingLabel;

  /// No description provided for @shareReceiptAction.
  ///
  /// In en, this message translates to:
  /// **'Share Receipt'**
  String get shareReceiptAction;

  /// No description provided for @imageLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load image'**
  String get imageLoadFailed;

  /// No description provided for @discountAppliedLabel.
  ///
  /// In en, this message translates to:
  /// **'-{amount} discount'**
  String discountAppliedLabel(String amount);

  /// No description provided for @accountDisabledTitle.
  ///
  /// In en, this message translates to:
  /// **'Account Disabled'**
  String get accountDisabledTitle;

  /// No description provided for @accountDisabledMessage.
  ///
  /// In en, this message translates to:
  /// **'Your account has been disabled by the administrator. Please contact support if you believe this is a mistake.'**
  String get accountDisabledMessage;

  /// No description provided for @notificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsTitle;

  /// No description provided for @noNotifications.
  ///
  /// In en, this message translates to:
  /// **'No notifications yet'**
  String get noNotifications;

  /// No description provided for @statusInactive.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get statusInactive;

  /// No description provided for @noticeDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Notice'**
  String get noticeDetailTitle;

  /// No description provided for @scheduleLabel.
  ///
  /// In en, this message translates to:
  /// **'Schedule'**
  String get scheduleLabel;

  /// No description provided for @noScheduleWindow.
  ///
  /// In en, this message translates to:
  /// **'No schedule window — always shown while active'**
  String get noScheduleWindow;

  /// No description provided for @maintenanceTitle.
  ///
  /// In en, this message translates to:
  /// **'Under Maintenance'**
  String get maintenanceTitle;

  /// No description provided for @maintenanceDefaultMessage.
  ///
  /// In en, this message translates to:
  /// **'We\'re doing some scheduled maintenance. Please check back soon.'**
  String get maintenanceDefaultMessage;

  /// No description provided for @maintenanceEtaLabel.
  ///
  /// In en, this message translates to:
  /// **'Expected back around {date}'**
  String maintenanceEtaLabel(String date);

  /// No description provided for @forceUpdateTitle.
  ///
  /// In en, this message translates to:
  /// **'Update Required'**
  String get forceUpdateTitle;

  /// No description provided for @forceUpdateMessage.
  ///
  /// In en, this message translates to:
  /// **'A new version of the app is required to continue. Please update to version {version} or later.'**
  String forceUpdateMessage(String version);

  /// No description provided for @updateNowButton.
  ///
  /// In en, this message translates to:
  /// **'Update Now'**
  String get updateNowButton;

  /// No description provided for @groupAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get groupAbout;

  /// No description provided for @aboutAppTitle.
  ///
  /// In en, this message translates to:
  /// **'About App'**
  String get aboutAppTitle;

  /// No description provided for @appVersionLabel.
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String appVersionLabel(String version);

  /// No description provided for @contactTitle.
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get contactTitle;

  /// No description provided for @contactSupportEmail.
  ///
  /// In en, this message translates to:
  /// **'Support email'**
  String get contactSupportEmail;

  /// No description provided for @contactSupportPhone.
  ///
  /// In en, this message translates to:
  /// **'Support phone'**
  String get contactSupportPhone;

  /// No description provided for @contactWhatsapp.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp'**
  String get contactWhatsapp;

  /// No description provided for @contactFacebook.
  ///
  /// In en, this message translates to:
  /// **'Facebook page'**
  String get contactFacebook;

  /// No description provided for @contactWebsite.
  ///
  /// In en, this message translates to:
  /// **'Website'**
  String get contactWebsite;

  /// No description provided for @noContactInfo.
  ///
  /// In en, this message translates to:
  /// **'No contact info added yet'**
  String get noContactInfo;

  /// No description provided for @faqTitle.
  ///
  /// In en, this message translates to:
  /// **'FAQ'**
  String get faqTitle;

  /// No description provided for @noFaqItems.
  ///
  /// In en, this message translates to:
  /// **'No FAQ items yet'**
  String get noFaqItems;

  /// No description provided for @copyLabel.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copyLabel;

  /// No description provided for @copiedToClipboard.
  ///
  /// In en, this message translates to:
  /// **'Copied to clipboard'**
  String get copiedToClipboard;

  /// No description provided for @agreementPrefix.
  ///
  /// In en, this message translates to:
  /// **'I agree to the '**
  String get agreementPrefix;

  /// No description provided for @agreementConnector.
  ///
  /// In en, this message translates to:
  /// **' and '**
  String get agreementConnector;

  /// No description provided for @agreementSuffix.
  ///
  /// In en, this message translates to:
  /// **'.'**
  String get agreementSuffix;

  /// No description provided for @agreeToTermsRequired.
  ///
  /// In en, this message translates to:
  /// **'Please agree to the Privacy Policy and Terms of Service to continue'**
  String get agreeToTermsRequired;

  /// No description provided for @policyUpdatedTitle.
  ///
  /// In en, this message translates to:
  /// **'Our Policies Have Been Updated'**
  String get policyUpdatedTitle;

  /// No description provided for @policyUpdatedMessage.
  ///
  /// In en, this message translates to:
  /// **'We\'ve updated our Privacy Policy and/or Terms of Service. Please review them and accept to continue using the app.'**
  String get policyUpdatedMessage;

  /// No description provided for @reviewPrivacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Review Privacy Policy'**
  String get reviewPrivacyPolicy;

  /// No description provided for @reviewTermsOfService.
  ///
  /// In en, this message translates to:
  /// **'Review Terms of Service'**
  String get reviewTermsOfService;

  /// No description provided for @iHaveReviewedAgreement.
  ///
  /// In en, this message translates to:
  /// **'I have read and accept the updated Privacy Policy and Terms of Service'**
  String get iHaveReviewedAgreement;

  /// No description provided for @acceptAndContinue.
  ///
  /// In en, this message translates to:
  /// **'Accept & Continue'**
  String get acceptAndContinue;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['bn', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'bn':
      return AppLocalizationsBn();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
