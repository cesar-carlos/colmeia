import 'dart:async';

import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/features/agent_queries/data/repositories/agent_queries_request_key.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_batch_execution_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_batch_request.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_request.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execution_result.dart';
import 'package:colmeia/features/agent_queries/domain/ports/agent_queries_cancel_scope.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/agent_queries_repository.dart';
import 'package:colmeia/features/agent_queries/domain/scheduling/cache_refresh_ports.dart';
import 'package:colmeia/features/agent_queries/domain/scheduling/cache_refresh_schedule.dart';
import 'package:result_dart/result_dart.dart';

class ScheduledQueryCapture {
  ScheduledQueryCapture({this.cancelScope});
  final AgentQueriesCancelScope? cancelScope;
  final queries = <String, dynamic>{};
  bool incomplete = false;
  static final Object _key = Object();
  static ScheduledQueryCapture? get current =>
      Zone.current[_key] as ScheduledQueryCapture?;
  Future<T> run<T>(Future<T> Function() action) =>
      runZoned(action, zoneValues: {_key: this});
}

class ScheduledQuerySnapshots implements AgentQueriesRepository {
  ScheduledQuerySnapshots(
    this._delegate,
    this._store,
    this._presence,
    this._online,
  );
  final AgentQueriesRepository _delegate;
  final CacheRefreshScheduleRepository _store;
  final CacheRefreshPresence _presence;
  final bool Function() _online;
  Future<Map<String, dynamic>?> _read(
    String? user,
    String agent,
    String key,
  ) async {
    if (user == null || !_online()) return null;
    final now = DateTime.now().toUtc();
    final records = await _store.list(user);
    for (final record in records) {
      if (!record.schedule.enabled ||
          record.schedule.agentId != agent ||
          record.state.status == CacheRefreshStatus.accessUnavailable ||
          record.state.lastSuccess == null ||
          now.difference(record.state.lastSuccess!) >=
              record.schedule.interval) {
        continue;
      }
      if (record.snapshot == null && !record.queryKeys.contains(key)) continue;
      final loaded = record.snapshot != null
          ? record
          : await _store.read(user, record.schedule.id);
      if (loaded?.revision != record.revision) continue;
      final snapshot = loaded?.snapshot;
      if (snapshot == null || snapshot['complete'] != true) continue;
      final period = record.schedule.resolvePeriod(DateTime.now());
      if (snapshot['periodStart'] != period.start.toIso8601String() ||
          snapshot['periodEnd'] != period.end.toIso8601String()) {
        continue;
      }
      final data = snapshot['data'];
      if (data is! Map || data['queries'] is! Map) continue;
      final entry = (data['queries'] as Map)[key];
      if (entry is! Map) continue;
      if (await _presence.reconcile(user, agent) !=
          RefreshAgentAvailability.online) {
        return null;
      }
      // Recheck after authorization: logout/edit may have removed this generation.
      final current = await _store.read(
        user,
        record.schedule.id,
        includeSnapshot: false,
      );
      if (current?.revision != record.revision) return null;
      return Map<String, dynamic>.from(entry);
    }
    return null;
  }

  @override
  Future<AppResult<AgentSqlExecutionResult>> executeSql(
    AgentSqlExecuteRequest request, {
    AgentQueriesCancelScope? cancelScope,
  }) async {
    final capture = ScheduledQueryCapture.current;
    final key = AgentQueriesRequestKey.build(request);
    if (capture == null &&
        !request.skipTransportCache &&
        !(cancelScope?.isCancelled ?? false)) {
      final saved = await _read(
        request.trimmedRequestingUserId,
        request.trimmedAgentId,
        key,
      );
      if (saved != null &&
          saved['kind'] == 'sql' &&
          !(cancelScope?.isCancelled ?? false)) {
        return Success(
          AgentSqlExecutionResult(
            rows: (saved['rows'] as List)
                .map((r) => Map<String, dynamic>.from(r as Map))
                .toList(),
            rowCount: saved['rowCount'] as int,
          ),
        );
      }
    }
    final result = await _delegate.executeSql(
      capture == null ? request : request.copyWith(skipTransportCache: true),
      cancelScope: cancelScope ?? capture?.cancelScope,
    );
    final value = result.getOrNull();
    if (capture != null &&
        value != null &&
        (value.rowCount != value.rows.length ||
            (request.executeOptions?.maxRows != null &&
                value.rows.length >= request.executeOptions!.maxRows!))) {
      capture.incomplete = true;
    }
    if (capture != null && value != null && value.pagination == null) {
      capture.queries[key] = {
        'kind': 'sql',
        'rows': value.rows,
        'rowCount': value.rowCount,
      };
    }
    return result;
  }

  @override
  Future<AppResult<AgentSqlBatchExecutionResult>> executeSqlBatch(
    AgentSqlExecuteBatchRequest request, {
    AgentQueriesCancelScope? cancelScope,
  }) async {
    final capture = ScheduledQueryCapture.current;
    final key = AgentQueriesRequestKey.buildBatch(request);
    if (capture == null &&
        !request.skipTransportCache &&
        !(cancelScope?.isCancelled ?? false)) {
      final saved = await _read(
        request.trimmedRequestingUserId,
        request.trimmedAgentId,
        key,
      );
      if (saved != null &&
          saved['kind'] == 'batch' &&
          !(cancelScope?.isCancelled ?? false)) {
        final items = (saved['items'] as List).map((e) {
          final m = e as Map;
          return AgentSqlBatchExecutionItem(
            index: m['index'] as int,
            ok: true,
            rows: (m['rows'] as List)
                .map((r) => Map<String, dynamic>.from(r as Map))
                .toList(),
            rowCount: m['rowCount'] as int,
            columnMetadata: (m['columns'] as List)
                .map((r) => Map<String, dynamic>.from(r as Map))
                .toList(),
          );
        }).toList();
        return Success(
          AgentSqlBatchExecutionResult(
            items: items,
            totalCommands: items.length,
            successfulCommands: items.length,
            failedCommands: 0,
          ),
        );
      }
    }
    final result = await _delegate.executeSqlBatch(
      capture == null ? request : request.copyWith(skipTransportCache: true),
      cancelScope: cancelScope ?? capture?.cancelScope,
    );
    final value = result.getOrNull();
    if (capture != null &&
        value != null &&
        (value.items.length != request.commands.length ||
            value.items.any(
              (item) =>
                  item.ok &&
                  (item.rowCount != item.rows.length ||
                      (request.options?.maxRows != null &&
                          item.rows.length >= request.options!.maxRows!)),
            ))) {
      capture.incomplete = true;
    }
    if (capture != null &&
        value != null &&
        value.failedCommands == 0 &&
        value.items.length == request.commands.length &&
        value.items.every((i) => i.ok)) {
      capture.queries[key] = {
        'kind': 'batch',
        'items': value.items
            .map(
              (i) => {
                'index': i.index,
                'rows': i.rows,
                'rowCount': i.rowCount,
                'columns': i.columnMetadata,
              },
            )
            .toList(),
      };
    }
    return result;
  }
}
