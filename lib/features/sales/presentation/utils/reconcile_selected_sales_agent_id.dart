import 'package:colmeia/shared/filters/dashboard_filter.dart';

/// Returns [previousSelectedId] if it appears in [agents]; otherwise null.
String? reconcileSelectedSalesAgentId({
  required List<DashboardAgentOption> agents,
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
