import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/filters/dashboard_filter.dart';

String overviewAgentFilterSummaryLabel({
  required DashboardFilter filter,
  required List<DashboardAgentOption> availableAgents,
  required AppLocalizations l10n,
}) {
  final selectedIds = filter.selectedAgentIds;
  if (selectedIds == null ||
      selectedIds.isEmpty ||
      (availableAgents.isNotEmpty &&
          selectedIds.length >= availableAgents.length)) {
    final count = availableAgents.isEmpty ? 0 : availableAgents.length;
    return l10n.overviewAgentFilterAllAgentsSummary(count);
  }
  return l10n.overviewAgentFilterSelectedCount(selectedIds.length);
}
