import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/features/agent_queries/data/cache/strategies/resumo_produto_venda_lucratividade_cache_strategy.dart';
import 'package:colmeia/features/agent_queries/data/repositories/caching/caching_resumo_produto_venda_lucratividade_repository_impl.dart';
import 'package:colmeia/features/agent_queries/domain/cache/calendar_bucket_closure.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_load_policy.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_produto_venda_lucratividade_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_produto_venda_lucratividade_row.dart';
import 'package:colmeia/features/agent_queries/domain/ports/agent_queries_cancel_scope.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/resumo_produto_venda_lucratividade_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:result_dart/result_dart.dart';

import '../../facts/memory_agent_query_facts_store.dart';

void main() {
  const strategy = ResumoProdutoVendaLucratividadeCacheStrategy();
  final clock = DateTime(2026, 6, 3);

  group('CachingResumoProdutoVendaLucratividadeRepositoryImpl', () {
    late _FakeDelegate delegate;
    late CachingResumoProdutoVendaLucratividadeRepositoryImpl cachingRepo;

    setUp(() {
      delegate = _FakeDelegate();
      cachingRepo = CachingResumoProdutoVendaLucratividadeRepositoryImpl(
        delegate: delegate,
        factsStore: memoryAgentQueryFactsStore(),
        clock: () => clock,
      );
    });

    test(
      'defaultLoad reads closed period bucket from store without delegate',
      () async {
        final filter = ResumoProdutoVendaLucratividadeFilter(
          dataVendaInicio: DateTime(2026, 4, 8),
          dataVendaFim: DateTime(2026, 4, 8, 23, 59, 59, 999, 999),
        );
        const row = ResumoProdutoVendaLucratividadeRow(
          codEmpresa: 1,
          codFilial: 1,
          qtdVendas: 1,
          qtdItensVendido: 1,
          valorTotalCustoMedio: 1,
          custoReposicao: 1,
          pontoEquilibrio: 1,
          valorTotalItem: 10,
        );
        final storageKey = strategy.storageKey(
          userId: 'u1',
          agentId: 'a1',
          bucketId: CalendarBucketClosure.periodRangeBucketId(
            start: filter.dataVendaInicio,
            end: filter.dataVendaFim,
          ),
          rangeFilter: filter,
        );
        await cachingRepo.factsStore.writePayload(
          storageKey: storageKey,
          payload: strategy.encodePayload([row]),
          schemaVersion: strategy.schemaVersion,
        );

        final result = await cachingRepo.loadAll(
          userId: 'u1',
          agentId: 'a1',
          filter: filter,
        );

        expect(result.getOrNull()?.single.valorTotalItem, row.valorTotalItem);
        expect(delegate.loadCount, 0);
      },
    );
  });
}

final class _FakeDelegate implements ResumoProdutoVendaLucratividadeRepository {
  int loadCount = 0;

  @override
  Future<AppResult<List<ResumoProdutoVendaLucratividadeRow>>> loadAll({
    required String userId,
    required String agentId,
    required ResumoProdutoVendaLucratividadeFilter filter,
    String? clientToken,
    int? bridgeTimeoutMs,
    Set<String>? hubPresenceOnlineAgentIdsSnapshot,
    bool? hubConnectedFromApprovedCatalogRow,
    AgentQueriesCancelScope? cancelScope,
    AgentQueryLoadPolicy cachePolicy = AgentQueryLoadPolicy.defaultLoad,
  }) async {
    loadCount++;
    return const Success<List<ResumoProdutoVendaLucratividadeRow>, AppFailure>(
      [],
    );
  }
}
