import 'package:grex/core/utils/result.dart';
import 'package:grex/features/tasks/domain/entities/task.dart';
import 'package:grex/features/tasks/domain/repositories/tasks_repository.dart';

/// Use case for updating a task
class UpdateTaskUseCase {
  /// Creates an [UpdateTaskUseCase] with the given [repository]
  UpdateTaskUseCase(this.repository);

  /// Tasks repository for updating tasks
  final TasksRepository repository;

  /// Executes updating a task
  Future<Result<Task>> call(Task task) async {
    final updatedTask = task.copyWith(updatedAt: DateTime.now());
    return repository.updateTask(updatedTask);
  }
}
