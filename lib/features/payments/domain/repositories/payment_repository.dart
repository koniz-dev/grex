import 'package:dartz/dartz.dart';
import 'package:grex/features/payments/domain/entities/payment.dart';
import 'package:grex/features/payments/domain/failures/payment_failure.dart';

/// Repository interface for payment operations
abstract class PaymentRepository {
  /// Get all payments for a specific group
  Future<Either<PaymentFailure, List<Payment>>> getGroupPayments(
    String groupId,
  );

  /// Create a new payment in a group
  Future<Either<PaymentFailure, Payment>> createPayment(Payment payment);

  /// Delete a payment
  Future<Either<PaymentFailure, void>> deletePayment(String paymentId);

  /// Get a specific payment by ID
  Future<Either<PaymentFailure, Payment>> getPaymentById(String paymentId);

  /// Watch payments for a group for real-time updates
  Stream<List<Payment>> watchGroupPayments(String groupId);

  /// Watch a specific payment for real-time updates
  Stream<Payment> watchPayment(String paymentId);

  /// Get payments with pagination
  Future<Either<PaymentFailure, List<Payment>>> getPaymentsPaginated(
    String groupId, {
    int limit = 20,
    int offset = 0,
  });

  /// Get payments by payer
  Future<Either<PaymentFailure, List<Payment>>> getPaymentsByPayer(
    String groupId,
    String payerId,
  );

  /// Get payments by recipient
  Future<Either<PaymentFailure, List<Payment>>> getPaymentsByRecipient(
    String groupId,
    String recipientId,
  );

  /// Get payments between two users
  Future<Either<PaymentFailure, List<Payment>>> getPaymentsBetweenUsers(
    String groupId,
    String userId1,
    String userId2,
  );

  /// Check if user has permission to perform action on payment
  Future<Either<PaymentFailure, bool>> hasPermission(
    String paymentId,
    String action,
  );

  /// Validate payment constraints
  Future<Either<PaymentFailure, bool>> validatePayment(Payment payment);
}
