# Meno V1.2

V1.2 keeps the existing question, answer, moderation, search, reporting,
privacy, and analytics flows unchanged while adding the approved Meno brand,
launcher/splash assets, share flow, tappable Home banners, and responsive
banner administration.

## Supabase rollout

Apply `supabase/migrations/202609080001_meno_v12_banner_storage.sql` after the
existing V1.1 migrations. The migration is additive and contains no table
drops. It adds:

- `home_banners.target_type` with `none`, `internal`, and `external` values;
- preservation of existing HTTPS targets by classifying them as `external`;
- HTTPS validation for external targets;
- a public `home-banners` Storage bucket limited to JPEG, PNG, and WebP files
  up to 5 MB;
- authenticated-admin-only insert, update, and delete Storage policies, with
  every upload scoped under the current admin UUID.

The browser uses only the public Supabase URL, public publishable/anon key, and
the signed-in admin JWT. Never configure a `service_role` key in Admin or
Flutter.

## Admin banner flow

Open Admin, choose **البنرات**, then choose an image from the device. The form
shows a local preview and upload progress. Configure the title, short text,
enabled state, order, dates, and one target:

- **بدون إجراء**: the banner is informational;
- **صفحة داخل التطبيق**: opens the Flutter Banner Detail screen;
- **رابط خارجي**: accepts HTTPS only and opens outside Meno.

## Screenshots

The reviewed captures are in `docs/screenshots/v1_2/`. They are generated with
the bundled Almarai font and contain no production credentials.
