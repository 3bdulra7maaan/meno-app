# Meno v1.1 setup

Meno v1.1 adds server-enforced blocked words, answer reports, moderation history, and homepage banners. The migration is additive and does not drop or truncate application tables.

## Apply the migration

Run `supabase/migrations/202609060001_meno_v11.sql` once in the SQL editor of the existing Meno Supabase project. Review the selected project name before running it. No service-role key is required by the app or browser dashboard.

After applying it, use **الكلمات المحظورة** and **البنرات** in the existing Admin dashboard. Admin access continues to be controlled by Supabase Auth, `public.admin_users`, and RLS.

## Live verification

The manual **Meno v1.1 live flow** GitHub Actions workflow uses the existing repository secrets `SUPABASE_URL`, `SUPABASE_ANON_KEY`, `SUPABASE_ADMIN_EMAIL`, and `SUPABASE_ADMIN_PASSWORD`. Credentials are passed only as environment variables and are never printed or deployed.

The workflow verifies backend blocking, a normal question and answer, reporting and duplicate prevention, admin hide/restore, public answer visibility, and active/disabled/expired banners. Test content is retired afterward where RLS permits.
