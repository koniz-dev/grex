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
}
