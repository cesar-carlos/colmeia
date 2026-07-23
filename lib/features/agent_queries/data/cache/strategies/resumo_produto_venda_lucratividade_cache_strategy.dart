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
import 'package:colmeia/features/agent_queries/domain/entities/resumo_produto_venda_lucratividade_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_produto_venda_lucratividade_row.dart';

final class ResumoProdutoVendaLucratividadeCacheStrategy
    implements
        AgentQueryCacheStrategy<
          ResumoProdutoVendaLucratividadeFilter,
          ResumoProdutoVendaLucratividadeRow
        > {
  const ResumoProdutoVendaLucratividadeCacheStrategy();

  @override
  AgentQueryKey get queryKey => AgentQueryKey.resumoProdutoVendaLucratividade;

  @override
  AgentQueryFactKind get factKind => AgentQueryFactKind.lucratividadePeriod;

  /// Bumped when storage moved from per-day buckets to one period-range bucket.
  @override
  int get schemaVersion => 2;

  @override
  ConsolidationStorageMode get storageMode =>
      ConsolidationStorageMode.persistClosedBuckets;

  @override
  AgentQueryBucketPlan planBuckets({
    required ResumoProdutoVendaLucratividadeFilter filter,
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
  ResumoProdutoVendaLucratividadeFilter filterForBucket({
    required ResumoProdutoVendaLucratividadeFilter rangeFilter,
    required String bucketId,
  }) {
    return rangeFilter;
  }

  @override
  bool get supportsRangeCoalesce => false;

  @override
  List<ResumoProdutoVendaLucratividadeRow> selectRowsForBucket({
    required List<ResumoProdutoVendaLucratividadeRow> rows,
    required String bucketId,
    required ResumoProdutoVendaLucratividadeFilter rangeFilter,
  }) {
    throw UnsupportedError(
      'Range coalesce is not supported for period-range '
      'resumo_produto_venda_lucratividade buckets (bucketId=$bucketId).',
    );
  }

  @override
  ResumoProdutoVendaLucratividadeFilter networkCoalesceFilter({
    required ResumoProdutoVendaLucratividadeFilter rangeFilter,
    required List<String> needNetworkBucketIds,
  }) {
    return rangeFilter;
  }

  @override
  List<ResumoProdutoVendaLucratividadeRow> decodePayload(List<int> bytes) {
    final decoded = jsonDecode(utf8.decode(bytes));
    if (decoded is! List<dynamic>) {
      return const <ResumoProdutoVendaLucratividadeRow>[];
    }
    return decoded
        .map((item) {
          final map = item as Map<String, dynamic>;
          return ResumoProdutoVendaLucratividadeRow(
            codEmpresa: map['codEmpresa'] as int,
            codFilial: map['codFilial'] as int,
            qtdVendas: map['qtdVendas'] as int,
            qtdItensVendido: (map['qtdItensVendido'] as num).toDouble(),
            valorTotalCustoMedio: (map['valorTotalCustoMedio'] as num)
                .toDouble(),
            custoReposicao: (map['custoReposicao'] as num).toDouble(),
            pontoEquilibrio: (map['pontoEquilibrio'] as num).toDouble(),
            valorTotalItem: (map['valorTotalItem'] as num).toDouble(),
            chartAxisLabel: map['chartAxisLabel'] as String?,
          );
        })
        .toList(growable: false);
  }

  @override
  List<int> encodePayload(List<ResumoProdutoVendaLucratividadeRow> rows) {
    final jsonList = rows
        .map(
          (row) => <String, Object?>{
            'codEmpresa': row.codEmpresa,
            'codFilial': row.codFilial,
            'qtdVendas': row.qtdVendas,
            'qtdItensVendido': row.qtdItensVendido,
            'valorTotalCustoMedio': row.valorTotalCustoMedio,
            'custoReposicao': row.custoReposicao,
            'pontoEquilibrio': row.pontoEquilibrio,
            'valorTotalItem': row.valorTotalItem,
            'chartAxisLabel': row.chartAxisLabel,
          },
        )
        .toList(growable: false);
    return utf8.encode(jsonEncode(jsonList));
  }

  @override
  String cacheScopeId(ResumoProdutoVendaLucratividadeFilter filter) {
    return AgentQueryCacheScope.lucratividadeScope(filter);
  }

  @override
  String storageKey({
    required String userId,
    required String agentId,
    required String bucketId,
    required ResumoProdutoVendaLucratividadeFilter rangeFilter,
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
