import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/features/agent_queries/data/cache/strategies/resumo_parcelas_mensal_cache_strategy.dart';
import 'package:colmeia/features/agent_queries/data/repositories/caching/caching_resumo_parcelas_mensal_repository_impl.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_load_policy.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_mensal_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_mensal_row.dart';
import 'package:colmeia/features/agent_queries/domain/ports/agent_queries_cancel_scope.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/resumo_parcelas_mensal_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:result_dart/result_dart.dart';

import '../../facts/memory_agent_query_facts_store.dart';

void main() {
  const strategy = ResumoParcelasMensalCacheStrategy();
  final clock = DateTime(2026, 6, 3);

  group('CachingResumoParcelasMensalRepositoryImpl', () {
    late _FakeDelegate delegate;
    late CachingResumoParcelasMensalRepositoryImpl cachingRepo;

    setUp(() {
      delegate = _FakeDelegate();
      cachingRepo = CachingResumoParcelasMensalRepositoryImpl(
        delegate: delegate,
        factsStore: memoryAgentQueryFactsStore(),
        clock: () => clock,
      );
    });

    test(
      'defaultLoad reads closed month bucket from store without delegate',
      () async {
        final filter = ResumoParcelasMensalFilter(
          dataVendaInicio: DateTime(2026, 4),
          dataVendaFim: DateTime(2026, 4, 30, 23, 59, 59, 999, 999),
        );
        const row = ResumoParcelasMensalRow(
          codEmpresa: 1,
          codFilial: 1,
          ano: 2026,
          mes: 4,
          anoMes: '2026/04',
          qtdVendas: 2,
          valorParcela: 10,
        );
        final storageKey = strategy.storageKey(
          userId: 'u1',
          agentId: 'a1',
          bucketId: '2026-04',
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

        expect(result.getOrNull()?.single.qtdVendas, row.qtdVendas);
        expect(delegate.loadCount, 0);
      },
    );

    test('forceRefresh calls delegate even when store has data', () async {
      final filter = ResumoParcelasMensalFilter(
        dataVendaInicio: DateTime(2026, 4),
        dataVendaFim: DateTime(2026, 4, 30, 23, 59, 59, 999, 999),
      );
      final storageKey = strategy.storageKey(
        userId: 'u1',
        agentId: 'a1',
        bucketId: '2026-04',
        rangeFilter: filter,
      );
      await cachingRepo.factsStore.writePayload(
        storageKey: storageKey,
        payload: strategy.encodePayload([
          const ResumoParcelasMensalRow(
            codEmpresa: 1,
            codFilial: 1,
            ano: 2026,
            mes: 4,
            anoMes: '2026/04',
            qtdVendas: 99,
            valorParcela: 99,
          ),
        ]),
        schemaVersion: strategy.schemaVersion,
      );
      delegate.rows = [
        const ResumoParcelasMensalRow(
          codEmpresa: 1,
          codFilial: 1,
          ano: 2026,
          mes: 4,
          anoMes: '2026/04',
          qtdVendas: 1,
          valorParcela: 5,
        ),
      ];

      final result = await cachingRepo.load(
        userId: 'u1',
        agentId: 'a1',
        filter: filter,
        cachePolicy: AgentQueryLoadPolicy.forceRefresh,
      );

      expect(result.getOrNull()?.single.valorParcela, 5);
      expect(delegate.loadCount, greaterThan(0));
    });
  });
}

final class _FakeDelegate implements ResumoParcelasMensalRepository {
  int loadCount = 0;
  List<ResumoParcelasMensalRow> rows = const <ResumoParcelasMensalRow>[];

  @override
  Future<AppResult<List<ResumoParcelasMensalRow>>> load({
    required String userId,
    required String agentId,
    required ResumoParcelasMensalFilter filter,
    String? clientToken,
    int? bridgeTimeoutMs,
    Set<String>? hubPresenceOnlineAgentIdsSnapshot,
    bool? hubConnectedFromApprovedCatalogRow,
    AgentQueriesCancelScope? cancelScope,
    AgentQueryLoadPolicy cachePolicy = AgentQueryLoadPolicy.defaultLoad,
  }) async {
    loadCount++;
    return Success<List<ResumoParcelasMensalRow>, AppFailure>(rows);
  }
}
