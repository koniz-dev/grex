import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:grex/core/performance/performance_service.dart';
import 'package:grex/features/auth/domain/entities/entities.dart';
import 'package:grex/features/auth/domain/repositories/user_repository.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

// Generate mocks for testing
@GenerateMocks(
  [
    UserRepository,
    PerformanceService,
  ],
  customMocks: [
    MockSpec<supabase.SupabaseClient>(as: #MockSupabaseClient),
    MockSpec<supabase.GoTrueClient>(as: #MockGoTrueClient),
    MockSpec<supabase.User>(as: #MockSupabaseUser),
    MockSpec<FlutterSecureStorage>(as: #MockFlutterSecureStorage),
    MockSpec<supabase.Session>(as: #MockSession),
    MockSpec<supabase.AuthResponse>(as: #MockAuthResponse),
  ],
)
import 'mock_helpers.mocks.dart';

// Export generated mocks
export 'mock_helpers.mocks.dart';

/// Test data factory for creating mock entities
class TestDataFactory {
  static User createTestUser({
    String id = 'test-user-id',
    String email = 'test@example.com',
    bool emailConfirmed = true,
    DateTime? createdAt,
    Map<String, dynamic>? appMetadata,
    Map<String, dynamic>? userMetadata,
  }) {
    return User(
      id: id,
      email: email,
      emailConfirmed: emailConfirmed,
      createdAt: createdAt ?? DateTime.now(),
      appMetadata: appMetadata,
      userMetadata: userMetadata,
    );
  }

  static UserProfile createTestUserProfile({
    String id = 'test-user-id',
    String email = 'test@example.com',
    String displayName = 'Test User',
    String preferredCurrency = 'USD',
    String languageCode = 'en',
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    final now = DateTime.now();
    return UserProfile(
      id: id,
      email: email,
      displayName: displayName,
      preferredCurrency: preferredCurrency,
      languageCode: languageCode,
      createdAt: createdAt ?? now,
      updatedAt: updatedAt ?? now,
    );
  }

  static supabase.User createSupabaseUser({
    String id = 'test-user-id',
    String email = 'test@example.com',
    DateTime? createdAt,
    Map<String, dynamic>? appMetadata,
    Map<String, dynamic>? userMetadata,
  }) {
    // This would need to be implemented based on the actual Supabase User
    // constructor
    // For now, we provide a mock structure
    final mockUser = MockSupabaseUser();
    when(mockUser.id).thenReturn(id);
    when(mockUser.email).thenReturn(email);
    when(
      mockUser.createdAt,
    ).thenReturn((createdAt ?? DateTime.now()).toIso8601String());
    when(mockUser.appMetadata).thenReturn(appMetadata ?? {});
    when(mockUser.userMetadata).thenReturn(userMetadata ?? {});
    return mockUser;
  }
}

/// Performance test helpers
class PerformanceTestHelpers {
  /// Simulate network delay
  static Future<void> simulateNetworkDelay([Duration? delay]) async {
    await Future<void>.delayed(delay ?? const Duration(milliseconds: 100));
  }

  /// Simulate processing delay
  static Future<void> simulateProcessingDelay([Duration? delay]) async {
    await Future<void>.delayed(delay ?? const Duration(milliseconds: 50));
  }

  /// Create a future that completes after the specified delay
  static Future<T> delayedResult<T>(T result, [Duration? delay]) async {
    await Future<void>.delayed(delay ?? const Duration(milliseconds: 100));
    return result;
  }

  /// Create a future that throws after the specified delay
  static Future<T> delayedError<T>(Exception error, [Duration? delay]) async {
    await Future<void>.delayed(delay ?? const Duration(milliseconds: 100));
    throw error;
  }
}

/// Mock setup helpers for common test scenarios
class MockSetupHelpers {
  /// Setup successful OAuth flow
  static void setupSuccessfulOAuth(MockSupabaseClient mockClient) {
    final mockAuth = MockGoTrueClient();
    when(mockClient.auth).thenReturn(mockAuth);

    // Mock successful OAuth initiation
    when(
      mockAuth.signInWithOAuth(
        supabase.OAuthProvider.google,
        redirectTo: anyNamed('redirectTo'),
        authScreenLaunchMode: supabase.LaunchMode.externalApplication,
      ),
    ).thenAnswer((_) async => true);

    // Mock user available after OAuth
    final testUser = TestDataFactory.createSupabaseUser();
    when(mockAuth.currentUser).thenReturn(testUser);
  }

  /// Setup OAuth timeout scenario
  static void setupOAuthTimeout(MockSupabaseClient mockClient) {
    final mockAuth = MockGoTrueClient();
    when(mockClient.auth).thenReturn(mockAuth);

    // Mock successful OAuth initiation
    when(
      mockAuth.signInWithOAuth(
        supabase.OAuthProvider.google,
        redirectTo: anyNamed('redirectTo'),
        authScreenLaunchMode: supabase.LaunchMode.externalApplication,
      ),
    ).thenAnswer((_) async => true);

    // Mock no user available (timeout scenario)
    when(mockAuth.currentUser).thenReturn(null);
  }

  /// Setup successful session refresh
  static void setupSuccessfulSessionRefresh(MockSupabaseClient mockClient) {
    final mockAuth = MockGoTrueClient();
    when(mockClient.auth).thenReturn(mockAuth);

    final testUser = TestDataFactory.createSupabaseUser();
    final mockSession = MockSession();
    when(mockSession.user).thenReturn(testUser);
    when(mockSession.accessToken).thenReturn('new-access-token');
    when(mockSession.refreshToken).thenReturn('new-refresh-token');

    final mockResponse = MockAuthResponse();
    when(mockResponse.session).thenReturn(mockSession);

    when(mockAuth.refreshSession()).thenAnswer((_) async => mockResponse);
  }
}

// Additional mock classes that might be needed
