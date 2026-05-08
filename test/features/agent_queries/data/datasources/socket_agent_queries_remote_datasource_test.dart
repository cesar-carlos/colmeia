import 'package:checks/checks.dart';
import 'package:colmeia/core/socket/agent_command_sender.dart';
import 'package:colmeia/core/socket/socket_dispatch_exception.dart';
import 'package:colmeia/features/agent_queries/data/datasources/socket_agent_queries_remote_datasource.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_request.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeSender implements AgentCommandSender {
  Map<String, Object?>? lastBody;
  String? lastAgentId;
  String? lastRpcId;
  Duration? lastTimeout;
  Exception? errorToThrow;
  Map<String, dynamic> response = const <String, dynamic>{
    'mode': 'bridge',
    'response': <String, dynamic>{
      'type': 'single',
      'success': true,
      'item': <String, dynamic>{
        'id': 'fake-rpc',
        'success': true,
        'result': <String, dynamic>{'rows': <Map<String, dynamic>>[]},
      },
    },
  };

  @override
  Future<Map<String, dynamic>> send({
    required String agentId,
    required Map<String, Object?> body,
    required String rpcId,
    Duration? timeout,
  }) async {
    lastAgentId = agentId;
    lastBody = body;
    lastRpcId = rpcId;
    lastTimeout = timeout;
    if (errorToThrow != null) {
      throw errorToThrow!;
    }
    return response;
  }
}

void main() {
  late _FakeSender sender;
  late SocketAgentQueriesRemoteDataSource dataSource;

  setUp(() {
    sender = _FakeSender();
    dataSource = SocketAgentQueriesRemoteDataSource(sender: sender);
  });

  test('forwards body shaped by AgentSqlExecuteRequestToBridgeBody', () async {
    const request = AgentSqlExecuteRequest(
      agentId: 'agent-42',
      sql: 'SELECT 1',
      bridgeTimeoutMs: 12000,
    );

    await dataSource.postSqlExecute(request);

    check(sender.lastAgentId).equals('agent-42');
    check(sender.lastBody!['agentId']).equals('agent-42');
    check(sender.lastBody!['timeoutMs']).equals(12000);
    final command = sender.lastBody!['command']! as Map<String, Object?>;
    check(command['method']).equals('sql.execute');
    // rpcId in the body must equal the rpcId passed to sender.
    check(command['id']).equals(sender.lastRpcId);
    // Effective timeout = bridgeTimeoutMs + 5000 buffer (matches REST).
    check(sender.lastTimeout).equals(const Duration(milliseconds: 17000));
  });

  test('uses default timeout buffer when bridgeTimeoutMs is null', () async {
    const request = AgentSqlExecuteRequest(
      agentId: 'agent-42',
      sql: 'SELECT 1',
    );
    await dataSource.postSqlExecute(request);
    check(sender.lastTimeout).equals(const Duration(milliseconds: 20000));
  });

  test('propagates SocketDispatchException raised by the sender', () async {
    const request = AgentSqlExecuteRequest(
      agentId: 'agent-42',
      sql: 'SELECT 1',
    );
    sender.errorToThrow = const SocketDispatchTimeout(message: 'boom');

    await check(
      dataSource.postSqlExecute(request),
    ).throws<SocketDispatchTimeout>();
  });

  test('returns the sender response Map verbatim', () async {
    const request = AgentSqlExecuteRequest(
      agentId: 'agent-42',
      sql: 'SELECT 1',
    );
    final result = await dataSource.postSqlExecute(request);
    check(result['mode']).equals('bridge');
  });
}
