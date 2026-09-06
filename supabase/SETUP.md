# Supabase setup for Meno Phase 2

No private credential or service-role key belongs in this repository or in the Flutter app.

## Create and configure

1. Create one Supabase project.
2. Open **SQL Editor**, paste the complete contents of `schema.sql`, and run it once.
3. Open **Authentication → Providers → Anonymous Sign-Ins** and enable anonymous sign-ins.
4. Open **Project Settings → API** and copy:
   - the **Project URL**;
   - the **Publishable key** (a legacy `anon` key also works).
5. For local development, pass those two public client values as Dart defines:

   ```bash
   flutter run \
     --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co \
     --dart-define=SUPABASE_ANON_KEY=YOUR_PUBLISHABLE_KEY
   ```

6. For live APKs built by GitHub Actions, add repository secrets named
   `SUPABASE_URL` and `SUPABASE_ANON_KEY`. The workflow passes them to the build;
   it does not print or commit them.

## Moderation

New questions always enter `pending`. In **Table Editor → questions**, change
`status` to `approved` or `rejected`. Only approved rows are visible publicly.
There is deliberately no client policy that can approve questions.

## How sessions work

Reading approved questions and answers uses the public `anon` role and requires
no session. On the first write, the app silently creates a Supabase anonymous
user. That user ID enforces one helpful vote per answer without adding a login UI.

## Never share with the app

- `service_role` key
- database password
- JWT signing secret
- access tokens copied from an authenticated dashboard session
