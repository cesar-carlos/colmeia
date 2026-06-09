import 'dart:async';

import 'package:colmeia/core/logging/app_logger.dart';
import 'package:colmeia/features/agent_queries/domain/ports/agent_query_target_resolver.dart';

/// Fire-and-forget pre-resolution of approved agents + tokens after login.
///
/// Best-effort: failures are logged at debug level and never surface to UI.
class AgentQueryTargetWarmUpCoordinator {
  AgentQueryTargetWarmUpCoordinator({
    required AgentQueryTargetResolver targetResolver,
  }) : _targetResolver = targetResolver;

  final AgentQueryTargetResolver _targetResolver;

  String? _lastScheduledUserId;
  int _generation = 0;

  void scheduleWarmUp({required String userId}) {
    final trimmed = userId.trim();
    if (trimmed.isEmpty) {
      return;
    }
    if (_lastScheduledUserId == trimmed) {
      return;
    }
    _lastScheduledUserId = trimmed;
    final generation = ++_generation;
    unawaited(_warmUp(userId: trimmed, generation: generation));
  }

  void invalidate() {
    _lastScheduledUserId = null;
    _generation++;
  }

  Future<void> _warmUp({
    required String userId,
    required int generation,
  }) async {
    final result = await _targetResolver.resolve(userId: userId);
    if (generation != _generation) {
      return;
    }
    result.fold(
      (_) {},
      (failure) {
        AppLogger.debug(
          'Agent query target warm-up failed',
          context: <String, Object?>{
            'operation': 'warmUpAgentQueryTargets',
            'userId': userId,
            'message': failure.message,
          },
        );
      },
    );
  }
}
