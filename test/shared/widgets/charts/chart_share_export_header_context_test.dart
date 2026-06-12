import 'package:colmeia/shared/widgets/charts/app_chart_filter_summary.dart';
import 'package:colmeia/shared/widgets/charts/chart_share_export_header_context.dart';
import 'package:colmeia/shared/widgets/charts/chart_share_pdf_limits.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const agents = <ChartShareAgentOption>[
    ChartShareAgentOption(agentId: 'a1', name: 'Centro'),
    ChartShareAgentOption(agentId: 'a2', name: 'Norte'),
  ];

  group('resolveChartShareSingleAgentName', () {
    test('returns name when exactly one agent is selected', () {
      expect(
        resolveChartShareSingleAgentName(
          availableAgents: agents,
          selectedAgentIds: const <String>{'a1'},
        ),
        'Centro',
      );
    });

    test('returns null for all agents', () {
      expect(
        resolveChartShareSingleAgentName(
          availableAgents: agents,
          selectedAgentIds: null,
        ),
        isNull,
      );
    });

    test('returns null for multiple agents', () {
      expect(
        resolveChartShareSingleAgentName(
          availableAgents: agents,
          selectedAgentIds: const <String>{'a1', 'a2'},
        ),
        isNull,
      );
    });
  });

  group('formatChartShareExportHeaderContext', () {
    test('includes single agent and parameters with middle dot separator', () {
      final formatted = formatChartShareExportHeaderContext(
        const ChartShareExportHeaderContext(
          singleAgentLabel: 'BRANCHES',
          singleAgentName: 'Centro',
          parameters: <ChartShareExportHeaderParameter>[
            ChartShareExportHeaderParameter(
              label: 'PERIOD',
              value: 'Jun/2026',
            ),
          ],
        ),
      );

      expect(formatted, isNotNull);
      expect(
        formatted,
        'BRANCHES: Centro${AppChartFilterSummary.spacedMiddleDotSeparator}'
        'PERIOD: Jun/2026',
      );
    });

    test('omits empty segments', () {
      expect(
        formatChartShareExportHeaderContext(
          const ChartShareExportHeaderContext(),
        ),
        isNull,
      );
    });
  });

  group('buildChartSharePdfFilterSummary', () {
    test('merges export context, extra notice, and truncation', () {
      final summary = buildChartSharePdfFilterSummary(
        exportHeaderContext: const ChartShareExportHeaderContext(
          parameters: <ChartShareExportHeaderParameter>[
            ChartShareExportHeaderParameter(label: 'PERIOD', value: 'Jun/2026'),
          ],
        ),
        additionalFilterSummary: 'Series truncated',
        truncationNotice: 'PDF table shows 10 of 20 rows.',
      );

      expect(summary, contains('PERIOD: Jun/2026'));
      expect(summary, contains('Series truncated'));
      expect(summary, contains('PDF table shows 10 of 20 rows.'));
      expect(
        joinChartShareFilterSummary(
          filterSummary: 'PERIOD: Jun/2026',
          truncationNotice: 'Series truncated',
        ),
        isNotNull,
      );
    });
  });
}
