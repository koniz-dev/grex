import 'package:dartz/dartz.dart';
import 'package:grex/features/payments/data/models/payment_model.dart';
import 'package:grex/features/payments/domain/entities/payment.dart';
import 'package:grex/features/payments/domain/failures/payment_failure.dart';
import 'package:grex/features/payments/domain/repositories/payment_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase implementation of PaymentRepository
class SupabasePaymentRepository implements PaymentRepository {
  /// Creates a [SupabasePaymentRepository] instance
  const SupabasePaymentRepository({
    required SupabaseClient supabaseClient,
  }) : _supabaseClient = supabaseClient;
  final SupabaseClient _supabaseClient;

  /// Get current user ID
  String? get _currentUserId => _supabaseClient.auth.currentUser?.id;

  @override
  Future<Either<PaymentFailure, List<Payment>>> getGroupPayments(
    String groupId,
  ) async {
    try {
      final userId = _currentUserId;
      if (userId == null) {
        return const Left(PaymentAuthenticationFailure());
      }

      // Query payments for the group with RLS-compliant query
      final response = await _supabaseClient
          .from('payments')
          .select()
          .eq('group_id', groupId)
          .order('payment_date', ascending: false);

      final payments = (response as List<dynamic>)
          .map((json) => PaymentModel.fromJson(json as Map<String, dynamic>))
          .cast<Payment>()
          .toList();

      return Right(payments);
    } on PostgrestException catch (e) {
      return Left(_mapPostgrestException(e));
    } on Exception catch (e) {
      return Left(UnknownPaymentFailure(e.toString()));
    }
  }

  @override
  Future<Either<PaymentFailure, Payment>> createPayment(Payment payment) async {
    try {
      final userId = _currentUserId;
      if (userId == null) {
        return const Left(PaymentAuthenticationFailure());
      }

      // Validate payment data
      final validationError = _validatePaymentData(payment);
      if (validationError != null) {
        return Left(validationError);
      }

      // Check if user is member of the group
      final isMember = await _checkGroupMembership(payment.groupId, userId);
      if (!isMember) {
        return const Left(
          InsufficientPaymentPermissionsFailure('create payment'),
        );
      }

      // Validate payment constraints
      final constraintValidation = await validatePayment(payment);
      if (constraintValidation.isLeft()) {
        return constraintValidation.fold(
          Left.new,
          (_) => const Left(PaymentDatabaseFailure('Validation failed')),
        );
      }

      // Create payment
      final paymentModel = PaymentModel.fromEntity(payment);
      final paymentResponse = await _supabaseClient
          .from('payments')
          .insert(paymentModel.toInsertJson())
          .select()
          .single();

      final createdPaymentId = paymentResponse['id'] as String;

      // Fetch the complete payment
      return getPaymentById(createdPaymentId);
    } on PostgrestException catch (e) {
      return Left(_mapPostgrestException(e));
    } on Exception catch (e) {
      return Left(UnknownPaymentFailure(e.toString()));
    }
  }

  @override
  Future<Either<PaymentFailure, void>> deletePayment(String paymentId) async {
    try {
      final userId = _currentUserId;
      if (userId == null) {
        return const Left(PaymentAuthenticationFailure());
      }

      // Check permissions
      final hasPermissionResult = await hasPermission(paymentId, 'delete');
      if (hasPermissionResult.isLeft()) {
        return hasPermissionResult.fold(
          Left.new,
          (_) => const Left(
            InsufficientPaymentPermissionsFailure('delete payment'),
          ),
        );
      }

      final userHasPermission = hasPermissionResult.getOrElse(() => false);
      if (!userHasPermission) {
        return const Left(
          InsufficientPaymentPermissionsFailure('delete payment'),
        );
      }

      // Delete payment
      await _supabaseClient.from('payments').delete().eq('id', paymentId);

      return const Right(null);
    } on PostgrestException catch (e) {
      return Left(_mapPostgrestException(e));
    } on Exception catch (e) {
      return Left(UnknownPaymentFailure(e.toString()));
    }
  }

  @override
  Future<Either<PaymentFailure, Payment>> getPaymentById(
    String paymentId,
  ) async {
    try {
      final userId = _currentUserId;
      if (userId == null) {
        return const Left(PaymentAuthenticationFailure());
      }

      final response = await _supabaseClient
          .from('payments')
          .select()
          .eq('id', paymentId)
          .single();

      final payment = PaymentModel.fromJson(response);
      return Right(payment);
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST116') {
        return Left(PaymentNotFoundFailure(paymentId));
      }
      return Left(_mapPostgrestException(e));
    } on Exception catch (e) {
      return Left(UnknownPaymentFailure(e.toString()));
    }
  }

  @override
  Stream<List<Payment>> watchGroupPayments(String groupId) {
    final userId = _currentUserId;
    if (userId == null) {
      return Stream.error(const PaymentAuthenticationFailure());
    }

    return _supabaseClient
        .from('payments')
        .stream(primaryKey: ['id'])
        .eq('group_id', groupId)
        .order('payment_date')
        .map(
          (data) => data.map(PaymentModel.fromJson).cast<Payment>().toList(),
        );
  }

  @override
  Stream<Payment> watchPayment(String paymentId) {
    return _supabaseClient
        .from('payments')
        .stream(primaryKey: ['id'])
        .eq('id', paymentId)
        .map(
          (data) => data.isNotEmpty
              ? PaymentModel.fromJson(data.first)
              : throw PaymentNotFoundFailure(paymentId),
        );
  }

  @override
  Future<Either<PaymentFailure, List<Payment>>> getPaymentsPaginated(
    String groupId, {
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final userId = _currentUserId;
      if (userId == null) {
        return const Left(PaymentAuthenticationFailure());
      }

      final response = await _supabaseClient
          .from('payments')
          .select()
          .eq('group_id', groupId)
          .order('payment_date', ascending: false)
          .range(offset, offset + limit - 1);

      final payments = (response as List<dynamic>)
          .map((json) => PaymentModel.fromJson(json as Map<String, dynamic>))
          .cast<Payment>()
          .toList();

      return Right(payments);
    } on PostgrestException catch (e) {
      return Left(_mapPostgrestException(e));
    } on Exception catch (e) {
      return Left(UnknownPaymentFailure(e.toString()));
    }
  }

  @override
  Future<Either<PaymentFailure, List<Payment>>> getPaymentsByPayer(
    String groupId,
    String payerId,
  ) async {
    try {
      final userId = _currentUserId;
      if (userId == null) {
        return const Left(PaymentAuthenticationFailure());
      }

      final response = await _supabaseClient
          .from('payments')
          .select()
          .eq('group_id', groupId)
          .eq('payer_id', payerId)
          .order('payment_date', ascending: false);

      final payments = (response as List<dynamic>)
          .map((json) => PaymentModel.fromJson(json as Map<String, dynamic>))
          .cast<Payment>()
          .toList();

      return Right(payments);
    } on PostgrestException catch (e) {
      return Left(_mapPostgrestException(e));
    } on Exception catch (e) {
      return Left(UnknownPaymentFailure(e.toString()));
    }
  }

  @override
  Future<Either<PaymentFailure, List<Payment>>> getPaymentsByRecipient(
    String groupId,
    String recipientId,
  ) async {
    try {
      final userId = _currentUserId;
      if (userId == null) {
        return const Left(PaymentAuthenticationFailure());
      }

      final response = await _supabaseClient
          .from('payments')
          .select()
          .eq('group_id', groupId)
          .eq('recipient_id', recipientId)
          .order('payment_date', ascending: false);

      final payments = (response as List<dynamic>)
          .map((json) => PaymentModel.fromJson(json as Map<String, dynamic>))
          .cast<Payment>()
          .toList();

      return Right(payments);
    } on PostgrestException catch (e) {
      return Left(_mapPostgrestException(e));
    } on Exception catch (e) {
      return Left(UnknownPaymentFailure(e.toString()));
    }
  }

  @override
  Future<Either<PaymentFailure, List<Payment>>> getPaymentsBetweenUsers(
    String groupId,
    String userId1,
    String userId2,
  ) async {
    try {
      final userId = _currentUserId;
      if (userId == null) {
        return const Left(PaymentAuthenticationFailure());
      }

      final response = await _supabaseClient
          .from('payments')
          .select()
          .eq('group_id', groupId)
          .or(
            'and(payer_id.eq.$userId1,recipient_id.eq.$userId2),'
            'and(payer_id.eq.$userId2,recipient_id.eq.$userId1)',
          )
          .order('payment_date', ascending: false);

      final payments = (response as List<dynamic>)
          .map((json) => PaymentModel.fromJson(json as Map<String, dynamic>))
          .cast<Payment>()
          .toList();

      return Right(payments);
    } on PostgrestException catch (e) {
      return Left(_mapPostgrestException(e));
    } on Exception catch (e) {
      return Left(UnknownPaymentFailure(e.toString()));
    }
  }

  @override
  Future<Either<PaymentFailure, bool>> hasPermission(
    String paymentId,
    String action,
  ) async {
    try {
      final userId = _currentUserId;
      if (userId == null) {
        return const Left(PaymentAuthenticationFailure());
      }

      // Get payment details
      final paymentResponse = await _supabaseClient
          .from('payments')
          .select('payer_id, recipient_id, group_id')
          .eq('id', paymentId)
          .maybeSingle();

      if (paymentResponse == null) {
        return Left(PaymentNotFoundFailure(paymentId));
      }

      final payerId = paymentResponse['payer_id'] as String;
      final recipientId = paymentResponse['recipient_id'] as String;
      final groupId = paymentResponse['group_id'] as String;

      // Check if user is involved in the payment (payer or recipient)
      if (payerId == userId || recipientId == userId) {
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
      final hasPermission = _checkPermission(role, action);

      return Right(hasPermission);
    } on PostgrestException catch (e) {
      return Left(_mapPostgrestException(e));
    } on Exception catch (e) {
      return Left(UnknownPaymentFailure(e.toString()));
    }
  }

  @override
  Future<Either<PaymentFailure, bool>> validatePayment(Payment payment) async {
    try {
      final userId = _currentUserId;
      if (userId == null) {
        return const Left(PaymentAuthenticationFailure());
      }

      // Validate basic constraints
      if (payment.amount <= 0) {
        return Left(
          InvalidPaymentAmountFailure(
            'Payment amount must be positive, got ${payment.amount}',
          ),
        );
      }

      if (payment.payerId == payment.recipientId) {
        return const Left(SelfPaymentFailure());
      }

      // Check if both users are members of the group
      final payerIsMember = await _checkGroupMembership(
        payment.groupId,
        payment.payerId,
      );
      final recipientIsMember = await _checkGroupMembership(
        payment.groupId,
        payment.recipientId,
      );

      if (!payerIsMember) {
        return const Left(PaymentUsersNotInGroupFailure());
      }

      if (!recipientIsMember) {
        return const Left(PaymentUsersNotInGroupFailure());
      }

      return const Right(true);
    } on PostgrestException catch (e) {
      return Left(_mapPostgrestException(e));
    } on Exception catch (e) {
      return Left(UnknownPaymentFailure(e.toString()));
    }
  }

  // Helper methods

  PaymentFailure? _validatePaymentData(Payment payment) {
    if (payment.amount <= 0) {
      return InvalidPaymentAmountFailure(
        'Payment amount must be positive, got ${payment.amount}',
      );
    }

    if (payment.currency.trim().isEmpty) {
      return InvalidPaymentCurrencyFailure(payment.currency);
    }

    if (payment.payerId.trim().isEmpty) {
      return const PayerNotFoundFailure('Payer ID is required');
    }

    if (payment.recipientId.trim().isEmpty) {
      return const RecipientNotFoundFailure('Recipient ID is required');
    }

    if (payment.payerId == payment.recipientId) {
      return const SelfPaymentFailure();
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
      case 'delete':
        // Administrators can delete any payment
        return role == 'administrator';
      default:
        return false;
    }
  }

  PaymentFailure _mapPostgrestException(PostgrestException e) {
    switch (e.code) {
      case '23505': // Unique violation
        return const PaymentDatabaseFailure('Duplicate data');
      case '23503': // Foreign key violation
        return const PaymentDatabaseFailure('Invalid reference');
      case '42501': // Insufficient privilege
        return const InsufficientPaymentPermissionsFailure();
      case 'PGRST116': // Not found
        return const PaymentNotFoundFailure();
      default:
        return PaymentDatabaseFailure(e.message);
    }
  }
}
