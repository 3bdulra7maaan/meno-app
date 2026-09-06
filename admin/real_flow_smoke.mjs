import {randomUUID} from 'node:crypto';
import {publicConfig} from '../scripts/public-config.mjs';
const {supabaseUrl:url,supabaseAnonKey:key}=publicConfig();
for(const name of ['SUPABASE_ADMIN_EMAIL','SUPABASE_ADMIN_PASSWORD']) {
  if(!process.env[name]) throw new Error('Missing verification credential: '+name);
}
const headers=(token)=>({apikey:key,Authorization:'Bearer '+token,'Content-Type':'application/json'});
async function request(path,token=key,method='GET',body,allowFailure=false) {
  const response=await fetch(url+path,{method,headers:headers(token),body:body===undefined?undefined:JSON.stringify(body),signal:AbortSignal.timeout(20000)});
  const raw=await response.text();
  if(!response.ok) {
    if(allowFailure) return {denied:true,status:response.status};
    // Never print response bodies, JWTs, login identifiers or private data.
    throw new Error('Verification request failed: HTTP '+response.status+' '+method+' '+path.split('?')[0]);
  }
  return raw?JSON.parse(raw):null;
}
const checks=[];
const check=(ok,name)=>{if(!ok)throw new Error('Failed check: '+name);checks.push(name)};
let adminToken,anonToken,questionId,answerId,voted=false;
try {
  await request('/rest/v1/questions?status=eq.approved&select=id&limit=1');
  checks.push('public_browse');
  const auth=await request('/auth/v1/token?grant_type=password',key,'POST',{email:process.env.SUPABASE_ADMIN_EMAIL,password:process.env.SUPABASE_ADMIN_PASSWORD});
  adminToken=auth.access_token;
  check(await request('/rest/v1/rpc/is_meno_admin',adminToken,'POST',{})===true,'admin_login');
  const anon=await request('/auth/v1/signup',key,'POST',{});
  anonToken=anon.access_token;
  check(await request('/rest/v1/rpc/is_meno_admin',anonToken,'POST',{})===false,'non_admin_not_allowlisted');
  check((await request('/rest/v1/rpc/admin_dashboard_metrics',anonToken,'POST',{},true))?.denied,'metrics_denied_to_non_admin');
  const session='smoke-'+randomUUID();
  async function event(event_name,entity_id) {
    await request('/rest/v1/analytics_events',anonToken,'POST',{event_name,session_id:session,user_id:anon.user.id,category:'أخرى',...(entity_id?{entity_id}:{})});
  }
  await event('app_open');
  questionId=randomUUID();
  await request('/rest/v1/questions',anonToken,'POST',{id:questionId,user_id:anon.user.id,title:'[SMOKE] سؤال تحقق آلي '+Date.now(),body:'سجل اختبار تقني مؤقت لدورة المراجعة.',category:'أخرى',is_anonymous:true,status:'pending'});
  await event('question_submitted',questionId);
  const query='/rest/v1/questions?id=eq.'+questionId;
  check((await request(query+'&select=id',key)).length===0,'pending_not_public');
  check((await request(query+'&status=eq.pending&select=id',adminToken)).length===1,'pending_read');
  await request(query,anonToken,'PATCH',{status:'approved'},true);
  check((await request(query+'&select=status',adminToken))[0].status==='pending','non_admin_cannot_approve');
  await request(query,adminToken,'PATCH',{status:'approved'});
  check((await request(query+'&select=id',key)).length===1,'approve_public_visibility');
  await event('question_view',questionId);
  await event('search');
  await event('category_selected');
  answerId=randomUUID();
  await request('/rest/v1/answers',anonToken,'POST',{id:answerId,question_id:questionId,user_id:anon.user.id,body:'إجابة اختبار تقني.'});
  await event('answer_submitted',questionId);
  check((await request('/rest/v1/answers?id=eq.'+answerId+'&select=id',key)).length===1,'answer_persisted');
  const vote=await request('/rest/v1/rpc/toggle_helpful',anonToken,'POST',{answer_id_input:answerId});
  voted=true;
  check(vote[0]?.is_helpful===true&&vote[0]?.helpful_count===1,'helpful_vote');
  await event('helpful_vote',questionId);
  await request('/rest/v1/answers?id=eq.'+answerId,anonToken,'PATCH',{is_hidden:true},true);
  check((await request('/rest/v1/answers?id=eq.'+answerId+'&select=is_hidden',adminToken))[0].is_hidden===false,'non_admin_cannot_hide');
  await request('/rest/v1/answers?id=eq.'+answerId,adminToken,'PATCH',{is_hidden:true});
  check((await request('/rest/v1/answers?id=eq.'+answerId+'&select=id',key)).length===0,'hide');
  check((await request('/rest/v1/rpc/toggle_helpful',anonToken,'POST',{answer_id_input:answerId},true))?.denied,'hidden_vote_denied');
  await request('/rest/v1/answers?id=eq.'+answerId,adminToken,'PATCH',{is_hidden:false});
  check((await request('/rest/v1/answers?id=eq.'+answerId+'&select=id',key)).length===1,'restore');
  const events=await request('/rest/v1/analytics_events?session_id=eq.'+session+'&select=event_name',adminToken);
  check(new Set(events.map(e=>e.event_name)).size===7,'analytics_events_persisted');
  const privateEvents=await request('/rest/v1/analytics_events?session_id=eq.'+session+'&select=event_name',anonToken);
  check(privateEvents.length===0,'analytics_not_public');
  const metrics=await request('/rest/v1/rpc/admin_dashboard_metrics',adminToken,'POST',{});
  check(metrics.total_questions>0&&metrics.app_opens>0&&Array.isArray(metrics.top_categories),'metrics');
  const recent=await request('/rest/v1/rpc/admin_recent_activity',adminToken,'POST',{});
  check(Array.isArray(recent.questions)&&Array.isArray(recent.answers)&&Array.isArray(recent.events),'recent_activity');
} finally {
  // Only IDs created by THIS run are touched. No production records are deleted.
  if(adminToken&&questionId) {
    if(answerId&&voted) {
      await request('/rest/v1/answers?id=eq.'+answerId,adminToken,'PATCH',{is_hidden:false});
      await request('/rest/v1/rpc/toggle_helpful',anonToken,'POST',{answer_id_input:answerId});
    }
    if(answerId) await request('/rest/v1/answers?id=eq.'+answerId,adminToken,'PATCH',{is_hidden:true});
    await request('/rest/v1/questions?id=eq.'+questionId,adminToken,'PATCH',{status:'rejected'});
    check((await request('/rest/v1/questions?id=eq.'+questionId+'&select=id',key)).length===0,'reject_cleanup_not_public');
  }
}
console.log(JSON.stringify({ok:true,checks,cleanup:'Test question rejected, answer hidden, vote removed. Test identity/events retained; no delete permission requested.'}));
