import 'package:dartz/dartz.dart';
import 'package:grex/features/expenses/data/models/expense_model.dart';
import 'package:grex/features/expenses/data/models/expense_participant_model.dart';
import 'package:grex/features/expenses/domain/entities/expense.dart';
import 'package:grex/features/expenses/domain/failures/expense_failure.dart';
import 'package:grex/features/expenses/domain/repositories/expense_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase implementation of ExpenseRepository
class SupabaseExpenseRepository implements ExpenseRepository {
  /// Creates a [SupabaseExpenseRepository] instance
  const SupabaseExpenseRepository({
    required SupabaseClient supabaseClient,
  }) : _supabaseClient = supabaseClient;
  final SupabaseClient _supabaseClient;

  /// Get current user ID
  String? get _currentUserId => _supabaseClient.auth.currentUser?.id;

  @override
  Future<Either<ExpenseFailure, List<Expense>>> getGroupExpenses(
    String groupId,
  ) async {
    try {
      final userId = _currentUserId;
      if (userId == null) {
        return const Left(ExpenseAuthenticationFailure());
      }

      // Query expenses for the group with RLS-compliant query
      final response = await _supabaseClient
          .from('expenses')
          .select('''
            *,
            expense_participants(
              id,
              user_id,
              display_name,
              share_amount,
              share_percentage
            )
          ''')
          .eq('group_id', groupId)
          .order('expense_date', ascending: false);

      final expenses = (response as List<dynamic>)
          .map((json) => ExpenseModel.fromJson(json as Map<String, dynamic>))
          .cast<Expense>()
          .toList();

      return Right(expenses);
    } on PostgrestException catch (e) {
      return Left(_mapPostgrestException(e));
    } on Exception catch (e) {
      return Left(UnknownExpenseFailure(e.toString()));
    }
  }

  @override
  Future<Either<ExpenseFailure, Expense>> createExpense(Expense expense) async {
    try {
      final userId = _currentUserId;
      if (userId == null) {
        return const Left(ExpenseAuthenticationFailure());
      }

      // Validate expense data
      final validationError = _validateExpenseData(expense);
      if (validationError != null) {
        return Left(validationError);
      }

      // Validate split totals
      final splitValidationError = _validateSplitTotals(expense);
      if (splitValidationError != null) {
        return Left(splitValidationError);
      }

      // Check if user is member of the group
      final isMember = await _checkGroupMembership(expense.groupId, userId);
      if (!isMember) {
        return const Left(
          InsufficientExpensePermissionsFailure('create expense'),
        );
      }

      // Create expense
      final expenseModel = ExpenseModel.fromEntity(expense);
      final expenseResponse = await _supabaseClient
          .from('expenses')
          .insert(expenseModel.toInsertJson())
          .select()
          .single();

      final createdExpenseId = expenseResponse['id'] as String;

      // Create expense participants
      final participantsJson = expense.participants.map((participant) {
        return ExpenseParticipantModel.fromEntity(
          participant,
        ).toInsertJson(expenseId: createdExpenseId);
      }).toList();

      await _supabaseClient
          .from('expense_participants')
          .insert(participantsJson);

      // Fetch the complete expense with participants
      return getExpenseById(createdExpenseId);
    } on PostgrestException catch (e) {
      return Left(_mapPostgrestException(e));
    } on Exception catch (e) {
      return Left(UnknownExpenseFailure(e.toString()));
    }
  }

  @override
  Future<Either<ExpenseFailure, Expense>> updateExpense(Expense expense) async {
    try {
      final userId = _currentUserId;
      if (userId == null) {
        return const Left(ExpenseAuthenticationFailure());
      }

      // Check permissions
      final hasPermissionResult = await hasPermission(expense.id, 'update');
      if (hasPermissionResult.isLeft()) {
        return hasPermissionResult.fold(
          Left.new,
          (_) => const Left(
            InsufficientExpensePermissionsFailure('update expense'),
          ),
        );
      }

      final userHasPermission = hasPermissionResult.getOrElse(() => false);
      if (!userHasPermission) {
        return const Left(
          InsufficientExpensePermissionsFailure('update expense'),
        );
      }

      // Validate expense data
      final validationError = _validateExpenseData(expense);
      if (validationError != null) {
        return Left(validationError);
      }

      // Validate split totals
      final splitValidationError = _validateSplitTotals(expense);
      if (splitValidationError != null) {
        return Left(splitValidationError);
      }

      // Update expense
      final expenseModel = ExpenseModel.fromEntity(expense);
      await _supabaseClient
          .from('expenses')
          .update(expenseModel.toUpdateJson())
          .eq('id', expense.id);

      // Delete existing participants
      await _supabaseClient
          .from('expense_participants')
          .delete()
          .eq('expense_id', expense.id);

      // Create updated participants
      final participantsJson = expense.participants.map((participant) {
        return ExpenseParticipantModel.fromEntity(
          participant,
        ).toInsertJson(expenseId: expense.id);
      }).toList();

      await _supabaseClient
          .from('expense_participants')
          .insert(participantsJson);

      // Fetch updated expense
      return getExpenseById(expense.id);
    } on PostgrestException catch (e) {
      return Left(_mapPostgrestException(e));
    } on Exception catch (e) {
      return Left(UnknownExpenseFailure(e.toString()));
    }
  }

  @override
  Future<Either<ExpenseFailure, void>> deleteExpense(String expenseId) async {
    try {
      final userId = _currentUserId;
      if (userId == null) {
        return const Left(ExpenseAuthenticationFailure());
      }

      // Check permissions
      final hasPermissionResult = await hasPermission(expenseId, 'delete');
      if (hasPermissionResult.isLeft()) {
        return hasPermissionResult.fold(
          Left.new,
          (_) => const Left(
            InsufficientExpensePermissionsFailure('delete expense'),
          ),
        );
      }

      final userHasPermission = hasPermissionResult.getOrElse(() => false);
      if (!userHasPermission) {
        return const Left(
          InsufficientExpensePermissionsFailure('delete expense'),
        );
      }

      // Delete expense (cascade will handle participants)
      await _supabaseClient.from('expenses').delete().eq('id', expenseId);

      return const Right(null);
    } on PostgrestException catch (e) {
      return Left(_mapPostgrestException(e));
    } on Exception catch (e) {
      return Left(UnknownExpenseFailure(e.toString()));
    }
  }

  @override
  Future<Either<ExpenseFailure, Expense>> getExpenseById(
    String expenseId,
  ) async {
    try {
      final userId = _currentUserId;
      if (userId == null) {
        return const Left(ExpenseAuthenticationFailure());
      }

      final response = await _supabaseClient
          .from('expenses')
          .select('''
            *,
            expense_participants(
              id,
              user_id,
              display_name,
              share_amount,
              share_percentage
            )
          ''')
          .eq('id', expenseId)
          .single();

      final expense = ExpenseModel.fromJson(response);
      return Right(expense);
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST116') {
        return Left(ExpenseNotFoundFailure(expenseId));
      }
      return Left(_mapPostgrestException(e));
    } on Exception catch (e) {
      return Left(UnknownExpenseFailure(e.toString()));
    }
  }

  @override
  Stream<List<Expense>> watchGroupExpenses(String groupId) {
    final userId = _currentUserId;
    if (userId == null) {
      return Stream.error(const ExpenseAuthenticationFailure());
    }

    return _supabaseClient
        .from('expenses')
        .stream(primaryKey: ['id'])
        .eq('group_id', groupId)
        .order('expense_date')
        .map(
          (data) => data.map(ExpenseModel.fromJson).toList(),
        );
  }

  @override
  Stream<Expense> watchExpense(String expenseId) {
    return _supabaseClient
        .from('expenses')
        .stream(primaryKey: ['id'])
        .eq('id', expenseId)
        .map(
          (data) => data.isNotEmpty
              ? ExpenseModel.fromJson(data.first)
              : throw ExpenseNotFoundFailure(expenseId),
        );
  }

  @override
  Future<Either<ExpenseFailure, List<Expense>>> searchExpenses(
    String groupId,
    String query,
  ) async {
    try {
      final userId = _currentUserId;
      if (userId == null) {
        return const Left(ExpenseAuthenticationFailure());
      }

      if (query.trim().isEmpty) {
        return getGroupExpenses(groupId);
      }

      // Search by description or amount
      final response = await _supabaseClient
          .from('expenses')
          .select('''
            *,
            expense_participants(
              id,
              user_id,
              display_name,
              share_amount,
              share_percentage
            )
          ''')
          .eq('group_id', groupId)
          .or(
            'description.ilike.%$query%,'
            'amount.eq.${double.tryParse(query) ?? -1}',
          )
          .order('expense_date', ascending: false);

      final expenses = (response as List<dynamic>)
          .map((json) => ExpenseModel.fromJson(json as Map<String, dynamic>))
          .cast<Expense>()
          .toList();

      return Right(expenses);
    } on PostgrestException catch (e) {
      return Left(_mapPostgrestException(e));
    } on Exception catch (e) {
      return Left(UnknownExpenseFailure(e.toString()));
    }
  }

  @override
  Future<Either<ExpenseFailure, List<Expense>>> getExpensesByDateRange(
    String groupId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final userId = _currentUserId;
      if (userId == null) {
        return const Left(ExpenseAuthenticationFailure());
      }

      final response = await _supabaseClient
          .from('expenses')
          .select('''
            *,
            expense_participants(
              id,
              user_id,
              display_name,
              share_amount,
              share_percentage
            )
          ''')
          .eq('group_id', groupId)
          .gte('expense_date', startDate.toIso8601String())
          .lte('expense_date', endDate.toIso8601String())
          .order('expense_date', ascending: false);

      final expenses = (response as List<dynamic>)
          .map((json) => ExpenseModel.fromJson(json as Map<String, dynamic>))
          .cast<Expense>()
          .toList();

      return Right(expenses);
    } on PostgrestException catch (e) {
      return Left(_mapPostgrestException(e));
    } on Exception catch (e) {
      return Left(UnknownExpenseFailure(e.toString()));
    }
  }

  @override
  Future<Either<ExpenseFailure, List<Expense>>> getExpensesByParticipant(
    String groupId,
    String participantId,
  ) async {
    try {
      final userId = _currentUserId;
      if (userId == null) {
        return const Left(ExpenseAuthenticationFailure());
      }

      final response = await _supabaseClient
          .from('expenses')
          .select('''
            *,
            expense_participants!inner(
              id,
              user_id,
              display_name,
              share_amount,
              share_percentage
            )
          ''')
          .eq('group_id', groupId)
          .eq('expense_participants.user_id', participantId)
          .order('expense_date', ascending: false);

      final expenses = (response as List<dynamic>)
          .map((json) => ExpenseModel.fromJson(json as Map<String, dynamic>))
          .cast<Expense>()
          .toList();

      return Right(expenses);
    } on PostgrestException catch (e) {
      return Left(_mapPostgrestException(e));
    } on Exception catch (e) {
      return Left(UnknownExpenseFailure(e.toString()));
    }
  }

  @override
  Future<Either<ExpenseFailure, List<Expense>>> getExpensesPaginated(
    String groupId, {
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final userId = _currentUserId;
      if (userId == null) {
        return const Left(ExpenseAuthenticationFailure());
      }

      final response = await _supabaseClient
          .from('expenses')
          .select('''
            *,
            expense_participants(
              id,
              user_id,
              display_name,
              share_amount,
              share_percentage
            )
          ''')
          .eq('group_id', groupId)
          .order('expense_date', ascending: false)
          .range(offset, offset + limit - 1);

      final expenses = (response as List<dynamic>)
          .map((json) => ExpenseModel.fromJson(json as Map<String, dynamic>))
          .cast<Expense>()
          .toList();

      return Right(expenses);
    } on PostgrestException catch (e) {
      return Left(_mapPostgrestException(e));
    } on Exception catch (e) {
      return Left(UnknownExpenseFailure(e.toString()));
    }
  }

  @override
  Future<Either<ExpenseFailure, bool>> hasPermission(
    String expenseId,
    String action,
  ) async {
    try {
      final userId = _currentUserId;
      if (userId == null) {
        return const Left(ExpenseAuthenticationFailure());
      }

      // Get expense details
      final expenseResponse = await _supabaseClient
          .from('expenses')
          .select('payer_id, group_id')
          .eq('id', expenseId)
          .maybeSingle();

      if (expenseResponse == null) {
        return Left(ExpenseNotFoundFailure(expenseId));
      }

      final payerId = expenseResponse['payer_id'] as String;
      final groupId = expenseResponse['group_id'] as String;

      // Check if user is the payer (can always edit/delete own expenses)
      if (payerId == userId) {
        return const Right(true);
      }

      // Check if user is group administrator
      final memberResponse = await _supabaseClient
          .from('group_members')
          .select('role')
          .eq('group_id', groupId)
          .eq('user_id', userId)
          .maybeSingle();

      if (memberResponse == null) {
        return const Right(false);
      }

      final role = memberResponse['role'] as String;
      final isAllowed = _checkPermission(role, action);

      return Right(isAllowed);
    } on PostgrestException catch (e) {
      return Left(_mapPostgrestException(e));
    } on Exception catch (e) {
      return Left(UnknownExpenseFailure(e.toString()));
    }
  }

  @override
  Future<Either<ExpenseFailure, bool>> validateExpenseSplit(
    String expenseId,
  ) async {
    try {
      final userId = _currentUserId;
      if (userId == null) {
        return const Left(ExpenseAuthenticationFailure());
      }

      // Use Supabase function for validation
      final result = await _supabaseClient.rpc<bool>(
        'validate_expense_split',
        params: {
          'expense_id_param': expenseId,
        },
      );

      return Right(result);
    } on PostgrestException catch (e) {
      return Left(_mapPostgrestException(e));
    } on Exception catch (e) {
      return Left(UnknownExpenseFailure(e.toString()));
    }
  }

  // Helper methods

  ExpenseFailure? _validateExpenseData(Expense expense) {
    if (expense.description.trim().isEmpty ||
        expense.description.length > 200) {
      return const InvalidExpenseDescriptionFailure();
    }

    if (expense.amount <= 0) {
      return InvalidExpenseAmountFailure(
        'Expense amount must be positive, got ${expense.amount}',
      );
    }

    if (expense.currency.trim().isEmpty) {
      return InvalidExpenseCurrencyFailure(expense.currency);
    }

    if (expense.participants.isEmpty) {
      return const InvalidParticipantsFailure('No participants');
    }

    return null;
  }

  ExpenseFailure? _validateSplitTotals(Expense expense) {
    final totalShareAmount = expense.participants.fold<double>(
      0,
      (sum, participant) => sum + participant.shareAmount,
    );

    // Allow small rounding differences (1 cent)
    const tolerance = 0.01;
    if ((totalShareAmount - expense.amount).abs() > tolerance) {
      return InvalidSplitFailure(
        'Split total ($totalShareAmount) does not match expense '
        'amount (${expense.amount})',
      );
    }

    // Check percentage totals if using percentage split
    final hasPercentages = expense.participants.any(
      (p) => p.sharePercentage > 0,
    );
    if (hasPercentages) {
      final totalPercentage = expense.participants.fold<double>(
        0,
        (sum, participant) => sum + participant.sharePercentage,
      );

      if ((totalPercentage - 100.0).abs() > tolerance) {
        return InvalidSplitFailure(
          'Split percentages total ($totalPercentage%) does not equal 100%',
        );
      }
    }

    return null;
  }

  Future<bool> _checkGroupMembership(String groupId, String userId) async {
    final response = await _supabaseClient
        .from('group_members')
        .select('id')
        .eq('group_id', groupId)
        .eq('user_id', userId)
        .maybeSingle();

    return response != null;
  }

  bool _checkPermission(String role, String action) {
    switch (action) {
      case 'update':
      case 'delete':
        // Administrators can edit/delete any expense
        return role == 'administrator';
      default:
        return false;
    }
  }

  ExpenseFailure _mapPostgrestException(PostgrestException e) {
    switch (e.code) {
      case '23505': // Unique violation
        return const ExpenseDatabaseFailure('Duplicate data');
      case '23503': // Foreign key violation
        return const ExpenseDatabaseFailure('Invalid reference');
      case '42501': // Insufficient privilege
        return const InsufficientExpensePermissionsFailure();
      case 'PGRST116': // Not found
        return const ExpenseNotFoundFailure();
      default:
        return ExpenseDatabaseFailure(e.message);
    }
  }
}
