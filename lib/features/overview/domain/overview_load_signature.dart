import 'package:colmeia/shared/filters/dashboard_filter.dart';

/// Stable cache key for overview loads: user, agent selection, period, range.
String overviewLoadSignature({
  required String userId,
  required DashboardFilter filter,
}) {
  final normalized = filter.normalizedForHomeDashboardReferenceRange();
  final ids = normalized.selectedAgentIds;
  final agentPart = ids == null
      ? '*'
      : (List<String>.from(ids)..sort()).join(',');
  final rr = normalized.referenceRange;
  final refPart = rr == null
      ? ''
      : '|r:${rr.startInclusive.year}-${rr.startInclusive.month}-${rr.startInclusive.day}'
            ':${rr.endInclusive.year}-${rr.endInclusive.month}-${rr.endInclusive.day}';
  return '$userId|$agentPart|${normalized.yearMonth ?? 'default'}$refPart';
}
