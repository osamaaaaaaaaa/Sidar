# SIDAR AI — launch completion plan

## Definition of done

- A signed-in user can upload a photo, receive a structured AI result, and see only verified doctors/products from the database.
- User data, reports, and analysis images are private, deletable, and auditable.
- The user website and the admin dashboard work on desktop and mobile, in Arabic and English.
- Every critical journey is tested against the real Supabase project and deployed from a reproducible build.

## Phase 0 — launch blockers: security and reliability

- [x] Keep the Gemini API key server-side in the Supabase Edge Function.
- [x] Remove the legacy browser-side Gemini key from the unused compatibility config.
- [x] Make `scan-images` private and scope storage access to the owning user.
- [x] Use expiring signed URLs for report images instead of public URLs.
- [x] Validate authenticated ownership before image upload.
- [x] Add bounded image payloads, allowed MIME types, origin allow-list support, and per-user analysis quota.
- [x] Delete stored analysis images as part of account deletion.
- [x] Render AI findings and verified recommendations as safe text and accept only HTTP/HTTPS recommendation links.
- [x] Block the obsolete dashboard script that disabled RLS and add a launch baseline that re-enables RLS for all SIDAR data tables.
- [ ] Apply the six required Client SQL files plus the admin dashboard migration to the live Supabase project.
- [ ] Remediate the current live anonymous exposure of `scan_sessions`, `scan_images`, and `scan_findings`; `npm run audit:privacy` must pass before launch.
- [x] Add a standalone emergency lockdown migration that restores owner-only report access without depending on the full release migration chain.
- [x] Add an anonymous RLS audit command that fails if protected account/analysis records are publicly readable.
- [ ] Configure `GEMINI_API_KEY`, `GEMINI_MODEL`, and `ALLOWED_ORIGINS` as Supabase secrets, deploy the Edge Function, and perform a real authenticated analysis.
- [x] Add a repeatable authenticated release smoke test; its optional deep mode validates a real Gemini response with a consented test image.
- [ ] Rotate the Gemini key that was previously pasted into chat and confirm no key exists in client files or git history.
- [x] Scan both application trees for literal Gemini keys after removing legacy browser-side copies.

## Phase 1 — data and recommendation integrity

- [x] Resolve AI recommendations by doctor/product UUID from Supabase, never model-written names or prices.
- [ ] Seed and approve real doctors, products, prices, links, coordinates, and service coverage through the dashboard.
- [ ] Run import/export, duplicate handling, image storage, edit, delete, and immediate refresh tests in the dashboard.
- [ ] Verify location filtering and the no-results state with real catalog data.
- [x] In `E:\android projects\SidarDashboard`, remove production mock-data fallback; an unavailable source now renders empty data instead of sample records.
- [ ] Run the admin dashboard's own `npm run check` plus create/edit/delete/import tests against the real project under an admin account.

## Phase 2 — account and user journeys

- [x] Email/password, Google, and Apple sign-in UI; no magic-link-only path.
- [x] Account settings, password update, report access, and guarded account deletion UI.
- [ ] Enable and test Google/Apple providers and redirect URLs in Supabase Auth.
- [ ] Test signup confirmation, login errors, expired sessions, password reset, logout, and delete-account on production.
- [x] Add report deletion with its corresponding stored images and immediate state refresh.

## Phase 3 — product quality and accessibility

- [x] Mobile upload flow: gallery/camera, target choice, focus crop, loading states, and custom inputs.
- [ ] Run browser acceptance tests on current Android/iOS-sized viewports in Arabic and English.
- [x] Smoke-test the Client and admin Dashboard in Chromium with no runtime exceptions during startup.
- [ ] Check keyboard navigation, focus behavior, labels, contrast, reduced motion, and error announcements.
- [ ] Remove remaining duplicate legacy code while migrating the live screens into normal React components without changing the approved design.

## Phase 4 — observability and release

- [ ] Add production error tracking and Edge Function error alerts without logging image payloads or sensitive notes.
- [ ] Create a support/admin runbook: catalog moderation, quota changes, key rotation, account-deletion recovery, and incident response.
- [ ] Run the release checklist: database migrations, auth providers, storage policies, Edge secrets, real AI request, catalog test, mobile smoke test, `npm run check`, and deployed smoke test.
- [ ] Tag the release and keep a rollback build.

## Execution order

1. Complete and apply Phase 0 first; nothing medical/image-related is deployed before it passes.
2. Validate real catalog data and recommendations in Phase 1.
3. Complete end-to-end user and dashboard tests in Phases 2–3.
4. Deploy only after Phase 4's release checklist is signed off.
