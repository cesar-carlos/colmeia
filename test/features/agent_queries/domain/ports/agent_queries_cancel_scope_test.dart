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
}
