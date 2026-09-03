# Meno admin setup

The dashboard uses the normal Supabase browser client plus Row Level Security. It never needs or accepts a `service_role` key.

## 1. Apply the migration

Apply `supabase/migrations/202609030001_admin_analytics.sql` in the Supabase SQL editor after the Phase 2 schema. This adds the admin allowlist, answer visibility flag, analytics events, policies, and admin-only reporting functions.

## 2. Create the first admin

1. In Supabase Authentication, ensure Email/password is enabled.
2. Create the admin user in Authentication > Users, or sign that user up normally.
3. Copy the user's UUID.
4. In the trusted Supabase SQL editor, run:

```sql
insert into public.admin_users (user_id)
values ('ADMIN_AUTH_USER_UUID');
```

Only a trusted operator can bootstrap the first entry. Existing admins can read the allowlist, but the v1 web UI deliberately does not manage other admins. Revoke access with:

```sql
delete from public.admin_users where user_id = 'ADMIN_AUTH_USER_UUID';
```

## 3. Configure the dashboard

Copy `admin/config.example.js` to `admin/config.js`. Set only the public Supabase project URL and the public anon/publishable key. `admin/config.js` is gitignored.

Serve the repository root locally:

```text
python -m http.server 8080
```

Open `http://localhost:8080/admin/` and sign in with the allowlisted email/password account.

For static hosting, generate the same `config.js` at deployment time from protected CI variables. A public anon/publishable key is expected in browser code; authorization is enforced by the authenticated session and RLS. Never place the service-role key in this directory or Flutter defines.

## Verification checklist

- A non-admin authenticated account is rejected by `is_meno_admin()`.
- An admin can list all question statuses and approve/reject a question.
- Public/anonymous clients can read only approved questions and non-hidden answers.
- An admin can hide an answer and it disappears from public reads.
- Clients can insert only the supported privacy-minimal event names; only admins can read analytics.
