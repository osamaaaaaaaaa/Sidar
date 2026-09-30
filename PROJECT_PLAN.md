# SIDAR delivery plan

## 1. Runtime foundation — complete

- React 19 + Vite build is the application entrypoint.
- Existing interface is rendered through a React compatibility boundary so the current design remains unchanged.
- Production build is verified with `npm run build`.

## 2. Data, AI, and catalog integrity — complete in code

- Gemini is constrained to choose verified catalog IDs.
- Doctors and products are protected by Supabase RLS policies in `sql/provider_catalog_migration.sql`.
- The dashboard includes a manager-only catalog form.

## 3. Native React migration — in progress

- Replace the compatibility boundary by domain components in this order: auth/session, scan form, analysis result, dashboard, catalog management, static marketing pages.
- Move browser configuration from `public/js/config.js` to Vite environment variables before production deployment.

## 4. Release review — required before production

- Run both SQL migrations in Supabase and designate an admin account.
- Confirm Firebase AI Logic is enabled for the configured project.
- Perform a signed-in scan using an image, then verify one doctor/product record is selected from the database.
- Deploy only the `dist/` output.
