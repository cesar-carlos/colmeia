import 'dart:async';

import 'package:colmeia/core/logging/app_logger.dart';
import 'package:colmeia/features/client_agents/application/client_agent_token_draft_store.dart';
import 'package:colmeia/features/client_agents/application/usecases/get_client_agent_token_use_case.dart';
import 'package:colmeia/features/client_agents/application/usecases/save_client_agent_token_use_case.dart';
import 'package:colmeia/features/client_agents/domain/entities/client_agent.dart';
import 'package:colmeia/features/client_agents/domain/entities/client_agent_token_constraints.dart';
import 'package:colmeia/features/client_agents/domain/entities/paginated_result.dart';
import 'package:colmeia/features/client_agents/presentation/controllers/request_access_submission_snapshot.dart';
import 'package:colmeia/features/client_agents/presentation/models/client_agent_access_request_row_input.dart';
import 'package:colmeia/features/client_agents/presentation/models/client_agents_presentation_message.dart';
import 'package:colmeia/features/client_agents/presentation/utils/client_agent_id_format.dart';

/// Surface the token-draft coordinator needs from its owner controller.
abstract interface class ClientAgentsTokenDraftHost {
  bool get isDisposed;

  String? get currentUserId;

  PaginatedResult<ClientAgent>? get approvedAgentsSnapshot;

  void setActionError(ClientAgentsPresentationMessage? error);

  void setActionFeedback({
    required ClientAgentsPresentationMessage message,
    required ClientAgentsActionFeedbackKind kind,
  });

  void notifyTokenDraftChanged();

  Future<bool> requestAccess({
    required Set<String> agentIds,
    Future<void> Function(RequestAccessSubmissionSnapshot snapshot)? onResolved,
  });
}

/// Owns local client-token draft persistence and the transactional flow that
/// pairs request-access submissions with token writes and server flushes.
class ClientAgentsTokenDraftCoordinator {
  ClientAgentsTokenDraftCoordinator({
    required ClientAgentsTokenDraftHost host,
    required ClientAgentTokenDraftStore clientTokenDraftStore,
    required GetClientAgentTokenUseCase getClientAgentTokenUseCase,
    required SaveClientAgentTokenUseCase saveClientAgentTokenUseCase,
  }) : _host = host,
       _clientTokenDraftStore = clientTokenDraftStore,
       _getClientAgentTokenUseCase = getClientAgentTokenUseCase,
       _saveClientAgentTokenUseCase = saveClientAgentTokenUseCase;

  final ClientAgentsTokenDraftHost _host;
  final ClientAgentTokenDraftStore _clientTokenDraftStore;
  final GetClientAgentTokenUseCase _getClientAgentTokenUseCase;
  final SaveClientAgentTokenUseCase _saveClientAgentTokenUseCase;

  final Set<String> _pendingLocalTokenServerFlushAgentIds = <String>{};

  Future<String?> readLocalClientToken(String agentId) async {
    final userId = _host.currentUserId;
    if (userId == null || userId.isEmpty) {
      return null;
    }
    final trimmedAgentId = agentId.trim();
    if (trimmedAgentId.isEmpty) {
      return null;
    }
    if (_approvedAgentIds().contains(trimmedAgentId)) {
      final result = await _getClientAgentTokenUseCase(
        userId: userId,
        agentId: trimmedAgentId,
      );
      final snapshot = result.getOrNull();
      if (snapshot != null) {
        return snapshot.token;
      }
    }
    return _clientTokenDraftStore.read(
      userId: userId,
      agentId: trimmedAgentId,
    );
  }

  Future<void> persistLocalClientTokenDraftLine({
    required String agentIdRaw,
    required String clientTokenRaw,
  }) async {
    final userId = _host.currentUserId;
    if (userId == null || userId.isEmpty) {
      return;
    }
    final id = agentIdRaw.trim();
    if (!isValidClientAgentId(id)) {
      return;
    }
    final token = clientTokenRaw.trim();
    if (token.length > ClientAgentTokenConstraints.maxLength) {
      AppLogger.warning(
        'Client token draft exceeds server cap; not persisted',
        context: <String, Object?>{
          'operation': 'persistLocalClientTokenDraftLine',
          'agentId': id,
          'length': token.length,
          'cap': ClientAgentTokenConstraints.maxLength,
        },
      );
      return;
    }
    if (token.isEmpty) {
      await _clientTokenDraftStore.delete(userId: userId, agentId: id);
    } else {
      await _clientTokenDraftStore.write(
        userId: userId,
        agentId: id,
        clientToken: token,
      );
    }
  }

  Future<bool> submitAccessRequestWithLocalTokens(
    List<ClientAgentAccessRequestRowInput> rows,
  ) async {
    final userId = _host.currentUserId;
    if (userId == null || userId.isEmpty) {
      _host
        ..setActionError(
          ClientAgentsPresentationMessage.clientAgentsSessionUnavailableRequest(),
        )
        ..notifyTokenDraftChanged();
      return false;
    }

    final tokenByAgentId = <String, String>{};
    final tokensTooLongIds = <String>[];
    for (final row in rows) {
      final id = row.agentIdRaw.trim();
      if (!isValidClientAgentId(id)) {
        continue;
      }
      final token = row.clientTokenRaw.trim();
      if (token.length > ClientAgentTokenConstraints.maxLength) {
        tokensTooLongIds.add(id);
        continue;
      }
      tokenByAgentId[id] = token;
    }

    if (tokensTooLongIds.isNotEmpty) {
      _host
        ..setActionError(
          ClientAgentsPresentationMessage.clientAgentsValidationTokenTooLong(
            maxLength: ClientAgentTokenConstraints.maxLength,
            agentIds: tokensTooLongIds,
          ),
        )
        ..notifyTokenDraftChanged();
      return false;
    }

    final requestedIds = tokenByAgentId.keys.toSet();
    if (requestedIds.isEmpty) {
      return false;
    }

    final localSnapshotById = <String, String?>{};
    for (final id in requestedIds) {
      localSnapshotById[id] = await _clientTokenDraftStore.read(
        userId: userId,
        agentId: id,
      );
    }

    AppLogger.info(
      'Client agents request access submission starting',
      context: <String, Object?>{
        'operation': 'submitAccessRequestWithLocalTokens',
        'requestedCount': requestedIds.length,
        'withTokenCount': tokenByAgentId.values
            .where((t) => t.isNotEmpty)
            .length,
      },
    );

    final outcome = await _host.requestAccess(
      agentIds: requestedIds,
      onResolved: (snapshot) async {
        await _applySubmittedTokensTransactionally(
          userId: userId,
          tokenByAgentId: tokenByAgentId,
          snapshot: snapshot,
        );
      },
    );

    if (!outcome) {
      await _restoreLocalTokenSnapshot(
        userId: userId,
        snapshotById: localSnapshotById,
      );
    }

    return outcome;
  }

  void scheduleLocalTokenServerFlushForApprovedAgents({
    required String userId,
    Iterable<String> preferredAgentIds = const <String>[],
  }) {
    if (_host.isDisposed) {
      return;
    }
    final approvedItems = _host.approvedAgentsSnapshot?.items;
    if (approvedItems == null || approvedItems.isEmpty) {
      return;
    }
    final approvedIds = approvedItems.map((agent) => agent.agentId).toSet();
    final candidates = <String>{
      ..._pendingLocalTokenServerFlushAgentIds,
      ...preferredAgentIds,
      for (final agent in approvedItems)
        if (agent.hasServerClientToken == false) agent.agentId,
    }.intersection(approvedIds);
    if (candidates.isEmpty) {
      return;
    }
    unawaited(
      pushLocalTokenToServerAfterApproval(
        userId: userId,
        agentIds: candidates,
      ),
    );
  }

  Future<void> pushLocalTokenToServerAfterApproval({
    required String userId,
    required Iterable<String> agentIds,
  }) async {
    var failedCount = 0;
    for (final agentId in agentIds) {
      final localToken = await _clientTokenDraftStore.read(
        userId: userId,
        agentId: agentId,
      );
      if (localToken == null) {
        continue;
      }
      final result = await _saveClientAgentTokenUseCase(
        userId: userId,
        agentId: agentId,
        clientToken: localToken,
      );
      if (result.isError()) {
        failedCount++;
        _pendingLocalTokenServerFlushAgentIds.add(agentId);
        final failure = result.exceptionOrNull()!;
        AppLogger.warning(
          'Server PUT of client-agent token after approval failed; local '
          'cache kept as fallback',
          context: <String, Object?>{
            'operation': 'pushLocalTokenAfterApproval',
            'agentId': agentId,
            'technicalMessage': failure.message,
          },
          error: failure.cause ?? failure,
          stackTrace: failure.stackTrace,
        );
      } else {
        _pendingLocalTokenServerFlushAgentIds.remove(agentId);
      }
    }
    if (failedCount > 0 && !_host.isDisposed) {
      _host
        ..setActionFeedback(
          message:
              ClientAgentsPresentationMessage.clientAgentsLocalTokenServerFlushFailed(
                failedCount: failedCount,
              ),
          kind: ClientAgentsActionFeedbackKind.info,
        )
        ..notifyTokenDraftChanged();
    }
  }

  Future<void> _applySubmittedTokensTransactionally({
    required String userId,
    required Map<String, String> tokenByAgentId,
    required RequestAccessSubmissionSnapshot snapshot,
  }) async {
    for (final agentId in snapshot.relinkedAgentIds) {
      final token = tokenByAgentId[agentId] ?? '';
      final result = await _saveClientAgentTokenUseCase(
        userId: userId,
        agentId: agentId,
        clientToken: token,
      );
      if (result.isError()) {
        _pendingLocalTokenServerFlushAgentIds.add(agentId);
        final failure = result.exceptionOrNull()!;
        AppLogger.warning(
          'Server PUT of client-agent token after relink failed; falling '
          'back to local cache (will retry on next approval flush)',
          context: <String, Object?>{
            'operation': 'applySubmittedTokens',
            'agentId': agentId,
            'phase': 'relinked',
            'technicalMessage': failure.message,
          },
          error: failure.cause ?? failure,
          stackTrace: failure.stackTrace,
        );
        await _writeLocalTokenSafely(
          userId: userId,
          agentId: agentId,
          token: token,
        );
      } else {
        _pendingLocalTokenServerFlushAgentIds.remove(agentId);
      }
    }

    for (final agentId in snapshot.queuedAgentIds) {
      final token = tokenByAgentId[agentId] ?? '';
      await _writeLocalTokenSafely(
        userId: userId,
        agentId: agentId,
        token: token,
      );
    }
  }

  Future<void> _writeLocalTokenSafely({
    required String userId,
    required String agentId,
    required String token,
  }) async {
    if (token.isEmpty) {
      _pendingLocalTokenServerFlushAgentIds.remove(agentId);
      await _clientTokenDraftStore.delete(userId: userId, agentId: agentId);
      return;
    }
    await _clientTokenDraftStore.write(
      userId: userId,
      agentId: agentId,
      clientToken: token,
    );
  }

  Future<void> _restoreLocalTokenSnapshot({
    required String userId,
    required Map<String, String?> snapshotById,
  }) async {
    for (final entry in snapshotById.entries) {
      final previous = entry.value;
      if (previous == null || previous.isEmpty) {
        await _clientTokenDraftStore.delete(
          userId: userId,
          agentId: entry.key,
        );
      } else {
        await _clientTokenDraftStore.write(
          userId: userId,
          agentId: entry.key,
          clientToken: previous,
        );
      }
    }
  }

  Set<String> _approvedAgentIds() {
    return _host.approvedAgentsSnapshot?.items
            .map((agent) => agent.agentId)
            .toSet() ??
        const <String>{};
  }
}
