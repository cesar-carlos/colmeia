import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/features/agent_queries/data/cache/strategies/resumo_total_diario_vendas_cache_strategy.dart';
import 'package:colmeia/features/agent_queries/data/repositories/caching/caching_resumo_total_diario_vendas_repository_impl.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_load_policy.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_total_diario_vendas_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_total_diario_vendas_row.dart';
import 'package:colmeia/features/agent_queries/domain/ports/agent_queries_cancel_scope.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/resumo_total_diario_vendas_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:result_dart/result_dart.dart';

import '../../facts/memory_agent_query_facts_store.dart';

void main() {
  const strategy = ResumoTotalDiarioVendasCacheStrategy();
  final clock = DateTime(2026, 6, 3);

  group('CachingResumoTotalDiarioVendasRepositoryImpl', () {
    late _FakeDelegate delegate;
    late CachingResumoTotalDiarioVendasRepositoryImpl cachingRepo;

    setUp(() {
      delegate = _FakeDelegate();
      cachingRepo = CachingResumoTotalDiarioVendasRepositoryImpl(
        delegate: delegate,
        factsStore: memoryAgentQueryFactsStore(),
        clock: () => clock,
      );
    });

    test('defaultLoad reads closed bucket from store without delegate', () async {
      final filter = ResumoTotalDiarioVendasFilter(
        dataVendaInicio: DateTime(2026, 6),
        dataVendaFim: DateTime(2026, 6, 1, 23, 59, 59, 999, 999),
      );
      final row = ResumoTotalDiarioVendasRow(
        codEmpresa: 1,
        codFilial: 1,
        dataVenda: DateTime(2026, 6),
        qtdVendas: 2,
        valorTotalDiarioVenda: 10,
      );
      final storageKey = strategy.storageKey(
        userId: 'u1',
        agentId: 'a1',
        bucketId: '2026-06-01',
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
      expect(loaded!.single.qtdVendas, row.qtdVendas);
      expect(delegate.loadCount, 0);
    });

    test('forceRefresh calls delegate even when store has data', () async {
      final filter = ResumoTotalDiarioVendasFilter(
        dataVendaInicio: DateTime(2026, 6),
        dataVendaFim: DateTime(2026, 6, 1, 23, 59, 59, 999, 999),
      );
      final row = ResumoTotalDiarioVendasRow(
        codEmpresa: 1,
        codFilial: 1,
        dataVenda: DateTime(2026, 6),
        qtdVendas: 1,
        valorTotalDiarioVenda: 5,
      );
      delegate.rows = [row];
      final storageKey = strategy.storageKey(
        userId: 'u1',
        agentId: 'a1',
        bucketId: '2026-06-01',
        rangeFilter: filter,
      );
      await cachingRepo.factsStore.writePayload(
        storageKey: storageKey,
        payload: strategy.encodePayload([
          ResumoTotalDiarioVendasRow(
            codEmpresa: 1,
            codFilial: 1,
            dataVenda: DateTime(2026, 6),
            qtdVendas: 99,
            valorTotalDiarioVenda: 99,
          ),
        ]),
        schemaVersion: strategy.schemaVersion,
      );

      final result = await cachingRepo.load(
        userId: 'u1',
        agentId: 'a1',
        filter: filter,
        cachePolicy: AgentQueryLoadPolicy.forceRefresh,
      );

      expect(result.getOrNull(), [row]);
      expect(delegate.loadCount, greaterThan(0));
    });

    test('networkOnly never reads store and always calls delegate', () async {
      final filter = ResumoTotalDiarioVendasFilter(
        dataVendaInicio: DateTime(2026, 6),
        dataVendaFim: DateTime(2026, 6, 1, 23, 59, 59, 999, 999),
      );
      final storageKey = strategy.storageKey(
        userId: 'u1',
        agentId: 'a1',
        bucketId: '2026-06-01',
        rangeFilter: filter,
      );
      await cachingRepo.factsStore.writePayload(
        storageKey: storageKey,
        payload: strategy.encodePayload([
          ResumoTotalDiarioVendasRow(
            codEmpresa: 1,
            codFilial: 1,
            dataVenda: DateTime(2026, 6),
            qtdVendas: 99,
            valorTotalDiarioVenda: 99,
          ),
        ]),
        schemaVersion: strategy.schemaVersion,
      );
      delegate.rows = [
        ResumoTotalDiarioVendasRow(
          codEmpresa: 1,
          codFilial: 1,
          dataVenda: DateTime(2026, 6),
          qtdVendas: 1,
          valorTotalDiarioVenda: 1,
        ),
      ];

      final result = await cachingRepo.load(
        userId: 'u1',
        agentId: 'a1',
        filter: filter,
        cachePolicy: AgentQueryLoadPolicy.networkOnly,
      );

      expect(result.getOrNull()?.single.qtdVendas, 1);
      expect(delegate.loadCount, greaterThan(0));
    });
  });
}

final class _FakeDelegate implements ResumoTotalDiarioVendasRepository {
  int loadCount = 0;
  List<ResumoTotalDiarioVendasRow> rows = const <ResumoTotalDiarioVendasRow>[];

  @override
  Future<AppResult<List<ResumoTotalDiarioVendasRow>>> load({
    required String userId,
    required String agentId,
    required ResumoTotalDiarioVendasFilter filter,
    String? clientToken,
    int? bridgeTimeoutMs,
    Set<String>? hubPresenceOnlineAgentIdsSnapshot,
    bool? hubConnectedFromApprovedCatalogRow,
    AgentQueriesCancelScope? cancelScope,
    AgentQueryLoadPolicy cachePolicy = AgentQueryLoadPolicy.defaultLoad,
  }) async {
    loadCount++;
    return Success<List<ResumoTotalDiarioVendasRow>, AppFailure>(rows);
  }
}
