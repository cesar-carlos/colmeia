import 'package:colmeia/features/agent_queries/domain/ports/agent_queries_cancel_scope.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('cancelAll invokes relay, socket, and streaming handlers', () {
    final scope = AgentQueriesCancelScope(traceId: 'trace-1');
    final relayIds = <String>[];
    final socketIds = <String>[];
    final streams = <AgentStreamingSqlCancelTarget>[];

    scope.relayCancelHandler = relayIds.addAll;
    scope.socketRpcCancelHandler = socketIds.addAll;
    scope.streamingSqlCancelHandler = streams.addAll;

    scope.trackPending('req-1');
    scope.trackStreamingSql(
      const AgentStreamingSqlCancelTarget(
        agentId: 'a1',
        streamId: 's1',
      ),
    );

    scope.cancelAll();

    expect(scope.isCancelled, isTrue);
    expect(relayIds, ['req-1']);
    expect(socketIds, ['req-1']);
    expect(streams, hasLength(1));
    expect(streams.first.streamId, 's1');
  });

  test('trackStreamingSql deduplicates by agent and stream', () {
    final scope = AgentQueriesCancelScope();
    final streams = <AgentStreamingSqlCancelTarget>[];
    scope.streamingSqlCancelHandler = streams.addAll;

    scope.trackStreamingSql(
      const AgentStreamingSqlCancelTarget(agentId: 'a', streamId: 's'),
    );
    scope.trackStreamingSql(
      const AgentStreamingSqlCancelTarget(agentId: 'a', streamId: 's'),
    );

    scope.cancelAll();
    expect(streams, hasLength(1));
  });
}
