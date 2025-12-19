import 'package:flutter_test/flutter_test.dart';
import 'package:grex/features/auth/data/repositories/repositories.dart';
import 'package:grex/features/auth/domain/entities/entities.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import 'supabase_auth_repository_test.mocks.dart';

class _MockSupabaseUser extends Mock implements supabase.User {}

@GenerateMocks([
  supabase.SupabaseClient,
  supabase.GoTrueClient,
  supabase.AuthResponse,
])
void main() {
  late SupabaseAuthRepository repository;
  late MockSupabaseClient mockSupabaseClient;
  late MockGoTrueClient mockGoTrueClient;

  setUp(() {
    mockSupabaseClient = MockSupabaseClient();
    mockGoTrueClient = MockGoTrueClient();
    when(mockSupabaseClient.auth).thenReturn(mockGoTrueClient);
    repository = SupabaseAuthRepository(supabaseClient: mockSupabaseClient);
  });

  group('SupabaseAuthRepository', () {
    group('Property Test 1: Registration creates account and profile', () {
      test(
        'should successfully register user with valid credentials',
        () async {
          // Arrange
          const email = 'test@example.com';
          const password = 'StrongPassword123!';
          final mockUser = _MockSupabaseUser();
          when(mockUser.id).thenReturn('user-123');
          when(mockUser.email).thenReturn(email);
          when(
            mockUser.emailConfirmedAt,
          ).thenReturn(DateTime.now().toIso8601String());
          when(mockUser.createdAt).thenReturn(DateTime.now().toIso8601String());
          when(mockUser.lastSignInAt).thenReturn(null);
          final mockResponse = MockAuthResponse();

          when(mockResponse.user).thenReturn(mockUser);
          when(
            mockGoTrueClient.signUp(
              email: email,
              password: password,
            ),
          ).thenAnswer((_) async => mockResponse);

          // Act
          final result = await repository.signUpWithEmail(
            email: email,
            password: password,
          );

          // Assert
          expect(result.isRight(), isTrue);
          result.fold(
            (failure) => fail('Should not return failure'),
            (user) {
              expect(user.id, equals('user-123'));
              expect(user.email, equals(email));
              expect(user.emailConfirmed, isTrue);
            },
          );

          verify(
            mockGoTrueClient.signUp(
              email: email,
              password: password,
            ),
          ).called(1);
        },
      );

      test('should handle registration failure with existing email', () async {
        // Arrange
        const email = 'existing@example.com';
        const password = 'StrongPassword123!';

        when(
          mockGoTrueClient.signUp(
            email: email,
            password: password,
          ),
        ).thenThrow(const supabase.AuthException('User already registered'));

        // Act
        final result = await repository.signUpWithEmail(
          email: email,
          password: password,
        );

        // Assert
        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) {
            expect(failure, isA<EmailAlreadyInUseFailure>());
          },
          (user) => fail('Should not return user'),
        );
      });

      test('should handle weak password during registration', () async {
        // Arrange
        const email = 'test@example.com';
        const password = '123'; // Weak password

        when(
          mockGoTrueClient.signUp(
            email: email,
            password: password,
          ),
        ).thenThrow(
          const supabase.AuthException(
            'Password should be at least 6 characters',
          ),
        );

        // Act
        final result = await repository.signUpWithEmail(
          email: email,
          password: password,
        );

        // Assert
        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) {
            expect(failure, isA<WeakPasswordFailure>());
          },
          (user) => fail('Should not return user'),
        );
      });
    });

    group('signInWithEmail', () {
      test('should successfully sign in with valid credentials', () async {
        // Arrange
        const email = 'test@example.com';
        const password = 'password123';
        final mockUser = _MockSupabaseUser();
        when(mockUser.id).thenReturn('user-123');
        when(mockUser.email).thenReturn(email);
        when(
          mockUser.emailConfirmedAt,
        ).thenReturn(DateTime.now().toIso8601String());
        when(mockUser.createdAt).thenReturn(DateTime.now().toIso8601String());
        when(mockUser.lastSignInAt).thenReturn(null);
        final mockResponse = MockAuthResponse();

        when(mockResponse.user).thenReturn(mockUser);
        when(
          mockGoTrueClient.signInWithPassword(
            email: email,
            password: password,
          ),
        ).thenAnswer((_) async => mockResponse);

        // Act
        final result = await repository.signInWithEmail(
          email: email,
          password: password,
        );

        // Assert
        expect(result.isRight(), isTrue);
        result.fold(
          (failure) => fail('Should not return failure'),
          (user) {
            expect(user.id, equals('user-123'));
            expect(user.email, equals(email));
          },
        );
      });

      test('should handle invalid credentials', () async {
        // Arrange
        const email = 'test@example.com';
        const password = 'wrongpassword';

        when(
          mockGoTrueClient.signInWithPassword(
            email: email,
            password: password,
          ),
        ).thenThrow(const supabase.AuthException('Invalid login credentials'));

        // Act
        final result = await repository.signInWithEmail(
          email: email,
          password: password,
        );

        // Assert
        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) {
            expect(failure, isA<InvalidCredentialsFailure>());
          },
          (user) => fail('Should not return user'),
        );
      });
    });

    group('signOut', () {
      test('should successfully sign out user', () async {
        // Arrange
        when(mockGoTrueClient.signOut()).thenAnswer((_) async {});

        // Act
        final result = await repository.signOut();

        // Assert
        expect(result.isRight(), isTrue);
        verify(mockGoTrueClient.signOut()).called(1);
      });

      test('should handle sign out failure', () async {
        // Arrange
        when(
          mockGoTrueClient.signOut(),
        ).thenThrow(const supabase.AuthException('Sign out failed'));

        // Act
        final result = await repository.signOut();

        // Assert
        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) {
            expect(failure, isA<AuthFailure>());
          },
          (_) => fail('Should not succeed'),
        );
      });
    });

    group('resetPassword', () {
      test('should successfully send reset password email', () async {
        // Arrange
        const email = 'test@example.com';
        when(
          mockGoTrueClient.resetPasswordForEmail(email),
        ).thenAnswer((_) async {});

        // Act
        final result = await repository.resetPassword(email: email);

        // Assert
        expect(result.isRight(), isTrue);
        verify(mockGoTrueClient.resetPasswordForEmail(email)).called(1);
      });
    });

    group('currentUser', () {
      test('should return current user when authenticated', () {
        // Arrange
        final mockUser = _MockSupabaseUser();
        when(mockUser.id).thenReturn('user-123');
        when(mockUser.email).thenReturn('test@example.com');
        when(mockUser.emailConfirmedAt).thenReturn(null);
        when(mockUser.createdAt).thenReturn(DateTime.now().toIso8601String());
        when(mockUser.lastSignInAt).thenReturn(null);

        when(mockGoTrueClient.currentUser).thenReturn(mockUser);

        // Act
        final user = repository.currentUser;

        // Assert
        expect(user, isNotNull);
        expect(user!.id, equals('user-123'));
        expect(user.email, equals('test@example.com'));
      });

      test('should return null when not authenticated', () {
        // Arrange
        when(mockGoTrueClient.currentUser).thenReturn(null);

        // Act
        final user = repository.currentUser;

        // Assert
        expect(user, isNull);
      });
    });
  });

  tearDown(() {
    repository.dispose();
  });
}
