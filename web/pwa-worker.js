/* Static files only. Private data belongs to the application IndexedDB store. */
'use strict';
const RELEASE = '__PWA_RELEASE__';
const FILES = __PWA_FILES__;
const scope = new URL(self.registration.scope);
const PREFIX = 'colmeia-shell-' + encodeURIComponent(scope.pathname) + '-';
const CACHE = PREFIX + RELEASE;
const localUrl = path => new URL(path, scope).href;
const known = new Set(FILES.map(file => localUrl(file.url)));
const metadata = 'colmeia-pwa-clients-' + encodeURIComponent(scope.pathname);

function pushConsent(enabled) {
  return new Promise((resolve, reject) => {
    const opening = indexedDB.open('colmeia-pwa-control',1);
    opening.onupgradeneeded = () => opening.result.createObjectStore('preferences');
    opening.onerror = () => reject(opening.error);
    opening.onsuccess = () => {
      const db = opening.result;
      const transaction = db.transaction('preferences', enabled === undefined ? 'readonly' : 'readwrite');
      const store = transaction.objectStore('preferences');
      const request = enabled === undefined ? store.get(scope.href) : store.put(enabled,scope.href);
      transaction.oncomplete = () => {db.close();resolve(enabled === undefined ? request.result === true : true);};
      transaction.onabort = () => {db.close();reject(transaction.error);};
    };
  });
}

self.addEventListener('install', event => {
  event.waitUntil((async () => {
    const started = performance.now();
    const cache = await caches.open(CACHE);
    try {
      // Bounded fetches prevent flooding mobile radios and browser connections.
      for (let offset = 0; offset < FILES.length; offset += 4) {
        const results = await Promise.allSettled(FILES.slice(offset, offset + 4).map(async file => {
          const request = new Request(localUrl(file.url), {cache: 'no-store', credentials: 'omit'});
          const response = await fetch(request);
          if (!response.ok || response.type === 'opaque' || response.redirected) throw new Error('Incomplete release');
          const bytes = await response.clone().arrayBuffer();
          const digest = Array.from(new Uint8Array(await crypto.subtle.digest('SHA-256', bytes)))
            .map(value => value.toString(16).padStart(2, '0')).join('');
          if (digest !== file.sha256) throw new Error('Release integrity mismatch');
          await cache.put(request, response);
        }));
        if (results.some(result => result.status === 'rejected')) throw new Error('Incomplete release');
      }
      console.info('pwa.cache.installed', {release: RELEASE, files: FILES.length, durationMs: Math.round(performance.now() - started)});
    } catch (error) {
      console.warn('pwa.cache.install_failed', {release: RELEASE});
      await caches.delete(CACHE);
      throw error;
    }
  })());
});

async function clientRelease(clientId) {
  if (!clientId) return RELEASE;
  const cache = await caches.open(metadata);
  const stored = await cache.match(localUrl('__pwa_client__/' + clientId));
  return stored ? stored.text() : RELEASE;
}

async function cleanupReleases() {
  if (self.registration.installing || self.registration.waiting) return;
  const windows = (await self.clients.matchAll({type: 'window', includeUncontrolled: true}))
    .filter(client => client.url.startsWith(scope.href));
  const meta = await caches.open(metadata);
  const retained = new Set([CACHE]);
  for (const client of windows) {
    const stored = await meta.match(localUrl('__pwa_client__/' + client.id));
    // Unknown clients may still be loading the previous release.
    if (!stored) return;
    retained.add(PREFIX + await stored.text());
  }
  for (const key of await caches.keys()) {
    if (key.startsWith(PREFIX) && !retained.has(key)) await caches.delete(key);
  }
  const liveIds = new Set(windows.map(client => localUrl('__pwa_client__/' + client.id)));
  for (const key of await meta.keys()) if (!liveIds.has(key.url)) await meta.delete(key);
}

self.addEventListener('message', event => {
  if (!event.source || !event.source.url || !event.source.url.startsWith(scope.href)) return;
  const data = event.data || {};
  if (data.type === 'PWA_PUSH_ENABLED' && typeof data.enabled === 'boolean') {
    event.waitUntil(pushConsent(data.enabled).then(() => event.ports[0]?.postMessage(true), () => event.ports[0]?.postMessage(false)));
  }
  if (data.type === 'PWA_CLIENT_VERSION' && /^[a-f0-9]{20}$/.test(data.version)) {
    event.waitUntil((async () => {
      const cache = await caches.open(metadata);
      await cache.put(localUrl('__pwa_client__/' + event.source.id), new Response(data.version));
      if (self.registration.active?.scriptURL === self.location.href) await cleanupReleases();
    })());
  }
  if (data.type === 'PWA_ACTIVATE') {
    event.waitUntil((async () => {
      const windows = await self.clients.matchAll({type: 'window', includeUncontrolled: true});
      const ready = await Promise.all(windows.filter(client => client.url.startsWith(scope.href)).map(client => new Promise(resolve => {
        const channel = new MessageChannel();
        const timer = setTimeout(() => { channel.port1.close(); resolve(false); }, 3000);
        channel.port1.onmessage = message => {clearTimeout(timer); channel.port1.close(); resolve(message.data === true);};
        client.postMessage({type: 'PWA_PREPARE_UPDATE'}, [channel.port2]);
      })));
      if (ready.every(Boolean)) await self.skipWaiting();
      else for (const client of windows.filter(client => client.url.startsWith(scope.href))) client.postMessage({type: 'PWA_UPDATE_BUSY'});
    })());
  }
});

self.addEventListener('activate', event => {
  event.waitUntil((async () => {
    const clients = await self.clients.matchAll({type: 'window', includeUncontrolled: true});
    const live = clients.filter(client => client.url.startsWith(scope.href));
    // Retain old releases while any old window may still request lazy assets.
    if (live.length === 0) {
      for (const key of await caches.keys()) if (key.startsWith(PREFIX) && key !== CACHE) await caches.delete(key);
      await caches.delete(metadata);
    }
    await self.clients.claim();
  })());
});

self.addEventListener('fetch', event => {
  const request = event.request;
  const url = new URL(request.url);
  if (request.method !== 'GET' || url.origin !== scope.origin || !url.pathname.startsWith(scope.pathname)) return;
  if (request.headers.has('Authorization')) return;
  const relative = url.pathname.slice(scope.pathname.length);
  if (/^(api|socket\.io)(\/|$)/.test(relative)) return;
  const navigation = request.mode === 'navigate';
  const asset = localUrl(relative);
  if (!navigation && !known.has(asset) && !/\.(js|wasm|json|woff2?|ttf|png|jpe?g|svg|webp|bin)$/i.test(relative)) return;
  if (navigation && relative !== 'index.html' && /\.[a-z0-9]{1,8}$/i.test(relative)) return;
  event.respondWith((async () => {
    const version = navigation ? RELEASE : await clientRelease(event.clientId);
    const cache = await caches.open(PREFIX + version);
    const cached = await cache.match(navigation ? localUrl('index.html') : asset);
    // Never mix release assets with a newer deployment if a cache was evicted.
    if (cached) return cached;
    if (!navigation && !known.has(asset) && version === RELEASE) return fetch(request);
    if (!navigation) return new Response('Application files unavailable. Reconnect and reload.', {status: 503});
    return fetch(request);
  })());
});

self.addEventListener('push', event => {
  event.waitUntil((async () => {
    let payload;
    try { payload = event.data?.json(); } catch (_) { return; }
    if (!payload || !['access-approved', 'access-revoked'].includes(payload.type) || typeof payload.eventId !== 'string') return;
    if (!await pushConsent()) return;
    for (const client of await self.clients.matchAll({type:'window'})) {
      if (client.url.startsWith(scope.href)) client.postMessage({type:'PWA_PERMISSIONS_CHANGED'});
    }
    await self.registration.showNotification('Colmeia', {
      body: 'Seu acesso aos agentes foi atualizado. Abra o aplicativo para consultar.',
      icon: localUrl('icons/Icon-192.png'), tag: 'colmeia-' + payload.eventId,
      data: {url: localUrl('agents')},
    });
  })());
});
self.addEventListener('notificationclick', event => {
  event.notification.close();
  event.waitUntil((async () => {
    const target = localUrl('agents');
    const clients = await self.clients.matchAll({type: 'window', includeUncontrolled: true});
    const existing = clients.find(client => client.url.startsWith(scope.href));
    if (existing) {await existing.navigate(target); await existing.focus();}
    else await self.clients.openWindow(target);
  })());
});
