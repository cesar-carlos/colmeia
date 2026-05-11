import 'dart:convert';

import 'package:colmeia/features/overview/domain/entities/overview_filter.dart';
import 'package:colmeia/features/sales/data/sales_preferences.dart';
import 'package:colmeia/features/sales/domain/entities/sales_live_map_filter.dart';
import 'package:colmeia/shared/widgets/charts/app_brazil_store_sales_map_models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SalesPreferences sales live map filter', () {
    late SharedPreferences prefs;
    late SalesPreferences salesPrefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      prefs = await SharedPreferences.getInstance();
      salesPrefs = SalesPreferences(prefs);
    });

    test('restore returns today defaults without selected agents', () {
      final filter = salesPrefs.restoreSalesLiveMapFilter();
      final range = filter.resolveDateRange(now: DateTime(2026, 5, 9, 10));

      expect(filter.selectedAgentIds, isNull);
      expect(filter.periodMode, SalesLiveMapPeriodMode.today);
      expect(filter.selectedBranchIds, isNull);
      expect(filter.detailLevel, SalesLiveMapMapDetail.branches);
      expect(filter.markerVisual, SalesLiveMapMarkerVisual.dot);
      expect(filter.metric, AppBrazilStoreSalesMapMetric.revenue);
      expect(range.startInclusive, DateTime(2026, 5, 9));
      expect(range.endInclusive, DateTime(2026, 5, 9));

      final queryFilter = filter.toAgentQueryFilter(
        now: DateTime(2026, 5, 9, 10),
      );
      expect(queryFilter.origem, kSalesLiveMapDefaultOrigem);
      expect(queryFilter.geraFinanceiro, kSalesLiveMapDefaultGeraFinanceiro);
      expect(queryFilter.preVenda, kSalesLiveMapDefaultPreVenda);
    });

    test(
      'persists selected branches, custom period, detail, visual and metric',
      () async {
        final customRange = OverviewDateRange.fromOrderedEndpoints(
          DateTime(2026, 3),
          DateTime(2026, 4, 15),
        );

        await salesPrefs.persistSalesLiveMapFilter(
          SalesLiveMapFilter(
            selectedAgentIds: const <String>{'agent-b', 'agent-a'},
            selectedBranchIds: const <String>{
              'agent-a-1-1',
              'agent-b-1-2',
            },
            periodMode: SalesLiveMapPeriodMode.customRange,
            customDateRange: customRange,
            detailLevel: SalesLiveMapMapDetail.municipalities,
            markerVisual: SalesLiveMapMarkerVisual.bubble,
            metric: AppBrazilStoreSalesMapMetric.salesCount,
          ),
        );

        final restored = salesPrefs.restoreSalesLiveMapFilter();
        final restoredRange = restored.resolveDateRange();

        expect(restored.selectedAgentIds, <String>{'agent-a', 'agent-b'});
        expect(restored.selectedBranchIds, <String>{
          'agent-a-1-1',
          'agent-b-1-2',
        });
        expect(restored.periodMode, SalesLiveMapPeriodMode.customRange);
        expect(restored.detailLevel, SalesLiveMapMapDetail.municipalities);
        expect(restored.markerVisual, SalesLiveMapMarkerVisual.bubble);
        expect(restored.metric, AppBrazilStoreSalesMapMetric.salesCount);
        expect(restoredRange.inclusiveCalendarDayCount, 31);
        expect(restoredRange.startInclusive, DateTime(2026, 3, 16));
        expect(restoredRange.endInclusive, DateTime(2026, 4, 15));
      },
    );

    test('restores legacy map preset into detail and marker visual', () async {
      await prefs.setString(
        'colmeia_sales_card.${SalesPreferences.salesLiveMapCardId}.filters',
        jsonEncode(<String, Object?>{
          'map_preset': SalesLiveMapMapPreset.stateBubbles.name,
        }),
      );

      final restored = salesPrefs.restoreSalesLiveMapFilter();

      expect(restored.detailLevel, SalesLiveMapMapDetail.states);
      expect(restored.markerVisual, SalesLiveMapMarkerVisual.bubble);
    });
  });
}
