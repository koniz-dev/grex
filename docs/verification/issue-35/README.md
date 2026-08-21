# Issue #35 — Tokens persisted to secure storage with no reader

Verification evidence. Branch `issue-35-token-copy`, on Flutter 3.47.0.

**Verdict: NEEDS-HUMAN.** Criteria 1–7 PASS. Criterion 8 is `(human)` and is
triggered, because the writes were removed.

## Criteria

| # | Criterion | Result |
|---|---|---|
| 1 | Decide and record: keep the writes or remove them; say what happens when the Dio layer is wired up | PASS — **removed** |
| 2 | If removed: `main.dart` and both session services stop writing the keys; sign-out deletes kept or removed deliberately | PASS — deletes **kept** |
| 3 | A test asserts the chosen behaviour against the storage double | PASS |
| 4 | Sign-out still clears any token the app did write | PASS |
| 5 | `network_scaffolding_test.dart` still passes; the Dio layer is not wired up | PASS — 4 passed |
| 6 | format clean, analyze 0, suite green, no new `skip:` | PASS — 1411 passed / 0 failed |
| 7 | Coverage gate | PASS — exit 0 |
| 8 | **(human)** confirm session restore across a cold start on a real device | NOT DONE |

## The decision: remove the writes

`AuthInterceptor` was the only reader of `AppConstants.tokenKey` /
`refreshTokenKey`, and it is unused scaffolding (#7 chose to keep the Dio layer
but nothing instantiates it). Three places wrote those keys — `main.dart` and
both session services — so the app kept a **second copy of live access and
refresh tokens that nothing read**.

What made removal clearly safe rather than a judgement call: the tokens are
**already inside the stored session record**. `SessionData.toJson()` serialises
`accessToken` and `refreshToken` into `grex_session_data`, which is a different
key and is what session restore actually reads. The standalone keys were pure
duplication.

**When the Dio layer is wired up**, `AuthInterceptor` should read the tokens from
the session service rather than re-adding a parallel copy. That is now the only
sensible route, and it is a smaller change than maintaining the duplicate.

## Criterion 2 — the deletes are kept, deliberately

`clearSession()` in both services still deletes both token keys. Installs
upgraded from a build that *did* write them must still have them cleared on
sign-out. A stale delete is harmless; a missing one leaves live credentials on
the device. Pinned by test.

## Tests

`secure_session_service_test.dart`:

- `storeSession does not write the standalone token keys` — `verifyNever` on both
- `storeSession still persists the session itself` — captures the
  `grex_session_data` write and asserts it contains both tokens, so removing the
  duplicate did not remove the record that matters
- `clearSession still deletes any token an older build wrote`

The middle test is the one that would catch an over-eager removal.

## Not covered — criterion 8

Session restore across a **cold start on a real device** is not verified. Only
`macos` and `chrome` devices exist here and `flutter drive` is unavailable.

The reasoning above says restore cannot depend on the removed keys — it reads
`grex_session_data` — and the suite agrees, but that is an argument plus unit
tests, not a phone. Worth one manual check before release: sign in, force-quit,
reopen, confirm you are still signed in.
