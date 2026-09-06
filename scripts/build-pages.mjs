import {mkdir, cp, writeFile, readFile} from 'node:fs/promises';
import {publicConfig} from './public-config.mjs';
const config = publicConfig();
await mkdir('dist/admin', {recursive:true});
await mkdir('dist/assets/fonts', {recursive:true});
await cp('docs', 'dist', {recursive:true});
for (const file of ['index.html','styles.css','app.js']) {
  const source = await readFile(`admin/${file}`, 'utf8');
  if (/SUPABASE_ADMIN_(EMAIL|PASSWORD)|service_role|sb_secret_/.test(source)) throw new Error('Unsafe admin asset');
  await cp(`admin/${file}`, `dist/admin/${file}`);
}
await cp('assets/fonts', 'dist/assets/fonts', {recursive:true});
await writeFile('dist/admin/config.js', `window.MENO_CONFIG = Object.freeze(${JSON.stringify(config)});\n`);
await writeFile('dist/.nojekyll', '');
console.log('Pages bundle built with verified public configuration only.');
