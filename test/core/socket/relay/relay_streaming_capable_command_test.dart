import 'package:checks/checks.dart';
import 'package:colmeia/core/socket/relay/relay_streaming_capable_command.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('isRelayStreamingCapableRpcBody', () {
    test('false for plain sql.execute', () {
      check(
        isRelayStreamingCapableRpcBody(<String, Object?>{
          'jsonrpc': '2.0',
          'method': 'sql.execute',
          'id': '1',
          'params': <String, Object?>{
            'sql': 'SELECT 1',
            'options': <String, Object?>{'max_rows': 1},
          },
        }),
      ).isFalse();
    });

    test('true when prefer_db_streaming is set on relay body', () {
      check(
        isRelayStreamingCapableRpcBody(<String, Object?>{
          'jsonrpc': '2.0',
          'method': 'sql.execute',
          'id': '1',
          'params': <String, Object?>{
            'sql': 'SELECT 1',
            'options': <String, Object?>{'prefer_db_streaming': true},
          },
        }),
      ).isTrue();
    });

    test('true when multi_result is set', () {
      check(
        isRelayStreamingCapableRpcBody(<String, Object?>{
          'jsonrpc': '2.0',
          'method': 'sql.execute',
          'id': '1',
          'params': <String, Object?>{
            'sql': 'SELECT 1',
            'options': <String, Object?>{'multi_result': true},
          },
        }),
      ).isTrue();
    });

    test('true for sql.executeBatch', () {
      check(
        isRelayStreamingCapableRpcBody(<String, Object?>{
          'jsonrpc': '2.0',
          'method': 'sql.executeBatch',
          'id': '1',
          'params': <String, Object?>{
            'commands': <Object?>[],
          },
        }),
      ).isTrue();
    });

    test('reads nested bridge-shaped command wrapper', () {
      check(
        isRelayStreamingCapableRpcBody(<String, Object?>{
          'agentId': 'agent-1',
          'command': <String, Object?>{
            'jsonrpc': '2.0',
            'method': 'sql.execute',
            'id': '1',
            'params': <String, Object?>{
              'sql': 'SELECT 1',
              'options': <String, Object?>{'prefer_db_streaming': true},
            },
          },
        }),
      ).isTrue();
    });
  });
}
