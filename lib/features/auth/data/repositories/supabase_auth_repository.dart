import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:grex/core/errors/failures.dart' as core;
import 'package:grex/core/utils/result.dart';
import 'package:grex/features/auth/domain/entities/entities.dart';
import 'package:grex/features/auth/domain/repositories/repositories.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

/// Supabase implementation of [AuthRepository].
///
/// This class provides concrete implementations of authentication operations
/// using Supabase Auth as the backend service. It handles error mapping
/// from Supabase exceptions to domain failures.
class SupabaseAuthRepository implements AuthRepository {
  /// Creates a [SupabaseAuthRepository] with the provided Supabase client.
  ///
  /// The [supabaseClient] is optional. If not provided, uses the default
  /// Supabase instance client.
  SupabaseAuthRepository({
    supabase.SupabaseClient? supabaseClient,
  }) : _supabaseClient = supabaseClient ?? supabase.Supabase.instance.client;
  final supabase.SupabaseClient _supabaseClient;
  StreamController<User?>? _authStateController;

  @override
  Future<Either<AuthFailure, User>> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabaseClient.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) {
        return const Left(InvalidCredentialsFailure());
      }

      final user = _mapSupabaseUserToDomain(response.user!);
      return Right(user);
    } on supabase.AuthException catch (e) {
      return Left(_mapAuthExceptionToFailure(e));
    } on Object catch (_) {
      return const Left(NetworkFailure());
    }
  }

  @override
  Future<Either<AuthFailure, User>> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabaseClient.auth.signUp(
        email: email,
        password: password,
      );

      if (response.user == null) {
        return const Left(GenericAuthFailure('Registration failed'));
      }

      final user = _mapSupabaseUserToDomain(response.user!);
      return Right(user);
    } on supabase.AuthException catch (e) {
      return Left(_mapAuthExceptionToFailure(e));
    } on Object catch (_) {
      return const Left(NetworkFailure());
    }
  }

  @override
  Future<Either<AuthFailure, void>> signOut() async {
    try {
      await _supabaseClient.auth.signOut();
      return const Right(null);
    } on supabase.AuthException catch (e) {
      return Left(_mapAuthExceptionToFailure(e));
    } on Object catch (_) {
      return const Left(NetworkFailure());
    }
  }

  @override
  Future<Either<AuthFailure, void>> resetPassword({
    required String email,
  }) async {
    try {
      await _supabaseClient.auth.resetPasswordForEmail(email);
      return const Right(null);
    } on supabase.AuthException catch (e) {
      return Left(_mapAuthExceptionToFailure(e));
    } on Object catch (_) {
      return const Left(NetworkFailure());
    }
  }

  @override
  Stream<User?> get authStateChanges {
    _authStateController ??= StreamController<User?>.broadcast();

    // Listen to Supabase auth state changes and map to domain User
    _supabaseClient.auth.onAuthStateChange.listen((data) {
      final supabaseUser = data.session?.user;
      final domainUser = supabaseUser != null
          ? _mapSupabaseUserToDomain(supabaseUser)
          : null;

      _authStateController?.add(domainUser);
    });

    return _authStateController!.stream;
  }

  @override
  User? get currentUser {
    final supabaseUser = _supabaseClient.auth.currentUser;
    return supabaseUser != null ? _mapSupabaseUserToDomain(supabaseUser) : null;
  }

  @override
  dynamic get currentSession {
    return _supabaseClient.auth.currentSession;
  }

  @override
  Future<Result<User?>> getCurrentUser() async {
    try {
      final supabaseUser = _supabaseClient.auth.currentUser;
      if (supabaseUser == null) {
        return const Success(null);
      }
      final user = _mapSupabaseUserToDomain(supabaseUser);
      return Success(user);
    } on Object catch (e) {
      return ResultFailure(
        core.AuthFailure('Failed to get current user: $e'),
      );
    }
  }

  @override
  Future<Result<bool>> isAuthenticated() async {
    try {
      final supabaseUser = _supabaseClient.auth.currentUser;
      return Success(supabaseUser != null);
    } on Object catch (e) {
      return ResultFailure(
        core.AuthFailure(
          'Failed to check authentication status: $e',
        ),
      );
    }
  }

  @override
  Future<Either<AuthFailure, void>> sendVerificationEmail() async {
    try {
      final user = _supabaseClient.auth.currentUser;
      if (user == null) {
        return const Left(GenericAuthFailure('No user is currently signed in'));
      }

      await _supabaseClient.auth.resend(
        type: supabase.OtpType.signup,
        email: user.email,
      );

      return const Right(null);
    } on supabase.AuthException catch (e) {
      return Left(_mapAuthExceptionToFailure(e));
    } on Object catch (_) {
      return const Left(NetworkFailure());
    }
  }

  @override
  Future<Either<AuthFailure, void>> verifyEmail({
    required String token,
    required String email,
  }) async {
    try {
      await _supabaseClient.auth.verifyOTP(
        token: token,
        type: supabase.OtpType.signup,
        email: email,
      );

      return const Right(null);
    } on supabase.AuthException catch (e) {
      return Left(_mapAuthExceptionToFailure(e));
    } on Object catch (_) {
      return const Left(NetworkFailure());
    }
  }

  @override
  bool get isEmailVerified {
    final user = _supabaseClient.auth.currentUser;
    return user?.emailConfirmedAt != null;
  }

  @override
  Future<Result<String>> refreshToken() async {
    try {
      final response = await _supabaseClient.auth.refreshSession();

      if (response.session == null) {
        return const ResultFailure(
          core.AuthFailure('Failed to refresh token: No session available'),
        );
      }

      final newToken = response.session!.accessToken;
      return Success(newToken);
    } on supabase.AuthException catch (e) {
      // Map Supabase AuthException to core AuthFailure for Result
      return ResultFailure(
        core.AuthFailure(
          e.message,
          code: e.statusCode,
        ),
      );
    } on Object catch (e) {
      return ResultFailure(
        core.AuthFailure('Token refresh failed: $e'),
      );
    }
  }

  /// Maps Supabase User to domain User entity.
  User _mapSupabaseUserToDomain(supabase.User supabaseUser) {
    return User(
      id: supabaseUser.id,
      email: supabaseUser.email ?? '',
      emailConfirmed: supabaseUser.emailConfirmedAt != null,
      createdAt: DateTime.parse(supabaseUser.createdAt),
      lastSignInAt: supabaseUser.lastSignInAt != null
          ? DateTime.parse(supabaseUser.lastSignInAt!)
          : null,
    );
  }

  /// Maps Supabase AuthException to domain AuthFailure.
  AuthFailure _mapAuthExceptionToFailure(supabase.AuthException exception) {
    switch (exception.statusCode) {
      case '400':
        if (exception.message.contains('Invalid login credentials')) {
          return const InvalidCredentialsFailure();
        }
        if (exception.message.contains('Password should be at least')) {
          return const WeakPasswordFailure();
        }
        if (exception.message.contains('User already registered')) {
          return const EmailAlreadyInUseFailure();
        }
        if (exception.message.contains('Email not confirmed')) {
          return const UnverifiedEmailFailure();
        }
        return GenericAuthFailure(exception.message);
      case '422':
        return const WeakPasswordFailure();
      case '429':
        return const GenericAuthFailure(
          'Too many requests. Please try again later',
        );
      default:
        return GenericAuthFailure(exception.message);
    }
  }

  /// Dispose resources when repository is no longer needed.
  void dispose() {
    unawaited(_authStateController?.close());
    _authStateController = null;
  }
}
