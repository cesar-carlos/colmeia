import 'package:checks/checks.dart';
import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_cadastro_filial_across_agents_use_case.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_execution_report.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_execution_strategy.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_key.dart';
import 'package:colmeia/features/agent_queries/domain/entities/cadastro_filial_across_agents_page_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/cadastro_filial_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/cadastro_filial_row.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/cadastro_filial_across_agents_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:result_dart/result_dart.dart';

class _MockCadastroFilialAcrossAgentsRepository extends Mock
    implements CadastroFilialAcrossAgentsRepository {}

void main() {
  late _MockCadastroFilialAcrossAgentsRepository repository;
  late LoadCadastroFilialAcrossAgentsUseCase useCase;

  setUp(() {
    repository = _MockCadastroFilialAcrossAgentsRepository();
    useCase = LoadCadastroFilialAcrossAgentsUseCase(repository);
  });

  test('forwards to CadastroFilialAcrossAgentsRepository.loadPage', () async {
    const strategy = AgentQueryExecutionStrategy.mergeAll;

    when(
      () => repository.loadPage(
        userId: 'user-1',
        filter: const CadastroFilialFilter(codEmpresa: 1),
        selectedAgentIds: const <String>{'agent-1'},
        // ignore: avoid_redundant_argument_values, test verifies forwarding.
        strategy: strategy,
        bridgeTimeoutMs: 5000,
        raceMaxSources: 2,
      ),
    ).thenAnswer(
      (_) async =>
          const Success<CadastroFilialAcrossAgentsPageResult, AppFailure>(
            CadastroFilialAcrossAgentsPageResult(
              report: AgentQueryExecutionReport<CadastroFilialRow>(
                queryKey: AgentQueryKey.cadastroFilial,
                strategy: strategy,
                consideredApprovedAgentCount: 0,
                plannedTargets: [],
                missingClientTokenTargets: [],
                participants: [],
                totalElapsedMs: 0,
              ),
              totalCountByAgentId: <String, int>{},
            ),
          ),
    );

    final out = await useCase.call(
      userId: 'user-1',
      filter: const CadastroFilialFilter(codEmpresa: 1),
      selectedAgentIds: const <String>{'agent-1'},
      bridgeTimeoutMs: 5000,
      raceMaxSources: 2,
    );

    check(out.isSuccess()).isTrue();
    verify(
      () => repository.loadPage(
        userId: 'user-1',
        filter: const CadastroFilialFilter(codEmpresa: 1),
        selectedAgentIds: const <String>{'agent-1'},
        // ignore: avoid_redundant_argument_values, test verifies forwarding.
        strategy: strategy,
        bridgeTimeoutMs: 5000,
        raceMaxSources: 2,
      ),
    ).called(1);
  });
}
