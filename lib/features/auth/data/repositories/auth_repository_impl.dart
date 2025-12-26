import 'dart:async';
import 'package:dartz/dartz.dart';
import 'package:grex/core/errors/exception_to_failure_mapper.dart';
import 'package:grex/core/errors/exceptions.dart';
import 'package:grex/core/errors/failures.dart' as core;
import 'package:grex/core/utils/result.dart';
import 'package:grex/features/auth/data/datasources/auth_local_datasource.dart';
import 'package:grex/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:grex/features/auth/domain/entities/entities.dart';
import 'package:grex/features/auth/domain/repositories/auth_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

/// Implementation of authentication repository
class AuthRepositoryImpl implements AuthRepository {
  /// Creates an [AuthRepositoryImpl] with the given [remoteDataSource] and
  /// [localDataSource]
  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  /// Remote data source for API calls
  final AuthRemoteDataSource remoteDataSource;

  /// Local data source for caching
  final AuthLocalDataSource localDataSource;

  /// Stream controller for auth state changes
  final StreamController<User?> _authStateController =
      StreamController<User?>.broadcast();

  @override
  Future<Either<AuthFailure, User>> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final authResponse = await remoteDataSource.login(email, password);
      final user = authResponse.user.toEntity();
      await localDataSource.cacheUser(authResponse.user);
      await localDataSource.cacheToken(authResponse.token);
      if (authResponse.refreshToken != null) {
        await localDataSource.cacheRefreshToken(authResponse.refreshToken!);
      }

      // Sync with Supabase SDK to enable RLS-compliant database calls
      if (authResponse.token.isNotEmpty) {
        await supabase.Supabase.instance.client.auth.setSession(
          authResponse.token,
        );
      }

      _authStateController.add(user);
      return Right(user);
    } on AppException catch (e) {
      return Left(
        _mapCoreFailureToAuthFailure(ExceptionToFailureMapper.map(e)),
      );
    } on Exception catch (e) {
      return Left(
        _mapCoreFailureToAuthFailure(ExceptionToFailureMapper.map(e)),
      );
    }
  }

  @override
  Future<Either<AuthFailure, User>> signUpWithEmail({
    required String email,
    required String password,
    String? displayName,
    String? preferredCurrency,
    String? languageCode,
  }) async {
    try {
      // Note: name parameter is not in the interface, using email as fallback
      final authResponse = await remoteDataSource.register(
        email,
        password,
        displayName ?? email.split('@').first,
      );
      final user = authResponse.user.toEntity();
      await localDataSource.cacheUser(authResponse.user);
      await localDataSource.cacheToken(authResponse.token);
      if (authResponse.refreshToken != null) {
        await localDataSource.cacheRefreshToken(authResponse.refreshToken!);
      }

      // Sync with Supabase SDK to enable RLS-compliant database calls
      // Note: During signup, token might be empty if email confirmation
      // is required.
      // Supabase SDK handles the unauthenticated/pending state correctly.
      if (authResponse.token.isNotEmpty) {
        await supabase.Supabase.instance.client.auth.setSession(
          authResponse.token,
        );
      }

      _authStateController.add(user);
      return Right(user);
    } on AppException catch (e) {
      return Left(
        _mapCoreFailureToAuthFailure(ExceptionToFailureMapper.map(e)),
      );
    } on Exception catch (e) {
      return Left(
        _mapCoreFailureToAuthFailure(ExceptionToFailureMapper.map(e)),
      );
    }
  }

  @override
  Future<Either<AuthFailure, void>> signOut() async {
    try {
      await remoteDataSource.logout();
      await localDataSource.clearCache();

      // Clear the Supabase SDK session
      await supabase.Supabase.instance.client.auth.signOut();

      _authStateController.add(null);
      return const Right(null);
    } on AppException catch (e) {
      return Left(
        _mapCoreFailureToAuthFailure(ExceptionToFailureMapper.map(e)),
      );
    } on Exception catch (e) {
      return Left(
        _mapCoreFailureToAuthFailure(ExceptionToFailureMapper.map(e)),
      );
    }
  }

  @override
  Future<Either<AuthFailure, void>> resetPassword({
    required String email,
  }) async {
    // Password reset is not implemented in remote data source
    // Return a failure indicating this feature is not available
    return const Left(GenericAuthFailure('Password reset is not implemented'));
  }

  @override
  Stream<User?> get authStateChanges => _authStateController.stream;

  @override
  User? get currentUser {
    // Synchronous getter - try to get cached user synchronously
    // Since localDataSource is async, we return null and rely on async methods
    // This is a limitation of the synchronous getter requirement
    return null;
  }

  @override
  Future<Result<User?>> getCurrentUser() async {
    try {
      final cachedUser = await localDataSource.getCachedUser();
      if (cachedUser == null) {
        return const Success(null);
      }
      return Success(cachedUser.toEntity());
    } on AppException catch (e) {
      return ResultFailure(ExceptionToFailureMapper.map(e));
    } on Exception catch (e) {
      return ResultFailure(ExceptionToFailureMapper.map(e));
    }
  }

  @override
  Future<Result<bool>> isAuthenticated() async {
    try {
      final cachedUser = await localDataSource.getCachedUser();
      return Success(cachedUser != null);
    } on AppException catch (e) {
      return ResultFailure(ExceptionToFailureMapper.map(e));
    } on Exception catch (e) {
      return ResultFailure(ExceptionToFailureMapper.map(e));
    }
  }

  @override
  dynamic get currentSession {
    // Session management is not implemented in this repository
    return null;
  }

  @override
  Future<Either<AuthFailure, void>> sendVerificationEmail() async {
    // Email verification is not implemented in remote data source
    return const Left(
      GenericAuthFailure('Email verification is not implemented'),
    );
  }

  @override
  Future<Either<AuthFailure, void>> verifyEmail({
    required String token,
    required String email,
  }) async {
    // Email verification is not implemented in remote data source
    return const Left(
      GenericAuthFailure('Email verification is not implemented'),
    );
  }

  @override
  bool get isEmailVerified {
    final user = currentUser;
    return user?.emailConfirmed ?? false;
  }

  @override
  Future<Result<String>> refreshToken() async {
    try {
      final refreshToken = await localDataSource.getRefreshToken();
      if (refreshToken == null) {
        return const ResultFailure(
          core.UnknownFailure('No refresh token available'),
        );
      }

      final authResponse = await remoteDataSource.refreshToken(refreshToken);
      await localDataSource.cacheToken(authResponse.token);
      if (authResponse.refreshToken != null) {
        await localDataSource.cacheRefreshToken(
          authResponse.refreshToken!,
        );
      }
      return Success(authResponse.token);
    } on AppException catch (e) {
      return ResultFailure(ExceptionToFailureMapper.map(e));
    } on Exception catch (e) {
      return ResultFailure(ExceptionToFailureMapper.map(e));
    }
  }

  /// Maps core Failure to domain AuthFailure
  AuthFailure _mapCoreFailureToAuthFailure(core.Failure failure) {
    if (failure is core.AuthFailure) {
      // Map core AuthFailure to domain AuthFailure
      if (failure.message.contains('Invalid') ||
          failure.message.contains('credentials')) {
        return const InvalidCredentialsFailure();
      }
      if (failure.message.contains('network') ||
          failure.message.contains('connection')) {
        return const NetworkFailure();
      }
      return GenericAuthFailure(failure.message);
    } else if (failure is core.NetworkFailure) {
      return const NetworkFailure();
    } else {
      return GenericAuthFailure(failure.message);
    }
  }

  /// Dispose resources
  void dispose() {
    unawaited(_authStateController.close());
  }
}
