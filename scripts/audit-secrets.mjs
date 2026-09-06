import {execFileSync} from 'node:child_process';
import {readFileSync,readdirSync,statSync} from 'node:fs';
import path from 'node:path';
let checked=0,findings=0;
function inspect(name,data) {
  checked++;
  const text=data.toString('utf8');
  let unsafe=/-----BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY-----|sb_secret_[A-Za-z0-9_-]{20,}|gh[pousr]_[A-Za-z0-9]{30,}/.test(text);
  for(const token of text.match(/eyJ[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+/g)||[]) {
    try {if(JSON.parse(Buffer.from(token.split('.')[1],'base64url')).role==='service_role')unsafe=true;}catch{}
  }
  if(/\.(jks|keystore|p12)$/i.test(name))unsafe=true;
  if(unsafe) {console.error('Potential private credential: '+name);findings++;}
}
if(process.argv.includes('--history')) {
  const entries=execFileSync('git',['rev-list','--objects','--all'],{encoding:'utf8'}).trim().split('\n');
  for(const entry of entries) {
    const [oid,...parts]=entry.split(' ');
    if(!parts.length)continue;
    const type=execFileSync('git',['cat-file','-t',oid],{encoding:'utf8'}).trim();
    if(type==='blob')inspect(parts.join(' '),execFileSync('git',['cat-file','blob',oid],{maxBuffer:20000000}));
  }
} else {
  const root=process.argv[2];
  if(root) {
    const visit=p=>{for(const item of readdirSync(p)){const f=path.join(p,item);if(statSync(f).isDirectory())visit(f);else inspect(f,readFileSync(f));}};
    visit(root);
  } else {
    const names=execFileSync('git',['ls-files','-z']).toString().split('\0').filter(Boolean);
    for(const name of names)inspect(name,readFileSync(name));
  }
}
console.log(JSON.stringify({checked,findings,scope:process.argv.slice(2)}));
if(findings)process.exitCode=1;
