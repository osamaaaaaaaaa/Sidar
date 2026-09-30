# SIDAR AI — React production package

This package merges:
1. The previous working production logic (upload, Gemini/Firebase AI, Supabase auth/storage/db, history, saving, sharing)
2. The new premium website design direction
3. A production-ready SQL schema upgrade in `sql/production_schema.sql`

## Included
- `index.html` — merged premium UI + live analysis flow
- `css/styles.css` — premium dark/gold design + functional app styling
- `js/app.js` — previous working logic adapted to the merged layout
- `js/firebase-ai.js` — Gemini via Firebase AI Logic
- `js/supabase.js` — auth, storage, scans, plans, settings
- `js/config.js` — current config from the previous project
- `sql/production_schema.sql` — schema/migration to run in Supabase

## Setup

1. Install dependencies with `npm install`.
2. Run `sql/production_schema.sql`, `sql/provider_catalog_migration.sql`, `sql/account_management_migration.sql`, `sql/privacy_hardening_migration.sql`, `sql/analysis_rate_limit_migration.sql`, then `sql/launch_security_baseline.sql` in the Supabase SQL editor. The last three are mandatory for an already deployed project.
3. Confirm bucket name in `public/js/config.js` is `scan-images`. The default secure analysis path is the Supabase Edge Function below.
4. Start locally with `npm run dev`; create deployment assets with `npm run build`.
5. Deploy the generated `dist/` folder as a static site.

Before deployment, run `npm run check` to validate the legacy runtime JavaScript and generate a clean React production build.

## Image privacy (required before launch)

Analysis images are medical/sensitive content. The `scan-images` bucket must be private. New projects receive this policy from `production_schema.sql`; existing projects must run `privacy_hardening_migration.sql`. Images are stored under the signed-in user's folder and reports display them through one-hour signed URLs. Existing files that were uploaded while the bucket was public should be reviewed and rotated/deleted by the project owner before launch.

Deleting an account also removes the user's stored analysis images before the database account is deleted.

### Immediate live remediation

The current live audit found anonymous access to `scan_sessions`, `scan_images`, and `scan_findings`. Before any other work, run [emergency_analysis_lockdown.sql](./sql/emergency_analysis_lockdown.sql) in the Supabase SQL Editor, then run `npm run audit:privacy`. It must exit successfully before the application can be considered safe to launch. Continue with the full ordered migrations afterward; `launch_security_baseline.sql` restores the final admin-aware policy set.

## Firebase AI Logic / Gemini authorization

## Secure Gemini setup

The browser never receives the Gemini key. The app calls the `analyze-skin-scan` Supabase Edge Function, which reads `GEMINI_API_KEY` from Supabase Secrets. From `Client/`, deploy it with:

```bash
supabase secrets set GEMINI_API_KEY=YOUR_KEY GEMINI_MODEL=gemini-3.5-flash-lite ALLOWED_ORIGINS=https://YOUR-PRODUCTION-DOMAIN --project-ref rextzhjhiktmylhwiqyk
supabase functions deploy analyze-skin-scan --project-ref rextzhjhiktmylhwiqyk
```

Do not add `GEMINI_API_KEY` to `public/js/config.js`, `.env`, or any client-side file. `USE_FIREBASE_AI_LOGIC` is kept only as an optional legacy fallback.

The edge function verifies the Supabase JWT, accepts only approved image MIME types and bounded payloads, and consumes a server-side quota of eight analyses per signed-in user per hour. Add your local origin to `ALLOWED_ORIGINS` during development, separated by commas if needed.

## Release smoke test

After migrations and Edge Function deployment, create a non-admin test account and run this from PowerShell. It authenticates, verifies the live catalog, and validates the authenticated Edge Function without using Gemini quota:

```powershell
$env:SIDAR_SUPABASE_URL='https://YOUR_PROJECT.supabase.co'
$env:SIDAR_SUPABASE_ANON_KEY='YOUR_ANON_KEY'
$env:SIDAR_TEST_EMAIL='release-test@example.com'
$env:SIDAR_TEST_PASSWORD='YOUR_TEST_PASSWORD'
npm run smoke:release
```

To make one real Gemini request and verify the structured response, append `-- --image="E:\path\to\consented-test-image.jpg"`. This consumes one analysis slot and must use a consented, non-production test image.

After applying `launch_security_baseline.sql`, run `npm run audit:privacy` with the same `SIDAR_SUPABASE_URL` and `SIDAR_SUPABASE_ANON_KEY` variables. It must report that anonymous users cannot read profiles, scans, analysis-image rows, findings, or wellness plans.

The configured Firebase Web API key must be allowed to call `firebasevertexai.googleapis.com`. In Google Cloud Console for the Firebase project, enable **Firebase Vertex AI API** and either remove the API key's service restriction or explicitly allow `firebasevertexai.googleapis.com`. Keep appropriate HTTP-referrer restrictions for the deployed domain. The application reports this setup issue clearly instead of presenting a generic analysis failure.

`index.html` is now the Vite/React entrypoint. The existing visual application is intentionally preserved in `public/legacy.html` and loaded through React while the screens are migrated incrementally; this keeps the current production design and interaction model unchanged.

## Verified doctors and products

Run [provider_catalog_migration.sql](./sql/provider_catalog_migration.sql) in the Supabase SQL editor after the base schema. It creates protected `doctors`, `products`, and `admin_users` tables and inserts three real, non-prescription product records with official product links.

The migration is safe to rerun and upgrades earlier `doctors` or `products` tables by adding any missing catalog columns and removing incompatible legacy product-category checks.

To enable the dashboard catalog editor for one account, find that account's UUID in **Authentication → Users** and run the final commented `insert into public.admin_users` line in the migration with the UUID filled in. Only that account can add or edit catalog records; all other users can only read active, verified entries.

The AI analysis receives a small catalog of active products and verified doctors. Gemini returns only selected record IDs; the UI resolves those IDs back to Supabase rows before showing names, pricing, and booking/product links. This prevents made-up doctor or product records from appearing in results.

## Main routes
- `#scan`
- `#results`
- `#auth`
- `#account`
