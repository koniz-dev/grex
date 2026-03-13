import 'dart:async';

import 'package:mockito/mockito.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Mock Supabase client for integration testing
class MockSupabaseClient extends Mock implements SupabaseClient {
  final MockGoTrueClient _auth = MockGoTrueClient();

  @override
  GoTrueClient get auth => _auth;

  // Let Mockito handle the from() and rpc() methods automatically
  // They can be configured in tests using when()
}

/// Mock GoTrue client for authentication
class MockGoTrueClient extends Mock implements GoTrueClient {
  User? _currentUser;
  Session? _currentSession;

  @override
  User? get currentUser => _currentUser;

  @override
  Session? get currentSession => _currentSession;

  Future<bool> signInWithOAuth(
    OAuthProvider provider, {
    String? redirectTo,
    String? scopes,
    Map<String, String>? queryParams,
    LaunchMode authScreenLaunchMode = LaunchMode.platformDefault,
  }) async {
    // Mock implementation - can be overridden in tests
    return true;
  }

  @override
  Future<void> signOut({SignOutScope scope = SignOutScope.global}) async {
    _currentUser = null;
    _currentSession = null;
  }

  @override
  Future<AuthSessionUrlResponse> getSessionFromUrl(
    Uri uri, {
    bool storeSession = true,
  }) async {
    // Mock implementation for deep link handling
    return AuthSessionUrlResponse(
      session:
          _currentSession ??
          Session(
            accessToken: 'mock_token',
            refreshToken: 'mock_refresh',
            expiresIn: 3600,
            tokenType: 'bearer',
            user:
                _currentUser ??
                User(
                  id: 'mock_user_id',
                  appMetadata: {},
                  userMetadata: {},
                  aud: 'authenticated',
                  createdAt: DateTime.now().toIso8601String(),
                ),
          ),
      redirectType: null,
    );
  }

  Future<AuthResponse> linkIdentity(OAuthProvider provider) async {
    // Mock implementation for account linking
    return AuthResponse(
      session: _currentSession,
      user: _currentUser,
    );
  }

  /// Test helper to set current user
  // ignore: use_setters_to_change_properties
  void setCurrentUserForTesting(User? user) {
    _currentUser = user;
  }

  /// Test helper to set current session
  // ignore: use_setters_to_change_properties
  void setCurrentSessionForTesting(Session? session) {
    _currentSession = session;
  }
}

/// Mock query builder for database operations
// ignore_for_file: avoid_returning_this
class MockQueryBuilder extends Mock {
  // Chain methods that return this for fluent interface
  MockQueryBuilder select([String columns = '*']) => this;
  MockQueryBuilder insert(Object values) => this;
  MockQueryBuilder update(Map<String, dynamic> values) => this;
  MockQueryBuilder delete() => this;
  MockQueryBuilder eq(String column, Object value) => this;
  MockQueryBuilder neq(String column, Object value) => this;
  MockQueryBuilder gt(String column, Object value) => this;
  MockQueryBuilder gte(String column, Object value) => this;
  MockQueryBuilder lt(String column, Object value) => this;
  MockQueryBuilder lte(String column, Object value) => this;
  MockQueryBuilder like(String column, String pattern) => this;
  MockQueryBuilder ilike(String column, String pattern) => this;
  MockQueryBuilder is_(String column, Object value) => this;
  MockQueryBuilder in_(String column, List<dynamic> values) => this;
  MockQueryBuilder contains(String column, Object value) => this;
  MockQueryBuilder containedBy(String column, Object value) => this;
  MockQueryBuilder order(
    String column, {
    bool ascending = false,
    bool nullsFirst = false,
  }) => this;
  MockQueryBuilder limit(
    int count, {
    String? foreignTable,
  }) => this;
  MockQueryBuilder range(
    int from,
    int to, {
    String? foreignTable,
  }) => this;
  MockQueryBuilder single() => this;
  MockQueryBuilder maybeSingle() => this;

  // Terminal method that returns data - can be configured with when() in tests
  Future<List<Map<String, dynamic>>> then<T>(
    FutureOr<T> Function(List<Map<String, dynamic>>) onValue, {
    Function? onError,
  }) async {
    // Default mock implementation - override in tests with when()
    return <Map<String, dynamic>>[];
  }
}
