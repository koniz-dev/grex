import 'package:dartz/dartz.dart';
import 'package:grex/features/payments/domain/failures/payment_failure.dart';

/// Builds the EMVCo payload string that a VietQR code encodes for a bank
/// transfer.
///
/// This is the string only. Rendering it as a QR image is deliberately not part
/// of this class, and neither is storing anyone's bank details -- the account
/// arrives as a parameter and is never persisted. See issue #34.
///
/// The layout follows the EMVCo Merchant-Presented-Mode QR specification with
/// NAPAS's Vietnam fields. Verified against three independently published
/// payloads whose CRCs recompute correctly under CRC-16/CCITT-FALSE; those
/// vectors are pinned in the test for this file.
///
/// ```text
/// 00 02 01                       payload format indicator
/// 01 02 12                       point of initiation (dynamic)
/// 38 .. 00 10 A000000727         NAPAS GUID
///       01 .. 00 06 <bank BIN>
///             01 .. <account number>
///       02 08 QRIBFTTA           account-to-account transfer
/// 53 03 704                      VND (ISO 4217)
/// 54 .. <amount>
/// 58 02 VN
/// 62 .. 08 .. <description>      optional
/// 63 04 <CRC>
/// ```
class VietQrPayload {
  VietQrPayload._();

  /// EMVCo payload format indicator: version 01.
  static const payloadFormatIndicator = '01';

  /// Point of initiation `12` — dynamic, i.e. the code carries an amount and is
  /// meant to be used once. `11` would mean a static, reusable code; a
  /// settlement is always for a specific sum, so this is always dynamic.
  static const pointOfInitiationDynamic = '12';

  /// NAPAS's registered application identifier.
  static const napasGuid = 'A000000727';

  /// Service code for an account-to-account transfer. (`QRIBFTTC` would be
  /// card-to-card, which this app has no use for.)
  static const serviceCodeAccountTransfer = 'QRIBFTTA';

  /// ISO 4217 numeric code for VND.
  static const currencyVnd = '704';

  /// ISO 3166-1 alpha-2 code for Vietnam.
  static const countryVietnam = 'VN';

  /// A bank BIN is always six digits.
  static const bankBinLength = 6;

  /// EMVCo caps the transaction amount field at 13 characters.
  static const maxAmountLength = 13;

  /// NAPAS caps the transfer description.
  static const maxDescriptionLength = 25;

  /// Build the payload for a transfer of [amountDong] to [accountNumber] at the
  /// bank identified by [bankBin].
  ///
  /// [amountDong] is a whole number of dong. VND has no minor unit in practice,
  /// so unlike the expense calculator there is nothing below the unit to carry:
  /// an `int` here *is* the minor-unit representation, which is why no cents
  /// conversion appears anywhere in this file.
  ///
  /// Returns a [PaymentFailure] rather than a malformed payload when the inputs
  /// cannot produce a valid code.
  static Either<PaymentFailure, String> build({
    required String bankBin,
    required String accountNumber,
    required int amountDong,
    String? description,
  }) {
    final bin = bankBin.trim();
    if (bin.length != bankBinLength || !_isAllDigits(bin)) {
      return Left(
        InvalidBankBinFailure(
          'Bank BIN must be exactly $bankBinLength digits, got "$bankBin"',
        ),
      );
    }

    final account = accountNumber.trim();
    if (account.isEmpty) {
      return const Left(
        InvalidBankAccountNumberFailure('Account number is required'),
      );
    }

    if (amountDong <= 0) {
      return Left(
        InvalidTransferAmountFailure(
          'Transfer amount must be positive, got $amountDong',
        ),
      );
    }

    final amount = amountDong.toString();
    if (amount.length > maxAmountLength) {
      return Left(
        InvalidTransferAmountFailure(
          'Transfer amount exceeds the $maxAmountLength-character field limit, '
          'got $amountDong',
        ),
      );
    }

    final trimmedDescription = description?.trim();
    if (trimmedDescription != null &&
        trimmedDescription.length > maxDescriptionLength) {
      return Left(
        InvalidTransferDescriptionFailure(
          'Transfer description exceeds $maxDescriptionLength characters, '
          'got ${trimmedDescription.length}',
        ),
      );
    }

    final beneficiary = _field('00', bin) + _field('01', account);
    final merchantAccount =
        _field('00', napasGuid) +
        _field('01', beneficiary) +
        _field('02', serviceCodeAccountTransfer);

    final buffer = StringBuffer()
      ..write(_field('00', payloadFormatIndicator))
      ..write(_field('01', pointOfInitiationDynamic))
      ..write(_field('38', merchantAccount))
      ..write(_field('53', currencyVnd))
      ..write(_field('54', amount))
      ..write(_field('58', countryVietnam));

    if (trimmedDescription != null && trimmedDescription.isNotEmpty) {
      buffer.write(_field('62', _field('08', trimmedDescription)));
    }

    // The checksum covers everything up to and including its own tag and
    // length, which is why '6304' is appended before computing it.
    final body = '$buffer${_crcTag}04';
    return Right('$body${_crc16(body)}');
  }

  /// Tag of the checksum field.
  static const _crcTag = '63';

  /// One TLV field: a 2-digit tag, a 2-digit length, then the value.
  static String _field(String tag, String value) {
    final length = value.length.toString().padLeft(2, '0');
    return '$tag$length$value';
  }

  static bool _isAllDigits(String value) =>
      value.isNotEmpty && RegExp(r'^\d+$').hasMatch(value);

  /// CRC-16/CCITT-FALSE: polynomial `0x1021`, initial value `0xFFFF`, no input
  /// or output reflection and no final XOR, rendered as four uppercase hex
  /// digits.
  static String _crc16(String input) {
    var crc = 0xFFFF;
    for (final byte in input.codeUnits) {
      crc ^= byte << 8;
      for (var bit = 0; bit < 8; bit++) {
        crc = (crc & 0x8000) != 0
            ? ((crc << 1) ^ 0x1021) & 0xFFFF
            : (crc << 1) & 0xFFFF;
      }
    }
    return crc.toRadixString(16).toUpperCase().padLeft(4, '0');
  }
}
