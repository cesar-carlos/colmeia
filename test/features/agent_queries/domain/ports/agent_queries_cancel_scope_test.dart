import 'package:colmeia/features/agent_queries/domain/ports/agent_queries_cancel_scope.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('cancelAll invokes relay, socket, rest, and streaming handlers', () {
    final scope = AgentQueriesCancelScope(traceId: 'trace-1');
    final relayIds = <String>[];
    final socketIds = <String>[];
    final streams = <AgentStreamingSqlCancelTarget>[];
    var restCancelled = false;

    scope
      ..relayCancelHandler = relayIds.addAll
      ..socketRpcCancelHandler = socketIds.addAll
      ..streamingSqlCancelHandler = streams.addAll
      ..trackRelayPending('relay-req-1')
      ..trackSocketPending('socket-rpc-1')
      ..trackRestPending(() => restCancelled = true)
      ..trackStreamingSql(
        const AgentStreamingSqlCancelTarget(
          agentId: 'a1',
          streamId: 's1',
        ),
      )
      ..cancelAll();

    expect(scope.isCancelled, isTrue);
    expect(relayIds, ['relay-req-1']);
    expect(socketIds, ['socket-rpc-1']);
    expect(restCancelled, isTrue);
    expect(streams, hasLength(1));
    expect(streams.first.streamId, 's1');
  });

  test(
    'cancelAll starts stream cancellation before local transport cleanup',
    () {
      final scope = AgentQueriesCancelScope();
      final calls = <String>[];

      void relayCancelHandler(Iterable<String> _) {
        calls.add('relay');
      }

      void socketCancelHandler(Iterable<String> _) {
        calls.add('socket');
      }

      void streamCancelHandler(Iterable<AgentStreamingSqlCancelTarget> _) {
        calls.add('stream');
      }

      scope
        ..relayCancelHandler = relayCancelHandler
        ..socketRpcCancelHandler = socketCancelHandler
        ..streamingSqlCancelHandler = streamCancelHandler
        ..trackRestPending(() => calls.add('rest'))
        ..registerLocalCancellation(() => calls.add('local'))
        ..trackRelayPending('relay-1')
        ..trackSocketPending('socket-1')
        ..trackStreamingSql(
          const AgentStreamingSqlCancelTarget(agentId: 'a', streamId: 's'),
        )
        ..cancelAll();

      expect(calls, <String>['stream', 'local', 'relay', 'socket', 'rest']);
    },
  );

  test('relay cancel does not pass socket ids and vice versa', () {
    final scope = AgentQueriesCancelScope();
    final relayIds = <String>[];
    final socketIds = <String>[];

    scope
      ..relayCancelHandler = relayIds.addAll
      ..socketRpcCancelHandler = socketIds.addAll
      ..trackRelayPending('relay-only')
      ..trackSocketPending('socket-only')
      ..cancelAll();

    expect(relayIds, ['relay-only']);
    expect(socketIds, ['socket-only']);
  });

  test('trackStreamingSql deduplicates by agent and stream', () {
    final scope = AgentQueriesCancelScope();
    final streams = <AgentStreamingSqlCancelTarget>[];

    scope
      ..streamingSqlCancelHandler = streams.addAll
      ..trackStreamingSql(
        const AgentStreamingSqlCancelTarget(agentId: 'a', streamId: 's'),
      )
      ..trackStreamingSql(
        const AgentStreamingSqlCancelTarget(agentId: 'a', streamId: 's'),
      )
      ..cancelAll();

    expect(streams, hasLength(1));
  });

  test('normal stream completion removes its cancellation target', () {
    final scope = AgentQueriesCancelScope();
    final streams = <AgentStreamingSqlCancelTarget>[];
    const target = AgentStreamingSqlCancelTarget(agentId: 'a', streamId: 's');

    scope
      ..streamingSqlCancelHandler = streams.addAll
      ..trackStreamingSql(target)
      ..untrackStreamingSql(target)
      ..cancelAll();

    expect(streams, isEmpty);
  });

  test('targeted stream cancellation emits once and removes the target', () {
    final scope = AgentQueriesCancelScope();
    final streams = <AgentStreamingSqlCancelTarget>[];
    const target = AgentStreamingSqlCancelTarget(agentId: 'a', streamId: 's');

    scope
      ..streamingSqlCancelHandler = streams.addAll
      ..trackStreamingSql(target)
      ..cancelStreamingSql(target)
      ..cancelStreamingSql(target)
      ..cancelAll();

    expect(streams, hasLength(1));
    expect(streams.single.streamId, 's');
  });
}
