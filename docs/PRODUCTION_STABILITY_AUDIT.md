# Meno V1.2.1 production stability audit

Base: `feature/meno-v1-2-1-pixel-match` (PR #11). The approved visual system is
unchanged. This branch must be merged after PR #11, or first merged into its
feature branch. Do not deploy its APK before applying the migration below.

## Root causes and remediation

| Area | Problem and root cause | Fix | Verification |
| --- | --- | --- | --- |
| Bootstrap | Missing `SUPABASE_URL`/`SUPABASE_ANON_KEY` silently selected sample data. | Validate HTTPS/public configuration; only an explicit non-release `MENO_DEMO_MODE=true` selects in-memory data. A release startup failure displays a generic Arabic error. | `production_stability_test.dart` |
| Home | `approvedQuestions()` selected every approved question with all nested answers and vote rows. | `approved_question_page` returns at most 21 lightweight rows per request, including server-computed visible-answer counts. The UI fetches 20 at a time near the scroll threshold. | Pagination tests and read-only Supabase smoke after migration |
| Search | `searchApprovedQuestions()` downloaded the full feed and filtered on-device. | PostgreSQL normalizes Arabic and filters title/body/category server-side, with bounded cursor pages. | Search pagination tests and read-only Supabase smoke after migration |
| Detail | List rows carried full answers; detail did not fetch on open. | Load answers and the current identity's helpful-vote state for one approved question when opened. | Detail/widget tests |
| Session | Concurrent first writes could each initiate anonymous sign-in. | Share one in-flight sign-in future; reuse a restored active session. | Existing live flow and follow-up staging test recommended |

## Database deployment order

Apply `supabase/migrations/202609160001_approved_question_paging.sql` to the
correct Meno Supabase project **before** distributing an APK from this branch.
The migration adds two indexes and two functions. It neither rewrites an older
migration nor changes existing question, answer, vote, user, or banner records.
The `approved_question_page` RPC is `SECURITY INVOKER`, explicitly restricts
rows to `approved`, and executes under existing RLS. `page_size` is clamped to
1–50. The 21st row is only a continuation marker for the 20-item UI page.

The read-only CI Supabase smoke checks this RPC. If it reports `PGRST202`,
apply the migration and allow PostgREST's schema cache to refresh before
rerunning CI. Do not bypass this check or ship the new APK first.

## Security review

- `questions`: public reads are approved-only. Owners can read their own
  submissions; inserts require the same `auth.uid()` and `pending`. Only
  allowlisted admins have update permission under RLS.
- `answers`: public reads are approved-question, non-hidden only. Inserts
  require an authenticated anonymous identity on an approved question. Only
  admins can hide or restore.
- `helpful_votes`: client reads are restricted to their own vote; writes are
  handled by the authenticated `toggle_helpful` RPC, which rejects hidden
  answers and unapproved questions.
- Reports, blocked words, analytics reads, admin dashboard RPCs, banner rows,
  and banner Storage uploads remain protected by their existing RLS/admin
  checks. The new paging RPC does not use `SECURITY DEFINER`.
- Flutter/Admin use only public client keys. No service-role key is introduced.

This is a source-policy review, not proof of the currently deployed database
state. Existing live moderation tests should be run against a staging project
with the migration applied. Production-writing live-flow scripts were not run
as part of this audit because the request prohibits modifying production data.

## CI and remaining debt

The committed `android/` tree contains customized `src/` resources but lacks
the Gradle wrapper/build shell. `flutter create --platforms=android` is still
required in CI until those files are committed and verified. The workflow now
checks formatting rather than silently rewriting files, and uses current
GitHub Actions versions. Full architectural extraction of the large
`lib/main.dart` remains follow-up work; the bootstrap configuration and paged
repository contract were separated without a cosmetic screen rewrite.

Simple normalized `LIKE` search is appropriate for the current small dataset
but may eventually need a trigram index or full-text strategy if search volume
grows significantly. The keyset index already keeps ordinary feed pagination
bounded. There is no external search service.
