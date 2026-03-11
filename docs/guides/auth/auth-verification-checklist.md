# Auth System Verification Checklist

Use this checklist to confirm the auth system works end-to-end (not just on paper).

## Prerequisites

- Supabase project configured; Redirect URL `grex://app/auth/confirm` added in Dashboard → Auth → URL Configuration.
- App built and installed on a device or emulator (Android/iOS).

---

## 1. Session restore and token sync

- [ ] **1.1** Log in once (email + password), then fully close the app (kill process).
- [ ] **1.2** Open the app again (cold start).
- [ ] **1.3** You are still logged in and land on the main app (e.g. groups), not the login screen.
- [ ] **1.4** (Optional) In debug: after main(), read `authNotifierProvider` and confirm `user != null`; read secure storage key `AppConstants.tokenKey` and confirm a token is present.

**Pass:** App restores session and syncs token on startup.

---

## 2. Login and token for API

- [ ] **2.1** Log out if needed, then log in from the Login page.
- [ ] **2.2** After login, you are redirected to the main app (e.g. groups).
- [ ] **2.3** (Optional) If you have any screen or API that uses Dio with AuthInterceptor: trigger that request and verify (e.g. via logging or network inspector) that the request has header `Authorization: Bearer <token>`.

**Pass:** Login succeeds and token is stored and attached to API requests that use the shared ApiClient.

---

## 3. Redirect behaviour

- [ ] **3.1** When not logged in, opening the app redirects to the login screen.
- [ ] **3.2** After login, you are redirected to the main app (e.g. groups).
- [ ] **3.3** If the account is not email-verified, you are redirected to the email verification screen (and cannot stay on login/register).

**Pass:** GoRouter redirects match auth state (unauthenticated → login; authenticated unverified → email verification; authenticated verified → main app).

---

## 4. Deep link (email confirmation)

- [ ] **4.1** On a device/emulator with the app installed, open a link (e.g. from Notes or browser):
  ```
  grex://app/auth/confirm?token=test&email=test@example.com&type=signup
  ```
  The app opens (does not open in browser only). No crash.
- [ ] **4.2** Register a new user with a real email. Open the confirmation email on the same device and tap the confirmation link. The app opens and, after verification, you end up in the main app (or appropriate screen).

**Pass:** Deep link opens the app and email confirmation flow completes when using a real confirmation link.

---

## 5. Logout and clear state

- [ ] **5.1** From the app, log out.
- [ ] **5.2** You are redirected to the login screen.
- [ ] **5.3** Restart the app; you remain on the login screen (no restored session).

**Pass:** Logout clears session and token; cold start does not restore the previous user.

---

## Summary

| # | Area | Pass? |
|---|------|--------|
| 1 | Session restore + token sync | |
| 2 | Login + token for API | |
| 3 | Redirect behaviour | |
| 4 | Deep link (email confirmation) | |
| 5 | Logout and clear state | |

If all items pass, the auth system is working end-to-end in the real environment.
