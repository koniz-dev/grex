import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:grex/core/di/main_app_injection.dart';
import 'package:grex/core/services/export_service.dart';
import 'package:grex/core/services/offline_queue_storage.dart';
import 'package:grex/core/services/real_time_manager.dart';
import 'package:grex/core/services/real_time_service.dart';
import 'package:grex/features/auth/data/repositories/supabase_auth_repository.dart';
import 'package:grex/features/auth/data/repositories/supabase_user_repository.dart';
import 'package:grex/features/auth/data/services/secure_session_service.dart';
import 'package:grex/features/auth/data/services/supabase_email_verification_service.dart';
import 'package:grex/features/auth/domain/repositories/auth_repository.dart';
import 'package:grex/features/auth/domain/repositories/user_repository.dart';
import 'package:grex/features/auth/domain/services/email_verification_service.dart';
import 'package:grex/features/auth/domain/services/session_manager.dart';
import 'package:grex/features/auth/domain/services/session_service.dart';
import 'package:grex/features/auth/presentation/bloc/bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Global GetIt instance for dependency injection
final GetIt getIt = GetIt.instance;

/// Initialize dependency injection
Future<void> configureDependencies() async {
  // External dependencies
  getIt
    ..registerLazySingleton<SupabaseClient>(
      () => Supabase.instance.client,
    )
    ..registerLazySingleton<FlutterSecureStorage>(
      () => const FlutterSecureStorage(
        aOptions: AndroidOptions(
          encryptedSharedPreferences: true,
        ),
        iOptions: IOSOptions(
          accessibility: KeychainAccessibility.first_unlock_this_device,
        ),
      ),
    )
    // Repositories
    ..registerLazySingleton<AuthRepository>(
      () => SupabaseAuthRepository(supabaseClient: getIt<SupabaseClient>()),
    )
    ..registerLazySingleton<UserRepository>(
      () => SupabaseUserRepository(supabaseClient: getIt<SupabaseClient>()),
    )
    // Services
    ..registerLazySingleton<SessionService>(
      () => SecureSessionService(
        secureStorage: getIt<FlutterSecureStorage>(),
        supabaseClient: getIt<SupabaseClient>(),
        userRepository: getIt<UserRepository>(),
      ),
    )
    ..registerLazySingleton<SessionManager>(
      () => SessionManager(
        sessionService: getIt<SessionService>(),
      ),
    )
    ..registerLazySingleton<EmailVerificationService>(
      SupabaseEmailVerificationService.new,
    )
    // Real-time services
    ..registerLazySingleton<RealTimeService>(
      () => SupabaseRealTimeService(
        supabaseClient: getIt<SupabaseClient>(),
        queueStorage: OfflineQueueStorage(
          secureStorage: getIt<FlutterSecureStorage>(),
        ),
      ),
    )
    ..registerLazySingleton<RealTimeManager>(
      () => RealTimeManager(
        realTimeService: getIt<RealTimeService>(),
      ),
    )
    ..registerLazySingleton<ExportService>(
      ExportService.new,
    )
    // BLoCs
    ..registerFactory<AuthBloc>(
      () => AuthBloc(
        authRepository: getIt<AuthRepository>(),
        userRepository: getIt<UserRepository>(),
        sessionManager: getIt<SessionManager>(),
      ),
    )
    ..registerFactory<ProfileBloc>(
      () => ProfileBloc(
        userRepository: getIt<UserRepository>(),
        authRepository: getIt<AuthRepository>(),
      ),
    );

  // Configure main app features dependencies
  configureMainAppDependencies();
}
