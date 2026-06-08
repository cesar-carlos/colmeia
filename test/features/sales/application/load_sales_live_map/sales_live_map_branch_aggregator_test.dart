import 'package:checks/checks.dart';
import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_execution_participant.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_execution_report.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_execution_strategy.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_key.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_target.dart';
import 'package:colmeia/features/agent_queries/domain/entities/cadastro_filial_row.dart';
import 'package:colmeia/features/client_agents/domain/entities/agent_connection_status.dart';
import 'package:colmeia/features/sales/application/load_sales_live_map/sales_live_map_branch_aggregator.dart';
import 'package:colmeia/features/sales/application/sales_live_map_internal_labels.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const aggregator = SalesLiveMapBranchAggregator();

  group('SalesLiveMapBranchAggregator.combinedFailedAgentCount', () {
    test(
      'returns plannedTargets when both catalog and sales sides are missing',
      () {
        final count = aggregator.combinedFailedAgentCount(
          catalogReport: null,
          salesReport: null,
          catalogFailure: const NetworkFailure(message: 'catalog down'),
          salesFailure: const NetworkFailure(message: 'sales down'),
          plannedTargets: 5,
        );

        check(count).equals(5);
      },
    );

    test(
      'counts catalog failures plus catalog-success agents when sales fails globally',
      () {
        final catalogReport = _catalogReport(
          participants: <AgentQueryExecutionParticipant<CadastroFilialRow>>[
            _catalogParticipant('agent-1'),
            _catalogParticipant(
              'agent-2',
              failure: const NetworkFailure(message: 'catalog failed'),
            ),
            _catalogParticipant('agent-3'),
          ],
          plannedTargets: _targets(const <String>[
            'agent-1',
            'agent-2',
            'agent-3',
          ]),
        );

        final count = aggregator.combinedFailedAgentCount(
          catalogReport: catalogReport,
          salesReport: null,
          catalogFailure: null,
          salesFailure: const NetworkFailure(message: 'sales down'),
          plannedTargets: 3,
        );

        check(count).equals(3);
      },
    );

    test('does not inflate to plannedTargets when catalog report exists', () {
      final catalogReport = _catalogReport(
        participants: <AgentQueryExecutionParticipant<CadastroFilialRow>>[
          _catalogParticipant('agent-1'),
          _catalogParticipant(
            'agent-2',
            failure: const NetworkFailure(message: 'catalog failed'),
          ),
          _catalogParticipant('agent-3'),
        ],
        plannedTargets: _targets(
          const <String>['agent-1', 'agent-2', 'agent-3', 'agent-4', 'agent-5'],
        ),
      );

      final count = aggregator.combinedFailedAgentCount(
        catalogReport: catalogReport,
        salesReport: null,
        catalogFailure: null,
        salesFailure: const NetworkFailure(message: 'sales down'),
        plannedTargets: 5,
      );

      check(count).equals(3);
    });
  });

  group('SalesLiveMapBranchAggregator.salesUnavailableLabelsByAgentId', () {
    test('uses internal fallback label when failure has no user message', () {
      final catalogReport = _catalogReport(
        participants: <AgentQueryExecutionParticipant<CadastroFilialRow>>[
          _catalogParticipant('agent-1'),
        ],
        plannedTargets: _targets(const <String>['agent-1']),
      );

      final labels = aggregator.salesUnavailableLabelsByAgentId(
        catalogReport: catalogReport,
        salesReport: null,
        salesFailure: const NetworkFailure(message: 'sales down'),
      );

      check(
        labels['agent-1'],
      ).equals(SalesLiveMapInternalLabels.salesUnavailableFallback);
    });
  });
}

List<AgentQueryTarget> _targets(List<String> agentIds) {
  return agentIds
      .map(
        (agentId) => AgentQueryTarget(
          agentId: agentId,
          displayName: agentId,
          clientToken: 'token',
          connectionStatus: AgentConnectionStatus.online,
          hubConnectedFromApprovedCatalogRow: true,
        ),
      )
      .toList(growable: false);
}

AgentQueryExecutionReport<CadastroFilialRow> _catalogReport({
  required List<AgentQueryExecutionParticipant<CadastroFilialRow>> participants,
  required List<AgentQueryTarget> plannedTargets,
}) {
  return AgentQueryExecutionReport<CadastroFilialRow>(
    queryKey: AgentQueryKey.cadastroFilial,
    strategy: AgentQueryExecutionStrategy.mergeAll,
    consideredApprovedAgentCount: plannedTargets.length,
    plannedTargets: plannedTargets,
    missingClientTokenTargets: const <AgentQueryTarget>[],
    participants: participants,
    totalElapsedMs: 1,
  );
}

AgentQueryExecutionParticipant<CadastroFilialRow> _catalogParticipant(
  String agentId, {
  AppFailure? failure,
}) {
  return AgentQueryExecutionParticipant<CadastroFilialRow>(
    agentId: agentId,
    displayName: agentId,
    rows: failure == null
        ? const <CadastroFilialRow>[
            CadastroFilialRow(
              codEmpresa: 1,
              codFilial: 1,
              nomeFilial: 'Filial',
              nomeFantasia: 'Fantasia',
              cep: '78005123',
              nomeMunicipio: 'Cuiaba',
              codigoIbge: '5103403',
              ufMunicipio: 'MT',
            ),
          ]
        : const <CadastroFilialRow>[],
    failure: failure,
    elapsedMs: 1,
  );
}
