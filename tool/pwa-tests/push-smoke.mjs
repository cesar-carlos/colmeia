// Optional provider smoke test. Uses a temporary browser profile and VAPID key.
// No subscription endpoint or private key is written to disk or printed.
import {createServer} from 'node:http';
import {readFile} from 'node:fs/promises';
import {resolve, extname, sep} from 'node:path';
import {createRequire} from 'node:module';
import {chromium} from 'playwright';

if (!process.env.PWA_SERVER_ROOT) throw new Error('PWA_SERVER_ROOT is required');
const require = createRequire(resolve(process.env.PWA_SERVER_ROOT,'package.json'));
const webPush = require('web-push');
const keys = webPush.generateVAPIDKeys();
const root = resolve(import.meta.dirname,'../../build/web');
const types={'.js':'text/javascript','.html':'text/html','.json':'application/json','.wasm':'application/wasm'};
const server=createServer(async(req,res)=>{
  const pathname=new URL(req.url,'http://localhost').pathname;
  const path=resolve(root,'.'+pathname);
  if(path!==root && !path.startsWith(root+sep)){res.writeHead(404).end();return;}
  try {const file=path===root?resolve(root,'index.html'):path;res.setHeader('Content-Type',types[extname(file)]??'application/octet-stream');res.end(await readFile(file));}
  catch{res.writeHead(404).end();}
});
await new Promise(done=>server.listen(0,'127.0.0.1',done));
const url=`http://127.0.0.1:${server.address().port}/`;
let browser;
let context;
try {
browser=await chromium.launch({headless:true,...(process.env.PWA_CHROME_PATH?{executablePath:process.env.PWA_CHROME_PATH}:{})});
context=await browser.newContext({permissions:['notifications']});
  const page=await context.newPage();await page.goto(url);
  await page.evaluate(()=>navigator.serviceWorker.ready);
  let timer;
  const subscription=await Promise.race([
    page.evaluate(key=>window.colmeiaPwa.subscribe(key),keys.publicKey),
    new Promise((_,reject)=>{timer=setTimeout(()=>reject(new Error('Push provider subscription timed out')),20000);}),
  ]).finally(()=>clearTimeout(timer));
  if(!subscription)throw new Error('Push permission or provider unavailable');
  await page.evaluate(()=>window.colmeiaPwa.setPushEnabled(true));
  await page.close();
  await webPush.sendNotification(subscription,JSON.stringify({type:'access-approved',eventId:'pwa-provider-smoke'}),{
    TTL:60,timeout:15000,vapidDetails:{subject:'mailto:pwa-test@example.test',publicKey:keys.publicKey,privateKey:keys.privateKey},
  });
  const verify=await context.newPage();await verify.goto(url);
  await verify.waitForFunction(async()=>{
    const registration=await navigator.serviceWorker.ready;
    return (await registration.getNotifications()).some(item=>item.tag==='colmeia-pwa-provider-smoke');
  },{},{timeout:20000});
  await verify.evaluate(()=>window.colmeiaPwa.setPushEnabled(false));
  await verify.evaluate(()=>window.colmeiaPwa.unsubscribe());
  console.log('PASS: real provider delivered a generic notification after the application tab closed');
} finally {await context?.close();await browser?.close();await new Promise(done=>server.close(done));}
