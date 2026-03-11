import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grex/core/logging/logging_providers.dart';
import 'package:grex/core/network/api_client.dart';
import 'package:grex/core/network/interceptors/auth_interceptor.dart';
import 'package:grex/core/performance/performance_providers.dart';
import 'package:grex/core/storage/secure_storage_service.dart';
import 'package:grex/core/storage/storage_migration_service.dart';
import 'package:grex/core/storage/storage_service.dart';
import 'package:grex/features/auth/data/repositories/supabase_auth_repository.dart';
import 'package:grex/features/auth/domain/repositories/auth_repository.dart';
import 'package:grex/features/auth/domain/usecases/get_current_user_usecase.dart';
import 'package:grex/features/auth/domain/usecases/is_authenticated_usecase.dart';
import 'package:grex/features/auth/domain/usecases/login_usecase.dart';
import 'package:grex/features/auth/domain/usecases/logout_usecase.dart';
import 'package:grex/features/auth/domain/usecases/refresh_token_usecase.dart';
import 'package:grex/features/auth/domain/usecases/register_usecase.dart';

/// Provider for [StorageService] instance
///
/// This provider creates a singleton instance of [StorageService] that can be
/// used throughout the application for non-sensitive local storage operations
/// (e.g., user preferences, cached data).
///
/// For sensitive data (tokens, passwords), use [secureStorageServiceProvider].
final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
});

/// Provider for [SecureStorageService] instance
///
/// This provider creates a singleton instance of [SecureStorageService] that
/// uses encrypted storage for sensitive data such as authentication tokens.
///
/// Platform-specific:
/// - Android: EncryptedSharedPreferences
/// - iOS: Keychain
final secureStorageServiceProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService();
});

/// Provider for [IStorageService] interface
///
/// This provider provides the storage service as an interface, allowing for
/// easier testing and potential future implementations.
///
/// **Note**: This defaults to [StorageService] for backward compatibility.
/// For secure storage, use [secureStorageServiceProvider] directly.
final iStorageServiceProvider = Provider<IStorageService>((ref) {
  return ref.watch(storageServiceProvider);
});

/// Startup initialization provider
///
/// This provider initializes storage services and runs migrations before
/// the app starts. It should be awaited in the main function to ensure
/// storage is ready and migrated.
final storageInitializationProvider = FutureProvider<void>((ref) async {
  final storageService = ref.read(storageServiceProvider);
  final secureStorageService = ref.read(secureStorageServiceProvider);
  final loggingService = ref.read(loggingServiceProvider);

  // Initialize storage services
  await storageService.init();

  // Run migrations
  final migrationService = StorageMigrationService(
    storageService: storageService,
    secureStorageService: secureStorageService,
    loggingService: loggingService,
  );
  await migrationService.migrateAll();
});

/// Provider for [AuthRepository] instance
///
/// Uses [SupabaseAuthRepository] which interacts directly with Supabase
/// Auth SDK. This provides full support for all auth operations including
/// password reset, email verification, and proper session management.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return SupabaseAuthRepository();
});

/// Provider for [AuthInterceptor] instance
///
/// This provider creates a singleton instance of [AuthInterceptor] that handles
/// authentication token injection and automatic token refresh on 401 errors.
final authInterceptorProvider = Provider<AuthInterceptor>((ref) {
  final secureStorageService = ref.watch(secureStorageServiceProvider);
  final authRepository = ref.watch(authRepositoryProvider);
  return AuthInterceptor(
    secureStorageService: secureStorageService,
    authRepository: authRepository,
  );
});

/// Provider for [ApiClient] instance with full auth support
///
/// This is the main API client used throughout the application for
/// non-auth API calls (groups, expenses, payments, etc.).
/// It includes AuthInterceptor for automatic token injection and refresh.
///
/// Note: Auth operations use Supabase SDK directly via
/// [SupabaseAuthRepository].
final apiClientProvider = Provider<ApiClient>((ref) {
  final storageService = ref.watch(storageServiceProvider);
  final authInterceptor = ref.watch(authInterceptorProvider);
  final loggingService = ref.read(loggingServiceProvider);
  final performanceService = ref.read(performanceServiceProvider);

  return ApiClient(
    storageService: storageService,
    authInterceptor: authInterceptor,
    loggingService: loggingService,
    performanceService: performanceService,
  );
});

/// Provider for [LoginUseCase] instance
///
/// This provider creates a singleton instance of [LoginUseCase]
/// that handles user login business logic.
final loginUseCaseProvider = Provider<LoginUseCase>((ref) {
  final repository = ref.watch<AuthRepository>(authRepositoryProvider);
  return LoginUseCase(repository);
});

/// Provider for [RegisterUseCase] instance
///
/// This provider creates a singleton instance of [RegisterUseCase]
/// that handles user registration business logic.
final registerUseCaseProvider = Provider<RegisterUseCase>((ref) {
  final repository = ref.watch<AuthRepository>(authRepositoryProvider);
  return RegisterUseCase(repository);
});

/// Provider for [LogoutUseCase] instance
///
/// This provider creates a singleton instance of [LogoutUseCase]
/// that handles user logout business logic.
final logoutUseCaseProvider = Provider<LogoutUseCase>((ref) {
  final repository = ref.watch<AuthRepository>(authRepositoryProvider);
  return LogoutUseCase(repository);
});

/// Provider for [RefreshTokenUseCase] instance
///
/// This provider creates a singleton instance of [RefreshTokenUseCase]
/// that handles token refresh business logic.
final refreshTokenUseCaseProvider = Provider<RefreshTokenUseCase>((ref) {
  final repository = ref.watch<AuthRepository>(authRepositoryProvider);
  return RefreshTokenUseCase(repository);
});

/// Provider for [GetCurrentUserUseCase] instance
///
/// This provider creates a singleton instance of [GetCurrentUserUseCase]
/// that handles getting the current authenticated user.
final getCurrentUserUseCaseProvider = Provider<GetCurrentUserUseCase>((ref) {
  final repository = ref.watch<AuthRepository>(authRepositoryProvider);
  return GetCurrentUserUseCase(repository);
});

/// Provider for [IsAuthenticatedUseCase] instance
///
/// This provider creates a singleton instance of [IsAuthenticatedUseCase]
/// that handles checking if the user is authenticated.
final isAuthenticatedUseCaseProvider = Provider<IsAuthenticatedUseCase>((ref) {
  final repository = ref.watch<AuthRepository>(authRepositoryProvider);
  return IsAuthenticatedUseCase(repository);
});
