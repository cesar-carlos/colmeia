import 'package:checks/checks.dart';
import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_resumo_vendas_diarias_por_vendedor_across_agents_use_case.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_execution_report.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_execution_strategy.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_key.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_vendas_diarias_por_vendedor_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_vendas_diarias_por_vendedor_row.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/resumo_vendas_diarias_por_vendedor_across_agents_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:result_dart/result_dart.dart';

class _MockResumoAcrossAgentsRepository extends Mock
    implements ResumoVendasDiariasPorVendedorAcrossAgentsRepository {}

void main() {
  late _MockResumoAcrossAgentsRepository repository;
  late LoadResumoVendasDiariasPorVendedorAcrossAgentsUseCase useCase;

  setUpAll(() {
    registerFallbackValue(AgentQueryExecutionStrategy.mergeAll);
    registerFallbackValue(
      ResumoVendasDiariasPorVendedorFilter(
        dataVendaInicio: DateTime.utc(2026, 4),
        dataVendaFim: DateTime.utc(2026, 4, 30),
      ),
    );
  });

  setUp(() {
    repository = _MockResumoAcrossAgentsRepository();
    useCase = LoadResumoVendasDiariasPorVendedorAcrossAgentsUseCase(repository);
  });

  test('should forward arguments to the repository', () async {
    const expectedReport =
        AgentQueryExecutionReport<ResumoVendasDiariasPorVendedorRow>(
          queryKey: AgentQueryKey.resumoVendasDiariasPorVendedor,
          strategy: AgentQueryExecutionStrategy.mergeAll,
          consideredApprovedAgentCount: 1,
          plannedTargets: [],
          missingClientTokenTargets: [],
          participants: [],
          totalElapsedMs: 10,
        );
    when(
      () => repository.load(
        userId: any(named: 'userId'),
        filter: any(named: 'filter'),
        selectedAgentIds: any(named: 'selectedAgentIds'),
        strategy: any(named: 'strategy'),
        bridgeTimeoutMs: any(named: 'bridgeTimeoutMs'),
        raceMaxSources: any(named: 'raceMaxSources'),
      ),
    ).thenAnswer(
      (_) async =>
          const Success<
            AgentQueryExecutionReport<ResumoVendasDiariasPorVendedorRow>,
            AppFailure
          >(expectedReport),
    );

    final filter = ResumoVendasDiariasPorVendedorFilter(
      dataVendaInicio: DateTime.utc(2026, 4),
      dataVendaFim: DateTime.utc(2026, 4, 30),
    );

    final result = await useCase(
      userId: 'user-1',
      filter: filter,
      selectedAgentIds: {'agent-1'},
      strategy: AgentQueryExecutionStrategy.singleSource,
      bridgeTimeoutMs: 5000,
      raceMaxSources: 2,
    );

    check(result.isSuccess()).isTrue();
    verify(
      () => repository.load(
        userId: 'user-1',
        filter: filter,
        selectedAgentIds: {'agent-1'},
        strategy: AgentQueryExecutionStrategy.singleSource,
        bridgeTimeoutMs: 5000,
        raceMaxSources: 2,
      ),
    ).called(1);
  });
}
