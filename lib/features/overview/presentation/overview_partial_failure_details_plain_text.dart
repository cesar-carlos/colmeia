import 'package:colmeia/features/overview/domain/entities/overview_agent_query_failure_detail.dart';
import 'package:colmeia/features/overview/domain/overview_failure_referenced_agent_id.dart';
import 'package:colmeia/features/overview/presentation/overview_agent_query_failure_detail_l10n.dart';
import 'package:colmeia/l10n/app_localizations.dart';

/// Plain-text diagnostic for partial agent failures (clipboard / logs).
String formatOverviewPartialFailureDetailsPlainText({
  required List<OverviewAgentQueryFailureDetail> details,
  required AppLocalizations l10n,
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
      ..writeln('$userLineLabel: ${d.userMessageFor(l10n)}');
    final referencedBridgeId = overviewFailureReferencedAgentId(
      detailAgentId: d.agentId,
      failure: d.failure,
    );
    if (referencedBridgeId != null) {
      b.writeln(
        'bridgeIdNote: technical detail mentions bridge id $referencedBridgeId; '
        'row branch id ${d.agentId}',
      );
    }
    final tech = d.technicalSummary?.trim();
    if (tech != null && tech.isNotEmpty) {
      b.writeln('$technicalLineLabel: $tech');
    }
  }
  return b.toString();
}
