import 'package:colmeia/features/client_agents/domain/entities/agent_access_request_status.dart';
import 'package:colmeia/features/client_agents/domain/entities/agent_catalog_status.dart';
import 'package:colmeia/features/client_agents/domain/entities/agent_connection_status.dart';
import 'package:colmeia/features/client_agents/domain/entities/client_agent.dart';
import 'package:colmeia/features/client_agents/domain/entities/client_agent_access_request.dart';
import 'package:colmeia/features/client_agents/domain/entities/pending_agent_action.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/widgets/reports/app_report_models.dart';
import 'package:flutter/material.dart';

int clientAgentsApprovedActiveFilterCount(
  AppLocalizations l10n,
  Map<String, Object?> approvedAgentFilters,
) {
  return buildClientAgentsApprovedFilterDescriptors(
    l10n,
  ).where((filter) => filter.hasActiveValue(approvedAgentFilters)).length;
}

int clientAgentsRequestsActiveFilterCount(
  AppLocalizations l10n,
  Map<String, Object?> requestsFilters,
) {
  return buildClientAgentsRequestsFilterDescriptors(
    l10n,
  ).where((filter) => filter.hasActiveValue(requestsFilters)).length;
}

List<AppReportFilterDescriptor> buildClientAgentsApprovedFilterDescriptors(
  AppLocalizations l10n,
) {
  return <AppReportFilterDescriptor>[
    AppReportFilterDescriptor(
      name: 'search',
      label: l10n.clientAgentsFilterSearchLabel,
      type: AppReportFilterType.search,
      hint: l10n.clientAgentsFilterSearchHint,
    ),
    AppReportFilterDescriptor(
      name: 'connectionStatus',
      label: l10n.clientAgentsFilterConnectionLabel,
      type: AppReportFilterType.singleSelect,
      options: <AppReportFilterOption>[
        AppReportFilterOption(
          value: 'online',
          label: l10n.clientAgentsFilterConnectionOnline,
        ),
        AppReportFilterOption(
          value: 'offline',
          label: l10n.clientAgentsFilterConnectionOffline,
        ),
        AppReportFilterOption(
          value: 'unknown',
          label: l10n.clientAgentsFilterConnectionUnknown,
        ),
      ],
    ),
    AppReportFilterDescriptor(
      name: 'catalogStatus',
      label: l10n.clientAgentsFilterCatalogLabel,
      type: AppReportFilterType.singleSelect,
      options: <AppReportFilterOption>[
        AppReportFilterOption(
          value: 'active',
          label: l10n.clientAgentsFilterCatalogActive,
        ),
        AppReportFilterOption(
          value: 'inactive',
          label: l10n.clientAgentsFilterCatalogInactive,
        ),
      ],
    ),
  ];
}

List<AppReportFilterDescriptor> buildClientAgentsRequestsFilterDescriptors(
  AppLocalizations l10n,
) {
  return <AppReportFilterDescriptor>[
    AppReportFilterDescriptor(
      name: 'search',
      label: l10n.clientAgentsRequestsFilterSearchLabel,
      type: AppReportFilterType.search,
      hint: l10n.clientAgentsRequestsFilterSearchHint,
    ),
    AppReportFilterDescriptor(
      name: 'requestStatus',
      label: l10n.clientAgentsRequestsFilterStatusLabel,
      type: AppReportFilterType.singleSelect,
      options: <AppReportFilterOption>[
        AppReportFilterOption(
          value: 'pending',
          label: l10n.clientAgentsRequestStatusPending,
        ),
        AppReportFilterOption(
          value: 'approved',
          label: l10n.clientAgentsRequestStatusApproved,
        ),
        AppReportFilterOption(
          value: 'rejected',
          label: l10n.clientAgentsRequestStatusRejected,
        ),
        AppReportFilterOption(
          value: 'expired',
          label: l10n.clientAgentsRequestStatusExpired,
        ),
        AppReportFilterOption(
          value: 'unknown',
          label: l10n.clientAgentsRequestStatusUnknown,
        ),
      ],
    ),
    AppReportFilterDescriptor(
      name: 'pendingState',
      label: l10n.clientAgentsRequestsFilterPendingLabel,
      type: AppReportFilterType.singleSelect,
      options: <AppReportFilterOption>[
        AppReportFilterOption(
          value: 'queued',
          label: l10n.clientAgentsPendingFilterQueued,
        ),
        AppReportFilterOption(
          value: 'syncing',
          label: l10n.clientAgentsPendingFilterSyncing,
        ),
        AppReportFilterOption(
          value: 'failed',
          label: l10n.clientAgentsPendingFilterFailed,
        ),
        AppReportFilterOption(
          value: 'synced',
          label: l10n.clientAgentsPendingFilterSynced,
        ),
      ],
    ),
  ];
}

List<ClientAgent> filterClientAgentsApprovedList(
  List<ClientAgent> agents,
  Map<String, Object?> approvedAgentFilters,
) {
  var filtered = agents;

  final search = approvedAgentFilters['search'] as String?;
  if (search != null && search.trim().isNotEmpty) {
    final normalized = search.trim().toLowerCase();
    filtered = filtered
        .where((agent) {
          return agent.name.toLowerCase().contains(normalized) ||
              agent.agentId.toLowerCase().contains(normalized) ||
              (agent.tradeName?.toLowerCase().contains(normalized) ?? false);
        })
        .toList(growable: false);
  }

  final connectionStatus = approvedAgentFilters['connectionStatus'] as String?;
  if (connectionStatus != null && connectionStatus.isNotEmpty) {
    filtered = filtered
        .where((agent) {
          return switch (connectionStatus) {
            'online' => agent.connectionStatus == AgentConnectionStatus.online,
            'offline' =>
              agent.connectionStatus == AgentConnectionStatus.offline,
            'unknown' =>
              agent.connectionStatus == AgentConnectionStatus.unknown,
            _ => true,
          };
        })
        .toList(growable: false);
  }

  final catalogStatus = approvedAgentFilters['catalogStatus'] as String?;
  if (catalogStatus != null && catalogStatus.isNotEmpty) {
    filtered = filtered
        .where((agent) {
          return switch (catalogStatus) {
            'active' => agent.catalogStatus == AgentCatalogStatus.active,
            'inactive' => agent.catalogStatus == AgentCatalogStatus.inactive,
            _ => true,
          };
        })
        .toList(growable: false);
  }

  return filtered;
}

/// Drops approved rows when that agent is not in the current approved-agents
/// list (e.g. after the user removed access). Other statuses are kept so
/// pending and historical rejected/expired rows still show.
List<ClientAgentAccessRequest> excludeApprovedRequestsWithoutActiveAgent(
  List<ClientAgentAccessRequest> requests,
  Set<String> activeApprovedAgentIds,
) {
  return requests
      .where((request) {
        if (request.status != AgentAccessRequestStatus.approved) {
          return true;
        }
        return activeApprovedAgentIds.contains(request.agentId);
      })
      .toList(growable: false);
}

List<ClientAgentAccessRequest> filterClientAgentsRequestsList(
  List<ClientAgentAccessRequest> requests,
  Map<String, Object?> requestsFilters,
) {
  var filtered = requests;

  final search = requestsFilters['search'] as String?;
  if (search != null && search.trim().isNotEmpty) {
    final normalized = search.trim().toLowerCase();
    filtered = filtered
        .where((request) {
          return request.agentName.toLowerCase().contains(normalized) ||
              request.agentId.toLowerCase().contains(normalized);
        })
        .toList(growable: false);
  }

  final status = requestsFilters['requestStatus'] as String?;
  if (status != null && status.isNotEmpty) {
    filtered = filtered
        .where((request) {
          return _requestStatusFilterValue(request.status) == status;
        })
        .toList(growable: false);
  }

  return filtered;
}

List<PendingAgentAction> filterClientAgentsPendingActionsList(
  List<PendingAgentAction> actions,
  Map<String, Object?> requestsFilters,
) {
  var filtered = actions;

  final search = requestsFilters['search'] as String?;
  if (search != null && search.trim().isNotEmpty) {
    final normalized = search.trim().toLowerCase();
    filtered = filtered
        .where((action) {
          return action.agentId.toLowerCase().contains(normalized);
        })
        .toList(growable: false);
  }

  final pendingState = requestsFilters['pendingState'] as String?;
  if (pendingState != null && pendingState.isNotEmpty) {
    filtered = filtered
        .where((action) {
          return _pendingActionStateFilterValue(action.state) == pendingState;
        })
        .toList(growable: false);
  }

  return filtered;
}

List<Widget> buildClientAgentsApprovedFilterSummaryChips({
  required AppLocalizations l10n,
  required Map<String, Object?> approvedAgentFilters,
}) {
  final chips = <Widget>[];
  final search = approvedAgentFilters['search'] as String?;
  if (search != null && search.trim().isNotEmpty) {
    chips.add(
      Chip(
        label: Text(l10n.clientAgentsFilterSummarySearch(search.trim())),
      ),
    );
  }

  final connectionStatus = approvedAgentFilters['connectionStatus'] as String?;
  if (connectionStatus != null && connectionStatus.isNotEmpty) {
    chips.add(
      Chip(
        label: Text(
          l10n.clientAgentsFilterSummaryConnection(
            clientAgentsConnectionFilterLabel(connectionStatus, l10n),
          ),
        ),
      ),
    );
  }

  final catalogStatus = approvedAgentFilters['catalogStatus'] as String?;
  if (catalogStatus != null && catalogStatus.isNotEmpty) {
    chips.add(
      Chip(
        label: Text(
          l10n.clientAgentsFilterSummaryCatalog(
            clientAgentsCatalogChipLabel(catalogStatus, l10n),
          ),
        ),
      ),
    );
  }

  return chips;
}

List<Widget> buildClientAgentsRequestsFilterSummaryChips({
  required AppLocalizations l10n,
  required Map<String, Object?> requestsFilters,
}) {
  final chips = <Widget>[];
  final search = requestsFilters['search'] as String?;
  if (search != null && search.trim().isNotEmpty) {
    chips.add(
      Chip(
        label: Text(l10n.clientAgentsFilterSummarySearch(search.trim())),
      ),
    );
  }

  final requestStatus = requestsFilters['requestStatus'] as String?;
  if (requestStatus != null && requestStatus.isNotEmpty) {
    chips.add(
      Chip(
        label: Text(
          l10n.clientAgentsRequestsFilterSummaryRequest(
            clientAgentsRequestStatusChipLabel(requestStatus, l10n),
          ),
        ),
      ),
    );
  }

  final pendingState = requestsFilters['pendingState'] as String?;
  if (pendingState != null && pendingState.isNotEmpty) {
    chips.add(
      Chip(
        label: Text(
          l10n.clientAgentsRequestsFilterSummaryPending(
            clientAgentsPendingStateChipLabel(pendingState, l10n),
          ),
        ),
      ),
    );
  }

  return chips;
}

String clientAgentsConnectionFilterLabel(
  String value,
  AppLocalizations l10n,
) {
  return switch (value) {
    'online' => l10n.clientAgentsFilterConnectionOnline,
    'offline' => l10n.clientAgentsFilterConnectionOffline,
    'unknown' => l10n.clientAgentsFilterConnectionUnknown,
    _ => value,
  };
}

String clientAgentsCatalogChipLabel(String value, AppLocalizations l10n) {
  return switch (value) {
    'active' => l10n.clientAgentsFilterCatalogActive,
    'inactive' => l10n.clientAgentsFilterCatalogInactive,
    _ => value,
  };
}

String _requestStatusFilterValue(AgentAccessRequestStatus status) {
  return switch (status) {
    AgentAccessRequestStatus.pending => 'pending',
    AgentAccessRequestStatus.approved => 'approved',
    AgentAccessRequestStatus.rejected => 'rejected',
    AgentAccessRequestStatus.expired => 'expired',
    AgentAccessRequestStatus.unknown => 'unknown',
  };
}

String _pendingActionStateFilterValue(PendingAgentActionState state) {
  return switch (state) {
    PendingAgentActionState.queued => 'queued',
    PendingAgentActionState.syncing => 'syncing',
    PendingAgentActionState.failed => 'failed',
    PendingAgentActionState.synced => 'synced',
  };
}

String clientAgentsRequestStatusChipLabel(
  String value,
  AppLocalizations l10n,
) {
  return switch (value) {
    'pending' => l10n.clientAgentsRequestStatusPending,
    'approved' => l10n.clientAgentsRequestStatusApproved,
    'rejected' => l10n.clientAgentsRequestStatusRejected,
    'expired' => l10n.clientAgentsRequestStatusExpired,
    'unknown' => l10n.clientAgentsRequestStatusUnknown,
    _ => value,
  };
}

String clientAgentsPendingStateChipLabel(
  String value,
  AppLocalizations l10n,
) {
  return switch (value) {
    'queued' => l10n.clientAgentsPendingChipQueued,
    'syncing' => l10n.clientAgentsPendingChipSyncing,
    'failed' => l10n.clientAgentsPendingChipFailed,
    'synced' => l10n.clientAgentsPendingChipSynced,
    _ => value,
  };
}
