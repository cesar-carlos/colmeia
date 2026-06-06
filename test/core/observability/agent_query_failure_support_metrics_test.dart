import 'package:colmeia/core/observability/agent_query_failure_support_metrics.dart';
import 'package:colmeia/core/observability/socket/socket_channel_metrics.dart';
import 'package:colmeia/features/agent_queries/data/repositories/coalescing_agent_queries_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockCoalescingRepository extends Mock
    implements CoalescingAgentQueriesRepository {}

void main() {
  test('collect exposes batch, gate peak and coalesced counters', () {
    final metrics = SocketChannelMetrics()
      ..recordBatchEmission(size: 2, partialFailure: false)
      ..lastGateSessionPeakSample = 3;
    final coalescing = _MockCoalescingRepository();
    when(() => coalescing.coalescedCount).thenReturn(5);

    final lines = AgentQueryFailureSupportMetrics.collect(
      channelMetrics: metrics,
      coalescingRepository: coalescing,
    );

    expect(lines['batchEmissionsTotal'], '1');
    expect(lines['sessionPeakMaxAgentInflight'], '3');
    expect(lines['coalescedCount'], '5');
  });

  test('collectOptional uses resolver when configured', () {
    AgentQueryFailureSupportMetrics.resolver = () => <String, String>{
      'batchEmissionsTotal': '9',
    };
    addTearDown(() => AgentQueryFailureSupportMetrics.resolver = null);

    expect(
      AgentQueryFailureSupportMetrics.collectOptional()['batchEmissionsTotal'],
      '9',
    );
  });
}
