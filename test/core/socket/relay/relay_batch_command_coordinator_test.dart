import 'dart:async';

import 'package:checks/checks.dart';
import 'package:colmeia/core/socket/relay/relay_batch_command_coordinator.dart';
import 'package:colmeia/core/socket/relay/relay_batch_item.dart';
import 'package:colmeia/core/socket/relay/relay_command_dispatcher.dart';
import 'package:colmeia/core/socket/relay/relay_dispatch_exception.dart';
import 'package:colmeia/core/socket/relay/relay_event_names.dart';
import 'package:colmeia/core/socket/relay/relay_rpc_outcome.dart';
import 'package:flutter_test/flutter_test.dart';

/// Records every call the coordinator forwards to the inner dispatcher
/// and lets each test stub the response shape per surface.
class _RecordingRelayDispatcher implements RelayCommandDispatcher {
  final List<_UnaryCall> unaryCalls = <_UnaryCall>[];
  final List<_BatchCall> batchCalls = <_BatchCall>[];
  final List<_StreamingCall> streamingCalls = <_StreamingCall>[];
  final List<String> cancelledIds = <String>[];

  Future<List<Map<String, dynamic>>> Function(
    String agentId,
    List<RelayBatchItem> items,
  )?
  onBatch;
  int innerDisposeCalls = 0;

  @override
  Future<Map<String, dynamic>> sendUnary({
    required String agentId,
    required Map<String, Object?> body,
    required String clientRequestId,
    Duration? timeout,
    RelayPayloadFrameCompression compression =
        RelayPayloadFrameCompression.auto,
  }) async {
    unaryCalls.add(
      _UnaryCall(
        agentId: agentId,
        body: body,
        clientRequestId: clientRequestId,
      ),
    );
    return <String, dynamic>{
      'response': <String, dynamic>{
        'type': 'single',
        'success': true,
        'item': <String, dynamic>{'id': clientRequestId, 'success': true},
      },
    };
  }

  @override
  Future<List<Map<String, dynamic>>> sendBatch({
    required String agentId,
    required List<RelayBatchItem> items,
    Duration? timeout,
    RelayPayloadFrameCompression compression =
        RelayPayloadFrameCompression.auto,
  }) async {
    batchCalls.add(_BatchCall(agentId: agentId, items: items));
    final handler = onBatch;
    if (handler != null) {
      return handler(agentId, items);
    }
    return items
        .map(
          (item) => <String, dynamic>{
            'response': <String, dynamic>{
              'type': 'single',
              'success': true,
              'item': <String, dynamic>{
                'id': item.clientRequestId,
                'success': true,
              },
            },
          },
        )
        .toList(growable: false);
  }

  @override
  Stream<Map<String, dynamic>> sendStreaming({
    required String agentId,
    required Map<String, Object?> body,
    required String clientRequestId,
    Duration? timeout,
    int? initialWindowSize,
    int? refillThreshold,
    RelayPayloadFrameCompression compression =
        RelayPayloadFrameCompression.auto,
  }) {
    streamingCalls.add(
      _StreamingCall(
        agentId: agentId,
        body: body,
        clientRequestId: clientRequestId,
      ),
    );
    return Stream<Map<String, dynamic>>.fromIterable(<Map<String, dynamic>>[
      <String, dynamic>{'request_id': clientRequestId},
    ]);
  }

  @override
  void cancel(String clientRequestId, {String reason = 'caller_cancelled'}) {
    cancelledIds.add(clientRequestId);
  }

  @override
  Stream<RelayRpcOutcome> outcomes() => const Stream<RelayRpcOutcome>.empty();

  @override
  Future<void> dispose() async {
    innerDisposeCalls += 1;
  }
}

class _UnaryCall {
  _UnaryCall({
    required this.agentId,
    required this.body,
    required this.clientRequestId,
  });
  final String agentId;
  final Map<String, Object?> body;
  final String clientRequestId;
}

class _BatchCall {
  _BatchCall({required this.agentId, required this.items});
  final String agentId;
  final List<RelayBatchItem> items;
}

class _StreamingCall {
  _StreamingCall({
    required this.agentId,
    required this.body,
    required this.clientRequestId,
  });
  final String agentId;
  final Map<String, Object?> body;
  final String clientRequestId;
}

Map<String, Object?> _bodyFor({
  String method = 'sql.execute',
  String id = 'rpc-1',
  Map<String, Object?>? options,
}) {
  return <String, Object?>{
    'command': <String, Object?>{
      'jsonrpc': '2.0',
      'method': method,
      'id': id,
      'params': <String, Object?>{
        'sql': 'SELECT 1',
        'options': ?options,
      },
    },
  };
}

void main() {
  late _RecordingRelayDispatcher inner;
  late RelayBatchCommandCoordinator coordinator;
  late List<int> emissions;
  late List<String> bypassReasons;

  setUp(() {
    inner = _RecordingRelayDispatcher();
    emissions = <int>[];
    bypassReasons = <String>[];
    coordinator = RelayBatchCommandCoordinator(
      inner: inner,
      windowDuration: const Duration(milliseconds: 5),
      maxBatchSize: 4,
      onBatchEmission: ({required size, required partialFailure}) =>
          emissions.add(size),
      onBypass: ({required reason}) => bypassReasons.add(reason),
    );
  });

  tearDown(() async {
    await coordinator.dispose();
  });

  group('constructor guards', () {
    test('rejects negative window', () {
      check(
        () => RelayBatchCommandCoordinator(
          inner: _RecordingRelayDispatcher(),
          windowDuration: const Duration(milliseconds: -1),
        ),
      ).throws<AssertionError>();
    });

    test('rejects maxBatchSize < 1', () {
      check(
        () => RelayBatchCommandCoordinator(
          inner: _RecordingRelayDispatcher(),
          maxBatchSize: 0,
        ),
      ).throws<AssertionError>();
    });
  });

  group('batching behaviour', () {
    test(
      'two concurrent unaries to the same agent flush as one batch',
      () async {
        final f1 = coordinator.sendUnary(
          agentId: 'agent-1',
          body: _bodyFor(id: 'rpc-a'),
          clientRequestId: 'rpc-a',
        );
        final f2 = coordinator.sendUnary(
          agentId: 'agent-1',
          body: _bodyFor(id: 'rpc-b'),
          clientRequestId: 'rpc-b',
        );

        final results = await Future.wait(<Future<Map<String, dynamic>>>[
          f1,
          f2,
        ]);

        check(inner.batchCalls.length).equals(1);
        check(inner.unaryCalls).isEmpty();
        final batch = inner.batchCalls.single;
        check(batch.agentId).equals('agent-1');
        check(batch.items.length).equals(2);
        check(
          batch.items.map((i) => i.clientRequestId).toSet(),
        ).deepEquals(<String>{'rpc-a', 'rpc-b'});
        check(results.length).equals(2);
        check(emissions).deepEquals(<int>[2]);
      },
    );

    test('unaries to different agents flush as independent batches', () async {
      final fa = coordinator.sendUnary(
        agentId: 'agent-A',
        body: _bodyFor(id: 'a'),
        clientRequestId: 'a',
      );
      final fb = coordinator.sendUnary(
        agentId: 'agent-B',
        body: _bodyFor(id: 'b'),
        clientRequestId: 'b',
      );

      await Future.wait(<Future<Map<String, dynamic>>>[fa, fb]);

      check(inner.batchCalls.length).equals(2);
      check(
        inner.batchCalls.map((c) => c.agentId).toSet(),
      ).deepEquals(<String>{'agent-A', 'agent-B'});
      for (final call in inner.batchCalls) {
        check(call.items.length).equals(1);
        check(call.items.single.clientRequestId).equals(
          call.agentId == 'agent-A' ? 'a' : 'b',
        );
      }
    });

    test('hitting maxBatchSize triggers immediate flush', () async {
      final futures = <Future<Map<String, dynamic>>>[];
      for (var i = 0; i < 4; i++) {
        futures.add(
          coordinator.sendUnary(
            agentId: 'agent-1',
            body: _bodyFor(id: 'rpc-$i'),
            clientRequestId: 'rpc-$i',
          ),
        );
      }
      await Future.wait(futures);
      check(inner.batchCalls.length).equals(1);
      check(inner.batchCalls.single.items.length).equals(4);
    });

    test(
      'beyond maxBatchSize triggers a follow-up batch in the next window',
      () async {
        final futures = <Future<Map<String, dynamic>>>[];
        for (var i = 0; i < 5; i++) {
          futures.add(
            coordinator.sendUnary(
              agentId: 'agent-1',
              body: _bodyFor(id: 'rpc-$i'),
              clientRequestId: 'rpc-$i',
            ),
          );
        }
        await Future.wait(futures);
        check(inner.batchCalls.length).equals(2);
        check(inner.batchCalls[0].items.length).equals(4);
        check(inner.batchCalls[1].items.length).equals(1);
      },
    );
  });

  group('automatic bypass', () {
    test('sql.executeBatch bypasses the coordinator', () async {
      await coordinator.sendUnary(
        agentId: 'agent-1',
        body: _bodyFor(method: 'sql.executeBatch'),
        clientRequestId: 'rpc-eb',
      );
      check(inner.unaryCalls.length).equals(1);
      check(inner.batchCalls).isEmpty();
      check(bypassReasons).contains('executeBatch');
    });

    test('sql.cancel bypasses the coordinator (latency-critical)', () async {
      await coordinator.sendUnary(
        agentId: 'agent-1',
        body: _bodyFor(method: 'sql.cancel'),
        clientRequestId: 'rpc-c',
      );
      check(inner.unaryCalls.length).equals(1);
      check(bypassReasons).contains('cancel');
    });

    test('multi_result option bypasses the coordinator', () async {
      await coordinator.sendUnary(
        agentId: 'agent-1',
        body: _bodyFor(options: <String, Object?>{'multi_result': true}),
        clientRequestId: 'rpc-mr',
      );
      check(inner.unaryCalls.length).equals(1);
      check(bypassReasons).contains('multi_result');
    });

    test('prefer_db_streaming option bypasses the coordinator', () async {
      await coordinator.sendUnary(
        agentId: 'agent-1',
        body: _bodyFor(
          options: <String, Object?>{'prefer_db_streaming': true},
        ),
        clientRequestId: 'rpc-stream',
      );
      check(inner.unaryCalls.length).equals(1);
      check(bypassReasons).contains('prefer_db_streaming');
    });

    test('unknown method bypasses the coordinator', () async {
      await coordinator.sendUnary(
        agentId: 'agent-1',
        body: const <String, Object?>{'command': 'not a map'},
        clientRequestId: 'rpc-unknown',
      );
      check(inner.unaryCalls.length).equals(1);
      check(bypassReasons).contains('unknown_method');
    });
  });

  group('passthrough surfaces', () {
    test('sendStreaming bypasses batching entirely', () async {
      final stream = coordinator.sendStreaming(
        agentId: 'agent-1',
        body: _bodyFor(id: 'rpc-stream'),
        clientRequestId: 'rpc-stream',
      );
      final received = await stream.toList();
      check(received.length).equals(1);
      check(inner.streamingCalls.length).equals(1);
      check(inner.batchCalls).isEmpty();
    });

    test('explicit sendBatch goes straight to the wire', () async {
      await coordinator.sendBatch(
        agentId: 'agent-1',
        items: <RelayBatchItem>[
          RelayBatchItem(
            clientRequestId: 'a',
            body: _bodyFor(id: 'a'),
          ),
        ],
      );
      check(inner.batchCalls.length).equals(1);
      check(emissions).isEmpty(); // emission counter is for sendUnary path
    });

    test('cancel forwards to the inner dispatcher', () async {
      // Cancel a request that is NOT queued in the coordinator — pure
      // passthrough.
      coordinator.cancel('rpc-x');
      check(inner.cancelledIds).deepEquals(<String>['rpc-x']);
    });

    test(
      'cancel removes a still-queued pending without emitting a batch',
      () async {
        final future = coordinator.sendUnary(
          agentId: 'agent-1',
          body: _bodyFor(id: 'rpc-q'),
          clientRequestId: 'rpc-q',
        );
        // Same reasoning as the dispose test: register the error handler
        // before the synchronous cancel settles the completer.
        final assertion = expectLater(
          future,
          throwsA(isA<RelayRequestCancelled>()),
        );

        coordinator.cancel('rpc-q');
        await assertion;
        // The window flush should NOT emit a batch (nothing left).
        await Future<void>.delayed(const Duration(milliseconds: 20));
        check(inner.batchCalls).isEmpty();
      },
    );
  });

  group('dispose', () {
    test('drains queued pendings with RelayDispatcherDisposed', () async {
      // Use a custom coordinator with a long window so the queue stays
      // populated until we call dispose.
      final scoped = RelayBatchCommandCoordinator(
        inner: inner,
        windowDuration: const Duration(seconds: 30),
      );
      final future = scoped.sendUnary(
        agentId: 'agent-1',
        body: _bodyFor(id: 'rpc-disp'),
        clientRequestId: 'rpc-disp',
      );
      // Attach the error handler BEFORE dispose synchronously settles
      // the pending: otherwise the error becomes "unhandled" in the
      // test zone before we get to await it.
      final assertion = expectLater(
        future,
        throwsA(isA<RelayDispatcherDisposed>()),
      );

      await scoped.dispose();
      await assertion;

      check(inner.batchCalls).isEmpty();
      check(inner.innerDisposeCalls).equals(1);
    });

    test('is idempotent', () async {
      final scoped = RelayBatchCommandCoordinator(inner: inner);
      await scoped.dispose();
      await scoped.dispose();
      // The inner dispatcher is disposed at most once per coordinator
      // dispose call to keep semantics clear; double-dispose on the
      // coordinator MUST NOT cascade twice.
      check(inner.innerDisposeCalls).equals(1);
    });
  });

  test('outcomes() forwards the inner stream', () async {
    final stream = coordinator.outcomes();
    final empty = await stream.isEmpty;
    check(empty).isTrue();
  });

  test('event name constants stay in sync with the hub contract', () {
    // Defensive check so a renamed constant gets caught here before any
    // batch test misroutes events. Hub contract reference:
    // `docs/server_adjustments/relay_rpc_batch_protocol.md`.
    check(RelayEventNames.rpcRequestBatch).equals('relay:rpc.request.batch');
    check(RelayEventNames.rpcBatchAccepted).equals('relay:rpc.batch_accepted');
  });
}
