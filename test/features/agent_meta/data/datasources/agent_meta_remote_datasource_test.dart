import 'package:checks/checks.dart';
import 'package:colmeia/core/network/bridge_rpc_response.dart';
import 'package:colmeia/core/socket/agent_command_sender.dart';
import 'package:colmeia/core/socket/socket_dispatch_exception.dart';
import 'package:colmeia/features/agent_meta/data/datasources/agent_meta_remote_datasource.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeSender implements AgentCommandSender {
  String? lastAgentId;
  String? lastRpcId;
  Map<String, Object?>? lastBody;
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
        'result': <String, dynamic>{
          'agent_id': 'agent-42',
          'name': 'Agent 42',
        },
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
  late SocketAgentMetaRemoteDataSource dataSource;

  setUp(() {
    sender = _FakeSender();
    dataSource = SocketAgentMetaRemoteDataSource(sender: sender);
  });

  test('sends agent.getProfile through the socket bridge sender', () async {
    final dto = await dataSource.agentGetProfile(
      agentId: 'agent-42',
      clientToken: 'client-token',
    );

    check(sender.lastAgentId).equals('agent-42');
    check(sender.lastTimeout).isNull();
    check(sender.lastBody!['agentId']).equals('agent-42');
    final command = sender.lastBody!['command']! as Map<String, Object?>;
    check(command['jsonrpc']).equals('2.0');
    check(command['method']).equals('agent.getProfile');
    check(command['id']).equals(sender.lastRpcId);
    final params = command['params']! as Map<String, Object?>;
    check(params['client_token']).equals('client-token');
    check(dto.agentId).equals('agent-42');
    check(dto.name).equals('Agent 42');
  });

  test('sends rpc.discover through the socket bridge sender', () async {
    sender.response = const <String, dynamic>{
      'response': <String, dynamic>{
        'item': <String, dynamic>{
          'result': <String, dynamic>{
            'openrpc': '1.3.2',
            'methods': <Map<String, Object?>>[
              <String, Object?>{'name': 'sql.execute'},
              <String, Object?>{'name': 'agent.getProfile'},
            ],
          },
        },
      },
    };

    final dto = await dataSource.rpcDiscover(agentId: 'agent-42');

    final command = sender.lastBody!['command']! as Map<String, Object?>;
    check(command['method']).equals('rpc.discover');
    check(command.containsKey('params')).isFalse();
    check(dto.methods).contains('sql.execute');
    check(dto.methods).contains('agent.getProfile');
  });

  test('propagates socket dispatch failures', () async {
    sender.errorToThrow = const SocketDispatchTimeout(message: 'boom');

    await check(
      dataSource.rpcDiscover(agentId: 'agent-42'),
    ).throws<SocketDispatchTimeout>();
  });

  test('throws BridgeRpcException when bridge returns item.error', () async {
    sender.response = const <String, dynamic>{
      'response': <String, dynamic>{
        'type': 'single',
        'success': true,
        'item': <String, dynamic>{
          'id': 'fake-rpc',
          'success': false,
          'error': <String, dynamic>{
            'code': -32601,
            'message': 'method not found',
            'data': <String, dynamic>{
              'reason': 'method_not_found',
            },
          },
        },
      },
    };

    await check(
      dataSource.rpcDiscover(agentId: 'agent-42'),
    ).throws<BridgeRpcException>();
  });
}
