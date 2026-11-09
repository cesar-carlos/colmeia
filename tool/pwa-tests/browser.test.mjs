import {test} from 'node:test';
import assert from 'node:assert/strict';
import {createServer} from 'node:http';
import {readFile} from 'node:fs/promises';
import {resolve, extname, sep} from 'node:path';
import {createHash} from 'node:crypto';
import {chromium} from 'playwright';

const root = resolve(import.meta.dirname, '../../build/web');
const hash = bytes => createHash('sha256').update(bytes).digest('hex');
const types = {'.js':'text/javascript', '.wasm':'application/wasm', '.html':'text/html', '.json':'application/json', '.png':'image/png', '.woff2':'font/woff2'};

for (const prefix of ['/', '/colmeia/']) {
  test(`production shell supports offline routes and interrupted updates at ${prefix}`, {timeout:180000}, async () => {
    const originalIndex = await readFile(resolve(root,'index.html'));
    let index = Buffer.from(originalIndex.toString().replace('<base href="/">', `<base href="${prefix}">`));
    let worker = (await readFile(resolve(root,'pwa-worker.js'),'utf8')).replaceAll(hash(originalIndex),hash(index));
    let failInstall = false;
    const server = createServer(async (req,res) => {
      const pathname = new URL(req.url,'http://localhost').pathname;
      if (!pathname.startsWith(prefix)) {res.writeHead(404).end(); return;}
      const relative = decodeURIComponent(pathname.slice(prefix.length));
      const path = resolve(root, relative || 'index.html');
      if (!path.startsWith(root + sep)) {res.writeHead(404).end(); return;}
      res.setHeader('Cache-Control','no-store');
      if (relative === 'pwa-worker.js') {res.setHeader('Content-Type','text/javascript');res.end(worker);return;}
      if (failInstall && relative === 'main.dart.js') {res.writeHead(503).end();return;}
      try {
        const data = !relative || relative === 'index.html' ? index : await readFile(path);
        res.setHeader('Content-Type', types[extname(path)] ?? 'application/octet-stream');
        res.end(data);
      } catch {
        if (extname(path)) res.writeHead(404).end();
        else {res.setHeader('Content-Type','text/html');res.end(index);}
      }
    });
    await new Promise(done=>server.listen(0,'127.0.0.1',done));
    const url = `http://127.0.0.1:${server.address().port}${prefix}`;
    let browser;
    let context;
    try {
    browser = await chromium.launch(process.env.PWA_CHROME_PATH ? {executablePath:process.env.PWA_CHROME_PATH,headless:true} : {headless:true});
    context = await browser.newContext();
      const page = await context.newPage();
      await page.goto(url);
      await page.evaluate(()=>navigator.serviceWorker.ready);
      await page.waitForFunction(()=>navigator.serviceWorker.controller !== null);
      const estimate = await page.evaluate(()=>window.colmeiaPwa.estimate());
      assert.ok(Number.isFinite(estimate.usage) && estimate.usage >= 0);
      assert.ok(Number.isFinite(estimate.quota) && estimate.quota >= estimate.usage);
      await page.waitForSelector('flutter-view',{state:'attached',timeout:60000});
      let old = await page.evaluate(()=>caches.keys());
      assert.ok(old.some(key=>key.startsWith('colmeia-shell-')));
      await context.setOffline(true);
      await page.goto(url + 'agents');
      await page.waitForSelector('flutter-view',{state:'attached',timeout:60000});
      assert.equal(await page.evaluate(()=>navigator.onLine),false);
      await page.goto(url + 'index.html');
      await page.waitForSelector('flutter-view',{state:'attached',timeout:60000});
      assert.equal(await page.evaluate(()=>navigator.onLine),false);
      assert.equal(await page.evaluate(async()=> {const response=await fetch('main.dart.js');await response.arrayBuffer();return response.status;}),200);
      await context.setOffline(false);
      assert.equal(await page.evaluate(async()=> (await fetch('missing.js')).status),404);
      const other = await context.newPage();
      await other.goto(url);
      await other.waitForFunction(()=>!!window.colmeiaPwa);
      await other.waitForSelector('flutter-view',{state:'attached',timeout:60000});
      
      await other.evaluate(()=>window.colmeiaPwa.beginWork());
      await other.evaluate(()=>{
        window.lockAcquired = false;
        window.lockWork = window.colmeiaPwa.exclusive('test-package', () => new Promise(resolve=>{window.releaseLock=resolve;window.lockAcquired=true;}));
      });
      await other.waitForFunction(()=>window.lockAcquired);
      assert.equal(await page.evaluate(async()=>{
        try {await window.colmeiaPwa.exclusive('test-package',async()=>{});return false;} catch {return true;}
      }),true);
      await other.evaluate(async()=>{window.releaseLock();await window.lockWork;});
      const updatedIndex = Buffer.from(index.toString().replace(/content="[a-f0-9]{20}"/, 'content="22222222222222222222"'));
      worker = worker.replaceAll(hash(index),hash(updatedIndex)).replace(/const RELEASE = '[a-f0-9]{20}'/, "const RELEASE = '22222222222222222222'");
      index = updatedIndex;
      await page.evaluate(async()=>{
        const registration=await navigator.serviceWorker.getRegistration();
        await registration.update();
        if(registration.waiting) return;
        await new Promise((resolve,reject)=>{
          const installing=registration.installing;
          if(!installing) {reject(new Error('No installing update'));return;}
          const changed=()=>{if(installing.state==='installed')resolve();else if(installing.state==='redundant')reject(new Error('Update installation failed'));};
          installing.addEventListener('statechange',changed);changed();
        });
      });
      await page.evaluate(()=>{window.pwaBusy=false;window.addEventListener('colmeia-update-busy',()=>window.pwaBusy=true,{once:true});return window.colmeiaPwa.update();});
      await page.waitForFunction(()=>window.pwaBusy);
      assert.notEqual(await page.locator('meta[name="colmeia-release"]').getAttribute('content'),'22222222222222222222');
      await other.evaluate(()=>window.colmeiaPwa.endWork());
      await page.evaluate(()=>window.colmeiaPwa.update());
      await page.waitForFunction(()=>document.querySelector('meta[name="colmeia-release"]').content === '22222222222222222222');
      await other.waitForFunction(()=>document.querySelector('meta[name="colmeia-release"]').content === '22222222222222222222');
      await other.close();
      old = (await page.evaluate(()=>caches.keys())).filter(key=>key.endsWith('22222222222222222222'));
      // A new worker cannot replace the previous generation until every file verifies.
      failInstall = true;
      worker = worker.replace(/const RELEASE = '[a-f0-9]{20}'/, "const RELEASE = '11111111111111111111'");
      const state = await page.evaluate(async()=>{
        const registration = await navigator.serviceWorker.getRegistration();
        const failed = new Promise(resolve=>registration.addEventListener('updatefound',()=>{
          const installing = registration.installing;
          installing.addEventListener('statechange',()=>{
            if (['installed','redundant'].includes(installing.state)) resolve(installing.state);
          });
        },{once:true}));
        await registration.update(); return failed;
      });
      assert.equal(state,'redundant');
      await context.setOffline(true);
      await page.reload();
      await page.waitForSelector('flutter-view',{state:'attached',timeout:60000});
      const remaining = await page.evaluate(()=>caches.keys());
      assert.ok(old.filter(key=>key.startsWith('colmeia-shell-')).every(key=>remaining.includes(key)));
      assert.ok(!remaining.some(key=>key.endsWith('11111111111111111111')));
    } finally {await context?.close();await browser?.close();await new Promise(done=>server.close(done));}
  });
}
