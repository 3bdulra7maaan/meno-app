# Meno Admin v1

See `supabase/ADMIN_SETUP.md` for database and first-admin setup. For a UI-only preview without contacting Supabase, open `admin/?demo=1`. Demo mode does not perform mutations.

The production dashboard supports:

- email/password login plus server-enforced admin allowlist
- summary and lightweight product analytics
- pending, approved, and rejected question queues
- full question and answer inspection
- approve/reject moderation
- hide/restore answer moderation
- scheduled Home banners with direct image upload and internal/external targets

All production reads and writes use the logged-in user's Supabase JWT and RLS. No privileged key is used in the browser.

V1.2 banner uploads require
`supabase/migrations/202609080001_meno_v12_banner_storage.sql`. Images are
limited to JPEG, PNG, or WebP (5 MB) and are written to the public
`home-banners` bucket under the authenticated admin UUID. Storage writes and
banner mutations remain protected by the existing admin allowlist and RLS.
