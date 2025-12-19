import 'package:grex/core/errors/failures.dart' as core;
import 'package:grex/core/utils/result.dart';
import 'package:grex/features/auth/domain/repositories/auth_repository.dart';

/// Use case for user logout
class LogoutUseCase {
  /// Creates a [LogoutUseCase] with the given [repository]
  LogoutUseCase(this.repository);

  /// Authentication repository for logout operations
  final AuthRepository repository;

  /// Executes logout for the current user
  Future<Result<void>> call() async {
    final either = await repository.signOut();

    return either.fold(
      (authFailure) => ResultFailure(
        core.AuthFailure(authFailure.message),
      ),
      (_) => const Success(null),
    );
  }
}
