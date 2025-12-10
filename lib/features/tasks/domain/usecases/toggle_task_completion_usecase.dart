import 'package:grex/core/utils/result.dart';
import 'package:grex/features/tasks/domain/entities/task.dart';
import 'package:grex/features/tasks/domain/repositories/tasks_repository.dart';

/// Use case for toggling task completion status
class ToggleTaskCompletionUseCase {
  /// Creates a [ToggleTaskCompletionUseCase] with the given [repository]
  ToggleTaskCompletionUseCase(this.repository);

  /// Tasks repository for toggling task completion
  final TasksRepository repository;

  /// Executes toggling task completion by [id]
  Future<Result<Task>> call(String id) async {
    return repository.toggleTaskCompletion(id);
  }
}
