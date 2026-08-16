@Tags(['e2e'])
library;

import 'package:colmeia/core/config/app_environment.dart';
import 'package:colmeia/core/di/injector.dart';
import 'package:colmeia/core/errors/app_failure.dart'
    show AppFailure, RpcFailure, SessionFailure;
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
    'Agent SQL bridge (e2e)',
    () {
      registerE2eAgentQueriesSuiteHooks();

      test(
        'executeSql loads Municipio rows on the legacy bridge',
        () async {
          final missingKeys = missingE2eRepositoryKeys();
          if (missingKeys.isNotEmpty) {
            // Same gate as repository e2e: e2eSetupDependencies only attaches
            // Bearer after client-auth login when email/password are set.
            // E2E_AGENT_ID + E2E_CLIENT_TOKEN alone yield HTTP 401 on /agents/commands.
            // E2E skip hint; `print` is intentional for local diagnostics.
            // ignore: avoid_print
            print(
              'SKIP agent_sql_bridge_e2e: missing ${missingKeys.join(', ')}. '
              'Set them in assets/env/local.env, process env, or --dart-define.',
            );
            return;
          }

          expect(AppEnvironment.apiBaseUrl, isNotEmpty);

          final repo = getIt<AgentQueriesRepository>();
          final result = await runE2eAppResult(
            () => repo.executeSql(
              AgentSqlExecuteRequest(
                agentId: AppEnvironment.e2eAgentId,
                clientToken: AppEnvironment.e2eClientToken,
                sql:
                    'SELECT TOP 10 CodMunicipio, Nome FROM Municipio '
                    'ORDER BY CodMunicipio',
                bridgeTimeoutMs: 30000,
                executeOptions: const AgentSqlExecuteOptions(
                  maxRows: 10,
                ),
              ),
            ),
            actionLabel: 'agent_sql_bridge_execute',
          );

          result.fold(
            (success) {
              expect(success.rows, isNotEmpty);
              expect(success.rows.length, lessThanOrEqualTo(10));
            },
            (failure) => _expectBridgeE2eFailure(
              failure,
              context: 'agent_sql_bridge_execute',
            ),
          );
        },
      );

      test(
        'executeSql loads Cliente with body page pagination when hub allows',
        () async {
          final missingKeys = missingE2eRepositoryKeys();
          if (missingKeys.isNotEmpty) {
            // ignore: avoid_print -- E2E skip hints should appear in local diagnostics.
            print(
              'SKIP agent_sql_bridge_pagination_e2e: missing '
              '${missingKeys.join(', ')}.',
            );
            return;
          }

          final repo = getIt<AgentQueriesRepository>();
          final result = await runE2eAppResult(
            () => repo.executeSql(
              AgentSqlExecuteRequest(
                agentId: AppEnvironment.e2eAgentId,
                clientToken: AppEnvironment.e2eClientToken,
                sql:
                    'SELECT CodCliente, Nome FROM Cliente '
                    'ORDER BY CodCliente',
                bridgeTimeoutMs: 30000,
                pagination: const AgentSqlPagePagination(page: 1, pageSize: 10),
                executeOptions: const AgentSqlExecuteOptions(
                  maxRows: 10,
                  preferDbStreaming: true,
                ),
              ),
            ),
            actionLabel: 'agent_sql_bridge_pagination',
          );

          result.fold(
            (success) {
              expect(success.rows, isNotEmpty);
              expect(success.rows.length, lessThanOrEqualTo(10));
              final pagination = success.pagination;
              if (pagination != null) {
                expect(pagination.page, 1);
                expect(pagination.pageSize, 10);
                expect(pagination.returnedRows, success.rows.length);
              }
            },
            (failure) {
              if (_isHubBodyPaginationSchemaRejection(failure)) {
                return;
              }
              _expectBridgeE2eFailure(
                failure,
                context: 'agent_sql_bridge_pagination',
              );
            },
          );
        },
      );

      test(
        'executeSqlBatch runs multiple SQL commands in one bridge call',
        () async {
          final missingKeys = missingE2eRepositoryKeys();
          if (missingKeys.isNotEmpty) {
            // E2E skip hint; `print` is intentional for local diagnostics.
            // ignore: avoid_print
            print(
              'SKIP agent_sql_bridge_batch_e2e: missing ${missingKeys.join(', ')}. '
              'Set them in assets/env/local.env, process env, or --dart-define.',
            );
            return;
          }

          final repo = getIt<AgentQueriesRepository>();
          final result = await runE2eAppResult(
            () => repo.executeSqlBatch(
              AgentSqlExecuteBatchRequest(
                agentId: AppEnvironment.e2eAgentId,
                clientToken: AppEnvironment.e2eClientToken,
                options: const AgentSqlExecuteBatchOptions(maxRows: 1),
                commands: const <AgentSqlExecuteBatchCommand>[
                  AgentSqlExecuteBatchCommand(
                    sql: 'SELECT TOP 1 CodCliente FROM Cliente ORDER BY CodCliente',
                  ),
                  AgentSqlExecuteBatchCommand(
                    sql: 'SELECT TOP 1 Nome FROM Cliente ORDER BY CodCliente',
                  ),
                ],
              ),
            ),
          );

          result.fold(
            (success) {
              expect(success.items.length, 2);
              expect(success.items.every((item) => item.ok), isTrue);
              expect(success.items.first.rows, isNotEmpty);
              expect(success.items.last.rows, isNotEmpty);
            },
            (failure) => _expectBridgeE2eFailure(
              failure,
              context: 'agent_sql_bridge_execute_batch',
            ),
          );
        },
      );
    },
    tags: <String>['e2e'],
  );
}

/// Hub profile 2.10 may reject merged `options.page` / `page_size` for some
/// SQL shapes even when body `pagination` is valid — production uses
/// `startRow` / `endRow` instead ([AgentSqlPagePagination] is fake-backend
/// coverage + this opt-in probe).
bool _isHubBodyPaginationSchemaRejection(AppFailure failure) {
  if (failure is! RpcFailure) {
    return false;
  }
  if (failure.reason != 'invalid_params' || failure.rpcCode != -32602) {
    return false;
  }
  final technical = failure.technicalMessage?.toLowerCase() ?? '';
  return technical.contains('sql-execute.schema.json') &&
      technical.contains('page');
}

void _expectBridgeE2eFailure(
  AppFailure failure, {
  required String context,
}) {
  if (shouldLogE2eAcceptedFailureDiagnostic(failure)) {
    // ignore: avoid_print -- E2E failure diagnostics should appear in local output.
    print('$context failure: ${e2eAgentSqlFailureDiagnostic(failure)}');
  }
  expect(failure, isA<AppFailure>());
  if (AppEnvironment.hasE2eAgentBridgeCredentials) {
    expect(
      failure,
      isNot(isA<SessionFailure>()),
      reason: 'Unexpected HTTP 401 after client login for $context.',
    );
  }
  expect(
    isAcceptableE2eAgentSqlRepositoryFailure(failure),
    isTrue,
    reason:
        '$context should succeed or return an accepted E2E environmental '
        'failure. ${e2eAgentSqlFailureDiagnostic(failure)}',
  );
}
