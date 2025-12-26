import 'package:grex/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:grex/features/auth/data/models/auth_response_model.dart';
import 'package:grex/features/auth/data/models/user_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase implementation of [AuthRemoteDataSource]
///
/// Uses Supabase Auth SDK directly instead of custom API endpoints.
/// This is the recommended approach for Supabase-based authentication.
class SupabaseAuthRemoteDataSource implements AuthRemoteDataSource {
  /// Creates a [SupabaseAuthRemoteDataSource] instance
  SupabaseAuthRemoteDataSource() : _client = Supabase.instance.client;

  final SupabaseClient _client;

  @override
  Future<AuthResponseModel> login(String email, String password) async {
    final response = await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );

    if (response.user == null) {
      throw Exception('Login failed: No user returned');
    }

    return AuthResponseModel(
      user: UserModel.fromSupabaseUser(response.user!),
      token: response.session?.accessToken ?? '',
      refreshToken: response.session?.refreshToken,
    );
  }

  @override
  Future<AuthResponseModel> register(
    String email,
    String password,
    String name,
  ) async {
    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: {'display_name': name},
      );

      if (response.user == null) {
        throw Exception('Registration failed: No user returned');
      }

      return AuthResponseModel(
        user: UserModel.fromSupabaseUser(response.user!),
        token: response.session?.accessToken ?? '',
        refreshToken: response.session?.refreshToken,
      );
    } on AuthException catch (e) {
      throw Exception('Registration failed: ${e.message}');
    }
  }

  @override
  Future<void> logout() async {
    await _client.auth.signOut();
  }

  @override
  Future<AuthResponseModel> refreshToken(String refreshToken) async {
    final response = await _client.auth.refreshSession();

    if (response.user == null) {
      throw Exception('Token refresh failed: No user returned');
    }

    return AuthResponseModel(
      user: UserModel.fromSupabaseUser(response.user!),
      token: response.session?.accessToken ?? '',
      refreshToken: response.session?.refreshToken,
    );
  }
}
