import assert from 'node:assert/strict';
import test from 'node:test';

import {
  githubErrorAnnotation,
  safeSupabaseResponseBody,
  supabaseRequestError,
} from './live_v11_helpers.mjs';

test('keeps useful Supabase error details while redacting credentials', () => {
  const body = JSON.stringify({
    code: '23514',
    message: 'new row violates check constraint',
    access_token: 'eyJheader.payload.signature',
    refresh_token: 'refresh-secret',
    password: 'password-secret',
    authorization: 'Bearer authorization-secret',
    apikey: 'public-key-that-still-must-not-be-logged',
    service_role: 'privileged-secret',
    email: 'admin@example.com',
  });

  const safe = safeSupabaseResponseBody(body);

  assert.match(safe, /23514/);
  assert.match(safe, /new row violates check constraint/);
  assert.doesNotMatch(safe, /eyJheader|refresh-secret|password-secret/);
  assert.doesNotMatch(safe, /authorization-secret|public-key-that-still/);
  assert.doesNotMatch(safe, /privileged-secret|admin@example\.com/);
  assert.match(safe, /\[REDACTED\]/);
});

test('GitHub annotation escapes command-breaking characters', () => {
  const annotation = githubErrorAnnotation('failure 100%\nnext line');

  assert.equal(
    annotation,
    '::error title=Supabase request failed::failure 100%25%0Anext line',
  );
});

test('request errors omit query values and include the safe response body', () => {
  const error = supabaseRequestError({
    method: 'PATCH',
    path: '/rest/v1/answer_reports?answer_id=eq.private-id',
    status: 400,
    responseBody: '{"code":"PGRST102","message":"Invalid request body"}',
  });

  assert.match(error.message, /PATCH \/rest\/v1\/answer_reports returned 400/);
  assert.match(error.message, /PGRST102/);
  assert.doesNotMatch(error.message, /private-id/);
});
