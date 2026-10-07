@Tags(['e2e'])
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:colmeia/core/config/app_environment.dart';
import 'package:colmeia/core/di/injector.dart';
import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/features/agent_queries/domain/agent_sql_rpc_failure_ui_key.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_diagnostics.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_batch_request.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_options.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_request.dart';
import 'package:colmeia/features/agent_queries/domain/ports/agent_queries_cancel_scope.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/agent_queries_repository.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/e2e_dependency_bootstrap.dart';

const _enabled = bool.fromEnvironment('E2E_REQUEST_BENCHMARK');
const _route = String.fromEnvironment('E2E_BENCH_ROUTE', defaultValue: 'rest');
const _samples = int.fromEnvironment('E2E_BENCH_SAMPLES', defaultValue: 100);
const _warmups = int.fromEnvironment('E2E_BENCH_WARMUPS', defaultValue: 5);
const _scenarios = String.fromEnvironment(
  'E2E_BENCH_SCENARIOS',
  defaultValue: 'small,large,batch',
);

void main() {
  test(
    'strict per-request transport benchmark',
    () async {
      final bootstrap = Stopwatch()..start();
      await e2eSetupDependencies();
      addTearDown(e2eTeardownDependencies);
      expect(missingE2eRepositoryKeys(), isEmpty);
      expect(_samples, greaterThan(0));
      expect(_warmups, greaterThanOrEqualTo(0));
      _emit({
        'kind': 'bootstrap',
        'route': _route,
        'ms': bootstrap.elapsedMicroseconds / 1000,
      });

      final repository = getIt<AgentQueriesRepository>();
      final reference = <String, String>{};
      var initial = true;
      for (final scenario in _scenarios.split(',')) {
        for (final cache in [false, true]) {
          for (var index = -_warmups - 1; index < _samples; index++) {
            final phase = index == -_warmups - 1
                ? (initial ? 'initial' : 'prepare')
                : index < 0
                ? 'warmup'
                : 'sample';
            initial = false;
            final diagnostics = AgentQueryDiagnostics();
            final scope = AgentQueriesCancelScope(diagnostics: diagnostics);
            final rssBefore = ProcessInfo.currentRss;
            var peakRss = rssBefore;
            final memoryTimer = Timer.periodic(
              const Duration(milliseconds: 10),
              (_) {
                peakRss = math.max(peakRss, ProcessInfo.currentRss);
              },
            );
            final clock = Stopwatch()..start();
            AppFailure? requestFailure;
            try {
              late final Object rows;
              var count = 0;
              if (scenario == 'batch') {
                final result = await repository.executeSqlBatch(
                  AgentSqlExecuteBatchRequest(
                    agentId: AppEnvironment.e2eAgentId,
                    clientToken: AppEnvironment.e2eClientToken,
                    bridgeTimeoutMs: 60000,
                    // ignore: avoid_redundant_argument_values -- The benchmark route is selected by dart-define.
                    useRelay: _route == 'relay',
                    skipTransportCache: !cache,
                    options: const AgentSqlExecuteBatchOptions(maxRows: 1),
                    commands: const [
                      AgentSqlExecuteBatchCommand(
                        sql: 'SELECT TOP 1 CodCliente FROM Cliente ORDER BY CodCliente',
                      ),
                      AgentSqlExecuteBatchCommand(
                        sql: 'SELECT TOP 1 Nome FROM Cliente ORDER BY CodCliente',
                      ),
                    ],
                  ),
                  cancelScope: scope,
                );
                final value = result.getOrNull();
                if (value == null) {
                  requestFailure = result.exceptionOrNull();
                  throw StateError(
                    'Benchmark failed: ${result.exceptionOrNull().runtimeType}',
                  );
                }
                expect(value.items, hasLength(2));
                expect(value.items.every((item) => item.ok), isTrue);
                rows = value.items.map((item) => item.rows).toList();
                count = value.items.fold(
                  0,
                  (sum, item) => sum + item.rows.length,
                );
              } else {
                final limit = scenario == 'small' ? 1 : 5000;
                final result = await repository.executeSql(
                  AgentSqlExecuteRequest(
                    agentId: AppEnvironment.e2eAgentId,
                    clientToken: AppEnvironment.e2eClientToken,
                    sql:
                        'SELECT TOP $limit CodCliente, Nome FROM Cliente ORDER BY CodCliente',
                    bridgeTimeoutMs: 60000,
                    // ignore: avoid_redundant_argument_values -- The benchmark route is selected by dart-define.
                    useRelay: _route == 'relay',
                    skipTransportCache: !cache,
                    executeOptions: AgentSqlExecuteOptions(
                      maxRows: limit,
                      preferDbStreaming: false,
                    ),
                  ),
                  cancelScope: scope,
                );
                final value = result.getOrNull();
                if (value == null) {
                  requestFailure = result.exceptionOrNull();
                  throw StateError(
                    'Benchmark failed: ${result.exceptionOrNull().runtimeType}',
                  );
                }
                expect(value.rows, isNotEmpty);
                rows = value.rows;
                count = value.rows.length;
              }
              final measured = diagnostics.toJson();
              if (!diagnostics.cacheHit) {
                const expected = _route == 'legacy' ? 'socket_legacy' : _route;
                expect(
                  measured['transport'],
                  expected,
                  reason:
                      'Fallback cannot count as a sample of another transport',
                );
                expect(measured['fallback'], false);
              }
              final completionMs = clock.elapsedMicroseconds / 1000;
              memoryTimer.cancel();
              peakRss = math.max(peakRss, ProcessInfo.currentRss);
              final digest = sha256
                  .convert(utf8.encode(jsonEncode(_canonical(rows))))
                  .toString();
              reference.putIfAbsent(scenario, () => digest);
              expect(
                digest,
                reference[scenario],
                reason: 'Data changed between benchmark samples',
              );
              _emit({
                'kind': 'request',
                'route': _route,
                'scenario': scenario,
                'cache': cache,
                'phase': phase,
                'index': index,
                'completionMs': completionMs,
                'rows': count,
                'digest': digest,
                'rssBytes': peakRss,
                'rssGrowthBytes': math.max(0, peakRss - rssBefore),
                'diagnostics': diagnostics.toJson(),
                'success': true,
              });
            } on Object catch (error) {
              _emit({
                'kind': 'request',
                'route': _route,
                'scenario': scenario,
                'cache': cache,
                'phase': phase,
                'index': index,
                'success': false,
                'completionMs': clock.elapsedMicroseconds / 1000,
                'errorType': error.runtimeType.toString(),
                'failureType': requestFailure?.runtimeType.toString(),
                'failureUiKey':
                    requestFailure?.context[AgentSqlRpcFailureUiKey.field],
                'timeout':
                    error is TimeoutException ||
                    requestFailure?.cause is TimeoutException ||
                    requestFailure?.context['deadlineExceeded'] == true ||
                    requestFailure?.context[AgentSqlRpcFailureUiKey.field] ==
                        AgentSqlRpcFailureUiKey.transportTimeout ||
                    requestFailure?.context[AgentSqlRpcFailureUiKey.field] ==
                        AgentSqlRpcFailureUiKey.queryTimeout,
                'diagnostics': diagnostics.toJson(),
              });
              rethrow;
            } finally {
              memoryTimer.cancel();
              scope.cancelAll();
            }
          }
        }
      }
    },
    skip: !_enabled,
    timeout: const Timeout(Duration(minutes: 30)),
  );
}

Object? _canonical(Object? value) {
  if (value is Map) {
    final keys = value.keys.map((key) => key.toString()).toList()..sort();
    return {for (final key in keys) key: _canonical(value[key])};
  }
  if (value is List) {
    return value.map(_canonical).toList();
  }
  return value;
}

void _emit(Map<String, Object?> value) {
  // ignore: avoid_print -- Structured measurements contain no SQL or row values.
  print('REQUEST_BENCHMARK ${jsonEncode(value)}');
}
