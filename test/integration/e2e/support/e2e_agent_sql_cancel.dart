import 'package:colmeia/core/di/injector.dart';
import 'package:colmeia/core/socket/agent_command_batch_coordinator.dart';
import 'package:colmeia/core/socket/agent_sql_cancel_emitter.dart';
import 'package:colmeia/core/socket/agent_sql_open_stream.dart';
import 'package:colmeia/core/socket/relay/relay_command_dispatcher.dart';
import 'package:colmeia/core/socket/socket_command_dispatcher.dart';

/// Best-effort abort of abandoned Agent SQL waiters between E2E tests.
///
/// Fail-fasts client-side socket/relay pendings and emits hub `sql.cancel`
/// for open streams. Unary agent work is not guaranteed to stop — isolating
/// heavy reports into dedicated files is still required.
Future<void> e2eCancelAbandonedAgentSql() async {
  if (!getIt.isRegistered<SocketCommandDispatcher>() &&
      !getIt.isRegistered<RelayCommandDispatcher>()) {
    return;
  }

  if (getIt.isRegistered<AgentCommandBatchCoordinator>()) {
    getIt<AgentCommandBatchCoordinator>().cancelAllQueued(
      reason: 'e2e_teardown',
    );
  }

  var streams = const <AgentSqlOpenStream>[];
  if (getIt.isRegistered<RelayCommandDispatcher>()) {
    streams = getIt<RelayCommandDispatcher>().cancelAllPending(
      reason: 'e2e_teardown',
    );
  }
  if (getIt.isRegistered<SocketCommandDispatcher>()) {
    getIt<SocketCommandDispatcher>().cancelAllPending(reason: 'e2e_teardown');
  }

  if (streams.isEmpty || !getIt.isRegistered<AgentSqlCancelEmitter>()) {
    return;
  }

  final emitter = getIt<AgentSqlCancelEmitter>();
  for (final stream in streams) {
    await emitter.cancelStream(
      agentId: stream.agentId,
      streamId: stream.streamId,
    );
  }
  await Future<void>.delayed(const Duration(milliseconds: 250));
}
