// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Grex';

  @override
  String get appTagline => 'Divide gastos con facilidad';

  @override
  String get welcome => '¡Bienvenido a Grex con Arquitectura Limpia!';

  @override
  String get featureFlagsReady => '¡El Sistema de Feature Flags está listo!';

  @override
  String get checkExamples =>
      'Consulta los ejemplos en feature_flags_example_screen.dart';

  @override
  String get login => 'Iniciar sesión';

  @override
  String get register => 'Registrarse';

  @override
  String get email => 'Correo electrónico';

  @override
  String get password => 'Contraseña';

  @override
  String get name => 'Nombre';

  @override
  String get emailRequired => 'Por favor ingresa tu correo electrónico';

  @override
  String get emailInvalid => 'Por favor ingresa un correo electrónico válido';

  @override
  String get passwordRequired => 'Por favor ingresa tu contraseña';

  @override
  String passwordMinLength(int minLength) {
    return 'La contraseña debe tener al menos $minLength caracteres';
  }

  @override
  String get nameRequired => 'Por favor ingresa tu nombre';

  @override
  String nameMinLength(int minLength) {
    return 'El nombre debe tener al menos $minLength caracteres';
  }

  @override
  String get dontHaveAccount => '¿No tienes una cuenta?';

  @override
  String get alreadyHaveAccount => '¿Ya tienes una cuenta? Inicia sesión';

  @override
  String get retry => 'Reintentar';

  @override
  String get error => 'Error';

  @override
  String get loading => 'Cargando...';

  @override
  String get language => 'Idioma';

  @override
  String get selectLanguage => 'Seleccionar idioma';

  @override
  String get english => 'Inglés';

  @override
  String get spanish => 'Español';

  @override
  String get arabic => 'Árabe';

  @override
  String get vietnamese => 'Vietnamita';

  @override
  String get featureFlagsDebug => 'Depuración de Feature Flags';

  @override
  String get unexpectedError => 'Ocurrió un error inesperado';

  @override
  String get badRequest =>
      'Solicitud incorrecta. Por favor verifica tu entrada.';

  @override
  String get unauthorized =>
      'No autorizado. Por favor inicia sesión nuevamente.';

  @override
  String get forbidden => 'Prohibido. No tienes permiso.';

  @override
  String get notFound => 'Recurso no encontrado.';

  @override
  String get conflict => 'Conflicto. El recurso ya existe.';

  @override
  String get validationError =>
      'Error de validación. Por favor verifica tu entrada.';

  @override
  String get tooManyRequests =>
      'Demasiadas solicitudes. Por favor intenta más tarde.';

  @override
  String get internalServerError =>
      'Error interno del servidor. Por favor intenta más tarde.';

  @override
  String get badGateway =>
      'Puerta de enlace incorrecta. Por favor intenta más tarde.';

  @override
  String get serviceUnavailable =>
      'Servicio no disponible. Por favor intenta más tarde.';

  @override
  String get gatewayTimeout =>
      'Tiempo de espera de puerta de enlace agotado. Por favor intenta más tarde.';

  @override
  String get clientError => 'Ocurrió un error del cliente.';

  @override
  String get serverError =>
      'Ocurrió un error del servidor. Por favor intenta más tarde.';

  @override
  String itemCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count elementos',
      one: '1 elemento',
      zero: 'Sin elementos',
    );
    return '$_temp0';
  }

  @override
  String minutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Hace $count minutos',
      one: 'Hace 1 minuto',
      zero: 'Ahora mismo',
    );
    return '$_temp0';
  }

  @override
  String get edit => 'Editar';

  @override
  String get delete => 'Eliminar';

  @override
  String get save => 'Guardar';

  @override
  String get cancel => 'Cancelar';

  @override
  String get add => 'Agregar';

  @override
  String get refresh => 'Actualizar';

  @override
  String get noItemsFound => 'No se encontraron elementos';

  @override
  String get loadMore => 'Cargar más';

  @override
  String get copyError => 'Copiar error';

  @override
  String get restart => 'Reiniciar';

  @override
  String get errorOccurred => 'Ocurrió un error inesperado';

  @override
  String get errorDescription =>
      'La aplicación encontró un error que no pudo ser manejado. Hemos registrado este error y lo corregiremos en la próxima versión.';

  @override
  String get errorDetails => 'Detalles del error:';

  @override
  String get copyErrorSuccess => 'Detalles del error copiados';

  @override
  String get contactSupport =>
      'Si el error persiste, por favor contacte al soporte técnico.';

  @override
  String get close => 'Cerrar';

  @override
  String get pageNotFound => 'Página no encontrada';

  @override
  String get goToGroups => 'Ir a Grupos';

  @override
  String get addPayment => 'Agregar pago';

  @override
  String get createPayment => 'Crear pago';

  @override
  String get paymentCreatedSuccess => 'Pago creado exitosamente';

  @override
  String get selectPayer => 'Por favor selecciona quién realizó el pago';

  @override
  String get selectRecipient => 'Por favor selecciona quién recibió el pago';

  @override
  String get payerRecipientSame =>
      'El pagador y el receptor no pueden ser la misma persona';

  @override
  String get paymentDetails => 'Detalles del pago';

  @override
  String get deletePayment => 'Eliminar pago';

  @override
  String get confirmDeletePayment =>
      '¿Estás seguro de que deseas eliminar este pago?';

  @override
  String get addFirstPayment => 'Agregar primer pago';

  @override
  String get clearAll => 'Limpiar todo';

  @override
  String get ascendingOrder => 'Orden ascendente';

  @override
  String get apply => 'Aplicar';

  @override
  String get minAmountNegative => 'El monto mínimo no puede ser negativo';

  @override
  String get maxAmountNegative => 'El monto máximo no puede ser negativo';

  @override
  String get minGreaterThanMax =>
      'El monto mínimo no puede ser mayor que el monto máximo';

  @override
  String get startAfterEnd =>
      'La fecha de inicio no puede ser posterior a la fecha de fin';

  @override
  String get createNewGroup => 'Crear nuevo grupo';

  @override
  String get featureFlagsDebugTitle => 'Depuración de Feature Flags';

  @override
  String get clearAllOverrides => 'Limpiar todas las anulaciones';

  @override
  String get confirmClearOverrides =>
      '¿Estás seguro de que deseas limpiar todas las anulaciones locales?';

  @override
  String get clear => 'Limpiar';

  @override
  String get overridesCleared =>
      'Todas las anulaciones locales han sido limpiadas';

  @override
  String get noFeatureFlags => 'No se encontraron feature flags';

  @override
  String get featureFlagsExamples => 'Ejemplos de Feature Flags';

  @override
  String get newFeatureEnabled => 'Nueva función HABILITADA';

  @override
  String get newFeatureDisabled => 'Nueva función DESHABILITADA';

  @override
  String get noPayments => 'Sin pagos';

  @override
  String get paymentSummary => 'Resumen de pagos';

  @override
  String get totalPayments => 'Total de pagos';

  @override
  String get totalAmount => 'Monto total';

  @override
  String get errorLoadingPayments => 'Error al cargar pagos';

  @override
  String get filterPayments => 'Filtrar pagos';

  @override
  String get clearFilters => 'Limpiar filtros';

  @override
  String get filterAndSortPayments => 'Filtrar y ordenar pagos';

  @override
  String get dateRange => 'Rango de fechas';

  @override
  String get amountRange => 'Rango de montos';

  @override
  String get sortBy => 'Ordenar por';

  @override
  String get startDate => 'Fecha de inicio';

  @override
  String get endDate => 'Fecha de fin';

  @override
  String get minAmount => 'Monto mínimo';

  @override
  String get maxAmount => 'Monto máximo';

  @override
  String get selectDate => 'Seleccionar fecha';

  @override
  String get oldestToNewest => 'Más antiguo a más reciente';

  @override
  String get newestToOldest => 'Más reciente a más antiguo';

  @override
  String get amountRequired => 'El monto es requerido';

  @override
  String get enterValidPositiveAmount => 'Ingresa un monto positivo válido';

  @override
  String get currency => 'Moneda';

  @override
  String get descriptionOptional => 'Descripción (Opcional)';

  @override
  String get whatWasPaymentFor => '¿Para qué fue este pago?';

  @override
  String get paymentDate => 'Fecha de pago';

  @override
  String get paymentParticipants => 'Participantes del pago';

  @override
  String get whoPaid => '¿Quién pagó? *';

  @override
  String get whoReceivedPayment => '¿Quién recibió el pago? *';

  @override
  String get cannotPaySelf =>
      'Una persona no puede pagarse a sí misma. Por favor selecciona diferentes pagador y receptor.';

  @override
  String from(String name) {
    return 'De: $name';
  }

  @override
  String to(String name) {
    return 'Para: $name';
  }

  @override
  String amount(String value) {
    return 'Monto: $value';
  }

  @override
  String description(String text) {
    return 'Descripción: $text';
  }

  @override
  String date(String value) {
    return 'Fecha: $value';
  }

  @override
  String groupPayments(String groupName) {
    return 'Pagos de $groupName';
  }

  @override
  String get enterPaymentAmount => 'Ingresa el monto del pago';

  @override
  String confirmDeletePaymentFrom(String payer, String recipient) {
    return '¿Estás seguro de que deseas eliminar este pago de $payer a $recipient?';
  }

  @override
  String get noPaymentsMatchSearch =>
      'Ningún pago coincide con tus criterios de búsqueda. Intenta ajustar los filtros.';

  @override
  String get noPaymentsYet =>
      'Aún no hay pagos. ¡Agrega tu primer pago para comenzar!';

  @override
  String get amountLabel => 'Monto *';

  @override
  String get exampleScreen => 'Pantalla de ejemplo';

  @override
  String get exampleScreenContent => 'Contenido de pantalla de ejemplo';

  @override
  String get welcomeBack => 'Bienvenido de nuevo';

  @override
  String get signInToContinue => 'Inicia sesión para continuar';

  @override
  String get forgotPassword => '¿Olvidaste tu contraseña?';

  @override
  String get orContinueWith => 'o';

  @override
  String get continueWithGoogle => 'Continuar con Google';

  @override
  String get continueWithApple => 'Continuar con Apple';

  @override
  String get createAccount => 'Crear cuenta';

  @override
  String get joinGrexToday => 'Únete a Grex hoy';

  @override
  String get displayName => 'Nombre visible';

  @override
  String get enterYourName => 'Ingresa tu nombre';

  @override
  String get enterYourEmail => 'Ingresa tu correo';

  @override
  String get enterYourPassword => 'Ingresa tu contraseña';

  @override
  String get selectCurrency => 'Seleccionar moneda';

  @override
  String get passwordRequirements =>
      'Al menos 8 caracteres con mayúsculas, minúsculas y números';

  @override
  String get pwdReqLength => 'Al menos 8 caracteres';

  @override
  String get pwdReqUppercase => 'Al menos 1 letra mayúscula';

  @override
  String get pwdReqNumber => 'Al menos 1 número';

  @override
  String get pwdReqSpecial => 'Al menos 1 carácter especial';

  @override
  String get alreadyHaveAccountSignIn => '¿Ya tienes una cuenta? Inicia sesión';

  @override
  String get forgotPasswordQuestion => '¿Olvidaste tu contraseña?';

  @override
  String get enterEmailForReset =>
      'Ingresa tu dirección de correo y te enviaremos un enlace para restablecer la contraseña';

  @override
  String get sendResetLink => 'Enviar enlace de restablecimiento';

  @override
  String get resetLinkSent =>
      '¡Enlace de restablecimiento enviado! Revisa tu correo.';

  @override
  String get backToSignIn => 'Volver a inicio de sesión';

  @override
  String get verifyYourEmail => 'Verifica tu correo';

  @override
  String get verificationEmailSent =>
      'Hemos enviado un correo de verificación a:';

  @override
  String get checkInboxAndClick =>
      'Revisa tu bandeja y haz clic en el enlace de verificación para continuar.';

  @override
  String get resendEmail => 'Reenviar correo';

  @override
  String get openEmailApp => 'Abrir app de correo';

  @override
  String get didntReceiveEmail => '¿No recibiste el correo?';

  @override
  String get checkSpamFolder =>
      '• Revisa tu carpeta de spam o correo no deseado';

  @override
  String get verifyEmailAddress =>
      '• Asegúrate de que la dirección de correo sea correcta';

  @override
  String get waitFewMinutes => '• Espera unos minutos e intenta de nuevo';

  @override
  String get signOut => 'Cerrar sesión';

  @override
  String get emailSentCheckInbox => '¡Correo enviado! Revisa tu bandeja.';

  @override
  String pleaseWaitSeconds(int seconds) {
    return 'Por favor espera $seconds segundos';
  }

  @override
  String get resetPassword => 'Restablecer contraseña';

  @override
  String get enterNewPassword => 'Ingresa tu nueva contraseña abajo';

  @override
  String get newPassword => 'Nueva contraseña';

  @override
  String get confirmPassword => 'Confirmar contraseña';

  @override
  String get confirmYourPassword => 'Confirma tu contraseña';

  @override
  String get passwordsDoNotMatch => 'Las contraseñas no coinciden';

  @override
  String get completeYourProfile => 'Completa tu perfil';

  @override
  String get stepOfTwo => 'Paso 1 de 2';

  @override
  String get uploadPhoto => 'Subir foto';

  @override
  String get completeSetup => 'Completar configuración';

  @override
  String get skipForNow => 'Omitir por ahora';

  @override
  String get success => '¡Éxito!';

  @override
  String get accountCreatedSuccessfully =>
      'Tu cuenta se ha creado exitosamente';

  @override
  String get passwordResetSuccessfully =>
      'Tu contraseña se ha restablecido exitosamente';

  @override
  String get emailVerifiedSuccessfully =>
      'Tu correo se ha verificado exitosamente';

  @override
  String get continueButton => 'Continuar';

  @override
  String get getStarted => 'Comenzar';

  @override
  String get back => 'Atrás';

  @override
  String get socialAuthFailed =>
      'La autenticación falló. Por favor intenta de nuevo.';

  @override
  String get socialAuthNetworkError =>
      'Falló la conexión de red. Por favor verifica tu conexión a internet e intenta de nuevo.';

  @override
  String get socialAuthTimeout =>
      'La autenticación expiró. Por favor intenta de nuevo.';

  @override
  String get accountLinkingError =>
      'No se pudo vincular tu cuenta. Por favor intenta de nuevo o contacta soporte.';

  @override
  String get signInWithEmail => 'Iniciar sesión con correo';

  @override
  String get dismiss => 'Descartar';

  @override
  String get repeatedNetworkFailureMessage =>
      'Se detectaron múltiples errores de red. Verifica tu conexión o intenta iniciar sesión con correo electrónico.';

  @override
  String get repeatedTimeoutFailureMessage =>
      'La autenticación sigue agotando el tiempo. Intenta iniciar sesión con correo electrónico.';

  @override
  String get repeatedAuthFailureMessage =>
      'La autenticación falló varias veces. Intenta iniciar sesión con correo electrónico o contacta a soporte.';

  @override
  String get or => 'o';

  @override
  String get profileSetupDescription =>
      'Por favor completa tu perfil para comenzar a usar Grex';

  @override
  String get linkYourAccount => 'Vincular tu cuenta';

  @override
  String accountExistsMessage(String email) {
    return 'Ya existe una cuenta con el correo $email.';
  }

  @override
  String linkAccountQuestion(String provider) {
    return '¿Te gustaría vincular tu cuenta de $provider con tu cuenta existente?';
  }

  @override
  String get linkAccountBenefit =>
      'Esto te permitirá iniciar sesión con cualquiera de los dos métodos.';

  @override
  String get linkAccounts => 'Vincular cuentas';

  @override
  String get createNewAccount => 'Crear nueva cuenta';

  @override
  String get cancelProfileSetup => 'Cancelar configuración';

  @override
  String get cancelProfileSetupMessage =>
      '¿Estás seguro de que quieres cancelar? Serás desconectado y necesitarás iniciar sesión de nuevo.';

  @override
  String get continueSetup => 'Continuar configuración';

  @override
  String get signingIn => 'Iniciando sesión...';

  @override
  String get registerAccount => 'Crear cuenta';

  @override
  String get joinGrexExpenseShare =>
      'Únete a Grex para empezar a dividir gastos';

  @override
  String get registering => 'Creando cuenta...';

  @override
  String get displayNameRequired => 'Por favor ingresa tu nombre';

  @override
  String get displayNameEmpty => 'El nombre no puede estar vacío';

  @override
  String get displayNameTooLong => 'El nombre debe tener 50 caracteres o menos';

  @override
  String get preferredCurrencyLabel => 'Moneda preferida';

  @override
  String get passwordHintShort => 'Mín. 8 caracteres';

  @override
  String get yourNameHint => 'Tu nombre';

  @override
  String get passwordHint =>
      'Al menos 8 caracteres con mayúsculas, minúsculas y números';

  @override
  String get alreadyHaveAccountPrefix => '¿Ya tienes una cuenta? ';

  @override
  String get signIn => 'Iniciar sesión';

  @override
  String get forgotPasswordTitle => 'Olvidé mi contraseña';

  @override
  String get enterEmailForResetShort =>
      'Ingresa tu correo para restablecer tu contraseña';

  @override
  String get sendResetLinkShort => 'Enviar enlace';

  @override
  String get sending => 'Enviando...';

  @override
  String get resetEmailSent => 'Se envió el correo de restablecimiento';

  @override
  String pleaseCheckEmailAt(String email) {
    return 'Por favor revisa tu correo en $email';
  }

  @override
  String get resend => 'Reenviar';

  @override
  String get emailNotInSystem => 'Correo no encontrado en el sistema';

  @override
  String get weWillSendLink =>
      'Te enviaremos un enlace para restablecer tu contraseña';

  @override
  String get rememberPassword => '¿Recuerdas tu contraseña? ';

  @override
  String get profileTitle => 'Perfil';

  @override
  String get profileFullTitle => 'Tu perfil';

  @override
  String get signOutConfirmTitle => 'Cerrar sesión';

  @override
  String get signOutConfirmMessage =>
      '¿Estás seguro de que quieres cerrar sesión?';

  @override
  String get profileLoadFailed => 'No se pudo cargar el perfil';

  @override
  String get noProfileData => 'Sin datos de perfil';

  @override
  String get accountCreatedAt => 'Cuenta creada';

  @override
  String get lastUpdatedAt => 'Última actualización';

  @override
  String get editProfile => 'Editar perfil';

  @override
  String errorWithMessage(String message) {
    return 'Error: $message';
  }

  @override
  String get refreshTooltip => 'Actualizar';

  @override
  String joinedAt(String date) {
    return 'Se unió $date';
  }

  @override
  String get today => 'Hoy';

  @override
  String get yesterday => 'Ayer';

  @override
  String daysAgo(int count) {
    return 'hace $count días';
  }

  @override
  String weeksAgo(int count) {
    return 'hace $count semanas';
  }

  @override
  String monthsAgo(int count) {
    return 'hace $count meses';
  }

  @override
  String yearsAgo(int count) {
    return 'hace $count años';
  }

  @override
  String get saveChanges => 'Guardar cambios';

  @override
  String get saving => 'Guardando...';

  @override
  String get cancelChangesTitle => '¿Descartar cambios?';

  @override
  String get unsavedChangesMessage =>
      'Tienes cambios sin guardar. ¿Seguro que quieres cancelar?';

  @override
  String get continueEditing => 'Continuar editando';

  @override
  String get discardChanges => 'Descartar';

  @override
  String get profileUpdatedSuccess => 'Perfil actualizado exitosamente';

  @override
  String get displayNameHint => 'Ingresa tu nombre visible';

  @override
  String displayNameTooShort(int min) {
    return 'El nombre debe tener al menos $min caracteres';
  }

  @override
  String get displayNameInvalidChars =>
      'El nombre contiene caracteres no válidos';

  @override
  String get editProfileNoteTitle => 'Nota';

  @override
  String get editProfileTipDisplayName =>
      '• Tu nombre visible se muestra a otros miembros';

  @override
  String get editProfileTipCurrency =>
      '• La moneda preferida se usa como predeterminada';

  @override
  String get editProfileTipLanguage =>
      '• Los cambios de idioma se aplican a toda la app';

  @override
  String get reenterPassword => 'Reingresa la contraseña';

  @override
  String get currencyRequired => 'Por favor selecciona una moneda';

  @override
  String get languageRequired => 'Por favor selecciona un idioma';

  @override
  String get myGroups => 'Mis grupos';

  @override
  String get noGroupsTitle => 'Aún no hay grupos';

  @override
  String get noGroupsDescription =>
      'Crea tu primer grupo para empezar a compartir gastos con amigos y familia.';

  @override
  String get somethingWentWrong => 'Algo salió mal';

  @override
  String get couldNotLoadGroups =>
      'No pudimos cargar tus grupos. Verifica tu conexión e inténtalo de nuevo.';

  @override
  String membersCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count miembros',
      one: '1 miembro',
      zero: 'Sin miembros',
    );
    return '$_temp0';
  }

  @override
  String expensesPageTitle(String groupName) {
    return 'Gastos de $groupName';
  }

  @override
  String get expensesSearchHint => 'Buscar gastos…';

  @override
  String get filterExpenses => 'Filtrar gastos';

  @override
  String get addExpense => 'Añadir gasto';

  @override
  String get noExpensesTitle => 'Aún no hay gastos';

  @override
  String get noExpensesDescription =>
      'Empieza a registrar los gastos del grupo añadiendo el primero.';

  @override
  String get noExpensesMatchFilters =>
      'Ningún gasto coincide con los filtros. Prueba a ampliar los criterios.';

  @override
  String get addFirstExpense => 'Añadir primer gasto';

  @override
  String get couldNotLoadExpenses =>
      'No pudimos cargar los gastos. Verifica tu conexión e inténtalo de nuevo.';

  @override
  String paidByPerson(String name) {
    return 'Pagado por $name';
  }

  @override
  String participantsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count participantes',
      one: '1 participante',
      zero: 'Sin participantes',
    );
    return '$_temp0';
  }

  @override
  String get invalidSplit => 'División inválida';

  @override
  String get validSplit => 'Válida';

  @override
  String groupCurrencyLabel(String currency) {
    return 'Grupo: $currency';
  }

  @override
  String balancesPageTitle(String groupName) {
    return 'Saldos de $groupName';
  }

  @override
  String get refreshBalances => 'Actualizar saldos';

  @override
  String get couldNotLoadBalances =>
      'No pudimos cargar los saldos. Verifica tu conexión e inténtalo de nuevo.';

  @override
  String get memberBalances => 'Saldos por miembro';

  @override
  String get settleUp => 'Liquidar';

  @override
  String get balanceAmountLabel => 'Saldo';

  @override
  String get viewSettlementPlan => 'Ver plan de liquidación';

  @override
  String get balanceStatusOwes => 'Debe dinero al grupo';

  @override
  String get balanceStatusOwed => 'El grupo le debe dinero';

  @override
  String get balanceStatusSettled => 'Todo liquidado';

  @override
  String get balanceBadgeOwes => 'DEBE';

  @override
  String get balanceBadgeOwed => 'LE DEBEN';

  @override
  String get balanceBadgeSettled => 'LIQUIDADO';

  @override
  String get noBalancesTitle => 'Aún no hay saldos';

  @override
  String get noBalancesDescription =>
      'Los saldos aparecerán aquí cuando se añadan gastos y pagos al grupo.';

  @override
  String get balancesAutoExplainer =>
      'Los saldos se calculan automáticamente a partir de los gastos y pagos del grupo.';

  @override
  String get addExpenses => 'Añadir gastos';

  @override
  String get recordPayments => 'Registrar pagos';

  @override
  String get balanceSummary => 'Resumen de saldos';

  @override
  String get totalOwed => 'Total a favor';

  @override
  String get totalOwes => 'Total adeudado';

  @override
  String get settledStat => 'Liquidados';

  @override
  String get unsettledStat => 'Pendientes';

  @override
  String get generateSettlementPlan => 'Generar plan de liquidación';

  @override
  String get allMembersSettledUp => '¡Todos los miembros están liquidados!';

  @override
  String get couldNotLoadPayments =>
      'No pudimos cargar los pagos. Verifica tu conexión e inténtalo de nuevo.';

  @override
  String get deletePaymentTooltip => 'Eliminar pago';

  @override
  String get yourNameSectionTitle => 'Tu nombre';

  @override
  String get preferencesSectionTitle => 'Preferencias';

  @override
  String get displayNameHelper =>
      'Así es como los demás te verán en los grupos.';

  @override
  String get searchHint => 'Buscar';

  @override
  String get useDifferentAccount => 'Usar otra cuenta';

  @override
  String get currencyHelper =>
      'Se usará como moneda predeterminada para nuevos grupos.';

  @override
  String get termsOfService => 'Términos del Servicio';

  @override
  String get privacyPolicy => 'Política de Privacidad';

  @override
  String agreeToTermsAndPrivacy(String tos, String privacy) {
    return 'Acepto los $tos y la $privacy.';
  }
}
