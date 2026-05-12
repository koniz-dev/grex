import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:grex/core/config/app_config.dart';
import 'package:grex/core/config/env_config.dart';
import 'package:grex/core/config/supabase_config.dart';
import 'package:grex/core/constants/app_constants.dart';
import 'package:grex/core/di/injection.dart';
import 'package:grex/core/di/providers.dart';
import 'package:grex/core/localization/localization_providers.dart';
import 'package:grex/core/localization/localization_service.dart';
import 'package:grex/core/routing/routing_providers.dart';
import 'package:grex/core/services/error_logging_service.dart';
import 'package:grex/core/storage/secure_storage_service.dart';
import 'package:grex/core/widgets/global_error_handler.dart';
import 'package:grex/features/auth/presentation/bloc/bloc.dart';
import 'package:grex/features/auth/presentation/providers/auth_provider.dart';
import 'package:grex/features/auth/presentation/widgets/app_link_listener.dart';
import 'package:grex/features/feature_flags/presentation/providers/feature_flags_providers.dart';
import 'package:grex/l10n/app_localizations.dart';
import 'package:grex/shared/theme/app_theme.dart';
import 'package:grex/shared/utils/locale_defaults.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

void main() async {
  // Ensure Flutter binding is initialized first (required for all Flutter APIs)
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment configuration first (required for Supabase)
  await EnvConfig.load();

  // Run initialization tasks in parallel where possible
  await Future.wait([
    // Initialize Supabase with environment configuration
    SupabaseConfig.initialize(),
    // Initialize image cache settings for better performance
    _initializeImageCache(),
  ]);

  // Initialize dependency injection after Supabase is ready
  await configureDependencies();

  // Print configuration in debug mode (optional, useful for development)
  if (AppConfig.isDebugMode) {
    AppConfig.printConfig();
  }

  // Create ProviderContainer with overrides so secure storage shares the same
  // FlutterSecureStorage instance as GetIt (used by SecureSessionService for
  // token keys), ensuring AuthInterceptor and session service see the same
  // tokens.
  final container = ProviderContainer(
    overrides: [
      secureStorageServiceProvider.overrideWith(
        (ref) => SecureStorageService(
          secureStorage: getIt<FlutterSecureStorage>(),
        ),
      ),
    ],
  );

  // Initialize storage service via provider before app starts
  // This is done after env config to ensure storage is ready
  await container.read(storageInitializationProvider.future);

  // Initialize feature flags system
  // Note: Firebase Remote Config will be initialized here if Firebase is set
  // up. The system will gracefully fall back to local flags if Firebase is not
  // available
  await container.read(featureFlagsInitializationProvider.future);

  // Initialize locale from storage. Also propagate the persisted locale to
  // LocaleDefaults so that downstream consumers (signup, profile setup, new
  // groups, etc.) derive `preferred_language` / `preferred_currency` from
  // the user's selected app locale instead of the raw device locale.
  final localizationService = container.read(localizationServiceProvider);
  final savedLocale = await localizationService.getCurrentLocale();
  container.read(localeStateProvider.notifier).locale = savedLocale;
  LocaleDefaults.setAppLocale(savedLocale);

  // Restore user session if existing and sync tokens for AuthInterceptor
  try {
    await container
        .read(authNotifierProvider.notifier)
        .getCurrentUser()
        .timeout(const Duration(seconds: 5));

    // If user is restored from Supabase, write current session tokens to
    // secure storage so AuthInterceptor can attach Bearer token to API requests
    final authState = container.read(authNotifierProvider);
    if (authState.user != null) {
      final authRepository = container.read(authRepositoryProvider);
      final session = authRepository.currentSession;
      if (session != null) {
        final supabaseSession = session as supabase.Session;
        final secureStorage = container.read(secureStorageServiceProvider);
        await secureStorage.setString(
          AppConstants.tokenKey,
          supabaseSession.accessToken,
        );
        final refreshToken = supabaseSession.refreshToken;
        if (refreshToken != null && refreshToken.isNotEmpty) {
          await secureStorage.setString(
            AppConstants.refreshTokenKey,
            refreshToken,
          );
        }
      }
    }
  } on Exception {
    // Session restore failed, continue without session
  }

  runApp(
    GlobalErrorHandler(
      onError: (details) {
        // Log critical errors
        ErrorLoggingService.logError(
          details.exception,
          stackTrace: details.stack,
          context: {
            'library': details.library,
            'context': details.context?.toString(),
          },
          severity: ErrorSeverity.critical,
        );
      },
      child: UncontrolledProviderScope(
        container: container,
        child: BlocProvider<AuthBloc>.value(
          value: getIt<AuthBloc>(),
          child: const AppLinkListener(
            child: MyApp(),
          ),
        ),
      ),
    ),
  );
}

/// Initialize image cache settings for optimal performance
Future<void> _initializeImageCache() async {
  // Set reasonable cache limits to balance memory usage and performance
  // These values can be adjusted based on app requirements
  imageCache.maximumSize = 100; // Maximum number of images
  imageCache.maximumSizeBytes = 100 << 20; // 100 MB
}

/// Root application widget
class MyApp extends ConsumerWidget {
  /// Creates a [MyApp] widget
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch<Locale>(localeStateProvider);
    final textDirection = ref.watch<TextDirection>(textDirectionProvider);
    final router = ref.watch(goRouterProvider);

    return MaterialApp.router(
      title: 'Grex',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      // Router configuration
      routerConfig: router,
      // Localization configuration
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: LocalizationService.supportedLocales,
      // RTL support
      builder: (context, child) {
        return Directionality(
          textDirection: textDirection,
          child: RepaintBoundary(
            child: child ?? const SizedBox.shrink(),
          ),
        );
      },
    );
  }
}
