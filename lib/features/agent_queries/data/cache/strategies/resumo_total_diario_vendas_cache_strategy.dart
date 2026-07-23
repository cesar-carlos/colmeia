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
import 'package:colmeia/features/agent_queries/domain/entities/resumo_total_diario_vendas_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_total_diario_vendas_row.dart';

final class ResumoTotalDiarioVendasCacheStrategy
    implements
        AgentQueryCacheStrategy<
          ResumoTotalDiarioVendasFilter,
          ResumoTotalDiarioVendasRow
        > {
  const ResumoTotalDiarioVendasCacheStrategy();

  @override
  AgentQueryKey get queryKey => AgentQueryKey.resumoTotalDiarioVendas;

  @override
  AgentQueryFactKind get factKind => AgentQueryFactKind.dailySales;

  @override
  int get schemaVersion => 1;

  @override
  ConsolidationStorageMode get storageMode =>
      ConsolidationStorageMode.persistClosedBuckets;

  @override
  AgentQueryBucketPlan planBuckets({
    required ResumoTotalDiarioVendasFilter filter,
    required DateTime clock,
    required AgentQueryLoadPolicy policy,
  }) {
    final days = CalendarBucketClosure.daysInRange(
      start: filter.dataVendaInicio,
      end: filter.dataVendaFim,
    );
    final allIds = days.map(CalendarBucketClosure.dayBucketId).toList();
    final closedIds = <String>[];
    final openIds = <String>[];
    for (final day in days) {
      final id = CalendarBucketClosure.dayBucketId(day);
      if (isBucketClosed(bucketId: id, clock: clock)) {
        closedIds.add(id);
      } else {
        openIds.add(id);
      }
    }

    final networkIds = policy == AgentQueryLoadPolicy.forceRefresh
        ? List<String>.from(allIds)
        : List<String>.from(openIds);

    return AgentQueryBucketPlan(
      allBucketIdsInRange: allIds,
      closedBucketIds: closedIds,
      openBucketIds: openIds,
      networkBucketIds: networkIds,
    );
  }

  @override
  ResumoTotalDiarioVendasFilter filterForBucket({
    required ResumoTotalDiarioVendasFilter rangeFilter,
    required String bucketId,
  }) {
    final day = CalendarBucketClosure.parseDayBucketId(bucketId);
    if (day == null) {
      return rangeFilter;
    }
    final end = DateTime(day.year, day.month, day.day, 23, 59, 59, 999, 999);
    return ResumoTotalDiarioVendasFilter(
      dataVendaInicio: day,
      dataVendaFim: end,
      origem: rangeFilter.origem,
      geraFinanceiro: rangeFilter.geraFinanceiro,
      preVenda: rangeFilter.preVenda,
    );
  }

  @override
  bool get supportsRangeCoalesce => true;

  @override
  List<ResumoTotalDiarioVendasRow> selectRowsForBucket({
    required List<ResumoTotalDiarioVendasRow> rows,
    required String bucketId,
    required ResumoTotalDiarioVendasFilter rangeFilter,
  }) {
    final day = CalendarBucketClosure.parseDayBucketId(bucketId);
    if (day == null) {
      return const <ResumoTotalDiarioVendasRow>[];
    }
    return rows
        .where(
          (row) =>
              row.dataVenda.year == day.year &&
              row.dataVenda.month == day.month &&
              row.dataVenda.day == day.day,
        )
        .toList(growable: false);
  }

  @override
  ResumoTotalDiarioVendasFilter networkCoalesceFilter({
    required ResumoTotalDiarioVendasFilter rangeFilter,
    required List<String> needNetworkBucketIds,
  }) {
    if (needNetworkBucketIds.isEmpty) {
      return rangeFilter;
    }
    final sorted = List<String>.from(needNetworkBucketIds)..sort();
    final start = CalendarBucketClosure.parseDayBucketId(sorted.first);
    final endDay = CalendarBucketClosure.parseDayBucketId(sorted.last);
    if (start == null || endDay == null) {
      return rangeFilter;
    }
    final end = DateTime(
      endDay.year,
      endDay.month,
      endDay.day,
      23,
      59,
      59,
      999,
      999,
    );
    return ResumoTotalDiarioVendasFilter(
      dataVendaInicio: start,
      dataVendaFim: end,
      origem: rangeFilter.origem,
      geraFinanceiro: rangeFilter.geraFinanceiro,
      preVenda: rangeFilter.preVenda,
    );
  }

  @override
  List<ResumoTotalDiarioVendasRow> decodePayload(List<int> bytes) {
    final decoded = jsonDecode(utf8.decode(bytes));
    if (decoded is! List<dynamic>) {
      return const <ResumoTotalDiarioVendasRow>[];
    }
    return decoded
        .map((item) {
          final map = item as Map<String, dynamic>;
          return ResumoTotalDiarioVendasRow(
            codEmpresa: map['codEmpresa'] as int,
            codFilial: map['codFilial'] as int,
            dataVenda: DateTime.parse(map['dataVenda'] as String),
            qtdVendas: map['qtdVendas'] as int,
            valorTotalDiarioVenda: (map['valorTotalDiarioVenda'] as num)
                .toDouble(),
          );
        })
        .toList(growable: false);
  }

  @override
  List<int> encodePayload(List<ResumoTotalDiarioVendasRow> rows) {
    final jsonList = rows
        .map(
          (row) => <String, Object?>{
            'codEmpresa': row.codEmpresa,
            'codFilial': row.codFilial,
            'dataVenda': row.dataVenda.toIso8601String(),
            'qtdVendas': row.qtdVendas,
            'valorTotalDiarioVenda': row.valorTotalDiarioVenda,
          },
        )
        .toList(growable: false);
    return utf8.encode(jsonEncode(jsonList));
  }

  @override
  String cacheScopeId(ResumoTotalDiarioVendasFilter filter) {
    return AgentQueryCacheScope.dailyScope(filter);
  }

  @override
  String storageKey({
    required String userId,
    required String agentId,
    required String bucketId,
    required ResumoTotalDiarioVendasFilter rangeFilter,
  }) {
    return '${AppKvCacheKeyPrefixes.agentQueryFacts}$userId:$agentId:${factKind.name}:${cacheScopeId(rangeFilter)}:$bucketId';
  }

  @override
  bool isBucketClosed({required String bucketId, required DateTime clock}) {
    final day = CalendarBucketClosure.parseDayBucketId(bucketId);
    if (day == null) {
      return false;
    }
    return CalendarBucketClosure.isCalendarDayClosed(day: day, clock: clock);
  }
}
