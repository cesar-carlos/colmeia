import 'package:colmeia/features/agent_queries/domain/entities/agent_query_execution_participant.dart';
import 'package:colmeia/features/agent_queries/domain/entities/cadastro_filial_row.dart';
import 'package:colmeia/features/sales/application/load_sales_live_map/sales_live_map_branch_aggregate.dart';
import 'package:colmeia/features/sales/application/load_sales_live_map/sales_live_map_branch_location_cache.dart';
import 'package:colmeia/features/sales/application/load_sales_live_map/sales_live_map_diagnostics_logger.dart';
import 'package:colmeia/features/sales/application/load_sales_live_map/sales_live_map_geolocator.dart';
import 'package:colmeia/features/sales/application/load_sales_live_map/sales_live_map_load_cancel_token.dart';
import 'package:colmeia/features/sales/application/sales_live_map_point_factory.dart';
import 'package:colmeia/features/sales/domain/contracts/sales_live_map_point_resolver.dart';
import 'package:colmeia/features/sales/domain/entities/sales_live_map_point.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late SalesLiveMapBranchLocationCache locationCache;
  late _FakePointResolver pointResolver;
  late SalesLiveMapGeolocator geolocator;

  setUp(() {
    locationCache = SalesLiveMapBranchLocationCache(
      maxEntries: 50,
      ttl: const Duration(minutes: 10),
    );
    pointResolver = _FakePointResolver();
    geolocator = SalesLiveMapGeolocator(
      locationCache: locationCache,
      pointResolver: pointResolver,
      pointFactory: const SalesLiveMapPointFactory(),
      diagnosticsLogger: const SalesLiveMapDiagnosticsLogger(),
      maxConcurrency: 4,
    );
  });

  test(
    'resolveSqlMunicipalityPoints uses the SQL municipality resolver path',
    () async {
      final refreshedAt = DateTime(2026, 5, 27, 12);
      final aggregate = _aggregate(id: 'agent-1-1-1');
      pointResolver.resolved[aggregate.id] = SalesLiveMapResolvedPoint(
        point: SalesLiveMapPoint(
          id: aggregate.id,
          name: aggregate.name,
          uf: 'MT',
          latitude: -15.60,
          longitude: -56.10,
          salesAmount: 0,
          salesCount: 0,
          city: 'Cuiaba',
        ),
      );

      final outcome = await geolocator.resolveSqlMunicipalityPoints(
        <SalesLiveMapBranchAggregate>[aggregate],
        refreshedAt: refreshedAt,
      );

      expect(outcome.points, hasLength(1));
      expect(pointResolver.sqlMunicipalityResolveCalls, 1);
      expect(pointResolver.resolveCalls, 0);
    },
  );

  test(
    'returns an empty result when there are no aggregates to resolve',
    () async {
      final outcome = await geolocator.resolveBranchPoints(
        const <SalesLiveMapBranchAggregate>[],
        refreshedAt: DateTime(2026, 5, 27),
      );
      expect(outcome.points, isEmpty);
      expect(outcome.cacheHitCount, 0);
      expect(outcome.cacheMissCount, 0);
      expect(outcome.cancelled, isFalse);
      expect(pointResolver.resolveCalls, 0);
    },
  );

  test(
    'resolves uncached aggregates via the point resolver and caches the '
    'outcome for subsequent runs',
    () async {
      final refreshedAt = DateTime(2026, 5, 27, 12);
      final aggregate = _aggregate(id: 'agent-1-1-1');
      pointResolver.resolved[aggregate.id] = SalesLiveMapResolvedPoint(
        point: SalesLiveMapPoint(
          id: aggregate.id,
          name: aggregate.name,
          uf: 'MT',
          latitude: -15.60,
          longitude: -56.10,
          salesAmount: 0,
          salesCount: 0,
          city: 'Cuiaba',
        ),
      );

      final first = await geolocator.resolveBranchPoints(
        <SalesLiveMapBranchAggregate>[aggregate],
        refreshedAt: refreshedAt,
      );
      expect(first.points, hasLength(1));
      expect(first.cacheMissCount, 1);
      expect(first.resolvedAndCachedCount, 1);
      expect(pointResolver.resolveCalls, 1);

      // Second call should hit the location cache (no resolver call).
      final second = await geolocator.resolveBranchPoints(
        <SalesLiveMapBranchAggregate>[aggregate],
        refreshedAt: refreshedAt,
      );
      expect(second.points, hasLength(1));
      expect(second.cacheHitCount, 1);
      expect(
        pointResolver.resolveCalls,
        1,
        reason: 'resolver must not be called again on cache hit',
      );
    },
  );

  test(
    'full pass retries branches left unresolved by the SQL municipality preview',
    () async {
      final refreshedAt = DateTime(2026, 6, 8, 12);
      final aggregate = SalesLiveMapBranchAggregate.fromCadastro(
        participant: const AgentQueryExecutionParticipant<CadastroFilialRow>(
          agentId: 'agent-a',
          displayName: 'Agente agent-a',
          rows: <CadastroFilialRow>[],
          elapsedMs: 0,
          sourceRowCount: 0,
        ),
        row: const CadastroFilialRow(
          codEmpresa: 1,
          codFilial: 1,
          nomeFilial: 'CASA DO MEL VILHENA',
          cep: '76980000',
        ),
      );

      final sqlOutcome = await geolocator.resolveSqlMunicipalityPoints(
        <SalesLiveMapBranchAggregate>[aggregate],
        refreshedAt: refreshedAt,
      );
      expect(sqlOutcome.points, isEmpty);
      expect(sqlOutcome.unresolvedAndCachedCount, 1);

      pointResolver.resolved[aggregate.id] = SalesLiveMapResolvedPoint(
        point: SalesLiveMapPoint(
          id: aggregate.id,
          name: aggregate.name,
          uf: 'RO',
          latitude: -12.74,
          longitude: -60.15,
          salesAmount: 0,
          salesCount: 0,
          locationResolution: SalesLiveMapLocationResolution.cep,
        ),
      );

      final fullOutcome = await geolocator.resolveBranchPoints(
        <SalesLiveMapBranchAggregate>[aggregate],
        refreshedAt: refreshedAt,
      );

      expect(fullOutcome.points, hasLength(1));
      expect(
        fullOutcome.points.single.locationResolution,
        SalesLiveMapLocationResolution.cep,
      );
      expect(pointResolver.sqlMunicipalityResolveCalls, 1);
      expect(pointResolver.resolveCalls, 1);
    },
  );

  test(
    'caches unresolved (negative) entries so subsequent runs short-circuit',
    () async {
      final refreshedAt = DateTime(2026, 5, 27, 12);
      final aggregate = _aggregate(id: 'agent-1-1-2');
      // resolver does not return anything for this id -> unresolved

      final first = await geolocator.resolveBranchPoints(
        <SalesLiveMapBranchAggregate>[aggregate],
        refreshedAt: refreshedAt,
      );
      expect(first.points, isEmpty);
      expect(first.unresolvedAndCachedCount, 1);

      final second = await geolocator.resolveBranchPoints(
        <SalesLiveMapBranchAggregate>[aggregate],
        refreshedAt: refreshedAt,
      );
      expect(second.points, isEmpty);
      expect(second.cacheUnresolvedHitCount, 1);
      expect(
        pointResolver.resolveCalls,
        1,
        reason: 'resolver must not be called again on unresolved cache hit',
      );
    },
  );

  test(
    'reuses partial geo snapshot when allowPartialGeoReuse is enabled '
    'and the locationSourceSignature is unchanged',
    () async {
      final refreshedAt = DateTime(2026, 5, 27, 12);
      final aggregate = _aggregate(id: 'agent-1-1-3');
      final partialPoint = SalesLiveMapPoint(
        id: aggregate.id,
        name: 'Pending Loja',
        uf: 'MT',
        latitude: -10,
        longitude: -55,
        salesAmount: 0,
        salesCount: 0,
      );
      geolocator.recordPartialGeoSnapshot(
        aggregates: <SalesLiveMapBranchAggregate>[aggregate],
        points: <SalesLiveMapPoint>[partialPoint],
      );

      final outcome = await geolocator.resolveBranchPoints(
        <SalesLiveMapBranchAggregate>[aggregate],
        refreshedAt: refreshedAt,
        allowPartialGeoReuse: true,
      );

      expect(outcome.partialGeoReuseCount, 1);
      expect(outcome.points, hasLength(1));
      expect(pointResolver.resolveCalls, 0);
    },
  );

  test(
    'resetPartialGeoSnapshot clears the partial state so the next call '
    'cannot reuse it',
    () async {
      final refreshedAt = DateTime(2026, 5, 27, 12);
      final aggregate = _aggregate(id: 'agent-1-1-4');
      geolocator
        ..recordPartialGeoSnapshot(
          aggregates: <SalesLiveMapBranchAggregate>[aggregate],
          points: <SalesLiveMapPoint>[
            SalesLiveMapPoint(
              id: aggregate.id,
              name: aggregate.name,
              uf: 'MT',
              latitude: -10,
              longitude: -55,
              salesAmount: 0,
              salesCount: 0,
            ),
          ],
        )
        ..resetPartialGeoSnapshot();

      final outcome = await geolocator.resolveBranchPoints(
        <SalesLiveMapBranchAggregate>[aggregate],
        refreshedAt: refreshedAt,
        allowPartialGeoReuse: true,
      );

      expect(outcome.partialGeoReuseCount, 0);
      expect(outcome.cacheMissCount, 1);
    },
  );

  test('returns cancelled result without invoking the resolver', () async {
    final refreshedAt = DateTime(2026, 5, 27, 12);
    final aggregate = _aggregate(id: 'agent-1-1-5');
    final cancelToken = SalesLiveMapLoadCancelToken()..cancel();

    final outcome = await geolocator.resolveBranchPoints(
      <SalesLiveMapBranchAggregate>[aggregate],
      refreshedAt: refreshedAt,
      cancelToken: cancelToken,
    );

    expect(outcome.cancelled, isTrue);
    expect(outcome.points, isEmpty);
    expect(pointResolver.resolveCalls, 0);
  });
}

SalesLiveMapBranchAggregate _aggregate({required String id}) {
  // id format used by the live map cache: agent-codEmpresa-codFilial.
  final parts = id.split('-');
  // For deterministic test ids of the form 'agent-1-1-1', take the trailing
  // two numbers as company / branch codes (everything before stays the
  // agent id).
  final codFilial = int.parse(parts.last);
  final codEmpresa = int.parse(parts[parts.length - 2]);
  final agentId = parts.sublist(0, parts.length - 2).join('-');
  return SalesLiveMapBranchAggregate.fromCadastro(
    participant: AgentQueryExecutionParticipant<CadastroFilialRow>(
      agentId: agentId,
      displayName: 'Agente $agentId',
      rows: <CadastroFilialRow>[],
      elapsedMs: 0,
      sourceRowCount: 0,
    ),
    row: CadastroFilialRow(
      codEmpresa: codEmpresa,
      codFilial: codFilial,
      nomeFilial: 'Loja $codFilial',
      nomeMunicipio: 'Cuiaba',
      ufMunicipio: 'MT',
    ),
  );
}

class _FakePointResolver implements SalesLiveMapPointResolver {
  final Map<String, SalesLiveMapResolvedPoint> resolved =
      <String, SalesLiveMapResolvedPoint>{};
  int resolveCalls = 0;
  int sqlMunicipalityResolveCalls = 0;

  @override
  Future<List<SalesLiveMapResolvedPoint>> resolveAllWithDetails(
    Iterable<SalesLiveMapPointSource> sources, {
    int maxConcurrent = 1,
  }) async {
    resolveCalls += 1;
    return sources
        .map((source) => resolved[source.id])
        .whereType<SalesLiveMapResolvedPoint>()
        .toList(growable: false);
  }

  @override
  Future<List<SalesLiveMapResolvedPoint>> resolveAllSqlMunicipalityWithDetails(
    Iterable<SalesLiveMapPointSource> sources, {
    int maxConcurrent = 1,
  }) async {
    sqlMunicipalityResolveCalls += 1;
    return sources
        .map((source) => resolved[source.id])
        .whereType<SalesLiveMapResolvedPoint>()
        .toList(growable: false);
  }

  @override
  Future<SalesLiveMapPoint?> resolve(SalesLiveMapPointSource source) async {
    throw UnimplementedError();
  }

  @override
  Future<SalesLiveMapResolvedPoint?> resolveWithDetails(
    SalesLiveMapPointSource source,
  ) async {
    throw UnimplementedError();
  }

  @override
  Future<List<SalesLiveMapPoint>> resolveAll(
    Iterable<SalesLiveMapPointSource> sources,
  ) async {
    throw UnimplementedError();
  }
}
