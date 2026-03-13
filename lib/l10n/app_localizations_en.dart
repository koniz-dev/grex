// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Grex';

  @override
  String get welcome => 'Welcome to Grex with Clean Architecture!';

  @override
  String get featureFlagsReady => 'Feature Flags System is ready!';

  @override
  String get checkExamples =>
      'Check the examples in feature_flags_example_screen.dart';

  @override
  String get login => 'Login';

  @override
  String get register => 'Register';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get name => 'Name';

  @override
  String get emailRequired => 'Please enter your email';

  @override
  String get emailInvalid => 'Please enter a valid email address';

  @override
  String get passwordRequired => 'Please enter your password';

  @override
  String passwordMinLength(int minLength) {
    return 'Password must be at least $minLength characters';
  }

  @override
  String get nameRequired => 'Please enter your name';

  @override
  String nameMinLength(int minLength) {
    return 'Name must be at least $minLength characters';
  }

  @override
  String get dontHaveAccount => 'Don\'t have an account? Register';

  @override
  String get alreadyHaveAccount => 'Already have an account? Login';

  @override
  String get retry => 'Retry';

  @override
  String get error => 'Error';

  @override
  String get loading => 'Loading...';

  @override
  String get language => 'Language';

  @override
  String get selectLanguage => 'Select Language';

  @override
  String get english => 'English';

  @override
  String get spanish => 'Spanish';

  @override
  String get arabic => 'Arabic';

  @override
  String get vietnamese => 'Vietnamese';

  @override
  String get featureFlagsDebug => 'Feature Flags Debug';

  @override
  String get unexpectedError => 'An unexpected error occurred';

  @override
  String get badRequest => 'Bad request. Please check your input.';

  @override
  String get unauthorized => 'Unauthorized. Please login again.';

  @override
  String get forbidden => 'Forbidden. You do not have permission.';

  @override
  String get notFound => 'Resource not found.';

  @override
  String get conflict => 'Conflict. The resource already exists.';

  @override
  String get validationError => 'Validation error. Please check your input.';

  @override
  String get tooManyRequests => 'Too many requests. Please try again later.';

  @override
  String get internalServerError =>
      'Internal server error. Please try again later.';

  @override
  String get badGateway => 'Bad gateway. Please try again later.';

  @override
  String get serviceUnavailable =>
      'Service unavailable. Please try again later.';

  @override
  String get gatewayTimeout => 'Gateway timeout. Please try again later.';

  @override
  String get clientError => 'Client error occurred.';

  @override
  String get serverError => 'Server error occurred. Please try again later.';

  @override
  String itemCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items',
      one: '1 item',
      zero: 'No items',
    );
    return '$_temp0';
  }

  @override
  String minutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count minutes ago',
      one: '1 minute ago',
      zero: 'Just now',
    );
    return '$_temp0';
  }

  @override
  String get edit => 'Edit';

  @override
  String get delete => 'Delete';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get add => 'Add';

  @override
  String get refresh => 'Refresh';

  @override
  String get noItemsFound => 'No items found';

  @override
  String get loadMore => 'Load More';

  @override
  String get copyError => 'Copy Error';

  @override
  String get restart => 'Restart';

  @override
  String get errorOccurred => 'An unexpected error occurred';

  @override
  String get errorDescription =>
      'The application encountered an error that could not be handled. We have logged this error and will fix it in the next version.';

  @override
  String get errorDetails => 'Error Details:';

  @override
  String get copyErrorSuccess => 'Error details copied';

  @override
  String get contactSupport =>
      'If the error persists, please contact technical support.';

  @override
  String get close => 'Close';

  @override
  String get pageNotFound => 'Page Not Found';

  @override
  String get goToGroups => 'Go to Groups';

  @override
  String get addPayment => 'Add Payment';

  @override
  String get createPayment => 'Create Payment';

  @override
  String get paymentCreatedSuccess => 'Payment created successfully';

  @override
  String get selectPayer => 'Please select who made the payment';

  @override
  String get selectRecipient => 'Please select who received the payment';

  @override
  String get payerRecipientSame =>
      'Payer and recipient cannot be the same person';

  @override
  String get paymentDetails => 'Payment Details';

  @override
  String get deletePayment => 'Delete Payment';

  @override
  String get confirmDeletePayment =>
      'Are you sure you want to delete this payment?';

  @override
  String get addFirstPayment => 'Add First Payment';

  @override
  String get clearAll => 'Clear All';

  @override
  String get ascendingOrder => 'Ascending Order';

  @override
  String get apply => 'Apply';

  @override
  String get minAmountNegative => 'Minimum amount cannot be negative';

  @override
  String get maxAmountNegative => 'Maximum amount cannot be negative';

  @override
  String get minGreaterThanMax =>
      'Min amount cannot be greater than max amount';

  @override
  String get startAfterEnd => 'Start date cannot be after end date';

  @override
  String get createNewGroup => 'Create New Group';

  @override
  String get featureFlagsDebugTitle => 'Feature Flags Debug';

  @override
  String get clearAllOverrides => 'Clear All Overrides';

  @override
  String get confirmClearOverrides =>
      'Are you sure you want to clear all local overrides?';

  @override
  String get clear => 'Clear';

  @override
  String get overridesCleared => 'All local overrides cleared';

  @override
  String get noFeatureFlags => 'No feature flags found';

  @override
  String get featureFlagsExamples => 'Feature Flags Examples';

  @override
  String get newFeatureEnabled => 'New Feature is ENABLED';

  @override
  String get newFeatureDisabled => 'New Feature is DISABLED';

  @override
  String get noPayments => 'No Payments';

  @override
  String get paymentSummary => 'Payment Summary';

  @override
  String get totalPayments => 'Total Payments';

  @override
  String get totalAmount => 'Total Amount';

  @override
  String get errorLoadingPayments => 'Error loading payments';

  @override
  String get filterPayments => 'Filter payments';

  @override
  String get clearFilters => 'Clear filters';

  @override
  String get filterAndSortPayments => 'Filter & Sort Payments';

  @override
  String get dateRange => 'Date Range';

  @override
  String get amountRange => 'Amount Range';

  @override
  String get sortBy => 'Sort By';

  @override
  String get startDate => 'Start Date';

  @override
  String get endDate => 'End Date';

  @override
  String get minAmount => 'Min Amount';

  @override
  String get maxAmount => 'Max Amount';

  @override
  String get selectDate => 'Select date';

  @override
  String get oldestToNewest => 'Oldest to newest';

  @override
  String get newestToOldest => 'Newest to oldest';

  @override
  String get amountRequired => 'Amount is required';

  @override
  String get enterValidPositiveAmount => 'Enter a valid positive amount';

  @override
  String get currency => 'Currency';

  @override
  String get descriptionOptional => 'Description (Optional)';

  @override
  String get whatWasPaymentFor => 'What was this payment for?';

  @override
  String get paymentDate => 'Payment Date';

  @override
  String get paymentParticipants => 'Payment Participants';

  @override
  String get whoPaid => 'Who paid? *';

  @override
  String get whoReceivedPayment => 'Who received the payment? *';

  @override
  String get cannotPaySelf =>
      'A person cannot pay themselves. Please select different payer and recipient.';

  @override
  String from(String name) {
    return 'From: $name';
  }

  @override
  String to(String name) {
    return 'To: $name';
  }

  @override
  String amount(String value) {
    return 'Amount: $value';
  }

  @override
  String description(String text) {
    return 'Description: $text';
  }

  @override
  String date(String value) {
    return 'Date: $value';
  }

  @override
  String groupPayments(String groupName) {
    return '$groupName Payments';
  }

  @override
  String get enterPaymentAmount => 'Enter the payment amount';

  @override
  String confirmDeletePaymentFrom(String payer, String recipient) {
    return 'Are you sure you want to delete this payment from $payer to $recipient?';
  }

  @override
  String get noPaymentsMatchCriteria => 'No payments match your criteria.';

  @override
  String get noPaymentsMatchSearch =>
      'No payments match your search criteria. Try adjusting your filters.';

  @override
  String get noPaymentsYet =>
      'No payments yet. Add your first payment to get started!';

  @override
  String get amountLabel => 'Amount *';

  @override
  String get exampleScreen => 'Example Screen';

  @override
  String get exampleScreenContent => 'Example Screen Content';

  @override
  String get welcomeBack => 'Welcome back';

  @override
  String get signInToContinue => 'Sign in to continue';

  @override
  String get forgotPassword => 'Forgot password?';

  @override
  String get orContinueWith => 'or';

  @override
  String get continueWithGoogle => 'Continue with Google';

  @override
  String get continueWithApple => 'Continue with Apple';

  @override
  String get createAccount => 'Create Account';

  @override
  String get joinGrexToday => 'Join Grex today';

  @override
  String get displayName => 'Display Name';

  @override
  String get enterYourName => 'Enter your name';

  @override
  String get enterYourEmail => 'Enter your email';

  @override
  String get enterYourPassword => 'Enter your password';

  @override
  String get selectCurrency => 'Select Currency';

  @override
  String get passwordRequirements =>
      'At least 8 characters with uppercase, lowercase, and numbers';

  @override
  String get alreadyHaveAccountSignIn => 'Already have an account? Sign in';

  @override
  String get forgotPasswordQuestion => 'Forgot Password?';

  @override
  String get enterEmailForReset =>
      'Enter your email address and we\'ll send you a link to reset your password';

  @override
  String get sendResetLink => 'Send Reset Link';

  @override
  String get resetLinkSent => 'Reset link sent! Check your email.';

  @override
  String get backToSignIn => 'Back to Sign in';

  @override
  String get verifyYourEmail => 'Verify Your Email';

  @override
  String get verificationEmailSent => 'We\'ve sent a verification email to:';

  @override
  String get checkInboxAndClick =>
      'Check your inbox and click the verification link to continue.';

  @override
  String get resendEmail => 'Resend Email';

  @override
  String get openEmailApp => 'Open Email App';

  @override
  String get didntReceiveEmail => 'Didn\'t receive the email?';

  @override
  String get checkSpamFolder => '• Check your spam or junk folder';

  @override
  String get verifyEmailAddress => '• Make sure the email address is correct';

  @override
  String get waitFewMinutes => '• Wait a few minutes and try again';

  @override
  String get signOut => 'Sign out';

  @override
  String get emailSentCheckInbox => 'Email sent! Check your inbox.';

  @override
  String pleaseWaitSeconds(int seconds) {
    return 'Please wait $seconds seconds';
  }

  @override
  String get resetPassword => 'Reset Password';

  @override
  String get enterNewPassword => 'Enter your new password below';

  @override
  String get newPassword => 'New Password';

  @override
  String get confirmPassword => 'Confirm Password';

  @override
  String get confirmYourPassword => 'Confirm your password';

  @override
  String get passwordsDoNotMatch => 'Passwords do not match';

  @override
  String get completeYourProfile => 'Complete Your Profile';

  @override
  String get stepOfTwo => 'Step 1 of 2';

  @override
  String get uploadPhoto => 'Upload Photo';

  @override
  String get completeSetup => 'Complete Setup';

  @override
  String get skipForNow => 'Skip for now';

  @override
  String get success => 'Success!';

  @override
  String get accountCreatedSuccessfully =>
      'Your account has been created successfully';

  @override
  String get passwordResetSuccessfully =>
      'Your password has been reset successfully';

  @override
  String get emailVerifiedSuccessfully =>
      'Your email has been verified successfully';

  @override
  String get continueButton => 'Continue';

  @override
  String get getStarted => 'Get Started';

  @override
  String get back => 'Back';

  @override
  String get socialAuthFailed => 'Authentication failed. Please try again.';

  @override
  String get socialAuthNetworkError =>
      'Network connection failed. Please check your internet connection and try again.';

  @override
  String get socialAuthTimeout => 'Authentication timed out. Please try again.';

  @override
  String get accountLinkingError =>
      'Failed to link your account. Please try again or contact support.';

  @override
  String get signInWithEmail => 'Sign in with email';

  @override
  String get dismiss => 'Dismiss';

  @override
  String get repeatedNetworkFailureMessage =>
      'Multiple network errors detected. Please check your internet connection or try signing in with email.';

  @override
  String get repeatedTimeoutFailureMessage =>
      'Authentication keeps timing out. Please try signing in with email instead.';

  @override
  String get repeatedAuthFailureMessage =>
      'Authentication failed multiple times. Please try signing in with email or contact support.';

  @override
  String get or => 'or';

  @override
  String get profileSetupDescription =>
      'Please complete your profile to get started with Grex';

  @override
  String get linkYourAccount => 'Link Your Account';

  @override
  String accountExistsMessage(String email) {
    return 'An account with email $email already exists.';
  }

  @override
  String linkAccountQuestion(String provider) {
    return 'Would you like to link your $provider account to your existing account?';
  }

  @override
  String get linkAccountBenefit =>
      'This will allow you to sign in with either method.';

  @override
  String get linkAccounts => 'Link Accounts';

  @override
  String get createNewAccount => 'Create New Account';

  @override
  String get cancelProfileSetup => 'Cancel Setup';

  @override
  String get cancelProfileSetupMessage =>
      'Are you sure you want to cancel? You will be signed out and need to sign in again.';

  @override
  String get continueSetup => 'Continue Setup';
}
