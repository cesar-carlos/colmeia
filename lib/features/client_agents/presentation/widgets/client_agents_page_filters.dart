import 'dart:convert';

import 'package:colmeia/core/preferences/persisted_filter_map_codec.dart';
import 'package:colmeia/core/preferences/persisted_page_session_store.dart';
import 'package:colmeia/features/client_agents/domain/entities/agent_access_request_status.dart';
import 'package:colmeia/features/client_agents/domain/entities/agent_catalog_status.dart';
import 'package:colmeia/features/client_agents/domain/entities/agent_connection_status.dart';
import 'package:colmeia/features/client_agents/domain/entities/client_agent.dart';
import 'package:colmeia/features/client_agents/domain/entities/client_agent_access_request.dart';
import 'package:colmeia/features/client_agents/domain/entities/pending_agent_action.dart';
import 'package:colmeia/features/client_agents/presentation/utils/client_agent_id_format.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/widgets/reports/app_report_models.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _kClientAgentsSessionNamespace = 'client_agents';
const String _kApprovedFiltersKey = 'approved_filters.v1';
const String _kRequestsFiltersKey = 'requests_filters.v1';
const String _kRequestAccessDraftKey = 'request_access_draft.v1';
const String _kRequestAccessDraftV2Key = 'request_access_draft.v2';
const String _kSelectedTabIndexKey = 'selected_tab_index.v1';

final PersistedFilterMapSchema _approvedFiltersSchema =
    _buildClientAgentsApprovedFiltersSchema();

final PersistedFilterMapSchema _requestsFiltersSchema =
    _buildClientAgentsRequestsFiltersSchema();

PersistedFilterMapSchema _buildClientAgentsApprovedFiltersSchema() {
  return PersistedFilterMapSchema(
    rules: <PersistedFilterRule>[
      PersistedFilterMapSchema.trimmedString('search'),
      PersistedFilterMapSchema.stringIfAllowed(
        key: 'connectionStatus',
        allowedValues: <String>{'online', 'offline', 'unknown'},
      ),
      PersistedFilterMapSchema.stringIfAllowed(
        key: 'catalogStatus',
        allowedValues: <String>{'active', 'inactive'},
      ),
    ],
  );
}

PersistedFilterMapSchema _buildClientAgentsRequestsFiltersSchema() {
  return PersistedFilterMapSchema(
    rules: <PersistedFilterRule>[
      PersistedFilterMapSchema.trimmedString('search'),
      PersistedFilterMapSchema.stringIfAllowed(
        key: 'requestStatus',
        allowedValues: <String>{
          'pending',
          'approved',
          'rejected',
          'expired',
          'unknown',
        },
      ),
      PersistedFilterMapSchema.stringIfAllowed(
        key: 'pendingState',
        allowedValues: <String>{'queued', 'syncing', 'failed', 'synced'},
      ),
    ],
  );
}

PersistedPageSessionStore _clientAgentsSessionStore(SharedPreferences prefs) {
  return PersistedPageSessionStore(
    prefs: prefs,
    namespace: _kClientAgentsSessionNamespace,
  );
}

@immutable
class ClientAgentsPageSessionState {
  const ClientAgentsPageSessionState({
    required this.selectedTabIndex,
    required this.approvedAgentFilters,
    required this.requestsFilters,
    required this.requestAccessDraftAgentIdSlots,
  });

  factory ClientAgentsPageSessionState.restore({
    required SharedPreferences prefs,
    required int fallbackTabIndex,
    required int maxTabIndex,
  }) {
    return ClientAgentsPageSessionState(
      selectedTabIndex: restoreClientAgentsSelectedTabIndex(
        prefs: prefs,
        fallbackIndex: fallbackTabIndex,
        maxTabIndex: maxTabIndex,
      ),
      approvedAgentFilters: restoreClientAgentsApprovedFilters(prefs),
      requestsFilters: restoreClientAgentsRequestsFilters(prefs),
      requestAccessDraftAgentIdSlots:
          restoreClientAgentsRequestAccessDraftAgentIdSlots(prefs),
    );
  }

  final int selectedTabIndex;
  final Map<String, Object?> approvedAgentFilters;
  final Map<String, Object?> requestsFilters;

  /// Text field values for each request row (agent id only). Tokens are never
  /// stored in SharedPreferences.
  final List<String> requestAccessDraftAgentIdSlots;

  ClientAgentsPageSessionState copyWith({
    int? selectedTabIndex,
    Map<String, Object?>? approvedAgentFilters,
    Map<String, Object?>? requestsFilters,
    List<String>? requestAccessDraftAgentIdSlots,
  }) {
    return ClientAgentsPageSessionState(
      selectedTabIndex: selectedTabIndex ?? this.selectedTabIndex,
      approvedAgentFilters: approvedAgentFilters ?? this.approvedAgentFilters,
      requestsFilters: requestsFilters ?? this.requestsFilters,
      requestAccessDraftAgentIdSlots:
          requestAccessDraftAgentIdSlots ?? this.requestAccessDraftAgentIdSlots,
    );
  }
}

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

Map<String, Object?> restoreClientAgentsApprovedFilters(
  SharedPreferences prefs,
) {
  final decoded = _clientAgentsSessionStore(prefs).restoreJsonMap(
    suffix: _kApprovedFiltersKey,
  );
  return _approvedFiltersSchema.apply(decoded);
}

Future<void> persistClientAgentsApprovedFilters(
  SharedPreferences prefs,
  Map<String, Object?> approvedAgentFilters,
) async {
  final payload = _approvedFiltersSchema.apply(approvedAgentFilters);

  await _clientAgentsSessionStore(prefs).persistJsonMap(
    suffix: _kApprovedFiltersKey,
    value: payload,
  );
}

Map<String, Object?> restoreClientAgentsRequestsFilters(
  SharedPreferences prefs,
) {
  final decoded = _clientAgentsSessionStore(prefs).restoreJsonMap(
    suffix: _kRequestsFiltersKey,
  );
  return _requestsFiltersSchema.apply(decoded);
}

Future<void> persistClientAgentsRequestsFilters(
  SharedPreferences prefs,
  Map<String, Object?> requestsFilters,
) async {
  final payload = _requestsFiltersSchema.apply(requestsFilters);

  await _clientAgentsSessionStore(prefs).persistJsonMap(
    suffix: _kRequestsFiltersKey,
    value: payload,
  );
}

List<String> restoreClientAgentsRequestAccessDraftAgentIdSlots(
  SharedPreferences prefs,
) {
  final store = _clientAgentsSessionStore(prefs);
  final rawV2 = store.restoreText(
    suffix: _kRequestAccessDraftV2Key,
  );
  if (rawV2.isNotEmpty) {
    try {
      final decoded = jsonDecode(rawV2);
      if (decoded is List<dynamic>) {
        final slots = decoded
            .map((dynamic e) => e == null ? '' : e.toString())
            .toList(growable: false);
        if (slots.isNotEmpty) {
          return slots;
        }
      }
    } on FormatException {
      // Fall through to legacy migration.
    }
  }

  final legacy = store.restoreText(
    suffix: _kRequestAccessDraftKey,
  );
  final migrated = parseAgentIdsFromFreeformDraft(legacy);
  if (migrated.isEmpty) {
    return <String>[''];
  }
  return migrated;
}

Future<void> persistClientAgentsRequestAccessDraftAgentIdSlots(
  SharedPreferences prefs,
  List<String> agentIdSlots,
) async {
  final store = _clientAgentsSessionStore(prefs);
  final slots = agentIdSlots.isEmpty
      ? <String>['']
      : List<String>.from(agentIdSlots);
  await store.persistText(
    suffix: _kRequestAccessDraftV2Key,
    value: jsonEncode(slots),
    removeWhenBlank: false,
  );
  await prefs.remove(
    '$_kClientAgentsSessionNamespace.$_kRequestAccessDraftKey',
  );
}

int restoreClientAgentsSelectedTabIndex({
  required SharedPreferences prefs,
  required int fallbackIndex,
  required int maxTabIndex,
}) {
  return _clientAgentsSessionStore(prefs).restoreTabIndex(
    suffix: _kSelectedTabIndexKey,
    fallbackIndex: fallbackIndex,
    maxTabIndex: maxTabIndex,
  );
}

Future<void> persistClientAgentsSelectedTabIndex(
  SharedPreferences prefs,
  int tabIndex,
) async {
  await _clientAgentsSessionStore(prefs).persistTabIndex(
    suffix: _kSelectedTabIndexKey,
    tabIndex: tabIndex,
  );
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
