import 'dart:ui';

import 'package:colmeia/app/theme/app_theme.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/widgets/charts/app_brazil_store_sales_map_chart.dart';
import 'package:colmeia/shared/widgets/charts/app_brazil_store_sales_map_data.dart';
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
          fantasyName: 'Casa do Mel',
          branchName: 'Casa do Mel Matriz',
          companyCode: 1,
          branchCode: 1,
          agentName: 'Agente Tangara',
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
    expect(find.text('Casa do Mel Matriz'), findsOneWidget);
    expect(find.text('Empresa 1 - Filial 1'), findsOneWidget);
    expect(find.text('Agente Tangara'), findsOneWidget);
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
          fantasyName: 'Casa do Mel Centro',
          branchName: 'Centro',
          companyCode: 1,
          branchCode: 1,
          agentName: 'Agente Tangara',
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
          fantasyName: 'Casa do Mel Jardim',
          branchName: 'Jardim',
          companyCode: 1,
          branchCode: 2,
          agentName: 'Agente Tangara',
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

    expect(find.text('Casa do Mel Centro'), findsOneWidget);
    expect(find.text('Tangara da Serra / MT'), findsOneWidget);
    expect(find.text(r'R$ 60.000,00'), findsOneWidget);
    expect(find.text('1.100 vendas'), findsOneWidget);
    expect(find.text('1 de 2'), findsWidgets);
    expect(find.text('Empresa 1 - Filial 1'), findsOneWidget);
  });

  testWidgets('hover on a single store marker shows the branch detail card', (
    tester,
  ) async {
    await _pumpHoverAnchor(
      tester,
      points: const <AppBrazilStoreSalesPoint>[
        AppBrazilStoreSalesPoint(
          id: 'store-1',
          name: 'Filial cadastro',
          fantasyName: 'Mel Sinop',
          branchName: 'Filial cadastro',
          companyCode: 7,
          branchCode: 3,
          agentName: 'Agente Norte',
          uf: 'MT',
          city: 'Sinop',
          latitude: -11.8604,
          longitude: -55.5091,
          salesAmount: 3421.77,
          salesCount: 64,
        ),
      ],
    );

    final gesture = await _hoverFirstStoreMarker(tester);
    addTearDown(gesture.removePointer);

    expect(
      find.byKey(const ValueKey<String>('brazil-store-sales-branch-card')),
      findsOneWidget,
    );
    expect(find.text('Mel Sinop'), findsOneWidget);
    expect(find.text('Sinop / MT'), findsOneWidget);
    expect(find.text(r'R$ 3.421,77'), findsOneWidget);
    expect(find.text('64 vendas'), findsOneWidget);
    expect(find.text('Empresa 7 - Filial 3'), findsOneWidget);
    expect(find.text('Agente Norte'), findsOneWidget);
  });

  testWidgets('hover card navigates between stores in the same marker', (
    tester,
  ) async {
    await _pumpHoverAnchor(
      tester,
      points: const <AppBrazilStoreSalesPoint>[
        AppBrazilStoreSalesPoint(
          id: 'store-1',
          name: 'Matriz',
          fantasyName: 'Mel Centro',
          branchName: 'Matriz',
          companyCode: 1,
          branchCode: 1,
          agentName: 'Agente MT',
          uf: 'MT',
          city: 'Sinop',
          latitude: -11.8604,
          longitude: -55.5091,
          salesAmount: 2000,
          salesCount: 20,
        ),
        AppBrazilStoreSalesPoint(
          id: 'store-2',
          name: 'Filial 2',
          fantasyName: 'Mel Norte',
          branchName: 'Filial 2',
          companyCode: 1,
          branchCode: 2,
          agentName: 'Agente MT',
          uf: 'MT',
          city: 'Sinop',
          latitude: -11.8604,
          longitude: -55.5091,
          salesAmount: 1421.77,
          salesCount: 44,
        ),
      ],
    );

    final gesture = await _hoverFirstStoreMarker(tester);
    addTearDown(gesture.removePointer);

    expect(find.text('Mel Centro'), findsOneWidget);
    expect(find.text('1 de 2'), findsWidgets);

    await tester.tap(
      find.byKey(const ValueKey<String>('brazil-store-sales-branch-card-next')),
    );
    await tester.pump();

    expect(find.text('Mel Norte'), findsOneWidget);
    expect(find.text(r'R$ 1.421,77'), findsOneWidget);
    expect(find.text('44 vendas'), findsOneWidget);
    expect(find.text('2 de 2'), findsWidgets);
  });

  testWidgets('hover card stays open when the mouse enters the overlay', (
    tester,
  ) async {
    await _pumpHoverAnchor(
      tester,
      points: const <AppBrazilStoreSalesPoint>[
        AppBrazilStoreSalesPoint(
          id: 'store-1',
          name: 'Filial cadastro',
          fantasyName: 'Mel Sinop',
          uf: 'MT',
          city: 'Sinop',
          latitude: -11.8604,
          longitude: -55.5091,
          salesAmount: 3421.77,
          salesCount: 64,
        ),
      ],
    );

    final gesture = await _hoverFirstStoreMarker(tester);
    addTearDown(gesture.removePointer);
    final cardFinder = find.byKey(
      const ValueKey<String>('brazil-store-sales-branch-card'),
    );

    await gesture.moveTo(tester.getCenter(cardFinder));
    await tester.pump(const Duration(milliseconds: 220));

    expect(cardFinder, findsOneWidget);
    expect(find.text('Mel Sinop'), findsOneWidget);
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
  String? selectedStoreId,
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

Future<TestGesture> _hoverFirstStoreMarker(WidgetTester tester) async {
  final marker = find.byKey(
    const ValueKey<String>('brazil-store-sales-test-marker'),
  );
  final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
  await gesture.addPointer();
  await tester.pump();
  await gesture.moveTo(tester.getCenter(marker));
  await tester.pump();
  return gesture;
}

Future<void> _pumpHoverAnchor(
  WidgetTester tester, {
  required List<AppBrazilStoreSalesPoint> points,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Center(
          child: AppBrazilStoreSalesBranchHoverDetailAnchor(
            group: AppBrazilStoreSalesMarkerGroup(points: points),
            metric: AppBrazilStoreSalesMapMetric.revenue,
            marker: Container(
              key: const ValueKey<String>('brazil-store-sales-test-marker'),
              width: 32,
              height: 32,
              alignment: Alignment.center,
              color: Colors.transparent,
              child: const Icon(Icons.storefront_rounded),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}
