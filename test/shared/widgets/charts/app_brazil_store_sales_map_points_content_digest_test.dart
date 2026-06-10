import 'package:colmeia/features/sales/domain/entities/sales_live_map_point.dart';
import 'package:colmeia/features/sales/presentation/mappers/sales_live_map_chart_mapper.dart';
import 'package:colmeia/shared/widgets/charts/app_brazil_store_sales_map_data.dart';
import 'package:colmeia/shared/widgets/charts/app_brazil_store_sales_map_models.dart';
import 'package:colmeia/shared/widgets/charts/app_brazil_store_sales_map_points_content_digest.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('brazilStoreSalesMapPointsContentDigest', () {
    const sharedFields = BrazilStoreSalesMapPointDigestFields(
      id: 'store-1',
      name: 'Loja Base',
      fantasyName: 'Loja Base',
      branchName: 'Matriz',
      agentName: 'Agente 1',
      uf: 'MT',
      city: 'Cuiaba',
      municipalityCode: '5103403',
      latitude: -15.6,
      longitude: -56.1,
      salesAmount: 100,
      salesCount: 1,
      salesDataLoading: false,
      salesDataUnavailable: false,
      salesDataStatusLabel: 'Disponivel',
      locationResolutionName: 'ibgeMunicipalityCode',
      subtitle: 'Empresa 1 - Filial 1',
    );

    const domainPoint = SalesLiveMapPoint(
      id: 'store-1',
      name: 'Loja Base',
      fantasyName: 'Loja Base',
      branchName: 'Matriz',
      agentName: 'Agente 1',
      uf: 'MT',
      city: 'Cuiaba',
      municipalityCode: '5103403',
      latitude: -15.6,
      longitude: -56.1,
      salesAmount: 100,
      salesCount: 1,
      salesDataStatusLabel: 'Disponivel',
      locationResolution: SalesLiveMapLocationResolution.ibgeMunicipalityCode,
      subtitle: 'Empresa 1 - Filial 1',
    );

    const chartPoint = AppBrazilStoreSalesPoint(
      id: 'store-1',
      name: 'Loja Base',
      fantasyName: 'Loja Base',
      branchName: 'Matriz',
      agentName: 'Agente 1',
      uf: 'MT',
      city: 'Cuiaba',
      municipalityCode: '5103403',
      latitude: -15.6,
      longitude: -56.1,
      salesAmount: 100,
      salesCount: 1,
      salesDataStatusLabel: 'Disponivel',
      locationResolution:
          AppBrazilStoreSalesLocationResolution.ibgeMunicipalityCode,
      subtitle: 'Empresa 1 - Filial 1',
    );

    test('domain and chart paths agree for equivalent logical data', () {
      final sharedDigest = brazilStoreSalesMapPointsContentDigest(
        const <BrazilStoreSalesMapPointDigestFields>[sharedFields],
      );
      final domainDigest = SalesLiveMapChartMapper.pointsContentDigest(
        const <SalesLiveMapPoint>[domainPoint],
      );
      final chartDigest = AppBrazilStoreSalesMapData.pointsContentDigest(
        const <AppBrazilStoreSalesPoint>[chartPoint],
      );

      expect(domainDigest, sharedDigest);
      expect(chartDigest, sharedDigest);
      expect(domainDigest, chartDigest);
    });

    test('digest changes when a payload-relevant field changes', () {
      final baseDigest = brazilStoreSalesMapPointsContentDigest(
        const <BrazilStoreSalesMapPointDigestFields>[sharedFields],
      );
      final changedDigest = brazilStoreSalesMapPointsContentDigest(
        <BrazilStoreSalesMapPointDigestFields>[
          BrazilStoreSalesMapPointDigestFields(
            id: sharedFields.id,
            name: sharedFields.name,
            fantasyName: sharedFields.fantasyName,
            branchName: sharedFields.branchName,
            agentName: sharedFields.agentName,
            uf: sharedFields.uf,
            city: sharedFields.city,
            municipalityCode: sharedFields.municipalityCode,
            latitude: sharedFields.latitude,
            longitude: sharedFields.longitude,
            salesAmount: sharedFields.salesAmount + 1,
            salesCount: sharedFields.salesCount,
            salesDataLoading: sharedFields.salesDataLoading,
            salesDataUnavailable: sharedFields.salesDataUnavailable,
            salesDataStatusLabel: sharedFields.salesDataStatusLabel,
            locationResolutionName: sharedFields.locationResolutionName,
            subtitle: sharedFields.subtitle,
          ),
        ],
      );

      expect(changedDigest, isNot(baseDigest));
    });
  });
}
