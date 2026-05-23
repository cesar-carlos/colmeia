import 'package:colmeia/core/socket/agent_sql_cancel_command.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('builds sql.cancel bridge body with stream_id', () {
    final body = AgentSqlCancelCommand.build(
      agentId: ' agent-1 ',
      rpcId: 'rpc-1',
      streamId: ' stream-9 ',
      clientToken: ' token ',
    );

    expect(body['agentId'], 'agent-1');
    final command = body['command']! as Map<String, Object?>;
    expect(command['method'], 'sql.cancel');
    expect(command['id'], 'rpc-1');
    final params = command['params']! as Map<String, Object?>;
    expect(params['stream_id'], 'stream-9');
    expect(params['client_token'], 'token');
  });

  test('omits empty client_token', () {
    final body = AgentSqlCancelCommand.build(
      agentId: 'a',
      rpcId: 'r',
      streamId: 's',
      clientToken: '   ',
    );

    final params =
        (body['command']! as Map<String, Object?>)['params']!
            as Map<String, Object?>;
    expect(params.containsKey('client_token'), isFalse);
  });
}
