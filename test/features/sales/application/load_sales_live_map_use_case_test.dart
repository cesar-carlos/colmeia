import 'dart:async';
import 'dart:convert';

import 'package:checks/checks.dart';
import 'package:colmeia/core/cache/app_cache_store.dart';
import 'package:colmeia/core/config/app_environment.dart';
import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/features/agent_queries/application/orchestration/agent_query_plan_builder.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_cadastro_filial_across_agents_use_case.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_resumo_total_vendas_municipio_filial_periodo_across_agents_use_case.dart';
import 'package:colmeia/features/agent_queries/data/agent_queries_bounded_result_max_rows.dart';
import 'package:colmeia/features/agent_queries/data/orchestration/agent_query_target_resolver.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_execution_participant.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_execution_report.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_execution_strategy.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_key.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_target.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_target_resolution.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_batch_execution_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_batch_request.dart';
import 'package:colmeia/features/agent_queries/domain/entities/cadastro_filial_across_agents_page_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/cadastro_filial_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/cadastro_filial_row.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_total_vendas_municipio_filial_periodo_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_total_vendas_municipio_filial_periodo_row.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/agent_queries_repository.dart';
import 'package:colmeia/features/client_agents/domain/entities/agent_connection_status.dart';
import 'package:colmeia/features/sales/application/load_sales_live_map_use_case.dart';
import 'package:colmeia/features/sales/application/sales_live_map_catalog_scope.dart';
import 'package:colmeia/features/sales/application/sales_live_map_internal_labels.dart';
import 'package:colmeia/features/sales/application/sales_live_map_refresh_metrics.dart';
import 'package:colmeia/features/sales/application/sales_live_map_reload_reason.dart';
import 'package:colmeia/features/sales/data/sales_live_map_batch_loader.dart';
import 'package:colmeia/features/sales/data/sales_live_map_catalog_disk_cache.dart';
import 'package:colmeia/features/sales/data/sales_live_map_point_resolver_adapter.dart';
import 'package:colmeia/features/sales/domain/entities/sales_live_map_branch_ref.dart';
import 'package:colmeia/features/sales/domain/entities/sales_live_map_filter.dart';
import 'package:colmeia/features/sales/domain/entities/sales_live_map_point.dart';
import 'package:colmeia/shared/maps/app_location_geocode_cache.dart';
import 'package:colmeia/shared/maps/app_location_models.dart';
import 'package:colmeia/shared/maps/app_location_resolver.dart';
import 'package:colmeia/shared/widgets/charts/app_brazil_store_sales_point_resolver.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:result_dart/result_dart.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockLoadResumoTotalVendasMunicipioFilialPeriodoAcrossAgentsUseCase
    extends Mock
    implements LoadResumoTotalVendasMunicipioFilialPeriodoAcrossAgentsUseCase {}

class _MockLoadCadastroFilialAcrossAgentsUseCase extends Mock
    implements LoadCadastroFilialAcrossAgentsUseCase {}

class _MockAgentQueryTargetResolver extends Mock
    implements AgentQueryTargetResolver {}

class _MockSalesLiveMapCatalogDiskCache extends Mock
    implements SalesLiveMapCatalogDiskCache {}

class _MockAgentQueriesRepository extends Mock
    implements AgentQueriesRepository {}

AgentQueryTargetResolution _wideTestAgentResolution() {
  return AgentQueryTargetResolution(
    consideredApprovedTargets: <AgentQueryTarget>[
      _target('agent-a'),
      _target('agent-b'),
      _target('agent-c'),
      _target('agent-d', clientToken: null),
      _target('agent-e'),
    ],
    missingClientTokenTargets: const <AgentQueryTarget>[],
    consideredApprovedAgentCount: 5,
    sqlEligibleConsideredTargetCount: 5,
  );
}

void main() {
  const userId = 'user-1';
  final now = DateTime(2026, 5, 9, 14);

  late _MockLoadResumoTotalVendasMunicipioFilialPeriodoAcrossAgentsUseCase
  loadAcrossAgents;
  late _MockLoadCadastroFilialAcrossAgentsUseCase loadCadastroAcrossAgents;
  late _MockAgentQueryTargetResolver targetResolver;
  late _MockSalesLiveMapCatalogDiskCache catalogDiskCache;
  late SalesLiveMapRefreshMetrics refreshMetrics;
  late _MemoryCacheStore cacheStore;
  late _StaticBrazilTestGeocoder geocoder;
  late LoadSalesLiveMapUseCase useCase;

  setUpAll(() {
    registerFallbackValue(
      ResumoTotalVendasMunicipioFilialPeriodoFilter(
        dataVendaInicio: DateTime.utc(2026),
        dataVendaFim: DateTime.utc(2026, 12, 31),
      ),
    );
    registerFallbackValue(const CadastroFilialFilter());
    registerFallbackValue(AgentQueryExecutionStrategy.mergeAll);
    registerFallbackValue(_wideTestAgentResolution());
    registerFallbackValue(
      CadastroFilialAcrossAgentsPageResult.fromReport(
        const AgentQueryExecutionReport<CadastroFilialRow>(
          queryKey: AgentQueryKey.cadastroFilial,
          strategy: AgentQueryExecutionStrategy.mergeAll,
          consideredApprovedAgentCount: 0,
          plannedTargets: <AgentQueryTarget>[],
          missingClientTokenTargets: <AgentQueryTarget>[],
          participants: <AgentQueryExecutionParticipant<CadastroFilialRow>>[],
          totalElapsedMs: 0,
        ),
      ),
    );
    registerFallbackValue(SalesLiveMapCatalogScope.fullAgent());
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
    loadAcrossAgents =
        _MockLoadResumoTotalVendasMunicipioFilialPeriodoAcrossAgentsUseCase();
    loadCadastroAcrossAgents = _MockLoadCadastroFilialAcrossAgentsUseCase();
    targetResolver = _MockAgentQueryTargetResolver();
    catalogDiskCache = _MockSalesLiveMapCatalogDiskCache();
    refreshMetrics = SalesLiveMapRefreshMetrics();
    _stubCatalogFailure(loadCadastroAcrossAgents);
    when(
      () => targetResolver.resolve(
        userId: any(named: 'userId'),
        selectedAgentIds: any(named: 'selectedAgentIds'),
      ),
    ).thenAnswer(
      (_) async => Success<AgentQueryTargetResolution, AppFailure>(
        _wideTestAgentResolution(),
      ),
    );
    when(
      () => catalogDiskCache.readIfFresh(
        userId: any(named: 'userId'),
        scope: any(named: 'scope'),
        now: any(named: 'now'),
      ),
    ).thenReturn(null);
    when(
      () => catalogDiskCache.write(
        userId: any(named: 'userId'),
        scope: any(named: 'scope'),
        now: any(named: 'now'),
        result: any(named: 'result'),
      ),
    ).thenAnswer((_) async {});
    cacheStore = _MemoryCacheStore();
    geocoder = _StaticBrazilTestGeocoder();
    final locationResolver = AppLocationResolver(
      cache: AppLocationGeocodeCache(cacheStore),
      geocoders: <AppLocationGeocoder>[geocoder],
      now: () => now,
    );
    useCase = LoadSalesLiveMapUseCase(
      targetResolver,
      catalogDiskCache,
      loadAcrossAgents,
      loadCadastroAcrossAgents,
      SalesLiveMapPointResolverAdapter(
        delegate: AppBrazilStoreSalesPointResolver(
          locationResolver: locationResolver,
        ),
      ),
      refreshMetrics: refreshMetrics,
      now: () => now,
    );
  });

  LoadSalesLiveMapUseCase buildUseCaseWithDiskCache(
    SalesLiveMapCatalogDiskCache diskCache, {
    SalesLiveMapRefreshMetrics? metrics,
  }) {
    final locationResolver = AppLocationResolver(
      cache: AppLocationGeocodeCache(_MemoryCacheStore()),
      geocoders: <AppLocationGeocoder>[geocoder],
      now: () => now,
    );
    return LoadSalesLiveMapUseCase(
      targetResolver,
      diskCache,
      loadAcrossAgents,
      loadCadastroAcrossAgents,
      SalesLiveMapPointResolverAdapter(
        delegate: AppBrazilStoreSalesPointResolver(
          locationResolver: locationResolver,
        ),
      ),
      refreshMetrics: metrics,
      now: () => now,
    );
  }

  test('agrega varias linhas da mesma filial em um ponto', () async {
    _stubReport(
      loadAcrossAgents,
      _report(
        plannedTargets: <AgentQueryTarget>[_target('agent-a')],
        participants:
            <
              AgentQueryExecutionParticipant<
                ResumoTotalVendasMunicipioFilialPeriodoRow
              >
            >[
              _participant(
                'agent-a',
                rows: <ResumoTotalVendasMunicipioFilialPeriodoRow>[
                  _row(
                    nomeFilial: 'Cadastro matriz',
                    nomeFantasiaFilial: 'Fantasia matriz',
                    totalVenda: 120,
                    qtdVendas: 2,
                  ),
                  _row(
                    nomeFilial: 'Cadastro matriz',
                    nomeFantasiaFilial: 'Fantasia matriz',
                    totalVenda: 80,
                    qtdVendas: 3,
                  ),
                ],
              ),
            ],
      ),
    );

    final result = await useCase(
      userId: userId,
      filter: const SalesLiveMapFilter(),
    );

    check(result.points).has((points) => points.length, 'length').equals(1);
    final point = result.points.single;
    check(point.fantasyName).equals('Fantasia matriz');
    check(point.branchName).equals('Cadastro matriz');
    check(point.companyCode).equals(1);
    check(point.branchCode).equals(1);
    check(point.agentName).equals('Agente agent-a');
    check(point.salesAmount).equals(200);
    check(point.salesCount).equals(5);
    check(result.totalRevenue).equals(200);
    check(result.totalSalesCount).equals(5);
    check(result.totalBranchCount).equals(1);
    check(result.mappedBranchCount).equals(1);
    check(result.mappedMunicipalityCount).equals(1);
    check(result.branchOptions.single.name).equals('Cadastro matriz');
    check(result.branchOptions.map((branch) => branch.id).toList()).deepEquals(
      <String>['agent-a-1-1'],
    );
  });

  test(
    'preserva separacao por agente quando empresa e filial coincidem',
    () async {
      _stubReport(
        loadAcrossAgents,
        _report(
          plannedTargets: <AgentQueryTarget>[
            _target('agent-a'),
            _target('agent-b'),
          ],
          participants:
              <
                AgentQueryExecutionParticipant<
                  ResumoTotalVendasMunicipioFilialPeriodoRow
                >
              >[
                _participant(
                  'agent-a',
                  rows: <ResumoTotalVendasMunicipioFilialPeriodoRow>[
                    _row(totalVenda: 100),
                  ],
                ),
                _participant(
                  'agent-b',
                  rows: <ResumoTotalVendasMunicipioFilialPeriodoRow>[
                    _row(totalVenda: 250, qtdVendas: 4),
                  ],
                ),
              ],
        ),
      );

      final result = await useCase(
        userId: userId,
        filter: const SalesLiveMapFilter(),
      );

      check(result.points.map((point) => point.id).toSet()).deepEquals(
        <String>{'agent-a-1-1', 'agent-b-1-1'},
      );
      check(result.totalBranchCount).equals(2);
      check(result.totalRevenue).equals(350);
      check(result.mappedMunicipalityCount).equals(1);
    },
  );

  test('mostra filial do cadastro sem venda com valores zerados', () async {
    _stubCatalogReport(
      loadCadastroAcrossAgents,
      _catalogReport(
        plannedTargets: <AgentQueryTarget>[_target('agent-a')],
        participants: <AgentQueryExecutionParticipant<CadastroFilialRow>>[
          _catalogParticipant(
            'agent-a',
            rows: <CadastroFilialRow>[
              _catalogRow(nomeFilial: 'Cadastro sem venda'),
            ],
          ),
        ],
      ),
    );
    _stubReport(
      loadAcrossAgents,
      _report(
        plannedTargets: <AgentQueryTarget>[_target('agent-a')],
        participants:
            <
              AgentQueryExecutionParticipant<
                ResumoTotalVendasMunicipioFilialPeriodoRow
              >
            >[
              _participant(
                'agent-a',
                rows: const <ResumoTotalVendasMunicipioFilialPeriodoRow>[],
              ),
            ],
      ),
    );

    final result = await useCase(
      userId: userId,
      filter: const SalesLiveMapFilter(),
    );

    check(result.points).has((points) => points.length, 'length').equals(1);
    check(result.points.single.name).equals('Loja matriz');
    check(result.points.single.salesAmount).equals(0);
    check(result.points.single.salesCount).equals(0);
    check(result.totalRevenue).equals(0);
    check(result.totalSalesCount).equals(0);
    check(result.catalogBranchCount).equals(1);
    check(result.salesBranchCount).equals(0);
    check(result.zeroedBranchCount).equals(1);
    check(result.noSalesBranchCount).equals(1);
    check(result.salesUnavailableBranchCount).equals(0);
    check(result.points.single.salesDataUnavailable).isFalse();
    check(result.branchOptions.single.name).equals('Cadastro sem venda');
  });

  test(
    'chama AgentQueryTargetResolver.resolve uma vez por carga com catalogo e vendas',
    () async {
      _stubCatalogReport(
        loadCadastroAcrossAgents,
        _catalogReport(
          plannedTargets: <AgentQueryTarget>[_target('agent-a')],
          participants: <AgentQueryExecutionParticipant<CadastroFilialRow>>[
            _catalogParticipant(
              'agent-a',
              rows: <CadastroFilialRow>[_catalogRow()],
            ),
          ],
        ),
      );
      _stubReport(
        loadAcrossAgents,
        _report(
          plannedTargets: <AgentQueryTarget>[_target('agent-a')],
          participants:
              <
                AgentQueryExecutionParticipant<
                  ResumoTotalVendasMunicipioFilialPeriodoRow
                >
              >[
                _participant(
                  'agent-a',
                  rows: <ResumoTotalVendasMunicipioFilialPeriodoRow>[
                    _row(totalVenda: 50),
                  ],
                ),
              ],
        ),
      );

      await useCase(userId: userId, filter: const SalesLiveMapFilter());

      verify(
        () => targetResolver.resolve(
          userId: any(named: 'userId'),
          selectedAgentIds: any(named: 'selectedAgentIds'),
        ),
      ).called(1);
    },
  );

  test(
    'loadProgressive emite cadastro no mapa enquanto vendas seguem carregando',
    () async {
      final catalogCompleter =
          Completer<AppResult<CadastroFilialAcrossAgentsPageResult>>();
      final salesCompleter =
          Completer<
            AppResult<
              AgentQueryExecutionReport<
                ResumoTotalVendasMunicipioFilialPeriodoRow
              >
            >
          >();
      _stubCatalogFuture(loadCadastroAcrossAgents, catalogCompleter.future);
      _stubReportFuture(loadAcrossAgents, salesCompleter.future);

      final iterator = StreamIterator<SalesLiveMapLoadResult>(
        useCase.loadProgressive(
          userId: userId,
          filter: const SalesLiveMapFilter(),
        ),
      );
      addTearDown(iterator.cancel);

      check(await iterator.moveNext()).isTrue();
      final base = iterator.current;
      check(base.salesDataPending).isTrue();
      check(base.points).isEmpty();

      catalogCompleter.complete(
        Success<CadastroFilialAcrossAgentsPageResult, AppFailure>(
          CadastroFilialAcrossAgentsPageResult.fromReport(
            _catalogReport(
              plannedTargets: <AgentQueryTarget>[_target('agent-a')],
              participants: <AgentQueryExecutionParticipant<CadastroFilialRow>>[
                _catalogParticipant(
                  'agent-a',
                  rows: <CadastroFilialRow>[_catalogRow()],
                ),
              ],
            ),
          ),
        ),
      );

      await Future<void>.delayed(Duration.zero);
      check(await iterator.moveNext()).isTrue();
      var partial = iterator.current;
      if (partial.points.isEmpty && partial.branchOptions.isNotEmpty) {
        check(partial.salesDataPending).isTrue();
        check(await iterator.moveNext()).isTrue();
        partial = iterator.current;
      }
      if (partial.points.isEmpty) {
        check(await iterator.moveNext()).isTrue();
        partial = iterator.current;
      }
      check(partial.salesDataPending).isTrue();
      check(partial.salesPendingBranchCount).equals(1);
      check(partial.points.single.salesDataLoading).isTrue();
      check(partial.points.single.salesAmount).equals(0);
      check(partial.noSalesBranchCount).equals(0);

      salesCompleter.complete(
        Success<
          AgentQueryExecutionReport<ResumoTotalVendasMunicipioFilialPeriodoRow>,
          AppFailure
        >(
          _report(
            plannedTargets: <AgentQueryTarget>[_target('agent-a')],
            participants:
                <
                  AgentQueryExecutionParticipant<
                    ResumoTotalVendasMunicipioFilialPeriodoRow
                  >
                >[
                  _participant(
                    'agent-a',
                    rows: <ResumoTotalVendasMunicipioFilialPeriodoRow>[
                      _row(totalVenda: 220, qtdVendas: 6),
                    ],
                  ),
                ],
          ),
        ),
      );

      SalesLiveMapLoadResult? finalResult;
      while (await iterator.moveNext()) {
        finalResult = iterator.current;
      }
      check(finalResult).isNotNull();
      check(finalResult!.salesDataPending).isFalse();
      check(finalResult.salesPendingBranchCount).equals(0);
      check(finalResult.points.single.salesDataLoading).isFalse();
      check(finalResult.points.single.salesAmount).equals(220);
      check(finalResult.points.single.salesCount).equals(6);
      check(finalResult.partialGeoReuseCount).equals(1);
      check(geocoder.lookups).has((it) => it.length, 'length').equals(1);
    },
  );

  test(
    'loadProgressive emite pontos IBGE antes da geolocalizacao completa',
    () async {
      final catalogCompleter =
          Completer<AppResult<CadastroFilialAcrossAgentsPageResult>>();
      final salesCompleter =
          Completer<
            AppResult<
              AgentQueryExecutionReport<
                ResumoTotalVendasMunicipioFilialPeriodoRow
              >
            >
          >();
      _stubCatalogFuture(loadCadastroAcrossAgents, catalogCompleter.future);
      _stubReportFuture(loadAcrossAgents, salesCompleter.future);

      final emissions = <SalesLiveMapLoadResult>[];
      final subscription = useCase
          .loadProgressive(
            userId: userId,
            filter: const SalesLiveMapFilter(),
          )
          .listen(emissions.add);
      addTearDown(subscription.cancel);

      await Future<void>.delayed(Duration.zero);
      check(emissions.single.points).isEmpty();

      catalogCompleter.complete(
        Success<CadastroFilialAcrossAgentsPageResult, AppFailure>(
          CadastroFilialAcrossAgentsPageResult.fromReport(
            _catalogReport(
              plannedTargets: <AgentQueryTarget>[_target('agent-a')],
              participants: <AgentQueryExecutionParticipant<CadastroFilialRow>>[
                _catalogParticipant(
                  'agent-a',
                  rows: <CadastroFilialRow>[_catalogRow()],
                ),
              ],
            ),
          ),
        ),
      );
      await Future<void>.delayed(Duration.zero);

      final pendingShell = emissions
          .where(
            (result) =>
                result.salesDataPending &&
                result.points.isEmpty &&
                result.branchOptions.isNotEmpty,
          )
          .toList(growable: false);
      check(pendingShell).isNotEmpty();

      final pendingWithPoints = emissions
          .where(
            (result) => result.salesDataPending && result.points.isNotEmpty,
          )
          .toList(growable: false);
      check(pendingWithPoints).isNotEmpty();
      check(
        pendingWithPoints.first.points.single.locationResolution,
      ).equals(SalesLiveMapLocationResolution.ibgeMunicipalityCode);

      salesCompleter.complete(
        Success<
          AgentQueryExecutionReport<ResumoTotalVendasMunicipioFilialPeriodoRow>,
          AppFailure
        >(
          _report(
            plannedTargets: <AgentQueryTarget>[_target('agent-a')],
            participants:
                <
                  AgentQueryExecutionParticipant<
                    ResumoTotalVendasMunicipioFilialPeriodoRow
                  >
                >[
                  _participant(
                    'agent-a',
                    rows: <ResumoTotalVendasMunicipioFilialPeriodoRow>[
                      _row(),
                    ],
                  ),
                ],
          ),
        ),
      );
      await subscription.cancel();
    },
  );

  test(
    'loadProgressive marca venda indisponivel quando vendas falham apos cadastro',
    () async {
      _stubCatalogReport(
        loadCadastroAcrossAgents,
        _catalogReport(
          plannedTargets: <AgentQueryTarget>[_target('agent-a')],
          participants: <AgentQueryExecutionParticipant<CadastroFilialRow>>[
            _catalogParticipant(
              'agent-a',
              rows: <CadastroFilialRow>[_catalogRow()],
            ),
          ],
        ),
      );
      _stubSalesFailure(loadAcrossAgents);

      final emissions = await useCase
          .loadProgressive(
            userId: userId,
            filter: const SalesLiveMapFilter(),
          )
          .toList();

      final pendingEmission = emissions.lastWhere(
        (result) => result.salesDataPending && result.points.isNotEmpty,
      );
      check(pendingEmission.points.single.salesDataLoading).isTrue();
      final finalResult = emissions.last;
      check(finalResult.salesDataPending).isFalse();
      check(finalResult.points.single.salesDataLoading).isFalse();
      check(finalResult.points.single.salesDataUnavailable).isTrue();
      check(finalResult.salesUnavailableBranchCount).equals(1);
    },
  );

  test(
    'loadProgressive usa fallback de vendas quando cadastro falha',
    () async {
      _stubReport(
        loadAcrossAgents,
        _report(
          plannedTargets: <AgentQueryTarget>[_target('agent-a')],
          participants:
              <
                AgentQueryExecutionParticipant<
                  ResumoTotalVendasMunicipioFilialPeriodoRow
                >
              >[
                _participant(
                  'agent-a',
                  rows: <ResumoTotalVendasMunicipioFilialPeriodoRow>[
                    _row(totalVenda: 180, qtdVendas: 3),
                  ],
                ),
              ],
        ),
      );

      final emissions = await useCase
          .loadProgressive(
            userId: userId,
            filter: const SalesLiveMapFilter(),
          )
          .toList();

      check(emissions.first.salesDataPending).isTrue();
      final finalResult = emissions.last;
      check(finalResult.salesDataPending).isFalse();
      check(finalResult.points.single.salesAmount).equals(180);
      check(finalResult.points.single.salesDataLoading).isFalse();
    },
  );

  test(
    'loadProgressive com merged batch emite vendas antes da paginacao do catalogo',
    () async {
      if (!AppEnvironment.agentSqlSalesLiveMapMergeSqlBatchesPerTarget) {
        return;
      }

      final agentQueriesRepository = _MockAgentQueriesRepository();
      final target = _target('agent-a');
      final paginationGate = Completer<void>();
      var paginationCompleted = false;
      when(
        () => targetResolver.resolve(
          userId: any(named: 'userId'),
          selectedAgentIds: any(named: 'selectedAgentIds'),
        ),
      ).thenAnswer(
        (_) async => Success<AgentQueryTargetResolution, AppFailure>(
          AgentQueryTargetResolution(
            consideredApprovedTargets: <AgentQueryTarget>[target],
            missingClientTokenTargets: const <AgentQueryTarget>[],
            consideredApprovedAgentCount: 1,
            selectedAgentIds: <String>{target.agentId},
            hubPresenceOnlineAgentIdsSnapshot: <String>{target.agentId},
          ),
        ),
      );
      when(
        () => agentQueriesRepository.executeSqlBatch(any()),
      ).thenAnswer((invocation) async {
        final request =
            invocation.positionalArguments.first
                as AgentSqlExecuteBatchRequest;
        if (request.commands.length == salesLiveMapBatchCommandCount) {
          return Success<AgentSqlBatchExecutionResult, AppFailure>(
            _mergedBatchSqlResult(
              agentId: request.agentId,
              totalVenda: 220,
              catalogTotalCount: 2,
            ),
          );
        }
        await paginationGate.future;
        paginationCompleted = true;
        return const Success<AgentSqlBatchExecutionResult, AppFailure>(
          AgentSqlBatchExecutionResult(
            totalCommands: 1,
            successfulCommands: 1,
            failedCommands: 0,
            items: <AgentSqlBatchExecutionItem>[
              AgentSqlBatchExecutionItem(
                index: 0,
                ok: true,
                rows: <Map<String, dynamic>>[
                  <String, dynamic>{
                    'TotalCount': 2,
                    'CodEmpresa': 1,
                    'CodFilial': 2,
                    'NomeFilial': 'Loja agent-a filial 2',
                    'NomeFantasia': 'Loja agent-a filial 2',
                    'CEP': '78550000',
                    'NomeMunicipio': 'SINOP',
                    'CodigoIBGE': 5107909,
                    'UFMunicipio': 'MT',
                  },
                ],
                rowCount: 1,
              ),
            ],
          ),
        );
      });

      final locationResolver = AppLocationResolver(
        cache: AppLocationGeocodeCache(_MemoryCacheStore()),
        geocoders: <AppLocationGeocoder>[geocoder],
        now: () => now,
      );
      final mergedBatchUseCase = LoadSalesLiveMapUseCase(
        targetResolver,
        catalogDiskCache,
        loadAcrossAgents,
        loadCadastroAcrossAgents,
        SalesLiveMapPointResolverAdapter(
          delegate: AppBrazilStoreSalesPointResolver(
            locationResolver: locationResolver,
          ),
        ),
        refreshMetrics: refreshMetrics,
        batchLoader: SalesLiveMapBatchLoader(
          planBuilder: const AgentQueryPlanBuilder(),
          agentQueriesRepository: agentQueriesRepository,
        ),
        now: () => now,
      );

      final emissions = <SalesLiveMapLoadResult>[];
      final loadDone = Completer<void>();
      final subscription = mergedBatchUseCase
          .loadProgressive(
            userId: userId,
            filter: const SalesLiveMapFilter(),
          )
          .listen(
            emissions.add,
            onDone: loadDone.complete,
          );
      addTearDown(subscription.cancel);

      while (!emissions.any(
        (result) => !result.salesDataPending && result.totalRevenue > 0,
      )) {
        await Future<void>.delayed(const Duration(milliseconds: 1));
      }
      final salesReady = emissions.lastWhere(
        (result) => !result.salesDataPending && result.totalRevenue > 0,
      );
      check(salesReady.totalRevenue).equals(220);
      check(paginationCompleted).isFalse();

      paginationGate.complete();
      await loadDone.future;

      check(paginationCompleted).isTrue();
      check(emissions.last.totalBranchCount).equals(2);
      verifyNever(
        () => loadAcrossAgents(
          userId: any(named: 'userId'),
          filter: any(named: 'filter'),
          selectedAgentIds: any(named: 'selectedAgentIds'),
          strategy: any(named: 'strategy'),
          bridgeTimeoutMs: any(named: 'bridgeTimeoutMs'),
          raceMaxSources: any(named: 'raceMaxSources'),
          preResolvedResolution: any(named: 'preResolvedResolution'),
          cancelScope: any(named: 'cancelScope'),
          orderTargetsOnlineFirst: any(named: 'orderTargetsOnlineFirst'),
          dedupeTargetsByAgentId: any(named: 'dedupeTargetsByAgentId'),
          mergeAllConcurrencyOverride: any(named: 'mergeAllConcurrencyOverride'),
        ),
      );
    },
  );

  test('vincula cadastro e vendas por agente empresa e filial', () async {
    _stubCatalogReport(
      loadCadastroAcrossAgents,
      _catalogReport(
        plannedTargets: <AgentQueryTarget>[
          _target('agent-a'),
          _target('agent-b'),
        ],
        participants: <AgentQueryExecutionParticipant<CadastroFilialRow>>[
          _catalogParticipant(
            'agent-a',
            rows: <CadastroFilialRow>[_catalogRow(nomeFilial: 'A')],
          ),
          _catalogParticipant(
            'agent-b',
            rows: <CadastroFilialRow>[_catalogRow(nomeFilial: 'B')],
          ),
        ],
      ),
    );
    _stubReport(
      loadAcrossAgents,
      _report(
        plannedTargets: <AgentQueryTarget>[
          _target('agent-a'),
          _target('agent-b'),
        ],
        participants:
            <
              AgentQueryExecutionParticipant<
                ResumoTotalVendasMunicipioFilialPeriodoRow
              >
            >[
              _participant(
                'agent-b',
                rows: <ResumoTotalVendasMunicipioFilialPeriodoRow>[
                  _row(totalVenda: 250, qtdVendas: 4),
                ],
              ),
            ],
      ),
    );

    final result = await useCase(
      userId: userId,
      filter: const SalesLiveMapFilter(),
    );

    final byId = {for (final point in result.points) point.id: point};
    check(byId['agent-a-1-1']!.salesAmount).equals(0);
    check(byId['agent-b-1-1']!.salesAmount).equals(250);
    check(byId['agent-b-1-1']!.salesCount).equals(4);
    check(result.totalBranchCount).equals(2);
    check(result.totalRevenue).equals(250);
    check(result.salesBranchCount).equals(1);
    check(result.zeroedBranchCount).equals(1);
    check(result.noSalesBranchCount).equals(1);
    check(result.salesUnavailableBranchCount).equals(0);
  });

  test('filtra pontos e KPIs pela filial primaria selecionada', () async {
    _stubReport(
      loadAcrossAgents,
      _report(
        plannedTargets: <AgentQueryTarget>[_target('agent-a')],
        participants:
            <
              AgentQueryExecutionParticipant<
                ResumoTotalVendasMunicipioFilialPeriodoRow
              >
            >[
              _participant(
                'agent-a',
                rows: <ResumoTotalVendasMunicipioFilialPeriodoRow>[
                  _row(nomeFilial: 'Loja 1', totalVenda: 100),
                  _row(codFilial: 2, nomeFilial: 'Loja 2', totalVenda: 300),
                ],
              ),
            ],
      ),
    );

    final result = await useCase(
      userId: userId,
      filter: SalesLiveMapFilter(
        selectedAgentIds: const <String>{'agent-a'},
        selectedBranchIds: <SalesLiveMapBranchRef>{
          const SalesLiveMapBranchRef(
            agentId: 'agent-a',
            codEmpresa: 1,
            codFilial: 1,
          ),
        },
      ),
    );

    check(result.branchOptions.map((branch) => branch.id).toSet()).deepEquals(
      <String>{'agent-a-1-1'},
    );
    check(result.points.map((point) => point.id).toList()).deepEquals(
      <String>['agent-a-1-1'],
    );
    check(result.totalBranchCount).equals(1);
    check(result.totalRevenue).equals(100);
  });

  test('usa cadastro como fonte das opcoes mesmo sem venda', () async {
    _stubCatalogReport(
      loadCadastroAcrossAgents,
      _catalogReport(
        plannedTargets: <AgentQueryTarget>[_target('agent-a')],
        participants: <AgentQueryExecutionParticipant<CadastroFilialRow>>[
          _catalogParticipant(
            'agent-a',
            rows: <CadastroFilialRow>[_catalogRow(nomeFilial: 'Loja 1')],
          ),
        ],
      ),
    );
    _stubReport(
      loadAcrossAgents,
      _report(
        plannedTargets: <AgentQueryTarget>[_target('agent-a')],
        participants:
            <
              AgentQueryExecutionParticipant<
                ResumoTotalVendasMunicipioFilialPeriodoRow
              >
            >[
              _participant(
                'agent-a',
                rows: <ResumoTotalVendasMunicipioFilialPeriodoRow>[
                  _row(totalVenda: 100),
                ],
              ),
            ],
      ),
    );

    final result = await useCase(
      userId: userId,
      filter: SalesLiveMapFilter(
        selectedBranchIds: <SalesLiveMapBranchRef>{
          const SalesLiveMapBranchRef(
            agentId: 'agent-a',
            codEmpresa: 1,
            codFilial: 1,
          ),
        },
      ),
    );

    check(result.branchOptions.map((branch) => branch.id).toSet()).deepEquals(
      <String>{'agent-a-1-1'},
    );
    check(result.points.map((point) => point.id).toList()).deepEquals(
      <String>['agent-a-1-1'],
    );
    check(result.totalRevenue).equals(100);
    check(result.zeroedBranchCount).equals(0);

    final captured = verify(
      () => loadCadastroAcrossAgents.loadAll(
        userId: 'user-1',
        filter: captureAny(named: 'filter'),
        selectedAgentIds: captureAny(named: 'selectedAgentIds'),
        strategy: any(named: 'strategy'),
        bridgeTimeoutMs: any(named: 'bridgeTimeoutMs'),
        raceMaxSources: any(named: 'raceMaxSources'),
        preResolvedResolution: any(named: 'preResolvedResolution'),
        cancelScope: any(named: 'cancelScope'),
        orderTargetsOnlineFirst: any(named: 'orderTargetsOnlineFirst'),
        dedupeTargetsByAgentId: any(named: 'dedupeTargetsByAgentId'),
        mergeAllConcurrencyOverride: any(named: 'mergeAllConcurrencyOverride'),
      ),
    ).captured;
    final catalogFilter = captured[0] as CadastroFilialFilter;
    final selectedAgentIds = captured[1] as Set<String>;
    check(
      catalogFilter.selectedBranches,
    ).has((branches) => branches.length, 'length').equals(1);
    final branch = catalogFilter.selectedBranches.single;
    check(branch.agentId).equals('agent-a');
    check(branch.codEmpresa).equals(1);
    check(branch.codFilial).equals(1);
    check(selectedAgentIds).deepEquals(<String>{'agent-a'});
  });

  test(
    'consulta catalogo uma vez quando varias filiais do mesmo agente estao selecionadas',
    () async {
      _stubCatalogReport(
        loadCadastroAcrossAgents,
        _catalogReport(
          plannedTargets: <AgentQueryTarget>[_target('agent-a')],
          participants: <AgentQueryExecutionParticipant<CadastroFilialRow>>[
            _catalogParticipant(
              'agent-a',
              rows: <CadastroFilialRow>[_catalogRow(nomeFilial: 'Loja 1')],
            ),
          ],
        ),
      );
      _stubReport(
        loadAcrossAgents,
        _report(
          plannedTargets: <AgentQueryTarget>[_target('agent-a')],
          participants:
              <
                AgentQueryExecutionParticipant<
                  ResumoTotalVendasMunicipioFilialPeriodoRow
                >
              >[
                _participant(
                  'agent-a',
                  rows: <ResumoTotalVendasMunicipioFilialPeriodoRow>[
                    _row(totalVenda: 100),
                  ],
                ),
              ],
        ),
      );

      await useCase(
        userId: userId,
        filter: SalesLiveMapFilter(
          selectedBranchIds: <SalesLiveMapBranchRef>{
            const SalesLiveMapBranchRef(
              agentId: 'agent-a',
              codEmpresa: 1,
              codFilial: 1,
            ),
            const SalesLiveMapBranchRef(
              agentId: 'agent-a',
              codEmpresa: 1,
              codFilial: 2,
            ),
          },
        ),
      );

      final verification = verify(
        () => loadCadastroAcrossAgents.loadAll(
          userId: 'user-1',
          filter: captureAny(named: 'filter'),
          selectedAgentIds: captureAny(named: 'selectedAgentIds'),
          strategy: any(named: 'strategy'),
          bridgeTimeoutMs: any(named: 'bridgeTimeoutMs'),
          raceMaxSources: any(named: 'raceMaxSources'),
          preResolvedResolution: any(named: 'preResolvedResolution'),
          cancelScope: any(named: 'cancelScope'),
          orderTargetsOnlineFirst: any(named: 'orderTargetsOnlineFirst'),
          dedupeTargetsByAgentId: any(named: 'dedupeTargetsByAgentId'),
          mergeAllConcurrencyOverride: any(named: 'mergeAllConcurrencyOverride'),
        ),
      )..called(1);
      final captured = verification.captured;
      final catalogFilter = captured[0] as CadastroFilialFilter;
      final selectedAgentIds = captured[1] as Set<String>;
      check(
        catalogFilter.selectedBranches
            .map(
              (branch) =>
                  '${branch.agentId}:${branch.codEmpresa}:${branch.codFilial}',
            )
            .toList(),
      ).deepEquals(<String>['agent-a:1:1']);
      check(selectedAgentIds).deepEquals(<String>{'agent-a'});
    },
  );

  test(
    'deriva um unico escopo de agentes do catalogo a partir das filiais selecionadas',
    () async {
      _stubCatalogReport(
        loadCadastroAcrossAgents,
        _catalogReport(
          plannedTargets: <AgentQueryTarget>[
            _target('agent-a'),
            _target('agent-b'),
          ],
          participants: <AgentQueryExecutionParticipant<CadastroFilialRow>>[
            _catalogParticipant(
              'agent-a',
              rows: <CadastroFilialRow>[_catalogRow(nomeFilial: 'Loja A')],
            ),
            _catalogParticipant(
              'agent-b',
              rows: <CadastroFilialRow>[
                _catalogRow(nomeFilial: 'Loja B'),
              ],
            ),
          ],
        ),
      );
      _stubReport(
        loadAcrossAgents,
        _report(
          plannedTargets: <AgentQueryTarget>[
            _target('agent-a'),
            _target('agent-b'),
          ],
          participants:
              <
                AgentQueryExecutionParticipant<
                  ResumoTotalVendasMunicipioFilialPeriodoRow
                >
              >[
                _participant(
                  'agent-a',
                  rows: <ResumoTotalVendasMunicipioFilialPeriodoRow>[
                    _row(totalVenda: 100),
                  ],
                ),
                _participant(
                  'agent-b',
                  rows: <ResumoTotalVendasMunicipioFilialPeriodoRow>[
                    _row(totalVenda: 220, qtdVendas: 4),
                  ],
                ),
              ],
        ),
      );

      final result = await useCase(
        userId: userId,
        filter: SalesLiveMapFilter(
          selectedAgentIds: const <String>{'agent-a', 'agent-b', 'agent-c'},
          selectedBranchIds: <SalesLiveMapBranchRef>{
            const SalesLiveMapBranchRef(
              agentId: 'agent-a',
              codEmpresa: 1,
              codFilial: 1,
            ),
            const SalesLiveMapBranchRef(
              agentId: 'agent-b',
              codEmpresa: 1,
              codFilial: 1,
            ),
          },
        ),
      );

      check(result.branchOptions.map((branch) => branch.id).toSet()).deepEquals(
        <String>{'agent-a-1-1', 'agent-b-1-1'},
      );

      final verification = verify(
        () => loadCadastroAcrossAgents.loadAll(
          userId: 'user-1',
          filter: any(named: 'filter'),
          selectedAgentIds: captureAny(named: 'selectedAgentIds'),
          strategy: any(named: 'strategy'),
          bridgeTimeoutMs: any(named: 'bridgeTimeoutMs'),
          raceMaxSources: any(named: 'raceMaxSources'),
          preResolvedResolution: any(named: 'preResolvedResolution'),
          cancelScope: any(named: 'cancelScope'),
          orderTargetsOnlineFirst: any(named: 'orderTargetsOnlineFirst'),
          dedupeTargetsByAgentId: any(named: 'dedupeTargetsByAgentId'),
          mergeAllConcurrencyOverride: any(named: 'mergeAllConcurrencyOverride'),
        ),
      )..called(1);
      final selectedAgentIds = verification.captured.single as Set<String>;
      check(selectedAgentIds).deepEquals(<String>{'agent-a', 'agent-b'});
    },
  );

  test('repassa apenas agentes selecionados para reduzir consulta', () async {
    _stubReport(
      loadAcrossAgents,
      _report(
        plannedTargets: <AgentQueryTarget>[_target('agent-a')],
        participants:
            <
              AgentQueryExecutionParticipant<
                ResumoTotalVendasMunicipioFilialPeriodoRow
              >
            >[
              _participant(
                'agent-a',
                rows: <ResumoTotalVendasMunicipioFilialPeriodoRow>[
                  _row(totalVenda: 100),
                ],
              ),
            ],
      ),
    );

    await useCase(
      userId: userId,
      filter: const SalesLiveMapFilter(
        selectedAgentIds: <String>{'agent-a'},
      ),
    );

    final captured = verify(
      () => loadAcrossAgents.call(
        userId: 'user-1',
        filter: any(named: 'filter'),
        selectedAgentIds: captureAny(named: 'selectedAgentIds'),
        strategy: any(named: 'strategy'),
        bridgeTimeoutMs: any(named: 'bridgeTimeoutMs'),
        raceMaxSources: any(named: 'raceMaxSources'),
        preResolvedResolution: any(named: 'preResolvedResolution'),
        cancelScope: any(named: 'cancelScope'),
        orderTargetsOnlineFirst: any(named: 'orderTargetsOnlineFirst'),
        dedupeTargetsByAgentId: any(named: 'dedupeTargetsByAgentId'),
        mergeAllConcurrencyOverride: any(named: 'mergeAllConcurrencyOverride'),
      ),
    ).captured.single;
    check(captured as Set<String>).deepEquals(<String>{'agent-a'});
  });

  test(
    'envia filtro tecnico para empresa 1 filial 1 na consulta padrao',
    () async {
      _stubReport(
        loadAcrossAgents,
        _report(
          plannedTargets: <AgentQueryTarget>[_target('agent-a')],
          participants:
              <
                AgentQueryExecutionParticipant<
                  ResumoTotalVendasMunicipioFilialPeriodoRow
                >
              >[
                _participant(
                  'agent-a',
                  rows: <ResumoTotalVendasMunicipioFilialPeriodoRow>[
                    _row(totalVenda: 100),
                  ],
                ),
              ],
        ),
      );

      await useCase(
        userId: userId,
        filter: const SalesLiveMapFilter(),
      );

      final captured = verify(
        () => loadAcrossAgents.call(
          userId: 'user-1',
          filter: captureAny(named: 'filter'),
          selectedAgentIds: captureAny(named: 'selectedAgentIds'),
          strategy: any(named: 'strategy'),
          bridgeTimeoutMs: any(named: 'bridgeTimeoutMs'),
          raceMaxSources: any(named: 'raceMaxSources'),
          preResolvedResolution: any(named: 'preResolvedResolution'),
          cancelScope: any(named: 'cancelScope'),
          orderTargetsOnlineFirst: any(named: 'orderTargetsOnlineFirst'),
          dedupeTargetsByAgentId: any(named: 'dedupeTargetsByAgentId'),
          mergeAllConcurrencyOverride: any(named: 'mergeAllConcurrencyOverride'),
        ),
      ).captured;
      final queryFilter =
          captured[0] as ResumoTotalVendasMunicipioFilialPeriodoFilter;
      final selectedAgentIds = captured[1] as Set<String>?;

      check(queryFilter.codEmpresa).equals(1);
      check(queryFilter.codFilial).equals(1);
      check(queryFilter.selectedBranches).isEmpty();
      check(selectedAgentIds).isNull();
    },
  );

  test(
    'usa filiais selecionadas para reduzir agentes e SQL do resumo',
    () async {
      _stubReport(
        loadAcrossAgents,
        _report(
          plannedTargets: <AgentQueryTarget>[_target('agent-a')],
          participants:
              <
                AgentQueryExecutionParticipant<
                  ResumoTotalVendasMunicipioFilialPeriodoRow
                >
              >[
                _participant(
                  'agent-a',
                  rows: <ResumoTotalVendasMunicipioFilialPeriodoRow>[
                    _row(totalVenda: 100),
                  ],
                ),
              ],
        ),
      );

      await useCase(
        userId: userId,
        filter: SalesLiveMapFilter(
          selectedBranchIds: <SalesLiveMapBranchRef>{
            const SalesLiveMapBranchRef(
              agentId: 'agent-a',
              codEmpresa: 1,
              codFilial: 1,
            ),
          },
        ),
      );

      final captured = verify(
        () => loadAcrossAgents.call(
          userId: 'user-1',
          filter: captureAny(named: 'filter'),
          selectedAgentIds: captureAny(named: 'selectedAgentIds'),
          strategy: any(named: 'strategy'),
          bridgeTimeoutMs: any(named: 'bridgeTimeoutMs'),
          raceMaxSources: any(named: 'raceMaxSources'),
          preResolvedResolution: any(named: 'preResolvedResolution'),
          cancelScope: any(named: 'cancelScope'),
          orderTargetsOnlineFirst: any(named: 'orderTargetsOnlineFirst'),
          dedupeTargetsByAgentId: any(named: 'dedupeTargetsByAgentId'),
          mergeAllConcurrencyOverride: any(named: 'mergeAllConcurrencyOverride'),
        ),
      ).captured;
      final queryFilter =
          captured[0] as ResumoTotalVendasMunicipioFilialPeriodoFilter;
      final selectedAgentIds = captured[1] as Set<String>;

      check(queryFilter.codEmpresa).equals(1);
      check(queryFilter.codFilial).equals(1);
      check(selectedAgentIds).deepEquals(<String>{'agent-a'});
      check(queryFilter.selectedBranches)
          .has((it) => it.length, 'length')
          .equals(
            1,
          );
      final branch = queryFilter.selectedBranches.single;
      check(branch.agentId).equals('agent-a');
      check(branch.codEmpresa).equals(1);
      check(branch.codFilial).equals(1);
    },
  );

  test('resolve ponto por CodigoIBGEMunicipioFilial', () async {
    _stubReport(
      loadAcrossAgents,
      _report(
        plannedTargets: <AgentQueryTarget>[_target('agent-a')],
        participants:
            <
              AgentQueryExecutionParticipant<
                ResumoTotalVendasMunicipioFilialPeriodoRow
              >
            >[
              _participant(
                'agent-a',
                rows: <ResumoTotalVendasMunicipioFilialPeriodoRow>[
                  _row(
                    nomeMunicipioFilial: "ALTA FLORESTA D'OESTE",
                    ufMunicipioFilial: 'RO',
                    codigoIbgeMunicipioFilial: '1100015',
                  ),
                ],
              ),
            ],
      ),
    );

    final result = await useCase(
      userId: userId,
      filter: const SalesLiveMapFilter(),
    );

    final point = result.points.single;
    check(point.uf).equals('RO');
    check(point.latitude).equals(-11.9355403047646);
    check(point.longitude).equals(-61.9998238962936);
    check(point.municipalityCode).equals('1100015');
    check(point.locationResolution).equals(
      SalesLiveMapLocationResolution.ibgeMunicipalityCode,
    );
    check(result.mappedMunicipalityCount).equals(1);
    check(
      result.locationDiagnostics.resolvedByIbgeMunicipalityCodeCount,
    ).equals(1);
    check(result.locationDiagnostics.unresolvedBranchCount).equals(0);
    check(geocoder.lookups.map((input) => input.type).toList()).deepEquals(
      <AppLocationLookupType>[AppLocationLookupType.ibgeMunicipalityCode],
    );
    check(cacheStore.writeCount).equals(0);
  });

  test('ignora linhas sem UF ou coordenada resolvivel', () async {
    _stubReport(
      loadAcrossAgents,
      _report(
        plannedTargets: <AgentQueryTarget>[_target('agent-a')],
        participants:
            <
              AgentQueryExecutionParticipant<
                ResumoTotalVendasMunicipioFilialPeriodoRow
              >
            >[
              _participant(
                'agent-a',
                rows: <ResumoTotalVendasMunicipioFilialPeriodoRow>[
                  _row(
                    nomeMunicipioFilial: 'Municipio sem cadastro',
                    ufMunicipioFilial: 'XX',
                    codigoIbgeMunicipioFilial: null,
                  ),
                ],
              ),
            ],
      ),
    );

    final result = await useCase(
      userId: userId,
      filter: const SalesLiveMapFilter(),
    );

    check(result.totalBranchCount).equals(1);
    check(result.mappedBranchCount).equals(0);
    check(result.mappedMunicipalityCount).equals(0);
    check(result.points).isEmpty();
    check(result.unmappedBranchOptions.single.name).equals('Loja matriz');
    check(result.unmappedBranchOptions.single.agentName).equals(
      'Agente agent-a',
    );
    check(result.hasPartialIssue).isTrue();
  });

  test(
    'nao posiciona filial no centro da UF sem municipio resolvivel',
    () async {
      _stubReport(
        loadAcrossAgents,
        _report(
          plannedTargets: <AgentQueryTarget>[_target('agent-a')],
          participants:
              <
                AgentQueryExecutionParticipant<
                  ResumoTotalVendasMunicipioFilialPeriodoRow
                >
              >[
                _participant(
                  'agent-a',
                  rows: <ResumoTotalVendasMunicipioFilialPeriodoRow>[
                    _row(
                      nomeMunicipioFilial: 'Municipio sem cadastro',
                      codigoIbgeMunicipioFilial: null,
                    ),
                  ],
                ),
              ],
        ),
      );

      final result = await useCase(
        userId: userId,
        filter: const SalesLiveMapFilter(),
      );

      check(result.totalBranchCount).equals(1);
      check(result.mappedBranchCount).equals(0);
      check(result.points).isEmpty();
      check(result.unmappedBranchOptions.single.name).equals('Loja matriz');
      check(result.unmappedBranchOptions.single.city).equals(
        'Municipio sem cadastro',
      );
      check(result.unmappedBranchOptions.single.uf).equals('MT');
      check(result.locationDiagnostics.resolvedByStateUfCount).equals(0);
      check(result.locationDiagnostics.unresolvedBranchCount).equals(1);
      check(geocoder.lookups.map((input) => input.type).toList()).deepEquals(
        <AppLocationLookupType>[
          AppLocationLookupType.cityUf,
          AppLocationLookupType.cityUf,
        ],
      );
    },
  );

  test('calcula KPIs e falhas parciais do report', () async {
    _stubReport(
      loadAcrossAgents,
      _report(
        plannedTargets: <AgentQueryTarget>[
          _target('agent-a'),
          _target('agent-b'),
        ],
        missingClientTokenTargets: <AgentQueryTarget>[
          _target('agent-c', clientToken: null),
        ],
        skippedDueToHubPresenceTargets: <AgentQueryTarget>[
          _target('agent-d'),
        ],
        participants:
            <
              AgentQueryExecutionParticipant<
                ResumoTotalVendasMunicipioFilialPeriodoRow
              >
            >[
              _participant(
                'agent-a',
                rows: <ResumoTotalVendasMunicipioFilialPeriodoRow>[
                  _row(totalVenda: 90, qtdVendas: 2),
                ],
              ),
              _participant(
                'agent-b',
                rows: const <ResumoTotalVendasMunicipioFilialPeriodoRow>[],
                failure: const NetworkFailure(
                  message: 'down',
                  userMessage: 'Agente indisponivel.',
                ),
              ),
            ],
      ),
    );

    final result = await useCase(
      userId: userId,
      filter: const SalesLiveMapFilter(),
    );

    check(result.totalRevenue).equals(90);
    check(result.totalSalesCount).equals(2);
    check(result.mappedMunicipalityCount).equals(1);
    check(result.queriedAgentCount).equals(2);
    check(result.plannedAgentCount).equals(2);
    check(result.salesAgentCount).equals(1);
    check(result.noSalesAgentOptions).isEmpty();
    check(result.failedAgentCount).equals(1);
    check(result.missingClientTokenAgentCount).equals(1);
    check(result.skippedOfflineAgentCount).equals(1);
    check(result.hasPartialIssue).isTrue();
    check(result.refreshedAt).equals(now);
  });

  test(
    'calcula agentes com vendas e sem vendas sem misturar falhas',
    () async {
      _stubReport(
        loadAcrossAgents,
        _report(
          plannedTargets: <AgentQueryTarget>[
            _target('agent-a'),
            _target('agent-b'),
            _target('agent-c'),
          ],
          missingClientTokenTargets: <AgentQueryTarget>[
            _target('agent-d', clientToken: null),
          ],
          skippedDueToHubPresenceTargets: <AgentQueryTarget>[
            _target('agent-e'),
          ],
          participants:
              <
                AgentQueryExecutionParticipant<
                  ResumoTotalVendasMunicipioFilialPeriodoRow
                >
              >[
                _participant(
                  'agent-a',
                  rows: <ResumoTotalVendasMunicipioFilialPeriodoRow>[
                    _row(totalVenda: 90, qtdVendas: 2),
                  ],
                ),
                _participant(
                  'agent-b',
                  rows: const <ResumoTotalVendasMunicipioFilialPeriodoRow>[],
                ),
                _participant(
                  'agent-c',
                  rows: const <ResumoTotalVendasMunicipioFilialPeriodoRow>[],
                  failure: const NetworkFailure(
                    message: 'down',
                    userMessage: 'Agente indisponivel.',
                  ),
                ),
              ],
        ),
      );

      final result = await useCase(
        userId: userId,
        filter: const SalesLiveMapFilter(),
      );

      check(result.salesAgentCount).equals(1);
      check(
        result.noSalesAgentOptions.map((agent) => agent.id).toList(),
      ).deepEquals(<String>['agent-b']);
      check(result.noSalesAgentOptions.single.name).equals('Agente agent-b');
      check(result.failedAgentCount).equals(1);
      check(result.missingClientTokenAgentCount).equals(1);
      check(result.skippedOfflineAgentCount).equals(1);
      check(result.hasPartialIssue).isTrue();
    },
  );

  test(
    'mantem filiais do cadastro zeradas quando a consulta de vendas falha',
    () async {
      _stubCatalogReport(
        loadCadastroAcrossAgents,
        _catalogReport(
          plannedTargets: <AgentQueryTarget>[_target('agent-a')],
          participants: <AgentQueryExecutionParticipant<CadastroFilialRow>>[
            _catalogParticipant(
              'agent-a',
              rows: <CadastroFilialRow>[_catalogRow()],
            ),
          ],
        ),
      );
      _stubSalesFailure(loadAcrossAgents);

      final result = await useCase(
        userId: userId,
        filter: const SalesLiveMapFilter(),
      );

      check(result.points).has((points) => points.length, 'length').equals(1);
      check(result.points.single.salesAmount).equals(0);
      check(result.points.single.salesCount).equals(0);
      check(result.points.single.salesDataUnavailable).isTrue();
      check(result.points.single.salesDataStatusLabel).equals(
        'Vendas indisponiveis.',
      );
      check(result.failedSalesAgentCount).equals(1);
      check(result.failedAgentCount).equals(1);
      check(result.zeroedBranchCount).equals(1);
      check(result.noSalesBranchCount).equals(0);
      check(result.salesUnavailableBranchCount).equals(1);
      check(result.hasPartialIssue).isTrue();
    },
  );

  test(
    'usa cadastros bem sucedidos quando o cadastro falha parcialmente',
    () async {
      _stubCatalogReport(
        loadCadastroAcrossAgents,
        _catalogReport(
          plannedTargets: <AgentQueryTarget>[
            _target('agent-a'),
            _target('agent-b'),
          ],
          participants: <AgentQueryExecutionParticipant<CadastroFilialRow>>[
            _catalogParticipant(
              'agent-a',
              rows: <CadastroFilialRow>[_catalogRow()],
            ),
            _catalogParticipant(
              'agent-b',
              rows: const <CadastroFilialRow>[],
              failure: const NetworkFailure(
                message: 'down',
                userMessage: 'Cadastro indisponivel.',
              ),
            ),
          ],
        ),
      );
      _stubReport(
        loadAcrossAgents,
        _report(
          plannedTargets: <AgentQueryTarget>[
            _target('agent-a'),
            _target('agent-b'),
          ],
          participants:
              <
                AgentQueryExecutionParticipant<
                  ResumoTotalVendasMunicipioFilialPeriodoRow
                >
              >[
                _participant(
                  'agent-a',
                  rows: <ResumoTotalVendasMunicipioFilialPeriodoRow>[
                    _row(totalVenda: 100),
                  ],
                ),
                _participant(
                  'agent-b',
                  rows: <ResumoTotalVendasMunicipioFilialPeriodoRow>[
                    _row(totalVenda: 200),
                  ],
                ),
              ],
        ),
      );

      final result = await useCase(
        userId: userId,
        filter: const SalesLiveMapFilter(),
      );

      check(result.points.map((point) => point.id).toList()).deepEquals(
        <String>['agent-a-1-1'],
      );
      check(result.totalRevenue).equals(100);
      check(result.failedCatalogAgentCount).equals(1);
      check(result.failedAgentCount).equals(1);
      check(result.hasPartialIssue).isTrue();
    },
  );

  test(
    'sinaliza consulta possivelmente truncada pelo limite de linhas',
    () async {
      _stubReport(
        loadAcrossAgents,
        _report(
          plannedTargets: <AgentQueryTarget>[_target('agent-a')],
          participants:
              <
                AgentQueryExecutionParticipant<
                  ResumoTotalVendasMunicipioFilialPeriodoRow
                >
              >[
                _participant(
                  'agent-a',
                  rows: List<ResumoTotalVendasMunicipioFilialPeriodoRow>.filled(
                    1,
                    _row(totalVenda: 1),
                  ),
                  sourceRowCount: AgentQueriesBoundedResultMaxRows
                      .resumoTotalVendasMunicipioFilialPeriodo,
                ),
              ],
        ),
      );

      final result = await useCase(
        userId: userId,
        filter: const SalesLiveMapFilter(),
      );

      check(result.rowCapReachedAgentCount).equals(1);
      check(result.hasPartialIssue).isTrue();
    },
  );

  test(
    'mantem venda de filial sem municipio como nao mapeada',
    () async {
      _stubReport(
        loadAcrossAgents,
        _report(
          plannedTargets: <AgentQueryTarget>[_target('agent-a')],
          participants:
              <
                AgentQueryExecutionParticipant<
                  ResumoTotalVendasMunicipioFilialPeriodoRow
                >
              >[
                _participant(
                  'agent-a',
                  rows: <ResumoTotalVendasMunicipioFilialPeriodoRow>[
                    _row(
                      nomeMunicipioFilial: null,
                      ufMunicipioFilial: null,
                      codigoIbgeMunicipioFilial: null,
                      totalVenda: 450,
                      qtdVendas: 7,
                    ),
                  ],
                ),
              ],
        ),
      );

      final result = await useCase(
        userId: userId,
        filter: const SalesLiveMapFilter(),
      );

      check(result.totalRevenue).equals(450);
      check(result.totalSalesCount).equals(7);
      check(result.totalBranchCount).equals(1);
      check(result.mappedBranchCount).equals(0);
      check(result.points).isEmpty();
      check(
        result.branchOptions.single.city,
      ).equals(SalesLiveMapInternalLabels.missingMunicipalityCity);
      check(result.branchOptions.single.uf).equals('--');
      check(result.locationDiagnostics.unresolvedBranchCount).equals(1);
    },
  );

  test(
    'reutiliza cache de geolocalizacao por filial entre refreshes',
    () async {
      _stubReport(
        loadAcrossAgents,
        _report(
          plannedTargets: <AgentQueryTarget>[_target('agent-a')],
          participants:
              <
                AgentQueryExecutionParticipant<
                  ResumoTotalVendasMunicipioFilialPeriodoRow
                >
              >[
                _participant(
                  'agent-a',
                  rows: <ResumoTotalVendasMunicipioFilialPeriodoRow>[
                    _row(totalVenda: 100),
                  ],
                ),
              ],
        ),
      );

      final first = await useCase(
        userId: userId,
        filter: const SalesLiveMapFilter(),
      );
      final second = await useCase(
        userId: userId,
        filter: const SalesLiveMapFilter(),
      );

      check(first.points.single.salesAmount).equals(100);
      check(second.points.single.salesAmount).equals(100);
      check(second.points.single.fantasyName).equals('Loja matriz');
      check(second.points.single.branchName).equals('Loja matriz');
      check(second.points.single.companyCode).equals(1);
      check(second.points.single.branchCode).equals(1);
      check(second.points.single.agentName).equals('Agente agent-a');
      check(geocoder.lookups).has((it) => it.length, 'length').equals(1);
    },
  );

  test(
    'hidrata o cache em memoria e evita nova consulta de catalogo apos snapshot fresco em disco',
    () async {
      final diskCatalog = CadastroFilialAcrossAgentsPageResult.fromReport(
        _catalogReport(
          plannedTargets: <AgentQueryTarget>[_target('agent-a')],
          participants: <AgentQueryExecutionParticipant<CadastroFilialRow>>[
            _catalogParticipant(
              'agent-a',
              rows: <CadastroFilialRow>[_catalogRow()],
            ),
          ],
        ),
      );
      var diskEnabled = true;
      final exactScope = SalesLiveMapCatalogScope.branchSubset(
        selectedBranches: const <CadastroFilialBranchRef>[
          CadastroFilialBranchRef(
            agentId: 'agent-a',
            codEmpresa: 1,
            codFilial: 1,
          ),
        ],
      );
      when(
        () => catalogDiskCache.readIfFresh(
          userId: any(named: 'userId'),
          scope: any(named: 'scope'),
          now: any(named: 'now'),
        ),
      ).thenAnswer((invocation) {
        final scope =
            invocation.namedArguments[#scope] as SalesLiveMapCatalogScope;
        if (diskEnabled && scope.storageKey == exactScope.storageKey) {
          return diskCatalog;
        }
        return null;
      });
      _stubReport(
        loadAcrossAgents,
        _report(
          plannedTargets: <AgentQueryTarget>[_target('agent-a')],
          participants:
              <
                AgentQueryExecutionParticipant<
                  ResumoTotalVendasMunicipioFilialPeriodoRow
                >
              >[
                _participant(
                  'agent-a',
                  rows: <ResumoTotalVendasMunicipioFilialPeriodoRow>[
                    _row(totalVenda: 100),
                  ],
                ),
              ],
        ),
      );

      final filter = SalesLiveMapFilter(
        selectedAgentIds: const <String>{'agent-a', 'agent-b'},
        selectedBranchIds: <SalesLiveMapBranchRef>{
          const SalesLiveMapBranchRef(
            agentId: 'agent-a',
            codEmpresa: 1,
            codFilial: 1,
          ),
        },
      );

      await useCase(userId: userId, filter: filter);
      diskEnabled = false;
      await useCase(userId: userId, filter: filter);

      final readVerification = verify(
        () => catalogDiskCache.readIfFresh(
          userId: 'user-1',
          scope: captureAny(named: 'scope'),
          now: now,
        ),
      )..called(1);
      check(
        readVerification.captured
            .cast<SalesLiveMapCatalogScope>()
            .map((scope) => scope.storageKey)
            .toList(),
      ).deepEquals(
        <String>[exactScope.storageKey],
      );
      verifyNever(
        () => loadCadastroAcrossAgents.loadAll(
          userId: any(named: 'userId'),
          filter: any(named: 'filter'),
          selectedAgentIds: any(named: 'selectedAgentIds'),
          strategy: any(named: 'strategy'),
          bridgeTimeoutMs: any(named: 'bridgeTimeoutMs'),
          raceMaxSources: any(named: 'raceMaxSources'),
          preResolvedResolution: any(named: 'preResolvedResolution'),
          cancelScope: any(named: 'cancelScope'),
          orderTargetsOnlineFirst: any(named: 'orderTargetsOnlineFirst'),
          dedupeTargetsByAgentId: any(named: 'dedupeTargetsByAgentId'),
          mergeAllConcurrencyOverride: any(named: 'mergeAllConcurrencyOverride'),
        ),
      );
      verify(
        () => loadAcrossAgents.call(
          userId: 'user-1',
          filter: any(named: 'filter'),
          selectedAgentIds: any(named: 'selectedAgentIds'),
          strategy: any(named: 'strategy'),
          bridgeTimeoutMs: any(named: 'bridgeTimeoutMs'),
          raceMaxSources: any(named: 'raceMaxSources'),
          preResolvedResolution: any(named: 'preResolvedResolution'),
          cancelScope: any(named: 'cancelScope'),
          orderTargetsOnlineFirst: any(named: 'orderTargetsOnlineFirst'),
          dedupeTargetsByAgentId: any(named: 'dedupeTargetsByAgentId'),
          mergeAllConcurrencyOverride: any(named: 'mergeAllConcurrencyOverride'),
        ),
      ).called(2);
      check(refreshMetrics.latest).isNotNull();
      check(refreshMetrics.latest!.catalogSource).equals(
        SalesLiveMapCatalogSource.memory,
      );
      check(refreshMetrics.latest!.reloadReason).equals(
        SalesLiveMapReloadReason.manual,
      );
    },
  );

  test(
    'reutiliza snapshot v2 fullAgent do disk cache para atender branchSubset com broaderCacheFiltered',
    () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final prefs = await SharedPreferences.getInstance();
      final realDiskCache = SalesLiveMapCatalogDiskCache(prefs);
      final localMetrics = SalesLiveMapRefreshMetrics();
      final localUseCase = buildUseCaseWithDiskCache(
        realDiskCache,
        metrics: localMetrics,
      );
      final fullScope = SalesLiveMapCatalogScope.fullAgent(
        agentIds: const <String>{'agent-a'},
      );
      await realDiskCache.write(
        userId: userId,
        scope: fullScope,
        now: now,
        result: CadastroFilialAcrossAgentsPageResult.fromReport(
          _catalogReport(
            plannedTargets: <AgentQueryTarget>[_target('agent-a')],
            participants: <AgentQueryExecutionParticipant<CadastroFilialRow>>[
              _catalogParticipant(
                'agent-a',
                rows: <CadastroFilialRow>[
                  _catalogRow(nomeFilial: 'Loja 1'),
                  _catalogRow(codFilial: 2, nomeFilial: 'Loja 2'),
                ],
              ),
            ],
          ),
        ),
      );
      _stubReport(
        loadAcrossAgents,
        _report(
          plannedTargets: <AgentQueryTarget>[_target('agent-a')],
          participants:
              <
                AgentQueryExecutionParticipant<
                  ResumoTotalVendasMunicipioFilialPeriodoRow
                >
              >[
                _participant(
                  'agent-a',
                  rows: <ResumoTotalVendasMunicipioFilialPeriodoRow>[
                    _row(totalVenda: 100),
                  ],
                ),
              ],
        ),
      );

      final result = await localUseCase(
        userId: userId,
        filter: SalesLiveMapFilter(
          selectedBranchIds: <SalesLiveMapBranchRef>{
            const SalesLiveMapBranchRef(
              agentId: 'agent-a',
              codEmpresa: 1,
              codFilial: 2,
            ),
          },
        ),
        reason: SalesLiveMapReloadReason.autoRefresh,
      );

      check(
        result.branchOptions.map((branch) => branch.id).toList(),
      ).deepEquals(
        <String>['agent-a-1-2'],
      );
      verifyNever(
        () => loadCadastroAcrossAgents.loadAll(
          userId: any(named: 'userId'),
          filter: any(named: 'filter'),
          selectedAgentIds: any(named: 'selectedAgentIds'),
          strategy: any(named: 'strategy'),
          bridgeTimeoutMs: any(named: 'bridgeTimeoutMs'),
          raceMaxSources: any(named: 'raceMaxSources'),
          preResolvedResolution: any(named: 'preResolvedResolution'),
          cancelScope: any(named: 'cancelScope'),
          orderTargetsOnlineFirst: any(named: 'orderTargetsOnlineFirst'),
          dedupeTargetsByAgentId: any(named: 'dedupeTargetsByAgentId'),
          mergeAllConcurrencyOverride: any(named: 'mergeAllConcurrencyOverride'),
        ),
      );
      check(localMetrics.latest).isNotNull();
      check(localMetrics.latest!.catalogSource).equals(
        SalesLiveMapCatalogSource.broaderCacheFiltered,
      );
      check(localMetrics.latest!.reloadReason).equals(
        SalesLiveMapReloadReason.autoRefresh,
      );
    },
  );

  test('decodifica snapshot v2 branchSubset exato do disk cache', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final prefs = await SharedPreferences.getInstance();
    final realDiskCache = SalesLiveMapCatalogDiskCache(prefs);
    final localMetrics = SalesLiveMapRefreshMetrics();
    final localUseCase = buildUseCaseWithDiskCache(
      realDiskCache,
      metrics: localMetrics,
    );
    final scope = SalesLiveMapCatalogScope.branchSubset(
      selectedBranches: const <CadastroFilialBranchRef>[
        CadastroFilialBranchRef(
          agentId: 'agent-a',
          codEmpresa: 1,
          codFilial: 1,
        ),
      ],
    );
    await realDiskCache.write(
      userId: userId,
      scope: scope,
      now: now,
      result: CadastroFilialAcrossAgentsPageResult.fromReport(
        _catalogReport(
          plannedTargets: <AgentQueryTarget>[_target('agent-a')],
          participants: <AgentQueryExecutionParticipant<CadastroFilialRow>>[
            _catalogParticipant(
              'agent-a',
              rows: <CadastroFilialRow>[_catalogRow(nomeFilial: 'Loja 1')],
            ),
          ],
        ),
      ),
    );
    _stubReport(
      loadAcrossAgents,
      _report(
        plannedTargets: <AgentQueryTarget>[_target('agent-a')],
        participants:
            <
              AgentQueryExecutionParticipant<
                ResumoTotalVendasMunicipioFilialPeriodoRow
              >
            >[
              _participant(
                'agent-a',
                rows: <ResumoTotalVendasMunicipioFilialPeriodoRow>[
                  _row(totalVenda: 100),
                ],
              ),
            ],
      ),
    );

    final result = await localUseCase(
      userId: userId,
      filter: SalesLiveMapFilter(
        selectedBranchIds: <SalesLiveMapBranchRef>{
          const SalesLiveMapBranchRef(
            agentId: 'agent-a',
            codEmpresa: 1,
            codFilial: 1,
          ),
        },
      ),
    );

    check(result.branchOptions.map((branch) => branch.id).toSet()).deepEquals(
      <String>{'agent-a-1-1'},
    );
    verifyNever(
      () => loadCadastroAcrossAgents.loadAll(
        userId: any(named: 'userId'),
        filter: any(named: 'filter'),
        selectedAgentIds: any(named: 'selectedAgentIds'),
        strategy: any(named: 'strategy'),
        bridgeTimeoutMs: any(named: 'bridgeTimeoutMs'),
        raceMaxSources: any(named: 'raceMaxSources'),
        preResolvedResolution: any(named: 'preResolvedResolution'),
        cancelScope: any(named: 'cancelScope'),
        orderTargetsOnlineFirst: any(named: 'orderTargetsOnlineFirst'),
        dedupeTargetsByAgentId: any(named: 'dedupeTargetsByAgentId'),
        mergeAllConcurrencyOverride: any(named: 'mergeAllConcurrencyOverride'),
      ),
    );
    check(localMetrics.latest).isNotNull();
    check(localMetrics.latest!.catalogSource).equals(
      SalesLiveMapCatalogSource.disk,
    );
  });

  test('decodifica snapshot legacy v1 como fullAgent do disk cache', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final prefs = await SharedPreferences.getInstance();
    final agentSignature = SalesLiveMapCatalogScope.agentSignatureOf(
      const <String>{'agent-a'},
    );
    final legacyKey =
        'colmeia_sales_live_map_catalog_v1.$userId|1|1|$agentSignature';
    await prefs.setString(
      legacyKey,
      jsonEncode(<String, Object?>{
        'v': 1,
        'cachedAtMs': now.millisecondsSinceEpoch,
        'participants': <Object?>[
          <String, Object?>{
            'agentId': 'agent-a',
            'displayName': 'Agente agent-a',
            'elapsedMs': 0,
            'rows': <Object?>[
              <String, Object?>{
                'ce': 1,
                'cf': 1,
                'nf': 'Loja 1',
                'fa': 'Fantasia 1',
                'cp': '78000123',
                'nm': 'Cuiaba',
                'uf': 'MT',
                'ib': '5103403',
              },
            ],
          },
        ],
      }),
    );
    final realDiskCache = SalesLiveMapCatalogDiskCache(prefs);
    final localMetrics = SalesLiveMapRefreshMetrics();
    final localUseCase = buildUseCaseWithDiskCache(
      realDiskCache,
      metrics: localMetrics,
    );
    _stubReport(
      loadAcrossAgents,
      _report(
        plannedTargets: <AgentQueryTarget>[_target('agent-a')],
        participants:
            <
              AgentQueryExecutionParticipant<
                ResumoTotalVendasMunicipioFilialPeriodoRow
              >
            >[
              _participant(
                'agent-a',
                rows: <ResumoTotalVendasMunicipioFilialPeriodoRow>[
                  _row(totalVenda: 100),
                ],
              ),
            ],
      ),
    );

    final result = await localUseCase(
      userId: userId,
      filter: const SalesLiveMapFilter(
        selectedAgentIds: <String>{'agent-a'},
      ),
    );

    check(result.branchOptions.map((branch) => branch.id).toSet()).deepEquals(
      <String>{'agent-a-1-1'},
    );
    verifyNever(
      () => loadCadastroAcrossAgents.loadAll(
        userId: any(named: 'userId'),
        filter: any(named: 'filter'),
        selectedAgentIds: any(named: 'selectedAgentIds'),
        strategy: any(named: 'strategy'),
        bridgeTimeoutMs: any(named: 'bridgeTimeoutMs'),
        raceMaxSources: any(named: 'raceMaxSources'),
        preResolvedResolution: any(named: 'preResolvedResolution'),
        cancelScope: any(named: 'cancelScope'),
        orderTargetsOnlineFirst: any(named: 'orderTargetsOnlineFirst'),
        dedupeTargetsByAgentId: any(named: 'dedupeTargetsByAgentId'),
        mergeAllConcurrencyOverride: any(named: 'mergeAllConcurrencyOverride'),
      ),
    );
    check(localMetrics.latest).isNotNull();
    check(localMetrics.latest!.catalogSource).equals(
      SalesLiveMapCatalogSource.disk,
    );
  });

  test(
    'nao grava nem reutiliza snapshot parcial como catalogo global de um escopo mais amplo',
    () async {
      final diskEntries = <String, CadastroFilialAcrossAgentsPageResult>{};
      when(
        () => catalogDiskCache.readIfFresh(
          userId: any(named: 'userId'),
          scope: any(named: 'scope'),
          now: any(named: 'now'),
        ),
      ).thenAnswer((invocation) {
        final scope =
            invocation.namedArguments[#scope] as SalesLiveMapCatalogScope;
        return diskEntries[scope.storageKey];
      });
      when(
        () => catalogDiskCache.write(
          userId: any(named: 'userId'),
          scope: any(named: 'scope'),
          now: any(named: 'now'),
          result: any(named: 'result'),
        ),
      ).thenAnswer((invocation) async {
        final scope =
            invocation.namedArguments[#scope] as SalesLiveMapCatalogScope;
        final result =
            invocation.namedArguments[#result]
                as CadastroFilialAcrossAgentsPageResult;
        diskEntries[scope.storageKey] = result;
      });
      _stubCatalogReport(
        loadCadastroAcrossAgents,
        _catalogReport(
          plannedTargets: <AgentQueryTarget>[_target('agent-a')],
          participants: <AgentQueryExecutionParticipant<CadastroFilialRow>>[
            _catalogParticipant(
              'agent-a',
              rows: <CadastroFilialRow>[_catalogRow()],
            ),
          ],
        ),
      );
      _stubReport(
        loadAcrossAgents,
        _report(
          plannedTargets: <AgentQueryTarget>[_target('agent-a')],
          participants:
              <
                AgentQueryExecutionParticipant<
                  ResumoTotalVendasMunicipioFilialPeriodoRow
                >
              >[
                _participant(
                  'agent-a',
                  rows: <ResumoTotalVendasMunicipioFilialPeriodoRow>[
                    _row(totalVenda: 100),
                  ],
                ),
              ],
        ),
      );

      await useCase(
        userId: userId,
        filter: SalesLiveMapFilter(
          selectedAgentIds: const <String>{'agent-a', 'agent-b'},
          selectedBranchIds: <SalesLiveMapBranchRef>{
            const SalesLiveMapBranchRef(
              agentId: 'agent-a',
              codEmpresa: 1,
              codFilial: 1,
            ),
          },
        ),
      );

      check(diskEntries.keys).deepEquals(
        <String>[
          SalesLiveMapCatalogScope.branchSubset(
            selectedBranches: const <CadastroFilialBranchRef>[
              CadastroFilialBranchRef(
                agentId: 'agent-a',
                codEmpresa: 1,
                codFilial: 1,
              ),
            ],
          ).storageKey,
        ],
      );

      _stubCatalogReport(
        loadCadastroAcrossAgents,
        _catalogReport(
          plannedTargets: <AgentQueryTarget>[
            _target('agent-a'),
            _target('agent-b'),
          ],
          participants: <AgentQueryExecutionParticipant<CadastroFilialRow>>[
            _catalogParticipant(
              'agent-a',
              rows: <CadastroFilialRow>[_catalogRow(nomeFilial: 'Loja A')],
            ),
            _catalogParticipant(
              'agent-b',
              rows: <CadastroFilialRow>[
                _catalogRow(nomeFilial: 'Loja B'),
              ],
            ),
          ],
        ),
      );
      _stubReport(
        loadAcrossAgents,
        _report(
          plannedTargets: <AgentQueryTarget>[
            _target('agent-a'),
            _target('agent-b'),
          ],
          participants:
              <
                AgentQueryExecutionParticipant<
                  ResumoTotalVendasMunicipioFilialPeriodoRow
                >
              >[
                _participant(
                  'agent-a',
                  rows: <ResumoTotalVendasMunicipioFilialPeriodoRow>[
                    _row(totalVenda: 100),
                  ],
                ),
                _participant(
                  'agent-b',
                  rows: <ResumoTotalVendasMunicipioFilialPeriodoRow>[
                    _row(totalVenda: 200),
                  ],
                ),
              ],
        ),
      );

      final result = await useCase(
        userId: userId,
        filter: const SalesLiveMapFilter(
          selectedAgentIds: <String>{'agent-a', 'agent-b'},
        ),
      );

      check(result.branchOptions.map((branch) => branch.id).toSet()).deepEquals(
        <String>{'agent-a-1-1', 'agent-b-1-1'},
      );
      verify(
        () => loadCadastroAcrossAgents.loadAll(
          userId: any(named: 'userId'),
          filter: any(named: 'filter'),
          selectedAgentIds: any(named: 'selectedAgentIds'),
          strategy: any(named: 'strategy'),
          bridgeTimeoutMs: any(named: 'bridgeTimeoutMs'),
          raceMaxSources: any(named: 'raceMaxSources'),
          preResolvedResolution: any(named: 'preResolvedResolution'),
          cancelScope: any(named: 'cancelScope'),
          orderTargetsOnlineFirst: any(named: 'orderTargetsOnlineFirst'),
          dedupeTargetsByAgentId: any(named: 'dedupeTargetsByAgentId'),
          mergeAllConcurrencyOverride: any(named: 'mergeAllConcurrencyOverride'),
        ),
      ).called(2);
    },
  );

  test(
    'reutiliza cache curto do cadastro entre atualizacoes do mapa',
    () async {
      _stubCatalogReport(
        loadCadastroAcrossAgents,
        _catalogReport(
          plannedTargets: <AgentQueryTarget>[_target('agent-a')],
          participants: <AgentQueryExecutionParticipant<CadastroFilialRow>>[
            _catalogParticipant(
              'agent-a',
              rows: <CadastroFilialRow>[_catalogRow()],
            ),
          ],
        ),
      );
      _stubReport(
        loadAcrossAgents,
        _report(
          plannedTargets: <AgentQueryTarget>[_target('agent-a')],
          participants:
              <
                AgentQueryExecutionParticipant<
                  ResumoTotalVendasMunicipioFilialPeriodoRow
                >
              >[
                _participant(
                  'agent-a',
                  rows: <ResumoTotalVendasMunicipioFilialPeriodoRow>[
                    _row(totalVenda: 100),
                  ],
                ),
              ],
        ),
      );

      await useCase(
        userId: userId,
        filter: const SalesLiveMapFilter(),
      );
      await useCase(
        userId: userId,
        filter: const SalesLiveMapFilter(),
      );

      verify(
        () => loadCadastroAcrossAgents.loadAll(
          userId: 'user-1',
          filter: any(named: 'filter'),
          selectedAgentIds: any(named: 'selectedAgentIds'),
          strategy: any(named: 'strategy'),
          bridgeTimeoutMs: any(named: 'bridgeTimeoutMs'),
          raceMaxSources: any(named: 'raceMaxSources'),
          preResolvedResolution: any(named: 'preResolvedResolution'),
          cancelScope: any(named: 'cancelScope'),
          orderTargetsOnlineFirst: any(named: 'orderTargetsOnlineFirst'),
          dedupeTargetsByAgentId: any(named: 'dedupeTargetsByAgentId'),
          mergeAllConcurrencyOverride: any(named: 'mergeAllConcurrencyOverride'),
        ),
      ).called(1);
      verify(
        () => loadAcrossAgents.call(
          userId: 'user-1',
          filter: any(named: 'filter'),
          selectedAgentIds: any(named: 'selectedAgentIds'),
          strategy: any(named: 'strategy'),
          bridgeTimeoutMs: any(named: 'bridgeTimeoutMs'),
          raceMaxSources: any(named: 'raceMaxSources'),
          preResolvedResolution: any(named: 'preResolvedResolution'),
          cancelScope: any(named: 'cancelScope'),
          orderTargetsOnlineFirst: any(named: 'orderTargetsOnlineFirst'),
          dedupeTargetsByAgentId: any(named: 'dedupeTargetsByAgentId'),
          mergeAllConcurrencyOverride: any(named: 'mergeAllConcurrencyOverride'),
        ),
      ).called(2);
    },
  );

  test(
    'broader catalog cache hit does not inflate planned/missing-token counts',
    () async {
      // First load: fullAgent scope for agents {agent-a, agent-x}. The
      // catalog includes both planned and missing-token targets so the
      // cached page captures a state where agent-x has no usable token.
      _stubCatalogReport(
        loadCadastroAcrossAgents,
        _catalogReport(
          plannedTargets: <AgentQueryTarget>[_target('agent-a')],
          missingClientTokenTargets: <AgentQueryTarget>[
            _target('agent-x', clientToken: null),
          ],
          skippedDueToHubPresenceTargets: <AgentQueryTarget>[_target('agent-y')],
          participants: <AgentQueryExecutionParticipant<CadastroFilialRow>>[
            _catalogParticipant(
              'agent-a',
              rows: <CadastroFilialRow>[_catalogRow(nomeFilial: 'Loja A')],
            ),
          ],
        ),
      );
      _stubReport(
        loadAcrossAgents,
        _report(
          plannedTargets: <AgentQueryTarget>[_target('agent-a')],
          participants:
              <
                AgentQueryExecutionParticipant<
                  ResumoTotalVendasMunicipioFilialPeriodoRow
                >
              >[
                _participant(
                  'agent-a',
                  rows: <ResumoTotalVendasMunicipioFilialPeriodoRow>[
                    _row(totalVenda: 100),
                  ],
                ),
              ],
        ),
      );

      // Prime the in-memory catalog with fullAgent({agent-a}). This is the
      // same scope the next branchSubset call will derive via
      // `compatibleFullAgentScope`, so it can hit broaderCacheFiltered.
      await useCase(
        userId: userId,
        filter: const SalesLiveMapFilter(
          selectedAgentIds: <String>{'agent-a'},
        ),
      );

      // Second load: branch subset under agent-a. The branchSubset scope
      // misses exact memory/disk but the broader fullAgent({agent-a})
      // lookup hits. Before the bug 1.1 fix the resulting metadata would
      // keep `agent-x` (missing token) and `agent-y` (hub-skipped) from
      // the cached broader report, inflating the counters surfaced in
      // the attention panel / KPIs.
      final result = await useCase(
        userId: userId,
        filter: SalesLiveMapFilter(
          selectedBranchIds: <SalesLiveMapBranchRef>{
            const SalesLiveMapBranchRef(
              agentId: 'agent-a',
              codEmpresa: 1,
              codFilial: 1,
            ),
          },
        ),
      );

      expect(
        result.plannedAgentCount,
        1,
        reason: 'should reflect only the agent owning the selected branch',
      );
      expect(
        result.queriedAgentCount,
        1,
        reason: 'only the participant for the selected agent must remain',
      );
      expect(
        result.missingClientTokenAgentCount,
        0,
        reason:
            'missing-token entries from other agents must not leak through '
            'the broader cache filter',
      );
      expect(
        result.skippedOfflineAgentCount,
        0,
        reason:
            'hub-skipped entries from other agents must not leak through '
            'the broader cache filter',
      );
      expect(result.totalBranchCount, 1);
      expect(result.mappedBranchCount, 1);

      // Sanity: the broader lookup must have been used (i.e. the catalog
      // remote loader was called only once, for the first invocation).
      verify(
        () => loadCadastroAcrossAgents.loadAll(
          userId: any(named: 'userId'),
          filter: any(named: 'filter'),
          selectedAgentIds: any(named: 'selectedAgentIds'),
          strategy: any(named: 'strategy'),
          bridgeTimeoutMs: any(named: 'bridgeTimeoutMs'),
          raceMaxSources: any(named: 'raceMaxSources'),
          preResolvedResolution: any(named: 'preResolvedResolution'),
          cancelScope: any(named: 'cancelScope'),
          orderTargetsOnlineFirst: any(named: 'orderTargetsOnlineFirst'),
          dedupeTargetsByAgentId: any(named: 'dedupeTargetsByAgentId'),
          mergeAllConcurrencyOverride: any(named: 'mergeAllConcurrencyOverride'),
        ),
      ).called(1);
    },
  );

  test('cancela processamento local obsoleto antes de geolocalizar', () async {
    final reportCompleter =
        Completer<
          AppResult<
            AgentQueryExecutionReport<
              ResumoTotalVendasMunicipioFilialPeriodoRow
            >
          >
        >();
    when(
      () => loadAcrossAgents.call(
        userId: any(named: 'userId'),
        filter: any(named: 'filter'),
        selectedAgentIds: any(named: 'selectedAgentIds'),
        strategy: any(named: 'strategy'),
        bridgeTimeoutMs: any(named: 'bridgeTimeoutMs'),
        raceMaxSources: any(named: 'raceMaxSources'),
        preResolvedResolution: any(named: 'preResolvedResolution'),
        cancelScope: any(named: 'cancelScope'),
        orderTargetsOnlineFirst: any(named: 'orderTargetsOnlineFirst'),
        dedupeTargetsByAgentId: any(named: 'dedupeTargetsByAgentId'),
        mergeAllConcurrencyOverride: any(named: 'mergeAllConcurrencyOverride'),
      ),
    ).thenAnswer((_) => reportCompleter.future);
    final cancelToken = SalesLiveMapLoadCancelToken();

    final future = useCase(
      userId: userId,
      filter: const SalesLiveMapFilter(),
      cancelToken: cancelToken,
    );
    cancelToken.cancel();
    reportCompleter.complete(
      Success<
        AgentQueryExecutionReport<ResumoTotalVendasMunicipioFilialPeriodoRow>,
        AppFailure
      >(
        _report(
          plannedTargets: <AgentQueryTarget>[_target('agent-a')],
          participants:
              <
                AgentQueryExecutionParticipant<
                  ResumoTotalVendasMunicipioFilialPeriodoRow
                >
              >[
                _participant(
                  'agent-a',
                  rows: <ResumoTotalVendasMunicipioFilialPeriodoRow>[
                    _row(totalVenda: 100),
                  ],
                ),
              ],
        ),
      ),
    );

    final result = await future;

    check(result.cancelled).isTrue();
    check(result.points).isEmpty();
    check(geocoder.lookups).isEmpty();
  });
}

void _stubReport(
  _MockLoadResumoTotalVendasMunicipioFilialPeriodoAcrossAgentsUseCase useCase,
  AgentQueryExecutionReport<ResumoTotalVendasMunicipioFilialPeriodoRow> report,
) {
  _stubReportFuture(
    useCase,
    Future<
      AppResult<
        AgentQueryExecutionReport<ResumoTotalVendasMunicipioFilialPeriodoRow>
      >
    >.value(
      Success<
        AgentQueryExecutionReport<ResumoTotalVendasMunicipioFilialPeriodoRow>,
        AppFailure
      >(report),
    ),
  );
}

void _stubReportFuture(
  _MockLoadResumoTotalVendasMunicipioFilialPeriodoAcrossAgentsUseCase useCase,
  Future<
    AppResult<
      AgentQueryExecutionReport<ResumoTotalVendasMunicipioFilialPeriodoRow>
    >
  >
  result,
) {
  when(
    () => useCase(
      userId: any(named: 'userId'),
      filter: any(named: 'filter'),
      selectedAgentIds: any(named: 'selectedAgentIds'),
      strategy: any(named: 'strategy'),
      bridgeTimeoutMs: any(named: 'bridgeTimeoutMs'),
      raceMaxSources: any(named: 'raceMaxSources'),
      preResolvedResolution: any(named: 'preResolvedResolution'),
      cancelScope: any(named: 'cancelScope'),
      orderTargetsOnlineFirst: any(named: 'orderTargetsOnlineFirst'),
      dedupeTargetsByAgentId: any(named: 'dedupeTargetsByAgentId'),
      mergeAllConcurrencyOverride: any(named: 'mergeAllConcurrencyOverride'),
    ),
  ).thenAnswer((_) => result);
}

void _stubSalesFailure(
  _MockLoadResumoTotalVendasMunicipioFilialPeriodoAcrossAgentsUseCase useCase,
) {
  when(
    () => useCase(
      userId: any(named: 'userId'),
      filter: any(named: 'filter'),
      selectedAgentIds: any(named: 'selectedAgentIds'),
      strategy: any(named: 'strategy'),
      bridgeTimeoutMs: any(named: 'bridgeTimeoutMs'),
      raceMaxSources: any(named: 'raceMaxSources'),
      preResolvedResolution: any(named: 'preResolvedResolution'),
      cancelScope: any(named: 'cancelScope'),
      orderTargetsOnlineFirst: any(named: 'orderTargetsOnlineFirst'),
      dedupeTargetsByAgentId: any(named: 'dedupeTargetsByAgentId'),
      mergeAllConcurrencyOverride: any(named: 'mergeAllConcurrencyOverride'),
    ),
  ).thenAnswer(
    (_) async =>
        const Failure<
          AgentQueryExecutionReport<ResumoTotalVendasMunicipioFilialPeriodoRow>,
          AppFailure
        >(
          NetworkFailure(
            message: 'sales down',
            userMessage: 'Vendas indisponiveis.',
          ),
        ),
  );
}

void _stubCatalogReport(
  _MockLoadCadastroFilialAcrossAgentsUseCase cadastroMock,
  AgentQueryExecutionReport<CadastroFilialRow> report,
) {
  _stubCatalogFuture(
    cadastroMock,
    Future<AppResult<CadastroFilialAcrossAgentsPageResult>>.value(
      Success<CadastroFilialAcrossAgentsPageResult, AppFailure>(
        CadastroFilialAcrossAgentsPageResult.fromReport(report),
      ),
    ),
  );
}

void _stubCatalogFuture(
  _MockLoadCadastroFilialAcrossAgentsUseCase cadastroMock,
  Future<AppResult<CadastroFilialAcrossAgentsPageResult>> result,
) {
  when(
    () => cadastroMock.loadAll(
      userId: any(named: 'userId'),
      filter: any(named: 'filter'),
      selectedAgentIds: any(named: 'selectedAgentIds'),
      strategy: any(named: 'strategy'),
      bridgeTimeoutMs: any(named: 'bridgeTimeoutMs'),
      raceMaxSources: any(named: 'raceMaxSources'),
      preResolvedResolution: any(named: 'preResolvedResolution'),
      cancelScope: any(named: 'cancelScope'),
      orderTargetsOnlineFirst: any(named: 'orderTargetsOnlineFirst'),
      dedupeTargetsByAgentId: any(named: 'dedupeTargetsByAgentId'),
      mergeAllConcurrencyOverride: any(named: 'mergeAllConcurrencyOverride'),
    ),
  ).thenAnswer((_) => result);
}

void _stubCatalogFailure(
  _MockLoadCadastroFilialAcrossAgentsUseCase cadastroMock,
) {
  when(
    () => cadastroMock.loadAll(
      userId: any(named: 'userId'),
      filter: any(named: 'filter'),
      selectedAgentIds: any(named: 'selectedAgentIds'),
      strategy: any(named: 'strategy'),
      bridgeTimeoutMs: any(named: 'bridgeTimeoutMs'),
      raceMaxSources: any(named: 'raceMaxSources'),
      preResolvedResolution: any(named: 'preResolvedResolution'),
      cancelScope: any(named: 'cancelScope'),
      orderTargetsOnlineFirst: any(named: 'orderTargetsOnlineFirst'),
      dedupeTargetsByAgentId: any(named: 'dedupeTargetsByAgentId'),
      mergeAllConcurrencyOverride: any(named: 'mergeAllConcurrencyOverride'),
    ),
  ).thenAnswer(
    (_) async =>
        const Failure<CadastroFilialAcrossAgentsPageResult, AppFailure>(
          NetworkFailure(
            message: 'catalog down',
            userMessage: 'Catalogo indisponivel.',
          ),
        ),
  );
}

AgentQueryExecutionReport<ResumoTotalVendasMunicipioFilialPeriodoRow> _report({
  required List<
    AgentQueryExecutionParticipant<ResumoTotalVendasMunicipioFilialPeriodoRow>
  >
  participants,
  List<AgentQueryTarget> plannedTargets = const <AgentQueryTarget>[],
  List<AgentQueryTarget> missingClientTokenTargets = const <AgentQueryTarget>[],
  List<AgentQueryTarget> skippedDueToHubPresenceTargets =
      const <AgentQueryTarget>[],
}) {
  return AgentQueryExecutionReport<ResumoTotalVendasMunicipioFilialPeriodoRow>(
    queryKey: AgentQueryKey.resumoTotalVendasMunicipioFilialPeriodo,
    strategy: AgentQueryExecutionStrategy.mergeAll,
    consideredApprovedAgentCount:
        plannedTargets.length + missingClientTokenTargets.length,
    plannedTargets: plannedTargets,
    missingClientTokenTargets: missingClientTokenTargets,
    participants: participants,
    totalElapsedMs: 12,
    skippedDueToHubPresenceTargets: skippedDueToHubPresenceTargets,
  );
}

AgentQueryExecutionReport<CadastroFilialRow> _catalogReport({
  required List<AgentQueryExecutionParticipant<CadastroFilialRow>> participants,
  List<AgentQueryTarget> plannedTargets = const <AgentQueryTarget>[],
  List<AgentQueryTarget> missingClientTokenTargets = const <AgentQueryTarget>[],
  List<AgentQueryTarget> skippedDueToHubPresenceTargets =
      const <AgentQueryTarget>[],
}) {
  return AgentQueryExecutionReport<CadastroFilialRow>(
    queryKey: AgentQueryKey.cadastroFilial,
    strategy: AgentQueryExecutionStrategy.mergeAll,
    consideredApprovedAgentCount:
        plannedTargets.length + missingClientTokenTargets.length,
    plannedTargets: plannedTargets,
    missingClientTokenTargets: missingClientTokenTargets,
    participants: participants,
    totalElapsedMs: 12,
    skippedDueToHubPresenceTargets: skippedDueToHubPresenceTargets,
  );
}

AgentQueryExecutionParticipant<ResumoTotalVendasMunicipioFilialPeriodoRow>
_participant(
  String agentId, {
  required List<ResumoTotalVendasMunicipioFilialPeriodoRow> rows,
  int? sourceRowCount,
  AppFailure? failure,
}) {
  return AgentQueryExecutionParticipant<
    ResumoTotalVendasMunicipioFilialPeriodoRow
  >(
    agentId: agentId,
    displayName: 'Agente $agentId',
    rows: rows,
    sourceRowCount: sourceRowCount,
    failure: failure,
    elapsedMs: 10,
  );
}

AgentQueryExecutionParticipant<CadastroFilialRow> _catalogParticipant(
  String agentId, {
  required List<CadastroFilialRow> rows,
  int? sourceRowCount,
  AppFailure? failure,
}) {
  return AgentQueryExecutionParticipant<CadastroFilialRow>(
    agentId: agentId,
    displayName: 'Agente $agentId',
    rows: rows,
    sourceRowCount: sourceRowCount,
    failure: failure,
    elapsedMs: 10,
  );
}

ResumoTotalVendasMunicipioFilialPeriodoRow _row({
  int codEmpresa = 1,
  int codFilial = 1,
  String nomeFilial = 'Loja matriz',
  String? nomeFantasiaFilial = 'Loja matriz',
  int? codMunicipioFilial = 5107909,
  String? nomeMunicipioFilial = 'SINOP',
  String? ufMunicipioFilial = 'MT',
  String? codigoIbgeMunicipioFilial = '5107909',
  String? cepFilial,
  int qtdVendas = 1,
  double totalVenda = 10,
}) {
  return ResumoTotalVendasMunicipioFilialPeriodoRow(
    codEmpresa: codEmpresa,
    codFilial: codFilial,
    nomeFilial: nomeFilial,
    nomeFantasiaFilial: nomeFantasiaFilial,
    codMunicipioFilial: codMunicipioFilial,
    nomeMunicipioFilial: nomeMunicipioFilial,
    ufMunicipioFilial: ufMunicipioFilial,
    codigoIbgeMunicipioFilial: codigoIbgeMunicipioFilial,
    cepFilial: cepFilial,
    qtdVendas: qtdVendas,
    totalVenda: totalVenda,
  );
}

CadastroFilialRow _catalogRow({
  int codEmpresa = 1,
  int codFilial = 1,
  String nomeFilial = 'Loja matriz',
  String? nomeFantasia = 'Loja matriz',
  int? codMunicipio = 5107909,
  String? nomeMunicipio = 'SINOP',
  String? ufMunicipio = 'MT',
  String? codigoIbge = '5107909',
  String? cep,
}) {
  return CadastroFilialRow(
    codEmpresa: codEmpresa,
    codFilial: codFilial,
    nomeFilial: nomeFilial,
    nomeFantasia: nomeFantasia,
    codMunicipio: codMunicipio,
    nomeMunicipio: nomeMunicipio,
    ufMunicipio: ufMunicipio,
    codigoIbge: codigoIbge,
    cep: cep,
  );
}

AgentQueryTarget _target(String agentId, {String? clientToken = 'token'}) {
  return AgentQueryTarget(
    agentId: agentId,
    displayName: 'Agente $agentId',
    connectionStatus: AgentConnectionStatus.online,
    clientToken: clientToken,
    hubConnectedFromApprovedCatalogRow: true,
  );
}

AgentSqlBatchExecutionResult _mergedBatchSqlResult({
  required String agentId,
  required double totalVenda,
  int catalogTotalCount = 1,
}) {
  return AgentSqlBatchExecutionResult(
    totalCommands: salesLiveMapBatchCommandCount,
    successfulCommands: salesLiveMapBatchCommandCount,
    failedCommands: 0,
    items: <AgentSqlBatchExecutionItem>[
      AgentSqlBatchExecutionItem(
        index: 0,
        ok: true,
        rows: <Map<String, dynamic>>[
          <String, dynamic>{
            'TotalCount': catalogTotalCount,
            'CodEmpresa': 1,
            'CodFilial': 1,
            'NomeFilial': 'Loja $agentId',
            'NomeFantasia': 'Loja $agentId',
            'CEP': '78550000',
            'NomeMunicipio': 'SINOP',
            'CodigoIBGE': 5107909,
            'UFMunicipio': 'MT',
          },
        ],
        rowCount: 1,
      ),
      AgentSqlBatchExecutionItem(
        index: 1,
        ok: true,
        rows: <Map<String, dynamic>>[
          <String, dynamic>{
            'CodEmpresa': 1,
            'CodFilial': 1,
            'NomeFilial': 'Loja $agentId',
            'NomeFantasiaFilial': 'Loja $agentId',
            'CEPFilial': '78550000',
            'CodMunicipioFilial': 1,
            'NomeMunicipioFilial': 'SINOP',
            'UFMunicipioFilial': 'MT',
            'CodigoIBGEMunicipioFilial': 5107909,
            'QtdVendas': 1,
            'TotalVenda': totalVenda,
          },
        ],
        rowCount: 1,
      ),
    ],
  );
}

class _StaticBrazilTestGeocoder implements AppLocationGeocoder {
  final List<AppLocationLookupInput> lookups = <AppLocationLookupInput>[];

  @override
  String get providerId => 'static-test';

  @override
  bool get isExternal => false;

  @override
  int get maxConcurrentRequests => 1;

  @override
  Future<AppLocationGeocoderResult> resolve(
    AppLocationLookupInput input,
  ) async {
    lookups.add(input);
    return switch (input.ibgeMunicipalityCode) {
      '1100015' => AppLocationGeocoderResult.resolved(
        _resolved(
          latitude: -11.9355403047646,
          longitude: -61.9998238962936,
          uf: 'RO',
          city: "ALTA FLORESTA D'OESTE",
        ),
      ),
      '5107909' => AppLocationGeocoderResult.resolved(
        _resolved(
          latitude: -11.8604,
          longitude: -55.5091,
          uf: 'MT',
          city: 'SINOP',
        ),
      ),
      _ => const AppLocationGeocoderResult.notFound(),
    };
  }

  AppResolvedLocation _resolved({
    required double latitude,
    required double longitude,
    required String uf,
    required String city,
  }) {
    return AppResolvedLocation(
      point: AppGeoPoint(latitude: latitude, longitude: longitude),
      precision: AppLocationPrecision.city,
      source: AppLocationSource.staticBrazilMunicipalityCentroid,
      cacheKey: 'test',
      details: AppResolvedAddressDetails(
        uf: uf,
        city: city,
        countryCode: 'BR',
      ),
    );
  }
}

class _MemoryCacheStore implements AppCacheStore {
  final Map<String, String> _values = <String, String>{};
  int writeCount = 0;

  @override
  Future<void> clearAll() async {
    _values.clear();
  }

  @override
  Future<String?> getString(String key) async => _values[key];

  @override
  Future<void> putString({required String key, required String value}) async {
    writeCount += 1;
    _values[key] = value;
  }

  @override
  Future<void> removeString(String key) async {
    _values.remove(key);
  }

  @override
  Future<void> removeKeysWithPrefix(String prefix) async {
    _values.removeWhere((key, _) => key.startsWith(prefix));
  }

  @override
  Future<void> removeKeysWhere({
    required String prefix,
    required bool Function(String key) predicate,
  }) async {
    _values.removeWhere(
      (key, _) => key.startsWith(prefix) && predicate(key),
    );
  }
}
