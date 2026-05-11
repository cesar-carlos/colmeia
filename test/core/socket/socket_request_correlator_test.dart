import 'package:checks/checks.dart';
import 'package:colmeia/core/socket/socket_dispatch_exception.dart';
import 'package:colmeia/core/socket/socket_request_correlator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SocketRequestCorrelator', () {
    late SocketRequestCorrelator correlator;

    setUp(() {
      correlator = SocketRequestCorrelator();
    });

    tearDown(() async {
      await correlator.dispose();
    });

    test('register + completeWith resolves the future', () async {
      final pending = correlator.register(
        'rpc-1',
        timeout: const Duration(seconds: 5),
      );
      check(correlator.pendingCount).equals(1);

      correlator.completeWith('rpc-1', <String, dynamic>{'ok': true});
      final result = await pending;
      check(result['ok']).equals(true);
      check(correlator.pendingCount).equals(0);
    });

    test('duplicate id throws synchronously', () async {
      final pending = correlator.register(
        'rpc-1',
        timeout: const Duration(seconds: 5),
      );
      // Attach an error handler BEFORE the next assertion so any later
      // teardown-time `failAll` does not produce an uncaught error.
      final captured = expectLater(
        pending,
        throwsA(isA<SocketDispatchDisconnected>()),
      );

      check(
        () => correlator.register('rpc-1', timeout: const Duration(seconds: 5)),
      ).throws<SocketDispatchDuplicateId>();

      // Trigger the (now expected) failure so the captured future resolves.
      correlator.failAll(
        const SocketDispatchDisconnected(message: 'cleanup'),
      );
      await captured;
    });

    test('failWith resolves the future with the given error', () async {
      final pending = correlator.register(
        'rpc-2',
        timeout: const Duration(seconds: 5),
      );
      correlator.failWith(
        'rpc-2',
        const SocketDispatchAppError(
          message: 'boom',
          serverCode: 'AGENT_ACCESS_DENIED',
        ),
      );

      await check(pending).throws<SocketDispatchAppError>();
      check(correlator.pendingCount).equals(0);
    });

    test('failAll cancels every pending', () async {
      final p1 = correlator.register('a', timeout: const Duration(seconds: 5));
      final p2 = correlator.register('b', timeout: const Duration(seconds: 5));

      // Pre-attach error handlers so the synchronous completeError does not
      // surface as unhandled.
      final c1 = expectLater(p1, throwsA(isA<SocketDispatchDisconnected>()));
      final c2 = expectLater(p2, throwsA(isA<SocketDispatchDisconnected>()));

      correlator.failAll(
        const SocketDispatchDisconnected(message: 'socket dropped'),
      );

      await c1;
      await c2;
      check(correlator.pendingCount).equals(0);
    });

    test(
      'solePendingRpcIdWhenUnambiguous is null unless exactly one pending',
      () async {
        check(correlator.solePendingRpcIdWhenUnambiguous).isNull();

        final p1 = correlator.register(
          'a',
          timeout: const Duration(seconds: 5),
        );
        check(correlator.solePendingRpcIdWhenUnambiguous).equals('a');

        final p2 = correlator.register(
          'b',
          timeout: const Duration(seconds: 5),
        );
        check(correlator.solePendingRpcIdWhenUnambiguous).isNull();

        final c1 = expectLater(
          p1,
          throwsA(isA<SocketDispatchDisconnected>()),
        );
        final c2 = expectLater(
          p2,
          throwsA(isA<SocketDispatchDisconnected>()),
        );
        correlator.failAll(
          const SocketDispatchDisconnected(message: 'cleanup'),
        );
        await c1;
        await c2;
      },
    );

    test(
      'solePendingRpcIdWhenUnambiguous is null after completeWith',
      () async {
        final pending = correlator.register(
          'x',
          timeout: const Duration(seconds: 5),
        );
        check(correlator.solePendingRpcIdWhenUnambiguous).equals('x');
        correlator.completeWith('x', <String, dynamic>{});
        await pending;
        check(correlator.solePendingRpcIdWhenUnambiguous).isNull();
      },
    );

    test('completeWith for unknown id invokes orphan hook and stays empty', () {
      final orphans = <String>[];
      final c = SocketRequestCorrelator(
        onOrphanWireResponse:
            ({
              required rpcId,
              required operation,
              required responseFieldCount,
            }) {
              orphans.add('$operation|$rpcId|$responseFieldCount');
            },
      );
      addTearDown(() async {
        await c.dispose();
      });
      c.completeWith('ghost', <String, dynamic>{'late': true, 'x': 2});
      check(orphans.single).equals('completeWith|ghost|2');
      check(c.pendingCount).equals(0);
    });

    test('failWith for unknown id invokes orphan hook', () {
      final orphans = <String>[];
      final c = SocketRequestCorrelator(
        onOrphanWireResponse:
            ({
              required rpcId,
              required operation,
              required responseFieldCount,
            }) {
              orphans.add('$operation|$rpcId|$responseFieldCount');
            },
      );
      addTearDown(() async {
        await c.dispose();
      });
      c.failWith('ghost', const SocketDispatchDisconnected(message: 'late'));
      check(orphans.single).equals('failWith|ghost|0');
      check(c.pendingCount).equals(0);
    });

    test('orphan completeWith after timeout triggers hook', () async {
      final orphans = <String>[];
      final c = SocketRequestCorrelator(
        onOrphanWireResponse:
            ({
              required rpcId,
              required operation,
              required responseFieldCount,
            }) {
              orphans.add(operation);
            },
      );
      addTearDown(() async {
        await c.dispose();
      });
      final pending = c.register(
        'rpc-late',
        timeout: const Duration(milliseconds: 20),
      );
      await check(pending).throws<SocketDispatchTimeout>();
      c.completeWith('rpc-late', <String, dynamic>{'ok': true});
      check(orphans).deepEquals(<String>['completeWith']);
    });

    test('timeout fires SocketDispatchTimeout', () async {
      final pending = correlator.register(
        'rpc-timeout',
        timeout: const Duration(milliseconds: 30),
      );
      await check(pending).throws<SocketDispatchTimeout>();
      check(correlator.pendingCount).equals(0);
    });

    test('register after dispose throws SocketDispatchDisconnected', () async {
      final c = SocketRequestCorrelator();
      await c.dispose();
      check(
        () => c.register('any', timeout: const Duration(seconds: 1)),
      ).throws<SocketDispatchDisconnected>();
    });
  });
}
