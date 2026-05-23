import 'dart:async';

import 'package:colmeia/core/logging/app_logger.dart';
import 'package:colmeia/core/socket/agent_command_sender.dart';
import 'package:colmeia/core/socket/agent_sql_cancel_command.dart';
import 'package:uuid/uuid.dart';

/// Best-effort hub notification for abandoned streaming SQL work.
///
/// Unary / relay-local cancel remains client-side only; the hub honours
/// `sql.cancel` primarily for open streams — see
/// `docs/Features/socket/sql_cancel_contract_colmeia_map.md`.
class AgentSqlCancelEmitter {
  AgentSqlCancelEmitter({
    required AgentCommandSender sender,
    Uuid uuid = const Uuid(),
    Duration timeout = const Duration(seconds: 5),
  }) : _sender = sender,
       _uuid = uuid,
       _timeout = timeout;

  final AgentCommandSender _sender;
  final Uuid _uuid;
  final Duration _timeout;

  Future<void> cancelStream({
    required String agentId,
    required String streamId,
    String? clientToken,
  }) async {
    final trimmedAgentId = agentId.trim();
    final trimmedStreamId = streamId.trim();
    if (trimmedAgentId.isEmpty || trimmedStreamId.isEmpty) {
      return;
    }
    final rpcId = _uuid.v4();
    try {
      await _sender.send(
        agentId: trimmedAgentId,
        body: AgentSqlCancelCommand.build(
          agentId: trimmedAgentId,
          rpcId: rpcId,
          streamId: trimmedStreamId,
          clientToken: clientToken,
        ),
        rpcId: rpcId,
        timeout: _timeout,
      );
    } on Object catch (error, stackTrace) {
      AppLogger.debug(
        'sql.cancel emit failed (best-effort)',
        context: <String, Object?>{
          'component': 'AgentSqlCancelEmitter',
          'agentId': trimmedAgentId,
          'streamId': trimmedStreamId,
          'error': error.toString(),
          'stackTrace': stackTrace.toString(),
        },
      );
    }
  }
}
