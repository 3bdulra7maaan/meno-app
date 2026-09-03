# Meno Admin v1

See `supabase/ADMIN_SETUP.md` for database and first-admin setup. For a UI-only preview without contacting Supabase, open `admin/?demo=1`. Demo mode does not perform mutations.

The production dashboard supports:

- email/password login plus server-enforced admin allowlist
- summary and lightweight product analytics
- pending, approved, and rejected question queues
- full question and answer inspection
- approve/reject moderation
- hide/restore answer moderation

All production reads and writes use the logged-in user's Supabase JWT and RLS. No privileged key is used in the browser.
