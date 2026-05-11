@Tags(['e2e'])
library;

import 'package:colmeia/core/config/app_environment.dart';
import 'package:colmeia/core/di/injector.dart';
import 'package:colmeia/core/errors/app_failure.dart'
    show AppFailure, SessionFailure;
import 'package:colmeia/features/agent_queries/application/orchestration/agent_query_plan_builder.dart';
import 'package:colmeia/features/agent_queries/data/orchestration/agent_query_target_resolver.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_execution_strategy.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_batch_execution_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_batch_request.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_request.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execution_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_dia_semana_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_mensal_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_total_diario_vendas_filter.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/agent_queries_repository.dart';
import 'package:colmeia/features/overview/data/overview_batch_loader.dart';
import 'package:colmeia/features/overview/domain/entities/overview_filter.dart';
import 'package:flutter_test/flutter_test.dart' hide group;
import 'package:result_dart/result_dart.dart';
import 'package:test_api/scaffolding.dart' show group;

import 'support/e2e_dependency_bootstrap.dart';

void main() {
  group(
    'OverviewBatchLoader (e2e)',
    () {
      test(
        'runs the overview home command set through sql.executeBatch',
        () async {
          final missingKeys = missingE2eRepositoryKeys();
          if (missingKeys.isNotEmpty) {
            // E2E skip hint; `print` is intentional for local diagnostics.
            // ignore: avoid_print
            print(
              'SKIP overview_batch_loader_e2e: missing '
              '${missingKeys.join(', ')}. '
              'Set them in assets/env/local.env, process env, or --dart-define.',
            );
            return;
          }

          await e2eSetupDependencies();
          addTearDown(e2eTeardownDependencies);

          final countingRepository = _CountingAgentQueriesRepository(
            getIt<AgentQueriesRepository>(),
          );
          final loader = OverviewBatchLoader(
            targetResolver: getIt<AgentQueryTargetResolver>(),
            planBuilder: getIt<AgentQueryPlanBuilder>(),
            agentQueriesRepository: countingRepository,
          );
          final today = DateTime.now();
          final periodEnd = DateTime(today.year, today.month, today.day);
          final periodStart = periodEnd.subtract(const Duration(days: 14));
          final last12Start = DateTime(periodEnd.year - 1, periodEnd.month + 1);

          final result = await runE2eAppResultWithHubRetry(
            () => loader.load(
              userId: 'user-1',
              filter: OverviewFilter(
                selectedAgentIds: <String>{AppEnvironment.e2eAgentId},
              ),
              periodStart: periodStart,
              periodEnd: periodEnd,
              last12Range: (
                dataVendaInicio: last12Start,
                dataVendaFim: periodEnd,
              ),
              mensalFilter: ResumoParcelasMensalFilter(
                dataVendaInicio: last12Start,
                dataVendaFim: periodEnd,
              ),
              weekdayFilter: ResumoParcelasDiaSemanaFilter(
                dataVendaInicio: periodStart,
                dataVendaFim: periodEnd,
              ),
              dailyTotalFilter: ResumoTotalDiarioVendasFilter(
                dataVendaInicio: periodStart,
                dataVendaFim: periodEnd,
              ),
              executionStrategy: AgentQueryExecutionStrategy.singleSource,
            ),
            actionLabel: 'overview_batch_loader',
          );

          result.fold(
            (success) {
              expect(countingRepository.batchCallCount, 1);
              expect(
                countingRepository.lastBatchRequest?.commands.length,
                7,
              );
              expect(
                countingRepository.lastBatchRequest?.useRelay,
                isTrue,
              );
              expect(success.targetResults.length, 1);
              expect(success.plan.plannedTargets.length, 1);
              expect(success.mainResumoReport.participants.length, 1);
              final target = success.targetResults.single;
              expect(target.target.agentId, AppEnvironment.e2eAgentId);
              for (final row in target.mainRows) {
                expect(row.codEmpresa, greaterThan(0));
                expect(row.codFilial, greaterThan(0));
                expect(row.qtdVendas, greaterThanOrEqualTo(0));
                expect(row.valorParcela, isNonNegative);
              }
            },
            (failure) {
              // E2E diagnostic only; stdout is intentional for local/CI triage.
              // ignore: avoid_print
              print(
                'overview_batch_loader_e2e failure: '
                '${e2eAgentSqlFailureDiagnostic(failure)}',
              );
              expect(failure, isA<AppFailure>());
              if (AppEnvironment.hasE2eAgentBridgeCredentials) {
                expect(
                  failure,
                  isNot(isA<SessionFailure>()),
                  reason:
                      'Unexpected HTTP 401 after client login for overview '
                      'batch loader.',
                );
              }
              expect(
                isAcceptableE2eAgentSqlRepositoryFailure(failure),
                isTrue,
                reason:
                    'Overview batch e2e should return rows/empty sections, '
                    'invalid_policy / missing_permission RPC, transient '
                    'transport, queue saturation, or transient bridge HTTP 5xx. '
                    '${e2eAgentSqlFailureDiagnostic(failure)}',
              );
            },
          );
        },
      );
    },
    tags: <String>['e2e'],
  );
}

final class _CountingAgentQueriesRepository implements AgentQueriesRepository {
  _CountingAgentQueriesRepository(this._delegate);

  final AgentQueriesRepository _delegate;
  int batchCallCount = 0;
  AgentSqlExecuteBatchRequest? lastBatchRequest;

  @override
  Future<ResultDart<AgentSqlExecutionResult, AppFailure>> executeSql(
    AgentSqlExecuteRequest request,
  ) {
    return _delegate.executeSql(request);
  }

  @override
  Future<ResultDart<AgentSqlBatchExecutionResult, AppFailure>> executeSqlBatch(
    AgentSqlExecuteBatchRequest request,
  ) {
    batchCallCount++;
    lastBatchRequest = request;
    return _delegate.executeSqlBatch(request);
  }
}
