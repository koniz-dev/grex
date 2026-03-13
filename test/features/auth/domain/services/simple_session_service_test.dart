import 'package:flutter_test/flutter_test.dart';
import 'package:grex/features/auth/domain/entities/entities.dart';
import 'package:grex/features/auth/domain/services/simple_session_service.dart';
import 'package:mockito/mockito.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;

import '../../../../helpers/supabase_mocks.dart';

void main() {
  group('SimpleSessionService', () {
    late MockSupabaseClient mockSupabaseClient;
    late MockGoTrueClient mockAuth;
    late SimpleSessionService sessionService;

    setUp(() {
      mockSupabaseClient = MockSupabaseClient();
      mockAuth = MockGoTrueClient();
      when(mockSupabaseClient.auth).thenReturn(mockAuth);
      sessionService = SimpleSessionService(mockSupabaseClient);
    });

    group('hasValidSession', () {
      test('should return true for valid session with future expiry', () async {
        // Arrange
        final mockSession = MockSession();
        final futureExpiry =
            DateTime.now()
                .add(const Duration(hours: 1))
                .millisecondsSinceEpoch ~/
            1000;
        when(mockSession.expiresAt).thenReturn(futureExpiry);
        when(mockAuth.currentSession).thenReturn(mockSession);

        // Act
        final result = await sessionService.hasValidSession();

        // Assert
        expect(result, isTrue);
      });

      test('should return false for expired session', () async {
        // Arrange
        final mockSession = MockSession();
        final pastExpiry =
            DateTime.now()
                .subtract(const Duration(hours: 1))
                .millisecondsSinceEpoch ~/
            1000;
        when(mockSession.expiresAt).thenReturn(pastExpiry);
        when(mockAuth.currentSession).thenReturn(mockSession);

        // Act
        final result = await sessionService.hasValidSession();

        // Assert
        expect(result, isFalse);
      });

      test('should return false for null session', () async {
        // Arrange
        when(mockAuth.currentSession).thenReturn(null);

        // Act
        final result = await sessionService.hasValidSession();

        // Assert
        expect(result, isFalse);
      });

      test('should return false for session with null expiry', () async {
        // Arrange
        final mockSession = MockSession();
        when(mockSession.expiresAt).thenReturn(null);
        when(mockAuth.currentSession).thenReturn(mockSession);

        // Act
        final result = await sessionService.hasValidSession();

        // Assert
        expect(result, isFalse);
      });
    });

    group('getCurrentUser', () {
      test('should return User for authenticated Google OAuth user', () {
        // Arrange
        final mockSupabaseUser = MockUser();
        when(mockSupabaseUser.id).thenReturn('google-user-123');
        when(mockSupabaseUser.email).thenReturn('user@gmail.com');
        when(
          mockSupabaseUser.emailConfirmedAt,
        ).thenReturn(DateTime.now().toIso8601String());
        when(
          mockSupabaseUser.createdAt,
        ).thenReturn(DateTime.now().toIso8601String());
        when(
          mockSupabaseUser.lastSignInAt,
        ).thenReturn(DateTime.now().toIso8601String());
        when(mockSupabaseUser.appMetadata).thenReturn({
          'providers': ['google'],
        });
        when(mockSupabaseUser.userMetadata).thenReturn({
          'full_name': 'Google User',
        });
        when(mockAuth.currentUser).thenReturn(mockSupabaseUser);

        // Act
        final result = sessionService.getCurrentUser();

        // Assert
        expect(result, isNotNull);
        expect(result!.id, equals('google-user-123'));
        expect(result.email, equals('user@gmail.com'));
        expect(result.socialProvider, equals(SocialAuthProvider.google));
      });

      test('should return null for unauthenticated user', () {
        // Arrange
        when(mockAuth.currentUser).thenReturn(null);

        // Act
        final result = sessionService.getCurrentUser();

        // Assert
        expect(result, isNull);
      });
    });

    group('signOut', () {
      test('should call Supabase auth signOut', () async {
        // Arrange
        when(mockAuth.signOut()).thenAnswer((_) async {});

        // Act
        await sessionService.signOut();

        // Assert
        verify(mockAuth.signOut()).called(1);
      });

      test('should propagate signOut exceptions', () async {
        // Arrange
        when(
          mockAuth.signOut(),
        ).thenThrow(const AuthException('Sign out failed'));

        // Act & Assert
        await expectLater(
          sessionService.signOut(),
          throwsA(isA<AuthException>()),
        );
      });
    });

    group('getAuthenticationMethod', () {
      test('should return "google" for Google OAuth user', () {
        // Arrange
        final mockSupabaseUser = MockUser();
        when(mockSupabaseUser.id).thenReturn('google-user');
        when(mockSupabaseUser.email).thenReturn('user@gmail.com');
        when(
          mockSupabaseUser.emailConfirmedAt,
        ).thenReturn(DateTime.now().toIso8601String());
        when(
          mockSupabaseUser.createdAt,
        ).thenReturn(DateTime.now().toIso8601String());
        when(mockSupabaseUser.appMetadata).thenReturn({
          'providers': ['google'],
        });
        when(mockSupabaseUser.userMetadata).thenReturn({});
        when(mockAuth.currentUser).thenReturn(mockSupabaseUser);

        // Act
        final result = sessionService.getAuthenticationMethod();

        // Assert
        expect(result, equals('google'));
      });

      test('should return "email" for email authentication user', () {
        // Arrange
        final mockSupabaseUser = MockUser();
        when(mockSupabaseUser.id).thenReturn('email-user');
        when(mockSupabaseUser.email).thenReturn('user@example.com');
        when(
          mockSupabaseUser.emailConfirmedAt,
        ).thenReturn(DateTime.now().toIso8601String());
        when(
          mockSupabaseUser.createdAt,
        ).thenReturn(DateTime.now().toIso8601String());
        when(mockSupabaseUser.appMetadata).thenReturn({
          'providers': ['email'],
        });
        when(mockSupabaseUser.userMetadata).thenReturn({});
        when(mockAuth.currentUser).thenReturn(mockSupabaseUser);

        // Act
        final result = sessionService.getAuthenticationMethod();

        // Assert
        expect(result, equals('email'));
      });

      test('should return null for unauthenticated user', () {
        // Arrange
        when(mockAuth.currentUser).thenReturn(null);

        // Act
        final result = sessionService.getAuthenticationMethod();

        // Assert
        expect(result, isNull);
      });
    });

    group('refreshSession', () {
      test('should return true when refresh succeeds', () async {
        // Arrange
        final mockAuthResponse = MockAuthResponse();
        final mockSession = MockSession();
        when(mockAuthResponse.session).thenReturn(mockSession);
        when(
          mockAuth.refreshSession(),
        ).thenAnswer((_) async => mockAuthResponse);

        // Act
        final result = await sessionService.refreshSession();

        // Assert
        expect(result, isTrue);
        verify(mockAuth.refreshSession()).called(1);
      });

      test('should return false when refresh throws exception', () async {
        // Arrange
        when(
          mockAuth.refreshSession(),
        ).thenThrow(const AuthException('Refresh failed'));

        // Act
        final result = await sessionService.refreshSession();

        // Assert
        expect(result, isFalse);
        verify(mockAuth.refreshSession()).called(1);
      });
    });
  });
}
