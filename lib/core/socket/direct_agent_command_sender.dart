import 'package:colmeia/core/socket/agent_command_sender.dart';
import 'package:colmeia/core/socket/command_phase_observability.dart';
import 'package:colmeia/core/socket/socket_command_dispatcher.dart';

/// Pass-through implementation of [AgentCommandSender] that forwards each
/// call to [SocketCommandDispatcher.sendAgentsCommand] with coalescing
/// enabled. Used when batching is disabled (`SOCKET_BATCH_ENABLED=false`).
class DirectAgentCommandSender
    implements AgentCommandSender, CommandPhaseObservability {
  const DirectAgentCommandSender({required this._dispatcher});

  @override
  void Function() observePhases(
    String requestId,
    CommandPhaseListener listener,
  ) => observeCommandPhases(_dispatcher, requestId, listener);

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
