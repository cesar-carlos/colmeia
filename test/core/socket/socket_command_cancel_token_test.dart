// Test-only: sequential `token.register(...)` / `token.cancelAll()`
// statements describe the arrange→act steps of each test more
// clearly than cascades.
// ignore_for_file: cascade_invocations

import 'package:checks/checks.dart';
import 'package:colmeia/core/socket/socket_command_cancel_token.dart';
import 'package:colmeia/core/socket/socket_command_dispatcher.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockDispatcher extends Mock implements SocketCommandDispatcher {}

void main() {
  late _MockDispatcher dispatcher;
  late SocketCommandCancelToken token;

  setUp(() {
    dispatcher = _MockDispatcher();
    when(() => dispatcher.cancel(any(), reason: any(named: 'reason')))
        .thenReturn(null);
    token = SocketCommandCancelToken(dispatcher: dispatcher);
  });

  group('SocketCommandCancelToken', () {
    test('register tracks rpcIds and returns the id (chainable)', () {
      final id = token.register('rpc-1');
      check(id).equals('rpc-1');
      check(token.pendingCount).equals(1);
      token.register('rpc-2');
      check(token.pendingCount).equals(2);
    });

    test('register de-duplicates the same rpcId', () {
      token.register('rpc-1');
      token.register('rpc-1');
      check(token.pendingCount).equals(1);
    });

    test('unregister removes one rpcId', () {
      token.register('rpc-1');
      token.register('rpc-2');
      token.unregister('rpc-1');
      check(token.pendingCount).equals(1);
    });

    test('cancelAll fires dispatcher.cancel for every tracked id', () {
      token.register('rpc-1');
      token.register('rpc-2');
      token.cancelAll(reason: 'route_left');
      verify(() => dispatcher.cancel('rpc-1', reason: 'route_left'))
          .called(1);
      verify(() => dispatcher.cancel('rpc-2', reason: 'route_left'))
          .called(1);
      check(token.pendingCount).equals(0);
    });

    test('cancelAll uses the default reason when none is supplied', () {
      token.register('rpc-x');
      token.cancelAll();
      verify(() => dispatcher.cancel('rpc-x', reason: 'caller_cancelled'))
          .called(1);
    });

    test('cancelAll on empty bag is a silent no-op', () {
      token.cancelAll();
      verifyNever(
        () => dispatcher.cancel(any(), reason: any(named: 'reason')),
      );
    });

    test(
      'dispose cancels pendings with token_disposed and blocks future register',
      () {
        token.register('rpc-1');
        token.dispose();
        verify(() => dispatcher.cancel('rpc-1', reason: 'token_disposed'))
            .called(1);
        check(token.isDisposed).isTrue();

        // After dispose, register is a no-op.
        token.register('rpc-2');
        check(token.pendingCount).equals(0);

        // Repeat dispose is silent.
        token.dispose();
        verifyNever(
          () => dispatcher.cancel('rpc-2', reason: any(named: 'reason')),
        );
      },
    );
  });
}
