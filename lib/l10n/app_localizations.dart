import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_vi.dart';

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
    Locale('ar'),
    Locale('en'),
    Locale('es'),
    Locale('vi'),
  ];

  /// The application title
  ///
  /// In en, this message translates to:
  /// **'Grex'**
  String get appTitle;

  /// Welcome message on home screen
  ///
  /// In en, this message translates to:
  /// **'Welcome to Grex with Clean Architecture!'**
  String get welcome;

  /// Message indicating feature flags are ready
  ///
  /// In en, this message translates to:
  /// **'Feature Flags System is ready!'**
  String get featureFlagsReady;

  /// Hint to check examples
  ///
  /// In en, this message translates to:
  /// **'Check the examples in feature_flags_example_screen.dart'**
  String get checkExamples;

  /// Login button and screen title
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// Register button and screen title
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get register;

  /// Email field label
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// Password field label
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// Name field label
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// Email validation error message
  ///
  /// In en, this message translates to:
  /// **'Please enter your email'**
  String get emailRequired;

  /// Invalid email validation error
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email address'**
  String get emailInvalid;

  /// Password validation error message
  ///
  /// In en, this message translates to:
  /// **'Please enter your password'**
  String get passwordRequired;

  /// Password minimum length validation error
  ///
  /// In en, this message translates to:
  /// **'Password must be at least {minLength} characters'**
  String passwordMinLength(int minLength);

  /// Name validation error message
  ///
  /// In en, this message translates to:
  /// **'Please enter your name'**
  String get nameRequired;

  /// Name minimum length validation error
  ///
  /// In en, this message translates to:
  /// **'Name must be at least {minLength} characters'**
  String nameMinLength(int minLength);

  /// Link to registration screen
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? Register'**
  String get dontHaveAccount;

  /// Link to login screen
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Login'**
  String get alreadyHaveAccount;

  /// Retry button label
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// Error title
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// Loading indicator text
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// Language selection label
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// Language selector label
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguage;

  /// English language name
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// Spanish language name
  ///
  /// In en, this message translates to:
  /// **'Spanish'**
  String get spanish;

  /// Arabic language name
  ///
  /// In en, this message translates to:
  /// **'Arabic'**
  String get arabic;

  /// Vietnamese language name
  ///
  /// In en, this message translates to:
  /// **'Vietnamese'**
  String get vietnamese;

  /// Feature flags debug tooltip
  ///
  /// In en, this message translates to:
  /// **'Feature Flags Debug'**
  String get featureFlagsDebug;

  /// Generic error message
  ///
  /// In en, this message translates to:
  /// **'An unexpected error occurred'**
  String get unexpectedError;

  /// HTTP 400 error message
  ///
  /// In en, this message translates to:
  /// **'Bad request. Please check your input.'**
  String get badRequest;

  /// HTTP 401 error message
  ///
  /// In en, this message translates to:
  /// **'Unauthorized. Please login again.'**
  String get unauthorized;

  /// HTTP 403 error message
  ///
  /// In en, this message translates to:
  /// **'Forbidden. You do not have permission.'**
  String get forbidden;

  /// HTTP 404 error message
  ///
  /// In en, this message translates to:
  /// **'Resource not found.'**
  String get notFound;

  /// HTTP 409 error message
  ///
  /// In en, this message translates to:
  /// **'Conflict. The resource already exists.'**
  String get conflict;

  /// HTTP 422 error message
  ///
  /// In en, this message translates to:
  /// **'Validation error. Please check your input.'**
  String get validationError;

  /// HTTP 429 error message
  ///
  /// In en, this message translates to:
  /// **'Too many requests. Please try again later.'**
  String get tooManyRequests;

  /// HTTP 500 error message
  ///
  /// In en, this message translates to:
  /// **'Internal server error. Please try again later.'**
  String get internalServerError;

  /// HTTP 502 error message
  ///
  /// In en, this message translates to:
  /// **'Bad gateway. Please try again later.'**
  String get badGateway;

  /// HTTP 503 error message
  ///
  /// In en, this message translates to:
  /// **'Service unavailable. Please try again later.'**
  String get serviceUnavailable;

  /// HTTP 504 error message
  ///
  /// In en, this message translates to:
  /// **'Gateway timeout. Please try again later.'**
  String get gatewayTimeout;

  /// Generic 4xx error message
  ///
  /// In en, this message translates to:
  /// **'Client error occurred.'**
  String get clientError;

  /// Generic 5xx error message
  ///
  /// In en, this message translates to:
  /// **'Server error occurred. Please try again later.'**
  String get serverError;

  /// Pluralized item count
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No items} =1{1 item} other{{count} items}}'**
  String itemCount(int count);

  /// Pluralized minutes ago
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Just now} =1{1 minute ago} other{{count} minutes ago}}'**
  String minutesAgo(int count);

  /// Edit button label
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// Delete button label
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// Save button label
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// Cancel button label
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Add button label
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// Refresh button label
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// Message displayed when a list has no items
  ///
  /// In en, this message translates to:
  /// **'No items found'**
  String get noItemsFound;

  /// Button label to load more items in a list
  ///
  /// In en, this message translates to:
  /// **'Load More'**
  String get loadMore;

  /// Button label to copy error details to clipboard
  ///
  /// In en, this message translates to:
  /// **'Copy Error'**
  String get copyError;

  /// Button label to restart the application
  ///
  /// In en, this message translates to:
  /// **'Restart'**
  String get restart;

  /// Title for global error handler screen
  ///
  /// In en, this message translates to:
  /// **'An unexpected error occurred'**
  String get errorOccurred;

  /// Description text explaining the error to the user
  ///
  /// In en, this message translates to:
  /// **'The application encountered an error that could not be handled. We have logged this error and will fix it in the next version.'**
  String get errorDescription;

  /// Label for error details section
  ///
  /// In en, this message translates to:
  /// **'Error Details:'**
  String get errorDetails;

  /// Snackbar message when error details are copied to clipboard
  ///
  /// In en, this message translates to:
  /// **'Error details copied'**
  String get copyErrorSuccess;

  /// Message suggesting user contact support for persistent errors
  ///
  /// In en, this message translates to:
  /// **'If the error persists, please contact technical support.'**
  String get contactSupport;

  /// Button label to close a dialog or screen
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// Title displayed on the 404 error page when a route is not found
  ///
  /// In en, this message translates to:
  /// **'Page Not Found'**
  String get pageNotFound;

  /// Button label to navigate to the groups page from error page
  ///
  /// In en, this message translates to:
  /// **'Go to Groups'**
  String get goToGroups;

  /// Button label to add a new payment
  ///
  /// In en, this message translates to:
  /// **'Add Payment'**
  String get addPayment;

  /// Title for the create payment screen
  ///
  /// In en, this message translates to:
  /// **'Create Payment'**
  String get createPayment;

  /// Success message when a payment is created
  ///
  /// In en, this message translates to:
  /// **'Payment created successfully'**
  String get paymentCreatedSuccess;

  /// Validation message when payer is not selected
  ///
  /// In en, this message translates to:
  /// **'Please select who made the payment'**
  String get selectPayer;

  /// Validation message when recipient is not selected
  ///
  /// In en, this message translates to:
  /// **'Please select who received the payment'**
  String get selectRecipient;

  /// Validation error when payer and recipient are the same
  ///
  /// In en, this message translates to:
  /// **'Payer and recipient cannot be the same person'**
  String get payerRecipientSame;

  /// Title for payment details section or screen
  ///
  /// In en, this message translates to:
  /// **'Payment Details'**
  String get paymentDetails;

  /// Button label to delete a payment
  ///
  /// In en, this message translates to:
  /// **'Delete Payment'**
  String get deletePayment;

  /// Confirmation message for deleting a payment
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this payment?'**
  String get confirmDeletePayment;

  /// Button label shown when no payments exist
  ///
  /// In en, this message translates to:
  /// **'Add First Payment'**
  String get addFirstPayment;

  /// Button label to clear all filters or selections
  ///
  /// In en, this message translates to:
  /// **'Clear All'**
  String get clearAll;

  /// Label for ascending sort order option
  ///
  /// In en, this message translates to:
  /// **'Ascending Order'**
  String get ascendingOrder;

  /// Button label to apply filters or changes
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get apply;

  /// Validation error for negative minimum amount
  ///
  /// In en, this message translates to:
  /// **'Minimum amount cannot be negative'**
  String get minAmountNegative;

  /// Validation error for negative maximum amount
  ///
  /// In en, this message translates to:
  /// **'Maximum amount cannot be negative'**
  String get maxAmountNegative;

  /// Validation error when minimum exceeds maximum amount
  ///
  /// In en, this message translates to:
  /// **'Min amount cannot be greater than max amount'**
  String get minGreaterThanMax;

  /// Validation error when start date is after end date
  ///
  /// In en, this message translates to:
  /// **'Start date cannot be after end date'**
  String get startAfterEnd;

  /// Button label to create a new group
  ///
  /// In en, this message translates to:
  /// **'Create New Group'**
  String get createNewGroup;

  /// Title for the feature flags debug screen
  ///
  /// In en, this message translates to:
  /// **'Feature Flags Debug'**
  String get featureFlagsDebugTitle;

  /// Button label to clear all feature flag overrides
  ///
  /// In en, this message translates to:
  /// **'Clear All Overrides'**
  String get clearAllOverrides;

  /// Confirmation message for clearing all feature flag overrides
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to clear all local overrides?'**
  String get confirmClearOverrides;

  /// Button label for clear action
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// Success message when all feature flag overrides are cleared
  ///
  /// In en, this message translates to:
  /// **'All local overrides cleared'**
  String get overridesCleared;

  /// Message displayed when no feature flags are available
  ///
  /// In en, this message translates to:
  /// **'No feature flags found'**
  String get noFeatureFlags;

  /// Title for the feature flags examples screen
  ///
  /// In en, this message translates to:
  /// **'Feature Flags Examples'**
  String get featureFlagsExamples;

  /// Message indicating a new feature is enabled
  ///
  /// In en, this message translates to:
  /// **'New Feature is ENABLED'**
  String get newFeatureEnabled;

  /// Message indicating a new feature is disabled
  ///
  /// In en, this message translates to:
  /// **'New Feature is DISABLED'**
  String get newFeatureDisabled;

  /// Title displayed when there are no payments
  ///
  /// In en, this message translates to:
  /// **'No Payments'**
  String get noPayments;

  /// Title for the payment summary section
  ///
  /// In en, this message translates to:
  /// **'Payment Summary'**
  String get paymentSummary;

  /// Label for total number of payments
  ///
  /// In en, this message translates to:
  /// **'Total Payments'**
  String get totalPayments;

  /// Label for total payment amount
  ///
  /// In en, this message translates to:
  /// **'Total Amount'**
  String get totalAmount;

  /// Error message when payments fail to load
  ///
  /// In en, this message translates to:
  /// **'Error loading payments'**
  String get errorLoadingPayments;

  /// Tooltip for filter payments button
  ///
  /// In en, this message translates to:
  /// **'Filter payments'**
  String get filterPayments;

  /// Tooltip for clear filters button
  ///
  /// In en, this message translates to:
  /// **'Clear filters'**
  String get clearFilters;

  /// Title for the filter and sort bottom sheet
  ///
  /// In en, this message translates to:
  /// **'Filter & Sort Payments'**
  String get filterAndSortPayments;

  /// Section header for date range filter
  ///
  /// In en, this message translates to:
  /// **'Date Range'**
  String get dateRange;

  /// Section header for amount range filter
  ///
  /// In en, this message translates to:
  /// **'Amount Range'**
  String get amountRange;

  /// Section header for sort options
  ///
  /// In en, this message translates to:
  /// **'Sort By'**
  String get sortBy;

  /// Label for start date field
  ///
  /// In en, this message translates to:
  /// **'Start Date'**
  String get startDate;

  /// Label for end date field
  ///
  /// In en, this message translates to:
  /// **'End Date'**
  String get endDate;

  /// Label for minimum amount field
  ///
  /// In en, this message translates to:
  /// **'Min Amount'**
  String get minAmount;

  /// Label for maximum amount field
  ///
  /// In en, this message translates to:
  /// **'Max Amount'**
  String get maxAmount;

  /// Placeholder text for date selection
  ///
  /// In en, this message translates to:
  /// **'Select date'**
  String get selectDate;

  /// Description for ascending date sort order
  ///
  /// In en, this message translates to:
  /// **'Oldest to newest'**
  String get oldestToNewest;

  /// Description for descending date sort order
  ///
  /// In en, this message translates to:
  /// **'Newest to oldest'**
  String get newestToOldest;

  /// Validation error when amount is empty
  ///
  /// In en, this message translates to:
  /// **'Amount is required'**
  String get amountRequired;

  /// Validation error for invalid amount
  ///
  /// In en, this message translates to:
  /// **'Enter a valid positive amount'**
  String get enterValidPositiveAmount;

  /// Label for currency field
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get currency;

  /// Label for optional description field
  ///
  /// In en, this message translates to:
  /// **'Description (Optional)'**
  String get descriptionOptional;

  /// Hint text for payment description field
  ///
  /// In en, this message translates to:
  /// **'What was this payment for?'**
  String get whatWasPaymentFor;

  /// Label for payment date field
  ///
  /// In en, this message translates to:
  /// **'Payment Date'**
  String get paymentDate;

  /// Section title for payment participants
  ///
  /// In en, this message translates to:
  /// **'Payment Participants'**
  String get paymentParticipants;

  /// Label for payer selection field
  ///
  /// In en, this message translates to:
  /// **'Who paid? *'**
  String get whoPaid;

  /// Label for recipient selection field
  ///
  /// In en, this message translates to:
  /// **'Who received the payment? *'**
  String get whoReceivedPayment;

  /// Warning message when payer and recipient are the same
  ///
  /// In en, this message translates to:
  /// **'A person cannot pay themselves. Please select different payer and recipient.'**
  String get cannotPaySelf;

  /// Label showing who made the payment
  ///
  /// In en, this message translates to:
  /// **'From: {name}'**
  String from(String name);

  /// Label showing who received the payment
  ///
  /// In en, this message translates to:
  /// **'To: {name}'**
  String to(String name);

  /// Label showing payment amount
  ///
  /// In en, this message translates to:
  /// **'Amount: {value}'**
  String amount(String value);

  /// Label showing payment description
  ///
  /// In en, this message translates to:
  /// **'Description: {text}'**
  String description(String text);

  /// Label showing payment date
  ///
  /// In en, this message translates to:
  /// **'Date: {value}'**
  String date(String value);

  /// Title for group payments page
  ///
  /// In en, this message translates to:
  /// **'{groupName} Payments'**
  String groupPayments(String groupName);

  /// Helper text for payment amount field
  ///
  /// In en, this message translates to:
  /// **'Enter the payment amount'**
  String get enterPaymentAmount;

  /// Confirmation message for deleting a specific payment
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this payment from {payer} to {recipient}?'**
  String confirmDeletePaymentFrom(String payer, String recipient);

  /// Message when no payments match filter criteria
  ///
  /// In en, this message translates to:
  /// **'No payments match your criteria.'**
  String get noPaymentsMatchCriteria;

  /// Message when no payments match search filters
  ///
  /// In en, this message translates to:
  /// **'No payments match your search criteria. Try adjusting your filters.'**
  String get noPaymentsMatchSearch;

  /// Message when there are no payments in the group
  ///
  /// In en, this message translates to:
  /// **'No payments yet. Add your first payment to get started!'**
  String get noPaymentsYet;

  /// Label for required amount field
  ///
  /// In en, this message translates to:
  /// **'Amount *'**
  String get amountLabel;

  /// Title for example screen in performance examples
  ///
  /// In en, this message translates to:
  /// **'Example Screen'**
  String get exampleScreen;

  /// Content text for example screen in performance examples
  ///
  /// In en, this message translates to:
  /// **'Example Screen Content'**
  String get exampleScreenContent;

  /// Login screen title
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get welcomeBack;

  /// Login screen subtitle
  ///
  /// In en, this message translates to:
  /// **'Sign in to continue'**
  String get signInToContinue;

  /// Forgot password link
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotPassword;

  /// Divider text for social login
  ///
  /// In en, this message translates to:
  /// **'or'**
  String get orContinueWith;

  /// Google sign-in button text
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get continueWithGoogle;

  /// Apple sign-in button text
  ///
  /// In en, this message translates to:
  /// **'Continue with Apple'**
  String get continueWithApple;

  /// Register screen title
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get createAccount;

  /// Register screen subtitle
  ///
  /// In en, this message translates to:
  /// **'Join Grex today'**
  String get joinGrexToday;

  /// Display name field label
  ///
  /// In en, this message translates to:
  /// **'Display Name'**
  String get displayName;

  /// Display name field hint
  ///
  /// In en, this message translates to:
  /// **'Enter your name'**
  String get enterYourName;

  /// Email field hint
  ///
  /// In en, this message translates to:
  /// **'Enter your email'**
  String get enterYourEmail;

  /// Password field hint
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get enterYourPassword;

  /// Currency selector label
  ///
  /// In en, this message translates to:
  /// **'Select Currency'**
  String get selectCurrency;

  /// Password requirements hint
  ///
  /// In en, this message translates to:
  /// **'At least 8 characters with uppercase, lowercase, and numbers'**
  String get passwordRequirements;

  /// Link to login from register
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Sign in'**
  String get alreadyHaveAccountSignIn;

  /// Forgot password screen title
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPasswordQuestion;

  /// Forgot password instructions
  ///
  /// In en, this message translates to:
  /// **'Enter your email address and we\'ll send you a link to reset your password'**
  String get enterEmailForReset;

  /// Send reset link button
  ///
  /// In en, this message translates to:
  /// **'Send Reset Link'**
  String get sendResetLink;

  /// Success message after sending reset link
  ///
  /// In en, this message translates to:
  /// **'Reset link sent! Check your email.'**
  String get resetLinkSent;

  /// Link back to login
  ///
  /// In en, this message translates to:
  /// **'Back to Sign in'**
  String get backToSignIn;

  /// Email verification screen title
  ///
  /// In en, this message translates to:
  /// **'Verify Your Email'**
  String get verifyYourEmail;

  /// Email verification instructions
  ///
  /// In en, this message translates to:
  /// **'We\'ve sent a verification email to:'**
  String get verificationEmailSent;

  /// Email verification instructions continued
  ///
  /// In en, this message translates to:
  /// **'Check your inbox and click the verification link to continue.'**
  String get checkInboxAndClick;

  /// Resend verification email button
  ///
  /// In en, this message translates to:
  /// **'Resend Email'**
  String get resendEmail;

  /// Open email app button
  ///
  /// In en, this message translates to:
  /// **'Open Email App'**
  String get openEmailApp;

  /// Help section title
  ///
  /// In en, this message translates to:
  /// **'Didn\'t receive the email?'**
  String get didntReceiveEmail;

  /// Help tip 1
  ///
  /// In en, this message translates to:
  /// **'• Check your spam or junk folder'**
  String get checkSpamFolder;

  /// Help tip 2
  ///
  /// In en, this message translates to:
  /// **'• Make sure the email address is correct'**
  String get verifyEmailAddress;

  /// Help tip 3
  ///
  /// In en, this message translates to:
  /// **'• Wait a few minutes and try again'**
  String get waitFewMinutes;

  /// Sign out button
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// Success message after resending email
  ///
  /// In en, this message translates to:
  /// **'Email sent! Check your inbox.'**
  String get emailSentCheckInbox;

  /// Cooldown message for resend button
  ///
  /// In en, this message translates to:
  /// **'Please wait {seconds} seconds'**
  String pleaseWaitSeconds(int seconds);

  /// Reset password screen title
  ///
  /// In en, this message translates to:
  /// **'Reset Password'**
  String get resetPassword;

  /// Reset password instructions
  ///
  /// In en, this message translates to:
  /// **'Enter your new password below'**
  String get enterNewPassword;

  /// New password field label
  ///
  /// In en, this message translates to:
  /// **'New Password'**
  String get newPassword;

  /// Confirm password field label
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPassword;

  /// Confirm password field hint
  ///
  /// In en, this message translates to:
  /// **'Confirm your password'**
  String get confirmYourPassword;

  /// Password mismatch error
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsDoNotMatch;

  /// Profile setup screen title for new social login users
  ///
  /// In en, this message translates to:
  /// **'Complete Your Profile'**
  String get completeYourProfile;

  /// Progress indicator
  ///
  /// In en, this message translates to:
  /// **'Step 1 of 2'**
  String get stepOfTwo;

  /// Avatar upload button
  ///
  /// In en, this message translates to:
  /// **'Upload Photo'**
  String get uploadPhoto;

  /// Complete setup button
  ///
  /// In en, this message translates to:
  /// **'Complete Setup'**
  String get completeSetup;

  /// Skip setup button
  ///
  /// In en, this message translates to:
  /// **'Skip for now'**
  String get skipForNow;

  /// Success screen title
  ///
  /// In en, this message translates to:
  /// **'Success!'**
  String get success;

  /// Account creation success message
  ///
  /// In en, this message translates to:
  /// **'Your account has been created successfully'**
  String get accountCreatedSuccessfully;

  /// Password reset success message
  ///
  /// In en, this message translates to:
  /// **'Your password has been reset successfully'**
  String get passwordResetSuccessfully;

  /// Email verification success message
  ///
  /// In en, this message translates to:
  /// **'Your email has been verified successfully'**
  String get emailVerifiedSuccessfully;

  /// Continue button
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueButton;

  /// Get started button
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get getStarted;

  /// Back button
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// Generic social authentication failure message
  ///
  /// In en, this message translates to:
  /// **'Authentication failed. Please try again.'**
  String get socialAuthFailed;

  /// Network error during social authentication
  ///
  /// In en, this message translates to:
  /// **'Network connection failed. Please check your internet connection and try again.'**
  String get socialAuthNetworkError;

  /// Timeout error during social authentication
  ///
  /// In en, this message translates to:
  /// **'Authentication timed out. Please try again.'**
  String get socialAuthTimeout;

  /// Account linking failure message
  ///
  /// In en, this message translates to:
  /// **'Failed to link your account. Please try again or contact support.'**
  String get accountLinkingError;

  /// Fallback button to use email authentication
  ///
  /// In en, this message translates to:
  /// **'Sign in with email'**
  String get signInWithEmail;

  /// Dismiss button for error dialogs
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get dismiss;

  /// Message shown after repeated network failures
  ///
  /// In en, this message translates to:
  /// **'Multiple network errors detected. Please check your internet connection or try signing in with email.'**
  String get repeatedNetworkFailureMessage;

  /// Message shown after repeated timeout failures
  ///
  /// In en, this message translates to:
  /// **'Authentication keeps timing out. Please try signing in with email instead.'**
  String get repeatedTimeoutFailureMessage;

  /// Message shown after repeated authentication failures
  ///
  /// In en, this message translates to:
  /// **'Authentication failed multiple times. Please try signing in with email or contact support.'**
  String get repeatedAuthFailureMessage;

  /// Divider text between authentication options
  ///
  /// In en, this message translates to:
  /// **'or'**
  String get or;

  /// Description text on profile setup screen
  ///
  /// In en, this message translates to:
  /// **'Please complete your profile to get started with Grex'**
  String get profileSetupDescription;

  /// Account linking dialog title
  ///
  /// In en, this message translates to:
  /// **'Link Your Account'**
  String get linkYourAccount;

  /// Message explaining existing account with email
  ///
  /// In en, this message translates to:
  /// **'An account with email {email} already exists.'**
  String accountExistsMessage(String email);

  /// Question asking user to confirm account linking
  ///
  /// In en, this message translates to:
  /// **'Would you like to link your {provider} account to your existing account?'**
  String linkAccountQuestion(String provider);

  /// Explanation of account linking benefits
  ///
  /// In en, this message translates to:
  /// **'This will allow you to sign in with either method.'**
  String get linkAccountBenefit;

  /// Button to confirm account linking
  ///
  /// In en, this message translates to:
  /// **'Link Accounts'**
  String get linkAccounts;

  /// Button to decline linking and create new account
  ///
  /// In en, this message translates to:
  /// **'Create New Account'**
  String get createNewAccount;

  /// Button to cancel profile setup
  ///
  /// In en, this message translates to:
  /// **'Cancel Setup'**
  String get cancelProfileSetup;

  /// Confirmation message when canceling profile setup
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to cancel? You will be signed out and need to sign in again.'**
  String get cancelProfileSetupMessage;

  /// Button to continue with profile setup
  ///
  /// In en, this message translates to:
  /// **'Continue Setup'**
  String get continueSetup;

  /// Loading text shown during sign-in
  ///
  /// In en, this message translates to:
  /// **'Signing in...'**
  String get signingIn;

  /// Register page title
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get registerAccount;

  /// Register page subtitle
  ///
  /// In en, this message translates to:
  /// **'Join Grex to start splitting expenses'**
  String get joinGrexExpenseShare;

  /// Loading text shown during registration
  ///
  /// In en, this message translates to:
  /// **'Creating account...'**
  String get registering;

  /// Validation error when display name is missing
  ///
  /// In en, this message translates to:
  /// **'Please enter your display name'**
  String get displayNameRequired;

  /// Validation error when display name is only whitespace
  ///
  /// In en, this message translates to:
  /// **'Display name cannot be empty'**
  String get displayNameEmpty;

  /// Validation error for display name length
  ///
  /// In en, this message translates to:
  /// **'Display name must be 50 characters or less'**
  String get displayNameTooLong;

  /// Label for preferred currency selector
  ///
  /// In en, this message translates to:
  /// **'Preferred Currency'**
  String get preferredCurrencyLabel;

  /// Short password placeholder
  ///
  /// In en, this message translates to:
  /// **'Min. 8 characters'**
  String get passwordHintShort;

  /// Display name field placeholder
  ///
  /// In en, this message translates to:
  /// **'Your name'**
  String get yourNameHint;

  /// Hint shown beneath password input
  ///
  /// In en, this message translates to:
  /// **'Must be at least 8 characters with mixed case and numbers'**
  String get passwordHint;

  /// Prefix before the sign-in link on register page
  ///
  /// In en, this message translates to:
  /// **'Already have an account? '**
  String get alreadyHaveAccountPrefix;

  /// Sign-in CTA
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signIn;

  /// Forgot password screen title without question mark
  ///
  /// In en, this message translates to:
  /// **'Forgot Password'**
  String get forgotPasswordTitle;

  /// Short forgot password instructions
  ///
  /// In en, this message translates to:
  /// **'Enter your email to reset your password'**
  String get enterEmailForResetShort;

  /// Short send reset link button
  ///
  /// In en, this message translates to:
  /// **'Send Reset Link'**
  String get sendResetLinkShort;

  /// Loading text shown during password reset send
  ///
  /// In en, this message translates to:
  /// **'Sending...'**
  String get sending;

  /// Success message after reset email sent
  ///
  /// In en, this message translates to:
  /// **'Password reset email sent'**
  String get resetEmailSent;

  /// Success detail referencing the email address
  ///
  /// In en, this message translates to:
  /// **'Please check your email at {email}'**
  String pleaseCheckEmailAt(String email);

  /// Resend button label
  ///
  /// In en, this message translates to:
  /// **'Resend'**
  String get resend;

  /// Error when email not registered
  ///
  /// In en, this message translates to:
  /// **'Email not found in our system'**
  String get emailNotInSystem;

  /// Helper text on forgot password
  ///
  /// In en, this message translates to:
  /// **'We\'ll send a link to reset your password to your email'**
  String get weWillSendLink;

  /// Prefix above sign-in link on forgot password
  ///
  /// In en, this message translates to:
  /// **'Remember your password? '**
  String get rememberPassword;

  /// Profile page app bar title
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileTitle;

  /// Profile page large heading / hero title
  ///
  /// In en, this message translates to:
  /// **'Your Profile'**
  String get profileFullTitle;

  /// Sign-out confirmation dialog title
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOutConfirmTitle;

  /// Sign-out confirmation dialog body
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to sign out?'**
  String get signOutConfirmMessage;

  /// Profile page error title when load fails
  ///
  /// In en, this message translates to:
  /// **'Could not load your profile'**
  String get profileLoadFailed;

  /// Shown when profile state has no profile attached
  ///
  /// In en, this message translates to:
  /// **'No profile data'**
  String get noProfileData;

  /// Info card title for profile creation date
  ///
  /// In en, this message translates to:
  /// **'Account created'**
  String get accountCreatedAt;

  /// Info card title for last profile update
  ///
  /// In en, this message translates to:
  /// **'Last updated'**
  String get lastUpdatedAt;

  /// Edit profile button + page title
  ///
  /// In en, this message translates to:
  /// **'Edit profile'**
  String get editProfile;

  /// Inline error banner with detail message
  ///
  /// In en, this message translates to:
  /// **'Error: {message}'**
  String errorWithMessage(String message);

  /// Tooltip for refresh action button
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refreshTooltip;

  /// Profile creation summary line
  ///
  /// In en, this message translates to:
  /// **'Joined {date}'**
  String joinedAt(String date);

  /// Relative time: today
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// Relative time: yesterday
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get yesterday;

  /// Relative time: N days ago
  ///
  /// In en, this message translates to:
  /// **'{count} days ago'**
  String daysAgo(int count);

  /// Relative time: N weeks ago
  ///
  /// In en, this message translates to:
  /// **'{count} weeks ago'**
  String weeksAgo(int count);

  /// Relative time: N months ago
  ///
  /// In en, this message translates to:
  /// **'{count} months ago'**
  String monthsAgo(int count);

  /// Relative time: N years ago
  ///
  /// In en, this message translates to:
  /// **'{count} years ago'**
  String yearsAgo(int count);

  /// Save button on edit profile
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get saveChanges;

  /// Save button loading label
  ///
  /// In en, this message translates to:
  /// **'Saving...'**
  String get saving;

  /// Confirm-cancel dialog title
  ///
  /// In en, this message translates to:
  /// **'Discard changes?'**
  String get cancelChangesTitle;

  /// Confirm-cancel dialog body
  ///
  /// In en, this message translates to:
  /// **'You have unsaved changes. Are you sure you want to cancel?'**
  String get unsavedChangesMessage;

  /// Confirm-cancel: keep editing button
  ///
  /// In en, this message translates to:
  /// **'Continue editing'**
  String get continueEditing;

  /// Confirm-cancel: discard button
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get discardChanges;

  /// Snackbar after profile saves successfully
  ///
  /// In en, this message translates to:
  /// **'Profile updated successfully'**
  String get profileUpdatedSuccess;

  /// Hint for display name text field
  ///
  /// In en, this message translates to:
  /// **'Enter your display name'**
  String get displayNameHint;

  /// Display name minimum length error
  ///
  /// In en, this message translates to:
  /// **'Display name must be at least {min} characters'**
  String displayNameTooShort(int min);

  /// Display name forbidden-character error
  ///
  /// In en, this message translates to:
  /// **'Display name contains invalid characters'**
  String get displayNameInvalidChars;

  /// Section title for tips on edit profile
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get editProfileNoteTitle;

  /// Edit-profile tip about display name visibility
  ///
  /// In en, this message translates to:
  /// **'• Your display name is shown to other members'**
  String get editProfileTipDisplayName;

  /// Edit-profile tip about default currency
  ///
  /// In en, this message translates to:
  /// **'• Preferred currency is used as the default'**
  String get editProfileTipCurrency;

  /// Edit-profile tip about language scope
  ///
  /// In en, this message translates to:
  /// **'• Language changes apply across the whole app'**
  String get editProfileTipLanguage;

  /// Placeholder for confirm-password field
  ///
  /// In en, this message translates to:
  /// **'Re-enter password'**
  String get reenterPassword;

  /// Validation error when currency dropdown has no selection
  ///
  /// In en, this message translates to:
  /// **'Please select a currency'**
  String get currencyRequired;

  /// Validation error when language dropdown has no selection
  ///
  /// In en, this message translates to:
  /// **'Please select a language'**
  String get languageRequired;

  /// App bar title on the group list page
  ///
  /// In en, this message translates to:
  /// **'My Groups'**
  String get myGroups;

  /// Empty-state title shown when the user has no groups
  ///
  /// In en, this message translates to:
  /// **'No groups yet'**
  String get noGroupsTitle;

  /// Empty-state body shown when the user has no groups
  ///
  /// In en, this message translates to:
  /// **'Create your first group to start splitting expenses with friends and family.'**
  String get noGroupsDescription;

  /// Generic error title used on error states
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get somethingWentWrong;

  /// Friendly explanation shown when the groups list fails to load
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t load your groups. Check your connection and try again.'**
  String get couldNotLoadGroups;

  /// Pluralized count of members in a group
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No members} =1{1 member} other{{count} members}}'**
  String membersCount(int count);

  /// App bar title on the expense list page
  ///
  /// In en, this message translates to:
  /// **'{groupName} expenses'**
  String expensesPageTitle(String groupName);

  /// Placeholder text in the expense search field
  ///
  /// In en, this message translates to:
  /// **'Search expenses…'**
  String get expensesSearchHint;

  /// Tooltip for the expense filter button
  ///
  /// In en, this message translates to:
  /// **'Filter expenses'**
  String get filterExpenses;

  /// Label / tooltip for the add-expense action
  ///
  /// In en, this message translates to:
  /// **'Add expense'**
  String get addExpense;

  /// Empty-state title on the expense list
  ///
  /// In en, this message translates to:
  /// **'No expenses yet'**
  String get noExpensesTitle;

  /// Empty-state body when no expenses exist
  ///
  /// In en, this message translates to:
  /// **'Start tracking your group\'s spending by adding the first expense.'**
  String get noExpensesDescription;

  /// Empty-state body when search/filter returns no results
  ///
  /// In en, this message translates to:
  /// **'No expenses match your filters. Try widening the criteria.'**
  String get noExpensesMatchFilters;

  /// Empty-state CTA label
  ///
  /// In en, this message translates to:
  /// **'Add first expense'**
  String get addFirstExpense;

  /// Friendly explanation shown when the expense list fails to load
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t load expenses. Check your connection and try again.'**
  String get couldNotLoadExpenses;

  /// Label showing who paid for an expense
  ///
  /// In en, this message translates to:
  /// **'Paid by {name}'**
  String paidByPerson(String name);

  /// Pluralized count of participants in a split
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No participants} =1{1 participant} other{{count} participants}}'**
  String participantsCount(int count);

  /// Badge shown when an expense's split totals do not match its amount
  ///
  /// In en, this message translates to:
  /// **'Invalid split'**
  String get invalidSplit;

  /// Badge shown when an expense's split totals match its amount
  ///
  /// In en, this message translates to:
  /// **'Valid'**
  String get validSplit;

  /// Small label shown when an expense is in a currency different from the group's
  ///
  /// In en, this message translates to:
  /// **'Group: {currency}'**
  String groupCurrencyLabel(String currency);

  /// App bar title on the balance page
  ///
  /// In en, this message translates to:
  /// **'{groupName} balances'**
  String balancesPageTitle(String groupName);

  /// Tooltip for the refresh-balances action
  ///
  /// In en, this message translates to:
  /// **'Refresh balances'**
  String get refreshBalances;

  /// Friendly explanation shown when balances fail to load
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t load balances. Check your connection and try again.'**
  String get couldNotLoadBalances;

  /// Section title above the list of per-member balances
  ///
  /// In en, this message translates to:
  /// **'Member balances'**
  String get memberBalances;

  /// FAB label that opens the settlement plan
  ///
  /// In en, this message translates to:
  /// **'Settle up'**
  String get settleUp;

  /// Label above a single balance amount in the detail sheet
  ///
  /// In en, this message translates to:
  /// **'Balance'**
  String get balanceAmountLabel;

  /// CTA opening the settlement plan from a balance detail sheet
  ///
  /// In en, this message translates to:
  /// **'View settlement plan'**
  String get viewSettlementPlan;

  /// Subtitle shown when a member owes money to the group
  ///
  /// In en, this message translates to:
  /// **'Owes money to group'**
  String get balanceStatusOwes;

  /// Subtitle shown when a member is owed money by the group
  ///
  /// In en, this message translates to:
  /// **'Is owed money by group'**
  String get balanceStatusOwed;

  /// Subtitle shown when a member's balance is zero
  ///
  /// In en, this message translates to:
  /// **'All settled up'**
  String get balanceStatusSettled;

  /// Compact badge label for the 'owes' balance state
  ///
  /// In en, this message translates to:
  /// **'OWES'**
  String get balanceBadgeOwes;

  /// Compact badge label for the 'owed' balance state
  ///
  /// In en, this message translates to:
  /// **'OWED'**
  String get balanceBadgeOwed;

  /// Compact badge label for the 'settled' balance state
  ///
  /// In en, this message translates to:
  /// **'SETTLED'**
  String get balanceBadgeSettled;

  /// Empty-state title on the balance page
  ///
  /// In en, this message translates to:
  /// **'No balances yet'**
  String get noBalancesTitle;

  /// Empty-state body on the balance page
  ///
  /// In en, this message translates to:
  /// **'Balances will appear here once expenses and payments are added to the group.'**
  String get noBalancesDescription;

  /// Help text on the empty balance state
  ///
  /// In en, this message translates to:
  /// **'Balances are calculated automatically from your group\'s expenses and payments.'**
  String get balancesAutoExplainer;

  /// CTA label that returns to the expense list to add expenses
  ///
  /// In en, this message translates to:
  /// **'Add expenses'**
  String get addExpenses;

  /// CTA label that returns to the payment list to record payments
  ///
  /// In en, this message translates to:
  /// **'Record payments'**
  String get recordPayments;

  /// Title for the summary card on the balance page
  ///
  /// In en, this message translates to:
  /// **'Balance summary'**
  String get balanceSummary;

  /// Stat label — total money owed to members in the group
  ///
  /// In en, this message translates to:
  /// **'Total owed'**
  String get totalOwed;

  /// Stat label — total money owed by members in the group
  ///
  /// In en, this message translates to:
  /// **'Total owes'**
  String get totalOwes;

  /// Stat label — number of members fully settled
  ///
  /// In en, this message translates to:
  /// **'Settled'**
  String get settledStat;

  /// Stat label — number of members still with non-zero balances
  ///
  /// In en, this message translates to:
  /// **'Unsettled'**
  String get unsettledStat;

  /// Primary CTA in the balance summary card
  ///
  /// In en, this message translates to:
  /// **'Generate settlement plan'**
  String get generateSettlementPlan;

  /// Celebratory banner shown when nobody owes anything
  ///
  /// In en, this message translates to:
  /// **'All members are settled up!'**
  String get allMembersSettledUp;
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
      <String>['ar', 'en', 'es', 'vi'].contains(locale.languageCode);

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
    case 'es':
      return AppLocalizationsEs();
    case 'vi':
      return AppLocalizationsVi();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
