import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:grex/features/auth/data/repositories/repositories.dart';
import 'package:grex/features/auth/domain/entities/entities.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_user_repository_test.mocks.dart';

// Mock classes must be mutable to allow dynamic behavior in tests
// ignore: must_be_immutable
class _MockPostgrestFilterBuilder<T> extends Mock
    implements PostgrestFilterBuilder<T> {}

// Mock classes must be mutable to allow dynamic behavior in tests
// ignore: must_be_immutable
class _MockPostgrestTransformBuilder<T> extends Mock
    implements PostgrestTransformBuilder<T> {}

// Fake implementation that implements both PostgrestTransformBuilder and Future
class _FakePostgrestTransformBuilder<T> extends Fake
    implements PostgrestTransformBuilder<T>, Future<T> {
  _FakePostgrestTransformBuilder(this._value);
  final T _value;

  @override
  Future<R> then<R>(
    FutureOr<R> Function(T value) onValue, {
    Function? onError,
  }) async {
    return onValue(_value);
  }

  @override
  Future<T> catchError(
    Function onError, {
    bool Function(Object)? test,
  }) {
    return Future<T>.value(_value);
  }

  @override
  Stream<T> asStream() {
    return Stream<T>.value(_value);
  }

  @override
  Future<T> timeout(
    Duration timeLimit, {
    FutureOr<T> Function()? onTimeout,
  }) {
    return Future<T>.value(_value);
  }

  @override
  Future<T> whenComplete(FutureOr<void> Function() action) {
    return Future<T>.value(_value);
  }
}

@GenerateMocks([
  SupabaseClient,
  SupabaseQueryBuilder,
])
void main() {
  late SupabaseUserRepository repository;
  late MockSupabaseClient mockSupabaseClient;
  late MockSupabaseQueryBuilder mockQueryBuilder;
  late _MockPostgrestFilterBuilder<dynamic> mockFilterBuilder;
  late _MockPostgrestFilterBuilder<List<Map<String, dynamic>>>
  mockSelectFilterBuilder;
  late _MockPostgrestTransformBuilder<PostgrestList>
  mockTransformBuilderForList;

  setUp(() {
    mockSupabaseClient = MockSupabaseClient();
    mockQueryBuilder = MockSupabaseQueryBuilder();
    mockFilterBuilder = _MockPostgrestFilterBuilder<dynamic>();
    mockSelectFilterBuilder =
        _MockPostgrestFilterBuilder<List<Map<String, dynamic>>>();
    mockTransformBuilderForList =
        _MockPostgrestTransformBuilder<PostgrestList>();
    when(mockSupabaseClient.from('users')).thenReturn(mockQueryBuilder);
    repository = SupabaseUserRepository(supabaseClient: mockSupabaseClient);
  });

  group('SupabaseUserRepository', () {
    final testProfile = UserProfile(
      id: 'user-123',
      email: 'test@example.com',
      displayName: 'Test User',
      preferredCurrency: 'VND',
      languageCode: 'vi',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    group('Property Test 6: Profile updates are atomic', () {
      test('should successfully update profile with valid data', () async {
        // Arrange
        final updatedProfile = testProfile.copyWith(
          displayName: 'Updated Name',
          preferredCurrency: 'USD',
        );

        final mockResponse = {
          'id': updatedProfile.id,
          'email': updatedProfile.email,
          'display_name': updatedProfile.displayName,
          'preferred_currency': updatedProfile.preferredCurrency,
          'language_code': updatedProfile.languageCode,
          'created_at': updatedProfile.createdAt.toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        };

        when(mockQueryBuilder.update(any)).thenReturn(mockFilterBuilder);
        when(
          mockFilterBuilder.eq('id', updatedProfile.id),
        ).thenReturn(mockFilterBuilder);
        when(
          mockFilterBuilder.select(),
        ).thenReturn(mockTransformBuilderForList);
        // single() returns PostgrestTransformBuilder<PostgrestMap> which
        // implements Future
        // Create a fake that resolves to mockResponse when awaited
        final fakeSingleBuilder = _FakePostgrestTransformBuilder<PostgrestMap>(
          mockResponse,
        );
        when(
          mockTransformBuilderForList.single(),
        ).thenReturn(fakeSingleBuilder);

        // Act
        final result = await repository.updateUserProfile(updatedProfile);

        // Assert
        expect(result.isRight(), isTrue);
        result.fold(
          (failure) => fail('Should not return failure'),
          (profile) {
            expect(profile.id, equals(updatedProfile.id));
            expect(profile.displayName, equals('Updated Name'));
            expect(profile.preferredCurrency, equals('USD'));
            expect(profile.email, equals(updatedProfile.email));
          },
        );

        // Verify the update was called with correct data
        final capturedData =
            verify(
                  mockQueryBuilder.update(captureAny),
                ).captured.first
                as Map<String, dynamic>;
        expect(capturedData['display_name'], equals('Updated Name'));
        expect(capturedData['preferred_currency'], equals('USD'));
        // Ensure ID and timestamps are not included in update
        expect(capturedData.containsKey('id'), isFalse);
        expect(capturedData.containsKey('created_at'), isFalse);
        expect(capturedData.containsKey('updated_at'), isFalse);
      });

      test('should handle concurrent update conflicts', () async {
        // Arrange
        final updatedProfile = testProfile.copyWith(
          displayName: 'Concurrent Update',
        );

        when(mockQueryBuilder.update(any)).thenReturn(mockFilterBuilder);
        when(
          mockFilterBuilder.eq('id', updatedProfile.id),
        ).thenReturn(mockFilterBuilder);
        when(
          mockFilterBuilder.select(),
        ).thenReturn(mockTransformBuilderForList);
        when(mockTransformBuilderForList.single()).thenThrow(
          const PostgrestException(
            message: 'No rows found',
            code: 'PGRST116',
          ),
        );

        // Act
        final result = await repository.updateUserProfile(updatedProfile);

        // Assert
        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) {
            expect(failure, isA<UserNotFoundFailure>());
          },
          (profile) => fail('Should not return profile'),
        );
      });

      test('should validate profile data before update', () async {
        // Arrange
        final invalidProfile = testProfile.copyWith(displayName: '');

        when(mockQueryBuilder.update(any)).thenReturn(mockFilterBuilder);
        when(
          mockFilterBuilder.eq('id', invalidProfile.id),
        ).thenReturn(mockFilterBuilder);
        when(
          mockFilterBuilder.select(),
        ).thenReturn(mockTransformBuilderForList);
        when(mockTransformBuilderForList.single()).thenThrow(
          const PostgrestException(
            message: 'Check constraint violation',
            code: '23514',
          ),
        );

        // Act
        final result = await repository.updateUserProfile(invalidProfile);

        // Assert
        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) {
            expect(failure, isA<ValidationFailure>());
          },
          (profile) => fail('Should not return profile'),
        );
      });
    });

    group('getUserProfile', () {
      test('should successfully get user profile', () async {
        // Arrange
        final mockResponse = {
          'id': testProfile.id,
          'email': testProfile.email,
          'display_name': testProfile.displayName,
          'preferred_currency': testProfile.preferredCurrency,
          'language_code': testProfile.languageCode,
          'created_at': testProfile.createdAt.toIso8601String(),
          'updated_at': testProfile.updatedAt.toIso8601String(),
        };

        when(mockQueryBuilder.select()).thenReturn(mockSelectFilterBuilder);
        when(
          mockSelectFilterBuilder.eq('id', testProfile.id),
        ).thenReturn(mockSelectFilterBuilder);
        final fakeMaybeSingleBuilder =
            _FakePostgrestTransformBuilder<PostgrestMap?>(mockResponse);
        when(
          mockSelectFilterBuilder.maybeSingle(),
        ).thenReturn(fakeMaybeSingleBuilder);

        // Act
        final result = await repository.getUserProfile(testProfile.id);

        // Assert
        expect(result.isRight(), isTrue);
        result.fold(
          (failure) => fail('Should not return failure'),
          (profile) {
            expect(profile.id, equals(testProfile.id));
            expect(profile.email, equals(testProfile.email));
            expect(profile.displayName, equals(testProfile.displayName));
          },
        );
      });

      test('should handle user not found', () async {
        // Arrange
        when(mockQueryBuilder.select()).thenReturn(mockSelectFilterBuilder);
        when(
          mockSelectFilterBuilder.eq('id', 'nonexistent'),
        ).thenReturn(mockSelectFilterBuilder);
        // maybeSingle() returns PostgrestTransformBuilder<PostgrestMap?> which
        // implements Future
        final fakeMaybeSingleBuilderNull =
            _FakePostgrestTransformBuilder<PostgrestMap?>(null);
        when(
          mockSelectFilterBuilder.maybeSingle(),
        ).thenReturn(fakeMaybeSingleBuilderNull);

        // Act
        final result = await repository.getUserProfile('nonexistent');

        // Assert
        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) {
            expect(failure, isA<UserNotFoundFailure>());
          },
          (profile) => fail('Should not return profile'),
        );
      });
    });

    group('createUserProfile', () {
      test('should successfully create user profile', () async {
        // Arrange
        final newProfile = UserProfile(
          id: 'new-user-123',
          email: 'newuser@example.com',
          displayName: 'New User',
          preferredCurrency: 'VND',
          languageCode: 'vi',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final mockResponse = {
          'id': newProfile.id,
          'email': newProfile.email,
          'display_name': newProfile.displayName,
          'preferred_currency': newProfile.preferredCurrency,
          'language_code': newProfile.languageCode,
          'created_at': newProfile.createdAt.toIso8601String(),
          'updated_at': newProfile.updatedAt.toIso8601String(),
        };

        when(mockQueryBuilder.insert(any)).thenReturn(mockFilterBuilder);
        when(
          mockFilterBuilder.select(),
        ).thenReturn(mockTransformBuilderForList);
        // single() returns PostgrestTransformBuilder<PostgrestMap> which
        // implements Future
        // Create a fake that resolves to mockResponse when awaited
        final fakeSingleBuilder = _FakePostgrestTransformBuilder<PostgrestMap>(
          mockResponse,
        );
        when(
          mockTransformBuilderForList.single(),
        ).thenReturn(fakeSingleBuilder);

        // Act
        final result = await repository.createUserProfile(newProfile);

        // Assert
        expect(result.isRight(), isTrue);
        result.fold(
          (failure) => fail('Should not return failure'),
          (profile) {
            expect(profile.id, equals(newProfile.id));
            expect(profile.email, equals(newProfile.email));
            expect(profile.displayName, equals(newProfile.displayName));
          },
        );

        // Verify timestamps are not included in insert
        final capturedData =
            verify(
                  mockQueryBuilder.insert(captureAny),
                ).captured.first
                as Map<String, dynamic>;
        expect(capturedData.containsKey('created_at'), isFalse);
        expect(capturedData.containsKey('updated_at'), isFalse);
      });

      test('should handle duplicate profile creation', () async {
        // Arrange
        when(mockQueryBuilder.insert(any)).thenReturn(mockFilterBuilder);
        when(
          mockFilterBuilder.select(),
        ).thenReturn(mockTransformBuilderForList);
        when(mockTransformBuilderForList.single()).thenThrow(
          const PostgrestException(
            message: 'Unique constraint violation',
            code: '23505',
          ),
        );

        // Act
        final result = await repository.createUserProfile(testProfile);

        // Assert
        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) {
            expect(failure, isA<UserFailure>());
          },
          (profile) => fail('Should not return profile'),
        );
      });
    });
  });
}
