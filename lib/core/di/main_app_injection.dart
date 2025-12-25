import 'package:get_it/get_it.dart';
import 'package:grex/features/balances/data/repositories/repositories.dart';
import 'package:grex/features/balances/domain/repositories/balance_repository.dart';
import 'package:grex/features/balances/presentation/bloc/balance_bloc.dart';
import 'package:grex/features/expenses/data/repositories/repositories.dart';
import 'package:grex/features/expenses/domain/repositories/expense_repository.dart';
import 'package:grex/features/expenses/presentation/bloc/expense_bloc.dart';
import 'package:grex/features/groups/data/repositories/repositories.dart';
import 'package:grex/features/groups/domain/repositories/group_repository.dart';
// BLoC imports
import 'package:grex/features/groups/presentation/bloc/group_bloc.dart';
import 'package:grex/features/payments/data/repositories/repositories.dart';
import 'package:grex/features/payments/domain/repositories/payment_repository.dart';
import 'package:grex/features/payments/presentation/bloc/payment_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Configure dependencies for main app features
/// This will be populated as we implement the repositories and services
void configureMainAppDependencies() {
  final getIt = GetIt.instance;

  // Register repositories
  // Groups
  getIt
    ..registerLazySingleton<GroupRepository>(
      () => SupabaseGroupRepository(
        Supabase.instance.client,
      ),
    )
    // Expenses
    ..registerLazySingleton<ExpenseRepository>(
      () => SupabaseExpenseRepository(
        supabaseClient: Supabase.instance.client,
      ),
    )
    // Payments
    ..registerLazySingleton<PaymentRepository>(
      () => SupabasePaymentRepository(
        supabaseClient: Supabase.instance.client,
      ),
    )
    // Balances
    ..registerLazySingleton<BalanceRepository>(
      () => SupabaseBalanceRepository(
        supabaseClient: Supabase.instance.client,
      ),
    )
    // Register BLoCs
    ..registerFactory<GroupBloc>(
      () => GroupBloc(
        getIt<GroupRepository>(),
      ),
    )
    ..registerFactory<ExpenseBloc>(
      () => ExpenseBloc(
        getIt<ExpenseRepository>(),
      ),
    )
    ..registerFactory<PaymentBloc>(
      () => PaymentBloc(
        getIt<PaymentRepository>(),
      ),
    )
    ..registerFactory<BalanceBloc>(
      () => BalanceBloc(
        balanceRepository: getIt<BalanceRepository>(),
      ),
    );
}
