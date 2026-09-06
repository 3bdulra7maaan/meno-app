import {randomUUID} from 'node:crypto';

const required = [
  'SUPABASE_URL',
  'SUPABASE_ANON_KEY',
  'SUPABASE_ADMIN_EMAIL',
  'SUPABASE_ADMIN_PASSWORD',
];
for (const name of required) {
  if (!process.env[name]) throw new Error(`Missing required secret: ${name}`);
}

const url = process.env.SUPABASE_URL.replace(/\/$/, '').replace(/\/rest\/v1$/, '');
const key = process.env.SUPABASE_ANON_KEY;
const headers = (token) => ({
  apikey: key,
  Authorization: `Bearer ${token}`,
  'Content-Type': 'application/json',
});
async function request(path, token = key, method = 'GET', body) {
  const response = await fetch(`${url}${path}`, {
    method,
    headers: headers(token),
    body: body === undefined ? undefined : JSON.stringify(body),
    signal: AbortSignal.timeout(20000),
  });
  const raw = await response.text();
  if (!response.ok) {
    throw new Error(`Live check failed: ${method} ${path.split('?')[0]} returned ${response.status}`);
  }
  return raw ? JSON.parse(raw) : null;
}
const normalize = (value) => value
  .toLowerCase()
  .replace(/[\u064B-\u065F\u0670\u06D6-\u06ED\u0640]/g, '')
  .replace(/[أإآٱ]/g, 'ا')
  .replace(/ى/g, 'ي')
  .replace(/ؤ/g, 'و')
  .replace(/ئ/g, 'ي')
  .replace(/ة/g, 'ه');
const searchable = (question, term) => normalize(
  `${question.title} ${question.body} ${question.category}`,
).includes(normalize(term));
const assert = (condition, name) => {
  if (!condition) throw new Error(`Live assertion failed: ${name}`);
  checks.push(name);
};

const checks = [];
let adminToken;
let anonToken;
let firstQuestionId;
let rejectedQuestionId;
let answerId;
let voteActive = false;
try {
  const admin = await request('/auth/v1/token?grant_type=password', key, 'POST', {
    email: process.env.SUPABASE_ADMIN_EMAIL,
    password: process.env.SUPABASE_ADMIN_PASSWORD,
  });
  adminToken = admin.access_token;
  assert(
    await request('/rest/v1/rpc/is_meno_admin', adminToken, 'POST', {}) === true,
    'admin_authenticated',
  );

  const anonymous = await request('/auth/v1/signup', key, 'POST', {});
  anonToken = anonymous.access_token;
  const userId = anonymous.user.id;
  firstQuestionId = randomUUID();
  const marker = `بحث مينو ${Date.now()}`;
  await request('/rest/v1/questions', anonToken, 'POST', {
    id: firstQuestionId,
    user_id: userId,
    title: `${marker} عن التحويل`,
    body: 'تفاصيل تجربة سودانية ثابتة بعد إعادة تشغيل التطبيق',
    category: 'البنوك والتحويلات',
    is_anonymous: true,
    status: 'pending',
  });
  const ownPath = `/rest/v1/questions?id=eq.${firstQuestionId}&user_id=eq.${userId}&select=id,status,title,body,category`;
  assert((await request(ownPath, anonToken))[0]?.status === 'pending', 'my_questions_pending');
  assert((await request(`/rest/v1/questions?id=eq.${firstQuestionId}&select=id`, key)).length === 0, 'pending_private');

  const resumed = await request('/auth/v1/token?grant_type=refresh_token', key, 'POST', {
    refresh_token: anonymous.refresh_token,
  });
  anonToken = resumed.access_token;
  assert(resumed.user.id === userId, 'anonymous_identity_restored');
  assert((await request(ownPath, anonToken)).length === 1, 'my_questions_after_restart');

  await request(`/rest/v1/questions?id=eq.${firstQuestionId}`, adminToken, 'PATCH', {
    status: 'approved',
  });
  assert((await request(ownPath, anonToken))[0]?.status === 'approved', 'my_questions_published_after_refresh');
  const publicQuestion = (await request(
    `/rest/v1/questions?id=eq.${firstQuestionId}&status=eq.approved&select=id,title,body,category`,
  ))[0];
  assert(publicQuestion?.id === firstQuestionId, 'approved_public');
  assert(searchable(publicQuestion, 'بحث مينو'), 'search_title_partial_arabic');
  assert(searchable(publicQuestion, 'تجربه سودانيه'), 'search_body_normalized_arabic');
  assert(searchable(publicQuestion, 'تحويلات'), 'search_category_partial_arabic');

  answerId = randomUUID();
  await request('/rest/v1/answers', anonToken, 'POST', {
    id: answerId,
    question_id: firstQuestionId,
    user_id: userId,
    body: 'إجابة تحقق محفوظة في Supabase.',
  });
  assert((await request(`/rest/v1/answers?id=eq.${answerId}&select=id`)).length === 1, 'answer_persisted');
  const vote = await request('/rest/v1/rpc/toggle_helpful', anonToken, 'POST', {
    answer_id_input: answerId,
  });
  voteActive = true;
  assert(vote[0]?.is_helpful === true && vote[0]?.helpful_count === 1, 'helpful_vote_persisted');

  rejectedQuestionId = randomUUID();
  await request('/rest/v1/questions', anonToken, 'POST', {
    id: rejectedQuestionId,
    user_id: userId,
    title: `${marker} سؤال مرفوض`,
    body: 'تفاصيل اختبار الرفض وعدم الظهور في البحث العام',
    category: 'أخرى',
    is_anonymous: true,
    status: 'pending',
  });
  await request(`/rest/v1/questions?id=eq.${rejectedQuestionId}`, adminToken, 'PATCH', {
    status: 'rejected',
  });
  const rejectedOwn = await request(
    `/rest/v1/questions?id=eq.${rejectedQuestionId}&user_id=eq.${userId}&select=id,status`,
    anonToken,
  );
  assert(rejectedOwn[0]?.status === 'rejected', 'my_questions_rejected');
  assert((await request(`/rest/v1/questions?id=eq.${rejectedQuestionId}&select=id`, key)).length === 0, 'rejected_not_public_or_searchable');

  const afterRestart = await request('/auth/v1/token?grant_type=refresh_token', key, 'POST', {
    refresh_token: resumed.refresh_token,
  });
  anonToken = afterRestart.access_token;
  assert((await request(ownPath, anonToken))[0]?.status === 'approved', 'question_persists_after_second_restart');
  assert((await request(`/rest/v1/answers?id=eq.${answerId}&select=id,helpful_count`))[0]?.helpful_count === 1, 'answer_and_vote_persist_after_restart');
} finally {
  // No delete policy is requested. Only records created above are retired.
  if (adminToken && firstQuestionId) {
    if (voteActive && anonToken && answerId) {
      await request('/rest/v1/rpc/toggle_helpful', anonToken, 'POST', {
        answer_id_input: answerId,
      });
    }
    if (answerId) {
      await request(`/rest/v1/answers?id=eq.${answerId}`, adminToken, 'PATCH', {
        is_hidden: true,
      });
    }
    await request(`/rest/v1/questions?id=eq.${firstQuestionId}`, adminToken, 'PATCH', {
      status: 'rejected',
    });
  }
}
console.log(JSON.stringify({
  ok: true,
  checks,
  cleanup: 'Created questions rejected, answer hidden, helpful vote removed.',
}));
