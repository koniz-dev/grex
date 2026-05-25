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
  String get appTagline => 'قسّم النفقات بسهولة';

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
  String get dontHaveAccount => 'ليس لديك حساب؟';

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
  String get welcomeBack => 'مرحبًا بعودتك';

  @override
  String get signInToContinue => 'سجل الدخول للمتابعة';

  @override
  String get forgotPassword => 'نسيت كلمة المرور؟';

  @override
  String get orContinueWith => 'أو';

  @override
  String get continueWithGoogle => 'المتابعة مع Google';

  @override
  String get continueWithApple => 'المتابعة مع Apple';

  @override
  String get createAccount => 'إنشاء حساب';

  @override
  String get joinGrexToday => 'انضم إلى Grex اليوم';

  @override
  String get displayName => 'الاسم المعروض';

  @override
  String get enterYourName => 'أدخل اسمك';

  @override
  String get enterYourEmail => 'أدخل بريدك الإلكتروني';

  @override
  String get enterYourPassword => 'أدخل كلمة المرور';

  @override
  String get selectCurrency => 'اختر العملة';

  @override
  String get passwordRequirements =>
      'على الأقل 8 أحرف مع أحرف كبيرة وصغيرة وأرقام';

  @override
  String get pwdReqLength => 'At least 8 characters';

  @override
  String get pwdReqUppercase => 'At least 1 uppercase letter';

  @override
  String get pwdReqNumber => 'At least 1 number';

  @override
  String get pwdReqSpecial => 'At least 1 special character';

  @override
  String get alreadyHaveAccountSignIn => 'هل لديك حساب بالفعل؟ سجل الدخول';

  @override
  String get forgotPasswordQuestion => 'نسيت كلمة المرور؟';

  @override
  String get enterEmailForReset =>
      'أدخل بريدك الإلكتروني وسنرسل لك رابطًا لإعادة تعيين كلمة المرور';

  @override
  String get sendResetLink => 'إرسال رابط إعادة التعيين';

  @override
  String get resetLinkSent => 'تم إرسال رابط إعادة التعيين! تحقق من بريدك.';

  @override
  String get backToSignIn => 'العودة إلى تسجيل الدخول';

  @override
  String get verifyYourEmail => 'تحقق من بريدك';

  @override
  String get verificationEmailSent => 'أرسلنا رسالة تحقق إلى:';

  @override
  String get checkInboxAndClick =>
      'تحقق من بريدك الوارد وانقر على رابط التحقق للمتابعة.';

  @override
  String get resendEmail => 'إعادة إرسال البريد';

  @override
  String get openEmailApp => 'فتح تطبيق البريد';

  @override
  String get didntReceiveEmail => 'لم تستلم البريد؟';

  @override
  String get checkSpamFolder => '• تحقق من مجلد الرسائل غير المرغوب فيها';

  @override
  String get verifyEmailAddress => '• تأكد من صحة عنوان البريد';

  @override
  String get waitFewMinutes => '• انتظر بضع دقائق وحاول مرة أخرى';

  @override
  String get signOut => 'تسجيل الخروج';

  @override
  String get emailSentCheckInbox => 'تم إرسال البريد! تحقق من بريدك الوارد.';

  @override
  String pleaseWaitSeconds(int seconds) {
    return 'يرجى الانتظار $seconds ثانية';
  }

  @override
  String get resetPassword => 'إعادة تعيين كلمة المرور';

  @override
  String get enterNewPassword => 'أدخل كلمة المرور الجديدة أدناه';

  @override
  String get newPassword => 'كلمة المرور الجديدة';

  @override
  String get confirmPassword => 'تأكيد كلمة المرور';

  @override
  String get confirmYourPassword => 'أكد كلمة المرور';

  @override
  String get passwordsDoNotMatch => 'كلمتا المرور غير متطابقتين';

  @override
  String get completeYourProfile => 'أكمل ملفك الشخصي';

  @override
  String get stepOfTwo => 'الخطوة 1 من 2';

  @override
  String get uploadPhoto => 'رفع صورة';

  @override
  String get completeSetup => 'إكمال الإعداد';

  @override
  String get skipForNow => 'تخطي الآن';

  @override
  String get success => 'نجاح!';

  @override
  String get accountCreatedSuccessfully => 'تم إنشاء حسابك بنجاح';

  @override
  String get passwordResetSuccessfully => 'تمت إعادة تعيين كلمة المرور بنجاح';

  @override
  String get emailVerifiedSuccessfully => 'تم التحقق من بريدك بنجاح';

  @override
  String get continueButton => 'متابعة';

  @override
  String get getStarted => 'ابدأ';

  @override
  String get back => 'رجوع';

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
  String get profileTitle => 'الملف الشخصي';

  @override
  String get profileFullTitle => 'ملفك الشخصي';

  @override
  String get signOutConfirmTitle => 'تسجيل الخروج';

  @override
  String get signOutConfirmMessage => 'هل أنت متأكد من تسجيل الخروج؟';

  @override
  String get profileLoadFailed => 'تعذر تحميل ملفك الشخصي';

  @override
  String get noProfileData => 'لا توجد بيانات للملف الشخصي';

  @override
  String get accountCreatedAt => 'تم إنشاء الحساب';

  @override
  String get lastUpdatedAt => 'آخر تحديث';

  @override
  String get editProfile => 'تعديل الملف الشخصي';

  @override
  String errorWithMessage(String message) {
    return 'خطأ: $message';
  }

  @override
  String get refreshTooltip => 'تحديث';

  @override
  String joinedAt(String date) {
    return 'انضم في $date';
  }

  @override
  String get today => 'اليوم';

  @override
  String get yesterday => 'أمس';

  @override
  String daysAgo(int count) {
    return 'منذ $count يوم';
  }

  @override
  String weeksAgo(int count) {
    return 'منذ $count أسبوع';
  }

  @override
  String monthsAgo(int count) {
    return 'منذ $count شهر';
  }

  @override
  String yearsAgo(int count) {
    return 'منذ $count سنة';
  }

  @override
  String get saveChanges => 'حفظ التغييرات';

  @override
  String get saving => 'جارٍ الحفظ...';

  @override
  String get cancelChangesTitle => 'تجاهل التغييرات؟';

  @override
  String get unsavedChangesMessage =>
      'لديك تغييرات غير محفوظة. هل أنت متأكد من الإلغاء؟';

  @override
  String get continueEditing => 'متابعة التحرير';

  @override
  String get discardChanges => 'تجاهل';

  @override
  String get profileUpdatedSuccess => 'تم تحديث الملف الشخصي بنجاح';

  @override
  String get displayNameHint => 'أدخل اسمك المعروض';

  @override
  String displayNameTooShort(int min) {
    return 'يجب أن يكون الاسم على الأقل $min حرفًا';
  }

  @override
  String get displayNameInvalidChars => 'الاسم يحتوي على أحرف غير صالحة';

  @override
  String get editProfileNoteTitle => 'ملاحظة';

  @override
  String get editProfileTipDisplayName => '• اسمك المعروض يظهر للأعضاء الآخرين';

  @override
  String get editProfileTipCurrency => '• العملة المفضلة تُستخدم كافتراضية';

  @override
  String get editProfileTipLanguage =>
      '• تغييرات اللغة تنطبق على التطبيق بالكامل';

  @override
  String get reenterPassword => 'أعد إدخال كلمة المرور';

  @override
  String get currencyRequired => 'يرجى اختيار عملة';

  @override
  String get languageRequired => 'يرجى اختيار لغة';

  @override
  String get myGroups => 'مجموعاتي';

  @override
  String get noGroupsTitle => 'لا توجد مجموعات بعد';

  @override
  String get noGroupsDescription =>
      'أنشئ مجموعتك الأولى لبدء تقسيم النفقات مع الأصدقاء والعائلة.';

  @override
  String get somethingWentWrong => 'حدث خطأ ما';

  @override
  String get couldNotLoadGroups =>
      'تعذر تحميل مجموعاتك. تحقق من اتصالك وحاول مرة أخرى.';

  @override
  String membersCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count عضو',
      many: '$count عضواً',
      few: '$count أعضاء',
      two: 'عضوان',
      one: 'عضو واحد',
      zero: 'لا يوجد أعضاء',
    );
    return '$_temp0';
  }

  @override
  String expensesPageTitle(String groupName) {
    return 'نفقات $groupName';
  }

  @override
  String get expensesSearchHint => 'ابحث في النفقات…';

  @override
  String get filterExpenses => 'تصفية النفقات';

  @override
  String get addExpense => 'إضافة نفقة';

  @override
  String get noExpensesTitle => 'لا توجد نفقات بعد';

  @override
  String get noExpensesDescription =>
      'ابدأ بتتبع نفقات المجموعة بإضافة أول نفقة.';

  @override
  String get noExpensesMatchFilters =>
      'لا توجد نفقات تطابق عوامل التصفية. حاول توسيع المعايير.';

  @override
  String get addFirstExpense => 'أضف أول نفقة';

  @override
  String get couldNotLoadExpenses =>
      'تعذر تحميل النفقات. تحقق من اتصالك وحاول مرة أخرى.';

  @override
  String paidByPerson(String name) {
    return 'دفع بواسطة $name';
  }

  @override
  String participantsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count مشارك',
      many: '$count مشاركاً',
      few: '$count مشاركين',
      two: 'مشاركان',
      one: 'مشارك واحد',
      zero: 'لا يوجد مشاركون',
    );
    return '$_temp0';
  }

  @override
  String get invalidSplit => 'تقسيم غير صالح';

  @override
  String get validSplit => 'صالح';

  @override
  String groupCurrencyLabel(String currency) {
    return 'المجموعة: $currency';
  }

  @override
  String balancesPageTitle(String groupName) {
    return 'أرصدة $groupName';
  }

  @override
  String get refreshBalances => 'تحديث الأرصدة';

  @override
  String get couldNotLoadBalances =>
      'تعذر تحميل الأرصدة. تحقق من اتصالك وحاول مرة أخرى.';

  @override
  String get memberBalances => 'أرصدة الأعضاء';

  @override
  String get settleUp => 'تسوية';

  @override
  String get balanceAmountLabel => 'الرصيد';

  @override
  String get viewSettlementPlan => 'عرض خطة التسوية';

  @override
  String get balanceStatusOwes => 'مدين للمجموعة';

  @override
  String get balanceStatusOwed => 'للمجموعة دَين عليه';

  @override
  String get balanceStatusSettled => 'تمت التسوية';

  @override
  String get balanceBadgeOwes => 'مدين';

  @override
  String get balanceBadgeOwed => 'دائن';

  @override
  String get balanceBadgeSettled => 'متوازن';

  @override
  String get noBalancesTitle => 'لا توجد أرصدة بعد';

  @override
  String get noBalancesDescription =>
      'ستظهر الأرصدة هنا بمجرد إضافة النفقات والمدفوعات إلى المجموعة.';

  @override
  String get balancesAutoExplainer =>
      'تُحسب الأرصدة تلقائياً من نفقات ومدفوعات المجموعة.';

  @override
  String get addExpenses => 'إضافة نفقات';

  @override
  String get recordPayments => 'تسجيل المدفوعات';

  @override
  String get balanceSummary => 'ملخص الأرصدة';

  @override
  String get totalOwed => 'إجمالي المستحق';

  @override
  String get totalOwes => 'إجمالي الدَين';

  @override
  String get settledStat => 'تمت التسوية';

  @override
  String get unsettledStat => 'غير مسوّى';

  @override
  String get generateSettlementPlan => 'إنشاء خطة تسوية';

  @override
  String get allMembersSettledUp => 'جميع الأعضاء في حالة توازن!';

  @override
  String get couldNotLoadPayments =>
      'تعذر تحميل المدفوعات. تحقق من اتصالك وحاول مرة أخرى.';

  @override
  String get deletePaymentTooltip => 'حذف الدفعة';
}
