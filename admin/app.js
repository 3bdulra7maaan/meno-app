const config = window.MENO_CONFIG || {};
const demo = new URLSearchParams(location.search).has('demo');
let client = null;
let answersCache = [];
let bannersCache = [];
const $ = (id) => document.getElementById(id);
const esc = (value = '') => String(value).replace(/[&<>'"]/g, (c) => ({'&':'&amp;','<':'&lt;','>':'&gt;',"'":'&#39;','"':'&quot;'}[c]));
const labels = {pending:'قيد المراجعة',approved:'معتمد',rejected:'مرفوض'};
const reasonLabels = {abuse:'إساءة أو تنمر',misleading:'معلومات مضللة',spam:'إعلان أو Spam',inappropriate:'محتوى غير مناسب',other:'أخرى'};
const wordCategoryLabels = {abuse:'إساءة',racism:'عنصرية',spam:'Spam',other:'أخرى'};
const bannerTypeLabels = {announcement:'إعلان عام',promotion:'ترويج',ad:'إعلان مدفوع'};
const bannerTargetLabels = {none:'بدون إجراء',internal:'تفاصيل داخل التطبيق',external:'رابط خارجي'};
const metricLabels = {
  total_users:'إجمالي المستخدمين',anonymous_users:'هويات مجهولة',total_questions:'إجمالي الأسئلة',pending_questions:'قيد المراجعة',approved_questions:'الأسئلة المعتمدة',rejected_questions:'الأسئلة المرفوضة',total_answers:'إجمالي الإجابات',total_helpful_votes:'علامات أفادني',questions_today:'أسئلة اليوم',answers_today:'إجابات اليوم',new_users_today:'مستخدمون جدد اليوم',daily_active_users:'نشطون اليوم',app_opens:'فتح التطبيق',question_views:'مشاهدات الأسئلة',searches:'عمليات البحث',question_submissions:'إرسال أسئلة',answer_submissions:'إرسال إجابات',helpful_vote_events:'تفاعلات أفادني'
};

function toast(message){$('toast').textContent=message;$('toast').classList.add('show');setTimeout(()=>$('toast').classList.remove('show'),2200)}
function showApp(){$('login-view').hidden=true;$('app-view').hidden=false;navigate('dashboard')}
function showLogin(message=''){$('app-view').hidden=true;$('login-view').hidden=false;$('login-error').textContent=message}
async function assertAdmin(){const {data,error}=await client.rpc('is_meno_admin');if(error||data!==true)throw new Error('هذا الحساب غير مصرح له بالدخول.')}

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
document.querySelectorAll('[data-reload]').forEach((button)=>button.onclick=()=>navigate(button.dataset.reload));

function navigate(view){
  document.querySelectorAll('nav button').forEach((b)=>b.classList.toggle('active',b.dataset.view===view));
  ['dashboard','questions','reports','answers','blocked','banners'].forEach((id)=>$(id).hidden=true);
  if(view==='dashboard'){$('dashboard').hidden=false;loadDashboard();return}
  if(['pending','approved','rejected'].includes(view)){$('questions').hidden=false;loadQuestions(view);return}
  $(view).hidden=false;
  if(view==='reports')loadReports();
  if(view==='answers')loadAnswers();
  if(view==='blocked')loadBlockedWords();
  if(view==='banners')loadBanners();
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
async function setAnswerHidden(id,isHidden,q=null){if(demo){toast('وضع العرض التجريبي');return}const {error}=await client.from('answers').update({is_hidden:isHidden}).eq('id',id);if(error){toast('فشل تحديث الإجابة');return}toast(isHidden?'تم إخفاء الإجابة':'تم إظهار الإجابة');if($('question-dialog').open)$('question-dialog').close();q?loadQuestions(q.status):loadAnswers()}

async function loadReports(){
  $('reports-list').innerHTML='<p class="meta">جارٍ التحميل…</p>';
  const {data,error}=await client.from('answer_reports').select('id,answer_id,reason,status,created_at,answers(id,body,is_hidden,questions(id,title))').order('created_at',{ascending:false});
  if(error){toast('تعذر تحميل البلاغات');return}
  const grouped=new Map();
  for(const report of data){const group=grouped.get(report.answer_id)||{answer:report.answers,reports:[]};group.reports.push(report);grouped.set(report.answer_id,group)}
  $('reports-list').innerHTML=[...grouped.entries()].map(([answerId,g])=>{const open=g.reports.filter((r)=>r.status==='open');const latest=g.reports[0];return `<article class="question"><span class="status">${open.length} بلاغ مفتوح</span><h2>${esc(g.answer?.questions?.title||'سؤال غير متاح')}</h2><p>${esc(g.answer?.body||'إجابة غير متاحة')}</p><div class="meta">${g.reports.map((r)=>esc(reasonLabels[r.reason])).join('، ')} · ${new Date(latest.created_at).toLocaleString('ar')} · ${g.answer?.is_hidden?'مخفية':'ظاهرة'}</div><div class="actions"><button data-report-dismiss="${answerId}" class="quiet">تجاهل البلاغ</button><button data-report-hide="${answerId}" data-hidden="${!g.answer?.is_hidden}">${g.answer?.is_hidden?'استعادة المحتوى':'إخفاء المحتوى'}</button></div></article>`}).join('')||'<p class="meta">لا توجد بلاغات.</p>';
  document.querySelectorAll('[data-report-dismiss]').forEach((b)=>b.onclick=()=>updateReports(b.dataset.reportDismiss,'dismissed'));
  document.querySelectorAll('[data-report-hide]').forEach((b)=>b.onclick=()=>moderateReportedAnswer(b.dataset.reportHide,b.dataset.hidden==='true'));
}
async function updateReports(answerId,status){const {error}=await client.from('answer_reports').update({status}).eq('answer_id',answerId).eq('status','open');if(error){toast('فشل تحديث البلاغ');return}toast('تم تحديث البلاغ');loadReports()}
async function moderateReportedAnswer(answerId,isHidden){const {error}=await client.from('answers').update({is_hidden:isHidden}).eq('id',answerId);if(error){toast('فشل تحديث الإجابة');return}await client.from('answer_reports').update({status:isHidden?'actioned':'dismissed'}).eq('answer_id',answerId).eq('status','open');toast(isHidden?'تم إخفاء المحتوى':'تمت استعادة المحتوى');loadReports()}

async function loadAnswers(){
  $('answers-list').innerHTML='<p class="meta">جارٍ التحميل…</p>';
  const {data,error}=await client.from('answers').select('id,body,author_name,is_hidden,created_at,questions(id,title)').order('created_at',{ascending:false});
  if(error){toast('تعذر تحميل الإجابات');return}answersCache=data;renderAnswers()
}
function renderAnswers(){
  const term=$('answers-search').value.trim().toLowerCase();const filter=$('answers-filter').value;
  const rows=answersCache.filter((a)=>(filter==='all'||(filter==='hidden')===a.is_hidden)&&(!term||a.body.toLowerCase().includes(term)||(a.questions?.title||'').toLowerCase().includes(term)));
  $('answers-count').textContent=`${rows.length} إجابة`;
  $('answers-list').innerHTML=rows.map((a)=>`<article class="question"><span class="status">${a.is_hidden?'مخفية':'ظاهرة'}</span><h2>${esc(a.questions?.title||'سؤال غير متاح')}</h2><p>${esc(a.body)}</p><div class="meta">${new Date(a.created_at).toLocaleString('ar')}</div><div class="actions"><button data-all-answer="${a.id}" data-hidden="${!a.is_hidden}">${a.is_hidden?'استعادة':'إخفاء'}</button></div></article>`).join('')||'<p class="meta">لا توجد إجابات مطابقة.</p>';
  document.querySelectorAll('[data-all-answer]').forEach((b)=>b.onclick=()=>setAnswerHidden(b.dataset.allAnswer,b.dataset.hidden==='true'));
}
$('answers-search').oninput=renderAnswers;$('answers-filter').onchange=renderAnswers;

async function loadBlockedWords(){
  $('blocked-list').innerHTML='<p class="meta">جارٍ التحميل…</p>';
  const {data,error}=await client.from('blocked_words').select('id,word,category,enabled,created_at,updated_at').order('created_at',{ascending:false});
  if(error){toast('تعذر تحميل الكلمات المحظورة');return}
  $('blocked-list').innerHTML=data.map((w)=>`<article class="question"><span class="status">${w.enabled?'مفعّلة':'معطّلة'}</span><h2>${esc(w.word)}</h2><div class="meta">${esc(wordCategoryLabels[w.category])} · أضيفت ${new Date(w.created_at).toLocaleString('ar')} · آخر تعديل ${new Date(w.updated_at).toLocaleString('ar')}</div><div class="actions"><button data-word-toggle="${w.id}" data-enabled="${!w.enabled}" class="quiet">${w.enabled?'تعطيل':'تفعيل'}</button><button data-word-delete="${w.id}" class="danger">حذف</button></div></article>`).join('')||'<p class="meta">لا توجد كلمات محظورة.</p>';
  document.querySelectorAll('[data-word-toggle]').forEach((b)=>b.onclick=()=>toggleWord(b.dataset.wordToggle,b.dataset.enabled==='true'));
  document.querySelectorAll('[data-word-delete]').forEach((b)=>b.onclick=()=>deleteWord(b.dataset.wordDelete));
}
$('blocked-form').onsubmit=async(e)=>{e.preventDefault();const {error}=await client.from('blocked_words').insert({word:$('blocked-word').value.trim(),category:$('blocked-category').value});if(error){toast(error.code==='23505'?'الكلمة موجودة مسبقاً':'تعذر إضافة الكلمة');return}$('blocked-form').reset();toast('تمت إضافة الكلمة');loadBlockedWords()};
async function toggleWord(id,enabled){const {error}=await client.from('blocked_words').update({enabled}).eq('id',id);if(error){toast('تعذر تحديث الكلمة');return}loadBlockedWords()}
async function deleteWord(id){if(!confirm('حذف هذه الكلمة من قائمة الحظر؟'))return;const {error}=await client.from('blocked_words').delete().eq('id',id);if(error){toast('تعذر حذف الكلمة');return}toast('تم الحذف');loadBlockedWords()}

async function loadBanners(){
  $('banners-list').innerHTML='<p class="meta">جارٍ التحميل…</p>';
  const {data,error}=await client.from('home_banners').select().order('display_order').order('created_at');
  if(error){toast('تعذر تحميل البنرات');return}bannersCache=data;renderBanners()
}
function renderBanners(){$('banners-list').innerHTML=bannersCache.map((b)=>`<article class="question banner-row"><img src="${esc(b.image_url)}" alt=""><div><span class="status">${b.enabled?'مفعّل':'معطّل'} · ${esc(bannerTypeLabels[b.type])}</span><h2>${esc(b.title)}</h2><p>${esc(b.short_text)}</p><div class="meta">${esc(bannerTargetLabels[b.target_type||'none'])} · ترتيب ${b.display_order} · ${b.start_at?new Date(b.start_at).toLocaleString('ar'):'بداية فورية'} — ${b.end_at?new Date(b.end_at).toLocaleString('ar'):'بلا نهاية'}</div><div class="actions"><button data-banner-edit="${b.id}" class="quiet">تعديل</button><button data-banner-toggle="${b.id}" data-enabled="${!b.enabled}">${b.enabled?'تعطيل':'تفعيل'}</button></div></div></article>`).join('')||'<p class="meta">لا توجد بنرات. الصفحة الرئيسية ستعمل بصورة طبيعية.</p>';document.querySelectorAll('[data-banner-edit]').forEach((x)=>x.onclick=()=>editBanner(x.dataset.bannerEdit));document.querySelectorAll('[data-banner-toggle]').forEach((x)=>x.onclick=()=>toggleBanner(x.dataset.bannerToggle,x.dataset.enabled==='true'))}
function resetBannerForm(){ $('banner-form').reset();$('banner-id').value='';$('banner-image').value='';$('banner-order').value='0';$('banner-target-type').value='none';$('banner-enabled').checked=true;$('banner-form').hidden=false;setTargetFields();setUploadProgress(null);previewBanner() }
function localDate(value){if(!value)return'';const d=new Date(value);return new Date(d.getTime()-d.getTimezoneOffset()*60000).toISOString().slice(0,16)}
function editBanner(id){const b=bannersCache.find((x)=>x.id===id);$('banner-id').value=b.id;$('banner-title').value=b.title;$('banner-text').value=b.short_text;$('banner-image').value=b.image_url;$('banner-image-file').value='';$('banner-target-type').value=b.target_type||(b.target_url?'external':'none');$('banner-target').value=b.target_url||'';$('banner-type').value=b.type;$('banner-order').value=b.display_order;$('banner-start').value=localDate(b.start_at);$('banner-end').value=localDate(b.end_at);$('banner-enabled').checked=b.enabled;$('banner-form').hidden=false;setTargetFields();setUploadProgress(null);previewBanner();$('banner-form').scrollIntoView({behavior:'smooth'})}
function previewBanner(source=$('banner-image').value){$('banner-preview').innerHTML=source?`<img src="${esc(source)}" alt="معاينة صورة البنر"><div><b>${esc($('banner-title').value||'معاينة البنر')}</b><p>${esc($('banner-text').value)}</p></div>`:''}
function setTargetFields(){const external=$('banner-target-type').value==='external';$('banner-target-wrap').hidden=!external;$('banner-target').required=external;if(!external)$('banner-target').value=''}
function setUploadProgress(value){const box=$('banner-upload-progress');if(value===null){box.hidden=true;box.querySelector('div').style.width='0%';return}box.hidden=false;box.querySelector('div').style.width=`${value}%`;box.querySelector('span').textContent=`جاري رفع الصورة… ${value}%`}
function validateBannerFile(file){if(!['image/png','image/jpeg','image/webp'].includes(file.type))throw new Error('اختر صورة PNG أو JPG أو WebP.');if(file.size>5*1024*1024)throw new Error('حجم الصورة يجب ألا يتجاوز 5 MB.')}
async function uploadBannerImage(file){validateBannerFile(file);const {data}=await client.auth.getSession();const session=data.session;if(!session)throw new Error('انتهت جلسة الدخول. سجّل الدخول مرة أخرى.');const extension={"image/png":'png',"image/jpeg":'jpg',"image/webp":'webp'}[file.type];const path=`${session.user.id}/${crypto.randomUUID()}.${extension}`;const endpoint=`${config.supabaseUrl.replace(/\/$/,'')}/storage/v1/object/home-banners/${path}`;await new Promise((resolve,reject)=>{const xhr=new XMLHttpRequest();xhr.open('POST',endpoint);xhr.setRequestHeader('Authorization',`Bearer ${session.access_token}`);xhr.setRequestHeader('apikey',config.supabaseAnonKey);xhr.setRequestHeader('Content-Type',file.type);xhr.setRequestHeader('x-upsert','false');xhr.upload.onprogress=(event)=>{if(event.lengthComputable)setUploadProgress(Math.round(event.loaded/event.total*100))};xhr.onload=()=>xhr.status>=200&&xhr.status<300?resolve():reject(new Error('تعذر رفع الصورة إلى التخزين.'));xhr.onerror=()=>reject(new Error('انقطع الاتصال أثناء رفع الصورة.'));xhr.send(file)});setUploadProgress(100);return client.storage.from('home-banners').getPublicUrl(path).data.publicUrl}
$('banner-image-file').onchange=()=>{const file=$('banner-image-file').files[0];if(!file){previewBanner();return}try{validateBannerFile(file);previewBanner(URL.createObjectURL(file))}catch(error){$('banner-image-file').value='';toast(error.message)}};
$('banner-target-type').onchange=setTargetFields;
$('new-banner').onclick=resetBannerForm;$('cancel-banner').onclick=()=>$('banner-form').hidden=true;['banner-title','banner-text'].forEach((id)=>$(id).oninput=()=>previewBanner());
$('banner-form').onsubmit=async(e)=>{e.preventDefault();if(demo){toast('وضع العرض التجريبي');return}const id=$('banner-id').value;const submit=$('banner-form').querySelector('button[type="submit"]');submit.disabled=true;try{const file=$('banner-image-file').files[0];const imageUrl=file?await uploadBannerImage(file):$('banner-image').value;if(!imageUrl)throw new Error('اختر صورة للبنر.');const targetType=$('banner-target-type').value;const targetUrl=targetType==='external'?$('banner-target').value.trim():null;if(targetType==='external'&&!targetUrl.startsWith('https://'))throw new Error('الرابط الخارجي يجب أن يبدأ بـ https://');const payload={title:$('banner-title').value.trim(),short_text:$('banner-text').value.trim(),image_url:imageUrl,target_type:targetType,target_url:targetUrl,type:$('banner-type').value,display_order:Number($('banner-order').value),start_at:$('banner-start').value?new Date($('banner-start').value).toISOString():null,end_at:$('banner-end').value?new Date($('banner-end').value).toISOString():null,enabled:$('banner-enabled').checked};const request=id?client.from('home_banners').update(payload).eq('id',id):client.from('home_banners').insert(payload);const {error}=await request;if(error)throw error;$('banner-form').hidden=true;toast('تم حفظ البنر');loadBanners()}catch(error){toast(error.message||'تعذر حفظ البنر')}finally{submit.disabled=false;setUploadProgress(null)}};
async function toggleBanner(id,enabled){const {error}=await client.from('home_banners').update({enabled}).eq('id',id);if(error){toast('تعذر تحديث البنر');return}loadBanners()}

const demoData={metrics:{total_users:124,anonymous_users:91,total_questions:68,pending_questions:7,approved_questions:56,rejected_questions:5,total_answers:143,total_helpful_votes:287,questions_today:9,answers_today:18,new_users_today:12,daily_active_users:47,app_opens:83,question_views:214,searches:39,question_submissions:9,answer_submissions:18,helpful_vote_events:31,top_categories:[{category:'السفر والتأشيرات',count:72}],active_days:[{day:'اليوم',count:47}]},activity:{questions:[],answers:[]},questions:[]};

async function start(){
  if(demo){showApp();return}
  if(!config.supabaseUrl||!config.supabaseAnonKey){showLogin('إعداد Supabase العام غير موجود. راجع ملف README.');return}
  try{await new Promise((resolve,reject)=>{const script=document.createElement('script');script.src='https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2';script.onload=resolve;script.onerror=reject;document.head.appendChild(script)});client=window.supabase.createClient(config.supabaseUrl,config.supabaseAnonKey)}catch(_){showLogin('تعذر تحميل اتصال Supabase. تحقق من الشبكة.');return}
  const {data}=await client.auth.getSession();if(data.session){try{await assertAdmin();showApp()}catch{await client.auth.signOut();showLogin('هذا الحساب غير مصرح له بالدخول.')}}
}
start();
