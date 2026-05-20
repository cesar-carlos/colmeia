import 'package:colmeia/features/sales/application/sales_live_map_point_factory.dart';
import 'package:colmeia/features/sales/domain/entities/sales_live_map_point.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const factory = SalesLiveMapPointFactory();

  group('SalesLiveMapPointFactory', () {
    test('createSource preserves branch lookup payload for geolocation', () {
      final source = factory.createSource(
        id: 'agent-a|1|2',
        name: 'Filial Centro',
        salesAmount: 120.5,
        salesCount: 4,
        uf: 'MT',
        city: 'Cuiaba',
        latitude: null,
        longitude: null,
        cep: '78000000',
        ibgeMunicipalityCode: '5103403',
        fantasyName: 'Casa do Mel',
        branchName: 'Casa do Mel Centro',
        companyCode: 1,
        branchCode: 2,
        agentName: 'Agente A',
        salesDataLoading: false,
        salesDataUnavailable: false,
        salesDataStatusLabel: null,
        subtitle: 'Agente A - Empresa 1 - Filial 2',
        payload: 'aggregate',
      );

      expect(source.id, 'agent-a|1|2');
      expect(source.city, 'Cuiaba');
      expect(source.ibgeMunicipalityCode, '5103403');
      expect(source.fantasyName, 'Casa do Mel');
      expect(source.payload, 'aggregate');
    });

    test('createPoint supports zeroed unavailable branches from cache hit', () {
      final point = factory.createPoint(
        id: 'agent-a|1|2',
        name: 'Filial Centro',
        uf: 'MT',
        latitude: -15.6,
        longitude: -56.1,
        salesAmount: 0,
        salesCount: 0,
        fantasyName: 'Casa do Mel',
        branchName: 'Casa do Mel Centro',
        companyCode: 1,
        branchCode: 2,
        agentName: 'Agente A',
        salesDataLoading: false,
        salesDataUnavailable: true,
        salesDataStatusLabel: 'Vendas indisponiveis',
        locationResolution: SalesLiveMapLocationResolution.cityUf,
        subtitle: 'Agente A - Empresa 1 - Filial 2',
        payload: 'aggregate',
        municipalityCode: '5103403',
        city: 'Cuiaba',
      );

      expect(point.salesAmount, 0);
      expect(point.salesCount, 0);
      expect(point.salesDataUnavailable, isTrue);
      expect(point.salesDataStatusLabel, 'Vendas indisponiveis');
      expect(point.locationResolution, SalesLiveMapLocationResolution.cityUf);
      expect(point.city, 'Cuiaba');
    });

    test(
      'mergeAggregateOntoResolvedBase preserves geo while refreshing sales',
      () {
        const base = SalesLiveMapPoint(
          id: 'agent-a|1|2',
          name: 'Filial Centro',
          uf: 'MT',
          latitude: -15.6,
          longitude: -56.1,
          salesAmount: 10,
          salesCount: 1,
          municipalityCode: '5103403',
          city: 'Cuiaba',
          fantasyName: 'Casa do Mel',
          branchName: 'Casa do Mel Centro',
          companyCode: 1,
          branchCode: 2,
          agentName: 'Agente A',
          locationResolution: SalesLiveMapLocationResolution.cep,
          subtitle: 'Agente A - Empresa 1 - Filial 2',
          payload: 'old',
        );

        final merged = factory.mergeAggregateOntoResolvedBase(
          base: base,
          name: 'Filial Centro Atualizada',
          salesAmount: 300,
          salesCount: 9,
          fantasyName: 'Casa do Mel Prime',
          branchName: 'Casa do Mel Centro',
          companyCode: 1,
          branchCode: 2,
          agentName: 'Agente A',
          salesDataLoading: true,
          salesDataUnavailable: false,
          salesDataStatusLabel: null,
          subtitle: 'Agente A - Empresa 1 - Filial 2',
          payload: 'new',
        );

        expect(merged.latitude, base.latitude);
        expect(merged.longitude, base.longitude);
        expect(merged.locationResolution, base.locationResolution);
        expect(merged.salesAmount, 300);
        expect(merged.salesCount, 9);
        expect(merged.salesDataLoading, isTrue);
        expect(merged.name, 'Filial Centro Atualizada');
        expect(merged.fantasyName, 'Casa do Mel Prime');
        expect(merged.payload, 'new');
      },
    );
  });
}
