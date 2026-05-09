import 'package:colmeia/features/overview/domain/entities/overview_filter.dart';
import 'package:colmeia/features/sales/data/sales_preferences.dart';
import 'package:colmeia/features/sales/domain/entities/sales_live_map_filter.dart';
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
      expect(filter.mapPreset, SalesLiveMapMapPreset.standard);
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
      'persists selected agents, custom period and map preset',
      () async {
        final customRange = OverviewDateRange.fromOrderedEndpoints(
          DateTime(2026, 3),
          DateTime(2026, 4, 15),
        );

        await salesPrefs.persistSalesLiveMapFilter(
          SalesLiveMapFilter(
            selectedAgentIds: const <String>{'agent-b', 'agent-a'},
            periodMode: SalesLiveMapPeriodMode.customRange,
            customDateRange: customRange,
            mapPreset: SalesLiveMapMapPreset.bubble,
          ),
        );

        final restored = salesPrefs.restoreSalesLiveMapFilter();
        final restoredRange = restored.resolveDateRange();

        expect(restored.selectedAgentIds, <String>{'agent-a', 'agent-b'});
        expect(restored.periodMode, SalesLiveMapPeriodMode.customRange);
        expect(restored.mapPreset, SalesLiveMapMapPreset.bubble);
        expect(restoredRange.inclusiveCalendarDayCount, 31);
        expect(restoredRange.startInclusive, DateTime(2026, 3, 16));
        expect(restoredRange.endInclusive, DateTime(2026, 4, 15));
      },
    );
  });
}
