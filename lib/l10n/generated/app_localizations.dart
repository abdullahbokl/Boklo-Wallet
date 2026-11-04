import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
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
/// import 'generated/app_localizations.dart';
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

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
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
    Locale('ar'),
    Locale('en'),
  ];

  /// No description provided for @signInToBoklo.
  ///
  /// In en, this message translates to:
  /// **'Sign in to Boklo'**
  String get signInToBoklo;

  /// No description provided for @signInSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Secure access to your wallet, transfers, and requests.'**
  String get signInSubtitle;

  /// No description provided for @newToBoklo.
  ///
  /// In en, this message translates to:
  /// **'New to Boklo?'**
  String get newToBoklo;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get createAccount;

  /// No description provided for @pleaseCompleteProfile.
  ///
  /// In en, this message translates to:
  /// **'Please complete your profile setup.'**
  String get pleaseCompleteProfile;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back, {name}.'**
  String welcomeBack(String name);

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signIn;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPassword;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsDoNotMatch;

  /// No description provided for @createYourBokloAccount.
  ///
  /// In en, this message translates to:
  /// **'Create your Boklo account'**
  String get createYourBokloAccount;

  /// No description provided for @createAccountAction.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get createAccountAction;

  /// No description provided for @signInLink.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signInLink;

  /// No description provided for @setUpYourProfile.
  ///
  /// In en, this message translates to:
  /// **'Set up your profile'**
  String get setUpYourProfile;

  /// No description provided for @completeSetup.
  ///
  /// In en, this message translates to:
  /// **'Complete Setup'**
  String get completeSetup;

  /// No description provided for @username.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get username;

  /// No description provided for @usernameHint.
  ///
  /// In en, this message translates to:
  /// **'john_doe'**
  String get usernameHint;

  /// No description provided for @displayNameOptional.
  ///
  /// In en, this message translates to:
  /// **'Display Name (Optional)'**
  String get displayNameOptional;

  /// No description provided for @displayNameHint.
  ///
  /// In en, this message translates to:
  /// **'John Doe'**
  String get displayNameHint;

  /// No description provided for @availableBalance.
  ///
  /// In en, this message translates to:
  /// **'Available balance'**
  String get availableBalance;

  /// No description provided for @fundsReadyToSendOrRequest.
  ///
  /// In en, this message translates to:
  /// **'Funds ready to send or request'**
  String get fundsReadyToSendOrRequest;

  /// No description provided for @recentActivity.
  ///
  /// In en, this message translates to:
  /// **'Recent activity'**
  String get recentActivity;

  /// No description provided for @recentActivitySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Track completed and pending money movement.'**
  String get recentActivitySubtitle;

  /// No description provided for @clearFilters.
  ///
  /// In en, this message translates to:
  /// **'Clear filters'**
  String get clearFilters;

  /// No description provided for @noTransactionsYet.
  ///
  /// In en, this message translates to:
  /// **'No transactions yet'**
  String get noTransactionsYet;

  /// No description provided for @noTransactionsYetSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your income and expenses will appear here.'**
  String get noTransactionsYetSubtitle;

  /// No description provided for @loadMore.
  ///
  /// In en, this message translates to:
  /// **'Load More'**
  String get loadMore;

  /// No description provided for @filterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filterAll;

  /// No description provided for @filterIncome.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get filterIncome;

  /// No description provided for @filterExpense.
  ///
  /// In en, this message translates to:
  /// **'Expense'**
  String get filterExpense;

  /// No description provided for @quickActionSend.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get quickActionSend;

  /// No description provided for @quickActionRequest.
  ///
  /// In en, this message translates to:
  /// **'Request'**
  String get quickActionRequest;

  /// No description provided for @quickActionContacts.
  ///
  /// In en, this message translates to:
  /// **'Contacts'**
  String get quickActionContacts;

  /// No description provided for @quickActionAlerts.
  ///
  /// In en, this message translates to:
  /// **'Alerts'**
  String get quickActionAlerts;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navSend.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get navSend;

  /// No description provided for @navRequests.
  ///
  /// In en, this message translates to:
  /// **'Requests'**
  String get navRequests;

  /// No description provided for @navContacts.
  ///
  /// In en, this message translates to:
  /// **'Contacts'**
  String get navContacts;

  /// No description provided for @navProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @sendMoney.
  ///
  /// In en, this message translates to:
  /// **'Send money'**
  String get sendMoney;

  /// No description provided for @transferDetails.
  ///
  /// In en, this message translates to:
  /// **'Transfer details'**
  String get transferDetails;

  /// No description provided for @reviewTransfer.
  ///
  /// In en, this message translates to:
  /// **'Review transfer'**
  String get reviewTransfer;

  /// No description provided for @transferSuccessful.
  ///
  /// In en, this message translates to:
  /// **'Transfer successful'**
  String get transferSuccessful;

  /// No description provided for @recipient.
  ///
  /// In en, this message translates to:
  /// **'Recipient'**
  String get recipient;

  /// No description provided for @recipientHint.
  ///
  /// In en, this message translates to:
  /// **'Wallet ID, Alias, or Email'**
  String get recipientHint;

  /// No description provided for @amount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amount;

  /// No description provided for @amountHint.
  ///
  /// In en, this message translates to:
  /// **'0.00'**
  String get amountHint;

  /// No description provided for @confirmAndSend.
  ///
  /// In en, this message translates to:
  /// **'Confirm & Send'**
  String get confirmAndSend;

  /// No description provided for @invalidAmount.
  ///
  /// In en, this message translates to:
  /// **'Invalid amount'**
  String get invalidAmount;

  /// No description provided for @insufficientBalance.
  ///
  /// In en, this message translates to:
  /// **'Insufficient balance'**
  String get insufficientBalance;

  /// No description provided for @paymentRequests.
  ///
  /// In en, this message translates to:
  /// **'Payment requests'**
  String get paymentRequests;

  /// No description provided for @createPaymentRequest.
  ///
  /// In en, this message translates to:
  /// **'Create payment request'**
  String get createPaymentRequest;

  /// No description provided for @newRequest.
  ///
  /// In en, this message translates to:
  /// **'New request'**
  String get newRequest;

  /// No description provided for @incoming.
  ///
  /// In en, this message translates to:
  /// **'Incoming'**
  String get incoming;

  /// No description provided for @outgoing.
  ///
  /// In en, this message translates to:
  /// **'Outgoing'**
  String get outgoing;

  /// No description provided for @noIncomingRequests.
  ///
  /// In en, this message translates to:
  /// **'No incoming requests'**
  String get noIncomingRequests;

  /// No description provided for @noOutgoingRequests.
  ///
  /// In en, this message translates to:
  /// **'No outgoing requests'**
  String get noOutgoingRequests;

  /// No description provided for @sendRequest.
  ///
  /// In en, this message translates to:
  /// **'Send Request'**
  String get sendRequest;

  /// No description provided for @requestSent.
  ///
  /// In en, this message translates to:
  /// **'Request Sent'**
  String get requestSent;

  /// No description provided for @noteOptional.
  ///
  /// In en, this message translates to:
  /// **'Note (Optional)'**
  String get noteOptional;

  /// No description provided for @noteHint.
  ///
  /// In en, this message translates to:
  /// **'What is this for?'**
  String get noteHint;

  /// No description provided for @accept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get accept;

  /// No description provided for @decline.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get decline;

  /// No description provided for @contacts.
  ///
  /// In en, this message translates to:
  /// **'Contacts'**
  String get contacts;

  /// No description provided for @yourNetwork.
  ///
  /// In en, this message translates to:
  /// **'Your network'**
  String get yourNetwork;

  /// No description provided for @noContactsYet.
  ///
  /// In en, this message translates to:
  /// **'No contacts yet'**
  String get noContactsYet;

  /// No description provided for @noContactsYetSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add trusted contacts to send or request money faster.'**
  String get noContactsYetSubtitle;

  /// No description provided for @addContact.
  ///
  /// In en, this message translates to:
  /// **'Add Contact'**
  String get addContact;

  /// No description provided for @emailOrUsername.
  ///
  /// In en, this message translates to:
  /// **'Email or Username'**
  String get emailOrUsername;

  /// No description provided for @emailOrUsernameHint.
  ///
  /// In en, this message translates to:
  /// **'user@example.com or @username'**
  String get emailOrUsernameHint;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @noNotificationsYet.
  ///
  /// In en, this message translates to:
  /// **'No notifications yet'**
  String get noNotificationsYet;

  /// No description provided for @notificationSettings.
  ///
  /// In en, this message translates to:
  /// **'Notification settings'**
  String get notificationSettings;

  /// No description provided for @transferAlerts.
  ///
  /// In en, this message translates to:
  /// **'Transfer alerts'**
  String get transferAlerts;

  /// No description provided for @incomingTransfers.
  ///
  /// In en, this message translates to:
  /// **'Incoming transfers'**
  String get incomingTransfers;

  /// No description provided for @incomingTransfersSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Notify me when money arrives'**
  String get incomingTransfersSubtitle;

  /// No description provided for @outgoingTransfers.
  ///
  /// In en, this message translates to:
  /// **'Outgoing transfers'**
  String get outgoingTransfers;

  /// No description provided for @outgoingTransfersSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Notify me when money is sent'**
  String get outgoingTransfersSubtitle;

  /// No description provided for @deleteNotification.
  ///
  /// In en, this message translates to:
  /// **'Delete notification'**
  String get deleteNotification;

  /// No description provided for @deleteNotificationBody.
  ///
  /// In en, this message translates to:
  /// **'This notification will be permanently removed.'**
  String get deleteNotificationBody;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @pleaseSignInToViewProfile.
  ///
  /// In en, this message translates to:
  /// **'Please sign in to view profile.'**
  String get pleaseSignInToViewProfile;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// No description provided for @deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get deleteAccount;

  /// No description provided for @deleteAccountBody.
  ///
  /// In en, this message translates to:
  /// **'This permanently removes your profile data. You can only delete the account when your balance is zero and there is no transfer or payment request history.'**
  String get deleteAccountBody;

  /// No description provided for @personalInformation.
  ///
  /// In en, this message translates to:
  /// **'Personal information'**
  String get personalInformation;

  /// No description provided for @personalInformationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Review the details linked to your Boklo account.'**
  String get personalInformationSubtitle;

  /// No description provided for @notificationsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose which alerts Boklo should send you.'**
  String get notificationsSubtitle;

  /// No description provided for @security.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get security;

  /// No description provided for @securitySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Security tools and protections for your wallet.'**
  String get securitySubtitle;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @copiedToClipboard.
  ///
  /// In en, this message translates to:
  /// **'Copied to clipboard'**
  String get copiedToClipboard;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @required.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get required;

  /// No description provided for @enterValidEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email'**
  String get enterValidEmail;

  /// No description provided for @statusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get statusPending;

  /// No description provided for @statusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get statusCompleted;

  /// No description provided for @statusFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get statusFailed;

  /// No description provided for @errorPrefix.
  ///
  /// In en, this message translates to:
  /// **'Error: {message}'**
  String errorPrefix(String message);

  /// No description provided for @ledger.
  ///
  /// In en, this message translates to:
  /// **'Ledger'**
  String get ledger;

  /// No description provided for @noEntriesYet.
  ///
  /// In en, this message translates to:
  /// **'No entries yet'**
  String get noEntriesYet;

  /// No description provided for @transferAlertsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Decide which money movement events should notify you.'**
  String get transferAlertsSubtitle;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotPassword;

  /// No description provided for @forgotPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset your password'**
  String get forgotPasswordTitle;

  /// No description provided for @forgotPasswordSend.
  ///
  /// In en, this message translates to:
  /// **'Send reset link'**
  String get forgotPasswordSend;

  /// No description provided for @passwordResetSent.
  ///
  /// In en, this message translates to:
  /// **'If the account exists, a reset link has been sent.'**
  String get passwordResetSent;

  /// No description provided for @verifyEmailTitle.
  ///
  /// In en, this message translates to:
  /// **'Verify your email'**
  String get verifyEmailTitle;

  /// No description provided for @verifyEmailBody.
  ///
  /// In en, this message translates to:
  /// **'We sent a verification link to your email address. Verify to secure your account.'**
  String get verifyEmailBody;

  /// No description provided for @verifyEmailResend.
  ///
  /// In en, this message translates to:
  /// **'Resend email'**
  String get verifyEmailResend;

  /// No description provided for @verifyEmailRefresh.
  ///
  /// In en, this message translates to:
  /// **'I\'ve verified'**
  String get verifyEmailRefresh;

  /// No description provided for @emailVerifiedBannerDismiss.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get emailVerifiedBannerDismiss;

  /// No description provided for @signedOutSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Signed out successfully.'**
  String get signedOutSuccessfully;

  /// No description provided for @transactionDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Transaction details'**
  String get transactionDetailTitle;

  /// No description provided for @detailDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get detailDate;

  /// No description provided for @detailFrom.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get detailFrom;

  /// No description provided for @detailTo.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get detailTo;

  /// No description provided for @detailDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get detailDescription;

  /// No description provided for @detailTransactionId.
  ///
  /// In en, this message translates to:
  /// **'Transaction ID'**
  String get detailTransactionId;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgain;

  /// No description provided for @reportProblem.
  ///
  /// In en, this message translates to:
  /// **'Report a problem'**
  String get reportProblem;

  /// No description provided for @reportProblemHint.
  ///
  /// In en, this message translates to:
  /// **'Tell us what happened'**
  String get reportProblemHint;

  /// No description provided for @reportProblemSubmit.
  ///
  /// In en, this message translates to:
  /// **'Submit report'**
  String get reportProblemSubmit;

  /// No description provided for @reportProblemSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Report submitted. Our team will review it.'**
  String get reportProblemSubmitted;

  /// No description provided for @receivedMoney.
  ///
  /// In en, this message translates to:
  /// **'Received Money'**
  String get receivedMoney;

  /// No description provided for @sentMoney.
  ///
  /// In en, this message translates to:
  /// **'Sent Money'**
  String get sentMoney;

  /// No description provided for @searchTransactions.
  ///
  /// In en, this message translates to:
  /// **'Search transactions'**
  String get searchTransactions;

  /// No description provided for @dateRange.
  ///
  /// In en, this message translates to:
  /// **'Date range'**
  String get dateRange;

  /// No description provided for @clearDates.
  ///
  /// In en, this message translates to:
  /// **'Clear dates'**
  String get clearDates;

  /// No description provided for @receiptTitle.
  ///
  /// In en, this message translates to:
  /// **'Receipt'**
  String get receiptTitle;

  /// No description provided for @receiptRecipient.
  ///
  /// In en, this message translates to:
  /// **'Recipient'**
  String get receiptRecipient;

  /// No description provided for @receiptShare.
  ///
  /// In en, this message translates to:
  /// **'Share receipt'**
  String get receiptShare;

  /// No description provided for @receiptShareText.
  ///
  /// In en, this message translates to:
  /// **'Payment of {amount} on {date} confirmed.\nTransfer ID: {transferId}'**
  String receiptShareText(String amount, String date, String transferId);

  /// No description provided for @receiptDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get receiptDone;

  /// No description provided for @offlineBanner.
  ///
  /// In en, this message translates to:
  /// **'Showing saved data — amounts may be outdated. Reconnect to refresh.'**
  String get offlineBanner;

  /// No description provided for @limitsRemaining.
  ///
  /// In en, this message translates to:
  /// **'Daily limit remaining: {amount}'**
  String limitsRemaining(Object amount);

  /// No description provided for @searchContacts.
  ///
  /// In en, this message translates to:
  /// **'Search contacts'**
  String get searchContacts;

  /// No description provided for @chooseRecipient.
  ///
  /// In en, this message translates to:
  /// **'Choose who should receive this action.'**
  String get chooseRecipient;

  /// No description provided for @peopleYouCanPay.
  ///
  /// In en, this message translates to:
  /// **'People you can pay or request money from.'**
  String get peopleYouCanPay;

  /// No description provided for @helpTitle.
  ///
  /// In en, this message translates to:
  /// **'Help & support'**
  String get helpTitle;

  /// No description provided for @helpFaqTitle.
  ///
  /// In en, this message translates to:
  /// **'Frequently asked questions'**
  String get helpFaqTitle;

  /// No description provided for @helpFaqTransfers.
  ///
  /// In en, this message translates to:
  /// **'Transfers execute once the backend validates them. You can retry a failed transfer from its details.'**
  String get helpFaqTransfers;

  /// No description provided for @helpFaqLimits.
  ///
  /// In en, this message translates to:
  /// **'Daily and single-transfer limits protect your account; the remaining daily headroom is shown on the send screen.'**
  String get helpFaqLimits;

  /// No description provided for @helpFaqVerification.
  ///
  /// In en, this message translates to:
  /// **'Verify your email from the banner at the top of your wallet to secure your account.'**
  String get helpFaqVerification;

  /// No description provided for @helpContact.
  ///
  /// In en, this message translates to:
  /// **'Contact support'**
  String get helpContact;

  /// No description provided for @helpContactEmail.
  ///
  /// In en, this message translates to:
  /// **'support@boklo.app'**
  String get helpContactEmail;

  /// No description provided for @selectContact.
  ///
  /// In en, this message translates to:
  /// **'Select contact'**
  String get selectContact;

  /// No description provided for @notFound.
  ///
  /// In en, this message translates to:
  /// **'This item could not be found.'**
  String get notFound;

  /// No description provided for @themePickLook.
  ///
  /// In en, this message translates to:
  /// **'Pick the look you want for Boklo.'**
  String get themePickLook;

  /// No description provided for @accountDeletedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Your account has been deleted successfully.'**
  String get accountDeletedSuccessfully;

  /// No description provided for @invalidNumber.
  ///
  /// In en, this message translates to:
  /// **'Invalid number'**
  String get invalidNumber;

  /// No description provided for @amountMustBePositive.
  ///
  /// In en, this message translates to:
  /// **'Amount must be greater than 0'**
  String get amountMustBePositive;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @languageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose the app language.'**
  String get languageSubtitle;

  /// No description provided for @languageSystem.
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get languageSystem;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageArabic.
  ///
  /// In en, this message translates to:
  /// **'العربية'**
  String get languageArabic;

  /// No description provided for @errTransferFailed.
  ///
  /// In en, this message translates to:
  /// **'The transfer could not be completed.'**
  String get errTransferFailed;

  /// No description provided for @errInsufficientBalance.
  ///
  /// In en, this message translates to:
  /// **'Insufficient balance for this transfer.'**
  String get errInsufficientBalance;

  /// No description provided for @errWalletNotFound.
  ///
  /// In en, this message translates to:
  /// **'Recipient wallet could not be found.'**
  String get errWalletNotFound;

  /// No description provided for @errCurrencyMismatch.
  ///
  /// In en, this message translates to:
  /// **'This transfer was blocked: the wallets use different currencies.'**
  String get errCurrencyMismatch;

  /// No description provided for @errWalletNotMigrated.
  ///
  /// In en, this message translates to:
  /// **'This wallet is temporarily unavailable for transfers.'**
  String get errWalletNotMigrated;

  /// No description provided for @errAlreadyProcessed.
  ///
  /// In en, this message translates to:
  /// **'This transfer was already processed.'**
  String get errAlreadyProcessed;

  /// No description provided for @appLock.
  ///
  /// In en, this message translates to:
  /// **'App lock'**
  String get appLock;

  /// No description provided for @appLockSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Require biometrics or your device PIN to open Boklo.'**
  String get appLockSubtitle;

  /// No description provided for @appLockLockedTitle.
  ///
  /// In en, this message translates to:
  /// **'Boklo is locked'**
  String get appLockLockedTitle;

  /// No description provided for @appLockLockedBody.
  ///
  /// In en, this message translates to:
  /// **'Verify that it\'s you to continue.'**
  String get appLockLockedBody;

  /// No description provided for @appLockUnlock.
  ///
  /// In en, this message translates to:
  /// **'Unlock'**
  String get appLockUnlock;

  /// No description provided for @appLockUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Biometric authentication is not available on this device.'**
  String get appLockUnavailable;
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
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
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
