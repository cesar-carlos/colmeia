import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/features/client_agents/domain/entities/sync_pending_agent_actions_result.dart';

/// Mutable accumulator for `PendingClientAgentActionsSynchronizer`.
///
/// Replaces the 9 ad-hoc `Set<String>` variables that the legacy
/// `syncPendingActions` carried in its local scope. Centralizing the
/// "what succeeded / what failed / what should we poll" tracking on a
/// dedicated builder makes the sync flow read top-to-bottom and lets us
/// unit-test the accumulation rules in isolation.
class PendingClientAgentActionsSyncOutcomeBuilder {
  /// IDs of `PendingAgentAction` entries whose remote call succeeded and
  /// can therefore be removed from the local queue. Includes both
  /// request-access and remove-access actions.
  final Set<String> _successfulActionIds = <String>{};

  final Set<String> _successfulRequestAccessAgentIds = <String>{};
  final Set<String> _successfulRemoveAccessAgentIds = <String>{};
  final Set<String> _failedRequestAccessAgentIds = <String>{};
  final Set<String> _failedRemoveAccessAgentIds = <String>{};
  final Set<String> _requestAccessPollAgentIds = <String>{};
  final Set<String> _requestAccessAlreadyApprovedAgentIds = <String>{};
  final Set<String> _requestAccessDebouncedAgentIds = <String>{};
  final Set<String> _requestAccessNewRequestsAgentIds = <String>{};
  Duration? _retryAfter;

  /// Longest `Retry-After` hint observed from a failed batch in this run.
  Duration? get retryAfter => _retryAfter;

  /// Read-only snapshot of the action IDs to drop from the queue after the
  /// sync run. Useful for cleanup operations that need to filter the
  /// in-memory working set.
  Set<String> get successfulActionIds =>
      Set<String>.unmodifiable(_successfulActionIds);

  Set<String> get successfulRemoveAccessAgentIds =>
      Set<String>.unmodifiable(_successfulRemoveAccessAgentIds);

  int get successfulRequestAccessCount =>
      _successfulRequestAccessAgentIds.length;
  int get failedRequestAccessCount => _failedRequestAccessAgentIds.length;
  int get successfulRemoveAccessCount => _successfulRemoveAccessAgentIds.length;
  int get failedRemoveAccessCount => _failedRemoveAccessAgentIds.length;
  int get requestAccessPollCount => _requestAccessPollAgentIds.length;
  int get requestAccessNewRequestsCount =>
      _requestAccessNewRequestsAgentIds.length;

  /// Records a successful request-access call for [agentId]. The hub
  /// flags ([shouldPollApproval], [alreadyApproved], [debounced],
  /// [isNewRequest]) come from the `POST /client/me/agents` response and
  /// surface as separate buckets on the final outcome so callers can
  /// drive specific UX (polling, "already approved" banner, etc.).
  void recordRequestAccessSuccess({
    required String actionId,
    required String agentId,
    required bool shouldPollApproval,
    required bool alreadyApproved,
    required bool debounced,
    required bool isNewRequest,
  }) {
    _successfulActionIds.add(actionId);
    _successfulRequestAccessAgentIds.add(agentId);
    if (shouldPollApproval) {
      _requestAccessPollAgentIds.add(agentId);
    }
    if (alreadyApproved) {
      _requestAccessAlreadyApprovedAgentIds.add(agentId);
    }
    if (debounced) {
      _requestAccessDebouncedAgentIds.add(agentId);
    }
    if (isNewRequest) {
      _requestAccessNewRequestsAgentIds.add(agentId);
    }
  }

  void recordRequestAccessFailure(String agentId) {
    _failedRequestAccessAgentIds.add(agentId);
  }

  void recordRemoveAccessSuccess({
    required String actionId,
    required String agentId,
  }) {
    _successfulActionIds.add(actionId);
    _successfulRemoveAccessAgentIds.add(agentId);
  }

  void recordRemoveAccessFailure(String agentId) {
    _failedRemoveAccessAgentIds.add(agentId);
  }

  void recordBatchFailure(AppFailure failure) {
    if (failure is NetworkFailure) {
      _mergeRetryAfter(failure.retryAfter);
    }
  }

  void _mergeRetryAfter(Duration? candidate) {
    if (candidate == null || candidate <= Duration.zero) {
      return;
    }
    final current = _retryAfter;
    if (current == null || candidate > current) {
      _retryAfter = candidate;
    }
  }

  /// Snapshots the accumulator into the domain DTO returned by
  /// `ClientAgentsRepository.syncPendingActions`. Subsequent reads of the
  /// builder remain valid: this method does not reset state.
  SyncPendingAgentActionsResult build() {
    return SyncPendingAgentActionsResult(
      successfulRequestAccessAgentIds: Set<String>.from(
        _successfulRequestAccessAgentIds,
      ),
      successfulRemoveAccessAgentIds: Set<String>.from(
        _successfulRemoveAccessAgentIds,
      ),
      failedRequestAccessAgentIds: Set<String>.from(
        _failedRequestAccessAgentIds,
      ),
      failedRemoveAccessAgentIds: Set<String>.from(_failedRemoveAccessAgentIds),
      requestAccessPollAgentIds: Set<String>.from(_requestAccessPollAgentIds),
      requestAccessAlreadyApprovedAgentIds: Set<String>.from(
        _requestAccessAlreadyApprovedAgentIds,
      ),
      requestAccessDebouncedAgentIds: Set<String>.from(
        _requestAccessDebouncedAgentIds,
      ),
      requestAccessNewRequestsAgentIds: Set<String>.from(
        _requestAccessNewRequestsAgentIds,
      ),
      retryAfter: _retryAfter,
    );
  }
}
