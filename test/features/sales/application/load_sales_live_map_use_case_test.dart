import 'dart:async';

import 'package:checks/checks.dart';
import 'package:colmeia/core/cache/app_cache_store.dart';
import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_resumo_total_vendas_municipio_filial_periodo_across_agents_use_case.dart';
import 'package:colmeia/features/agent_queries/data/agent_queries_bounded_result_max_rows.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_execution_participant.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_execution_report.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_execution_strategy.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_key.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_target.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_total_vendas_municipio_filial_periodo_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_total_vendas_municipio_filial_periodo_row.dart';
import 'package:colmeia/features/client_agents/domain/entities/agent_connection_status.dart';
import 'package:colmeia/features/sales/application/load_sales_live_map_use_case.dart';
import 'package:colmeia/features/sales/domain/entities/sales_live_map_filter.dart';
import 'package:colmeia/shared/maps/app_location_geocode_cache.dart';
import 'package:colmeia/shared/maps/app_location_models.dart';
import 'package:colmeia/shared/maps/app_location_resolver.dart';
import 'package:colmeia/shared/widgets/charts/app_brazil_store_sales_map_models.dart';
import 'package:colmeia/shared/widgets/charts/app_brazil_store_sales_point_resolver.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:result_dart/result_dart.dart';

class _MockLoadResumoTotalVendasMunicipioFilialPeriodoAcrossAgentsUseCase
    extends Mock
    implements LoadResumoTotalVendasMunicipioFilialPeriodoAcrossAgentsUseCase {}

void main() {
  const userId = 'user-1';
  final now = DateTime(2026, 5, 9, 14);

  late _MockLoadResumoTotalVendasMunicipioFilialPeriodoAcrossAgentsUseCase
  loadAcrossAgents;
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
    registerFallbackValue(AgentQueryExecutionStrategy.mergeAll);
  });

  setUp(() {
    loadAcrossAgents =
        _MockLoadResumoTotalVendasMunicipioFilialPeriodoAcrossAgentsUseCase();
    cacheStore = _MemoryCacheStore();
    geocoder = _StaticBrazilTestGeocoder();
    final locationResolver = AppLocationResolver(
      cache: AppLocationGeocodeCache(cacheStore),
      geocoders: <AppLocationGeocoder>[geocoder],
      now: () => now,
    );
    useCase = LoadSalesLiveMapUseCase(
      loadAcrossAgents,
      AppBrazilStoreSalesPointResolver(locationResolver: locationResolver),
      now: () => now,
    );
  });

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

  test('filtra pontos e KPIs pelas filiais selecionadas', () async {
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
      filter: const SalesLiveMapFilter(
        selectedAgentIds: <String>{'agent-a'},
        selectedBranchIds: <String>{'agent-a-1-2'},
      ),
    );

    check(result.branchOptions.map((branch) => branch.id).toSet()).deepEquals(
      <String>{'agent-a-1-1', 'agent-a-1-2'},
    );
    check(result.points.map((point) => point.id).toList()).deepEquals(
      <String>['agent-a-1-2'],
    );
    check(result.totalBranchCount).equals(1);
    check(result.totalRevenue).equals(300);
  });

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
      ),
    ).captured.single;
    check(captured as Set<String>).deepEquals(<String>{'agent-a'});
  });

  test(
    'nao envia filtro fixo de empresa e filial na consulta padrao',
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
        ),
      ).captured;
      final queryFilter =
          captured[0] as ResumoTotalVendasMunicipioFilialPeriodoFilter;
      final selectedAgentIds = captured[1] as Set<String>?;

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
        filter: const SalesLiveMapFilter(
          selectedBranchIds: <String>{'agent-a-1-1'},
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
        ),
      ).captured;
      final queryFilter =
          captured[0] as ResumoTotalVendasMunicipioFilialPeriodoFilter;
      final selectedAgentIds = captured[1] as Set<String>;

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
      AppBrazilStoreSalesLocationResolution.ibgeMunicipalityCode,
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
        <AppLocationLookupType>[AppLocationLookupType.cityUf],
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
    check(result.failedAgentCount).equals(1);
    check(result.missingClientTokenAgentCount).equals(1);
    check(result.skippedOfflineAgentCount).equals(1);
    check(result.hasPartialIssue).isTrue();
    check(result.refreshedAt).equals(now);
  });

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
      check(result.branchOptions.single.city).equals('Sem municipio');
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
  when(
    () => useCase(
      userId: any(named: 'userId'),
      filter: any(named: 'filter'),
      selectedAgentIds: any(named: 'selectedAgentIds'),
      strategy: any(named: 'strategy'),
      bridgeTimeoutMs: any(named: 'bridgeTimeoutMs'),
      raceMaxSources: any(named: 'raceMaxSources'),
    ),
  ).thenAnswer(
    (_) async =>
        Success<
          AgentQueryExecutionReport<ResumoTotalVendasMunicipioFilialPeriodoRow>,
          AppFailure
        >(report),
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

AgentQueryTarget _target(String agentId, {String? clientToken = 'token'}) {
  return AgentQueryTarget(
    agentId: agentId,
    displayName: 'Agente $agentId',
    connectionStatus: AgentConnectionStatus.online,
    clientToken: clientToken,
  );
}

class _StaticBrazilTestGeocoder implements AppLocationGeocoder {
  final List<AppLocationLookupInput> lookups = <AppLocationLookupInput>[];

  @override
  String get providerId => 'static-test';

  @override
  Future<AppResolvedLocation?> resolve(AppLocationLookupInput input) async {
    lookups.add(input);
    return switch (input.ibgeMunicipalityCode) {
      '1100015' => _resolved(
        latitude: -11.9355403047646,
        longitude: -61.9998238962936,
        uf: 'RO',
        city: "ALTA FLORESTA D'OESTE",
      ),
      '5107909' => _resolved(
        latitude: -11.8604,
        longitude: -55.5091,
        uf: 'MT',
        city: 'SINOP',
      ),
      _ => null,
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
      metadata: <String, Object?>{'uf': uf, 'city': city},
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
}
