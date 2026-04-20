import 'package:colmeia/core/socket/agent_command_sender.dart';
import 'package:colmeia/core/socket/socket_command_dispatcher.dart';

/// Pass-through implementation of [AgentCommandSender] that forwards each
/// call to [SocketCommandDispatcher.sendAgentsCommand] with coalescing
/// enabled. Used when batching is disabled (`SOCKET_BATCH_ENABLED=false`).
class DirectAgentCommandSender implements AgentCommandSender {
  const DirectAgentCommandSender({required SocketCommandDispatcher dispatcher})
    : _dispatcher = dispatcher;

  final SocketCommandDispatcher _dispatcher;

  @override
  Future<Map<String, dynamic>> send({
    required String agentId,
    required Map<String, Object?> body,
    required String rpcId,
    Duration? timeout,
  }) {
    return _dispatcher.sendAgentsCommand(
      agentId: agentId,
      body: body,
      rpcId: rpcId,
      timeout: timeout,
    );
  }
}
