import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/features/agent_queries/data/cache/strategies/resumo_total_vendas_municipio_filial_periodo_cache_strategy.dart';
import 'package:colmeia/features/agent_queries/data/repositories/caching/caching_resumo_total_vendas_municipio_filial_periodo_repository_impl.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_load_policy.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_loaded_rows.dart';
import 'package:colmeia/features/agent_queries/domain/cache/calendar_bucket_closure.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_total_vendas_municipio_filial_periodo_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_total_vendas_municipio_filial_periodo_row.dart';
import 'package:colmeia/features/agent_queries/domain/ports/agent_queries_cancel_scope.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/resumo_total_vendas_municipio_filial_periodo_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:result_dart/result_dart.dart';

import '../../facts/memory_agent_query_facts_store.dart';

void main() {
  const strategy = ResumoTotalVendasMunicipioFilialPeriodoCacheStrategy();
  final clock = DateTime(2026, 6, 3);

  String periodBucketId(ResumoTotalVendasMunicipioFilialPeriodoFilter filter) {
    return CalendarBucketClosure.periodRangeBucketId(
      start: filter.dataVendaInicio,
      end: filter.dataVendaFim,
    );
  }

  group('CachingResumoTotalVendasMunicipioFilialPeriodoRepositoryImpl', () {
    late _FakeDelegate delegate;
    late CachingResumoTotalVendasMunicipioFilialPeriodoRepositoryImpl
    cachingRepo;

    setUp(() {
      delegate = _FakeDelegate();
      cachingRepo =
          CachingResumoTotalVendasMunicipioFilialPeriodoRepositoryImpl(
            delegate: delegate,
            factsStore: memoryAgentQueryFactsStore(),
            clock: () => clock,
          );
    });

    test(
      'defaultLoad reads closed bucket from store without delegate',
      () async {
        final filter = ResumoTotalVendasMunicipioFilialPeriodoFilter(
          dataVendaInicio: DateTime(2026, 6),
          dataVendaFim: DateTime(2026, 6, 1, 23, 59, 59, 999, 999),
        );
        final row = _sampleRow(qtdVendas: 2, totalVenda: 10);
        final storageKey = strategy.storageKey(
          userId: 'u1',
          agentId: 'a1',
          bucketId: periodBucketId(filter),
          rangeFilter: filter,
        );
        await cachingRepo.factsStore.writePayload(
          storageKey: storageKey,
          payload: strategy.encodePayload([row]),
          schemaVersion: strategy.schemaVersion,
        );

        final result = await cachingRepo.load(
          userId: 'u1',
          agentId: 'a1',
          filter: filter,
        );

        final loaded = result.getOrNull();
        expect(loaded, isNotNull);
        expect(loaded!.rows.single.qtdVendas, row.qtdVendas);
        expect(delegate.loadCount, 0);
        expect(delegate.lastCancelScope, isNull);
      },
    );

    test('forceRefresh calls delegate even when store has data', () async {
      final filter = ResumoTotalVendasMunicipioFilialPeriodoFilter(
        dataVendaInicio: DateTime(2026, 6),
        dataVendaFim: DateTime(2026, 6, 1, 23, 59, 59, 999, 999),
      );
      final row = _sampleRow(totalVenda: 5);
      delegate.rows = AgentQueryLoadedRows(rows: [row]);
      final storageKey = strategy.storageKey(
        userId: 'u1',
        agentId: 'a1',
        bucketId: periodBucketId(filter),
        rangeFilter: filter,
      );
      await cachingRepo.factsStore.writePayload(
        storageKey: storageKey,
        payload: strategy.encodePayload([
          _sampleRow(qtdVendas: 99, totalVenda: 99),
        ]),
        schemaVersion: strategy.schemaVersion,
      );

      final result = await cachingRepo.load(
        userId: 'u1',
        agentId: 'a1',
        filter: filter,
        cachePolicy: AgentQueryLoadPolicy.forceRefresh,
      );

      expect(result.getOrNull()?.rows, [row]);
      expect(delegate.loadCount, greaterThan(0));
    });

    test('networkOnly never reads store and always calls delegate', () async {
      final filter = ResumoTotalVendasMunicipioFilialPeriodoFilter(
        dataVendaInicio: DateTime(2026, 6),
        dataVendaFim: DateTime(2026, 6, 1, 23, 59, 59, 999, 999),
      );
      final storageKey = strategy.storageKey(
        userId: 'u1',
        agentId: 'a1',
        bucketId: periodBucketId(filter),
        rangeFilter: filter,
      );
      await cachingRepo.factsStore.writePayload(
        storageKey: storageKey,
        payload: strategy.encodePayload([
          _sampleRow(qtdVendas: 99, totalVenda: 99),
        ]),
        schemaVersion: strategy.schemaVersion,
      );
      delegate.rows = AgentQueryLoadedRows(
        rows: [_sampleRow()],
      );

      final result = await cachingRepo.load(
        userId: 'u1',
        agentId: 'a1',
        filter: filter,
        cachePolicy: AgentQueryLoadPolicy.networkOnly,
      );

      expect(result.getOrNull()?.rows.single.qtdVendas, 1);
      expect(delegate.loadCount, greaterThan(0));
    });

    test('forwards cancelScope to delegate when network is required', () async {
      final filter = ResumoTotalVendasMunicipioFilialPeriodoFilter(
        dataVendaInicio: DateTime(2026, 6, 3),
        dataVendaFim: DateTime(2026, 6, 3, 23, 59, 59, 999, 999),
      );
      delegate.rows = AgentQueryLoadedRows(rows: [_sampleRow()]);
      final cancelScope = AgentQueriesCancelScope(traceId: 'trace-municipio');

      await cachingRepo.load(
        userId: 'u1',
        agentId: 'a1',
        filter: filter,
        cancelScope: cancelScope,
      );

      expect(delegate.loadCount, greaterThan(0));
      expect(delegate.lastCancelScope, same(cancelScope));
    });
  });
}

ResumoTotalVendasMunicipioFilialPeriodoRow _sampleRow({
  int qtdVendas = 1,
  double totalVenda = 1,
}) {
  return ResumoTotalVendasMunicipioFilialPeriodoRow(
    codEmpresa: 1,
    codFilial: 1,
    nomeFilial: 'Filial 1',
    qtdVendas: qtdVendas,
    totalVenda: totalVenda,
  );
}

final class _FakeDelegate
    implements ResumoTotalVendasMunicipioFilialPeriodoRepository {
  int loadCount = 0;
  AgentQueryLoadedRows<ResumoTotalVendasMunicipioFilialPeriodoRow> rows =
      AgentQueryLoadedRows(
        rows: const <ResumoTotalVendasMunicipioFilialPeriodoRow>[],
      );
  AgentQueriesCancelScope? lastCancelScope;

  @override
  Future<
    AppResult<AgentQueryLoadedRows<ResumoTotalVendasMunicipioFilialPeriodoRow>>
  >
  load({
    required String userId,
    required String agentId,
    required ResumoTotalVendasMunicipioFilialPeriodoFilter filter,
    String? clientToken,
    int? bridgeTimeoutMs,
    Set<String>? hubPresenceOnlineAgentIdsSnapshot,
    bool? hubConnectedFromApprovedCatalogRow,
    AgentQueriesCancelScope? cancelScope,
    AgentQueryLoadPolicy cachePolicy = AgentQueryLoadPolicy.defaultLoad,
  }) async {
    loadCount++;
    lastCancelScope = cancelScope;
    return Success<
      AgentQueryLoadedRows<ResumoTotalVendasMunicipioFilialPeriodoRow>,
      AppFailure
    >(rows);
  }
}
