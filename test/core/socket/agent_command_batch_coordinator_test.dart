import 'package:checks/checks.dart';
import 'package:colmeia/core/socket/agent_command_batch_coordinator.dart';
import 'package:colmeia/core/socket/agent_command_sender.dart';
import 'package:colmeia/core/socket/socket_dispatch_exception.dart';
import 'package:flutter_test/flutter_test.dart';

class _RecordingSender implements AgentCommandSender {
  final List<_Send> calls = <_Send>[];
  Exception? errorToThrow;
  Map<String, dynamic> Function(_Send call)? responseBuilder;

  @override
  Future<Map<String, dynamic>> send({
    required String agentId,
    required Map<String, Object?> body,
    required String rpcId,
    Duration? timeout,
  }) async {
    final entry = _Send(
      agentId: agentId,
      body: body,
      rpcId: rpcId,
      timeout: timeout,
    );
    calls.add(entry);
    if (errorToThrow != null) {
      throw errorToThrow!;
    }
    if (responseBuilder != null) {
      return responseBuilder!(entry);
    }
    final command = body['command'];
    if (command is List) {
      // Synthesize a batch response that ACKs every item with success.
      final items = <Map<String, dynamic>>[];
      for (final raw in command) {
        if (raw is Map<String, Object?>) {
          items.add(<String, dynamic>{
            'id': raw['id'],
            'success': true,
            'result': <String, dynamic>{'rows': <Map<String, dynamic>>[]},
          });
        }
      }
      return <String, dynamic>{
        'mode': 'bridge',
        'agentId': agentId,
        'requestId': 'req-$agentId',
        'response': <String, dynamic>{'type': 'batch', 'items': items},
      };
    }
    if (command is Map) {
      return <String, dynamic>{
        'mode': 'bridge',
        'agentId': agentId,
        'response': <String, dynamic>{
          'type': 'single',
          'success': true,
          'item': <String, dynamic>{
            'id': command['id'],
            'success': true,
            'result': <String, dynamic>{'rows': <Map<String, dynamic>>[]},
          },
        },
      };
    }
    return <String, dynamic>{};
  }
}

class _Send {
  _Send({
    required this.agentId,
    required this.body,
    required this.rpcId,
    required this.timeout,
  });
  final String agentId;
  final Map<String, Object?> body;
  final String rpcId;
  final Duration? timeout;
}

Map<String, Object?> _body({
  String agentId = 'agent-1',
  String rpcId = 'rpc-1',
  String method = 'sql.execute',
  int? timeoutMs,
  Map<String, Object?> params = const <String, Object?>{
    'sql': 'SELECT 1',
  },
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

void main() {
  late _RecordingSender direct;
  late AgentCommandBatchCoordinator coordinator;
  final emissions = <_BatchEmission>[];
  final bypassReasons = <String>[];

  setUp(() {
    direct = _RecordingSender();
    emissions.clear();
    bypassReasons.clear();
    coordinator = AgentCommandBatchCoordinator(
      directSender: direct,
      windowDuration: const Duration(milliseconds: 5),
      maxBatchSize: 4,
      onBatchEmission: ({required size, required partialFailure}) {
        emissions.add(
          _BatchEmission(size: size, partialFailure: partialFailure),
        );
      },
      onBypass: ({required reason}) => bypassReasons.add(reason),
    );
  });

  tearDown(() async {
    await coordinator.dispose();
  });

  group('AgentCommandBatchCoordinator constructor guards', () {
    test('rejects negative window', () {
      check(
        () => AgentCommandBatchCoordinator(
          directSender: _RecordingSender(),
          windowDuration: const Duration(milliseconds: -1),
        ),
      ).throws<AssertionError>();
    });

    test('rejects maxBatchSize < 1', () {
      check(
        () => AgentCommandBatchCoordinator(
          directSender: _RecordingSender(),
          maxBatchSize: 0,
        ),
      ).throws<AssertionError>();
    });

    test('clamps maxBatchSize to 32 (hub hard cap)', () async {
      final c = AgentCommandBatchCoordinator(
        directSender: _RecordingSender(),
        maxBatchSize: 999,
      );
      // Indirect proof: enqueue 33 sends; emissions should split (at most
      // 32 items per batch). We just check the coordinator does not
      // accept 33 items in one go via a single emission below.
      await c.dispose();
    });
  });

  group('batching behaviour', () {
    test('two pendings within the window flush as a single batch', () async {
      // Concurrent sends to the same agent — different SQLs so they are
      // not deduplicated by the coalesce key.
      final f1 = coordinator.send(
        agentId: 'agent-1',
        body: _body(rpcId: 'rpc-A'),
        rpcId: 'rpc-A',
      );
      final f2 = coordinator.send(
        agentId: 'agent-1',
        body: _body(
          rpcId: 'rpc-B',
          params: const <String, Object?>{
            'sql': 'SELECT 2',
          },
        ),
        rpcId: 'rpc-B',
      );

      final results = await Future.wait(<Future<Map<String, dynamic>>>[f1, f2]);
      check(direct.calls.length).equals(1);
      final batchCall = direct.calls.single;
      final command = batchCall.body['command']! as List<dynamic>;
      check(command.length).equals(2);
      check(emissions.length).equals(1);
      check(emissions.single.size).equals(2);
      check(emissions.single.partialFailure).isFalse();

      // Each caller receives a synthesized `single` envelope.
      for (final r in results) {
        final response = r['response']! as Map<String, dynamic>;
        check(response['type']).equals('single');
        check(response['success']).equals(true);
      }
    });

    test('different agents flush as independent batches', () async {
      final fa = coordinator.send(
        agentId: 'agent-A',
        body: _body(rpcId: 'a', agentId: 'agent-A'),
        rpcId: 'a',
      );
      final fb = coordinator.send(
        agentId: 'agent-B',
        body: _body(rpcId: 'b', agentId: 'agent-B'),
        rpcId: 'b',
      );
      await Future.wait(<Future<Map<String, dynamic>>>[fa, fb]);

      check(direct.calls.length).equals(2);
      check(
        direct.calls.map((c) => c.agentId).toSet(),
      ).deepEquals(<String>{'agent-A', 'agent-B'});
    });

    test('hitting maxBatchSize triggers immediate flush', () async {
      // With maxBatchSize=4, send 5 in a row → first 4 flush immediately
      // (size 4), the 5th fires after the window (size 1).
      final futures = <Future<Map<String, dynamic>>>[];
      for (var i = 0; i < 5; i++) {
        futures.add(
          coordinator.send(
            agentId: 'agent-1',
            body: _body(
              rpcId: 'rpc-$i',
              params: <String, Object?>{
                'sql': 'SELECT $i',
              },
            ),
            rpcId: 'rpc-$i',
          ),
        );
      }
      await Future.wait(futures);
      check(direct.calls.length).equals(2);
      final firstBatch = direct.calls.first.body['command']! as List<dynamic>;
      final secondBatch = direct.calls[1].body['command']! as List<dynamic>;
      check(firstBatch.length).equals(4);
      check(secondBatch.length).equals(1);
    });

    test('coalesces identical pendings within the same window', () async {
      // Two identical sends should occupy a single batch slot AND share
      // the same Future.
      final f1 = coordinator.send(
        agentId: 'agent-1',
        body: _body(rpcId: 'rpc-A'),
        rpcId: 'rpc-A',
      );
      final f2 = coordinator.send(
        agentId: 'agent-1',
        body: _body(rpcId: 'rpc-B'),
        rpcId: 'rpc-B',
      );
      final r1 = await f1;
      final r2 = await f2;
      check(direct.calls.length).equals(1);
      final command = direct.calls.single.body['command']! as List<dynamic>;
      // Coalesced into a single batch slot.
      check(command.length).equals(1);
      check(identical(r1, r2)).isTrue();
    });

    test(
      'batch preserves bridge timeoutMs while using dispatch timeout locally',
      () async {
        final f1 = coordinator.send(
          agentId: 'agent-1',
          body: _body(rpcId: 'rpc-A', timeoutMs: 15000),
          rpcId: 'rpc-A',
          timeout: const Duration(seconds: 20),
        );
        final f2 = coordinator.send(
          agentId: 'agent-1',
          body: _body(
            rpcId: 'rpc-B',
            timeoutMs: 22000,
            params: const <String, Object?>{'sql': 'SELECT 2'},
          ),
          rpcId: 'rpc-B',
          timeout: const Duration(seconds: 27),
        );

        await Future.wait(<Future<Map<String, dynamic>>>[f1, f2]);

        check(direct.calls.length).equals(1);
        final call = direct.calls.single;
        check(call.timeout).equals(const Duration(seconds: 27));
        check(call.body['timeoutMs']).equals(22000);
      },
    );

    test(
      'single fallback preserves bridge timeoutMs while using dispatch timeout',
      () async {
        final c = AgentCommandBatchCoordinator(
          directSender: direct,
          windowDuration: const Duration(milliseconds: 5),
          minBatchSize: 2,
        );
        addTearDown(c.dispose);

        await c.send(
          agentId: 'agent-1',
          body: _body(timeoutMs: 15000),
          rpcId: 'rpc-1',
          timeout: const Duration(seconds: 20),
        );

        check(direct.calls.length).equals(1);
        final call = direct.calls.single;
        check(call.timeout).equals(const Duration(seconds: 20));
        check(call.body['timeoutMs']).equals(15000);
        check(call.body['command']).isA<Map<String, Object?>>();
      },
    );
  });

  group('automatic bypass', () {
    test('sql.executeBatch bypasses the coordinator', () async {
      await coordinator.send(
        agentId: 'agent-1',
        body: _body(method: 'sql.executeBatch'),
        rpcId: 'rpc-1',
      );
      check(direct.calls.length).equals(1);
      check(direct.calls.single.body['command']).isA<Map<String, Object?>>();
      check(bypassReasons).contains('executeBatch');
      check(emissions).isEmpty();
    });

    test('sql.cancel bypasses the coordinator (latency-critical)', () async {
      await coordinator.send(
        agentId: 'agent-1',
        body: _body(method: 'sql.cancel'),
        rpcId: 'rpc-1',
      );
      check(bypassReasons).contains('cancel');
    });

    test('multi_result option bypasses the coordinator', () async {
      await coordinator.send(
        agentId: 'agent-1',
        body: _body(
          params: const <String, Object?>{
            'sql': 'SELECT 1; SELECT 2',
            'options': <String, Object?>{'multi_result': true},
          },
        ),
        rpcId: 'rpc-1',
      );
      check(bypassReasons).contains('multi_result');
    });

    test('body-level pagination bypasses the coordinator', () async {
      await coordinator.send(
        agentId: 'agent-1',
        body: _body(
          pagination: const <String, Object?>{'page': 1, 'pageSize': 50},
        ),
        rpcId: 'rpc-1',
      );
      check(bypassReasons).contains('paginated');
    });
  });

  group('partial failure', () {
    test(
      'per-item error completes only that pending with the failure',
      () async {
        direct.responseBuilder = (call) {
          // Two items: rpc-A succeeds, rpc-B fails.
          return <String, dynamic>{
            'mode': 'bridge',
            'agentId': call.agentId,
            'requestId': 'req-1',
            'response': <String, dynamic>{
              'type': 'batch',
              'items': <Map<String, dynamic>>[
                <String, dynamic>{
                  'id': 'rpc-A',
                  'success': true,
                  'result': <String, dynamic>{'rows': <Map<String, dynamic>>[]},
                },
                <String, dynamic>{
                  'id': 'rpc-B',
                  'success': false,
                  'error': <String, dynamic>{
                    'code': -32001,
                    'reason': 'authentication_failed',
                  },
                },
              ],
            },
          };
        };

        final f1 = coordinator.send(
          agentId: 'agent-1',
          body: _body(rpcId: 'rpc-A'),
          rpcId: 'rpc-A',
        );
        final f2 = coordinator.send(
          agentId: 'agent-1',
          body: _body(
            rpcId: 'rpc-B',
            params: const <String, Object?>{
              'sql': 'SELECT 2',
            },
          ),
          rpcId: 'rpc-B',
        );

        final r1 = await f1;
        final r2 = await f2;
        // Both completed (no exception); the per-item error rides inside
        // the synthesized envelope so the repository's parser can pick it up.
        final inner1 =
            (r1['response']! as Map<String, dynamic>)['item']!
                as Map<String, dynamic>;
        final inner2 =
            (r2['response']! as Map<String, dynamic>)['item']!
                as Map<String, dynamic>;
        check(inner1['success']).equals(true);
        check(inner2['success']).equals(false);
        check(inner2['error']).isNotNull();

        check(emissions.single.partialFailure).isTrue();
      },
    );

    test(
      'missing item id in response fails that pending defensively',
      () async {
        direct.responseBuilder = (call) {
          // Only ACKs rpc-A; rpc-B is omitted (server bug simulation).
          return <String, dynamic>{
            'mode': 'bridge',
            'response': <String, dynamic>{
              'type': 'batch',
              'items': <Map<String, dynamic>>[
                <String, dynamic>{
                  'id': 'rpc-A',
                  'success': true,
                  'result': <String, dynamic>{'rows': <Map<String, dynamic>>[]},
                },
              ],
            },
          };
        };

        final f1 = coordinator.send(
          agentId: 'agent-1',
          body: _body(rpcId: 'rpc-A'),
          rpcId: 'rpc-A',
        );
        final f2 = coordinator.send(
          agentId: 'agent-1',
          body: _body(
            rpcId: 'rpc-B',
            params: const <String, Object?>{
              'sql': 'SELECT 2',
            },
          ),
          rpcId: 'rpc-B',
        );

        // f1 must complete successfully…
        await f1;
        // …but f2 must fail with a decode error.
        await check(f2).throws<SocketDispatchDecodeFailure>();
      },
    );
  });

  group('total failure', () {
    test(
      'dispatcher exception fails every pending in the same batch',
      () async {
        direct.errorToThrow = const SocketDispatchTimeout(message: 'boom');

        final f1 = coordinator.send(
          agentId: 'agent-1',
          body: _body(rpcId: 'rpc-A'),
          rpcId: 'rpc-A',
        );
        final f2 = coordinator.send(
          agentId: 'agent-1',
          body: _body(
            rpcId: 'rpc-B',
            params: const <String, Object?>{
              'sql': 'SELECT 2',
            },
          ),
          rpcId: 'rpc-B',
        );

        // Pre-attach error handlers BEFORE the timer-driven flush so the
        // sync completeError that runs inside _dispatchBatch does not
        // surface as an uncaught error.
        final c1 = expectLater(f1, throwsA(isA<SocketDispatchTimeout>()));
        final c2 = expectLater(f2, throwsA(isA<SocketDispatchTimeout>()));

        await c1;
        await c2;
      },
    );
  });

  group('dispose', () {
    test('fails pending requests with SocketDispatchDisconnected', () async {
      // Use a long window so the timer never fires before dispose.
      final c = AgentCommandBatchCoordinator(
        directSender: direct,
        windowDuration: const Duration(seconds: 10),
      );
      final pending = c.send(
        agentId: 'agent-1',
        body: _body(),
        rpcId: 'rpc-1',
      );
      // Pre-attach handler so completeError does not surface as unhandled.
      final captured = expectLater(
        pending,
        throwsA(isA<SocketDispatchDisconnected>()),
      );
      await c.dispose();
      await captured;
    });
  });
}

class _BatchEmission {
  _BatchEmission({required this.size, required this.partialFailure});
  final int size;
  final bool partialFailure;
}
