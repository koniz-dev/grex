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

  group('SecureSessionService token sync', () {
    test(
      'storeSession writes accessToken and refreshToken to token keys',
      () async {
        const accessToken = 'access_123';
        const refreshToken = 'refresh_456';
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
          accessToken: accessToken,
          refreshToken: refreshToken,
          user: user,
          userProfile: profile,
        );

        expect(result.isRight(), isTrue);
        verify(
          mockStorage.write(
            key: AppConstants.tokenKey,
            value: accessToken,
          ),
        ).called(1);
        verify(
          mockStorage.write(
            key: AppConstants.refreshTokenKey,
            value: refreshToken,
          ),
        ).called(1);
      },
    );

    test('clearSession deletes tokenKey and refreshTokenKey', () async {
      final result = await service.clearSession();

      expect(result.isRight(), isTrue);
      verify(mockStorage.delete(key: AppConstants.tokenKey)).called(1);
      verify(mockStorage.delete(key: AppConstants.refreshTokenKey)).called(1);
    });
  });
}
