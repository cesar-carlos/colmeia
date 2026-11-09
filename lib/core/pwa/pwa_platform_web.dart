import 'dart:async';
import 'dart:js_interop';

import 'package:colmeia/core/pwa/pwa_platform.dart';
import 'package:web/web.dart' as web;

@JS('colmeiaPwa')
external _PwaBridge? get _bridge;

extension type _PwaBridge(JSObject _) implements JSObject {
  external JSPromise<JSBoolean> install();
  external void update();
  external JSBoolean get updateAvailable;
  external JSPromise<JSAny?> setPushEnabled(JSBoolean enabled);
  external void beginWork();
  external void endWork();
  external JSPromise<JSBoolean> persist();
  external JSPromise<JSAny?> estimate();
  external JSPromise<JSAny?> subscribe(JSString publicKey);
  external JSPromise<JSAny?> unsubscribe();
  external JSPromise<JSAny?> exclusive(JSString name, JSFunction action);
}

PwaPlatform createPwaPlatform() => _WebPwaPlatform();

class _WebPwaPlatform implements PwaPlatform {
  _WebPwaPlatform() {
    for (final name in _eventNames) {
      final listener = ((web.Event event) => _events.add(event.type)).toJS;
      _listeners[name] = listener;
      web.window.addEventListener(name, listener);
    }
    _channel.onmessage = ((web.MessageEvent event) {
      if (event.data.dartify() == 'logout') _events.add('logout');
    }).toJS;
  }
  static const _eventNames = [
    'colmeia-permissions-changed',
    'online',
    'offline',
    'focus',
    'colmeia-update-available',
    'colmeia-update-busy',
    'colmeia-install-available',
    'colmeia-installed',
    'colmeia-pwa-install-failed',
  ];
  final _events = StreamController<String>.broadcast();
  final _listeners = <String, JSFunction>{};
  final _channel = web.BroadcastChannel('colmeia-session');
  @override
  bool get supported => _bridge != null;
  @override
  bool get online => web.window.navigator.onLine;
  @override
  bool get updateAvailable => _bridge?.updateAvailable.toDart ?? false;
  @override
  Stream<String> get events => _events.stream;
  @override
  Future<bool> install() async =>
      (await _bridge?.install().toDart)?.toDart ?? false;
  @override
  void update() => _bridge?.update();
  @override
  void beginWork() => _bridge?.beginWork();
  @override
  void endWork() => _bridge?.endWork();
  @override
  Future<bool> persistStorage() async =>
      (await _bridge?.persist().toDart)?.toDart ?? false;
  @override
  Future<({int usage, int quota})?> storageEstimate() async {
    final value = (await _bridge?.estimate().toDart).dartify();
    if (value case {'usage': final num usage, 'quota': final num quota}
        when usage.isFinite && quota.isFinite && usage >= 0 && quota >= 0) {
      return (usage: usage.toInt(), quota: quota.toInt());
    }
    return null;
  }

  @override
  Future<Map<String, dynamic>?> subscribe(String publicKey) async {
    final value = (await _bridge?.subscribe(publicKey.toJS).toDart).dartify();
    return value is Map ? Map<String, dynamic>.from(value) : null;
  }

  @override
  Future<void> setPushEnabled({required bool enabled}) async {
    await _bridge?.setPushEnabled(enabled.toJS).toDart;
  }

  @override
  Future<void> unsubscribe() async {
    await _bridge?.unsubscribe().toDart;
  }

  @override
  Future<void> withLock(String name, Future<void> Function() action) async {
    final bridge = _bridge;
    if (bridge == null) throw StateError('PWA indisponível neste ambiente.');
    await bridge.exclusive(name.toJS, (() => action().toJS).toJS).toDart;
  }

  @override
  void broadcastLogout() => _channel.postMessage('logout'.toJS);
  @override
  void dispose() {
    for (final entry in _listeners.entries) {
      web.window.removeEventListener(entry.key, entry.value);
    }
    _channel.close();
    unawaited(_events.close());
  }
}
