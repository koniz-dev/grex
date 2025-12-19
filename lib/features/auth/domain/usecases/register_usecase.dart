import 'package:grex/core/errors/failures.dart' as core;
import 'package:grex/core/utils/result.dart';
import 'package:grex/features/auth/domain/entities/user.dart';
import 'package:grex/features/auth/domain/repositories/auth_repository.dart';

/// Use case for user registration
class RegisterUseCase {
  /// Creates a [RegisterUseCase] with the given [repository]
  RegisterUseCase(this.repository);

  /// Authentication repository for registration operations
  final AuthRepository repository;

  /// Executes registration with [email], [password], and [name]
  Future<Result<User>> call(
    String email,
    String password,
    String name,
  ) async {
    final either = await repository.signUpWithEmail(
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
