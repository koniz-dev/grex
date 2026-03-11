# Auth Deep Link and Supabase Setup

This guide ensures the auth system works end-to-end: email confirmation links open the app and trigger verification.

## Deep link URL

The app registers this URL for email confirmation:

- **Scheme:** `grex`
- **Host:** `app`
- **Path:** `/auth/confirm`
- **Full URL:** `grex://app/auth/confirm`

So when the user taps a link like `grex://app/auth/confirm?token=...&email=...&type=signup`, the app opens and [AppLinkListener](lib/features/auth/presentation/widgets/app_link_listener.dart) forwards the event to [AuthBloc](lib/features/auth/presentation/bloc/auth_bloc.dart) for verification.

## Platform configuration (already done in project)

- **Android:** [AndroidManifest.xml](android/app/src/main/AndroidManifest.xml) has an `intent-filter` for `grex` scheme, host `app`, path prefix `/auth/confirm`.
- **iOS:** [Info.plist](ios/Runner/Info.plist) has `CFBundleURLTypes` with URL scheme `grex`.

## Supabase Dashboard configuration

You must configure Supabase so that confirmation emails redirect to the app URL above.

### 1. Add redirect URL

1. Open [Supabase Dashboard](https://supabase.com/dashboard) → your project → **Authentication** → **URL Configuration**.
2. Under **Redirect URLs**, add exactly:
   ```
   grex://app/auth/confirm
   ```
3. Save.

### 2. Email template (Confirm signup)

1. Go to **Authentication** → **Email Templates** → **Confirm signup**.
2. The confirmation link in the email must eventually redirect to `grex://app/auth/confirm` with query (or hash) parameters that the app can read. The app expects:
   - `token` (verification token)
   - `email`
   - `type=signup`
3. Supabase’s default flow: user clicks link → Supabase `/auth/v1/verify` → redirect to your `emailRedirectTo`. The app’s [SupabaseAuthRepository](lib/features/auth/data/repositories/supabase_auth_repository.dart) passes `emailRedirectTo: AppConstants.authEmailConfirmRedirectUrl` on signUp, so the redirect target is `grex://app/auth/confirm`. Ensure the redirect preserves or appends `token`, `email`, and `type` so [SupabaseEmailVerificationService](lib/features/auth/data/services/supabase_email_verification_service.dart) can parse them (it reads `uri.queryParameters`).

If your template or Supabase version uses hash fragments instead of query params, the app may need to be updated to parse the hash; the service currently uses `Uri.parse(link).queryParameters`.

## Testing the deep link

1. **Manual test on device/emulator:** Install the app, then open a link (e.g. from Notes or browser):
   ```
   grex://app/auth/confirm?token=test123&email=test@example.com&type=signup
   ```
   The app should open. Verification may fail with a fake token, but the app should not crash and should handle the link.

2. **Full flow:** Register a new user with a real email, then tap the confirmation link in the email. The app should open and, after verification, redirect to the main app (e.g. groups).

## Summary

| Item | Value |
|------|--------|
| Deep link (app) | `grex://app/auth/confirm` |
| Redirect URL (Supabase allow list) | `grex://app/auth/confirm` |
| Code constant | [AppConstants.authEmailConfirmRedirectUrl](lib/core/constants/app_constants.dart) |
