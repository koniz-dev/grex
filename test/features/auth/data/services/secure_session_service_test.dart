import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grex/core/constants/app_constants.dart';
import 'package:grex/features/auth/data/services/secure_session_service.dart';
import 'package:grex/features/auth/domain/entities/entities.dart';
import 'package:grex/features/auth/domain/repositories/user_repository.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;

import '../../../../helpers/property_test_helpers.dart';
import 'secure_session_service_test.mocks.dart';

@GenerateMocks([FlutterSecureStorage, SupabaseClient, UserRepository])
void main() {
  late SecureSessionService service;
  late MockFlutterSecureStorage mockStorage;
  late MockSupabaseClient mockSupabaseClient;
  late MockUserRepository mockUserRepository;

  setUp(() {
    mockStorage = MockFlutterSecureStorage();
    mockSupabaseClient = MockSupabaseClient();
    mockUserRepository = MockUserRepository();
    when(
      mockStorage.write(key: anyNamed('key'), value: anyNamed('value')),
    ).thenAnswer((_) async => {});
    when(mockStorage.delete(key: anyNamed('key'))).thenAnswer((_) async => {});
    when(mockStorage.read(key: anyNamed('key'))).thenAnswer((_) async => null);

    service = SecureSessionService(
      secureStorage: mockStorage,
      supabaseClient: mockSupabaseClient,
      userRepository: mockUserRepository,
    );
  });

  group('validateSession error handling', () {
    // One of the four sites in #42 where adding `await` genuinely changed
    // behaviour. `validateSession` returns `sessionResult.fold(...)` from
    // inside a `try`, and the success branch is `async`. Without `await` that
    // future escaped the try before it could reject, so a throw inside the
    // branch propagated to the caller as a raw exception — breaking the
    // `Future<Either<AuthFailure, bool>>` contract the method advertises.
    // Awaited, the enclosing `catch` converts it into a Left.
    test(
      'a throw inside the async branch becomes a Left, not an exception',
      () async {
        // Round-trip a real session through storeSession so the stored JSON is
        // exactly what getStoredSession expects, then hand it back on read.
        final user = generateValidUser();
        final profile = UserProfile(
          id: user.id,
          email: user.email,
          displayName: 'Test',
          preferredCurrency: 'VND',
          languageCode: 'vi',
          createdAt: user.createdAt,
          updatedAt: user.createdAt,
        );
        await service.storeSession(
          accessToken: 'access_123',
          refreshToken: 'refresh_456',
          user: user,
          userProfile: profile,
        );
        final storedJson =
            verify(
                  mockStorage.write(
                    key: 'grex_session_data',
                    value: captureAnyNamed('value'),
                  ),
                ).captured.last
                as String;
        when(
          mockStorage.read(key: 'grex_session_data'),
        ).thenAnswer((_) async => storedJson);

        // Throw from inside the async fold branch.
        when(mockSupabaseClient.auth).thenThrow(Exception('auth unavailable'));

        final result = await service.validateSession();

        expect(
          result.isLeft(),
          isTrue,
          reason:
              'the throw must surface as a typed failure, not escape the '
              'Either contract',
        );
      },
    );
  });

  group('SecureSessionService token storage', () {
    // #35: the app used to mirror the session's tokens into
    // AppConstants.tokenKey / refreshTokenKey for AuthInterceptor, which is
    // unused scaffolding (#7). That left a second copy of live credentials that
    // nothing read. The tokens are already inside the stored session record, so
    // the duplicate is gone. Whoever wires the Dio layer up reads them from the
    // session service instead of re-adding this.
    test('storeSession does not write the standalone token keys', () async {
      final user = generateValidUser();
      final profile = UserProfile(
        id: user.id,
        email: user.email,
        displayName: 'Test',
        preferredCurrency: 'VND',
        languageCode: 'vi',
        createdAt: user.createdAt,
        updatedAt: user.createdAt,
      );

      final result = await service.storeSession(
        accessToken: 'access_123',
        refreshToken: 'refresh_456',
        user: user,
        userProfile: profile,
      );

      expect(result.isRight(), isTrue);
      verifyNever(
        mockStorage.write(key: AppConstants.tokenKey, value: anyNamed('value')),
      );
      verifyNever(
        mockStorage.write(
          key: AppConstants.refreshTokenKey,
          value: anyNamed('value'),
        ),
      );
    });

    test('storeSession still persists the session itself', () async {
      // Removing the duplicate must not remove the record that actually
      // matters -- the tokens live inside it.
      final user = generateValidUser();
      final profile = UserProfile(
        id: user.id,
        email: user.email,
        displayName: 'Test',
        preferredCurrency: 'VND',
        languageCode: 'vi',
        createdAt: user.createdAt,
        updatedAt: user.createdAt,
      );

      await service.storeSession(
        accessToken: 'access_123',
        refreshToken: 'refresh_456',
        user: user,
        userProfile: profile,
      );

      final stored =
          verify(
                mockStorage.write(
                  key: 'grex_session_data',
                  value: captureAnyNamed('value'),
                ),
              ).captured.last
              as String;
      expect(stored, contains('access_123'));
      expect(stored, contains('refresh_456'));
    });

    test('clearSession still deletes any token an older build wrote', () async {
      // The deletes are kept deliberately: installs upgraded from a build that
      // did write these keys must still have them cleared on sign-out. A stale
      // delete is harmless; a missing one leaves credentials behind.
      await service.clearSession();

      verify(mockStorage.delete(key: AppConstants.tokenKey)).called(1);
      verify(mockStorage.delete(key: AppConstants.refreshTokenKey)).called(1);
      verify(mockStorage.delete(key: 'grex_session_data')).called(1);
    });
  });
}
