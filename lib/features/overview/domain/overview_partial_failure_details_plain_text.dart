import 'package:colmeia/features/overview/domain/entities/overview_agent_query_failure_detail.dart';

/// Plain-text diagnostic for partial agent failures (clipboard / logs).
///
/// [sourceLabel] and line labels are injected so this stays free of UI/l10n
/// imports and is easy to unit test.
String formatOverviewPartialFailureDetailsPlainText({
  required List<OverviewAgentQueryFailureDetail> details,
  required String emptyMessage,
  required String Function(OverviewAgentQueryFailureSource) sourceLabel,
  required String userLineLabel,
  required String technicalLineLabel,
}) {
  if (details.isEmpty) {
    return emptyMessage;
  }
  final b = StringBuffer();
  for (var i = 0; i < details.length; i++) {
    final d = details[i];
    if (i > 0) {
      b
        ..writeln()
        ..writeln('---')
        ..writeln();
    }
    b
      ..writeln('${d.displayName} (${d.agentId})')
      ..writeln(sourceLabel(d.source))
      ..writeln('$userLineLabel: ${d.userMessage}');
    final tech = d.technicalSummary?.trim();
    if (tech != null && tech.isNotEmpty) {
      b.writeln('$technicalLineLabel: $tech');
    }
  }
  return b.toString();
}
