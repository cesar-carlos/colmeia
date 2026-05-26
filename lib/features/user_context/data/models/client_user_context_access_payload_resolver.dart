import 'package:colmeia/shared/data/json/wrapped_json_reader.dart';

class ResolvedClientUserContextAccessPayload {
  const ResolvedClientUserContextAccessPayload({
    required this.payload,
    required this.hasExplicitAccessData,
    required this.source,
  });

  final Map<String, dynamic> payload;
  final bool hasExplicitAccessData;
  final String source;
}

ResolvedClientUserContextAccessPayload resolveClientUserContextAccessPayload(
  Map<String, dynamic> payload,
) {
  const candidates = <({List<String> path, String source})>[
    (
      path: <String>['access', 'scope', 'userContext'],
      source: 'access.scope.userContext',
    ),
    (path: <String>['access', 'scope'], source: 'access.scope'),
    (path: <String>['access'], source: 'access'),
    (path: <String>['scope'], source: 'scope'),
    (path: <String>['userContext'], source: 'userContext'),
  ];

  for (final candidate in candidates) {
    final candidatePayload = readMapAtPath(payload, candidate.path);
    if (candidatePayload == null) {
      continue;
    }

    if (_hasExplicitAccessData(candidatePayload)) {
      return ResolvedClientUserContextAccessPayload(
        payload: candidatePayload,
        hasExplicitAccessData: true,
        source: candidate.source,
      );
    }
  }

  return ResolvedClientUserContextAccessPayload(
    payload: payload,
    hasExplicitAccessData: _hasExplicitAccessData(payload),
    source: 'root',
  );
}

bool _hasExplicitAccessData(Map<String, dynamic> json) {
  return json['allowedStores'] is List<dynamic> ||
      json['stores'] is List<dynamic> ||
      json['storeScopes'] is List<dynamic> ||
      json['permissions'] is List<dynamic> ||
      json['dashboardGrants'] is List<dynamic> ||
      json['dashboardAccess'] is List<dynamic> ||
      json['allowedDashboardIds'] is List<dynamic> ||
      json['viewDashboard'] is bool ||
      json['manageAgents'] is bool ||
      json['viewAgents'] is bool ||
      json['viewClientAgents'] is bool ||
      json['activeStoreId'] is String ||
      json['active_store_id'] is String;
}
