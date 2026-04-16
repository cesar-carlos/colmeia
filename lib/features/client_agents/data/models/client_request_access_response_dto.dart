/// Wire shape for `POST /client/me/agents` (Plug OpenAPI).
final class ClientRequestAccessResponseDto {
  const ClientRequestAccessResponseDto({
    this.requested = const <String>[],
    this.alreadyApproved = const <String>[],
    this.newRequests = const <String>[],
    this.reopened = const <String>[],
    this.debounced = const <String>[],
  });

  factory ClientRequestAccessResponseDto.parse(
    Map<String, dynamic> json,
    Set<String> sentAgentIds,
  ) {
    final requested = _stringIdList(json['requested']);
    final alreadyApproved = _stringIdList(json['alreadyApproved']);
    final newRequests = _stringIdList(json['newRequests']);
    final reopened = _stringIdList(json['reopened']);
    final debounced = _stringIdList(json['debounced']);
    final hasSemantic = requested.isNotEmpty ||
        alreadyApproved.isNotEmpty ||
        newRequests.isNotEmpty ||
        reopened.isNotEmpty ||
        debounced.isNotEmpty;
    if (!hasSemantic && sentAgentIds.isNotEmpty) {
      return ClientRequestAccessResponseDto(
        requested: sentAgentIds.toList(growable: false),
      );
    }
    return ClientRequestAccessResponseDto(
      requested: requested,
      alreadyApproved: alreadyApproved,
      newRequests: newRequests,
      reopened: reopened,
      debounced: debounced,
    );
  }

  final List<String> requested;
  final List<String> alreadyApproved;
  final List<String> newRequests;
  final List<String> reopened;
  final List<String> debounced;

  /// True when [agentId] appears in any server bucket for this POST.
  bool acknowledgesAgent(String agentId) {
    return requested.contains(agentId) ||
        alreadyApproved.contains(agentId) ||
        newRequests.contains(agentId) ||
        reopened.contains(agentId) ||
        debounced.contains(agentId);
  }

  /// Ids that should enter approval polling after a successful sync.
  ///
  /// `alreadyApproved` is excluded: the hub already granted access, so no
  /// pending approval to track. `debounced` is included: the row was
  /// refreshed without a new email but approval may still be pending.
  ///
  /// Successful sync always drops matching pending rows locally; polling
  /// (when true) keeps the UI aligned until the access request is resolved.
  bool shouldPollApprovalFor(String agentId) {
    if (alreadyApproved.contains(agentId)) {
      return false;
    }
    return requested.contains(agentId) ||
        newRequests.contains(agentId) ||
        reopened.contains(agentId) ||
        debounced.contains(agentId);
  }
}

List<String> _stringIdList(Object? value) {
  if (value is! List<dynamic>) {
    return const <String>[];
  }
  return value.whereType<String>().toList(growable: false);
}
