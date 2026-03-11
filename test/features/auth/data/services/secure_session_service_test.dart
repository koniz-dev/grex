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
    when(mockStorage.write(key: anyNamed('key'), value: anyNamed('value')))
        .thenAnswer((_) async => {});
    when(mockStorage.delete(key: anyNamed('key'))).thenAnswer((_) async => {});
    when(mockStorage.read(key: anyNamed('key'))).thenAnswer((_) async => null);

    service = SecureSessionService(
      secureStorage: mockStorage,
      supabaseClient: mockSupabaseClient,
      userRepository: mockUserRepository,
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
      verify(mockStorage.write(
        key: AppConstants.tokenKey,
        value: accessToken,
      )).called(1);
      verify(mockStorage.write(
        key: AppConstants.refreshTokenKey,
        value: refreshToken,
      )).called(1);
    });

    test('clearSession deletes tokenKey and refreshTokenKey', () async {
      final result = await service.clearSession();

      expect(result.isRight(), isTrue);
      verify(mockStorage.delete(key: AppConstants.tokenKey)).called(1);
      verify(mockStorage.delete(key: AppConstants.refreshTokenKey)).called(1);
    });
  });
}
