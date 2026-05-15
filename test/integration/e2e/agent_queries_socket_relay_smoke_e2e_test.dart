@Tags(['e2e'])
library;

import 'package:colmeia/core/config/agent_bridge_transport.dart';
import 'package:colmeia/core/config/app_environment.dart';
import 'package:colmeia/core/di/injector.dart';
import 'package:colmeia/core/errors/app_failure.dart'
    show AppFailure, SessionFailure;
import 'package:colmeia/core/socket/consumer_socket_connection.dart';
import 'package:colmeia/core/socket/relay/relay_command_dispatcher.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_batch_request.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_request.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/agent_queries_repository.dart';
import 'package:flutter_test/flutter_test.dart' hide group;
import 'package:test_api/scaffolding.dart' show group;

import 'support/e2e_dependency_bootstrap.dart';

void main() {
  group(
    'Agent queries socket relay smoke (e2e)',
    () {
      registerE2eAgentQueriesSuiteHooks(
        missingKeys: _missingSocketRelaySmokeKeys,
      );

      test('connects /consumers and executes SQL through relay', () async {
        if (_shouldSkipSocketRelaySmoke()) {
          return;
        }

        expect(getIt.isRegistered<ConsumerSocketConnection>(), isTrue);
        expect(getIt.isRegistered<RelayCommandDispatcher>(), isTrue);

        final connected = await getIt<ConsumerSocketConnection>().connect();
        expect(connected.socketId, isNotEmpty);

        final repo = getIt<AgentQueriesRepository>();
        final single = await runE2eAppResult(
          () => repo.executeSql(
            AgentSqlExecuteRequest(
              agentId: AppEnvironment.e2eAgentId,
              clientToken: AppEnvironment.e2eClientToken,
              sql: 'SELECT TOP 1 CodCliente FROM Cliente ORDER BY CodCliente',
              bridgeTimeoutMs: 30000,
              useRelay: true,
            ),
          ),
          actionLabel: 'socket_relay_smoke_sql_execute',
        );

        single.fold(
          (success) {
            expect(success.rows, isNotEmpty);
          },
          (failure) => _expectAcceptableSocketRelayFailure(
            failure,
            scope: 'socket relay sql.execute smoke',
          ),
        );

        final batch = await runE2eAppResult(
          () => repo.executeSqlBatch(
            AgentSqlExecuteBatchRequest(
              agentId: AppEnvironment.e2eAgentId,
              clientToken: AppEnvironment.e2eClientToken,
              bridgeTimeoutMs: 30000,
              useRelay: true,
              commands: const <AgentSqlExecuteBatchCommand>[
                AgentSqlExecuteBatchCommand(
                  sql:
                      'SELECT TOP 1 CodCliente FROM Cliente ORDER BY CodCliente',
                ),
                AgentSqlExecuteBatchCommand(
                  sql: 'SELECT TOP 1 Nome FROM Cliente ORDER BY CodCliente',
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
          (failure) => _expectAcceptableSocketRelayFailure(
            failure,
            scope: 'socket relay sql.executeBatch smoke',
          ),
        );
      });
    },
    tags: <String>['e2e'],
  );
}

bool _shouldSkipSocketRelaySmoke() {
  final missingKeys = _missingSocketRelaySmokeKeys();
  if (missingKeys.isNotEmpty) {
    // E2E skip hint; `print` is intentional for local diagnostics.
    // ignore: avoid_print -- E2E skip hints should appear in local diagnostics.
    print(
      'SKIP agent_queries_socket_relay_smoke_e2e: prerequisites not met: '
      '${missingKeys.join(', ')}. Set them in assets/env/local.env, '
      'process env, or --dart-define.',
    );
    return true;
  }

  return false;
}

List<String> _missingSocketRelaySmokeKeys() {
  final missing = missingE2eRepositoryKeys();
  if (AppEnvironment.agentBridgeTransport != AgentBridgeTransport.socket) {
    missing.add(
      'AGENT_BRIDGE_TRANSPORT=socket '
      '(current: ${AppEnvironment.agentBridgeTransport.name})',
    );
  }
  if (AppEnvironment.e2eDisableRelayDispatch) {
    missing.add('E2E_DISABLE_RELAY_DISPATCH=false (current: true)');
  }
  return missing;
}

void _expectAcceptableSocketRelayFailure(
  AppFailure failure, {
  required String scope,
}) {
  expect(
    failure,
    isNot(isA<SessionFailure>()),
    reason: 'Unexpected HTTP 401 after client login in $scope.',
  );
  expect(
    isAcceptableE2eAgentSqlRepositoryFailure(failure),
    isTrue,
    reason:
        '$scope should return rows or an accepted policy/permission/transient '
        'hub failure.',
  );
}
