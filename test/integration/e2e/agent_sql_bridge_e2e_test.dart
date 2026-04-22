import 'package:colmeia/core/config/app_environment.dart';
import 'package:colmeia/core/di/injector.dart';
import 'package:colmeia/core/errors/app_failure.dart'
    show AppFailure, SessionFailure;
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_bridge_pagination.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_request.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/agent_queries_repository.dart';
import 'package:flutter_test/flutter_test.dart' hide group;
import 'package:test_api/scaffolding.dart' show group;

import 'support/e2e_dependency_bootstrap.dart';

void main() {
  group(
    'Agent SQL bridge (e2e)',
    () {
      test(
        'executeSql loads Cliente with page pagination',
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

          await e2eSetupDependencies();
          addTearDown(e2eTeardownDependencies);
          expect(AppEnvironment.apiBaseUrl, isNotEmpty);

          final repo = getIt<AgentQueriesRepository>();
          final result = await repo.executeSql(
            AgentSqlExecuteRequest(
              agentId: AppEnvironment.e2eAgentId,
              clientToken: AppEnvironment.e2eClientToken,
              sql: 'SELECT * FROM Cliente ORDER BY CodCliente',
              pagination: const AgentSqlPagePagination(page: 1, pageSize: 10),
            ),
          );

          result.fold(
            (success) {
              expect(success.rows, isNotEmpty);
              expect(success.rows.length, lessThanOrEqualTo(10));
              expect(success.pagination, isNotNull);
              expect(success.pagination?.page, 1);
              expect(success.pagination?.pageSize, 10);
              expect(success.pagination?.returnedRows, success.rows.length);
            },
            (failure) {
              expect(
                failure,
                isA<AppFailure>(),
              );
              if (AppEnvironment.hasE2eAgentBridgeCredentials) {
                expect(
                  failure,
                  isNot(isA<SessionFailure>()),
                  reason:
                      'Unexpected HTTP 401 after client login '
                      '— check E2E_* values '
                      'and hub access.',
                );
              }
              if (isAcceptableE2eAgentSqlRepositoryFailure(failure)) {
                return;
              }
              fail(
                'Bridge e2e failed with ${failure.runtimeType}: '
                '${failure.displayMessage}',
              );
            },
          );
        },
      );
    },
    tags: <String>['e2e'],
  );
}
