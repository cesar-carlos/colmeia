import 'package:colmeia/features/agent_queries/domain/entities/agent_query_execution_participant.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_execution_report.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_execution_strategy.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_key.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_target.dart';
import 'package:colmeia/features/agent_queries/domain/entities/cadastro_filial_across_agents_page_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/cadastro_filial_row.dart';
import 'package:colmeia/features/sales/application/load_sales_live_map/sales_live_map_catalog_persister.dart';
import 'package:colmeia/features/sales/application/load_sales_live_map/sales_live_map_in_memory_catalog_cache.dart';
import 'package:colmeia/features/sales/application/ports/sales_live_map_catalog_cache.dart';
import 'package:colmeia/features/sales/application/sales_live_map_catalog_scope.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockSalesLiveMapCatalogCache extends Mock
    implements SalesLiveMapCatalogCache {}

void main() {
  late SalesLiveMapInMemoryCatalogCache memoryCache;
  late _MockSalesLiveMapCatalogCache diskCache;
  late SalesLiveMapCatalogPersister persister;

  final now = DateTime(2026, 5, 27, 18);
  const userId = 'user-1';
  final scope = SalesLiveMapCatalogScope.fullAgent(
    agentIds: const <String>{'agent-a'},
  );
  final page = CadastroFilialAcrossAgentsPageResult.fromReport(
    const AgentQueryExecutionReport<CadastroFilialRow>(
      queryKey: AgentQueryKey.cadastroFilial,
      strategy: AgentQueryExecutionStrategy.mergeAll,
      consideredApprovedAgentCount: 1,
      plannedTargets: <AgentQueryTarget>[],
      missingClientTokenTargets: <AgentQueryTarget>[],
      participants: <AgentQueryExecutionParticipant<CadastroFilialRow>>[],
      totalElapsedMs: 1,
    ),
  );

  setUpAll(() {
    registerFallbackValue(scope);
    registerFallbackValue(page);
  });

  setUp(() {
    memoryCache = SalesLiveMapInMemoryCatalogCache(
      maxEntries: 4,
      ttl: const Duration(minutes: 4),
    );
    diskCache = _MockSalesLiveMapCatalogCache();
    when(
      () => diskCache.write(
        userId: any(named: 'userId'),
        scope: any(named: 'scope'),
        now: any(named: 'now'),
        result: any(named: 'result'),
      ),
    ).thenAnswer((_) async {});
    persister = SalesLiveMapCatalogPersister(
      memoryCache: memoryCache,
      diskCache: diskCache,
    );
  });

  test('persist writes to memory cache immediately', () {
    persister.persist(
      userId: userId,
      scope: scope,
      now: now,
      page: page,
    );

    expect(
      memoryCache.read(userId: userId, scope: scope, now: now),
      same(page),
    );
  });

  test('persist schedules disk cache write', () {
    persister.persist(
      userId: userId,
      scope: scope,
      now: now,
      page: page,
    );

    verify(
      () => diskCache.write(
        userId: userId,
        scope: scope,
        now: now,
        result: page,
      ),
    ).called(1);
  });
}
