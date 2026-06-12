import 'dart:async';

import 'package:colmeia/features/agent_meta/application/agent_rpc_capabilities_registry.dart';
import 'package:colmeia/features/agent_queries/domain/ports/agent_queries_cancel_scope.dart';
import 'package:colmeia/shared/filters/dashboard_filter.dart';

/// Best-effort `rpc.discover` prefetch after overview agent options settle.
final class OverviewRpcCapabilitiesWarmUpCoordinator {
  const OverviewRpcCapabilitiesWarmUpCoordinator();

  void schedule({
    required AgentRpcCapabilitiesRegistry registry,
    required List<DashboardAgentOption> availableAgents,
    required AgentQueriesCancelScope? cancelScope,
  }) {
    if (availableAgents.isEmpty) {
      return;
    }
    final ids = <String>{
      for (final option in availableAgents)
        if (option.agentId.trim().isNotEmpty && !option.missingLocalClientToken)
          option.agentId.trim(),
    };
    if (ids.isEmpty) {
      return;
    }
    unawaited(
      registry.prefetch(
        ids,
        shouldAbort: () => cancelScope?.isCancelled ?? false,
      ),
    );
  }
}
