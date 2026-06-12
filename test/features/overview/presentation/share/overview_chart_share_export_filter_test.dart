import 'package:colmeia/features/overview/presentation/share/overview_chart_share_export_filter.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/filters/dashboard_filter.dart';
import 'package:colmeia/shared/widgets/charts/chart_share_export_header_context.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  late AppLocalizations l10n;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await initializeDateFormatting('en');
  });

  setUp(() {
    l10n = lookupAppLocalizations(const Locale('en'));
  });

  const agents = <DashboardAgentOption>[
    DashboardAgentOption(agentId: 'a1', name: 'Centro'),
    DashboardAgentOption(agentId: 'a2', name: 'Norte'),
  ];

  final periodStart = DateTime(2026, 6);
  final periodEnd = DateTime(2026, 6, 30);

  test('includes single agent name when one branch is selected', () {
    final formatted = formatChartShareExportHeaderContext(
      buildOverviewChartShareExportHeaderContext(
        l10n: l10n,
        filter: const DashboardFilter(
          selectedAgentIds: <String>{'a1'},
        ),
        availableAgents: agents,
        periodStart: periodStart,
        periodEnd: periodEnd,
      ),
    );

    expect(formatted, isNotNull);
    expect(formatted, contains('Centro'));
    expect(formatted, isNot(contains('Norte')));
  });

  test('weekday export header includes active metric parameter', () {
    final formatted = formatChartShareExportHeaderContext(
      overviewWeekdayChartShareExportHeaderContext(
        base: buildOverviewChartShareExportHeaderContext(
          l10n: l10n,
          filter: const DashboardFilter(
            selectedAgentIds: <String>{'a1'},
          ),
          availableAgents: agents,
          periodStart: periodStart,
          periodEnd: periodEnd,
        ),
        l10n: l10n,
        isSalesCountMetric: true,
      ),
    );

    expect(formatted, isNotNull);
    expect(formatted, contains(l10n.overviewWeekdayMetricSalesCountLabel));
    expect(
      formatted,
      isNot(contains(l10n.overviewWeekdayMetricSalesAmountLabel)),
    );
  });

  test('omits agent names when multiple branches are selected', () {
    final formatted = formatChartShareExportHeaderContext(
      buildOverviewChartShareExportHeaderContext(
        l10n: l10n,
        filter: const DashboardFilter(
          selectedAgentIds: <String>{'a1', 'a2'},
        ),
        availableAgents: agents,
        periodStart: periodStart,
        periodEnd: periodEnd,
      ),
    );

    expect(formatted, isNotNull);
    expect(formatted, isNot(contains('Centro')));
    expect(formatted, isNot(contains('Norte')));
    expect(formatted, contains('2'));
  });
}
