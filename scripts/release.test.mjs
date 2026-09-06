import test from 'node:test';
import assert from 'node:assert/strict';
import {readFile} from 'node:fs/promises';
import {publicConfig,projectUrl} from './public-config.mjs';
test('accepts public keys and normalizes REST URL', () => {
  assert.equal(publicConfig({SUPABASE_URL:projectUrl+'/rest/v1/',SUPABASE_ANON_KEY:'sb_publishable_test'}).supabaseUrl,projectUrl);
});
test('rejects private, malformed and wrong-project configuration', () => {
  for (const key of ['','sb_secret_fake','not-a-key',`a.${Buffer.from(JSON.stringify({role:'service_role'})).toString('base64url')}.c`]) {
    assert.throws(()=>publicConfig({SUPABASE_URL:projectUrl,SUPABASE_ANON_KEY:key}));
  }
  assert.throws(()=>publicConfig({SUPABASE_URL:'https://other.supabase.co',SUPABASE_ANON_KEY:'sb_publishable_test'}));
});
test('release identity and signing are explicit', async () => {
  const gradle=await readFile('android/app/build.gradle.kts','utf8');
  assert.match(gradle,/applicationId = "com.meno.app.meno"/);
  assert.match(gradle,/targetSdk = 36/);
  assert.match(gradle,/else null/);
});
test('admin hidden state cannot be overridden by layout styles',async()=>{
  assert.match(await readFile('admin/styles.css','utf8'),/\[hidden\]\s*\{\s*display:\s*none\s*!important/);
});
