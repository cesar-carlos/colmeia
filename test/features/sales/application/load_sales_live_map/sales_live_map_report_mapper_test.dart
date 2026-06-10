import 'package:colmeia/features/agent_queries/domain/entities/agent_query_execution_participant.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_execution_report.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_execution_strategy.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_key.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_target.dart';
import 'package:colmeia/features/agent_queries/domain/entities/cadastro_filial_across_agents_page_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/cadastro_filial_row.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_total_vendas_municipio_filial_periodo_row.dart';
import 'package:colmeia/features/client_agents/domain/entities/agent_connection_status.dart';
import 'package:colmeia/features/sales/application/load_sales_live_map/sales_live_map_branch_aggregator.dart';
import 'package:colmeia/features/sales/application/load_sales_live_map/sales_live_map_diagnostics_logger.dart';
import 'package:colmeia/features/sales/application/load_sales_live_map/sales_live_map_geolocator.dart';
import 'package:colmeia/features/sales/application/load_sales_live_map/sales_live_map_load_cancel_token.dart';
import 'package:colmeia/features/sales/application/load_sales_live_map/sales_live_map_progressive_emit_policy.dart';
import 'package:colmeia/features/sales/application/load_sales_live_map/sales_live_map_report_mapper.dart';
import 'package:colmeia/features/sales/domain/entities/sales_live_map_filter.dart';
import 'package:colmeia/features/sales/domain/entities/sales_live_map_point.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockSalesLiveMapGeolocator extends Mock
    implements SalesLiveMapGeolocator {}

void main() {
  late _MockSalesLiveMapGeolocator geolocator;
  late SalesLiveMapReportMapper mapper;
  final refreshedAt = DateTime(2026, 5, 27, 12);
  const filter = SalesLiveMapFilter();

  setUp(() {
    geolocator = _MockSalesLiveMapGeolocator();
    mapper = SalesLiveMapReportMapper(
      branchAggregator: const SalesLiveMapBranchAggregator(),
      diagnosticsLogger: const SalesLiveMapDiagnosticsLogger(),
      geolocator: geolocator,
      emitPolicy: const SalesLiveMapProgressiveEmitPolicy(
        diagnosticsLogger: SalesLiveMapDiagnosticsLogger(),
      ),
    );
  });

  test(
    'yields cancelled result when cancel token is set before mapping',
    () async {
      final cancelToken = SalesLiveMapLoadCancelToken()..cancel();
      final emissions = await mapper
          .emitMappedReports(
            _salesReport(),
            filter: filter,
            refreshedAt: refreshedAt,
            catalogResult: _catalogPage(),
            cancelToken: cancelToken,
          )
          .toList();

      expect(emissions, hasLength(1));
      expect(emissions.single.result.cancelled, isTrue);
      verifyNever(
        () => geolocator.resolveSqlMunicipalityPoints(
          any(),
          refreshedAt: any(named: 'refreshedAt'),
          cancelToken: any(named: 'cancelToken'),
        ),
      );
    },
  );

  test(
    'emits staged geo waves: shell, sql municipalities, full branch points',
    () async {
      final sqlPoint = _point(id: 'agent-a-1-1', latitude: -15.1);
      final branchPoint = _point(id: 'agent-a-1-1');
      when(
        () => geolocator.resolveSqlMunicipalityPoints(
          any(),
          refreshedAt: refreshedAt,
          cancelToken: any(named: 'cancelToken'),
        ),
      ).thenAnswer(
        (_) async => SalesLiveMapGeolocationResult(
          points: <SalesLiveMapPoint>[sqlPoint],
        ),
      );
      when(
        () => geolocator.resolveBranchPoints(
          any(),
          refreshedAt: refreshedAt,
          cancelToken: any(named: 'cancelToken'),
          allowPartialGeoReuse: any(named: 'allowPartialGeoReuse'),
        ),
      ).thenAnswer(
        (_) async => SalesLiveMapGeolocationResult(
          points: <SalesLiveMapPoint>[branchPoint],
        ),
      );

      final emissions = await mapper
          .emitMappedReports(
            _salesReport(),
            filter: filter,
            refreshedAt: refreshedAt,
            catalogResult: _catalogPage(),
          )
          .toList();

      expect(emissions, hasLength(3));
      expect(emissions.first.result.points, isEmpty);
      expect(emissions.first.result.branchOptions, isNotEmpty);
      expect(emissions[1].result.points, <SalesLiveMapPoint>[sqlPoint]);
      expect(emissions.last.result.points, <SalesLiveMapPoint>[branchPoint]);
    },
  );

  test('stops after sql geolocation when cancelled mid-stream', () async {
    when(
      () => geolocator.resolveSqlMunicipalityPoints(
        any(),
        refreshedAt: refreshedAt,
        cancelToken: any(named: 'cancelToken'),
      ),
    ).thenAnswer(
      (_) async => const SalesLiveMapGeolocationResult(cancelled: true),
    );

    final emissions = await mapper
        .emitMappedReports(
          _salesReport(),
          filter: filter,
          refreshedAt: refreshedAt,
          catalogResult: _catalogPage(),
        )
        .toList();

    expect(emissions, hasLength(2));
    expect(emissions.last.result.cancelled, isTrue);
    verifyNever(
      () => geolocator.resolveBranchPoints(
        any(),
        refreshedAt: any(named: 'refreshedAt'),
        cancelToken: any(named: 'cancelToken'),
        allowPartialGeoReuse: any(named: 'allowPartialGeoReuse'),
      ),
    );
  });

  test(
    'records partial geo snapshot and reuses points when sales is pending',
    () async {
      final branchPoint = _point(id: 'agent-a-1-1');
      when(
        () => geolocator.resolveSqlMunicipalityPoints(
          any(),
          refreshedAt: refreshedAt,
          cancelToken: any(named: 'cancelToken'),
        ),
      ).thenAnswer((_) async => const SalesLiveMapGeolocationResult());
      when(
        () => geolocator.resolveBranchPoints(
          any(),
          refreshedAt: refreshedAt,
          cancelToken: any(named: 'cancelToken'),
          allowPartialGeoReuse: true,
        ),
      ).thenAnswer(
        (_) async => SalesLiveMapGeolocationResult(
          points: <SalesLiveMapPoint>[branchPoint],
          partialGeoReuseCount: 1,
        ),
      );

      final emissions = await mapper
          .emitMappedReports(
            _salesReport(),
            filter: filter,
            refreshedAt: refreshedAt,
            catalogResult: _catalogPage(),
            salesDataPending: true,
            allowPartialGeoReuse: true,
          )
          .toList();

      verify(
        () => geolocator.recordPartialGeoSnapshot(
          aggregates: any(named: 'aggregates'),
          points: any(named: 'points'),
        ),
      ).called(1);
      expect(emissions.last.result.partialGeoReuseCount, 1);
    },
  );
}

SalesLiveMapPoint _point({
  required String id,
  double latitude = -15.6,
  double longitude = -56.1,
}) {
  return SalesLiveMapPoint(
    id: id,
    name: 'Branch',
    uf: 'MT',
    latitude: latitude,
    longitude: longitude,
    salesAmount: 100,
    salesCount: 1,
    city: 'Cuiaba',
  );
}

CadastroFilialAcrossAgentsPageResult _catalogPage() {
  return CadastroFilialAcrossAgentsPageResult.fromReport(
    AgentQueryExecutionReport<CadastroFilialRow>(
      queryKey: AgentQueryKey.cadastroFilial,
      strategy: AgentQueryExecutionStrategy.mergeAll,
      consideredApprovedAgentCount: 1,
      plannedTargets: _targets(const <String>['agent-a']),
      missingClientTokenTargets: const <AgentQueryTarget>[],
      participants: <AgentQueryExecutionParticipant<CadastroFilialRow>>[
        const AgentQueryExecutionParticipant<CadastroFilialRow>(
          agentId: 'agent-a',
          displayName: 'Agent A',
          rows: <CadastroFilialRow>[
            CadastroFilialRow(
              codEmpresa: 1,
              codFilial: 1,
              nomeFilial: 'Filial 1',
              nomeMunicipio: 'Cuiaba',
              ufMunicipio: 'MT',
            ),
          ],
          elapsedMs: 1,
        ),
      ],
      totalElapsedMs: 1,
    ),
  );
}

AgentQueryExecutionReport<ResumoTotalVendasMunicipioFilialPeriodoRow>
_salesReport() {
  return AgentQueryExecutionReport<ResumoTotalVendasMunicipioFilialPeriodoRow>(
    queryKey: AgentQueryKey.resumoTotalVendasMunicipioFilialPeriodo,
    strategy: AgentQueryExecutionStrategy.mergeAll,
    consideredApprovedAgentCount: 1,
    plannedTargets: _targets(const <String>['agent-a']),
    missingClientTokenTargets: const <AgentQueryTarget>[],
    participants:
        <
          AgentQueryExecutionParticipant<
            ResumoTotalVendasMunicipioFilialPeriodoRow
          >
        >[
          const AgentQueryExecutionParticipant<
            ResumoTotalVendasMunicipioFilialPeriodoRow
          >(
            agentId: 'agent-a',
            displayName: 'Agent A',
            rows: <ResumoTotalVendasMunicipioFilialPeriodoRow>[
              ResumoTotalVendasMunicipioFilialPeriodoRow(
                codEmpresa: 1,
                codFilial: 1,
                nomeFilial: 'Filial 1',
                qtdVendas: 2,
                totalVenda: 150,
              ),
            ],
            elapsedMs: 1,
          ),
        ],
    totalElapsedMs: 1,
  );
}

List<AgentQueryTarget> _targets(List<String> agentIds) {
  return agentIds
      .map(
        (agentId) => AgentQueryTarget(
          agentId: agentId,
          displayName: agentId,
          clientToken: 'token',
          connectionStatus: AgentConnectionStatus.online,
          hubConnectedFromApprovedCatalogRow: true,
        ),
      )
      .toList(growable: false);
}
