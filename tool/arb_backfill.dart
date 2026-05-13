// One-shot ARB backfill: takes hand-written ar/es translations for the
// 79 keys present in app_en.arb but missing from app_ar.arb /
// app_es.arb, copies their `@<key>` metadata from app_en.arb, and
// writes both files back as formatted JSON. Run once with `dart run`,
// then verify with the ARB synchronization test.
import 'dart:convert';
import 'dart:io';

const _ar = <String, String>{
  'accountCreatedAt': 'تم إنشاء الحساب',
  'accountCreatedSuccessfully': 'تم إنشاء حسابك بنجاح',
  'alreadyHaveAccountSignIn': 'هل لديك حساب بالفعل؟ سجل الدخول',
  'back': 'رجوع',
  'backToSignIn': 'العودة إلى تسجيل الدخول',
  'cancelChangesTitle': 'تجاهل التغييرات؟',
  'checkInboxAndClick': 'تحقق من بريدك الوارد وانقر على رابط التحقق للمتابعة.',
  'checkSpamFolder': '• تحقق من مجلد الرسائل غير المرغوب فيها',
  'completeSetup': 'إكمال الإعداد',
  'confirmPassword': 'تأكيد كلمة المرور',
  'confirmYourPassword': 'أكد كلمة المرور',
  'continueButton': 'متابعة',
  'continueEditing': 'متابعة التحرير',
  'createAccount': 'إنشاء حساب',
  'daysAgo': 'منذ {count} يوم',
  'didntReceiveEmail': 'لم تستلم البريد؟',
  'discardChanges': 'تجاهل',
  'displayName': 'الاسم المعروض',
  'displayNameHint': 'أدخل اسمك المعروض',
  'displayNameInvalidChars': 'الاسم يحتوي على أحرف غير صالحة',
  'displayNameTooShort': 'يجب أن يكون الاسم على الأقل {min} حرفًا',
  'editProfile': 'تعديل الملف الشخصي',
  'editProfileNoteTitle': 'ملاحظة',
  'editProfileTipCurrency': '• العملة المفضلة تُستخدم كافتراضية',
  'editProfileTipDisplayName': '• اسمك المعروض يظهر للأعضاء الآخرين',
  'editProfileTipLanguage': '• تغييرات اللغة تنطبق على التطبيق بالكامل',
  'emailSentCheckInbox': 'تم إرسال البريد! تحقق من بريدك الوارد.',
  'emailVerifiedSuccessfully': 'تم التحقق من بريدك بنجاح',
  'enterEmailForReset':
      'أدخل بريدك الإلكتروني وسنرسل لك رابطًا لإعادة تعيين كلمة المرور',
  'enterNewPassword': 'أدخل كلمة المرور الجديدة أدناه',
  'enterYourEmail': 'أدخل بريدك الإلكتروني',
  'enterYourName': 'أدخل اسمك',
  'enterYourPassword': 'أدخل كلمة المرور',
  'errorWithMessage': 'خطأ: {message}',
  'forgotPassword': 'نسيت كلمة المرور؟',
  'forgotPasswordQuestion': 'نسيت كلمة المرور؟',
  'getStarted': 'ابدأ',
  'joinGrexToday': 'انضم إلى Grex اليوم',
  'joinedAt': 'انضم في {date}',
  'lastUpdatedAt': 'آخر تحديث',
  'monthsAgo': 'منذ {count} شهر',
  'newPassword': 'كلمة المرور الجديدة',
  'noProfileData': 'لا توجد بيانات للملف الشخصي',
  'openEmailApp': 'فتح تطبيق البريد',
  'orContinueWith': 'أو',
  'passwordRequirements': 'على الأقل 8 أحرف مع أحرف كبيرة وصغيرة وأرقام',
  'passwordResetSuccessfully': 'تمت إعادة تعيين كلمة المرور بنجاح',
  'passwordsDoNotMatch': 'كلمتا المرور غير متطابقتين',
  'pleaseWaitSeconds': 'يرجى الانتظار {seconds} ثانية',
  'profileFullTitle': 'ملفك الشخصي',
  'profileLoadFailed': 'تعذر تحميل ملفك الشخصي',
  'profileTitle': 'الملف الشخصي',
  'profileUpdatedSuccess': 'تم تحديث الملف الشخصي بنجاح',
  'refreshTooltip': 'تحديث',
  'resendEmail': 'إعادة إرسال البريد',
  'resetLinkSent': 'تم إرسال رابط إعادة التعيين! تحقق من بريدك.',
  'resetPassword': 'إعادة تعيين كلمة المرور',
  'saveChanges': 'حفظ التغييرات',
  'saving': 'جارٍ الحفظ...',
  'selectCurrency': 'اختر العملة',
  'sendResetLink': 'إرسال رابط إعادة التعيين',
  'signInToContinue': 'سجل الدخول للمتابعة',
  'signOut': 'تسجيل الخروج',
  'signOutConfirmMessage': 'هل أنت متأكد من تسجيل الخروج؟',
  'signOutConfirmTitle': 'تسجيل الخروج',
  'skipForNow': 'تخطي الآن',
  'stepOfTwo': 'الخطوة 1 من 2',
  'success': 'نجاح!',
  'today': 'اليوم',
  'unsavedChangesMessage':
      'لديك تغييرات غير محفوظة. هل أنت متأكد من الإلغاء؟',
  'uploadPhoto': 'رفع صورة',
  'verificationEmailSent': 'أرسلنا رسالة تحقق إلى:',
  'verifyEmailAddress': '• تأكد من صحة عنوان البريد',
  'verifyYourEmail': 'تحقق من بريدك',
  'waitFewMinutes': '• انتظر بضع دقائق وحاول مرة أخرى',
  'weeksAgo': 'منذ {count} أسبوع',
  'welcomeBack': 'مرحبًا بعودتك',
  'yearsAgo': 'منذ {count} سنة',
  'yesterday': 'أمس',
};

const _es = <String, String>{
  'accountCreatedAt': 'Cuenta creada',
  'accountCreatedSuccessfully': 'Tu cuenta se ha creado exitosamente',
  'alreadyHaveAccountSignIn': '¿Ya tienes una cuenta? Inicia sesión',
  'back': 'Atrás',
  'backToSignIn': 'Volver a inicio de sesión',
  'cancelChangesTitle': '¿Descartar cambios?',
  'checkInboxAndClick':
      'Revisa tu bandeja y haz clic en el enlace de verificación para continuar.',
  'checkSpamFolder': '• Revisa tu carpeta de spam o correo no deseado',
  'completeSetup': 'Completar configuración',
  'confirmPassword': 'Confirmar contraseña',
  'confirmYourPassword': 'Confirma tu contraseña',
  'continueButton': 'Continuar',
  'continueEditing': 'Continuar editando',
  'createAccount': 'Crear cuenta',
  'daysAgo': 'hace {count} días',
  'didntReceiveEmail': '¿No recibiste el correo?',
  'discardChanges': 'Descartar',
  'displayName': 'Nombre visible',
  'displayNameHint': 'Ingresa tu nombre visible',
  'displayNameInvalidChars': 'El nombre contiene caracteres no válidos',
  'displayNameTooShort': 'El nombre debe tener al menos {min} caracteres',
  'editProfile': 'Editar perfil',
  'editProfileNoteTitle': 'Nota',
  'editProfileTipCurrency':
      '• La moneda preferida se usa como predeterminada',
  'editProfileTipDisplayName':
      '• Tu nombre visible se muestra a otros miembros',
  'editProfileTipLanguage':
      '• Los cambios de idioma se aplican a toda la app',
  'emailSentCheckInbox': '¡Correo enviado! Revisa tu bandeja.',
  'emailVerifiedSuccessfully': 'Tu correo se ha verificado exitosamente',
  'enterEmailForReset':
      "Ingresa tu dirección de correo y te enviaremos un enlace para restablecer la contraseña",
  'enterNewPassword': 'Ingresa tu nueva contraseña abajo',
  'enterYourEmail': 'Ingresa tu correo',
  'enterYourName': 'Ingresa tu nombre',
  'enterYourPassword': 'Ingresa tu contraseña',
  'errorWithMessage': 'Error: {message}',
  'forgotPassword': '¿Olvidaste tu contraseña?',
  'forgotPasswordQuestion': '¿Olvidaste tu contraseña?',
  'getStarted': 'Comenzar',
  'joinGrexToday': 'Únete a Grex hoy',
  'joinedAt': 'Se unió {date}',
  'lastUpdatedAt': 'Última actualización',
  'monthsAgo': 'hace {count} meses',
  'newPassword': 'Nueva contraseña',
  'noProfileData': 'Sin datos de perfil',
  'openEmailApp': 'Abrir app de correo',
  'orContinueWith': 'o',
  'passwordRequirements':
      'Al menos 8 caracteres con mayúsculas, minúsculas y números',
  'passwordResetSuccessfully':
      'Tu contraseña se ha restablecido exitosamente',
  'passwordsDoNotMatch': 'Las contraseñas no coinciden',
  'pleaseWaitSeconds': 'Por favor espera {seconds} segundos',
  'profileFullTitle': 'Tu perfil',
  'profileLoadFailed': 'No se pudo cargar el perfil',
  'profileTitle': 'Perfil',
  'profileUpdatedSuccess': 'Perfil actualizado exitosamente',
  'refreshTooltip': 'Actualizar',
  'resendEmail': 'Reenviar correo',
  'resetLinkSent': '¡Enlace de restablecimiento enviado! Revisa tu correo.',
  'resetPassword': 'Restablecer contraseña',
  'saveChanges': 'Guardar cambios',
  'saving': 'Guardando...',
  'selectCurrency': 'Seleccionar moneda',
  'sendResetLink': 'Enviar enlace de restablecimiento',
  'signInToContinue': 'Inicia sesión para continuar',
  'signOut': 'Cerrar sesión',
  'signOutConfirmMessage': '¿Estás seguro de que quieres cerrar sesión?',
  'signOutConfirmTitle': 'Cerrar sesión',
  'skipForNow': 'Omitir por ahora',
  'stepOfTwo': 'Paso 1 de 2',
  'success': '¡Éxito!',
  'today': 'Hoy',
  'unsavedChangesMessage':
      'Tienes cambios sin guardar. ¿Seguro que quieres cancelar?',
  'uploadPhoto': 'Subir foto',
  'verificationEmailSent': 'Hemos enviado un correo de verificación a:',
  'verifyEmailAddress': '• Asegúrate de que la dirección de correo sea correcta',
  'verifyYourEmail': 'Verifica tu correo',
  'waitFewMinutes': '• Espera unos minutos e intenta de nuevo',
  'weeksAgo': 'hace {count} semanas',
  'welcomeBack': 'Bienvenido de nuevo',
  'yearsAgo': 'hace {count} años',
  'yesterday': 'Ayer',
};

void main() {
  final en = json.decode(File('lib/l10n/app_en.arb').readAsStringSync())
      as Map<String, dynamic>;

  for (final locale in ['ar', 'es']) {
    final path = 'lib/l10n/app_$locale.arb';
    final arb =
        json.decode(File(path).readAsStringSync()) as Map<String, dynamic>;
    final translations = locale == 'ar' ? _ar : _es;

    for (final entry in translations.entries) {
      arb[entry.key] = entry.value;
      // Copy metadata from English if present.
      final metaKey = '@${entry.key}';
      if (en.containsKey(metaKey)) {
        arb[metaKey] = en[metaKey];
      }
    }

    final encoder = const JsonEncoder.withIndent('  ');
    File(path).writeAsStringSync('${encoder.convert(arb)}\n');
    print('Wrote $path (${arb.length ~/ 2} keys)');
  }
}
