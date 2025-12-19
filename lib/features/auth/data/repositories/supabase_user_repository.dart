import 'package:dartz/dartz.dart';
import 'package:grex/features/auth/domain/entities/entities.dart';
import 'package:grex/features/auth/domain/repositories/repositories.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase implementation of [UserRepository].
///
/// This class provides concrete implementations of user profile operations
/// using Supabase database as the backend. It handles RLS-compliant queries
/// and error mapping from Supabase exceptions to domain failures.
class SupabaseUserRepository implements UserRepository {
  /// Creates a [SupabaseUserRepository] with the provided Supabase client.
  ///
  /// The [supabaseClient] is optional. If not provided, uses the default
  /// Supabase instance client.
  SupabaseUserRepository({
    SupabaseClient? supabaseClient,
  }) : _supabaseClient = supabaseClient ?? Supabase.instance.client;
  final SupabaseClient _supabaseClient;
  static const String _tableName = 'users';

  @override
  Future<Either<UserFailure, UserProfile>> getUserProfile(String userId) async {
    try {
      final response = await _supabaseClient
          .from(_tableName)
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (response == null) {
        return const Left(UserNotFoundFailure());
      }

      final profile = UserProfile.fromJson(response);
      return Right(profile);
    } on PostgrestException catch (e) {
      return Left(_mapPostgrestExceptionToFailure(e));
    } on Object catch (_) {
      return const Left(GenericUserFailure('Network connection failed'));
    }
  }

  @override
  Future<Either<UserFailure, UserProfile>> createUserProfile(
    UserProfile profile,
  ) async {
    try {
      // Remove timestamps as they're handled by the database
      final profileData = profile.toJson()
        ..remove('created_at')
        ..remove('updated_at');

      final response = await _supabaseClient
          .from(_tableName)
          .insert(profileData)
          .select()
          .single();

      final createdProfile = UserProfile.fromJson(response);
      return Right(createdProfile);
    } on PostgrestException catch (e) {
      return Left(_mapPostgrestExceptionToFailure(e));
    } on Object catch (_) {
      return const Left(GenericUserFailure('Network connection failed'));
    }
  }

  @override
  Future<Either<UserFailure, UserProfile>> updateUserProfile(
    UserProfile profile,
  ) async {
    try {
      // Remove fields that shouldn't be updated
      final profileData = profile.toJson()
        ..remove('id')
        ..remove('created_at')
        ..remove('updated_at');

      final response = await _supabaseClient
          .from(_tableName)
          .update(profileData)
          .eq('id', profile.id)
          .select()
          .single();

      final updatedProfile = UserProfile.fromJson(response);
      return Right(updatedProfile);
    } on PostgrestException catch (e) {
      return Left(_mapPostgrestExceptionToFailure(e));
    } on Object catch (_) {
      return const Left(GenericUserFailure('Network connection failed'));
    }
  }

  /// Maps Supabase PostgrestException to domain UserFailure.
  UserFailure _mapPostgrestExceptionToFailure(PostgrestException exception) {
    switch (exception.code) {
      case '23505': // Unique violation
        return const GenericUserFailure('User profile already exists');
      case '23503': // Foreign key violation
        return const InvalidUserDataFailure('Invalid user reference');
      case '42501': // Insufficient privilege (RLS)
        return const GenericUserFailure('Access denied');
      case 'PGRST116': // No rows found
        return const UserNotFoundFailure();
      case '23514': // Check constraint violation
        return InvalidUserDataFailure('Invalid data: ${exception.message}');
      default:
        return GenericUserFailure(exception.message);
    }
  }
}
