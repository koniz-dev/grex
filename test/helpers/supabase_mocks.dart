import 'package:mockito/mockito.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

/// Manual mocks for Supabase classes since they can't be auto-generated
class MockSupabaseClient extends Mock implements supabase.SupabaseClient {
  @override
  supabase.GoTrueClient get auth =>
      super.noSuchMethod(
            Invocation.getter(#auth),
            returnValue: MockGoTrueClient(),
          )
          as supabase.GoTrueClient;
}

class MockGoTrueClient extends Mock implements supabase.GoTrueClient {
  @override
  supabase.Session? get currentSession =>
      super.noSuchMethod(
            Invocation.getter(#currentSession),
          )
          as supabase.Session?;

  @override
  supabase.User? get currentUser =>
      super.noSuchMethod(
            Invocation.getter(#currentUser),
          )
          as supabase.User?;

  @override
  Future<void> signOut({
    supabase.SignOutScope scope = supabase.SignOutScope.global,
  }) =>
      super.noSuchMethod(
            Invocation.method(#signOut, [], {#scope: scope}),
            returnValue: Future<void>.value(),
          )
          as Future<void>;

  @override
  Future<supabase.AuthResponse> refreshSession([String? refreshToken]) =>
      super.noSuchMethod(
            Invocation.method(#refreshSession, [refreshToken]),
            returnValue: Future.value(MockAuthResponse()),
          )
          as Future<supabase.AuthResponse>;
}

class MockUser extends Mock implements supabase.User {
  @override
  String get id =>
      super.noSuchMethod(
            Invocation.getter(#id),
            returnValue: '',
          )
          as String;

  @override
  String? get email =>
      super.noSuchMethod(
            Invocation.getter(#email),
          )
          as String?;

  @override
  String? get emailConfirmedAt =>
      super.noSuchMethod(
            Invocation.getter(#emailConfirmedAt),
          )
          as String?;

  @override
  String get createdAt =>
      super.noSuchMethod(
            Invocation.getter(#createdAt),
            returnValue: '',
          )
          as String;

  @override
  String? get lastSignInAt =>
      super.noSuchMethod(
            Invocation.getter(#lastSignInAt),
          )
          as String?;

  @override
  Map<String, dynamic> get appMetadata =>
      super.noSuchMethod(
            Invocation.getter(#appMetadata),
            returnValue: <String, dynamic>{},
          )
          as Map<String, dynamic>;

  @override
  Map<String, dynamic> get userMetadata =>
      super.noSuchMethod(
            Invocation.getter(#userMetadata),
            returnValue: <String, dynamic>{},
          )
          as Map<String, dynamic>;
}

class MockSession extends Mock implements supabase.Session {
  @override
  supabase.User get user =>
      super.noSuchMethod(
            Invocation.getter(#user),
            returnValue: MockUser(),
          )
          as supabase.User;

  @override
  int? get expiresAt =>
      super.noSuchMethod(
            Invocation.getter(#expiresAt),
          )
          as int?;

  @override
  String get accessToken =>
      super.noSuchMethod(
            Invocation.getter(#accessToken),
            returnValue: '',
          )
          as String;

  @override
  String? get refreshToken =>
      super.noSuchMethod(
            Invocation.getter(#refreshToken),
          )
          as String?;
}

class MockAuthResponse extends Mock implements supabase.AuthResponse {
  @override
  supabase.Session? get session =>
      super.noSuchMethod(
            Invocation.getter(#session),
          )
          as supabase.Session?;
}
