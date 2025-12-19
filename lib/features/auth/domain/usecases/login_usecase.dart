import 'package:grex/core/errors/failures.dart' as core;
import 'package:grex/core/utils/result.dart';
import 'package:grex/features/auth/domain/entities/user.dart';
import 'package:grex/features/auth/domain/repositories/auth_repository.dart';

/// Use case for user login
class LoginUseCase {
  /// Creates a [LoginUseCase] with the given [repository]
  LoginUseCase(this.repository);

  /// Authentication repository for login operations
  final AuthRepository repository;

  /// Executes login with [email] and [password]
  Future<Result<User>> call(String email, String password) async {
    final either = await repository.signInWithEmail(
      email: email,
      password: password,
    );

    return either.fold(
      (authFailure) => ResultFailure(
        core.AuthFailure(authFailure.message),
      ),
      Success.new,
    );
  }
}
