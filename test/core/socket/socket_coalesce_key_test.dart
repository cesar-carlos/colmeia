import 'package:checks/checks.dart';
import 'package:colmeia/core/socket/socket_coalesce_key.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Map<String, Object?> body({
    String agentId = 'agent-1',
    String? rpcId = 'rpc-1',
    String method = 'sql.execute',
    Map<String, Object?>? params = const <String, Object?>{
      'sql': 'SELECT 1',
    },
    int? timeoutMs,
    Map<String, Object?>? pagination,
  }) {
    return <String, Object?>{
      'agentId': agentId,
      'timeoutMs': ?timeoutMs,
      'pagination': ?pagination,
      'command': <String, Object?>{
        'jsonrpc': '2.0',
        'method': method,
        'id': rpcId,
        'params': params,
      },
    };
  }

  group('SocketCoalesceKey.compute', () {
    test('two identical bodies produce the same key', () {
      final a = SocketCoalesceKey.compute(agentId: 'x', body: body());
      final b = SocketCoalesceKey.compute(agentId: 'x', body: body());
      check(a).isNotNull();
      check(a).equals(b);
    });

    test('rpcId differences are ignored', () {
      final a = SocketCoalesceKey.compute(
        agentId: 'x',
        body: body(rpcId: 'rpc-A'),
      );
      final b = SocketCoalesceKey.compute(
        agentId: 'x',
        body: body(rpcId: 'rpc-B'),
      );
      check(a).equals(b);
    });

    test('params order independence', () {
      final a = SocketCoalesceKey.compute(
        agentId: 'x',
        body: body(
          params: const <String, Object?>{'k1': 1, 'k2': 2, 'k3': 3},
        ),
      );
      final b = SocketCoalesceKey.compute(
        agentId: 'x',
        body: body(
          params: const <String, Object?>{'k3': 3, 'k1': 1, 'k2': 2},
        ),
      );
      check(a).equals(b);
    });

    test('different agentIds produce different keys', () {
      final a = SocketCoalesceKey.compute(agentId: 'x', body: body());
      final b = SocketCoalesceKey.compute(agentId: 'y', body: body());
      check(a).isNotNull();
      check(a).not((it) => it.equals(b));
    });

    test('different methods produce different keys', () {
      final a = SocketCoalesceKey.compute(
        agentId: 'x',
        body: body(),
      );
      final b = SocketCoalesceKey.compute(
        agentId: 'x',
        body: body(method: 'agent.getProfile'),
      );
      check(a).not((it) => it.equals(b));
    });

    test('different params produce different keys', () {
      final a = SocketCoalesceKey.compute(
        agentId: 'x',
        body: body(),
      );
      final b = SocketCoalesceKey.compute(
        agentId: 'x',
        body: body(params: const <String, Object?>{'sql': 'SELECT 2'}),
      );
      check(a).not((it) => it.equals(b));
    });

    test(
      'different timeoutMs splits the key (caller may need stricter SLA)',
      () {
        final a = SocketCoalesceKey.compute(
          agentId: 'x',
          body: body(timeoutMs: 5000),
        );
        final b = SocketCoalesceKey.compute(
          agentId: 'x',
          body: body(timeoutMs: 10000),
        );
        check(a).not((it) => it.equals(b));
      },
    );

    test('different pagination splits the key', () {
      final a = SocketCoalesceKey.compute(
        agentId: 'x',
        body: body(
          pagination: const <String, Object?>{'page': 1, 'pageSize': 50},
        ),
      );
      final b = SocketCoalesceKey.compute(
        agentId: 'x',
        body: body(
          pagination: const <String, Object?>{'page': 2, 'pageSize': 50},
        ),
      );
      check(a).not((it) => it.equals(b));
    });

    test('returns null when command.method is missing', () {
      final key = SocketCoalesceKey.compute(
        agentId: 'x',
        body: <String, Object?>{
          'agentId': 'x',
          'command': <String, Object?>{'jsonrpc': '2.0', 'id': 'rpc-1'},
        },
      );
      check(key).isNull();
    });

    test('returns null when command is missing', () {
      final key = SocketCoalesceKey.compute(
        agentId: 'x',
        body: <String, Object?>{'agentId': 'x'},
      );
      check(key).isNull();
    });

    test('handles deeply nested params with stable ordering', () {
      final a = SocketCoalesceKey.compute(
        agentId: 'x',
        body: body(
          params: const <String, Object?>{
            'sql': 'SELECT * FROM t WHERE k = :k',
            'params': <String, Object?>{'k': 1, 'b': 2, 'a': 3},
            'options': <String, Object?>{
              'execution_mode': 'preserve',
              'max_rows': 1000,
            },
          },
        ),
      );
      final b = SocketCoalesceKey.compute(
        agentId: 'x',
        body: body(
          params: const <String, Object?>{
            'options': <String, Object?>{
              'max_rows': 1000,
              'execution_mode': 'preserve',
            },
            'sql': 'SELECT * FROM t WHERE k = :k',
            'params': <String, Object?>{'a': 3, 'k': 1, 'b': 2},
          },
        ),
      );
      check(a).equals(b);
    });
  });
}
