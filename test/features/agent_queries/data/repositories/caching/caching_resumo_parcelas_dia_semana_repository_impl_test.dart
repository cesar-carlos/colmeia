import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/features/agent_queries/data/cache/strategies/resumo_parcelas_dia_semana_cache_strategy.dart';
import 'package:colmeia/features/agent_queries/data/repositories/caching/caching_resumo_parcelas_dia_semana_repository_impl.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_load_policy.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_dia_semana_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_dia_semana_row.dart';
import 'package:colmeia/features/agent_queries/domain/ports/agent_queries_cancel_scope.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/resumo_parcelas_dia_semana_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:result_dart/result_dart.dart';

import '../../facts/memory_agent_query_facts_store.dart';

void main() {
  const strategy = ResumoParcelasDiaSemanaCacheStrategy();
  final clock = DateTime(2026, 6, 3);

  group('CachingResumoParcelasDiaSemanaRepositoryImpl', () {
    late _FakeDelegate delegate;
    late CachingResumoParcelasDiaSemanaRepositoryImpl cachingRepo;

    setUp(() {
      delegate = _FakeDelegate();
      cachingRepo = CachingResumoParcelasDiaSemanaRepositoryImpl(
        delegate: delegate,
        factsStore: memoryAgentQueryFactsStore(),
        clock: () => clock,
      );
    });

    test('defaultLoad reads closed month bucket from store without delegate', () async {
      final filter = ResumoParcelasDiaSemanaFilter(
        dataVendaInicio: DateTime(2026, 4),
        dataVendaFim: DateTime(2026, 4, 30, 23, 59, 59, 999, 999),
      );
      const row = ResumoParcelasDiaSemanaRow(
        codEmpresa: 1,
        codFilial: 1,
        diaSemanaNumero: 1,
        diaSemana: 'Segunda',
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
    });
  });
}

final class _FakeDelegate implements ResumoParcelasDiaSemanaRepository {
  int loadCount = 0;

  @override
  Future<AppResult<List<ResumoParcelasDiaSemanaRow>>> load({
    required String userId,
    required String agentId,
    required ResumoParcelasDiaSemanaFilter filter,
    String? clientToken,
    int? bridgeTimeoutMs,
    Set<String>? hubPresenceOnlineAgentIdsSnapshot,
    bool? hubConnectedFromApprovedCatalogRow,
    AgentQueriesCancelScope? cancelScope,
    AgentQueryLoadPolicy cachePolicy = AgentQueryLoadPolicy.defaultLoad,
  }) async {
    loadCount++;
    return const Success<List<ResumoParcelasDiaSemanaRow>, AppFailure>([]);
  }
}
