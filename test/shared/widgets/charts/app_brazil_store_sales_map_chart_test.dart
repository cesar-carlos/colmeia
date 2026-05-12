import 'package:colmeia/app/theme/app_theme.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/widgets/charts/app_brazil_store_sales_map_chart.dart';
import 'package:colmeia/shared/widgets/charts/app_brazil_store_sales_map_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders the selected store detail card content', (
    tester,
  ) async {
    await _pumpMap(
      tester,
      points: const <AppBrazilStoreSalesPoint>[
        AppBrazilStoreSalesPoint(
          id: 'store-1',
          name: 'Casa do Mel',
          uf: 'MT',
          city: 'Tangara da Serra',
          municipalityCode: '5107958',
          latitude: -14.6229,
          longitude: -57.4933,
          salesAmount: 84246.26,
          salesCount: 1568,
          locationResolution:
              AppBrazilStoreSalesLocationResolution.ibgeMunicipalityCode,
          subtitle: 'Agente Tangara - Empresa 1 - Filial 1',
        ),
      ],
      selectedStoreId: 'store-1',
    );

    expect(find.text('Casa do Mel'), findsOneWidget);
    expect(find.text('Agente Tangara - Empresa 1 - Filial 1'), findsOneWidget);
    expect(find.text(r'R$ 84.246,26'), findsOneWidget);
    expect(find.text('1.568 vendas'), findsOneWidget);
    expect(find.text('Tangara da Serra / MT'), findsOneWidget);
    expect(find.text('IBGE 5107958'), findsOneWidget);
    expect(find.text('Geolocalizacao IBGE'), findsOneWidget);
  });

  testWidgets('renders the municipality aggregate detail card content', (
    tester,
  ) async {
    await _pumpMap(
      tester,
      points: const <AppBrazilStoreSalesPoint>[
        AppBrazilStoreSalesPoint(
          id: 'store-1',
          name: 'Casa do Mel Centro',
          uf: 'MT',
          city: 'Tangara da Serra',
          municipalityCode: '5107958',
          latitude: -14.6229,
          longitude: -57.4933,
          salesAmount: 60000,
          salesCount: 1100,
        ),
        AppBrazilStoreSalesPoint(
          id: 'store-2',
          name: 'Casa do Mel Jardim',
          uf: 'MT',
          city: 'Tangara da Serra',
          municipalityCode: '5107958',
          latitude: -14.6329,
          longitude: -57.4833,
          salesAmount: 24246.26,
          salesCount: 468,
        ),
      ],
      selectedStoreId: 'store-1',
      style: _baseStyle.copyWith(
        markerAggregation: AppBrazilStoreSalesMarkerAggregation.municipalities,
      ),
    );

    expect(find.text('Tangara da Serra / MT'), findsOneWidget);
    expect(find.text('2 filiais agrupadas'), findsOneWidget);
    expect(find.text(r'R$ 84.246,26'), findsOneWidget);
    expect(find.text('1.568 vendas'), findsOneWidget);
    expect(find.text('2 filiais'), findsOneWidget);
    expect(find.text('Casa do Mel Centro'), findsOneWidget);
    expect(find.text('Casa do Mel Jardim'), findsOneWidget);
  });
}

const _baseStyle = AppBrazilStoreSalesMapStyle(
  height: 360,
  showLegend: false,
  showMetricSelector: false,
  showRegionFilter: false,
  showMarkerScaleLegend: false,
  enableZoomPan: false,
  markerVisual: AppBrazilStoreSalesMarkerVisual.storeIcon,
  selectedMarkerDetailPlacement:
      AppBrazilStoreSalesSelectedMarkerDetailPlacement.belowMap,
);

Future<void> _pumpMap(
  WidgetTester tester, {
  required List<AppBrazilStoreSalesPoint> points,
  required String selectedStoreId,
  AppBrazilStoreSalesMapStyle style = _baseStyle,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 720,
            child: AppBrazilStoreSalesMapChart(
              points: points,
              selectedStoreId: selectedStoreId,
              style: style,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
}
