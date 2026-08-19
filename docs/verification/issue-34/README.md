# Issue #34 — VietQR: build the EMVCo transfer payload for a settlement row

Verification evidence. Commands run on macOS against branch
`issue-34-vietqr-payload`.

## Criteria

| # | Criterion | Result | Evidence |
|---|---|---|---|
| 1 | Pure function under `lib/features/payments/domain/`, no Supabase, no stored account details | PASS | `vietqr_payload.dart` |
| 2 | Tests cover CRC, TLV validity, amount round-trip, description present/absent | PASS | [payload-tests.log](payload-tests.log) — 24 tests |
| 3 | Static fields match the spec, **with the source cited** | PASS | see below |
| 4 | At least one payload checked against a published reference vector | PASS — three, and one reproduced byte for byte | see below |
| 5 | Invalid input rejected with a typed failure, per case | PASS | 7 tests |
| 6 | `dart format` clean, `flutter analyze` 0, `flutter test` green, no new `skip:` | PASS | [analyze.log](analyze.log); 1394 passed / 0 failed |
| 7 | Coverage gate passes | PASS | [coverage-gate.log](coverage-gate.log), exit 0 |

## Criterion 4 answers the question the issue was really asking

**Yes — a valid VietQR payload can be produced client-side, with no bank
partnership and no third-party API.** That was the finding gating [#20](https://github.com/koniz-dev/grex/issues/20).

The strongest evidence is not the structure tests but this: given the same
inputs as a published payload — TPBank BIN `970423`, account `mynamebvh`,
50,000 VND, description `test` — this implementation reproduces it **byte for
byte**, including the checksum:

```
00020101021238530010A000000727012300069704230109mynamebvh0208QRIBFTTA53037045405500005802VN62080804test6304AB76
```

Three vectors are pinned, from two independent sources:

| Vector | Source |
|---|---|
| transfer with amount + description | [viblo.asia — Tạo mã QRCode chuyển tiền ngân hàng](https://viblo.asia/p/tao-ma-qrcode-chuyen-tien-ngan-hang-7ymJXnd5Vkq) |
| no amount | [thanhtinhpas1/vietqr-parser](https://github.com/thanhtinhpas1/vietqr-parser) |
| merchant, with amount | [thanhtinhpas1/vietqr-parser](https://github.com/thanhtinhpas1/vietqr-parser) |

Each is **self-validating**: the test recomputes the CRC the vector carries, so
a vector transcribed wrongly fails rather than quietly becoming the standard
this implementation is measured against. All three recompute correctly under
CRC-16/CCITT-FALSE (polynomial `0x1021`, init `0xFFFF`, no reflection, no final
XOR) over everything up to and including `6304`.

### A discrepancy between the published sources

The two `vietqr-parser` vectors carry **`00` as the payload format indicator**
(tag `00`), which contradicts both the EMVCo spec — where it is `01` — and the
viblo vector. Their CRCs are still internally consistent, so the vectors are
"valid" in the checksum sense while disagreeing about the format.

This implementation emits `01`, matching the spec and the vector it reproduces
byte for byte. Flagged rather than averaged over: it is a reason to treat the
`vietqr-parser` examples as CRC/TLV fixtures only, which is all the tests use
them for.

## Criterion 3 — field sources

| Field | Value | Source |
|---|---|---|
| `00` payload format indicator | `01` | EMVCo MPM QR spec; matches the viblo vector |
| `01` point of initiation | `12` (dynamic) | `11` is static/reusable; a settlement is for a specific sum |
| `38.00` GUID | `A000000727` | NAPAS's registered AID |
| `38.01.00` / `38.01.01` | BIN / account | NAPAS beneficiary organisation block |
| `38.02` service code | `QRIBFTTA` | account-to-account transfer (`QRIBFTTC` is card-to-card) |
| `53` currency | `704` | ISO 4217 numeric, VND |
| `58` country | `VN` | ISO 3166-1 alpha-2 |
| `62.08` | description | additional data — purpose of transaction |
| `63` CRC | CRC-16/CCITT-FALSE | verified against all three vectors |

The structure was confirmed by parsing the reference vectors, not taken on
trust from prose.

## On the tests

The TLV parser and the CRC are **reimplemented in the test file**, deliberately.
A test that parsed with the same helper that built the string would agree with
itself even if both were wrong about the format.

The amount round-trip walks 1,000 → 100,000,000 VND and asserts tag `54` carries
the value verbatim — no rounding, no separators, no decimals — plus the
boundaries including the 13-digit field limit.

## On money units

VND has no minor unit in practice, so `amountDong` is an `int` that already *is*
the minor-unit representation. There is no cents conversion anywhere in this
file, which is why it looks different from `ExpenseCalculator`. #4's rule —
never do money arithmetic in floats — holds: no `double` appears in this code
path at all.

## Scope held

No PII is stored: the BIN and account number are parameters and reach no entity,
model or table. No UI, no deep link, no QR-rendering dependency, nothing
persisted. Those are #20's, and #20 stays blocked on where bank details live and
what their RLS story is.

## Coverage

Gate passes; Domain rises 56.6% → 58.0%. Baselines untouched.

## Not covered — criterion 8 `(human)`

**No real bank app has scanned this.** Only `macos` and `chrome` devices exist
here and `flutter drive` is unavailable, so nothing in this repo can prove a VN
banking app accepts the output and prefills the right account and amount.

Byte-for-byte agreement with a published payload is strong, but it is agreement
with a blog post's example, not with a bank. Someone should generate a code for
a real account and scan it before #20 builds anything on this.
