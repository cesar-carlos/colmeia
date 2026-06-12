import 'package:colmeia/shared/widgets/charts/app_chart_filter_summary.dart';
import 'package:colmeia/shared/widgets/charts/chart_share_pdf_limits.dart';
import 'package:flutter/foundation.dart';

/// Minimal agent identity for chart export header resolution.
@immutable
class ChartShareAgentOption {
  const ChartShareAgentOption({
    required this.agentId,
    required this.name,
  });

  final String agentId;
  final String name;
}

/// One labeled value shown in a chart PDF export header.
@immutable
class ChartShareExportHeaderParameter {
  const ChartShareExportHeaderParameter({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  String format() => '${label.trim()}: ${value.trim()}';
}

/// Neutral, feature-agnostic context for chart PDF export headers.
///
/// Features build localized [parameters] and optional [singleAgentName] (only
/// when exactly one branch/agent is in scope). Multi-branch charts must not
/// populate [singleAgentName].
@immutable
class ChartShareExportHeaderContext {
  const ChartShareExportHeaderContext({
    this.parameters = const <ChartShareExportHeaderParameter>[],
    this.singleAgentLabel,
    this.singleAgentName,
  });

  final List<ChartShareExportHeaderParameter> parameters;
  final String? singleAgentLabel;
  final String? singleAgentName;
}

/// Resolves a single agent display name for export headers.
///
/// Returns non-null only when [selectedAgentIds] contains exactly one id.
String? resolveChartShareSingleAgentName({
  required Iterable<ChartShareAgentOption> availableAgents,
  required Set<String>? selectedAgentIds,
}) {
  final selected = selectedAgentIds;
  if (selected == null || selected.length != 1) {
    return null;
  }
  final agentId = selected.first;
  for (final agent in availableAgents) {
    if (agent.agentId == agentId) {
      return agent.name;
    }
  }
  return null;
}

/// Formats [context] for PDF / share headers using the shared middle-dot
/// separator between segments.
String? formatChartShareExportHeaderContext(
  ChartShareExportHeaderContext? context,
) {
  if (context == null) {
    return null;
  }

  final parts = <String>[];
  final agentLabel = context.singleAgentLabel?.trim();
  final agentName = context.singleAgentName?.trim();
  if (agentLabel != null &&
      agentLabel.isNotEmpty &&
      agentName != null &&
      agentName.isNotEmpty) {
    parts.add('$agentLabel: $agentName');
  }

  for (final parameter in context.parameters) {
    final label = parameter.label.trim();
    final value = parameter.value.trim();
    if (label.isEmpty || value.isEmpty) {
      continue;
    }
    parts.add(parameter.format());
  }

  if (parts.isEmpty) {
    return null;
  }
  return parts.join(AppChartFilterSummary.spacedMiddleDotSeparator);
}

/// Merges applied export filters with optional extra notices and table truncation.
String? buildChartSharePdfFilterSummary({
  ChartShareExportHeaderContext? exportHeaderContext,
  String? additionalFilterSummary,
  String? truncationNotice,
}) {
  final appliedFilters = formatChartShareExportHeaderContext(exportHeaderContext);
  return joinChartShareFilterSummary(
    filterSummary: joinChartShareFilterSummary(
      filterSummary: appliedFilters,
      truncationNotice: additionalFilterSummary,
    ),
    truncationNotice: truncationNotice,
  );
}
