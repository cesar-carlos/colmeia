import 'dart:convert';

import 'package:colmeia/core/preferences/persisted_filter_map_codec.dart';
import 'package:colmeia/core/preferences/persisted_page_session_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _kClientAgentsSessionNamespace = 'client_agents';
const String _kApprovedFiltersKey = 'approved_filters.v1';
const String _kRequestsFiltersKey = 'requests_filters.v1';
const String _kRequestAccessDraftKey = 'request_access_draft.v1';
const String _kRequestAccessDraftV2Key = 'request_access_draft.v2';
const String _kSelectedTabIndexKey = 'selected_tab_index.v1';

final PersistedFilterMapSchema _approvedFiltersSchema =
    PersistedFilterMapSchema(
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

final PersistedFilterMapSchema _requestsFiltersSchema =
    PersistedFilterMapSchema(
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

class ClientAgentsPageSessionService {
  ClientAgentsPageSessionService(this._prefs);

  final SharedPreferences _prefs;

  PersistedPageSessionStore get _store => PersistedPageSessionStore(
    prefs: _prefs,
    namespace: _kClientAgentsSessionNamespace,
  );

  ClientAgentsPageSessionState restore({
    required int fallbackTabIndex,
    required int maxTabIndex,
  }) {
    return ClientAgentsPageSessionState(
      selectedTabIndex: _store.restoreTabIndex(
        suffix: _kSelectedTabIndexKey,
        fallbackIndex: fallbackTabIndex,
        maxTabIndex: maxTabIndex,
      ),
      approvedAgentFilters: _approvedFiltersSchema.apply(
        _store.restoreJsonMap(suffix: _kApprovedFiltersKey),
      ),
      requestsFilters: _requestsFiltersSchema.apply(
        _store.restoreJsonMap(suffix: _kRequestsFiltersKey),
      ),
      requestAccessDraftAgentIdSlots: _restoreRequestAccessDraftAgentIdSlots(),
    );
  }

  Future<void> persistApprovedFilters(
    Map<String, Object?> approvedAgentFilters,
  ) {
    return _store.persistJsonMap(
      suffix: _kApprovedFiltersKey,
      value: _approvedFiltersSchema.apply(approvedAgentFilters),
    );
  }

  Future<void> persistRequestsFilters(Map<String, Object?> requestsFilters) {
    return _store.persistJsonMap(
      suffix: _kRequestsFiltersKey,
      value: _requestsFiltersSchema.apply(requestsFilters),
    );
  }

  Future<void> persistRequestAccessDraftAgentIdSlots(
    List<String> agentIdSlots,
  ) async {
    final slots = agentIdSlots.isEmpty
        ? <String>['']
        : List<String>.from(agentIdSlots);
    await _store.persistText(
      suffix: _kRequestAccessDraftV2Key,
      value: jsonEncode(slots),
      removeWhenBlank: false,
    );
    await _prefs.remove(
      '$_kClientAgentsSessionNamespace.$_kRequestAccessDraftKey',
    );
  }

  Future<void> persistSelectedTabIndex(int tabIndex) {
    return _store.persistTabIndex(
      suffix: _kSelectedTabIndexKey,
      tabIndex: tabIndex,
    );
  }

  List<String> _restoreRequestAccessDraftAgentIdSlots() {
    final rawV2 = _store.restoreText(suffix: _kRequestAccessDraftV2Key);
    if (rawV2.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawV2);
        if (decoded is List<dynamic>) {
          final slots = decoded
              .map((dynamic value) => value == null ? '' : value.toString())
              .toList(growable: false);
          if (slots.isNotEmpty) {
            return slots;
          }
        }
      } on FormatException {
        // Fall through to legacy migration.
      }
    }

    final legacy = _store.restoreText(suffix: _kRequestAccessDraftKey);
    final migrated = _parseAgentIdsFromFreeformDraft(legacy);
    if (migrated.isEmpty) {
      return <String>[''];
    }
    return migrated;
  }
}

class ClientAgentsPageSessionState {
  const ClientAgentsPageSessionState({
    required this.selectedTabIndex,
    required this.approvedAgentFilters,
    required this.requestsFilters,
    required this.requestAccessDraftAgentIdSlots,
  });

  final int selectedTabIndex;
  final Map<String, Object?> approvedAgentFilters;
  final Map<String, Object?> requestsFilters;
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

final RegExp _clientAgentIdUuidPattern = RegExp(
  '^[0-9a-fA-F]{8}-'
  '[0-9a-fA-F]{4}-'
  '[1-8][0-9a-fA-F]{3}-'
  '[89abAB][0-9a-fA-F]{3}-'
  r'[0-9a-fA-F]{12}$',
);

bool _isValidClientAgentId(String value) {
  return _clientAgentIdUuidPattern.hasMatch(value.trim());
}

List<String> _parseAgentIdsFromFreeformDraft(String rawValue) {
  final rawAgentIds = rawValue
      .split(RegExp(r'[\s,;]+'))
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty);

  final out = <String>[];
  final seen = <String>{};
  for (final agentId in rawAgentIds) {
    if (!_isValidClientAgentId(agentId)) {
      continue;
    }
    final normalized = agentId.trim();
    if (seen.add(normalized)) {
      out.add(normalized);
    }
  }
  return out;
}
