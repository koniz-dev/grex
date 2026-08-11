# Local Setup Checklist

A focused checklist for getting the app to boot and log in on a fresh
machine. Once everything below is done you can delete this file.

For deeper background see `docs/guides/onboarding/getting-started.md` and
`docs/oauth-setup/`.

---

## ✅ Already in repo

- `android/app/google-services.json` — Firebase Android config
- `lib/main.dart` — Firebase init wrapped in try/catch (degrades if missing);
  Supabase init errors show `_ConfigErrorApp` instead of crashing
- macOS deep-link schemes (`grex`, `io.supabase.grex`) + Apple Sign In
  entitlement + `network.client` entitlement

---

## ❗ You still need to provide

### 1. Your environment settings (the repo builds without this)

A fresh clone builds as-is. To actually log in, create **`assets/env/env`** —
no dot, no extension:

```bash
cat > assets/env/env <<'EOF'
SUPABASE_URL=https://<your-project-id>.supabase.co
SUPABASE_ANON_KEY=<anon-key>
EOF
```

Get both from **Supabase dashboard → Project Settings → API**. `.env.example`
at the repository root lists every setting the app understands; copy across
whatever else you need.

That file is **gitignored**, so your keys can never be committed. Nothing else
to do — no `skip-worktree`, no template copying.

Why this path: `pubspec.yaml` declares the *directory* `assets/env/`, not a file
inside it. A declared asset file that does not exist fails the build before any
Dart runs; a declared directory only has to exist, and it does, because
`assets/env/README.md` is committed. That is what lets your real file stay
ignored.

> ⚠️ Leave `SUPABASE_SERVICE_ROLE_KEY` **empty**. Everything in `assets/env/` is
> shipped inside the app bundle (and served publicly on web), and the
> service-role key bypasses every RLS policy. Note that
> `scripts/windows/database/utils/rotate-api-keys.ps1` writes the rotated
> service-role key into `.env` — clear it afterwards. See
> [F4 in the code audit](docs/audit/2026-08-04-code-audit.md#f4--env-is-bundled-into-the-app-while-documenting-a-service-role-key-high).

> `--dart-define` also works, and is what CI and the deploy workflows should
> prefer over writing secrets to a file. The env file wins over a define of the
> same key, and a define wins over the built-in default. Only the keys listed in
> `.env.example` can be supplied this way.
>
> ```bash
> flutter run --dart-define=SUPABASE_URL=https://your-project.supabase.co \
>             --dart-define=SUPABASE_ANON_KEY=<anon-key>
> ```

After editing run:

```bash
flutter clean && flutter pub get && flutter run
```

(the env file is bundled as an asset, so `flutter clean` is needed.)

### 2. `ios/Runner/GoogleService-Info.plist` (optional)

Only needed if you want Firebase to actually work on iOS (feature flags,
performance monitoring). Without it Firebase silently degrades to no-ops
on iOS — app still runs.

Download from Firebase console → iOS app → "Download GoogleService-Info.plist".

### 3. Apple Sign In — iOS capability

In Xcode → open `ios/Runner.xcworkspace` → target **Runner** → tab
**Signing & Capabilities** → **+ Capability → Sign in with Apple**.

Requires an Apple Developer account. Also enable the same capability in
Apple Developer Portal for your App ID. (macOS entitlement is already wired
in this repo — only the Apple-side App ID enable is missing.)

### 4. Google Sign In — Supabase provider config

No code change needed. Configure in:
- **Google Cloud Console** → APIs & Services → Credentials → create OAuth
  2.0 Client ID (one for Android, one for iOS, one for Web).
- **Supabase dashboard** → Authentication → Providers → Google → enable,
  paste the Web client ID + secret.

The app uses Supabase's web OAuth flow (`signInWithOAuth`) — no native
`google_sign_in` package, so no extra Flutter setup beyond the Supabase
config.

### 5. Apple Sign In — Supabase provider config

- **Apple Developer Portal** → create a **Services ID** + sign key.
- **Supabase dashboard** → Authentication → Providers → Apple → paste
  Services ID + key.

---

## 🔎 Verifying the setup

After editing `assets/env/env`:

```bash
flutter clean
flutter pub get
flutter run
```

- If you see "Configuration error" screen → `assets/env/env` is missing or
  wrong; check `SUPABASE_URL` / `SUPABASE_ANON_KEY`.
- If you see the login screen → boot is fine. Try email login first (least
  external config). Then social providers (require steps 4 / 5 above).
