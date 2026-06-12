import 'package:colmeia/features/overview/domain/entities/overview.dart';
import 'package:colmeia/features/overview/domain/entities/overview_agent_query_failure_detail.dart';

bool overviewHasPartialFailuresForSource(
  Overview overview,
  OverviewAgentQueryFailureSource source,
) {
  return overview.partialQueryFailureDetails.any((d) => d.source == source);
}
