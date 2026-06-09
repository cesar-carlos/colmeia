import 'dart:async';
import 'dart:math' show min;

import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/core/logging/app_logger.dart';
import 'package:colmeia/features/client_agents/application/usecases/load_client_access_requests_use_case.dart';
import 'package:colmeia/features/client_agents/application/usecases/load_client_access_status_use_case.dart';
import 'package:colmeia/features/client_agents/application/usecases/load_client_agent_detail_use_case.dart';
import 'package:colmeia/features/client_agents/application/usecases/load_client_approved_agents_use_case.dart';
import 'package:colmeia/features/client_agents/domain/entities/agent_access_request_status.dart';
import 'package:colmeia/features/client_agents/domain/entities/client_agent.dart';
import 'package:colmeia/features/client_agents/domain/entities/client_agent_access_request.dart';
import 'package:colmeia/features/client_agents/domain/entities/client_agents_list_page_size.dart';
import 'package:colmeia/features/client_agents/domain/entities/paginated_query.dart';
import 'package:colmeia/features/client_agents/domain/entities/paginated_result.dart';
import 'package:colmeia/features/client_agents/presentation/models/client_agents_presentation_message.dart';

/// Surface the [ClientAgentsApprovalPollingCoordinator] needs from its owner
/// to apply poll results to in-memory lists and user feedback.
abstract interface class ClientAgentsApprovalPollingHost {
  bool get isDisposed;

  String? get currentUserId;

  bool get isBusy;

  PaginatedResult<ClientAgent>? get approvedAgentsSnapshot;

  PaginatedResult<ClientAgentAccessRequest>? get accessRequestsSnapshot;

  void replaceApprovedAgents(PaginatedResult<ClientAgent> value);

  void replaceAccessRequests(PaginatedResult<ClientAgentAccessRequest> value);

  void upsertApprovedAgentsInMemory(List<ClientAgent> agents);

  void setApprovedAgentsError(ClientAgentsPresentationMessage? error);

  void setAccessRequestsError(ClientAgentsPresentationMessage? error);

  void setActionFeedback({
    required ClientAgentsPresentationMessage message,
    required ClientAgentsActionFeedbackKind kind,
  });

  void scheduleLocalTokenServerFlush({
    required String userId,
    required Iterable<String> agentIds,
  });

  void invalidateTargetResolution({required String userId});

  void notifyApprovalPollingChanged();

  ClientAgentAccessRequest? accessRequestForAgentId(String agentId);
}

/// Owns approval polling for queued `requestAccess` actions: refreshes access
/// requests, probes approved-agent detail for tracked ids, and surfaces
/// progress feedback until every id is approved, denied, or timed out.
class ClientAgentsApprovalPollingCoordinator {
  ClientAgentsApprovalPollingCoordinator({
    required ClientAgentsApprovalPollingHost host,
    required LoadClientAccessRequestsUseCase loadAccessRequestsUseCase,
    required LoadClientAgentDetailUseCase loadClientAgentDetailUseCase,
    required LoadClientAccessStatusUseCase loadClientAccessStatusUseCase,
    required LoadClientApprovedAgentsUseCase loadApprovedAgentsUseCase,
    Duration pollingInterval = const Duration(seconds: 10),
    Duration pollingTimeout = const Duration(minutes: 3),
    int probeConcurrency = 4,
  }) : _host = host,
       _loadAccessRequestsUseCase = loadAccessRequestsUseCase,
       _loadClientAgentDetailUseCase = loadClientAgentDetailUseCase,
       _loadClientAccessStatusUseCase = loadClientAccessStatusUseCase,
       _loadApprovedAgentsUseCase = loadApprovedAgentsUseCase,
       _pollingInterval = pollingInterval,
       _pollingTimeout = pollingTimeout,
       _probeConcurrency = probeConcurrency;

  final ClientAgentsApprovalPollingHost _host;
  final LoadClientAccessRequestsUseCase _loadAccessRequestsUseCase;
  final LoadClientAgentDetailUseCase _loadClientAgentDetailUseCase;
  final LoadClientAccessStatusUseCase _loadClientAccessStatusUseCase;
  final LoadClientApprovedAgentsUseCase _loadApprovedAgentsUseCase;
  final Duration _pollingInterval;
  final Duration _pollingTimeout;
  final int _probeConcurrency;

  static const PaginatedQuery _pollingQuery = PaginatedQuery(
    pageSize: kClientAgentsListPageSize,
  );

  final Set<String> _trackedApprovalAgentIds = <String>{};
  final Map<String, DateTime> _approvalPollingStartedAtByAgentId =
      <String, DateTime>{};
  Timer? _approvalPollingTimer;
  bool _isPollingApprovals = false;

  void startPolling({
    required String userId,
    required Set<String> agentIds,
  }) {
    if (agentIds.isEmpty || _host.isDisposed) {
      return;
    }
    final now = DateTime.now();
    for (final agentId in agentIds) {
      _trackedApprovalAgentIds.add(agentId);
      _approvalPollingStartedAtByAgentId[agentId] = now;
    }
    _approvalPollingTimer ??= Timer.periodic(_pollingInterval, (_) {
      unawaited(_pollApprovalStatus(userId: userId));
    });
    unawaited(_pollApprovalStatus(userId: userId));
  }

  void stopPolling({bool clearTracked = false}) {
    _approvalPollingTimer?.cancel();
    _approvalPollingTimer = null;
    _isPollingApprovals = false;
    if (clearTracked) {
      _trackedApprovalAgentIds.clear();
      _approvalPollingStartedAtByAgentId.clear();
    }
  }

  Future<void> _pollApprovalStatus({
    required String userId,
  }) async {
    if (_host.isDisposed ||
        _isPollingApprovals ||
        _trackedApprovalAgentIds.isEmpty ||
        _host.isBusy) {
      return;
    }
    final currentUserId = _host.currentUserId;
    if (currentUserId == null || currentUserId != userId) {
      stopPolling(clearTracked: true);
      return;
    }

    _isPollingApprovals = true;
    final requestsRefreshResult = await _loadAccessRequestsUseCase(
      userId: userId,
      query: _pollingQuery,
    );
    _host.setAccessRequestsError(
      _consumeResult(
        result: requestsRefreshResult,
        onSuccess: _host.replaceAccessRequests,
        operation: 'pollRefreshClientAgentAccessRequests',
      ),
    );

    final approvedNow = <String, ClientAgent>{};
    final deniedNow = <String>{};
    final timedOutNow = <String>{};

    final idsToCheck = _trackedApprovalAgentIds.toList(growable: false);
    for (var i = 0; i < idsToCheck.length; i += _probeConcurrency) {
      final upper = min(i + _probeConcurrency, idsToCheck.length);
      final chunk = idsToCheck.sublist(i, upper);
      final chunkResults = await Future.wait(
        chunk.map(
          (agentId) => _evaluateTrackedAgentForPoll(
            userId: userId,
            agentId: agentId,
          ),
        ),
      );
      for (final r in chunkResults) {
        if (r.timedOut) {
          timedOutNow.add(r.agentId);
        } else if (r.approved != null) {
          approvedNow[r.agentId] = r.approved!;
        } else if (r.denied) {
          deniedNow.add(r.agentId);
        }
      }
    }

    _trackedApprovalAgentIds
      ..removeAll(approvedNow.keys)
      ..removeAll(deniedNow)
      ..removeAll(timedOutNow);
    <String>{
      ...approvedNow.keys,
      ...deniedNow,
      ...timedOutNow,
    }.forEach(_approvalPollingStartedAtByAgentId.remove);

    if (approvedNow.isNotEmpty) {
      await _refreshApprovedAgentsSnapshot(userId: userId);
      _host.upsertApprovedAgentsInMemory(
        approvedNow.values.toList(growable: false),
      );
      _host.invalidateTargetResolution(userId: userId);
      _host.scheduleLocalTokenServerFlush(
        userId: userId,
        agentIds: approvedNow.keys,
      );
    }

    if (approvedNow.isNotEmpty ||
        deniedNow.isNotEmpty ||
        timedOutNow.isNotEmpty) {
      _host.setActionFeedback(
        message:
            ClientAgentsPresentationMessage.clientAgentsApprovalPollingProgress(
              approvedCount: approvedNow.length,
              deniedCount: deniedNow.length,
              timedOutCount: timedOutNow.length,
              remainingCount: _trackedApprovalAgentIds.length,
            ),
        kind: approvedNow.isNotEmpty && deniedNow.isEmpty && timedOutNow.isEmpty
            ? ClientAgentsActionFeedbackKind.success
            : ClientAgentsActionFeedbackKind.info,
      );
    }

    if (_trackedApprovalAgentIds.isEmpty) {
      stopPolling();
    }
    _isPollingApprovals = false;
    _host.notifyApprovalPollingChanged();
  }

  Future<
    ({
      String agentId,
      bool timedOut,
      ClientAgent? approved,
      bool denied,
    })
  >
  _evaluateTrackedAgentForPoll({
    required String userId,
    required String agentId,
  }) async {
    final startedAt = _approvalPollingStartedAtByAgentId[agentId];
    if (startedAt != null &&
        DateTime.now().difference(startedAt) >= _pollingTimeout) {
      return (
        agentId: agentId,
        timedOut: true,
        approved: null,
        denied: false,
      );
    }
    final approvedAgent = await _loadApprovedAgentForPolling(
      userId: userId,
      agentId: agentId,
    );
    if (approvedAgent != null) {
      return (
        agentId: agentId,
        timedOut: false,
        approved: approvedAgent,
        denied: false,
      );
    }
    final requestStatus = await _loadRequestStatusForPolling(
      userId: userId,
      agentId: agentId,
    );
    final denied =
        requestStatus == AgentAccessRequestStatus.rejected ||
        requestStatus == AgentAccessRequestStatus.expired;
    return (
      agentId: agentId,
      timedOut: false,
      approved: null,
      denied: denied,
    );
  }

  Future<ClientAgent?> _loadApprovedAgentForPolling({
    required String userId,
    required String agentId,
  }) async {
    final result = await _loadClientAgentDetailUseCase(
      userId: userId,
      agentId: agentId,
    );
    return result.fold((value) => value, (_) => null);
  }

  Future<AgentAccessRequestStatus?> _loadRequestStatusForPolling({
    required String userId,
    required String agentId,
  }) async {
    final cached = _host.accessRequestForAgentId(agentId);
    if (cached != null) {
      final token = cached.statusPollToken?.trim();
      if (token != null && token.isNotEmpty) {
        final snapshot = await _loadClientAccessStatusUseCase(token: token);
        return snapshot.fold((value) => value.status, (_) => cached.status);
      }
      return cached.status;
    }

    final result = await _loadAccessRequestsUseCase(
      userId: userId,
      query: const PaginatedQuery(pageSize: kClientAgentsListPageSize),
      search: agentId,
    );
    return result.fold((value) {
      for (final request in value.items) {
        if (request.agentId == agentId) {
          return request.status;
        }
      }
      return null;
    }, (_) => null);
  }

  Future<void> _refreshApprovedAgentsSnapshot({
    required String userId,
  }) async {
    final approvedResult = await _loadApprovedAgentsUseCase(
      userId: userId,
      query: _pollingQuery,
    );
    _host.setApprovedAgentsError(
      _consumeResult(
        result: approvedResult,
        onSuccess: _host.replaceApprovedAgents,
        operation: 'pollApprovedClientAgents',
      ),
    );
  }

  ClientAgentsPresentationMessage? _consumeResult<T extends Object>({
    required AppResult<T> result,
    required String operation,
    void Function(T value)? onSuccess,
  }) {
    return result.fold(
      (value) {
        onSuccess?.call(value);
        return null;
      },
      (failure) {
        AppLogger.warning(
          'Client agents operation failed',
          context: <String, Object?>{
            'operation': operation,
            'technicalMessage': failure.message,
          },
          error: failure.cause ?? failure,
          stackTrace: failure.stackTrace,
        );
        return ClientAgentsPresentationMessage.failure(failure);
      },
    );
  }

  void dispose() {
    stopPolling(clearTracked: true);
  }
}
