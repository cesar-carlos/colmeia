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
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_mensal_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_mensal_row.dart';

final class ResumoParcelasMensalCacheStrategy
    implements
        AgentQueryCacheStrategy<ResumoParcelasMensalFilter, ResumoParcelasMensalRow> {
  const ResumoParcelasMensalCacheStrategy();

  @override
  AgentQueryKey get queryKey => AgentQueryKey.resumoParcelasMensal;

  @override
  AgentQueryFactKind get factKind => AgentQueryFactKind.monthlyParcels;

  @override
  int get schemaVersion => 1;

  @override
  ConsolidationStorageMode get storageMode =>
      ConsolidationStorageMode.persistClosedBuckets;

  @override
  AgentQueryBucketPlan planBuckets({
    required ResumoParcelasMensalFilter filter,
    required DateTime clock,
    required AgentQueryLoadPolicy policy,
  }) {
    final months = CalendarBucketClosure.monthsInRange(
      start: filter.dataVendaInicio,
      end: filter.dataVendaFim,
    );
    final allIds = months
        .map((m) => CalendarBucketClosure.monthBucketId(year: m.year, month: m.month))
        .toList();
    final closedIds = <String>[];
    final openIds = <String>[];
    for (final month in months) {
      final id = CalendarBucketClosure.monthBucketId(
        year: month.year,
        month: month.month,
      );
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
  ResumoParcelasMensalFilter filterForBucket({
    required ResumoParcelasMensalFilter rangeFilter,
    required String bucketId,
  }) {
    final parsed = CalendarBucketClosure.parseMonthBucketId(bucketId);
    if (parsed == null) {
      return rangeFilter;
    }
    final start = DateTime(parsed.year, parsed.month);
    final end = DateTime(parsed.year, parsed.month + 1)
        .subtract(const Duration(microseconds: 1));
    return ResumoParcelasMensalFilter(
      dataVendaInicio: start,
      dataVendaFim: end,
      origem: rangeFilter.origem,
      geraFinanceiro: rangeFilter.geraFinanceiro,
      preVenda: rangeFilter.preVenda,
      codEmpresa: rangeFilter.codEmpresa,
      codFilial: rangeFilter.codFilial,
      codVendedor: rangeFilter.codVendedor,
    );
  }

  @override
  List<ResumoParcelasMensalRow> decodePayload(List<int> bytes) {
    final decoded = jsonDecode(utf8.decode(bytes));
    if (decoded is! List<dynamic>) {
      return const <ResumoParcelasMensalRow>[];
    }
    return decoded
        .map((item) {
          final map = item as Map<String, dynamic>;
          return ResumoParcelasMensalRow(
            codEmpresa: map['codEmpresa'] as int,
            codFilial: map['codFilial'] as int,
            ano: map['ano'] as int,
            mes: map['mes'] as int,
            anoMes: map['anoMes'] as String,
            qtdVendas: map['qtdVendas'] as int,
            valorParcela: (map['valorParcela'] as num).toDouble(),
          );
        })
        .toList(growable: false);
  }

  @override
  List<int> encodePayload(List<ResumoParcelasMensalRow> rows) {
    final jsonList = rows
        .map(
          (row) => <String, Object?>{
            'codEmpresa': row.codEmpresa,
            'codFilial': row.codFilial,
            'ano': row.ano,
            'mes': row.mes,
            'anoMes': row.anoMes,
            'qtdVendas': row.qtdVendas,
            'valorParcela': row.valorParcela,
          },
        )
        .toList(growable: false);
    return utf8.encode(jsonEncode(jsonList));
  }

  @override
  String cacheScopeId(ResumoParcelasMensalFilter filter) {
    return AgentQueryCacheScope.mensalScope(filter);
  }

  @override
  String storageKey({
    required String userId,
    required String agentId,
    required String bucketId,
    required ResumoParcelasMensalFilter rangeFilter,
  }) {
    return '${AppKvCacheKeyPrefixes.agentQueryFacts}$userId:$agentId:${factKind.name}:${cacheScopeId(rangeFilter)}:$bucketId';
  }

  @override
  bool isBucketClosed({required String bucketId, required DateTime clock}) {
    final parsed = CalendarBucketClosure.parseMonthBucketId(bucketId);
    if (parsed == null) {
      return false;
    }
    return CalendarBucketClosure.isCalendarMonthClosed(
      year: parsed.year,
      month: parsed.month,
      clock: clock,
    );
  }
}
