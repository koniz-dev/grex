import 'package:firebase_core/firebase_core.dart';
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
import 'package:grex/shared/widgets/dev_logout_overlay.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

void main() async {
  // Ensure Flutter binding is initialized first (required for all Flutter APIs)
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment configuration first (required for Supabase)
  await EnvConfig.load();

  // Initialize Firebase if native config files are present. Degrades silently
  // when google-services.json / GoogleService-Info.plist is missing so the app
  // still boots; feature flags + performance monitoring fall back to no-ops.
  try {
    await Firebase.initializeApp();
  } on Object catch (_) {
    // Firebase optional — continue without it.
  }

  // Initialize Supabase. If credentials are missing, show a clear error screen
  // instead of crashing the engine before runApp().
  try {
    await Future.wait([
      SupabaseConfig.initialize(),
      _initializeImageCache(),
    ]);
  } on Object catch (error, stackTrace) {
    runApp(_ConfigErrorApp(error: error, stackTrace: stackTrace));
    return;
  }

  // Initialize dependency injection after Supabase is ready
  await configureDependencies();

  // Print configuration in debug mode (optional, useful for development)
  if (AppConfig.isDebugMode) {
    AppConfig.printConfig();
  }

  // Create ProviderContainer with overrides so secure storage shares the same
  // FlutterSecureStorage instance as GetIt (used by SecureSessionService for
  // token keys), so every writer of those keys uses one store.
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
  LocaleDefaults.appLocale = savedLocale;

  // Restore the user session, then mirror its tokens into secure storage.
  //
  // NOTE: nothing reads those tokens today. AuthInterceptor is their only
  // reader and it is unused scaffolding (issue #7), so this write currently
  // feeds no one. It is kept rather than removed because #7 chose to keep the
  // Dio layer, and dropping the write would have to be undone the moment the
  // layer is wired up. See issue #35 for the open question of whether an
  // unread copy of the credentials should be persisted at all.
  try {
    await container
        .read(authNotifierProvider.notifier)
        .getCurrentUser()
        .timeout(const Duration(seconds: 5));

    // If the user is restored from Supabase, mirror the session tokens to the
    // shared secure-storage keys. Supabase holds its own copy of the session;
    // this is the second one, and it has no reader today.
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

/// Minimal fallback app shown when boot-time configuration is missing.
/// Renders without DI / Supabase / l10n so it survives any init failure.
class _ConfigErrorApp extends StatelessWidget {
  const _ConfigErrorApp({required this.error, required this.stackTrace});

  final Object error;
  final StackTrace stackTrace;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                const Text(
                  'Configuration error',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                const Text(
                  'The app could not start because required configuration is '
                  'missing. Set SUPABASE_URL and SUPABASE_ANON_KEY in your '
                  '.env file (or pass them via --dart-define) and restart.',
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: SingleChildScrollView(
                    child: SelectableText(
                      '$error\n\n$stackTrace',
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
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
            child: DevLogoutOverlay(
              child: child ?? const SizedBox.shrink(),
            ),
          ),
        );
      },
    );
  }
}
