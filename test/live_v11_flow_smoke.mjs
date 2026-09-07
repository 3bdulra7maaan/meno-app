import {randomUUID} from 'node:crypto';
import {
  githubErrorAnnotation,
  supabaseRequestError,
} from './live_v11_helpers.mjs';

const required = [
  'SUPABASE_URL',
  'SUPABASE_ANON_KEY',
  'SUPABASE_ADMIN_EMAIL',
  'SUPABASE_ADMIN_PASSWORD',
];
for (const name of required) {
  if (!process.env[name]) throw new Error(`Missing required secret: ${name}`);
}

const baseUrl = process.env.SUPABASE_URL
  .replace(/\/$/, '')
  .replace(/\/rest\/v1$/, '');
const publicKey = process.env.SUPABASE_ANON_KEY;
const headers = (token, prefer) => ({
  apikey: publicKey,
  Authorization: `Bearer ${token}`,
  'Content-Type': 'application/json',
  ...(prefer ? {Prefer: prefer} : {}),
});

async function request(path, token = publicKey, method = 'GET', body, prefer) {
  const response = await fetch(`${baseUrl}${path}`, {
    method,
    headers: headers(token, prefer),
    body: body === undefined ? undefined : JSON.stringify(body),
    signal: AbortSignal.timeout(20000),
  });
  const raw = await response.text();
  if (!response.ok) {
    const error = supabaseRequestError({
      method,
      path,
      status: response.status,
      responseBody: raw,
    });
    if (process.env.GITHUB_ACTIONS === 'true') {
      console.error(githubErrorAnnotation(error.message));
    }
    throw error;
  }
  return raw ? JSON.parse(raw) : null;
}

async function expectRejected(path, token, body) {
  const response = await fetch(`${baseUrl}${path}`, {
    method: 'POST',
    headers: headers(token),
    body: JSON.stringify(body),
    signal: AbortSignal.timeout(20000),
  });
  if (response.ok) throw new Error('Blocked content unexpectedly succeeded');
  return response.status;
}

const checks = [];
const assert = (condition, name) => {
  if (!condition) throw new Error(`Live assertion failed: ${name}`);
  checks.push(name);
};

let adminToken;
let anonToken;
let questionId;
let answerId;
let wordId;
const bannerIds = [];
try {
  const admin = await request('/auth/v1/token?grant_type=password', publicKey, 'POST', {
    email: process.env.SUPABASE_ADMIN_EMAIL,
    password: process.env.SUPABASE_ADMIN_PASSWORD,
  });
  adminToken = admin.access_token;
  assert(
    await request('/rest/v1/rpc/is_meno_admin', adminToken, 'POST', {}) === true,
    'admin_authenticated',
  );

  const anonymous = await request('/auth/v1/signup', publicKey, 'POST', {});
  anonToken = anonymous.access_token;
  const userId = anonymous.user.id;
  const suffix = String(Date.now());
  const blockedWord = `إساءة${suffix}`;
  const insertedWord = await request(
    '/rest/v1/blocked_words?select=id',
    adminToken,
    'POST',
    {word: blockedWord, category: 'abuse'},
    'return=representation',
  );
  wordId = insertedWord[0].id;

  const blockedQuestionStatus = await expectRejected(
    '/rest/v1/questions',
    anonToken,
    {
      id: randomUUID(),
      user_id: userId,
      title: `اِســاءة${suffix}`,
      body: 'نص اختبار',
      category: 'أخرى',
      is_anonymous: true,
      status: 'pending',
    },
  );
  assert(blockedQuestionStatus === 400, 'blocked_question_rejected_by_database');

  questionId = randomUUID();
  await request('/rest/v1/questions', anonToken, 'POST', {
    id: questionId,
    user_id: userId,
    title: `سؤال تحقق Meno v1.1 ${suffix}`,
    body: 'سؤال طبيعي لاختبار دورة الإشراف.',
    category: 'الخدمات',
    is_anonymous: true,
    status: 'pending',
  });
  assert(true, 'normal_question_submitted');
  await request(`/rest/v1/questions?id=eq.${questionId}`, adminToken, 'PATCH', {
    status: 'approved',
  });

  const blockedAnswerStatus = await expectRejected('/rest/v1/answers', anonToken, {
    id: randomUUID(),
    question_id: questionId,
    user_id: userId,
    body: `اِســاءة${suffix}`,
  });
  assert(blockedAnswerStatus === 400, 'blocked_answer_rejected_by_database');

  answerId = randomUUID();
  await request('/rest/v1/answers', anonToken, 'POST', {
    id: answerId,
    question_id: questionId,
    user_id: userId,
    body: 'إجابة طبيعية محفوظة لاختبار Meno v1.1.',
  });
  assert(true, 'normal_answer_submitted');

  assert(
    await request('/rest/v1/rpc/report_answer', anonToken, 'POST', {
      answer_id_input: answerId,
      reason_input: 'misleading',
    }) === true,
    'answer_report_saved',
  );
  assert(
    await request('/rest/v1/rpc/report_answer', anonToken, 'POST', {
      answer_id_input: answerId,
      reason_input: 'spam',
    }) === false,
    'duplicate_report_prevented',
  );
  const reports = await request(
    `/rest/v1/answer_reports?answer_id=eq.${answerId}&select=id,status`,
    adminToken,
  );
  assert(reports.length === 1, 'admin_sees_report');

  await request(`/rest/v1/answers?id=eq.${answerId}`, adminToken, 'PATCH', {
    is_hidden: true,
  });
  assert(
    (await request(`/rest/v1/answers?id=eq.${answerId}&select=id`)).length === 0,
    'hidden_answer_not_public',
  );
  await request(`/rest/v1/answers?id=eq.${answerId}`, adminToken, 'PATCH', {
    is_hidden: false,
  });
  assert(
    (await request(`/rest/v1/answers?id=eq.${answerId}&select=id`)).length === 1,
    'restored_answer_public',
  );

  const activeBanner = randomUUID();
  const disabledBanner = randomUUID();
  const expiredBanner = randomUUID();
  bannerIds.push(activeBanner, disabledBanner, expiredBanner);
  const commonBanner = {
    image_url: 'https://example.com/meno-v11.png',
    short_text: 'اختبار مؤقت',
    target_url: null,
    type: 'announcement',
    display_order: 0,
    start_at: null,
    end_at: null,
  };
  await request('/rest/v1/home_banners', adminToken, 'POST', [
    {...commonBanner, id: activeBanner, title: `بنر نشط ${suffix}`, enabled: true},
    {...commonBanner, id: disabledBanner, title: `بنر معطل ${suffix}`, enabled: false},
    {
      ...commonBanner,
      id: expiredBanner,
      title: `بنر منتهي ${suffix}`,
      enabled: true,
      end_at: new Date(Date.now() - 60000).toISOString(),
    },
  ]);
  const publicBanners = await request(
    `/rest/v1/home_banners?id=in.(${bannerIds.join(',')})&select=id`,
  );
  assert(
    publicBanners.length === 1 && publicBanners[0].id === activeBanner,
    'only_active_banner_public',
  );
} finally {
  if (adminToken) {
    if (answerId) {
      await request(`/rest/v1/answer_reports?answer_id=eq.${answerId}`, adminToken, 'PATCH', {
        status: 'dismissed',
      });
      await request(`/rest/v1/answers?id=eq.${answerId}`, adminToken, 'PATCH', {
        is_hidden: true,
      });
    }
    if (questionId) {
      await request(`/rest/v1/questions?id=eq.${questionId}`, adminToken, 'PATCH', {
        status: 'rejected',
      });
    }
    if (bannerIds.length) {
      await request(
        `/rest/v1/home_banners?id=in.(${bannerIds.join(',')})`,
        adminToken,
        'DELETE',
      );
    }
    if (wordId) {
      await request(`/rest/v1/blocked_words?id=eq.${wordId}`, adminToken, 'DELETE');
    }
  }
}

console.log(JSON.stringify({
  ok: true,
  checks,
  cleanup: 'Question rejected, answer hidden, report dismissed, temporary word and banners removed.',
}));
