import 'dart:convert';

import 'package:colmeia/core/cache/app_kv_cache_key_prefixes.dart';
import 'package:colmeia/features/agent_queries/domain/cache/agent_query_bucket_plan.dart';
import 'package:colmeia/features/agent_queries/domain/cache/agent_query_cache_scope.dart';
import 'package:colmeia/features/agent_queries/domain/cache/agent_query_cache_strategy.dart';
import 'package:colmeia/features/agent_queries/domain/cache/agent_query_fact_kind.dart';
import 'package:colmeia/features/agent_queries/domain/cache/calendar_bucket_closure.dart';
import 'package:colmeia/features/agent_queries/domain/cache/consolidation_storage_mode.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_key.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_load_policy.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_total_vendas_municipio_filial_periodo_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_total_vendas_municipio_filial_periodo_row.dart';

final class ResumoTotalVendasMunicipioFilialPeriodoCacheStrategy
    implements
        AgentQueryCacheStrategy<
          ResumoTotalVendasMunicipioFilialPeriodoFilter,
          ResumoTotalVendasMunicipioFilialPeriodoRow
        > {
  const ResumoTotalVendasMunicipioFilialPeriodoCacheStrategy();

  @override
  AgentQueryKey get queryKey =>
      AgentQueryKey.resumoTotalVendasMunicipioFilialPeriodo;

  @override
  AgentQueryFactKind get factKind =>
      AgentQueryFactKind.branchMunicipalityPeriodSales;

  /// Bumped when storage moved from per-day buckets to one period-range bucket
  /// so day-sliced `COUNT(DISTINCT)` payloads are never reused.
  @override
  int get schemaVersion => 2;

  @override
  ConsolidationStorageMode get storageMode =>
      ConsolidationStorageMode.persistClosedBuckets;

  @override
  AgentQueryBucketPlan planBuckets({
    required ResumoTotalVendasMunicipioFilialPeriodoFilter filter,
    required DateTime clock,
    required AgentQueryLoadPolicy policy,
  }) {
    final bucketId = CalendarBucketClosure.periodRangeBucketId(
      start: filter.dataVendaInicio,
      end: filter.dataVendaFim,
    );
    final closed = isBucketClosed(bucketId: bucketId, clock: clock);
    final closedIds = closed ? <String>[bucketId] : const <String>[];
    final openIds = closed ? const <String>[] : <String>[bucketId];
    final networkIds = policy == AgentQueryLoadPolicy.forceRefresh || !closed
        ? <String>[bucketId]
        : const <String>[];

    return AgentQueryBucketPlan(
      allBucketIdsInRange: <String>[bucketId],
      closedBucketIds: closedIds,
      openBucketIds: openIds,
      networkBucketIds: networkIds,
    );
  }

  @override
  ResumoTotalVendasMunicipioFilialPeriodoFilter filterForBucket({
    required ResumoTotalVendasMunicipioFilialPeriodoFilter rangeFilter,
    required String bucketId,
  }) {
    // One bucket covers the full filter range; do not shrink to a calendar day.
    return rangeFilter;
  }

  @override
  bool get supportsRangeCoalesce => false;

  @override
  List<ResumoTotalVendasMunicipioFilialPeriodoRow> selectRowsForBucket({
    required List<ResumoTotalVendasMunicipioFilialPeriodoRow> rows,
    required String bucketId,
    required ResumoTotalVendasMunicipioFilialPeriodoFilter rangeFilter,
  }) {
    throw UnsupportedError(
      'Range coalesce is not supported for period-range '
      'resumo_total_vendas_municipio_filial_periodo buckets '
      '(bucketId=$bucketId).',
    );
  }

  @override
  ResumoTotalVendasMunicipioFilialPeriodoFilter networkCoalesceFilter({
    required ResumoTotalVendasMunicipioFilialPeriodoFilter rangeFilter,
    required List<String> needNetworkBucketIds,
  }) {
    return rangeFilter;
  }

  @override
  List<ResumoTotalVendasMunicipioFilialPeriodoRow> decodePayload(
    List<int> bytes,
  ) {
    final decoded = jsonDecode(utf8.decode(bytes));
    if (decoded is! List<dynamic>) {
      return const <ResumoTotalVendasMunicipioFilialPeriodoRow>[];
    }
    return decoded
        .map((item) {
          final map = item as Map<String, dynamic>;
          return ResumoTotalVendasMunicipioFilialPeriodoRow(
            codEmpresa: map['codEmpresa'] as int,
            codFilial: map['codFilial'] as int,
            nomeFilial: map['nomeFilial'] as String,
            codMunicipioFilial: map['codMunicipioFilial'] as int?,
            nomeMunicipioFilial: map['nomeMunicipioFilial'] as String?,
            ufMunicipioFilial: map['ufMunicipioFilial'] as String?,
            qtdVendas: map['qtdVendas'] as int,
            totalVenda: (map['totalVenda'] as num).toDouble(),
            nomeFantasiaFilial: map['nomeFantasiaFilial'] as String?,
            cepFilial: map['cepFilial'] as String?,
            codigoIbgeMunicipioFilial:
                map['codigoIbgeMunicipioFilial'] as String?,
          );
        })
        .toList(growable: false);
  }

  @override
  List<int> encodePayload(
    List<ResumoTotalVendasMunicipioFilialPeriodoRow> rows,
  ) {
    final jsonList = rows
        .map(
          (row) => <String, Object?>{
            'codEmpresa': row.codEmpresa,
            'codFilial': row.codFilial,
            'nomeFilial': row.nomeFilial,
            'codMunicipioFilial': row.codMunicipioFilial,
            'nomeMunicipioFilial': row.nomeMunicipioFilial,
            'ufMunicipioFilial': row.ufMunicipioFilial,
            'qtdVendas': row.qtdVendas,
            'totalVenda': row.totalVenda,
            'nomeFantasiaFilial': row.nomeFantasiaFilial,
            'cepFilial': row.cepFilial,
            'codigoIbgeMunicipioFilial': row.codigoIbgeMunicipioFilial,
          },
        )
        .toList(growable: false);
    return utf8.encode(jsonEncode(jsonList));
  }

  @override
  String cacheScopeId(ResumoTotalVendasMunicipioFilialPeriodoFilter filter) {
    return AgentQueryCacheScope.municipioFilialPeriodoScope(filter);
  }

  @override
  String storageKey({
    required String userId,
    required String agentId,
    required String bucketId,
    required ResumoTotalVendasMunicipioFilialPeriodoFilter rangeFilter,
  }) {
    return '${AppKvCacheKeyPrefixes.agentQueryFacts}$userId:$agentId:${factKind.name}:${cacheScopeId(rangeFilter)}:$bucketId';
  }

  @override
  bool isBucketClosed({required String bucketId, required DateTime clock}) {
    final range = CalendarBucketClosure.parsePeriodRangeBucketId(bucketId);
    if (range == null) {
      return false;
    }
    return CalendarBucketClosure.isCalendarDayClosed(
      day: range.end,
      clock: clock,
    );
  }
}
