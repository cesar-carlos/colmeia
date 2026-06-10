import 'package:colmeia/features/client_agents/domain/entities/agent_connection_status.dart';
import 'package:colmeia/features/sales/application/load_sales_live_map_use_case.dart';
import 'package:colmeia/features/sales/domain/load_available_agents_for_sales.dart';
import 'package:colmeia/shared/filters/dashboard_filter.dart';
import 'package:flutter/foundation.dart';

/// Re-applies hub presence to the sales live map agent filter list after a load.
///
/// The approved-agent list comes from [LoadAvailableAgentsForSales]; load
/// results must not replace it with branch-catalog participants (that would
/// pollute multi-user binds and show agents outside the approved set).
abstract final class SalesLiveMapAvailableAgentsAssembler {
  static List<DashboardAgentOption>? rehydrate({
    required List<DashboardAgentOption> previousOptions,
    required Set<String>? onlineAgentIds,
    SalesLiveMapLoadResult? result,
  }) {
    if (previousOptions.isEmpty) {
      return null;
    }

    final namesById = <String, String>{};
    if (result != null) {
      for (final branch in result.branchOptions) {
        namesById[branch.agentId] = branch.agentName;
      }
      for (final agent in result.noSalesAgentOptions) {
        namesById[agent.id] = agent.name;
      }
    }

    final rehydrated = previousOptions
        .map(
          (option) => DashboardAgentOption(
            agentId: option.agentId,
            name: namesById[option.agentId] ?? option.name,
            connectionStatus: _connectionStatusFor(
              onlineAgentIds,
              option.agentId,
            ),
            missingLocalClientToken: option.missingLocalClientToken,
          ),
        )
        .toList(growable: false);

    if (listEquals(previousOptions, rehydrated)) {
      return null;
    }
    return rehydrated;
  }

  static AgentConnectionStatus _connectionStatusFor(
    Set<String>? onlineIds,
    String agentId,
  ) {
    if (onlineIds == null) {
      return AgentConnectionStatus.unknown;
    }
    return onlineIds.contains(agentId)
        ? AgentConnectionStatus.online
        : AgentConnectionStatus.offline;
  }
}
