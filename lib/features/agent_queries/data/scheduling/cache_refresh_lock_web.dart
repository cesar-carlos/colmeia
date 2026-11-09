import 'dart:js_interop';

import 'package:colmeia/features/agent_queries/domain/scheduling/cache_refresh_ports.dart';

@JS('navigator.locks.request')
external JSPromise<JSAny?> _request(JSString name, JSFunction action);
@JS('navigator.locks.request')
external JSPromise<JSAny?> _tryRequest(
  JSString name,
  JSObject options,
  JSFunction action,
);
CacheRefreshLock createCacheRefreshLock() => _BrowserCacheRefreshLock();

class _BrowserCacheRefreshLock implements CacheRefreshLock {
  @override
  Future<bool> runIfAvailable(
    String name,
    Future<void> Function() action,
  ) async {
    var acquired = false;
    Object? failure;
    StackTrace? stack;
    await _tryRequest(
      'colmeia-refresh-$name'.toJS,
      {'ifAvailable': true}.jsify()! as JSObject,
      ((JSAny? lock) => (() async {
        if (lock == null) return null;
        acquired = true;
        try {
          await action();
        } on Object catch (error, trace) {
          failure = error;
          stack = trace;
        }
        return null;
      })().toJS).toJS,
    ).toDart;
    if (failure != null) Error.throwWithStackTrace(failure!, stack!);
    return acquired;
  }

  @override
  Future<T> run<T>(String name, Future<T> Function() action) async {
    late T result;
    Object? failure;
    StackTrace? stack;
    await _request(
      'colmeia-refresh-$name'.toJS,
      ((JSAny? _) => (() async {
        try {
          result = await action();
        } on Object catch (error, trace) {
          failure = error;
          stack = trace;
        }
        return null;
      })().toJS).toJS,
    ).toDart;
    if (failure != null) Error.throwWithStackTrace(failure!, stack!);
    return result;
  }
}
