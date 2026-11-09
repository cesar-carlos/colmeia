(() => {
  'use strict';
  const version = document.querySelector('meta[name="colmeia-release"]')?.content;
  if (!version || !('serviceWorker' in navigator) || !window.isSecureContext) return;
  let busy = 0;
  let updating = false;
  let updateTimer;
  let prompt;
  let registration;
  const emit = (type, detail) => window.dispatchEvent(new CustomEvent(type, {detail}));
  window.colmeiaPwa = {
    get supported() {return true;},
    get updateAvailable() {return !!registration?.waiting;},
    get online() {return navigator.onLine;},
    beginWork() { if (updating) throw new Error('Update in progress'); busy++; },
    endWork() {busy = Math.max(0, busy - 1);},
    async install() {if (!prompt) return false; await prompt.prompt(); const result = await prompt.userChoice; prompt = null; return result.outcome === 'accepted';},
    async update() {const current = await navigator.serviceWorker.getRegistration(new URL('./', document.baseURI)); registration = current; current?.waiting?.postMessage({type: 'PWA_ACTIVATE'});},
    async exclusive(name, action) {
      if (!navigator.locks) throw new Error('Exclusive offline synchronization is unavailable');
      return navigator.locks.request('colmeia-' + name, {ifAvailable: true}, lock => {
        if (!lock) throw new Error('Sincronização em andamento em outra aba.');
        return action();
      });
    },
    async persist() {return navigator.storage?.persist ? navigator.storage.persist() : false;},
    async estimate() {
      try {return navigator.storage?.estimate ? await navigator.storage.estimate() : null;}
      catch {return null;}
    },
    async setPushEnabled(enabled) {
      const ready = await navigator.serviceWorker.ready;
      return new Promise((resolve, reject) => {
        const channel = new MessageChannel();
        const timer = setTimeout(() => {channel.port1.close();reject(new Error('Push preferences timeout'));}, 5000);
        channel.port1.onmessage = event => {clearTimeout(timer); channel.port1.close(); event.data ? resolve() : reject(new Error('Push preferences unavailable'));};
        ready.active.postMessage({type:'PWA_PUSH_ENABLED',enabled},[channel.port2]);
      });
    },
    async subscribe(publicKey) {
      if (!('Notification' in window) || !('PushManager' in window)) return null;
      if (await Notification.requestPermission() !== 'granted') return null;
      const ready = await navigator.serviceWorker.ready;
      const old = await ready.pushManager.getSubscription();
      if (old) return old.toJSON();
      const padding = '='.repeat((4 - publicKey.length % 4) % 4);
      const bytes = Uint8Array.from(atob((publicKey + padding).replace(/-/g, '+').replace(/_/g, '/')), c => c.charCodeAt(0));
      return (await ready.pushManager.subscribe({userVisibleOnly: true, applicationServerKey: bytes})).toJSON();
    },
    async unsubscribe() {const current = await navigator.serviceWorker.ready; return (await current.pushManager.getSubscription())?.unsubscribe() ?? true;},
  };
  window.addEventListener('beforeinstallprompt', event => {event.preventDefault(); prompt = event; emit('colmeia-install-available');});
  window.addEventListener('appinstalled', () => emit('colmeia-installed'));
  window.addEventListener('online', () => emit('colmeia-network', true));
  window.addEventListener('offline', () => emit('colmeia-network', false));
  const identify = () => navigator.serviceWorker.controller?.postMessage({type: 'PWA_CLIENT_VERSION', version});
  navigator.serviceWorker.addEventListener('message', event => {
    if (event.data?.type === 'PWA_PERMISSIONS_CHANGED') emit('colmeia-permissions-changed');
    if (event.data?.type === 'PWA_PREPARE_UPDATE') {
      if (busy === 0) {clearTimeout(updateTimer);updating = true;updateTimer=setTimeout(() => {updating = false;}, 30000);}
      event.ports[0]?.postMessage(busy === 0);
      event.ports[0]?.close();
    }
    if (event.data?.type === 'PWA_UPDATE_BUSY') {clearTimeout(updateTimer);updating = false; emit('colmeia-update-busy');}
  });
  navigator.serviceWorker.addEventListener('controllerchange', () => {
    if (updating) location.reload(); else identify();
  });
  navigator.serviceWorker.getRegistration(new URL('./', document.baseURI)).then(value => {if(value && !registration) {registration=value;identify();if(value.waiting) emit('colmeia-update-available');}});
  navigator.serviceWorker.register(new URL('pwa-worker.js', document.baseURI), {updateViaCache: 'none'}).then(value => {
    registration = value; identify();
    if (value.waiting) emit('colmeia-update-available');
    value.addEventListener('updatefound', () => {
      const worker = value.installing;
      worker?.addEventListener('statechange', () => {
        if (worker.state === 'installed' && navigator.serviceWorker.controller) emit('colmeia-update-available');
      });
    });
    window.addEventListener('focus', () => value.update().catch(() => emit('colmeia-update-check-failed')));
  }).catch(() => emit('colmeia-pwa-install-failed'));
})();
