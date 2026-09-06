export const projectUrl = 'https://wnoibalxkbqrgmltfjrx.supabase.co';
export function publicConfig(env = process.env) {
  const url = (env.SUPABASE_URL || '').trim().replace(/\/+$/, '').replace(/\/rest\/v1$/, '');
  const key = (env.SUPABASE_ANON_KEY || '').trim();
  if (url !== projectUrl) throw new Error('Supabase URL must match the verified Meno project');
  let allowed = /^sb_publishable_[A-Za-z0-9_-]+$/.test(key);
  if (key.split('.').length === 3) {
    try { allowed = JSON.parse(Buffer.from(key.split('.')[1], 'base64url')).role === 'anon'; }
    catch { allowed = false; }
  }
  if (!allowed) throw new Error('Only a public publishable/anon key is permitted');
  return {supabaseUrl: url, supabaseAnonKey: key};
}
