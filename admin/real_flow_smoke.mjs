const required = ['SUPABASE_URL', 'SUPABASE_ANON_KEY', 'SUPABASE_ADMIN_EMAIL', 'SUPABASE_ADMIN_PASSWORD'];
for (const name of required) {
  if (!process.env[name]) throw new Error(`Missing required environment variable: ${name}`);
}

const url = process.env.SUPABASE_URL.replace(/\/$/, '');
const key = process.env.SUPABASE_ANON_KEY;
const headers = (token, extra = {}) => ({ apikey: key, Authorization: `Bearer ${token}`, 'Content-Type': 'application/json', ...extra });
async function request(path, options = {}) {
  const response = await fetch(`${url}${path}`, options);
  const text = await response.text();
  const data = text ? JSON.parse(text) : null;
  if (!response.ok) throw new Error(`${options.method || 'GET'} ${path}: ${response.status} ${text}`);
  return data;
}

const adminAuth = await request('/auth/v1/token?grant_type=password', {
  method: 'POST', headers: headers(key), body: JSON.stringify({ email: process.env.SUPABASE_ADMIN_EMAIL, password: process.env.SUPABASE_ADMIN_PASSWORD }),
});
const adminToken = adminAuth.access_token;
const isAdmin = await request('/rest/v1/rpc/is_meno_admin', { method: 'POST', headers: headers(adminToken), body: '{}' });
if (isAdmin !== true) throw new Error('Configured user is not allowlisted in public.admin_users');

const anonAuth = await request('/auth/v1/signup', { method: 'POST', headers: headers(key), body: '{}' });
const anonToken = anonAuth.access_token;
const marker = `[SMOKE ${new Date().toISOString()}]`;
await request('/rest/v1/questions', {
  method: 'POST', headers: headers(anonToken, { Prefer: 'return=minimal' }),
  body: JSON.stringify({ title: `${marker} سؤال تحقق`, body: 'سؤال آلي للتحقق من دورة المراجعة الكاملة.', category: 'أخرى', is_anonymous: true, status: 'pending', user_id: anonAuth.user.id }),
});

const pending = await request(`/rest/v1/questions?title=eq.${encodeURIComponent(`${marker} سؤال تحقق`)}&status=eq.pending&select=*`, { headers: headers(adminToken) });
if (pending.length !== 1) throw new Error('Admin could not view the pending question');
const questionId = pending[0].id;
await request(`/rest/v1/questions?id=eq.${questionId}`, { method: 'PATCH', headers: headers(adminToken, { Prefer: 'return=minimal' }), body: JSON.stringify({ status: 'approved' }) });

const visible = await request(`/rest/v1/questions?id=eq.${questionId}&status=eq.approved&select=id`, { headers: headers(key) });
if (visible.length !== 1) throw new Error('Approved question is not publicly visible');

await request('/rest/v1/answers', {
  method: 'POST', headers: headers(anonToken, { Prefer: 'return=minimal' }),
  body: JSON.stringify({ question_id: questionId, body: 'إجابة آلية للتحقق.', user_id: anonAuth.user.id }),
});
const answers = await request(`/rest/v1/answers?question_id=eq.${questionId}&select=*`, { headers: headers(adminToken) });
if (answers.length !== 1) throw new Error('Admin could not view the submitted answer');
const answerId = answers[0].id;

const vote = await request('/rest/v1/rpc/toggle_helpful', { method: 'POST', headers: headers(anonToken), body: JSON.stringify({ answer_id_input: answerId }) });
if (!vote[0]?.is_helpful || vote[0]?.helpful_count < 1) throw new Error('Helpful vote did not persist');

await request(`/rest/v1/answers?id=eq.${answerId}`, { method: 'PATCH', headers: headers(adminToken, { Prefer: 'return=minimal' }), body: JSON.stringify({ is_hidden: true }) });
const hidden = await request(`/rest/v1/answers?id=eq.${answerId}&select=id`, { headers: headers(key) });
if (hidden.length !== 0) throw new Error('Hidden answer remained publicly visible');
await request(`/rest/v1/answers?id=eq.${answerId}`, { method: 'PATCH', headers: headers(adminToken, { Prefer: 'return=minimal' }), body: JSON.stringify({ is_hidden: false }) });
const restored = await request(`/rest/v1/answers?id=eq.${answerId}&select=id`, { headers: headers(key) });
if (restored.length !== 1) throw new Error('Restored answer is not publicly visible');

const metrics = await request('/rest/v1/rpc/admin_dashboard_metrics', { method: 'POST', headers: headers(adminToken), body: '{}' });
if (typeof metrics.total_questions !== 'number' || !Array.isArray(metrics.top_categories)) throw new Error('Dashboard metrics RPC returned an invalid payload');

await request(`/rest/v1/questions?id=eq.${questionId}`, { method: 'PATCH', headers: headers(adminToken, { Prefer: 'return=minimal' }), body: JSON.stringify({ status: 'rejected' }) });
await request(`/rest/v1/answers?id=eq.${answerId}`, { method: 'PATCH', headers: headers(adminToken, { Prefer: 'return=minimal' }), body: JSON.stringify({ is_hidden: true }) });
console.log(JSON.stringify({ ok: true, checks: ['admin_login', 'pending_read', 'approve', 'public_read', 'answer_submit', 'helpful_vote', 'answer_hide_restore', 'metrics', 'reject'] }));
