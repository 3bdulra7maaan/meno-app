# Meno v1 release checklist

Main is the intended authoritative branch for Flutter, admin, website and workflows.
This checklist is NOT a claim that Play has approved Meno.

## Android identity

- applicationId/namespace: `com.meno.app.meno` (preserves Flutter's `com.meno.app` + project name `meno`).
- Version: `1.0.0+2`; increment the code for every subsequent Play upload.
- compile/target API: 36; minimum API: 23; Java: 17.
- Only INTERNET is requested by the release manifest; inspect the merged manifest in CI for transitive permissions.
- Almarai is bundled and explicitly loaded by screenshot tests.
- Test APKs use explicitly opted-in debug signing. They are NOT Play releases.
- Unsigned AAB is a build-validation artifact, not uploadable to Play.

## Signing: minimum owner setup

Create and securely back up a Java upload keystore locally (never send it in chat or commit it).
Add repository Actions secrets `ANDROID_KEYSTORE_BASE64`, `ANDROID_KEYSTORE_PASSWORD`,
`ANDROID_KEY_ALIAS`, `ANDROID_KEY_PASSWORD`. Use base64 of the keystore for the first.
Then run **Signed Play bundle** from main. The runner deletes temporary signing material
and uploads only the AAB. Enroll in Play App Signing in Play Console and keep the upload key backup.

## Deployment

Set Settings → Pages → Source to **GitHub Actions**, not branch publishing.
Allow **main** in the existing `github-pages` environment deployment branch rules.
Do not remove the existing deployment until main's combined website/admin bundle is tested.
Pages receives ONLY `SUPABASE_URL` and `SUPABASE_ANON_KEY`. Admin credentials remain exclusive
to the manually dispatched **Admin real flow** workflow. No private key is required in browser code.

## Play declarations derived from source (review before submitting)

- Ads: no ad SDK or in-app advertising implemented.
- Access: public browsing needs no login; anonymous Supabase auth is automatic for contributions.
  Do NOT give Play reviewers an admin account. The web admin is not a mobile user feature.
- Data: user-generated questions/answers, helpful interactions, anonymous authentication IDs,
  random analytics session IDs, event names/timestamps/category/content IDs. Search text is NOT
  stored in the analytics table. Supabase/hosting may process IP/security logs.
- Purposes: app functionality, moderation/security and analytics. Public posts are visible to others.
- No contacts, precise location, camera, microphone, payment data or advertising ID collection is implemented.
- Encryption in transit: HTTPS. Deletion is currently a manual request, not an automatic retention job.
- Do not mark all data "not collected" simply because users are anonymous. Review User IDs,
  Other user-generated content and App interactions categories. Verify the processor/service-provider
  exception separately before answering the Data Safety "sharing" questions.
- Audience: owner must decide real intended age groups; do not invent a rating or child-directed status.
  Complete the IARC content-rating questionnaire honestly for public Q&A/UGC.

## Blocking Play policy gaps identified in current mobile implementation

- In-app report-content/report-user and block-user controls are not yet implemented.
- Terms/community rules acceptance before posting is not implemented.
- There is no in-app privacy-policy entry point or account/data deletion flow.
- GitHub Issues is public and requires a GitHub account; the owner should provide a private support/
  privacy contact and a usable deletion request route. Never request private identity details in public issues.
- Assess Google's account-deletion requirements for automatically created anonymous Auth identities;
  do not claim an exemption without confirmation. The app cannot currently delete server identities.

These are release gates, not cosmetic polish. Do not submit to Play until resolved and tested.

## Store assets

Arabic/English copy: `store-listing/ar.md`, `store-listing/en.md`.
Use the final `meno-final-screenshots` CI artifact. These are deterministic fixture screenshots,
not evidence of live production records. Review for accuracy before uploading.
Required: 512×512 PNG store icon, adaptive launcher icon, 1024×500 feature graphic,
at least two phone screenshots (320–3840 px, longest dimension no more than twice shortest).
Do not upload debug/empty/error screenshots as the main marketing set. No fabricated reviews,
download counts, awards, ranking or unsupported privacy claims.

## Verification checklist

- [ ] Format, analyze and all Flutter/widget tests pass on the exact merge SHA.
- [ ] APK and unsigned AAB built; verify final package/SDK/permissions/signature from artifacts.
- [ ] Scan current source, Git history and decompressed release artifacts for private credentials.
- [ ] Manual real-flow workflow passes on main; verify negative authorization checks too.
- [ ] Website, privacy and admin HTTPS routes checked after Pages deployment.
- [ ] Real Android keyboard/SafeArea, RTL, scrolling and accessibility checks on a device/emulator.
- [ ] Play pre-launch report, 16 KB native page-size compatibility and target API behavior verified.
- [ ] Complete developer verification/testing requirements shown for the actual Play account.

## Primary policy references (checked 2026-09-06)

- https://developer.android.com/google/play/requirements/target-sdk (API 36 from August 31, 2026)
- https://support.google.com/googleplay/android-developer/answer/9876937 (UGC reporting/blocking)
- https://support.google.com/googleplay/android-developer/answer/13327111 (account deletion)
- https://support.google.com/googleplay/android-developer/answer/10787469 (Data Safety)
- https://support.google.com/googleplay/android-developer/answer/9866151 (listing assets)
