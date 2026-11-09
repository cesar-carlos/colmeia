import 'dart:convert';

import 'package:colmeia/core/cache/app_cache_store.dart';
import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/logging/app_logger.dart';
import 'package:colmeia/features/agent_queries/domain/scheduling/cache_refresh_ports.dart';
import 'package:colmeia/features/agent_queries/domain/scheduling/cache_refresh_schedule.dart';
import 'package:uuid/uuid.dart';

class LocalCacheRefreshScheduleRepository
    implements CacheRefreshScheduleRepository {
  LocalCacheRefreshScheduleRepository(
    this._cache,
    this._lock, {
    this.isAuthorized,
  });
  final AppCacheStore _cache;
  final CacheRefreshLock _lock;
  final bool Function(String user)? isAuthorized;
  final _reportedInvalid = <String>{};
  static final _snapshotIdPattern = RegExp(r'^[a-f0-9-]{36}$');

  void _authorize(String user) {
    if (!(isAuthorized?.call(user) ?? true)) {
      throw const SessionFailure(message: 'schedule_session_changed');
    }
  }

  String _prefix(String user) => 'refresh/v1/${Uri.encodeComponent(user)}/';
  String _key(String user, String id) =>
      '${_prefix(user)}job/${Uri.encodeComponent(id)}';
  String _snapshots(String user, String id) =>
      '${_prefix(user)}snapshots/${Uri.encodeComponent(id)}/';
  Future<List<String>> _ids(String user) async {
    final raw = await _cache.getString('${_prefix(user)}index');
    return raw == null ? [] : (jsonDecode(raw) as List).cast<String>();
  }

  Future<void> _write(String key, Object value) async {
    final encoded = jsonEncode(value);
    await _cache.putString(key: key, value: encoded);
    if (await _cache.getString(key) != encoded) {
      throw const StorageFailure(
        message: 'schedule_storage_failed',
        userMessage: 'Não foi possível salvar a atualização no dispositivo.',
      );
    }
  }

  CacheRefreshRecord _invalid(String user, String id) {
    if (_reportedInvalid.add(_key(user, id))) {
      AppLogger.warning('cache.refresh.record_quarantined');
    }
    return CacheRefreshRecord(
      schedule: CacheRefreshSchedule(
        id: id,
        userId: user,
        agentId: 'unknown',
        reportId: 'invalid',
        enabled: false,
      ),
      revision: 'quarantined',
      state: const CacheRefreshState(
        status: CacheRefreshStatus.paused,
        reason: 'invalid_storage',
      ),
    );
  }

  Future<CacheRefreshRecord?> _read(
    String user,
    String id, {
    bool includeSnapshot = false,
  }) async {
    final raw = await _cache.getString(_key(user, id));
    if (raw == null) return null;
    late CacheRefreshRecord record;
    late Map<String, dynamic> json;
    try {
      json = jsonDecode(raw) as Map<String, dynamic>;
      record = CacheRefreshRecord.fromJson(json);
      if (record.schedule.userId != user || record.schedule.id != id) {
        return _invalid(user, id);
      }
      final snapshotId = record.snapshotId;
      if (snapshotId != null && !_snapshotIdPattern.hasMatch(snapshotId)) {
        return _invalid(user, id);
      }
    } on FormatException {
      return _invalid(user, id);
      // JSON casts and enum decoding can reject malformed persisted values.
      // ignore: avoid_catching_errors
    } on TypeError {
      return _invalid(user, id);
      // Enum names in persisted records are untrusted and may be unsupported.
      // ignore: avoid_catching_errors
    } on ArgumentError {
      return _invalid(user, id);
    }
    if (json['version'] == 1) {
      _authorize(user);
      // The index lock protects migration against concurrent edits/publication.
      record = await _publish(record, snapshot: record.snapshot);
    }
    if (!includeSnapshot || record.snapshotId == null) return record;
    final snapshotRaw = await _cache.getString(
      '${_snapshots(user, id)}${record.snapshotId}',
    );
    if (snapshotRaw == null) {
      AppLogger.warning('cache.refresh.snapshot_missing');
      return record;
    }
    try {
      return CacheRefreshRecord(
        schedule: record.schedule,
        revision: record.revision,
        state: record.state,
        snapshotId: record.snapshotId,
        snapshotBytes: record.snapshotBytes,
        currentDayPartial: record.currentDayPartial,
        queryKeys: record.queryKeys,
        snapshot: jsonDecode(snapshotRaw) as Map<String, dynamic>,
      );
    } on FormatException {
      return _invalid(user, id);
      // JSON root casts reject corrupted snapshots at this storage boundary.
      // ignore: avoid_catching_errors
    } on TypeError {
      return _invalid(user, id);
    }
  }

  @override
  Future<CacheRefreshRecord?> read(
    String user,
    String id, {
    bool includeSnapshot = true,
  }) => _lock.run(
    'index-$user',
    () => _read(user, id, includeSnapshot: includeSnapshot),
  );

  Future<List<CacheRefreshRecord>> _list(String user) async {
    final records = <CacheRefreshRecord>[];
    for (final id in await _ids(user)) {
      final record = await _read(user, id);
      if (record != null) records.add(record);
    }
    return records;
  }

  @override
  Future<List<CacheRefreshRecord>> list(String user) =>
      _lock.run('index-$user', () => _list(user));

  Future<CacheRefreshRecord> _publish(
    CacheRefreshRecord record, {
    Map<String, dynamic>? snapshot,
  }) async {
    final s = record.schedule;
    var snapshotId = record.snapshotId;
    var bytes = record.snapshotBytes;
    var partial = record.currentDayPartial;
    var queryKeys = record.queryKeys;
    if (snapshot != null) {
      snapshotId = const Uuid().v4();
      bytes = utf8.encode(jsonEncode(snapshot)).length;
      partial = snapshot['currentDayPartial'] == true;
      final data = snapshot['data'];
      queryKeys = data is Map && data['queries'] is Map
          ? (data['queries'] as Map).keys.cast<String>().toList()
          : [];
      await _write('${_snapshots(s.userId, s.id)}$snapshotId', snapshot);
    }
    _authorize(s.userId);
    final published = CacheRefreshRecord(
      schedule: s,
      revision: record.revision,
      state: record.state,
      snapshotId: snapshotId,
      snapshotBytes: bytes,
      currentDayPartial: partial,
      queryKeys: queryKeys,
    );
    // This single metadata write is the publication point. Failed writes leave the old pointer valid.
    await _write(
      _key(s.userId, s.id),
      published.toJson(includeSnapshot: false),
    );
    try {
      await _cache.removeKeysWhere(
        prefix: _snapshots(s.userId, s.id),
        predicate: (key) => key != '${_snapshots(s.userId, s.id)}$snapshotId',
      );
    } on Object {
      // A committed generation remains valid even if orphan cleanup must be retried later.
      AppLogger.warning('cache.refresh.snapshot_cleanup_failed');
    }
    return published;
  }

  @override
  Future<void> save(CacheRefreshSchedule schedule) =>
      _lock.run('index-${schedule.userId}', () async {
        final records = await _list(schedule.userId);
        if (records.any(
          (r) =>
              !r.isQuarantined &&
              r.schedule.id != schedule.id &&
              r.schedule.identity == schedule.identity,
        )) {
          throw const ValidationFailure(
            message: 'duplicate_schedule',
            userMessage: 'Esta consulta já possui agendamento.',
          );
        }
        final existing = records
            .where((r) => r.schedule.id == schedule.id)
            .firstOrNull;
        if (existing?.isQuarantined ?? false) {
          throw const StorageFailure(
            message: 'quarantined_schedule',
            userMessage:
                'Remova o registro incompatível e crie um novo agendamento.',
          );
        }
        final previous = existing?.schedule.identity == schedule.identity
            ? existing
            : null;
        final ids = await _ids(schedule.userId);
        _authorize(schedule.userId);
        if (!ids.contains(schedule.id)) {
          ids.add(schedule.id);
          await _write('${_prefix(schedule.userId)}index', ids);
        }
        await _publish(
          CacheRefreshRecord(
            schedule: schedule,
            revision: const Uuid().v4(),
            snapshotId: previous?.snapshotId,
            snapshotBytes: previous?.snapshotBytes ?? 0,
            currentDayPartial: previous?.currentDayPartial ?? false,
            queryKeys: previous?.queryKeys ?? const [],
            state: CacheRefreshState(
              lastSuccess: previous?.state.lastSuccess,
              durationMs: previous?.state.durationMs,
              status: schedule.enabled
                  ? CacheRefreshStatus.waiting
                  : CacheRefreshStatus.paused,
            ),
          ),
        );
      });

  @override
  Future<bool> commit(
    CacheRefreshRecord previous,
    CacheRefreshState state, {
    Map<String, dynamic>? snapshot,
    bool discardSnapshot = false,
  }) => _lock.run('index-${previous.schedule.userId}', () async {
    final current = await _read(previous.schedule.userId, previous.schedule.id);
    _authorize(previous.schedule.userId);
    if (current == null ||
        current.isQuarantined ||
        current.revision != previous.revision) {
      return false;
    }
    await _publish(
      CacheRefreshRecord(
        schedule: current.schedule,
        revision: const Uuid().v4(),
        state: state,
        snapshotId: discardSnapshot ? null : current.snapshotId,
        snapshotBytes: discardSnapshot ? 0 : current.snapshotBytes,
        currentDayPartial: !discardSnapshot && current.currentDayPartial,
        queryKeys: discardSnapshot ? const [] : current.queryKeys,
      ),
      snapshot: discardSnapshot ? null : snapshot,
    );
    return true;
  });

  @override
  Future<void> remove(String user, String id) =>
      _lock.run('index-$user', () async {
        await _cache.removeString(_key(user, id));
        if (await _cache.getString(_key(user, id)) != null) {
          throw const StorageFailure(message: 'schedule_delete_failed');
        }
        await _cache.removeKeysWithPrefix(_snapshots(user, id));
        final ids = await _ids(user)
          ..remove(id);
        await _write('${_prefix(user)}index', ids);
        _reportedInvalid.remove(_key(user, id));
      });
  @override
  Future<void> clearUser(String user) => _lock.run('index-$user', () async {
    await _cache.removeKeysWithPrefix(_prefix(user));
    if (await _cache.getString('${_prefix(user)}index') != null) {
      throw const StorageFailure(message: 'schedule_delete_failed');
    }
    _reportedInvalid.removeWhere((key) => key.startsWith(_prefix(user)));
  });
}
