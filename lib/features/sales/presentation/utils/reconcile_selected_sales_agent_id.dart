import 'package:colmeia/features/overview/domain/entities/overview_filter.dart';

/// Returns [previousSelectedId] if it appears in [agents]; otherwise null.
String? reconcileSelectedSalesAgentId({
  required List<OverviewAgentOption> agents,
  required String? previousSelectedId,
}) {
  if (previousSelectedId == null) {
    return null;
  }
  for (final a in agents) {
    if (a.agentId == previousSelectedId) {
      return previousSelectedId;
    }
  }
  return null;
}
