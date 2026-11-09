import {test} from 'node:test';
import assert from 'node:assert/strict';
import {readFile} from 'node:fs/promises';
import {runInNewContext} from 'node:vm';

const template = await readFile(new URL('../../web/pwa-worker.js', import.meta.url), 'utf8');
const release = 'a'.repeat(20);
const previous = 'b'.repeat(20);

function harness(path, clientVersion = release) {
  const scope = `https://example.test${path}`;
  const prefix = `colmeia-shell-${encodeURIComponent(path)}-`;
  const handlers = new Map();
  const entries = new Map();
  let networkRequests = 0;
  runInNewContext(template.replace('__PWA_RELEASE__', release).replace('__PWA_FILES__', JSON.stringify([{url: 'index.html'}, {url: 'main.dart.js'}])), {
    URL, Response,
    self: {registration: {scope}, addEventListener: (name, callback) => handlers.set(name, callback)},
    caches: {open: async name => ({match: async url => name.startsWith('colmeia-pwa-clients-')
      ? new Response(clientVersion) : entries.get(`${name}:${url}`)})},
    fetch: async () => {networkRequests++; return new Response('deployment');},
  });
  return {
    cache(file, body, version = release) {entries.set(`${prefix}${version}:${scope}${file}`, new Response(body));},
    async request(file, mode = 'cors') {
      let response;
      handlers.get('fetch')({clientId: 'tab', request: {url: scope + file, method: 'GET', headers: new Headers(), mode}, respondWith: value => {response = value;}});
      return response;
    },
    get networkRequests() {return networkRequests;},
  };
}

for (const scope of ['/', '/colmeia/']) {
  test(`offline index.html navigation uses shell at ${scope}`, async () => {
    const worker = harness(scope);
    worker.cache('index.html', 'offline shell');
    assert.equal(await (await worker.request('index.html', 'navigate')).text(), 'offline shell');
    assert.equal(worker.networkRequests, 0);
  });
  test(`evicted old assets never fall through to a new deployment at ${scope}`, async () => {
    const worker = harness(scope, previous);
    assert.equal((await worker.request('removed-lazy-chunk.js')).status, 503);
    assert.equal(worker.networkRequests, 0);
    worker.cache('removed-lazy-chunk.js', 'old chunk', previous);
    assert.equal(await (await worker.request('removed-lazy-chunk.js')).text(), 'old chunk');
  });
  test(`missing current assets and API calls retain network semantics at ${scope}`, async () => {
    const worker = harness(scope);
    assert.equal(await (await worker.request('missing.js')).text(), 'deployment');
    assert.equal(await worker.request('api/data'), undefined);
    assert.equal(await worker.request('socket.io/'), undefined);
    assert.equal(await worker.request('missing.png', 'navigate'), undefined);
    assert.equal(worker.networkRequests, 1);
  });
}
