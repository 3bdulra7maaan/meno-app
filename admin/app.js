const config = window.MENO_CONFIG || {};
const demo = new URLSearchParams(location.search).has('demo');
let client = null;
const $ = (id) => document.getElementById(id);
const esc = (value = '') => String(value).replace(/[&<>'"]/g, (c) => ({'&':'&amp;','<':'&lt;','>':'&gt;',"'":'&#39;','"':'&quot;'}[c]));
const labels = {pending:'قيد المراجعة',approved:'معتمد',rejected:'مرفوض'};
const metricLabels = {
  total_users:'إجمالي المستخدمين',anonymous_users:'هويات مجهولة',total_questions:'إجمالي الأسئلة',pending_questions:'قيد المراجعة',approved_questions:'الأسئلة المعتمدة',rejected_questions:'الأسئلة المرفوضة',total_answers:'إجمالي الإجابات',total_helpful_votes:'علامات أفادني',questions_today:'أسئلة اليوم',answers_today:'إجابات اليوم',new_users_today:'مستخدمون جدد اليوم',daily_active_users:'نشطون اليوم',app_opens:'فتح التطبيق',question_views:'مشاهدات الأسئلة',searches:'عمليات البحث',question_submissions:'إرسال أسئلة',answer_submissions:'إرسال إجابات',helpful_vote_events:'تفاعلات أفادني'
};

function toast(message){$('toast').textContent=message;$('toast').classList.add('show');setTimeout(()=>$('toast').classList.remove('show'),2200)}
function showApp(){ $('login-view').hidden=true;$('app-view').hidden=false;loadDashboard() }
function showLogin(message=''){ $('app-view').hidden=true;$('login-view').hidden=false;$('login-error').textContent=message }
async function assertAdmin(){ const {data,error}=await client.rpc('is_meno_admin');if(error||data!==true)throw new Error('هذا الحساب غير مصرح له بالدخول.') }

$('login-form').addEventListener('submit',async(e)=>{
  e.preventDefault();$('login-error').textContent='';
  if(!client){showLogin('أنشئ admin/config.js باستخدام عنوان Supabase والمفتاح العام فقط.');return}
  const {error}=await client.auth.signInWithPassword({email:$('email').value,password:$('password').value});
  if(error){showLogin('تعذر تسجيل الدخول. تحقق من البيانات.');return}
  try{await assertAdmin();showApp()}catch(err){await client.auth.signOut();showLogin(err.message)}
});
$('logout').onclick=async()=>{await client?.auth.signOut();showLogin()};
$('refresh').onclick=()=>loadDashboard();
$('close-dialog').onclick=()=>$('question-dialog').close();
document.querySelectorAll('nav button').forEach((button)=>button.onclick=()=>navigate(button.dataset.view));

function navigate(view){
  document.querySelectorAll('nav button').forEach((b)=>b.classList.toggle('active',b.dataset.view===view));
  $('dashboard').hidden=view!=='dashboard';$('questions').hidden=view==='dashboard';
  if(view!=='dashboard')loadQuestions(view);
}
function rowsHtml(rows,type){return (rows||[]).map((r)=>`<div class="row"><strong>${esc(type==='q'?r.title:r.body)}</strong><br><small>${esc(r.category||r.answer_type||'')} · ${new Date(r.created_at).toLocaleString('ar')}</small></div>`).join('')||'<p class="meta">لا يوجد نشاط بعد.</p>'}
function barsHtml(rows,key){const max=Math.max(1,...(rows||[]).map((r)=>Number(r.count)));return (rows||[]).map((r)=>`<div class="bar"><span>${esc(r[key])}</span><div class="track"><div class="fill" style="width:${Math.max(4,Number(r.count)/max*100)}%"></div></div><b>${r.count}</b></div>`).join('')||'<p class="meta">لا توجد بيانات كافية.</p>'}

async function loadDashboard(){
  if(demo){renderDashboard(demoData.metrics,demoData.activity);return}
  const [{data:m,error:me},{data:a,error:ae}]=await Promise.all([client.rpc('admin_dashboard_metrics'),client.rpc('admin_recent_activity')]);
  if(me||ae){toast('تعذر تحميل بيانات اللوحة');return}renderDashboard(m,a)
}
function renderDashboard(m,a){
  $('metrics').innerHTML=Object.entries(metricLabels).map(([key,label])=>`<div class="metric"><span>${label}</span><b>${Number(m[key]||0).toLocaleString('ar')}</b></div>`).join('');
  $('categories').innerHTML=barsHtml(m.top_categories,'category');$('days').innerHTML=barsHtml(m.active_days,'day');
  $('recent-questions').innerHTML=rowsHtml(a.questions,'q');$('recent-answers').innerHTML=rowsHtml(a.answers,'a');
}
async function loadQuestions(status){
  $('questions-title').textContent=`الأسئلة — ${labels[status]}`;$('questions-list').innerHTML='<p class="meta">جارٍ التحميل…</p>';
  if(demo){renderQuestions(demoData.questions.filter((q)=>q.status===status));return}
  const {data,error}=await client.from('questions').select('id,title,body,category,author_name,is_anonymous,status,created_at,answers(id,body,author_name,is_hidden,created_at)').eq('status',status).order('created_at',{ascending:false});
  if(error){toast('تعذر تحميل الأسئلة');return}renderQuestions(data)
}
function renderQuestions(rows){
  $('questions-count').textContent=`${rows.length} سؤال`;
  $('questions-list').innerHTML=rows.map((q)=>`<article class="question"><span class="status">${esc(labels[q.status])}</span><h2>${esc(q.title)}</h2><p>${esc(q.body).slice(0,180)}</p><div class="meta">${esc(q.category)} · ${q.is_anonymous?'مجهول':esc(q.author_name||'مستخدم')} · ${new Date(q.created_at).toLocaleString('ar')}</div><div class="actions"><button data-open="${q.id}" class="quiet">عرض التفاصيل</button>${q.status!=='approved'?`<button data-status="approved" data-id="${q.id}">اعتماد</button>`:''}${q.status!=='rejected'?`<button data-status="rejected" data-id="${q.id}" class="danger">رفض</button>`:''}</div></article>`).join('')||'<article class="question"><h2>لا توجد أسئلة هنا</h2><p class="meta">ستظهر الأسئلة الجديدة تلقائياً.</p></article>';
  document.querySelectorAll('[data-open]').forEach((b)=>b.onclick=()=>openQuestion(rows.find((q)=>q.id===b.dataset.open)));
  document.querySelectorAll('[data-status]').forEach((b)=>b.onclick=()=>setQuestionStatus(b.dataset.id,b.dataset.status));
}
function openQuestion(q){
  const answers=(q.answers||[]).map((a)=>`<div class="answer"><b>إجابة</b><p>${esc(a.body)}</p><small class="meta">${esc(a.author_name||'مستخدم')} · ${a.is_hidden?'مخفية':'ظاهرة'}</small><div class="actions"><button class="quiet" data-answer="${a.id}" data-hidden="${!a.is_hidden}">${a.is_hidden?'إظهار الإجابة':'إخفاء الإجابة'}</button></div></div>`).join('')||'<p class="meta">لا توجد إجابات.</p>';
  $('question-detail').innerHTML=`<span class="status">${labels[q.status]}</span><h1>${esc(q.title)}</h1><p>${esc(q.body)}</p><div class="meta">${esc(q.category)} · ${q.is_anonymous?'مجهول':esc(q.author_name||'مستخدم')}</div><h2>الإجابات</h2>${answers}`;
  document.querySelectorAll('[data-answer]').forEach((b)=>b.onclick=()=>setAnswerHidden(b.dataset.answer,b.dataset.hidden==='true',q));$('question-dialog').showModal();
}
async function setQuestionStatus(id,status){if(demo){toast('وضع العرض التجريبي');return}const {error}=await client.from('questions').update({status}).eq('id',id);if(error){toast('فشل تحديث السؤال');return}toast(status==='approved'?'تم اعتماد السؤال':'تم رفض السؤال');navigate(status)}
async function setAnswerHidden(id,isHidden,q){if(demo){toast('وضع العرض التجريبي');return}const {error}=await client.from('answers').update({is_hidden:isHidden}).eq('id',id);if(error){toast('فشل تحديث الإجابة');return}toast(isHidden?'تم إخفاء الإجابة':'تم إظهار الإجابة');$('question-dialog').close();loadQuestions(q.status)}

const demoData={metrics:{total_users:124,anonymous_users:91,total_questions:68,pending_questions:7,approved_questions:56,rejected_questions:5,total_answers:143,total_helpful_votes:287,questions_today:9,answers_today:18,new_users_today:12,daily_active_users:47,app_opens:83,question_views:214,searches:39,question_submissions:9,answer_submissions:18,helpful_vote_events:31,top_categories:[{category:'السفر والتأشيرات',count:72},{category:'البنوك والتحويلات',count:51},{category:'السكن',count:33}],active_days:[{day:'اليوم',count:47},{day:'أمس',count:39},{day:'قبل يومين',count:31}]},activity:{questions:[{title:'أفضل طريقة لتحويل مبلغ إلى السودان؟',category:'البنوك والتحويلات',created_at:new Date()},{title:'إجراءات تأشيرة الزيارة العائلية',category:'السفر والتأشيرات',created_at:new Date()}],answers:[{body:'جربت الخدمة الأسبوع الماضي وكانت الخطوات بسيطة…',answer_type:'تجربة شخصية',created_at:new Date()}]},questions:[{id:'demo',title:'أفضل طريقة لتحويل مبلغ إلى السودان؟',body:'أبحث عن تجربة حديثة وآمنة في التحويل، وما الرسوم المتوقعة؟',category:'البنوك والتحويلات',author_name:'',is_anonymous:true,status:'pending',created_at:new Date(),answers:[]}]};

async function start() {
  if (demo) { showApp(); return; }
  if (!config.supabaseUrl || !config.supabaseAnonKey) { showLogin('إعداد Supabase العام غير موجود. راجع ملف README.'); return; }
  try {
    await new Promise((resolve, reject) => {
      const script = document.createElement('script');
      script.src = 'https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2';
      script.onload = resolve;
      script.onerror = reject;
      document.head.appendChild(script);
    });
    client = window.supabase.createClient(config.supabaseUrl, config.supabaseAnonKey);
  } catch (_) { showLogin('تعذر تحميل اتصال Supabase. تحقق من الشبكة.'); return; }
  const { data } = await client.auth.getSession();
  if (data.session) {
    try { await assertAdmin(); showApp(); }
    catch { await client.auth.signOut(); showLogin('هذا الحساب غير مصرح له بالدخول.'); }
  }
}
start();
