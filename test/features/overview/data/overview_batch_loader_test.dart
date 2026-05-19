import 'package:checks/checks.dart';
import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/features/agent_queries/application/orchestration/agent_query_plan_builder.dart';
import 'package:colmeia/features/agent_queries/data/agent_queries_bounded_result_max_rows.dart';
import 'package:colmeia/features/agent_queries/data/agent_sql_execute_batch_request_to_bridge_body.dart';
import 'package:colmeia/features/agent_queries/data/orchestration/agent_query_target_resolver.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_execution_strategy.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_target.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_target_resolution.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_batch_execution_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_batch_request.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_dia_semana_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_mensal_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_total_diario_vendas_filter.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/agent_queries_repository.dart';
import 'package:colmeia/features/client_agents/domain/entities/agent_connection_status.dart';
import 'package:colmeia/features/overview/data/overview_batch_loader.dart';
import 'package:colmeia/features/overview/domain/entities/overview_filter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:result_dart/result_dart.dart';

class _MockAgentQueryTargetResolver extends Mock
    implements AgentQueryTargetResolver {}

class _MockAgentQueriesRepository extends Mock
    implements AgentQueriesRepository {}

void main() {
  late _MockAgentQueryTargetResolver targetResolver;
  late _MockAgentQueriesRepository agentQueriesRepository;
  late OverviewBatchLoader loader;

  setUpAll(() {
    registerFallbackValue(<String>{'agent-fallback'});
    registerFallbackValue(
      const AgentSqlExecuteBatchRequest(
        agentId: 'agent-fallback',
        commands: <AgentSqlExecuteBatchCommand>[
          AgentSqlExecuteBatchCommand(sql: 'SELECT 1'),
        ],
      ),
    );
  });

  setUp(() {
    targetResolver = _MockAgentQueryTargetResolver();
    agentQueriesRepository = _MockAgentQueriesRepository();
    loader = OverviewBatchLoader(
      targetResolver: targetResolver,
      planBuilder: const AgentQueryPlanBuilder(),
      agentQueriesRepository: agentQueriesRepository,
    );
  });

  group('OverviewBatchLoader', () {
    test(
      'sends phased batches per selected target and maps item rows',
      () async {
        final target = _agentTarget('agent-1', token: 'token-1');
        _stubResolution(
          targetResolver,
          AgentQueryTargetResolution(
            consideredApprovedTargets: <AgentQueryTarget>[target],
            missingClientTokenTargets: const <AgentQueryTarget>[],
            consideredApprovedAgentCount: 1,
            selectedAgentIds: const <String>{'agent-1'},
            hubPresenceOnlineAgentIdsSnapshot: const <String>{'agent-1'},
          ),
        );
        when(
          () => agentQueriesRepository.executeSqlBatch(any()),
        ).thenAnswer((invocation) async {
          final request =
              invocation.positionalArguments.single
                  as AgentSqlExecuteBatchRequest;
          if (request.commands.length == 2) {
            return Success<AgentSqlBatchExecutionResult, AppFailure>(
              _batchResult(
                commandCount: 2,
                rowsByIndex: <int, List<Map<String, dynamic>>>{
                  0: <Map<String, dynamic>>[_mainRow()],
                  1: <Map<String, dynamic>>[_porUsuarioRow()],
                },
              ),
            );
          }
          return Success<AgentSqlBatchExecutionResult, AppFailure>(
            _batchResult(
              commandCount: 6,
              rowsByIndex: <int, List<Map<String, dynamic>>>{
                0: <Map<String, dynamic>>[_monthlyRow()],
                1: <Map<String, dynamic>>[_weekdayRow()],
                2: <Map<String, dynamic>>[_dailyRow()],
                3: <Map<String, dynamic>>[_weekdayUserRow()],
                4: <Map<String, dynamic>>[_lucratividadeRow()],
                5: <Map<String, dynamic>>[_lucratividadeMensalRow()],
              },
            ),
          );
        });

        final result = await _loadSingleAgent(loader);

        check(result.isSuccess()).isTrue();
        final batch = result.getOrThrow();
        check(batch.targetResults.length).equals(1);
        final targetResult = batch.targetResults.single;
        check(targetResult.mainRows.single.valorParcela).equals(100);
        check(targetResult.userRankingRows.single.valorParcela).equals(100);
        check(targetResult.monthlyRows.single.anoMes).equals('2026/04');
        check(targetResult.weekdayRows.single.diaSemanaNumero).equals(2);
        check(targetResult.dailyRows.single.valorTotalDiarioVenda).equals(88);
        check(targetResult.weekdayUserRows.single.nomeUsuario).equals('Caixa');
        check(targetResult.lucratividadeRows.single.valorTotalItem).equals(140);
        check(targetResult.lucratividadeMensalRows.single.anoMes).equals(
          '2026/04',
        );
        check(batch.mainResumoReport.participants.single.rows.length).equals(1);

        verify(
          () => targetResolver.resolve(
            userId: 'user-1',
            selectedAgentIds: const <String>{'agent-1'},
          ),
        ).called(1);
        final requests = verify(
          () => agentQueriesRepository.executeSqlBatch(captureAny()),
        ).captured.cast<AgentSqlExecuteBatchRequest>().toList(growable: false);
        check(requests.length).equals(2);
        final mainRequest = requests[0];
        final sectionRequest = requests[1];
        check(mainRequest.agentId).equals('agent-1');
        check(mainRequest.clientToken).equals('token-1');
        check(mainRequest.requestingUserId).equals('user-1');
        check(mainRequest.useRelay).isTrue();
        check(sectionRequest.useRelay).isTrue();
        check(mainRequest.bridgeTimeoutMs).equals(
          OverviewBatchLoader.overviewBatchBridgeTimeoutMs,
        );
        check(mainRequest.options?.sqlTimeoutMs).equals(
          OverviewBatchLoader.overviewBatchSqlTimeoutMs,
        );
        check(mainRequest.options?.maxRows).equals(
          AgentQueriesBoundedResultMaxRows.resumoParcelasMensal,
        );
        check(mainRequest.options?.transaction).equals(false);
        check(mainRequest.options?.maxParallelReadOnlyBatchItems).equals(4);
        check(sectionRequest.options?.maxParallelReadOnlyBatchItems).equals(4);
        check(
          mainRequest.commands.map((command) => command.executionOrder),
        ).deepEquals(
          <int>[0, 1],
        );
        check(
          sectionRequest.commands.map((command) => command.executionOrder),
        ).deepEquals(
          <int>[0, 1, 2, 3, 4, 5],
        );

        final body = const AgentSqlExecuteBatchRequestToBridgeBody().build(
          request: sectionRequest,
          rpcId: 'rpc-1',
        );
        final command = body['command']! as Map<String, Object?>;
        check(command['method']).equals('sql.executeBatch');
        final params = command['params']! as Map<String, Object?>;
        final options = params['options']! as Map<String, Object?>;
        check(options['max_parallel_read_only_batch_items']).equals(4);
        final commands = params['commands']! as List<Object?>;
        check(commands.length).equals(6);
        for (final rawCommand in commands) {
          final batchCommand = rawCommand! as Map<String, Object?>;
          final sql = batchCommand['sql']! as String;
          expect(sql, isNot(contains('\n')));
          expect(sql, isNot(contains('\r')));
        }
      },
    );

    test(
      'keeps secondary item failure local to the matching target section',
      () async {
        final target = _agentTarget('agent-1', token: 'token-1');
        _stubResolution(
          targetResolver,
          AgentQueryTargetResolution(
            consideredApprovedTargets: <AgentQueryTarget>[target],
            missingClientTokenTargets: const <AgentQueryTarget>[],
            consideredApprovedAgentCount: 1,
            selectedAgentIds: const <String>{'agent-1'},
          ),
        );
        when(
          () => agentQueriesRepository.executeSqlBatch(any()),
        ).thenAnswer((invocation) async {
          final request =
              invocation.positionalArguments.single
                  as AgentSqlExecuteBatchRequest;
          if (request.commands.length == 2) {
            return Success<AgentSqlBatchExecutionResult, AppFailure>(
              _batchResult(
                commandCount: 2,
                rowsByIndex: <int, List<Map<String, dynamic>>>{
                  0: <Map<String, dynamic>>[_mainRow()],
                  1: <Map<String, dynamic>>[_porUsuarioRow()],
                },
              ),
            );
          }
          return Success<AgentSqlBatchExecutionResult, AppFailure>(
            _batchResult(commandCount: 6, failedIndexes: const <int>{0}),
          );
        });

        final result = await _loadSingleAgent(loader);

        check(result.isSuccess()).isTrue();
        final targetResult = result.getOrThrow().targetResults.single;
        check(targetResult.mainFailure).isNull();
        check(targetResult.monthlyFailure).isA<RpcFailure>();
        check(targetResult.weekdayFailure).isNull();
        check(targetResult.dailyFailure).isNull();
        check(targetResult.lucratividadeMensalFailure).isNull();
      },
    );

    test('allows tuning read-only batch parallelism', () async {
      final tunedLoader = OverviewBatchLoader(
        targetResolver: targetResolver,
        planBuilder: const AgentQueryPlanBuilder(),
        agentQueriesRepository: agentQueriesRepository,
        maxParallelReadOnlyBatchItems: 6,
      );
      final target = _agentTarget('agent-1', token: 'token-1');
      _stubResolution(
        targetResolver,
        AgentQueryTargetResolution(
          consideredApprovedTargets: <AgentQueryTarget>[target],
          missingClientTokenTargets: const <AgentQueryTarget>[],
          consideredApprovedAgentCount: 1,
          selectedAgentIds: const <String>{'agent-1'},
          hubPresenceOnlineAgentIdsSnapshot: const <String>{'agent-1'},
        ),
      );
      when(
        () => agentQueriesRepository.executeSqlBatch(any()),
      ).thenAnswer((invocation) async {
        final request =
            invocation.positionalArguments.single
                as AgentSqlExecuteBatchRequest;
        return Success<AgentSqlBatchExecutionResult, AppFailure>(
          _batchResult(commandCount: request.commands.length),
        );
      });

      final result = await _loadSingleAgent(tunedLoader);

      check(result.isSuccess()).isTrue();
      final requests = verify(
        () => agentQueriesRepository.executeSqlBatch(captureAny()),
      ).captured.cast<AgentSqlExecuteBatchRequest>().toList(growable: false);
      check(requests.length).equals(2);
      for (final request in requests) {
        check(request.options?.maxParallelReadOnlyBatchItems).equals(6);
      }
    });

    test(
      'keeps successful agent data when another target main batch fails',
      () async {
        final targets = <AgentQueryTarget>[
          _agentTarget('agent-1', token: 'token-1'),
          _agentTarget('agent-2', token: 'token-2'),
        ];
        _stubResolution(
          targetResolver,
          AgentQueryTargetResolution(
            consideredApprovedTargets: targets,
            missingClientTokenTargets: const <AgentQueryTarget>[],
            consideredApprovedAgentCount: 2,
            selectedAgentIds: const <String>{'agent-1', 'agent-2'},
          ),
        );
        when(
          () => agentQueriesRepository.executeSqlBatch(any()),
        ).thenAnswer((invocation) async {
          final request =
              invocation.positionalArguments.single
                  as AgentSqlExecuteBatchRequest;
          if (request.agentId == 'agent-1') {
            return const Failure<AgentSqlBatchExecutionResult, AppFailure>(
              NetworkFailure(
                message: 'batch transport failed',
                userMessage: 'Falha de comunicacao.',
              ),
            );
          }
          return Success<AgentSqlBatchExecutionResult, AppFailure>(
            _batchResult(
              commandCount: request.commands.length,
              rowsByIndex: request.commands.length == 2
                  ? <int, List<Map<String, dynamic>>>{
                      0: <Map<String, dynamic>>[_mainRow()],
                      1: <Map<String, dynamic>>[_porUsuarioRow()],
                    }
                  : const <int, List<Map<String, dynamic>>>{},
            ),
          );
        });

        final result = await loader.load(
          userId: 'user-1',
          filter: const OverviewFilter(
            selectedAgentIds: <String>{'agent-1', 'agent-2'},
          ),
          periodStart: DateTime(2026, 4),
          periodEnd: DateTime(2026, 4, 30),
          last12Range: (
            dataVendaInicio: DateTime(2025, 5),
            dataVendaFim: DateTime(2026, 4, 30),
          ),
          mensalFilter: _mensalFilter(),
          weekdayFilter: _weekdayFilter(),
          dailyTotalFilter: _dailyFilter(),
          executionStrategy: AgentQueryExecutionStrategy.mergeAll,
        );

        check(result.isSuccess()).isTrue();
        final targetResults = result.getOrThrow().targetResults;
        check(targetResults.length).equals(2);
        final failed = targetResults.singleWhere(
          (target) => target.target.agentId == 'agent-1',
        );
        final successful = targetResults.singleWhere(
          (target) => target.target.agentId == 'agent-2',
        );
        check(failed.mainFailure).isA<NetworkFailure>();
        check(failed.monthlyFailure).isNull();
        check(failed.weekdayFailure).isNull();
        check(successful.mainFailure).isNull();
        check(successful.mainRows.single.valorParcela).equals(100);
        final report = result.getOrThrow().mainResumoReport;
        check(report.participants.length).equals(2);
        check(
          report.participants
              .singleWhere((participant) => participant.agentId == 'agent-1')
              .failure,
        ).isA<NetworkFailure>();
        check(
          report.participants
              .singleWhere((participant) => participant.agentId == 'agent-2')
              .rows
              .length,
        ).equals(1);
        final captured = verify(
          () => agentQueriesRepository.executeSqlBatch(captureAny()),
        ).captured.cast<AgentSqlExecuteBatchRequest>().toList(growable: false);
        check(captured.map((request) => request.agentId)).deepEquals(
          <String>['agent-1', 'agent-2', 'agent-2'],
        );
      },
    );

    test(
      'omits monthly lucratividade when multiple agents are selected',
      () async {
        final targets = <AgentQueryTarget>[
          _agentTarget('agent-1', token: 'token-1'),
          _agentTarget('agent-2', token: 'token-2'),
        ];
        _stubResolution(
          targetResolver,
          AgentQueryTargetResolution(
            consideredApprovedTargets: targets,
            missingClientTokenTargets: const <AgentQueryTarget>[],
            consideredApprovedAgentCount: 2,
            selectedAgentIds: const <String>{'agent-1', 'agent-2'},
          ),
        );
        when(
          () => agentQueriesRepository.executeSqlBatch(any()),
        ).thenAnswer((invocation) async {
          final request =
              invocation.positionalArguments.single
                  as AgentSqlExecuteBatchRequest;
          return Success<AgentSqlBatchExecutionResult, AppFailure>(
            _batchResult(commandCount: request.commands.length),
          );
        });

        final result = await loader.load(
          userId: 'user-1',
          filter: const OverviewFilter(
            selectedAgentIds: <String>{'agent-1', 'agent-2'},
          ),
          periodStart: DateTime(2026, 4),
          periodEnd: DateTime(2026, 4, 30),
          last12Range: (
            dataVendaInicio: DateTime(2025, 5),
            dataVendaFim: DateTime(2026, 4, 30),
          ),
          mensalFilter: _mensalFilter(),
          weekdayFilter: _weekdayFilter(),
          dailyTotalFilter: _dailyFilter(),
          executionStrategy: AgentQueryExecutionStrategy.mergeAll,
        );

        check(result.isSuccess()).isTrue();
        final captured = verify(
          () => agentQueriesRepository.executeSqlBatch(captureAny()),
        ).captured;
        check(captured.length).equals(4);
        final requests = captured.cast<AgentSqlExecuteBatchRequest>().toList(
          growable: false,
        );
        for (final request in requests.take(2)) {
          check(request.commands.length).equals(2);
        }
        for (final request in requests.skip(2)) {
          check(request.commands.length).equals(5);
        }
        check(
          result.getOrThrow().targetResults.every(
            (target) => target.lucratividadeMensalFailure == null,
          ),
        ).isTrue();
      },
    );

    test(
      'dispatches executeSqlBatch calls for every agent target in parallel',
      () async {
        final targets = List<AgentQueryTarget>.generate(
          6,
          (i) => _agentTarget('agent-${i + 1}', token: 'token-${i + 1}'),
        );
        _stubResolution(
          targetResolver,
          AgentQueryTargetResolution(
            consideredApprovedTargets: targets,
            missingClientTokenTargets: const <AgentQueryTarget>[],
            consideredApprovedAgentCount: 6,
            selectedAgentIds: <String>{
              for (var i = 0; i < 6; i++) 'agent-${i + 1}',
            },
          ),
        );
        var active = 0;
        var maxActive = 0;
        when(
          () => agentQueriesRepository.executeSqlBatch(any()),
        ).thenAnswer((invocation) async {
          final request =
              invocation.positionalArguments.single
                  as AgentSqlExecuteBatchRequest;
          active++;
          if (active > maxActive) {
            maxActive = active;
          }
          await Future<void>.delayed(const Duration(milliseconds: 40));
          active--;
          return Success<AgentSqlBatchExecutionResult, AppFailure>(
            _batchResult(commandCount: request.commands.length),
          );
        });

        await loader.load(
          userId: 'user-1',
          filter: OverviewFilter(
            selectedAgentIds: <String>{
              for (var i = 0; i < 6; i++) 'agent-${i + 1}',
            },
          ),
          periodStart: DateTime(2026, 4),
          periodEnd: DateTime(2026, 4, 30),
          last12Range: (
            dataVendaInicio: DateTime(2025, 5),
            dataVendaFim: DateTime(2026, 4, 30),
          ),
          mensalFilter: _mensalFilter(),
          weekdayFilter: _weekdayFilter(),
          dailyTotalFilter: _dailyFilter(),
          executionStrategy: AgentQueryExecutionStrategy.mergeAll,
        );

        check(maxActive).equals(targets.length);
      },
    );

    test('returns resolver failure without executing batch', () async {
      when(
        () => targetResolver.resolve(
          userId: any(named: 'userId'),
          selectedAgentIds: any(named: 'selectedAgentIds'),
        ),
      ).thenAnswer(
        (_) async => const Failure<AgentQueryTargetResolution, AppFailure>(
          ValidationFailure(
            message: 'resolver failed',
            context: <String, Object?>{
              'operation': 'resolveAgentQueryTargets',
            },
          ),
        ),
      );

      final result = await _loadSingleAgent(loader);

      check(result.isError()).isTrue();
      verifyNever(() => agentQueriesRepository.executeSqlBatch(any()));
    });
  });
}

Future<ResultDart<OverviewBatchLoadResult, AppFailure>> _loadSingleAgent(
  OverviewBatchLoader loader,
) {
  return loader.load(
    userId: 'user-1',
    filter: const OverviewFilter(selectedAgentIds: <String>{'agent-1'}),
    periodStart: DateTime(2026, 4),
    periodEnd: DateTime(2026, 4, 30),
    last12Range: (
      dataVendaInicio: DateTime(2025, 5),
      dataVendaFim: DateTime(2026, 4, 30),
    ),
    mensalFilter: _mensalFilter(),
    weekdayFilter: _weekdayFilter(),
    dailyTotalFilter: _dailyFilter(),
    executionStrategy: AgentQueryExecutionStrategy.singleSource,
  );
}

void _stubResolution(
  _MockAgentQueryTargetResolver resolver,
  AgentQueryTargetResolution resolution,
) {
  when(
    () => resolver.resolve(
      userId: any(named: 'userId'),
      selectedAgentIds: any(named: 'selectedAgentIds'),
    ),
  ).thenAnswer(
    (_) async => Success<AgentQueryTargetResolution, AppFailure>(resolution),
  );
}

ResumoParcelasMensalFilter _mensalFilter() {
  return ResumoParcelasMensalFilter(
    dataVendaInicio: DateTime(2025, 5),
    dataVendaFim: DateTime(2026, 4, 30),
  );
}

ResumoParcelasDiaSemanaFilter _weekdayFilter() {
  return ResumoParcelasDiaSemanaFilter(
    dataVendaInicio: DateTime(2026, 4),
    dataVendaFim: DateTime(2026, 4, 30),
  );
}

ResumoTotalDiarioVendasFilter _dailyFilter() {
  return ResumoTotalDiarioVendasFilter(
    dataVendaInicio: DateTime(2026, 4),
    dataVendaFim: DateTime(2026, 4, 30),
  );
}

AgentSqlBatchExecutionResult _batchResult({
  required int commandCount,
  Map<int, List<Map<String, dynamic>>> rowsByIndex =
      const <int, List<Map<String, dynamic>>>{},
  Set<int> failedIndexes = const <int>{},
}) {
  return AgentSqlBatchExecutionResult(
    totalCommands: commandCount,
    successfulCommands: commandCount - failedIndexes.length,
    failedCommands: failedIndexes.length,
    items: List<AgentSqlBatchExecutionItem>.generate(
      commandCount,
      (index) => AgentSqlBatchExecutionItem(
        index: index,
        ok: !failedIndexes.contains(index),
        rows: rowsByIndex[index] ?? const <Map<String, dynamic>>[],
        rowCount: rowsByIndex[index]?.length ?? 0,
        error: failedIndexes.contains(index) ? 'item failed' : null,
      ),
    ),
  );
}

Map<String, dynamic> _porUsuarioRow() {
  return <String, dynamic>{
    'CodEmpresa': 1,
    'CodFilial': 1,
    'NomeUsuario': 'Caixa',
    'QtdVendas': 1,
    'ValorParcela': 100.0,
  };
}

Map<String, dynamic> _mainRow() {
  return <String, dynamic>{
    'CodEmpresa': 1,
    'CodFilial': 1,
    'NomeUsuario': 'Caixa',
    'AnoDataVenda': 2026,
    'MesDataVenda': 4,
    'AnoMesDataVenda': '2026/04',
    'CodFormaPagamento': 'PIX',
    'DescricaoFormaPagamento': 'Pix',
    'QtdVendas': 2,
    'ValorParcela': 100.0,
  };
}

Map<String, dynamic> _monthlyRow() {
  return <String, dynamic>{
    'CodEmpresa': 1,
    'CodFilial': 1,
    'Ano': 2026,
    'Mes': 4,
    'AnoMes': '2026/04',
    'QtdVendas': 3,
    'ValorParcela': 120.0,
  };
}

Map<String, dynamic> _weekdayRow() {
  return <String, dynamic>{
    'CodEmpresa': 1,
    'CodFilial': 1,
    'DiaSemanaNumero': 2,
    'DiaSemana': 'Segunda',
    'QtdVendas': 4,
    'ValorParcela': 130.0,
  };
}

Map<String, dynamic> _dailyRow() {
  return <String, dynamic>{
    'CodEmpresa': 1,
    'CodFilial': 1,
    'DataVenda': '2026-04-08',
    'QtdVendas': 5,
    'ValorTotalDiarioVenda': 88.0,
  };
}

Map<String, dynamic> _weekdayUserRow() {
  return <String, dynamic>{
    'CodEmpresa': 1,
    'CodFilial': 1,
    'NomeUsuario': 'Caixa',
    'DiaSemanaNumero': 2,
    'DiaSemana': 'Segunda',
    'QtdVendas': 6,
    'ValorParcela': 150.0,
  };
}

Map<String, dynamic> _lucratividadeRow() {
  return <String, dynamic>{
    'CodEmpresa': 1,
    'CodFilial': 1,
    'QtdVendas': 7,
    'QtdItensVendido': 8.0,
    'ValorTotalCustoMedio': 90.0,
    'CustoReposicao': 95.0,
    'PontoEquilibrio': 100.0,
    'ValorTotalItem': 140.0,
  };
}

Map<String, dynamic> _lucratividadeMensalRow() {
  return <String, dynamic>{
    ..._lucratividadeRow(),
    'Ano': 2026,
    'Mes': 4,
    'AnoMes': '2026/04',
  };
}

AgentQueryTarget _agentTarget(String agentId, {required String token}) {
  return AgentQueryTarget(
    agentId: agentId,
    displayName: 'Agent',
    connectionStatus: AgentConnectionStatus.online,
    clientToken: token,
    hubConnectedFromApprovedCatalogRow: true,
  );
}
