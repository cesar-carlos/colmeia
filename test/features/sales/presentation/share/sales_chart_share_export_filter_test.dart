import 'package:colmeia/features/sales/domain/entities/sales_live_map_branch_ref.dart';
import 'package:colmeia/features/sales/domain/entities/sales_live_map_filter.dart';
import 'package:colmeia/features/sales/domain/entities/sales_live_map_metric.dart';
import 'package:colmeia/features/sales/presentation/share/sales_chart_share_export_filter.dart';
import 'package:colmeia/l10n/app_localizations.dart';
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

  test('produto tendencia export header includes branch and periods', () {
    final formatted = formatChartShareExportHeaderContext(
      buildSalesProdutoTendenciaChartShareExportHeaderContext(
        l10n: l10n,
        agentName: 'Centro',
        periodoAtual: DateTimeRange(
          start: DateTime(2026, 6),
          end: DateTime(2026, 6, 30),
        ),
        periodoAnterior: DateTimeRange(
          start: DateTime(2026, 5),
          end: DateTime(2026, 5, 31),
        ),
      ),
    );

    expect(formatted, isNotNull);
    expect(formatted, contains('Centro'));
    expect(formatted, contains(l10n.salesProdutoTendenciaFilterCurrentPeriod));
    expect(
      formatted,
      contains(l10n.salesProdutoTendenciaFilterPreviousPeriod),
    );
  });

  test(
    'live map export header omits branch names when multiple are selected',
    () {
      const branches = <SalesLiveMapBranchOption>[
        SalesLiveMapBranchOption(
          id: 'b1',
          agentId: 'a1',
          agentName: 'Centro',
          codEmpresa: 1,
          codFilial: 1,
          registrationName: 'Centro',
          city: 'City',
          uf: 'SP',
        ),
        SalesLiveMapBranchOption(
          id: 'b2',
          agentId: 'a2',
          agentName: 'Norte',
          codEmpresa: 1,
          codFilial: 2,
          registrationName: 'Norte',
          city: 'City',
          uf: 'SP',
        ),
      ];

      final formatted = formatChartShareExportHeaderContext(
        buildSalesLiveMapChartShareExportHeaderContext(
          l10n: l10n,
          agentsSummary: l10n.salesLiveMapAgentsSelectedSummary(2),
          singleBranchName: resolveSalesLiveMapSingleBranchName(
            selectedBranchIds: <SalesLiveMapBranchRef>{
              const SalesLiveMapBranchRef(
                agentId: 'a1',
                codEmpresa: 1,
                codFilial: 1,
              ),
              const SalesLiveMapBranchRef(
                agentId: 'a2',
                codEmpresa: 1,
                codFilial: 2,
              ),
            },
            branchOptions: branches,
          ),
          periodSummary: l10n.salesLiveMapPeriodToday,
          detailSummary: l10n.salesLiveMapDetailBranches,
          visualSummary: l10n.salesLiveMapVisualDot,
          usesMapLabel: false,
          mapMetricLabel: salesLiveMapMetricExportLabel(
            l10n,
            SalesLiveMapMetric.revenue,
          ),
        ),
      );

      expect(formatted, isNotNull);
      expect(formatted, isNot(contains('Centro')));
      expect(formatted, isNot(contains('Norte')));
      expect(formatted, contains('2'));
    },
  );

  test(
    'live map export header includes single branch name when one is selected',
    () {
      const branches = <SalesLiveMapBranchOption>[
        SalesLiveMapBranchOption(
          id: 'b1',
          agentId: 'a1',
          agentName: 'Centro',
          codEmpresa: 1,
          codFilial: 1,
          registrationName: 'Centro',
          city: 'City',
          uf: 'SP',
        ),
      ];

      final formatted = formatChartShareExportHeaderContext(
        buildSalesLiveMapChartShareExportHeaderContext(
          l10n: l10n,
          agentsSummary: l10n.salesLiveMapAgentsSelectedSummary(1),
          singleBranchName: resolveSalesLiveMapSingleBranchName(
            selectedBranchIds: <SalesLiveMapBranchRef>{
              const SalesLiveMapBranchRef(
                agentId: 'a1',
                codEmpresa: 1,
                codFilial: 1,
              ),
            },
            branchOptions: branches,
          ),
          periodSummary: l10n.salesLiveMapPeriodToday,
          detailSummary: l10n.salesLiveMapDetailBranches,
          visualSummary: l10n.salesLiveMapVisualDot,
          usesMapLabel: false,
          mapMetricLabel: salesLiveMapMetricExportLabel(
            l10n,
            SalesLiveMapMetric.salesCount,
          ),
        ),
      );

      expect(formatted, isNotNull);
      expect(formatted, contains('Centro'));
    },
  );
}
