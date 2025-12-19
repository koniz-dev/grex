import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grex/core/config/app_config.dart';
import 'package:grex/core/config/env_config.dart';
import 'package:grex/core/config/supabase_config.dart';
import 'package:grex/core/di/injection.dart';
import 'package:grex/core/di/providers.dart';
import 'package:grex/core/localization/localization_providers.dart';
import 'package:grex/core/localization/localization_service.dart';
import 'package:grex/core/routing/app_router.dart';
import 'package:grex/core/services/error_logging_service.dart';
import 'package:grex/core/widgets/global_error_handler.dart';
import 'package:grex/features/feature_flags/presentation/providers/feature_flags_providers.dart';
import 'package:grex/l10n/app_localizations.dart';
import 'package:grex/shared/theme/app_theme.dart';

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

  // Create ProviderContainer for initialization
  final container = ProviderContainer();

  // Initialize storage service via provider before app starts
  // This is done after env config to ensure storage is ready
  await container.read(storageInitializationProvider.future);

  // Initialize feature flags system
  // Note: Firebase Remote Config will be initialized here if Firebase is set
  // up. The system will gracefully fall back to local flags if Firebase is not
  // available
  await container.read(featureFlagsInitializationProvider.future);

  // Initialize locale from storage
  final localizationService = container.read(localizationServiceProvider);
  final savedLocale = await localizationService.getCurrentLocale();
  container.read(localeStateProvider.notifier).locale = savedLocale;

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
        child: const MyApp(),
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
