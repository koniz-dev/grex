import 'package:flutter_test/flutter_test.dart';
import 'package:grex/features/payments/domain/failures/payment_failure.dart';
import 'package:grex/features/payments/domain/vietqr_payload.dart';

/// One decoded TLV field.
class Tlv {
  const Tlv(this.tag, this.length, this.value);

  final String tag;
  final int length;
  final String value;
}

/// Parse an EMVCo TLV string, rejecting anything malformed.
///
/// Written here rather than reusing the production code on purpose: a test that
/// parses with the same helper that built the string would agree with itself
/// even if both were wrong about the format.
List<Tlv> parseTlv(String input) {
  final fields = <Tlv>[];
  var index = 0;

  while (index < input.length) {
    if (index + 4 > input.length) {
      fail('truncated field header at offset $index in "$input"');
    }
    final tag = input.substring(index, index + 2);
    final rawLength = input.substring(index + 2, index + 4);
    final length = int.tryParse(rawLength);
    if (length == null) {
      fail('non-numeric length "$rawLength" at offset ${index + 2}');
    }
    index += 4;
    if (index + length > input.length) {
      fail(
        'field $tag claims $length chars but only ${input.length - index} '
        'remain',
      );
    }
    fields.add(Tlv(tag, length, input.substring(index, index + length)));
    index += length;
  }

  return fields;
}

/// CRC-16/CCITT-FALSE, implemented independently of the production code.
int crc16(String input) {
  var crc = 0xFFFF;
  for (final byte in input.codeUnits) {
    crc ^= byte << 8;
    for (var bit = 0; bit < 8; bit++) {
      crc = (crc & 0x8000) != 0
          ? ((crc << 1) ^ 0x1021) & 0xFFFF
          : (crc << 1) & 0xFFFF;
    }
  }
  return crc;
}

String buildOrFail({
  String bankBin = '970423',
  String accountNumber = '0123456789',
  int amountDong = 50000,
  String? description,
}) {
  final result = VietQrPayload.build(
    bankBin: bankBin,
    accountNumber: accountNumber,
    amountDong: amountDong,
    description: description,
  );
  return result.fold(
    (failure) => fail('expected a payload, got ${failure.message}'),
    (payload) => payload,
  );
}

PaymentFailure failureOf({
  String bankBin = '970423',
  String accountNumber = '0123456789',
  int amountDong = 50000,
  String? description,
}) {
  final result = VietQrPayload.build(
    bankBin: bankBin,
    accountNumber: accountNumber,
    amountDong: amountDong,
    description: description,
  );
  return result.fold(
    (failure) => failure,
    (payload) => fail('expected a failure, got "$payload"'),
  );
}

void main() {
  group('published reference vectors', () {
    // Three payloads published independently of this repo. Each is
    // self-validating: the CRC it carries is recomputed here, so a vector that
    // had been transcribed wrongly would fail rather than quietly becoming the
    // standard this implementation is measured against.
    //
    // Sources are cited in docs/verification/issue-34/README.md.
    const vectors = <String, String>{
      'vietqr-parser, no amount':
          '00020001021238570010A0000007270127000697043601130881000458086'
          '0208QRIBFTTA53037045802VN6304CD60',
      'vietqr-parser, merchant with amount':
          '00020001021138570010A0000007270127000697043601130881000458086'
          '0208QRIBFTTA520454115303702540569000550202560410005802VN5921'
          'Cua hang sua Vinamilk6011Ho Chi Minh61057000062220818Thanh toan'
          ' mua sua63043611',
      'viblo, TPBank transfer with amount and description':
          '00020101021238530010A000000727012300069704230109mynamebvh0208'
          'QRIBFTTA53037045405500005802VN62080804test6304AB76',
    };

    for (final entry in vectors.entries) {
      final name = entry.key;
      final payload = entry.value;
      test('$name has a CRC this implementation agrees with', () {
        final body = payload.substring(0, payload.length - 4);
        final declared = payload.substring(payload.length - 4);

        expect(
          body,
          endsWith('6304'),
          reason: 'the checksum covers everything up to and including 6304',
        );
        expect(
          crc16(body).toRadixString(16).toUpperCase().padLeft(4, '0'),
          equals(declared),
        );
      });

      test('$name parses as well-formed TLV', () {
        expect(() => parseTlv(payload), returnsNormally);
      });
    }

    test('a vector with the same inputs reproduces byte for byte', () {
      // The viblo vector: TPBank (970423), account "mynamebvh", 50,000 VND,
      // description "test". If this implementation disagrees with a published
      // payload on identical inputs, one of them is wrong about the format.
      expect(
        buildOrFail(accountNumber: 'mynamebvh', description: 'test'),
        equals(
          '00020101021238530010A000000727012300069704230109mynamebvh0208'
          'QRIBFTTA53037045405500005802VN62080804test6304AB76',
        ),
      );
    });
  });

  group('structure', () {
    test('every emitted field is valid TLV with nothing left over', () {
      final fields = parseTlv(buildOrFail(description: 'Settle up'));

      // parseTlv fails on a bad header or an over-long value, so reaching here
      // means every byte was accounted for.
      expect(fields.map((f) => f.tag), contains('63'));
      for (final field in fields) {
        expect(field.value.length, equals(field.length));
      }
    });

    test('the static fields match the spec', () {
      final byTag = {
        for (final field in parseTlv(buildOrFail())) field.tag: field.value,
      };

      expect(byTag['00'], equals('01'), reason: 'payload format indicator');
      expect(byTag['01'], equals('12'), reason: 'dynamic: carries an amount');
      expect(byTag['53'], equals('704'), reason: 'VND');
      expect(byTag['58'], equals('VN'));
    });

    test('the NAPAS merchant account block is nested correctly', () {
      final byTag = {
        for (final field in parseTlv(buildOrFail(bankBin: '970422')))
          field.tag: field.value,
      };

      final merchant = {
        for (final field in parseTlv(byTag['38']!)) field.tag: field.value,
      };
      expect(merchant['00'], equals('A000000727'), reason: 'NAPAS GUID');
      expect(merchant['02'], equals('QRIBFTTA'), reason: 'account transfer');

      final beneficiary = {
        for (final field in parseTlv(merchant['01']!)) field.tag: field.value,
      };
      expect(beneficiary['00'], equals('970422'), reason: 'bank BIN');
      expect(beneficiary['01'], equals('0123456789'), reason: 'account');
    });

    test('the checksum is correct for a payload we built', () {
      final payload = buildOrFail(description: 'Grex settlement');
      final body = payload.substring(0, payload.length - 4);

      expect(
        crc16(body).toRadixString(16).toUpperCase().padLeft(4, '0'),
        equals(payload.substring(payload.length - 4)),
      );
    });
  });

  group('amount', () {
    test('round-trips exactly across the realistic range', () {
      // VND has no minor unit, so the value carried is a whole number of dong
      // and must survive verbatim -- no rounding, no separators, no decimals.
      for (var amount = 1000; amount <= 100000000; amount += 997) {
        final byTag = {
          for (final field in parseTlv(buildOrFail(amountDong: amount)))
            field.tag: field.value,
        };

        expect(
          byTag['54'],
          equals(amount.toString()),
          reason: 'amount $amount must appear verbatim in tag 54',
        );
        expect(
          int.parse(byTag['54']!),
          equals(amount),
          reason: 'amount $amount must round-trip as an integer',
        );
      }
    });

    test('the boundary values round-trip', () {
      for (final amount in const [1, 1000, 100000000, 9999999999999]) {
        final byTag = {
          for (final field in parseTlv(buildOrFail(amountDong: amount)))
            field.tag: field.value,
        };
        expect(int.parse(byTag['54']!), equals(amount));
      }
    });
  });

  group('description', () {
    test('a payload with one carries it under tag 62 sub-tag 08', () {
      final byTag = {
        for (final field in parseTlv(buildOrFail(description: 'Chia tien an')))
          field.tag: field.value,
      };

      final additional = {
        for (final field in parseTlv(byTag['62']!)) field.tag: field.value,
      };
      expect(additional['08'], equals('Chia tien an'));
    });

    test('a payload without one omits tag 62 entirely', () {
      final tags = parseTlv(buildOrFail()).map((f) => f.tag);
      expect(tags, isNot(contains('62')));
    });

    test('an empty or whitespace description omits tag 62', () {
      for (final blank in const ['', '   ']) {
        final tags = parseTlv(
          buildOrFail(description: blank),
        ).map((f) => f.tag);
        expect(tags, isNot(contains('62')), reason: 'description "$blank"');
      }
    });

    test('both forms still parse cleanly', () {
      expect(() => parseTlv(buildOrFail()), returnsNormally);
      expect(
        () => parseTlv(buildOrFail(description: 'Settle')),
        returnsNormally,
      );
    });
  });

  group('invalid input is rejected, not encoded', () {
    test('an empty BIN', () {
      expect(failureOf(bankBin: ''), isA<InvalidBankBinFailure>());
    });

    test('a non-numeric BIN', () {
      expect(failureOf(bankBin: '97042X'), isA<InvalidBankBinFailure>());
    });

    test('a BIN of the wrong length', () {
      expect(failureOf(bankBin: '97042'), isA<InvalidBankBinFailure>());
      expect(failureOf(bankBin: '9704230'), isA<InvalidBankBinFailure>());
    });

    test('an empty account number', () {
      expect(
        failureOf(accountNumber: '  '),
        isA<InvalidBankAccountNumberFailure>(),
      );
    });

    test('a non-positive amount', () {
      expect(failureOf(amountDong: 0), isA<InvalidTransferAmountFailure>());
      expect(failureOf(amountDong: -1), isA<InvalidTransferAmountFailure>());
    });

    test('an amount past the field length limit', () {
      final failure = failureOf(amountDong: 99999999999999);
      expect(failure, isA<InvalidTransferAmountFailure>());
      expect(failure.message, contains('13'));
    });

    test('a description past the field length limit', () {
      expect(
        failureOf(description: 'x' * 26),
        isA<InvalidTransferDescriptionFailure>(),
      );
    });
  });
}
