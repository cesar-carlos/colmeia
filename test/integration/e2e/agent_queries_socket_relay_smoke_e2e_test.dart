@Tags(['e2e'])
library;

import 'package:colmeia/core/config/agent_bridge_transport.dart';
import 'package:colmeia/core/config/app_environment.dart';
import 'package:colmeia/core/di/injector.dart';
import 'package:colmeia/core/errors/app_failure.dart'
    show AppFailure, RpcFailure;
import 'package:colmeia/core/socket/consumer_socket_connection.dart';
import 'package:colmeia/core/socket/relay/relay_command_dispatcher.dart';
import 'package:colmeia/core/socket/relay/relay_rpc_outcome.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_bridge_pagination.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_batch_request.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_options.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_request.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/agent_queries_repository.dart';
import 'package:flutter_test/flutter_test.dart' hide group;
import 'package:test_api/scaffolding.dart' show group;

import 'support/e2e_dependency_bootstrap.dart';

void main() {
  group(
    'Agent queries socket channel smoke (e2e)',
    () {
      registerE2eAgentQueriesSuiteHooks(
        missingKeys: _missingSocketSmokeSuiteKeys,
      );

      test(
        'relay path: sql.execute (+ batch) with phase breadcrumbs',
        () async {
          if (_shouldSkipSocketSmoke(requireRelay: true)) {
            return;
          }

          expect(getIt.isRegistered<ConsumerSocketConnection>(), isTrue);
          expect(getIt.isRegistered<RelayCommandDispatcher>(), isTrue);

          final connected = await getIt<ConsumerSocketConnection>().connect();
          expect(connected.socketId, isNotEmpty);

          final outcomes = <String>[];
          final outcomesSub = getIt<RelayCommandDispatcher>().outcomes().listen(
            (outcome) => outcomes.add(_describeRelayOutcome(outcome)),
          );
          addTearDown(outcomesSub.cancel);

          final sw = Stopwatch()..start();
          final repo = getIt<AgentQueriesRepository>();
          final single = await runE2eAppResult(
            () => repo.executeSql(
              AgentSqlExecuteRequest(
                agentId: AppEnvironment.e2eAgentId,
                clientToken: AppEnvironment.e2eClientToken,
                sql: 'SELECT CodCliente, Nome FROM Cliente ORDER BY CodCliente',
                bridgeTimeoutMs: 60000,
                pagination: const AgentSqlPagePagination(page: 1, pageSize: 1),
                executeOptions: const AgentSqlExecuteOptions(
                  maxRows: 1,
                  preferDbStreaming: false,
                ),
                useRelay: true,
              ),
            ),
            actionLabel: 'socket_relay_smoke_sql_execute',
          );
          sw.stop();

          // ignore: avoid_print -- E2E diagnostics
          print(
            'E2E relay unary wallMs=${sw.elapsedMilliseconds} '
            'outcomes=${outcomes.join(' | ')}',
          );

          single.fold(
            (success) {
              expect(success.rows, isNotEmpty);
            },
            (failure) => fail(
              'socket relay sql.execute smoke failed: '
              '${_describeFailure(failure)}; outcomes=${outcomes.join(' | ')}',
            ),
          );

          final batch = await runE2eAppResult(
            () => repo.executeSqlBatch(
              AgentSqlExecuteBatchRequest(
                agentId: AppEnvironment.e2eAgentId,
                clientToken: AppEnvironment.e2eClientToken,
                bridgeTimeoutMs: 60000,
                options: const AgentSqlExecuteBatchOptions(maxRows: 1),
                useRelay: true,
                commands: const <AgentSqlExecuteBatchCommand>[
                  AgentSqlExecuteBatchCommand(
                    sql: 'SELECT CodCliente FROM Cliente ORDER BY CodCliente',
                  ),
                  AgentSqlExecuteBatchCommand(
                    sql: 'SELECT Nome FROM Cliente ORDER BY CodCliente',
                  ),
                ],
              ),
            ),
            actionLabel: 'socket_relay_smoke_sql_execute_batch',
          );

          batch.fold(
            (success) {
              expect(success.items.length, 2);
              expect(success.items.every((item) => item.ok), isTrue);
            },
            (failure) => fail(
              'socket relay sql.executeBatch smoke failed: '
              '${_describeFailure(failure)}',
            ),
          );
        },
      );

      test(
        'agents:command path: same SQL with useRelay:false (A/B vs relay)',
        () async {
          if (_shouldSkipSocketSmoke(requireRelay: false)) {
            return;
          }

          expect(getIt.isRegistered<ConsumerSocketConnection>(), isTrue);
          final connected = await getIt<ConsumerSocketConnection>().connect();
          expect(connected.socketId, isNotEmpty);

          final sw = Stopwatch()..start();
          final repo = getIt<AgentQueriesRepository>();
          final result = await runE2eAppResult(
            () => repo.executeSql(
              AgentSqlExecuteRequest(
                agentId: AppEnvironment.e2eAgentId,
                clientToken: AppEnvironment.e2eClientToken,
                sql: 'SELECT CodCliente, Nome FROM Cliente ORDER BY CodCliente',
                bridgeTimeoutMs: 60000,
                pagination: const AgentSqlPagePagination(page: 1, pageSize: 1),
                executeOptions: const AgentSqlExecuteOptions(
                  maxRows: 1,
                  preferDbStreaming: false,
                ),
              ),
            ),
            actionLabel: 'socket_agents_command_smoke_sql_execute',
          );
          sw.stop();

          // ignore: avoid_print -- E2E diagnostics
          print(
            'E2E agents:command unary wallMs=${sw.elapsedMilliseconds}',
          );

          result.fold(
            (success) {
              expect(success.rows, isNotEmpty);
            },
            (failure) => fail(
              'socket agents:command sql.execute smoke failed: '
              '${_describeFailure(failure)}',
            ),
          );
        },
      );

      test(
        'agents:command legacy batch path (useRelay:false)',
        () async {
          if (_shouldSkipSocketSmoke(requireRelay: false)) {
            return;
          }

          final connected = await getIt<ConsumerSocketConnection>().connect();
          expect(connected.socketId, isNotEmpty);

          final repo = getIt<AgentQueriesRepository>();
          final batch = await runE2eAppResult(
            () => repo.executeSqlBatch(
              AgentSqlExecuteBatchRequest(
                agentId: AppEnvironment.e2eAgentId,
                clientToken: AppEnvironment.e2eClientToken,
                bridgeTimeoutMs: 60000,
                options: const AgentSqlExecuteBatchOptions(maxRows: 1),
                commands: const <AgentSqlExecuteBatchCommand>[
                  AgentSqlExecuteBatchCommand(
                    sql: 'SELECT CodCliente FROM Cliente ORDER BY CodCliente',
                  ),
                  AgentSqlExecuteBatchCommand(
                    sql: 'SELECT Nome FROM Cliente ORDER BY CodCliente',
                  ),
                ],
              ),
            ),
            actionLabel: 'socket_agents_command_smoke_sql_execute_batch',
          );

          batch.fold(
            (success) {
              expect(success.items.length, 2);
              expect(success.items.every((item) => item.ok), isTrue);
            },
            (failure) => fail(
              'socket agents:command sql.executeBatch smoke failed: '
              '${_describeFailure(failure)}',
            ),
          );
        },
      );

      test(
        'foreground reconnect recovers ConsumerSocketConnection',
        () async {
          if (_shouldSkipSocketSmoke(requireRelay: false)) {
            return;
          }

          final connection = getIt<ConsumerSocketConnection>();
          final first = await connection.connect();
          expect(first.socketId, isNotEmpty);

          await connection.disconnect(reason: 'e2e_reconnect_probe');
          final second = await connection.connect();
          expect(second.socketId, isNotEmpty);
          expect(connection.isConnected, isTrue);
        },
      );

      test(
        'relay long timeoutMs envelope is honoured for slow SQL',
        () async {
          if (_shouldSkipSocketSmoke(requireRelay: true)) {
            return;
          }

          final connected = await getIt<ConsumerSocketConnection>().connect();
          expect(connected.socketId, isNotEmpty);

          final repo = getIt<AgentQueriesRepository>();
          final result = await runE2eAppResult(
            () => repo.executeSql(
              AgentSqlExecuteRequest(
                agentId: AppEnvironment.e2eAgentId,
                clientToken: AppEnvironment.e2eClientToken,
                sql: 'SELECT CodCliente FROM Cliente ORDER BY CodCliente',
                // Hub default wait is 30s; this proves the client envelope
                // can raise the bridge wait without client-side premature fail.
                bridgeTimeoutMs: 120000,
                pagination: const AgentSqlPagePagination(page: 1, pageSize: 1),
                executeOptions: const AgentSqlExecuteOptions(
                  maxRows: 1,
                  preferDbStreaming: false,
                ),
                useRelay: true,
              ),
            ),
            actionLabel: 'socket_relay_smoke_long_timeout_ms',
          );

          result.fold(
            (success) {
              expect(success.rows, isNotEmpty);
            },
            (failure) => fail(
              'socket relay long timeoutMs smoke failed: '
              '${_describeFailure(failure)}',
            ),
          );
        },
      );

      test(
        'relay coordinator respects local gate (batch at/under maxInflight)',
        () async {
          if (_shouldSkipSocketSmoke(requireRelay: true)) {
            return;
          }
          if (!AppEnvironment.socketRelayBatchEnabled) {
            // ignore: avoid_print -- E2E skip hints
            print(
              'SKIP relay gate batch smoke: SOCKET_RELAY_BATCH_ENABLED=false',
            );
            return;
          }

          final connected = await getIt<ConsumerSocketConnection>().connect();
          expect(connected.socketId, isNotEmpty);

          final gate = AppEnvironment.socketMaxInflightPerAgent;
          final underGateCount = gate > 0 ? gate : 8;
          final repo = getIt<AgentQueriesRepository>();

          Future<void> runParallelUnaries(int count) async {
            final futures = List<Future<void>>.generate(count, (index) async {
              final result = await runE2eAppResult(
                () => repo.executeSql(
                  AgentSqlExecuteRequest(
                    agentId: AppEnvironment.e2eAgentId,
                    clientToken: AppEnvironment.e2eClientToken,
                    sql:
                        'SELECT $index AS n, CodCliente FROM Cliente '
                        'ORDER BY CodCliente',
                    bridgeTimeoutMs: 90000,
                    pagination: const AgentSqlPagePagination(
                      page: 1,
                      pageSize: 1,
                    ),
                    executeOptions: const AgentSqlExecuteOptions(
                      maxRows: 1,
                      preferDbStreaming: false,
                    ),
                    useRelay: true,
                  ),
                ),
                actionLabel: 'socket_relay_gate_batch_$index',
              );
              result.fold(
                (success) => expect(success.rows, isNotEmpty),
                (failure) => fail(
                  'relay gate parallel unary failed index=$index: '
                  '${_describeFailure(failure)}',
                ),
              );
            });
            await Future.wait(futures);
          }

          // At/under gate: coordinator may coalesce into one wire batch.
          await runParallelUnaries(underGateCount);
          // Above gate: must still complete (split/cap) without deadlock.
          await runParallelUnaries(underGateCount + 1);
        },
      );
    },
    tags: <String>['e2e'],
  );
}

List<String> _missingSocketSmokeSuiteKeys() =>
    _missingSocketSmokeKeys(requireRelay: false);

bool _shouldSkipSocketSmoke({required bool requireRelay}) {
  final missingKeys = _missingSocketSmokeKeys(requireRelay: requireRelay);
  if (missingKeys.isEmpty) {
    return false;
  }
  // ignore: avoid_print -- E2E skip hints
  print(
    'SKIP agent_queries_socket_channel_smoke_e2e: prerequisites not met: '
    '${missingKeys.join(', ')}. Set them in assets/env/local.env, '
    'process env, or --dart-define.',
  );
  return true;
}

List<String> _missingSocketSmokeKeys({bool requireRelay = true}) {
  final missing = missingE2eRepositoryKeys();
  if (AppEnvironment.agentBridgeTransport != AgentBridgeTransport.socket) {
    missing.add(
      'AGENT_BRIDGE_TRANSPORT=socket '
      '(current: ${AppEnvironment.agentBridgeTransport.wireValue})',
    );
  }
  if (requireRelay && AppEnvironment.e2eDisableRelayDispatch) {
    missing.add('E2E_DISABLE_RELAY_DISPATCH=false (current: true)');
  }
  return missing;
}

String _describeRelayOutcome(RelayRpcOutcome outcome) {
  final base =
      'agent=${outcome.agentId} conv=${outcome.conversationId} '
      'clientReq=${outcome.clientRequestId} req=${outcome.requestId} '
      'elapsedMs=${outcome.elapsed.inMilliseconds} method=${outcome.method}';
  return switch (outcome) {
    RelayRpcSuccess(
      :final deduplicated,
      :final replayed,
      :final inFlight,
    ) =>
      'SUCCESS $base dedup=$deduplicated replayed=$replayed inFlight=$inFlight',
    RelayRpcFailure(:final exception) =>
      'FAILURE $base code=${exception.code} msg=${exception.message}',
  };
}

String _describeFailure(AppFailure failure) {
  final details = <String, Object?>{
    'type': failure.runtimeType.toString(),
    'message': failure.message,
    'userMessage': failure.userMessage,
    'isTransient': failure.isTransient,
    'context': _redactContext(failure.context),
  };
  if (failure is RpcFailure) {
    details.addAll(<String, Object?>{
      'rpcCode': failure.rpcCode,
      'reason': failure.reason,
      'category': failure.category,
      'retryable': failure.retryable,
      'correlationId': failure.correlationId,
    });
  }
  return details.entries
      .where((entry) => entry.value != null)
      .map((entry) => '${entry.key}=${entry.value}')
      .join(', ');
}

Map<String, Object?> _redactContext(Map<String, Object?> context) {
  return context.map((key, value) {
    final normalized = key.toLowerCase();
    if (normalized.contains('token') ||
        normalized.contains('password') ||
        normalized.contains('authorization')) {
      return MapEntry(key, '<redacted>');
    }
    return MapEntry(key, value);
  });
}
