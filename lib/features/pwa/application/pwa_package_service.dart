import 'dart:convert';

import 'package:colmeia/core/cache/app_cache_store.dart';
import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/logging/app_logger.dart';
import 'package:colmeia/core/pwa/pwa_platform.dart';
import 'package:colmeia/features/agent_queries/domain/ports/agent_queries_cancel_scope.dart';
import 'package:colmeia/features/agent_queries/domain/scheduling/cache_refresh_ports.dart';
import 'package:colmeia/features/pwa/domain/offline_download_stage.dart';
import 'package:colmeia/features/pwa/domain/offline_package.dart';
import 'package:colmeia/features/pwa/domain/offline_package_exception.dart';
import 'package:colmeia/features/pwa/domain/offline_package_repository.dart';
import 'package:uuid/uuid.dart';

typedef OfflineDatasetLoader = Future<Map<String, dynamic>> Function(
  String userId,
  String agentId,
  DateTime start,
  DateTime end,
  AgentQueriesCancelScope cancelScope,
);

class PwaPackageService {
  PwaPackageService({
    required this.platform,
    required this.store,
    required this._cache,
    required this._authorization,
    required this._loader,
    DateTime Function()? clock,
    this.onRevoked,
    this.selectionLock,
  }) : _clock = clock ?? DateTime.now;
  final void Function()? onRevoked;
  final CacheRefreshLock? selectionLock;
  final PwaPlatform platform;
  final OfflinePackageRepository store;
  final AppCacheStore _cache;
  final OfflineAuthorizationGateway _authorization;
  final OfflineDatasetLoader _loader;
  final DateTime Function() _clock;
  int _generation = 0;
  int _purgeGeneration = 0;
  final _pending = <AgentQueriesCancelScope, String>{};
  final _agentGeneration = <String, int>{};
  final _agentPurges = <String, int>{};
  Future<void> _agentLock(
    String user,
    String agent,
    Future<void> Function() action,
  ) =>
      selectionLock?.run('offline-$user-$agent', action) ??
      platform.withLock('offline-$user-$agent', action);
  String _removalKey(String user, String agent) =>
      'pwa/removal/${Uri.encodeComponent(user)}/${Uri.encodeComponent(agent)}';
  Future<void> _selection(String user, Future<void> Function() action) =>
      selectionLock?.run('offline-selection-$user', action) ??
      platform.withLock('offline-selection-$user', action);
  String _selectionKey(String user) =>
      'pwa/selected/${Uri.encodeComponent(user)}';

  Future<List<String>> selectedAgents(String user) async {
    final raw = await _cache.getString(_selectionKey(user));
    if (raw == null) return <String>[];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List || decoded.any((value) => value is! String)) {
        return <String>[];
      }
      return decoded.cast<String>();
    } on FormatException {
      return <String>[];
    }
  }

  Future<bool> canRestoreOffline(String user) async {
    if (platform.online) return false;
    for (final agent in await selectedAgents(user)) {
      if (await store.read(user, agent, _clock()) != null) return true;
    }
    return false;
  }

  Future<OfflinePackage?> read(String user, String agent) =>
      store.read(user, agent, _clock());

  Future<void> synchronize(
    String user,
    String agent, {
    void Function(OfflineDownloadStage)? onProgress,
    AgentQueriesCancelScope? cancelScope,
    bool ifStale = false,
  }) async {
    if (!platform.online) {
      throw const OfflinePackageException(
        OfflinePackageIssue.connectionRequired,
      );
    }
    final generation = _generation;
    final purgeGeneration = _purgeGeneration;
    final removalKey = _removalKey(user, agent);
    final removalVersion = await _cache.getString(removalKey);
    final agentGeneration = _agentGeneration[agent] ?? 0;
    await _agentLock(user, agent, () async {
      platform.beginWork();
      final elapsed = Stopwatch()..start();
      var published = false;
      final scope = cancelScope ?? AgentQueriesCancelScope();
      final agentPurge = _agentPurges[agent] ?? 0;
      bool cancelled() =>
          generation != _generation ||
          scope.isCancelled ||
          agentGeneration != (_agentGeneration[agent] ?? 0);
      bool purged() =>
          purgeGeneration != _purgeGeneration ||
          agentPurge != (_agentPurges[agent] ?? 0);
      _pending[scope] = agent;
      try {
        if (await _cache.getString(removalKey) != removalVersion) {
          throw const OfflinePackageException(OfflinePackageIssue.cancelled);
        }
        if (cancelled()) {
          throw const OfflinePackageException(OfflinePackageIssue.cancelled);
        }
        if (ifStale) {
          final current = await read(user, agent);
          if (current != null &&
              _clock().toUtc().difference(current.savedAt) <
                  const Duration(minutes: 15)) {
            return;
          }
        }
        onProgress?.call(OfflineDownloadStage.authorizing);
        var authorization = await _authorization.authorize(agent);
        if (cancelled()) {
          throw const OfflinePackageException(OfflinePackageIssue.cancelled);
        }
        if (!authorization.permits(user, agent, _clock().toUtc())) {
          throw const OfflinePackageException(
            OfflinePackageIssue.authorizationExpired,
          );
        }
        final now = _clock();
        final end = DateTime(now.year, now.month, now.day);
        final start = DateTime(end.year, end.month, end.day - 29);
        onProgress?.call(OfflineDownloadStage.downloading);
        final datasets = await _loader(user, agent, start, end, scope);
        if (cancelled()) {
          throw const OfflinePackageException(OfflinePackageIssue.cancelled);
        }
        onProgress?.call(OfflineDownloadStage.revalidating);
        authorization = await _authorization.authorize(agent);
        if (cancelled()) {
          throw const OfflinePackageException(OfflinePackageIssue.cancelled);
        }
        if (!authorization.permits(user, agent, _clock().toUtc())) {
          throw const OfflinePackageException(
            OfflinePackageIssue.authorizationExpired,
          );
        }
        await _selection(user, () async {
          if (cancelled()) {
            throw const OfflinePackageException(OfflinePackageIssue.cancelled);
          }
          final selected = (await selectedAgents(user)).toSet()..add(agent);
          onProgress?.call(OfflineDownloadStage.saving);
          final selectedValue = jsonEncode(selected.toList()..sort());
          await _cache.putString(
            key: _selectionKey(user),
            value: selectedValue,
          );
          if (await _cache.getString(_selectionKey(user)) != selectedValue) {
            throw const OfflinePackageException(
              OfflinePackageIssue.storageUnavailable,
            );
          }
        });
        if (cancelled()) {
          throw const OfflinePackageException(OfflinePackageIssue.cancelled);
        }
        final previous = await store.read(user, agent, _clock());
        if (cancelled()) {
          throw const OfflinePackageException(OfflinePackageIssue.cancelled);
        }
        await store.publish(
          OfflinePackage(
            authorization: authorization,
            agentId: agent,
            savedAt: _clock().toUtc(),
            periodStart: start,
            periodEnd: end,
            datasets: datasets,
          ),
        );
        if (cancelled()) {
          if (previous != null && !purged()) {
            await store.publish(previous);
            if (purged()) {
              await store.remove(user, agent);
            }
          } else {
            await store.remove(user, agent);
          }
          throw const OfflinePackageException(OfflinePackageIssue.cancelled);
        }
        published = true;
      } on AuthorizationFailure {
        _agentPurges[agent] = (_agentPurges[agent] ?? 0) + 1;
        cancel(agentId: agent);
        await store.remove(user, agent);
        rethrow;
      } on SessionFailure {
        await clearUser(user);
        onRevoked?.call();
        rethrow;
      } finally {
        AppLogger.info(
          'pwa.package.synchronization',
          context: {
            'published': published,
            'durationMs': elapsed.elapsedMilliseconds,
          },
        );
        _pending.remove(scope);
        platform.endWork();
      }
    });
  }

  Future<void> remove(String user, String agent) async {
    _agentPurges[agent] = (_agentPurges[agent] ?? 0) + 1;
    cancel(agentId: agent);
    await _agentLock(user, agent, () async {
      await _cache.putString(
        key: _removalKey(user, agent),
        value: const Uuid().v4(),
      );
      await _selection(user, () async {
        await store.remove(user, agent);
        final selected = (await selectedAgents(user))..remove(agent);
        await _cache.putString(
          key: _selectionKey(user),
          value: jsonEncode(selected),
        );
      });
    });
  }

  void cancel({String? agentId}) {
    if (agentId == null) {
      _generation++;
    } else {
      _agentGeneration[agentId] = (_agentGeneration[agentId] ?? 0) + 1;
    }
    for (final entry in _pending.entries.toList()) {
      if (agentId == null || entry.value == agentId) entry.key.cancelAll();
    }
  }

  void invalidateSession() {
    _purgeGeneration++;
    cancel();
  }

  Future<void> clearUser(String user) async {
    invalidateSession();
    await store.clearUser(user);
    await _cache.removeString(_selectionKey(user));
  }
}
