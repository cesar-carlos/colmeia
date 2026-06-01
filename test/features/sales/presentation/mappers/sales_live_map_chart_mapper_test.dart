import 'package:colmeia/features/sales/domain/entities/sales_live_map_metric.dart';
import 'package:colmeia/features/sales/domain/entities/sales_live_map_point.dart';
import 'package:colmeia/features/sales/presentation/mappers/sales_live_map_chart_mapper.dart';
import 'package:colmeia/l10n/app_localizations_pt.dart';
import 'package:colmeia/shared/widgets/charts/app_brazil_store_sales_map_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SalesLiveMapChartMapper', () {
    test('maps metrics both directions', () {
      expect(
        SalesLiveMapChartMapper.toChartMetric(SalesLiveMapMetric.revenue),
        AppBrazilStoreSalesMapMetric.revenue,
      );
      expect(
        SalesLiveMapChartMapper.toChartMetric(SalesLiveMapMetric.salesCount),
        AppBrazilStoreSalesMapMetric.salesCount,
      );
      expect(
        SalesLiveMapChartMapper.fromChartMetric(
          AppBrazilStoreSalesMapMetric.revenue,
        ),
        SalesLiveMapMetric.revenue,
      );
      expect(
        SalesLiveMapChartMapper.fromChartMetric(
          AppBrazilStoreSalesMapMetric.salesCount,
        ),
        SalesLiveMapMetric.salesCount,
      );
    });

    test('maps every point field to the shared chart model', () {
      final l10n = AppLocalizationsPt();
      const point = SalesLiveMapPoint(
        id: 'agent-a|1|2',
        name: 'Filial Centro',
        uf: 'MT',
        latitude: -15.6,
        longitude: -56.1,
        salesAmount: 450.75,
        salesCount: 12,
        municipalityCode: '5103403',
        city: 'Cuiaba',
        fantasyName: 'Casa do Mel',
        branchName: 'Casa do Mel Centro',
        companyCode: 1,
        branchCode: 2,
        agentName: 'Agente A',
        salesDataLoading: true,
        salesDataStatusLabel: 'Processando',
        locationResolution: SalesLiveMapLocationResolution.cityUf,
        payload: 'aggregate',
      );

      final mapped = SalesLiveMapChartMapper.toChartPoint(point, l10n);

      expect(mapped.id, point.id);
      expect(mapped.name, point.name);
      expect(mapped.uf, point.uf);
      expect(mapped.latitude, point.latitude);
      expect(mapped.longitude, point.longitude);
      expect(mapped.salesAmount, point.salesAmount);
      expect(mapped.salesCount, point.salesCount);
      expect(mapped.municipalityCode, point.municipalityCode);
      expect(mapped.city, point.city);
      expect(mapped.fantasyName, point.fantasyName);
      expect(mapped.branchName, point.branchName);
      expect(mapped.companyCode, point.companyCode);
      expect(mapped.branchCode, point.branchCode);
      expect(mapped.agentName, point.agentName);
      expect(mapped.salesDataLoading, point.salesDataLoading);
      expect(mapped.salesDataUnavailable, point.salesDataUnavailable);
      expect(mapped.salesDataStatusLabel, point.salesDataStatusLabel);
      expect(
        mapped.locationResolution,
        AppBrazilStoreSalesLocationResolution.cityUf,
      );
      expect(
        mapped.subtitle,
        l10n.salesLiveMapBranchPointSubtitle('Agente A', 1, 2),
      );
      expect(mapped.payload, point.payload);
    });

    test('pointsContentDigest reacts to payload-relevant field changes', () {
      const base = SalesLiveMapPoint(
        id: 'store-1',
        name: 'Filial 1',
        uf: 'MT',
        latitude: -15.6,
        longitude: -56.1,
        salesAmount: 10,
        salesCount: 1,
      );
      final changed = base.copyWith(salesAmount: 11);

      final baseDigest = SalesLiveMapChartMapper.pointsContentDigest(
        const <SalesLiveMapPoint>[base],
      );
      final changedDigest = SalesLiveMapChartMapper.pointsContentDigest(
        <SalesLiveMapPoint>[changed],
      );

      expect(changedDigest, isNot(baseDigest));
    });
  });
}
