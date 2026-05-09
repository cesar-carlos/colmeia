import 'package:checks/checks.dart';
import 'package:colmeia/core/cache/app_cache_store.dart';
import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_resumo_total_vendas_municipio_filial_diario_across_agents_use_case.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_execution_participant.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_execution_report.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_execution_strategy.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_key.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_target.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_total_vendas_municipio_filial_diario_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_total_vendas_municipio_filial_diario_row.dart';
import 'package:colmeia/features/client_agents/domain/entities/agent_connection_status.dart';
import 'package:colmeia/features/sales/application/load_sales_live_map_use_case.dart';
import 'package:colmeia/features/sales/domain/entities/sales_live_map_filter.dart';
import 'package:colmeia/shared/maps/app_location_geocode_cache.dart';
import 'package:colmeia/shared/maps/app_location_models.dart';
import 'package:colmeia/shared/maps/app_location_resolver.dart';
import 'package:colmeia/shared/widgets/charts/app_brazil_store_sales_point_resolver.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:result_dart/result_dart.dart';

class _MockLoadResumoTotalVendasMunicipioFilialDiarioAcrossAgentsUseCase
    extends Mock
    implements LoadResumoTotalVendasMunicipioFilialDiarioAcrossAgentsUseCase {}

void main() {
  const userId = 'user-1';
  final now = DateTime(2026, 5, 9, 14);

  late _MockLoadResumoTotalVendasMunicipioFilialDiarioAcrossAgentsUseCase
  loadAcrossAgents;
  late _MemoryCacheStore cacheStore;
  late _StaticBrazilTestGeocoder geocoder;
  late LoadSalesLiveMapUseCase useCase;

  setUpAll(() {
    registerFallbackValue(
      ResumoTotalVendasMunicipioFilialDiarioFilter(
        dataVendaInicio: DateTime.utc(2026),
        dataVendaFim: DateTime.utc(2026, 12, 31),
      ),
    );
    registerFallbackValue(AgentQueryExecutionStrategy.mergeAll);
  });

  setUp(() {
    loadAcrossAgents =
        _MockLoadResumoTotalVendasMunicipioFilialDiarioAcrossAgentsUseCase();
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
                ResumoTotalVendasMunicipioFilialDiarioRow
              >
            >[
              _participant(
                'agent-a',
                rows: <ResumoTotalVendasMunicipioFilialDiarioRow>[
                  _row(totalVenda: 120, qtdVendas: 2),
                  _row(totalVenda: 80, qtdVendas: 3),
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
    check(point.salesAmount).equals(200);
    check(point.salesCount).equals(5);
    check(result.totalRevenue).equals(200);
    check(result.totalSalesCount).equals(5);
    check(result.totalBranchCount).equals(1);
    check(result.mappedBranchCount).equals(1);
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
                  ResumoTotalVendasMunicipioFilialDiarioRow
                >
              >[
                _participant(
                  'agent-a',
                  rows: <ResumoTotalVendasMunicipioFilialDiarioRow>[
                    _row(totalVenda: 100),
                  ],
                ),
                _participant(
                  'agent-b',
                  rows: <ResumoTotalVendasMunicipioFilialDiarioRow>[
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
                ResumoTotalVendasMunicipioFilialDiarioRow
              >
            >[
              _participant(
                'agent-a',
                rows: <ResumoTotalVendasMunicipioFilialDiarioRow>[
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
                ResumoTotalVendasMunicipioFilialDiarioRow
              >
            >[
              _participant(
                'agent-a',
                rows: <ResumoTotalVendasMunicipioFilialDiarioRow>[
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
    check(result.points).isEmpty();
    check(result.hasPartialIssue).isTrue();
  });

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
                ResumoTotalVendasMunicipioFilialDiarioRow
              >
            >[
              _participant(
                'agent-a',
                rows: <ResumoTotalVendasMunicipioFilialDiarioRow>[
                  _row(totalVenda: 90, qtdVendas: 2),
                ],
              ),
              _participant(
                'agent-b',
                rows: const <ResumoTotalVendasMunicipioFilialDiarioRow>[],
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
    check(result.queriedAgentCount).equals(2);
    check(result.plannedAgentCount).equals(2);
    check(result.failedAgentCount).equals(1);
    check(result.missingClientTokenAgentCount).equals(1);
    check(result.skippedOfflineAgentCount).equals(1);
    check(result.hasPartialIssue).isTrue();
    check(result.refreshedAt).equals(now);
  });
}

void _stubReport(
  _MockLoadResumoTotalVendasMunicipioFilialDiarioAcrossAgentsUseCase useCase,
  AgentQueryExecutionReport<ResumoTotalVendasMunicipioFilialDiarioRow> report,
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
          AgentQueryExecutionReport<ResumoTotalVendasMunicipioFilialDiarioRow>,
          AppFailure
        >(report),
  );
}

AgentQueryExecutionReport<ResumoTotalVendasMunicipioFilialDiarioRow> _report({
  required List<
    AgentQueryExecutionParticipant<ResumoTotalVendasMunicipioFilialDiarioRow>
  >
  participants,
  List<AgentQueryTarget> plannedTargets = const <AgentQueryTarget>[],
  List<AgentQueryTarget> missingClientTokenTargets = const <AgentQueryTarget>[],
  List<AgentQueryTarget> skippedDueToHubPresenceTargets =
      const <AgentQueryTarget>[],
}) {
  return AgentQueryExecutionReport<ResumoTotalVendasMunicipioFilialDiarioRow>(
    queryKey: AgentQueryKey.resumoTotalVendasMunicipioFilialDiario,
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

AgentQueryExecutionParticipant<ResumoTotalVendasMunicipioFilialDiarioRow>
_participant(
  String agentId, {
  required List<ResumoTotalVendasMunicipioFilialDiarioRow> rows,
  AppFailure? failure,
}) {
  return AgentQueryExecutionParticipant<
    ResumoTotalVendasMunicipioFilialDiarioRow
  >(
    agentId: agentId,
    displayName: 'Agente $agentId',
    rows: rows,
    failure: failure,
    elapsedMs: 10,
  );
}

ResumoTotalVendasMunicipioFilialDiarioRow _row({
  int codEmpresa = 1,
  int codFilial = 1,
  String nomeFilial = 'Loja matriz',
  String? nomeFantasiaFilial = 'Loja matriz',
  String nomeMunicipioFilial = 'SINOP',
  String ufMunicipioFilial = 'MT',
  String? codigoIbgeMunicipioFilial = '5107909',
  int qtdVendas = 1,
  double totalVenda = 10,
}) {
  return ResumoTotalVendasMunicipioFilialDiarioRow(
    codEmpresa: codEmpresa,
    codFilial: codFilial,
    nomeFilial: nomeFilial,
    nomeFantasiaFilial: nomeFantasiaFilial,
    codMunicipioFilial: 5107909,
    nomeMunicipioFilial: nomeMunicipioFilial,
    ufMunicipioFilial: ufMunicipioFilial,
    codigoIbgeMunicipioFilial: codigoIbgeMunicipioFilial,
    dataVenda: DateTime(2026, 5, 9),
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
