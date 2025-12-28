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
  String get dontHaveAccount => '¿No tienes una cuenta? Regístrate';

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
  String get noPaymentsMatchCriteria =>
      'Ningún pago coincide con tus criterios.';

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
}
