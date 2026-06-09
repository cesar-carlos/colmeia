import 'dart:async';

import 'package:checks/checks.dart';
import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/features/agent_queries/application/orchestration/agent_query_plan_builder.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_target.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_target_resolution.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_batch_execution_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_batch_request.dart';
import 'package:colmeia/features/agent_queries/domain/entities/cadastro_filial_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_total_vendas_municipio_filial_periodo_filter.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/agent_queries_repository.dart';
import 'package:colmeia/features/client_agents/domain/entities/agent_connection_status.dart';
import 'package:colmeia/features/sales/application/sales_live_map_policies.dart';
import 'package:colmeia/features/sales/data/sales_live_map_batch_loader_impl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:result_dart/result_dart.dart';

class _MockAgentQueriesRepository extends Mock
    implements AgentQueriesRepository {}

void main() {
  late _MockAgentQueriesRepository agentQueriesRepository;
  late SalesLiveMapBatchLoaderImpl loader;

  setUpAll(() {
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
    agentQueriesRepository = _MockAgentQueriesRepository();
    loader = SalesLiveMapBatchLoaderImpl(
      planBuilder: const AgentQueryPlanBuilder(),
      agentQueriesRepository: agentQueriesRepository,
    );
  });

  group('SalesLiveMapBatchLoader', () {
    test(
      'sends one merged batch with catalog and sales commands per agent',
      () async {
        final target = _agentTarget('agent-1', token: 'token-1');
        when(
          () => agentQueriesRepository.executeSqlBatch(any()),
        ).thenAnswer(
          (_) async => Success<AgentSqlBatchExecutionResult, AppFailure>(
            _batchResult(
              commandCount: salesLiveMapBatchCommandCount,
              rowsByIndex: <int, List<Map<String, dynamic>>>{
                0: <Map<String, dynamic>>[_catalogRow()],
                1: <Map<String, dynamic>>[_salesRow()],
              },
            ),
          ),
        );

        final result = await loader.load(
          userId: 'user-1',
          catalogFilter: _catalogFilter(),
          salesFilter: _salesFilter(),
          preResolvedResolution: _resolution(target),
        );

        check(result.isSuccess()).isTrue();
        final batch = result.getOrThrow();
        check(batch.catalogPage.report.participants.single.rows.length).equals(1);
        check(batch.catalogPage.report.participants.single.rows.single.nomeFilial)
            .equals('Filial');
        check(batch.salesReport.participants.single.rows.single.qtdVendas)
            .equals(3);
        check(batch.salesReport.participants.single.rows.single.totalVenda)
            .equals(150);

        final requests = verify(
          () => agentQueriesRepository.executeSqlBatch(captureAny()),
        ).captured.cast<AgentSqlExecuteBatchRequest>();
        check(requests.length).equals(1);
        final request = requests.single;
        check(request.agentId).equals('agent-1');
        check(request.clientToken).equals('token-1');
        check(request.requestingUserId).equals('user-1');
        check(request.commands.length).equals(salesLiveMapBatchCommandCount);
        check(request.bridgeTimeoutMs).equals(
          SalesLiveMapBatchLoadConfig.bridgeTimeoutMs,
        );
        check(request.options?.maxRows).equals(
          SalesLiveMapBatchLoadConfig.batchMaxRows,
        );
        check(request.options?.maxParallelReadOnlyBatchItems).isNotNull();
        check(request.commands.first.sql).contains('Filial');
        check(request.commands.last.sql).contains('ProdutoVendido');
      },
    );

    test('keeps sales failure local when catalog succeeds', () async {
      final target = _agentTarget('agent-1', token: 'token-1');
      when(
        () => agentQueriesRepository.executeSqlBatch(any()),
      ).thenAnswer(
        (_) async => Success<AgentSqlBatchExecutionResult, AppFailure>(
          _batchResult(
            commandCount: salesLiveMapBatchCommandCount,
            rowsByIndex: <int, List<Map<String, dynamic>>>{
              0: <Map<String, dynamic>>[_catalogRow()],
            },
            failedIndexes: const <int>{1},
          ),
        ),
      );

      final result = await loader.load(
        userId: 'user-1',
        catalogFilter: _catalogFilter(),
        salesFilter: _salesFilter(),
        preResolvedResolution: _resolution(target),
      );

      check(result.isSuccess()).isTrue();
      final loaded = result.getOrThrow();
      check(loaded.catalogPage.report.participants.single.failure).isNull();
      check(loaded.salesReport.participants.single.failure).isA<RpcFailure>();
      check(loaded.salesReport.participants.single.rows).isEmpty();
    });

    test('limits concurrent executeSqlBatch calls per wave', () async {
      const waveConcurrency = 2;
      final waveLoader = SalesLiveMapBatchLoaderImpl(
        planBuilder: const AgentQueryPlanBuilder(),
        agentQueriesRepository: agentQueriesRepository,
        targetWaveConcurrency: waveConcurrency,
      );
      final targets = List<AgentQueryTarget>.generate(
        5,
        (index) => _agentTarget('agent-${index + 1}', token: 'token'),
      );
      var active = 0;
      var maxActive = 0;
      when(
        () => agentQueriesRepository.executeSqlBatch(any()),
      ).thenAnswer((_) async {
        active++;
        if (active > maxActive) {
          maxActive = active;
        }
        await Future<void>.delayed(const Duration(milliseconds: 30));
        active--;
        return Success<AgentSqlBatchExecutionResult, AppFailure>(
          _batchResult(
            commandCount: salesLiveMapBatchCommandCount,
            rowsByIndex: <int, List<Map<String, dynamic>>>{
              0: <Map<String, dynamic>>[_catalogRow()],
              1: <Map<String, dynamic>>[_salesRow()],
            },
          ),
        );
      });

      await waveLoader.load(
        userId: 'user-1',
        catalogFilter: _catalogFilter(),
        salesFilter: _salesFilter(),
        preResolvedResolution: AgentQueryTargetResolution(
          consideredApprovedTargets: targets,
          missingClientTokenTargets: const <AgentQueryTarget>[],
          consideredApprovedAgentCount: targets.length,
          selectedAgentIds: <String>{
            for (var i = 0; i < targets.length; i++) 'agent-${i + 1}',
          },
        ),
        targetWaveConcurrency: waveConcurrency,
      );

      check(maxActive <= waveConcurrency).isTrue();
      check(maxActive).isGreaterThan(1);
      verify(
        () => agentQueriesRepository.executeSqlBatch(any()),
      ).called(targets.length);
    });

    test(
      'loadProgressively exposes sales before catalog pagination completes',
      () async {
        final target = _agentTarget('agent-1', token: 'token-1');
        final paginationGate = Completer<void>();
        var paginationCompleted = false;
        when(
          () => agentQueriesRepository.executeSqlBatch(any()),
        ).thenAnswer((invocation) async {
          final request =
              invocation.positionalArguments.first
                  as AgentSqlExecuteBatchRequest;
          if (request.commands.length == salesLiveMapBatchCommandCount) {
            return Success<AgentSqlBatchExecutionResult, AppFailure>(
              _batchResult(
                commandCount: salesLiveMapBatchCommandCount,
                rowsByIndex: <int, List<Map<String, dynamic>>>{
                  0: <Map<String, dynamic>>[
                    _catalogRow(totalCount: 2),
                  ],
                  1: <Map<String, dynamic>>[_salesRow()],
                },
              ),
            );
          }
          await paginationGate.future;
          paginationCompleted = true;
          return Success<AgentSqlBatchExecutionResult, AppFailure>(
            _batchResult(
              commandCount: 1,
              rowsByIndex: <int, List<Map<String, dynamic>>>{
                0: <Map<String, dynamic>>[
                  _catalogRow(
                    totalCount: 2,
                    codFilial: 2,
                    nomeFilial: 'Filial 2',
                  ),
                ],
              },
            ),
          );
        });

        final emissions = <SalesLiveMapBatchLoadResult>[];
        final loadDone = Completer<void>();
        final subscription = loader
            .loadProgressively(
              userId: 'user-1',
              catalogFilter: _catalogFilter(),
              salesFilter: _salesFilter(),
              preResolvedResolution: _resolution(target),
            )
            .listen(
              (result) {
                result.fold(
                  emissions.add,
                  (_) {},
                );
              },
              onDone: loadDone.complete,
            );
        addTearDown(subscription.cancel);

        while (emissions.isEmpty) {
          await Future<void>.delayed(const Duration(milliseconds: 1));
        }
        final partial = emissions.first;
        check(partial.isFinal).isFalse();
        check(partial.salesLoadingComplete).isTrue();
        check(partial.salesReport.participants.single.rows).isNotEmpty();
        check(paginationCompleted).isFalse();

        paginationGate.complete();
        await loadDone.future;

        check(emissions.last.isFinal).isTrue();
        check(paginationCompleted).isTrue();
        check(
          emissions.last.catalogPage.report.participants.single.rows.length,
        ).equals(2);
      },
    );

    test(
      'marks pagination stalled when a follow-up catalog page fails',
      () async {
        final target = _agentTarget('agent-1', token: 'token-1');
        when(
          () => agentQueriesRepository.executeSqlBatch(any()),
        ).thenAnswer((invocation) async {
          final request =
              invocation.positionalArguments.first
                  as AgentSqlExecuteBatchRequest;
          if (request.commands.length == salesLiveMapBatchCommandCount) {
            return Success<AgentSqlBatchExecutionResult, AppFailure>(
              _batchResult(
                commandCount: salesLiveMapBatchCommandCount,
                rowsByIndex: <int, List<Map<String, dynamic>>>{
                  0: <Map<String, dynamic>>[
                    _catalogRow(totalCount: 2),
                  ],
                  1: <Map<String, dynamic>>[_salesRow()],
                },
              ),
            );
          }
          return const Failure<AgentSqlBatchExecutionResult, AppFailure>(
            NetworkFailure(message: 'pagination page failed'),
          );
        });

        final result = await loader.load(
          userId: 'user-1',
          catalogFilter: _catalogFilter(),
          salesFilter: _salesFilter(),
          preResolvedResolution: _resolution(target),
        );

        check(result.isSuccess()).isTrue();
        final loaded = result.getOrThrow();
        check(loaded.catalogPage.paginationStalledAgentIds.contains('agent-1'))
            .isTrue();
        check(loaded.catalogPage.report.participants.single.rows.length).equals(1);
      },
    );

    test('loadProgressively emits once per completed target wave', () async {
      const waveConcurrency = 2;
      final waveLoader = SalesLiveMapBatchLoaderImpl(
        planBuilder: const AgentQueryPlanBuilder(),
        agentQueriesRepository: agentQueriesRepository,
        targetWaveConcurrency: waveConcurrency,
      );
      final targets = List<AgentQueryTarget>.generate(
        5,
        (index) => _agentTarget('agent-${index + 1}', token: 'token'),
      );
      when(
        () => agentQueriesRepository.executeSqlBatch(any()),
      ).thenAnswer(
        (_) async => Success<AgentSqlBatchExecutionResult, AppFailure>(
          _batchResult(
            commandCount: salesLiveMapBatchCommandCount,
            rowsByIndex: <int, List<Map<String, dynamic>>>{
              0: <Map<String, dynamic>>[_catalogRow()],
              1: <Map<String, dynamic>>[_salesRow()],
            },
          ),
        ),
      );

      final emissions = <SalesLiveMapBatchLoadResult>[];
      await for (final result in waveLoader.loadProgressively(
        userId: 'user-1',
        catalogFilter: _catalogFilter(),
        salesFilter: _salesFilter(),
        preResolvedResolution: AgentQueryTargetResolution(
          consideredApprovedTargets: targets,
          missingClientTokenTargets: const <AgentQueryTarget>[],
          consideredApprovedAgentCount: targets.length,
          selectedAgentIds: <String>{
            for (var i = 0; i < targets.length; i++) 'agent-${i + 1}',
          },
        ),
        targetWaveConcurrency: waveConcurrency,
      )) {
        result.fold(
          emissions.add,
          (_) {},
        );
      }

      check(emissions.length).equals(4);
      check(emissions.take(3).every((batch) => !batch.isFinal)).isTrue();
      check(emissions[0].salesLoadingComplete).isFalse();
      check(emissions[1].salesLoadingComplete).isFalse();
      check(emissions[2].salesLoadingComplete).isTrue();
      check(emissions[0].salesReport.participants.length).equals(2);
      check(emissions[1].salesReport.participants.length).equals(4);
      check(emissions[2].salesReport.participants.length).equals(5);
      check(emissions.last.isFinal).isTrue();
      check(emissions.last.salesLoadingComplete).isTrue();
    });
  });
}

AgentQueryTarget _agentTarget(String agentId, {String? token}) {
  return AgentQueryTarget(
    agentId: agentId,
    displayName: agentId,
    clientToken: token,
    connectionStatus: AgentConnectionStatus.online,
    hubConnectedFromApprovedCatalogRow: true,
  );
}

AgentQueryTargetResolution _resolution(AgentQueryTarget target) {
  return AgentQueryTargetResolution(
    consideredApprovedTargets: <AgentQueryTarget>[target],
    missingClientTokenTargets: const <AgentQueryTarget>[],
    consideredApprovedAgentCount: 1,
    selectedAgentIds: <String>{target.agentId},
    hubPresenceOnlineAgentIdsSnapshot: <String>{target.agentId},
  );
}

CadastroFilialFilter _catalogFilter() {
  return CadastroFilialFilter(
    codEmpresa: SalesLiveMapPolicies.primaryCompanyCode,
    codFilial: SalesLiveMapPolicies.primaryBranchCode,
    pageSize: CadastroFilialFilter.maxPageSize,
    mapCatalogProjection: true,
  );
}

ResumoTotalVendasMunicipioFilialPeriodoFilter _salesFilter() {
  return ResumoTotalVendasMunicipioFilialPeriodoFilter(
    dataVendaInicio: DateTime(2026, 4),
    dataVendaFim: DateTime(2026, 4, 30),
    codEmpresa: SalesLiveMapPolicies.primaryCompanyCode,
    codFilial: SalesLiveMapPolicies.primaryBranchCode,
  );
}

Map<String, dynamic> _catalogRow({
  int totalCount = 1,
  int codFilial = 1,
  String nomeFilial = 'Filial',
}) {
  return <String, dynamic>{
    'TotalCount': totalCount,
    'CodEmpresa': 1,
    'CodFilial': codFilial,
    'NomeFilial': nomeFilial,
    'NomeFantasia': 'Fantasia',
    'CEP': '78005123',
    'NomeMunicipio': 'Cuiaba',
    'CodigoIBGE': 5103403,
    'UFMunicipio': 'MT',
  };
}

Map<String, dynamic> _salesRow() {
  return <String, dynamic>{
    'CodEmpresa': 1,
    'CodFilial': 1,
    'NomeFilial': 'Filial',
    'NomeFantasiaFilial': 'Fantasia',
    'CEPFilial': '78005123',
    'CodMunicipioFilial': 1,
    'NomeMunicipioFilial': 'Cuiaba',
    'UFMunicipioFilial': 'MT',
    'CodigoIBGEMunicipioFilial': 5103403,
    'QtdVendas': 3,
    'TotalVenda': 150,
  };
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
      ),
    ),
  );
}
