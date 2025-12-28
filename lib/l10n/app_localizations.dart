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

  /// Language selection dialog title
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
