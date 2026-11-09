import {test} from 'node:test';
import assert from 'node:assert/strict';
import {createServer} from 'node:http';
import {readFile, mkdir} from 'node:fs/promises';
import {resolve, extname, sep} from 'node:path';
import {chromium} from 'playwright';

test('scheduler uses real Web Locks and IndexedDB across tabs and restart', {timeout:180000}, async () => {
  const root = resolve(import.meta.dirname, '../../build/cache_refresh_browser');
  const types = {'.js':'text/javascript','.wasm':'application/wasm','.html':'text/html','.json':'application/json'};
  const server = createServer(async (req,res) => {
    const path = resolve(root, decodeURIComponent(new URL(req.url,'http://localhost').pathname).slice(1) || 'index.html');
    if (!path.startsWith(root + sep)) return res.writeHead(404).end();
    try {res.setHeader('Content-Type',types[extname(path)] ?? 'application/octet-stream');res.end(await readFile(path));}
    catch {res.writeHead(404).end();}
  });
  await new Promise(done=>server.listen(0,'127.0.0.1',done));
  let browser;
  try {
    browser = await chromium.launch(process.env.PWA_CHROME_PATH ? {executablePath:process.env.PWA_CHROME_PATH,headless:true} : {headless:true});
    const context = await browser.newContext();
    const url = `http://127.0.0.1:${server.address().port}/`;
    const first = await context.newPage();
    const second = await context.newPage();
    const errors = [];
    for (const page of [first,second]) page.on('pageerror', error=>errors.push(error.message));
    const call = (page,operation,extra={}) => page.evaluate(async args=>JSON.parse(await window.cacheRefreshSmoke(JSON.stringify(args))).value,{operation,...extra});
    for (const page of [first,second]) {await page.goto(url);await page.waitForFunction(()=>!!window.cacheRefreshSmoke);}
    await call(first,'seed');
    await Promise.all([call(first,'offline',{agent:'A'}),call(second,'offline',{agent:'A'})]);
    await Promise.all([call(first,'start'),call(second,'start')]);
    await first.waitForFunction(async()=>{
      const s=JSON.parse(await window.cacheRefreshSmoke(JSON.stringify({operation:'state'}))).value;
      return s.B==='1' && s.records.find(r=>r.schedule.agentId==='A')?.state.status==='waitingAgent'
        && s.records.find(r=>r.schedule.agentId==='B')?.state.lastSuccess !== null;
    });
    let state = await call(first,'state');
    assert.equal(state.A,null);
    assert.equal(state.records.find(r=>r.schedule.agentId==='A').state.status,'waitingAgent');
    await Promise.all([call(first,'recover',{agent:'A'}),call(second,'recover',{agent:'A'})]);
    await first.waitForFunction(async()=>JSON.parse(await window.cacheRefreshSmoke(JSON.stringify({operation:'state'}))).value.A === '1');
    await first.reload();
    await first.waitForFunction(()=>!!window.cacheRefreshSmoke);
    await call(first,'start');
    state = await call(first,'state');
    assert.equal(state.A,'1');assert.equal(state.B,'1');
    await call(first,'advance');
    await first.waitForFunction(async()=>{
      const s=JSON.parse(await window.cacheRefreshSmoke(JSON.stringify({operation:'state'}))).value;
      return s.A==='2' && s.B==='2' && s.running.length===0;
    });
    for (const [page, slot] of [[first,0],[second,1]]) {
      await page.evaluate(slot=>{
        window.capacityHeld=false;
        window.capacityPromise=navigator.locks.request(`colmeia-refresh-capacity-smoke-${slot}`,async()=>{
          window.capacityHeld=true;
          await new Promise(resolve=>window.releaseCapacity=resolve);
        });
      },slot);
      await page.waitForFunction(()=>window.capacityHeld);
    }
    await call(first,'advance');
    await first.waitForFunction(async()=>{
      const s=JSON.parse(await window.cacheRefreshSmoke(JSON.stringify({operation:'state'}))).value;
      return s.records.every(r=>r.state.reason==='capacity_busy');
    });
    state=await call(first,'state');
    assert.equal(state.A,'2');assert.equal(state.B,'2');
    await first.evaluate(async()=>{window.releaseCapacity();await window.capacityPromise;});
    await call(first,'advanceSeconds');
    await first.waitForFunction(async()=>{
      const s=JSON.parse(await window.cacheRefreshSmoke(JSON.stringify({operation:'state'}))).value;
      return s.A==='3' || s.B==='3';
    });
    await second.evaluate(async()=>{window.releaseCapacity();await window.capacityPromise;});
    await call(first,'advanceSeconds');
    await first.waitForFunction(async()=>{
      const s=JSON.parse(await window.cacheRefreshSmoke(JSON.stringify({operation:'state'}))).value;
      return s.A==='3' && s.B==='3' && s.running.length===0;
    });
    await mkdir(resolve(root,'evidence'),{recursive:true});
    for (const width of [390,1440]) {
      await first.setViewportSize({width,height:900});
      await first.waitForSelector('flutter-view',{state:'attached'});
      await first.screenshot({path:resolve(root,`evidence/scheduler-${width}.png`)});
    }
    await call(first,'logout');
    assert.deepEqual((await call(second,'state')).records,[]);
    assert.deepEqual(errors,[]);
  } finally {
    await browser?.close();
    await new Promise(done=>server.close(done));
  }
});
