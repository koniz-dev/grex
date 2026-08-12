# Local environment configuration

Put your machine's settings in **`assets/env/env`** (no extension, no dot).
That file is gitignored — your keys never become a tracked file.

```
SUPABASE_URL=https://<your-project-id>.supabase.co
SUPABASE_ANON_KEY=<anon-key>
```

`../../.env.example` at the repository root lists every setting the app
understands. Copy across the ones you need.

## Why this directory exists

`pubspec.yaml` declares `assets/env/` — the **directory**, not a file inside it.
A declared asset *file* that does not exist fails the build during bundling,
before any Dart runs, which is what made a fresh clone unbuildable (issue #5).
A declared *directory* only has to exist; files inside it are enumerated, so a
missing `env` is not an error. That is what lets the real file stay gitignored
(issue #24).

This README is committed so the directory always exists in a fresh clone. Do not
delete it, and do not put secrets in it — everything in this directory is
bundled into the app and served at a public URL on web builds.
