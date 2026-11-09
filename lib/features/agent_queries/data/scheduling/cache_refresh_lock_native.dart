import 'dart:async';

import 'package:colmeia/features/agent_queries/domain/scheduling/cache_refresh_ports.dart';

CacheRefreshLock createCacheRefreshLock() => LocalCacheRefreshLock();

class LocalCacheRefreshLock implements CacheRefreshLock {
  final _tails = <String, Future<void>>{};
  @override
  Future<bool> runIfAvailable(
    String name,
    Future<void> Function() action,
  ) async {
    if (_tails.containsKey(name)) return false;
    await run(name, action);
    return true;
  }

  @override
  Future<T> run<T>(String name, Future<T> Function() action) async {
    final previous = _tails[name] ?? Future<void>.value();
    final result = previous.then((_) => action());
    final tail = result.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    _tails[name] = tail;
    try {
      return await result;
    } finally {
      if (identical(_tails[name], tail)) unawaited(_tails.remove(name));
    }
  }
}
