import 'package:colmeia/features/agent_queries/domain/cache/agent_query_facts_store.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_load_policy.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_mensal_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_mensal_row.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_total_diario_vendas_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_total_diario_vendas_row.dart';
import 'package:colmeia/features/overview/data/overview_batch_facts_persister.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockFactsStore extends Mock implements AgentQueryFactsStore {}

void main() {
  late _MockFactsStore factsStore;
  late OverviewBatchFactsPersister persister;

  final clock = DateTime(2026, 4, 8);

  setUp(() {
    factsStore = _MockFactsStore();
    persister = OverviewBatchFactsPersister(
      factsStore: factsStore,
      clock: () => clock,
    );
    when(
      () => factsStore.writePayload(
        storageKey: any(named: 'storageKey'),
        payload: any(named: 'payload'),
        schemaVersion: any(named: 'schemaVersion'),
      ),
    ).thenAnswer((_) async {});
  });

  test('persistDailyRows writes closed day buckets only', () async {
    final filter = ResumoTotalDiarioVendasFilter(
      dataVendaInicio: DateTime(2026, 4),
      dataVendaFim: DateTime(2026, 4, 7),
    );

    await persister.persistDailyRows(
      userId: 'user-1',
      agentId: 'agent-1',
      filter: filter,
      rows: [
        ResumoTotalDiarioVendasRow(
          codEmpresa: 1,
          codFilial: 1,
          dataVenda: DateTime(2026, 4, 7),
          qtdVendas: 2,
          valorTotalDiarioVenda: 50,
        ),
      ],
    );

    verify(
      () => factsStore.writePayload(
        storageKey: any(named: 'storageKey'),
        payload: any(named: 'payload'),
        schemaVersion: any(named: 'schemaVersion'),
      ),
    ).called(greaterThan(0));
  });

  test('persistDailyRows skips when policy is forceRefresh', () async {
    await persister.persistDailyRows(
      userId: 'user-1',
      agentId: 'agent-1',
      filter: ResumoTotalDiarioVendasFilter(
        dataVendaInicio: DateTime(2026, 4),
        dataVendaFim: DateTime(2026, 4, 7),
      ),
      rows: const <ResumoTotalDiarioVendasRow>[],
      cachePolicy: AgentQueryLoadPolicy.forceRefresh,
    );

    verifyNever(
      () => factsStore.writePayload(
        storageKey: any(named: 'storageKey'),
        payload: any(named: 'payload'),
        schemaVersion: any(named: 'schemaVersion'),
      ),
    );
  });

  test('persistMonthlyRows writes closed month buckets', () async {
    final filter = ResumoParcelasMensalFilter(
      dataVendaInicio: DateTime(2026),
      dataVendaFim: DateTime(2026, 3, 31),
    );

    await persister.persistMonthlyRows(
      userId: 'user-1',
      agentId: 'agent-1',
      filter: filter,
      rows: const [
        ResumoParcelasMensalRow(
          codEmpresa: 1,
          codFilial: 1,
          ano: 2026,
          mes: 2,
          anoMes: '2026/02',
          qtdVendas: 1,
          valorParcela: 10,
        ),
      ],
    );

    verify(
      () => factsStore.writePayload(
        storageKey: any(named: 'storageKey'),
        payload: any(named: 'payload'),
        schemaVersion: any(named: 'schemaVersion'),
      ),
    ).called(greaterThan(0));
  });
}
