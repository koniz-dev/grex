// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'Grex';

  @override
  String get welcome => 'مرحباً بك في Grex مع Clean Architecture!';

  @override
  String get featureFlagsReady => 'نظام Feature Flags جاهز!';

  @override
  String get checkExamples =>
      'تحقق من الأمثلة في feature_flags_example_screen.dart';

  @override
  String get login => 'تسجيل الدخول';

  @override
  String get register => 'التسجيل';

  @override
  String get email => 'البريد الإلكتروني';

  @override
  String get password => 'كلمة المرور';

  @override
  String get name => 'الاسم';

  @override
  String get emailRequired => 'يرجى إدخال بريدك الإلكتروني';

  @override
  String get emailInvalid => 'يرجى إدخال عنوان بريد إلكتروني صحيح';

  @override
  String get passwordRequired => 'يرجى إدخال كلمة المرور';

  @override
  String passwordMinLength(int minLength) {
    return 'يجب أن تكون كلمة المرور على الأقل $minLength أحرف';
  }

  @override
  String get nameRequired => 'يرجى إدخال اسمك';

  @override
  String nameMinLength(int minLength) {
    return 'يجب أن يكون الاسم على الأقل $minLength أحرف';
  }

  @override
  String get dontHaveAccount => 'ليس لديك حساب؟ سجل';

  @override
  String get alreadyHaveAccount => 'هل لديك حساب بالفعل؟ سجل الدخول';

  @override
  String get retry => 'إعادة المحاولة';

  @override
  String get error => 'خطأ';

  @override
  String get loading => 'جاري التحميل...';

  @override
  String get language => 'اللغة';

  @override
  String get selectLanguage => 'اختر اللغة';

  @override
  String get english => 'الإنجليزية';

  @override
  String get spanish => 'الإسبانية';

  @override
  String get arabic => 'العربية';

  @override
  String get vietnamese => 'الفيتنامية';

  @override
  String get featureFlagsDebug => 'تصحيح Feature Flags';

  @override
  String get unexpectedError => 'حدث خطأ غير متوقع';

  @override
  String get badRequest => 'طلب غير صحيح. يرجى التحقق من المدخلات.';

  @override
  String get unauthorized => 'غير مصرح. يرجى تسجيل الدخول مرة أخرى.';

  @override
  String get forbidden => 'ممنوع. ليس لديك إذن.';

  @override
  String get notFound => 'المورد غير موجود.';

  @override
  String get conflict => 'تعارض. المورد موجود بالفعل.';

  @override
  String get validationError => 'خطأ في التحقق. يرجى التحقق من المدخلات.';

  @override
  String get tooManyRequests => 'طلبات كثيرة جداً. يرجى المحاولة لاحقاً.';

  @override
  String get internalServerError =>
      'خطأ داخلي في الخادم. يرجى المحاولة لاحقاً.';

  @override
  String get badGateway => 'بوابة غير صحيحة. يرجى المحاولة لاحقاً.';

  @override
  String get serviceUnavailable => 'الخدمة غير متاحة. يرجى المحاولة لاحقاً.';

  @override
  String get gatewayTimeout => 'انتهت مهلة البوابة. يرجى المحاولة لاحقاً.';

  @override
  String get clientError => 'حدث خطأ في العميل.';

  @override
  String get serverError => 'حدث خطأ في الخادم. يرجى المحاولة لاحقاً.';

  @override
  String itemCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count عناصر',
      one: 'عنصر واحد',
      zero: 'لا توجد عناصر',
    );
    return '$_temp0';
  }

  @override
  String minutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'منذ $count دقائق',
      one: 'منذ دقيقة واحدة',
      zero: 'الآن',
    );
    return '$_temp0';
  }

  @override
  String get edit => 'تعديل';

  @override
  String get delete => 'حذف';

  @override
  String get save => 'حفظ';

  @override
  String get cancel => 'إلغاء';

  @override
  String get add => 'إضافة';

  @override
  String get refresh => 'تحديث';

  @override
  String get noItemsFound => 'لم يتم العثور على عناصر';

  @override
  String get loadMore => 'تحميل المزيد';

  @override
  String get copyError => 'نسخ الخطأ';

  @override
  String get restart => 'إعادة التشغيل';

  @override
  String get errorOccurred => 'حدث خطأ غير متوقع';

  @override
  String get errorDescription =>
      'واجه التطبيق خطأ لا يمكن معالجته. لقد سجلنا هذا الخطأ وسنقوم بإصلاحه في الإصدار القادم.';

  @override
  String get errorDetails => 'تفاصيل الخطأ:';

  @override
  String get copyErrorSuccess => 'تم نسخ تفاصيل الخطأ';

  @override
  String get contactSupport => 'إذا استمر الخطأ، يرجى الاتصال بالدعم الفني.';

  @override
  String get close => 'إغلاق';

  @override
  String get pageNotFound => 'الصفحة غير موجودة';

  @override
  String get goToGroups => 'الذهاب إلى المجموعات';

  @override
  String get addPayment => 'إضافة دفعة';

  @override
  String get createPayment => 'إنشاء دفعة';

  @override
  String get paymentCreatedSuccess => 'تم إنشاء الدفعة بنجاح';

  @override
  String get selectPayer => 'يرجى اختيار من قام بالدفع';

  @override
  String get selectRecipient => 'يرجى اختيار من استلم الدفعة';

  @override
  String get payerRecipientSame => 'لا يمكن أن يكون الدافع والمستلم نفس الشخص';

  @override
  String get paymentDetails => 'تفاصيل الدفعة';

  @override
  String get deletePayment => 'حذف الدفعة';

  @override
  String get confirmDeletePayment => 'هل أنت متأكد أنك تريد حذف هذه الدفعة؟';

  @override
  String get addFirstPayment => 'إضافة أول دفعة';

  @override
  String get clearAll => 'مسح الكل';

  @override
  String get ascendingOrder => 'ترتيب تصاعدي';

  @override
  String get apply => 'تطبيق';

  @override
  String get minAmountNegative => 'لا يمكن أن يكون الحد الأدنى للمبلغ سالباً';

  @override
  String get maxAmountNegative => 'لا يمكن أن يكون الحد الأقصى للمبلغ سالباً';

  @override
  String get minGreaterThanMax =>
      'لا يمكن أن يكون الحد الأدنى للمبلغ أكبر من الحد الأقصى';

  @override
  String get startAfterEnd => 'لا يمكن أن يكون تاريخ البدء بعد تاريخ الانتهاء';

  @override
  String get createNewGroup => 'إنشاء مجموعة جديدة';

  @override
  String get featureFlagsDebugTitle => 'تصحيح Feature Flags';

  @override
  String get clearAllOverrides => 'مسح جميع التجاوزات';

  @override
  String get confirmClearOverrides =>
      'هل أنت متأكد أنك تريد مسح جميع التجاوزات المحلية؟';

  @override
  String get clear => 'مسح';

  @override
  String get overridesCleared => 'تم مسح جميع التجاوزات المحلية';

  @override
  String get noFeatureFlags => 'لم يتم العثور على feature flags';

  @override
  String get featureFlagsExamples => 'أمثلة Feature Flags';

  @override
  String get newFeatureEnabled => 'الميزة الجديدة مُفعّلة';

  @override
  String get newFeatureDisabled => 'الميزة الجديدة مُعطّلة';

  @override
  String get noPayments => 'لا توجد مدفوعات';

  @override
  String get paymentSummary => 'ملخص المدفوعات';

  @override
  String get totalPayments => 'إجمالي المدفوعات';

  @override
  String get totalAmount => 'المبلغ الإجمالي';

  @override
  String get errorLoadingPayments => 'خطأ في تحميل المدفوعات';

  @override
  String get filterPayments => 'تصفية المدفوعات';

  @override
  String get clearFilters => 'مسح الفلاتر';

  @override
  String get filterAndSortPayments => 'تصفية وترتيب المدفوعات';

  @override
  String get dateRange => 'نطاق التاريخ';

  @override
  String get amountRange => 'نطاق المبلغ';

  @override
  String get sortBy => 'ترتيب حسب';

  @override
  String get startDate => 'تاريخ البدء';

  @override
  String get endDate => 'تاريخ الانتهاء';

  @override
  String get minAmount => 'الحد الأدنى للمبلغ';

  @override
  String get maxAmount => 'الحد الأقصى للمبلغ';

  @override
  String get selectDate => 'اختر التاريخ';

  @override
  String get oldestToNewest => 'من الأقدم إلى الأحدث';

  @override
  String get newestToOldest => 'من الأحدث إلى الأقدم';

  @override
  String get amountRequired => 'المبلغ مطلوب';

  @override
  String get enterValidPositiveAmount => 'أدخل مبلغاً موجباً صحيحاً';

  @override
  String get currency => 'العملة';

  @override
  String get descriptionOptional => 'الوصف (اختياري)';

  @override
  String get whatWasPaymentFor => 'ما الغرض من هذه الدفعة؟';

  @override
  String get paymentDate => 'تاريخ الدفع';

  @override
  String get paymentParticipants => 'المشاركون في الدفع';

  @override
  String get whoPaid => 'من دفع؟ *';

  @override
  String get whoReceivedPayment => 'من استلم الدفعة؟ *';

  @override
  String get cannotPaySelf =>
      'لا يمكن للشخص أن يدفع لنفسه. يرجى اختيار دافع ومستلم مختلفين.';

  @override
  String from(String name) {
    return 'من: $name';
  }

  @override
  String to(String name) {
    return 'إلى: $name';
  }

  @override
  String amount(String value) {
    return 'المبلغ: $value';
  }

  @override
  String description(String text) {
    return 'الوصف: $text';
  }

  @override
  String date(String value) {
    return 'التاريخ: $value';
  }

  @override
  String groupPayments(String groupName) {
    return 'مدفوعات $groupName';
  }

  @override
  String get enterPaymentAmount => 'أدخل مبلغ الدفع';

  @override
  String confirmDeletePaymentFrom(String payer, String recipient) {
    return 'هل أنت متأكد أنك تريد حذف هذه الدفعة من $payer إلى $recipient؟';
  }

  @override
  String get noPaymentsMatchCriteria => 'لا توجد مدفوعات تطابق معاييرك.';

  @override
  String get noPaymentsMatchSearch =>
      'لا توجد مدفوعات تطابق معايير البحث. حاول تعديل الفلاتر.';

  @override
  String get noPaymentsYet => 'لا توجد مدفوعات بعد. أضف أول دفعة للبدء!';

  @override
  String get amountLabel => 'المبلغ *';

  @override
  String get exampleScreen => 'شاشة المثال';

  @override
  String get exampleScreenContent => 'محتوى شاشة المثال';

  @override
  String get welcomeBack => 'Welcome back';

  @override
  String get signInToContinue => 'Sign in to continue';

  @override
  String get forgotPassword => 'Forgot password?';

  @override
  String get orContinueWith => 'or';

  @override
  String get continueWithGoogle => 'المتابعة مع Google';

  @override
  String get continueWithApple => 'المتابعة مع Apple';

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
  String get completeYourProfile => 'أكمل ملفك الشخصي';

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
  String get socialAuthFailed => 'فشل في المصادقة. يرجى المحاولة مرة أخرى.';

  @override
  String get socialAuthNetworkError =>
      'فشل في الاتصال بالشبكة. يرجى التحقق من اتصالك بالإنترنت والمحاولة مرة أخرى.';

  @override
  String get socialAuthTimeout =>
      'انتهت مهلة المصادقة. يرجى المحاولة مرة أخرى.';

  @override
  String get accountLinkingError =>
      'فشل في ربط حسابك. يرجى المحاولة مرة أخرى أو الاتصال بالدعم.';

  @override
  String get signInWithEmail => 'تسجيل الدخول بالبريد الإلكتروني';

  @override
  String get dismiss => 'إغلاق';

  @override
  String get repeatedNetworkFailureMessage =>
      'تم اكتشاف أخطاء شبكة متعددة. يرجى التحقق من اتصال الإنترنت أو المحاولة باستخدام البريد الإلكتروني.';

  @override
  String get repeatedTimeoutFailureMessage =>
      'تستمر المصادقة في انتهاء المهلة. يرجى المحاولة باستخدام البريد الإلكتروني.';

  @override
  String get repeatedAuthFailureMessage =>
      'فشلت المصادقة عدة مرات. يرجى المحاولة باستخدام البريد الإلكتروني أو الاتصال بالدعم.';

  @override
  String get or => 'أو';

  @override
  String get profileSetupDescription =>
      'يرجى إكمال ملفك الشخصي للبدء في استخدام Grex';

  @override
  String get linkYourAccount => 'ربط حسابك';

  @override
  String accountExistsMessage(String email) {
    return 'يوجد حساب بالبريد الإلكتروني $email بالفعل.';
  }

  @override
  String linkAccountQuestion(String provider) {
    return 'هل تريد ربط حساب $provider الخاص بك بحسابك الحالي؟';
  }

  @override
  String get linkAccountBenefit =>
      'سيسمح لك هذا بتسجيل الدخول بأي من الطريقتين.';

  @override
  String get linkAccounts => 'ربط الحسابات';

  @override
  String get createNewAccount => 'إنشاء حساب جديد';

  @override
  String get cancelProfileSetup => 'إلغاء الإعداد';

  @override
  String get cancelProfileSetupMessage =>
      'هل أنت متأكد أنك تريد الإلغاء؟ سيتم تسجيل خروجك وستحتاج إلى تسجيل الدخول مرة أخرى.';

  @override
  String get continueSetup => 'متابعة الإعداد';

  @override
  String get signingIn => 'جاري تسجيل الدخول...';

  @override
  String get registerAccount => 'إنشاء حساب';

  @override
  String get joinGrexExpenseShare => 'انضم إلى Grex لبدء مشاركة المصاريف';

  @override
  String get registering => 'جاري إنشاء الحساب...';

  @override
  String get displayNameRequired => 'الرجاء إدخال الاسم المعروض';

  @override
  String get displayNameEmpty => 'لا يمكن أن يكون الاسم فارغًا';

  @override
  String get displayNameTooLong => 'يجب أن يكون الاسم 50 حرفًا أو أقل';

  @override
  String get preferredCurrencyLabel => 'العملة المفضلة';

  @override
  String get passwordHintShort => '8 أحرف على الأقل';

  @override
  String get yourNameHint => 'اسمك';

  @override
  String get passwordHint =>
      'يجب أن تحتوي على 8 أحرف على الأقل مع أحرف كبيرة وصغيرة وأرقام';

  @override
  String get alreadyHaveAccountPrefix => 'هل لديك حساب بالفعل؟ ';

  @override
  String get signIn => 'تسجيل الدخول';

  @override
  String get forgotPasswordTitle => 'هل نسيت كلمة المرور';

  @override
  String get enterEmailForResetShort =>
      'أدخل بريدك الإلكتروني لإعادة تعيين كلمة المرور';

  @override
  String get sendResetLinkShort => 'إرسال الرابط';

  @override
  String get sending => 'جارٍ الإرسال...';

  @override
  String get resetEmailSent => 'تم إرسال بريد إعادة التعيين';

  @override
  String pleaseCheckEmailAt(String email) {
    return 'يرجى التحقق من بريدك الإلكتروني $email';
  }

  @override
  String get resend => 'إعادة الإرسال';

  @override
  String get emailNotInSystem => 'البريد الإلكتروني غير موجود في النظام';

  @override
  String get weWillSendLink => 'سنرسل إليك رابطًا لإعادة تعيين كلمة المرور';

  @override
  String get rememberPassword => 'هل تتذكر كلمة المرور؟ ';

  @override
  String get profileTitle => 'Profile';

  @override
  String get profileFullTitle => 'Your Profile';

  @override
  String get signOutConfirmTitle => 'Sign out';

  @override
  String get signOutConfirmMessage => 'Are you sure you want to sign out?';

  @override
  String get profileLoadFailed => 'Could not load your profile';

  @override
  String get noProfileData => 'No profile data';

  @override
  String get accountCreatedAt => 'Account created';

  @override
  String get lastUpdatedAt => 'Last updated';

  @override
  String get editProfile => 'Edit profile';

  @override
  String errorWithMessage(String message) {
    return 'Error: $message';
  }

  @override
  String get refreshTooltip => 'Refresh';

  @override
  String joinedAt(String date) {
    return 'Joined $date';
  }

  @override
  String get today => 'Today';

  @override
  String get yesterday => 'Yesterday';

  @override
  String daysAgo(int count) {
    return '$count days ago';
  }

  @override
  String weeksAgo(int count) {
    return '$count weeks ago';
  }

  @override
  String monthsAgo(int count) {
    return '$count months ago';
  }

  @override
  String yearsAgo(int count) {
    return '$count years ago';
  }

  @override
  String get saveChanges => 'Save changes';

  @override
  String get saving => 'Saving...';

  @override
  String get cancelChangesTitle => 'Discard changes?';

  @override
  String get unsavedChangesMessage =>
      'You have unsaved changes. Are you sure you want to cancel?';

  @override
  String get continueEditing => 'Continue editing';

  @override
  String get discardChanges => 'Discard';

  @override
  String get profileUpdatedSuccess => 'Profile updated successfully';

  @override
  String get displayNameHint => 'Enter your display name';

  @override
  String displayNameTooShort(int min) {
    return 'Display name must be at least $min characters';
  }

  @override
  String get displayNameInvalidChars =>
      'Display name contains invalid characters';

  @override
  String get editProfileNoteTitle => 'Note';

  @override
  String get editProfileTipDisplayName =>
      '• Your display name is shown to other members';

  @override
  String get editProfileTipCurrency =>
      '• Preferred currency is used as the default';

  @override
  String get editProfileTipLanguage =>
      '• Language changes apply across the whole app';
}
