import 'package:colmeia/features/client_agents/domain/entities/agent_connection_status.dart';
import 'package:colmeia/features/sales/application/load_sales_live_map/sales_live_map_load_result.dart';
import 'package:colmeia/features/sales/domain/entities/sales_live_map_branch_option.dart';
import 'package:colmeia/features/sales/presentation/sales_live_map_available_agents_assembler.dart';
import 'package:colmeia/shared/filters/dashboard_filter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('null hub presence snapshot marks agents as unknown not offline', () {
    const previous = <DashboardAgentOption>[
      DashboardAgentOption(
        agentId: 'agent-1',
        name: 'Agent One',
        connectionStatus: AgentConnectionStatus.offline,
      ),
    ];
    const result = SalesLiveMapLoadResult(
      points: [],
      branchOptions: <SalesLiveMapBranchOption>[],
      totalRevenue: 0,
      totalSalesCount: 0,
      totalBranchCount: 0,
      mappedBranchCount: 0,
      mappedMunicipalityCount: 0,
      queriedAgentCount: 0,
      plannedAgentCount: 0,
      failedAgentCount: 0,
      missingClientTokenAgentCount: 0,
      skippedOfflineAgentCount: 0,
      rowCapReachedAgentCount: 0,
      refreshedAt: null,
    );

    final rehydrated = SalesLiveMapAvailableAgentsAssembler.rehydrate(
      previousOptions: previous,
      onlineAgentIds: result.hubPresenceOnlineAgentIdsSnapshot,
      result: result,
    );

    expect(rehydrated, isNotNull);
    expect(rehydrated!.first.connectionStatus, AgentConnectionStatus.unknown);
  });

  test('hub presence snapshot sets online and offline on existing agents', () {
    const previous = <DashboardAgentOption>[
      DashboardAgentOption(agentId: 'online', name: 'Online'),
      DashboardAgentOption(agentId: 'offline', name: 'Offline'),
    ];
    const result = SalesLiveMapLoadResult(
      points: [],
      branchOptions: <SalesLiveMapBranchOption>[],
      totalRevenue: 0,
      totalSalesCount: 0,
      totalBranchCount: 0,
      mappedBranchCount: 0,
      mappedMunicipalityCount: 0,
      queriedAgentCount: 0,
      plannedAgentCount: 0,
      failedAgentCount: 0,
      missingClientTokenAgentCount: 0,
      skippedOfflineAgentCount: 0,
      rowCapReachedAgentCount: 0,
      refreshedAt: null,
      hubPresenceOnlineAgentIdsSnapshot: {'online'},
    );

    final rehydrated = SalesLiveMapAvailableAgentsAssembler.rehydrate(
      previousOptions: previous,
      onlineAgentIds: result.hubPresenceOnlineAgentIdsSnapshot,
      result: result,
    )!;

    final byId = {for (final a in rehydrated) a.agentId: a.connectionStatus};
    expect(byId['online'], AgentConnectionStatus.online);
    expect(byId['offline'], AgentConnectionStatus.offline);
  });

  test('does not add branch-catalog agents outside the approved list', () {
    const previous = <DashboardAgentOption>[
      DashboardAgentOption(agentId: 'agent-2', name: 'Agent Two'),
    ];
    const result = SalesLiveMapLoadResult(
      points: [],
      branchOptions: <SalesLiveMapBranchOption>[
        SalesLiveMapBranchOption(
          id: 'agent-1-1-1',
          agentId: 'agent-1',
          agentName: 'Agent One',
          codEmpresa: 1,
          codFilial: 1,
          registrationName: 'Branch',
          city: 'City',
          uf: 'MT',
        ),
      ],
      totalRevenue: 0,
      totalSalesCount: 0,
      totalBranchCount: 0,
      mappedBranchCount: 0,
      mappedMunicipalityCount: 0,
      queriedAgentCount: 0,
      plannedAgentCount: 0,
      failedAgentCount: 0,
      missingClientTokenAgentCount: 0,
      skippedOfflineAgentCount: 0,
      rowCapReachedAgentCount: 0,
      refreshedAt: null,
      hubPresenceOnlineAgentIdsSnapshot: {'agent-2'},
    );

    final rehydrated = SalesLiveMapAvailableAgentsAssembler.rehydrate(
      previousOptions: previous,
      onlineAgentIds: result.hubPresenceOnlineAgentIdsSnapshot,
      result: result,
    );

    expect(rehydrated, isNotNull);
    expect(rehydrated!.map((a) => a.agentId).toList(), <String>['agent-2']);
  });
}
