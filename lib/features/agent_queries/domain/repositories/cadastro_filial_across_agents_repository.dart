import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_execution_strategy.dart';
import 'package:colmeia/features/agent_queries/domain/entities/cadastro_filial_across_agents_page_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/cadastro_filial_filter.dart';

// ignore: one_member_abstracts -- single entry point matches other across-agents repositories.
abstract interface class CadastroFilialAcrossAgentsRepository {
  Future<AppResult<CadastroFilialAcrossAgentsPageResult>> loadPage({
    required String userId,
    required CadastroFilialFilter filter,
    Set<String>? selectedAgentIds,
    AgentQueryExecutionStrategy strategy = AgentQueryExecutionStrategy.mergeAll,
    int? bridgeTimeoutMs,
    int? raceMaxSources,
  });
}
