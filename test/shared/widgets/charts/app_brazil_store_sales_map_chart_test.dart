import 'dart:ui';

import 'package:colmeia/app/theme/app_theme.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_colors.dart';
import 'package:colmeia/shared/widgets/charts/app_brazil_store_sales_map_chart.dart';
import 'package:colmeia/shared/widgets/charts/app_brazil_store_sales_map_data.dart';
import 'package:colmeia/shared/widgets/charts/app_brazil_store_sales_map_models.dart';
import 'package:colmeia/shared/widgets/charts/app_region_map_chart.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    expect(find.text('Empresa 1 - Filial 1'), findsNothing);
    expect(find.text('Agente Tangara'), findsOneWidget);
    expect(find.text(r'R$ 84.246,26'), findsOneWidget);
    expect(find.text('1.568 vendas'), findsOneWidget);
    expect(find.text('Tangara da Serra / MT'), findsOneWidget);
    expect(find.text('IBGE 5107958'), findsOneWidget);
    expect(find.text('Geolocalizacao IBGE'), findsOneWidget);
  });

  testWidgets('uses custom marker detail on Windows without native tooltip', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    try {
      await _pumpMap(
        tester,
        points: const <AppBrazilStoreSalesPoint>[
          AppBrazilStoreSalesPoint(
            id: 'store-1',
            name: 'Casa do Mel',
            fantasyName: 'Casa do Mel',
            uf: 'MT',
            city: 'Tangara da Serra',
            latitude: -14.6229,
            longitude: -57.4933,
            salesAmount: 84246.26,
            salesCount: 1568,
          ),
        ],
        selectedStoreId: 'store-1',
      );

      expect(find.text('Casa do Mel'), findsOneWidget);
      final regionMap = tester
          .widget<AppRegionMapChart<AppBrazilStoreSalesStateBucket>>(
            find
                .byWidgetPredicate(
                  (widget) =>
                      widget
                          is AppRegionMapChart<AppBrazilStoreSalesStateBucket>,
                )
                .first,
          );
      expect(regionMap.onPointTap, isNotNull);
      expect(regionMap.markerTooltipBuilder, isNull);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets(
    'selected marker detail anchor shows a persistent floating card',
    (
      tester,
    ) async {
      await _pumpSelectedAnchor(
        tester,
        points: const <AppBrazilStoreSalesPoint>[
          AppBrazilStoreSalesPoint(
            id: 'store-1',
            name: 'Casa do Mel',
            fantasyName: 'Casa do Mel',
            uf: 'MT',
            city: 'Tangara da Serra',
            latitude: -14.6229,
            longitude: -57.4933,
            salesAmount: 84246.26,
            salesCount: 1568,
          ),
        ],
      );

      expect(
        find.byKey(const ValueKey<String>('brazil-store-sales-branch-card')),
        findsOneWidget,
      );
      expect(find.text('Casa do Mel'), findsOneWidget);
      expect(find.text('Fixar filial'), findsOneWidget);
    },
  );

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
      selectedStoreId: 'store-2',
      style: _baseStyle.copyWith(
        markerAggregation: AppBrazilStoreSalesMarkerAggregation.municipalities,
      ),
    );

    expect(find.text('Casa do Mel Jardim'), findsOneWidget);
    expect(find.text('Tangara da Serra / MT'), findsOneWidget);
    expect(find.text(r'R$ 24.246,26'), findsOneWidget);
    expect(find.text('468 vendas'), findsOneWidget);
    expect(find.text('1 de 2'), findsWidgets);
    expect(find.text('Total do ponto'), findsOneWidget);
    expect(find.text(r'R$ 84.246,26'), findsOneWidget);
    expect(find.text('1.568 vendas'), findsOneWidget);
    expect(find.text('Empresa 1 - Filial 2'), findsNothing);
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
    expect(find.text('Empresa 7 - Filial 3'), findsNothing);
    expect(find.text('Agente Norte'), findsOneWidget);
  });

  testWidgets('hover card shows unavailable sales status', (
    tester,
  ) async {
    await _pumpHoverAnchor(
      tester,
      points: const <AppBrazilStoreSalesPoint>[
        AppBrazilStoreSalesPoint(
          id: 'store-1',
          name: 'Filial sem venda disponivel',
          fantasyName: 'Mel Sinop',
          uf: 'MT',
          city: 'Sinop',
          latitude: -11.8604,
          longitude: -55.5091,
          salesAmount: 0,
          salesCount: 0,
          salesDataUnavailable: true,
          salesDataStatusLabel: 'Vendas indisponiveis',
        ),
      ],
    );

    final gesture = await _hoverFirstStoreMarker(tester);
    addTearDown(gesture.removePointer);

    expect(find.text('Mel Sinop'), findsOneWidget);
    expect(find.text('0 vendas'), findsOneWidget);
    expect(find.text('Vendas indisponiveis'), findsOneWidget);
  });

  testWidgets('hover card hides zero values while sales are loading', (
    tester,
  ) async {
    await _pumpHoverAnchor(
      tester,
      points: const <AppBrazilStoreSalesPoint>[
        AppBrazilStoreSalesPoint(
          id: 'store-1',
          name: 'Filial carregando',
          fantasyName: 'Mel Sinop',
          uf: 'MT',
          city: 'Sinop',
          latitude: -11.8604,
          longitude: -55.5091,
          salesAmount: 0,
          salesCount: 0,
          salesDataLoading: true,
        ),
      ],
    );

    final gesture = await _hoverFirstStoreMarker(tester);
    addTearDown(gesture.removePointer);

    expect(find.text('Mel Sinop'), findsOneWidget);
    expect(find.text('Carregando vendas'), findsOneWidget);
    expect(find.text(r'R$ 0,00'), findsNothing);
    expect(find.text('0 vendas'), findsNothing);
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

  testWidgets('hover card action pins the current branch', (tester) async {
    String? pinnedStoreId;
    await _pumpHoverAnchor(
      tester,
      points: const <AppBrazilStoreSalesPoint>[
        AppBrazilStoreSalesPoint(
          id: 'store-1',
          name: 'Matriz',
          fantasyName: 'Mel Centro',
          uf: 'MT',
          city: 'Sinop',
          latitude: -11.8604,
          longitude: -55.5091,
          salesAmount: 2000,
          salesCount: 20,
        ),
      ],
      onPinBranch: (point) {
        pinnedStoreId = point.id;
      },
    );

    final gesture = await _hoverFirstStoreMarker(tester);
    addTearDown(gesture.removePointer);

    await tester.tap(find.text('Fixar filial'));
    await tester.pump();

    expect(pinnedStoreId, 'store-1');
  });

  testWidgets('hover card can expose a fixed branch toggle label', (
    tester,
  ) async {
    String? filteredStoreId;
    await _pumpHoverAnchor(
      tester,
      points: const <AppBrazilStoreSalesPoint>[
        AppBrazilStoreSalesPoint(
          id: 'store-1',
          name: 'Matriz',
          fantasyName: 'Mel Centro',
          uf: 'MT',
          city: 'Sinop',
          latitude: -11.8604,
          longitude: -55.5091,
          salesAmount: 2000,
          salesCount: 20,
        ),
      ],
      onPinBranch: (point) {
        filteredStoreId = point.id;
      },
      pinBranchLabelBuilder: (_) => 'Desfixar filial',
    );

    final gesture = await _hoverFirstStoreMarker(tester);
    addTearDown(gesture.removePointer);

    expect(find.text('Desfixar filial'), findsOneWidget);

    await tester.tap(find.text('Desfixar filial'));
    await tester.pump();

    expect(filteredStoreId, 'store-1');
    expect(
      find.byKey(const ValueKey<String>('brazil-store-sales-branch-card')),
      findsOneWidget,
    );
  });

  testWidgets('hover card shows branch picker for many stores', (tester) async {
    await _pumpHoverAnchor(
      tester,
      points: List<AppBrazilStoreSalesPoint>.generate(
        10,
        (index) => AppBrazilStoreSalesPoint(
          id: 'store-${index + 1}',
          name: 'Loja ${index + 1}',
          fantasyName: 'Loja ${index + 1}',
          uf: 'MT',
          city: 'Sinop',
          latitude: -11.8604,
          longitude: -55.5091,
          salesAmount: (index + 1).toDouble(),
          salesCount: index + 1,
        ),
      ),
    );

    final gesture = await _hoverFirstStoreMarker(tester);
    addTearDown(gesture.removePointer);

    expect(find.text('Loja 10'), findsOneWidget);
    await tester.tap(
      find.byKey(
        const ValueKey<String>('brazil-store-sales-branch-card-picker'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('10. Loja 1'), findsOneWidget);
  });

  testWidgets('hover card height is constrained and scrollable', (
    tester,
  ) async {
    await _pumpHoverAnchor(
      tester,
      points: List<AppBrazilStoreSalesPoint>.generate(
        12,
        (index) => AppBrazilStoreSalesPoint(
          id: 'store-${index + 1}',
          name: 'Loja ${index + 1}',
          fantasyName: 'Loja ${index + 1}',
          branchName: 'Cadastro ${index + 1}',
          companyCode: 1,
          branchCode: index + 1,
          agentName: 'Agente $index',
          uf: 'MT',
          city: 'Sinop',
          municipalityCode: '5107909',
          latitude: -11.8604,
          longitude: -55.5091,
          salesAmount: (index + 1) * 1000,
          salesCount: index + 1,
          locationResolution:
              AppBrazilStoreSalesLocationResolution.ibgeMunicipalityCode,
        ),
      ),
    );

    final gesture = await _hoverFirstStoreMarker(tester);
    addTearDown(gesture.removePointer);
    final card = find.byKey(
      const ValueKey<String>('brazil-store-sales-branch-card'),
    );

    expect(tester.getSize(card).height, lessThanOrEqualTo(460));
    expect(
      find.byKey(
        const ValueKey<String>('brazil-store-sales-branch-card-scroll'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('hover card supports keyboard navigation and escape', (
    tester,
  ) async {
    await _pumpHoverAnchor(
      tester,
      points: const <AppBrazilStoreSalesPoint>[
        AppBrazilStoreSalesPoint(
          id: 'store-1',
          name: 'Matriz',
          fantasyName: 'Mel Centro',
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

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    expect(find.text('Mel Norte'), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();
    expect(
      find.byKey(const ValueKey<String>('brazil-store-sales-branch-card')),
      findsNothing,
    );
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

  testWidgets('fits compact bounded layout when marker legend wraps', (
    tester,
  ) async {
    await _pumpMap(
      tester,
      width: 321,
      height: 617,
      style: const AppBrazilStoreSalesMapStyle(
        height: 600,
        showLegend: false,
        showStoreDetail: false,
        markerVisual: AppBrazilStoreSalesMarkerVisual.storeIcon,
        markerMinSize: 24,
        markerMaxSize: 34,
      ),
      points: const <AppBrazilStoreSalesPoint>[
        AppBrazilStoreSalesPoint(
          id: 'store-1',
          name: 'Casa do Mel',
          uf: 'MT',
          city: 'Tangara da Serra',
          latitude: -14.6229,
          longitude: -57.4933,
          salesAmount: 84246.26,
          salesCount: 1568,
        ),
        AppBrazilStoreSalesPoint(
          id: 'store-2',
          name: 'Mel Sinop',
          uf: 'MT',
          city: 'Sinop',
          latitude: -11.8604,
          longitude: -55.5091,
          salesAmount: 3421.77,
          salesCount: 64,
        ),
      ],
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Legenda'), findsOneWidget);
    expect(find.text('Marker size'), findsNothing);

    await tester.tap(find.text('Legenda'));
    await tester.pumpAndSettle();

    expect(find.text('Marker size'), findsOneWidget);
  });

  testWidgets('fits common mobile map widths without layout overflow', (
    tester,
  ) async {
    const widths = <double>[320, 360, 390];

    for (final width in widths) {
      await _pumpMap(
        tester,
        width: width,
        height: 617,
        style: const AppBrazilStoreSalesMapStyle(
          height: 600,
          showLegend: false,
          showStoreDetail: false,
          markerVisual: AppBrazilStoreSalesMarkerVisual.storeIcon,
          markerMinSize: 24,
          markerMaxSize: 34,
        ),
        points: const <AppBrazilStoreSalesPoint>[
          AppBrazilStoreSalesPoint(
            id: 'store-1',
            name: 'Casa do Mel',
            uf: 'MT',
            city: 'Tangara da Serra',
            latitude: -14.6229,
            longitude: -57.4933,
            salesAmount: 84246.26,
            salesCount: 1568,
          ),
          AppBrazilStoreSalesPoint(
            id: 'store-2',
            name: 'Mel Sinop',
            uf: 'MT',
            city: 'Sinop',
            latitude: -11.8604,
            longitude: -55.5091,
            salesAmount: 3421.77,
            salesCount: 64,
          ),
        ],
      );

      expect(
        tester.takeException(),
        isNull,
        reason: 'width $width should not overflow',
      );
      expect(find.text('Legenda'), findsOneWidget);
    }
  });

  testWidgets('wraps full state labels and uses compact type on mobile', (
    tester,
  ) async {
    await _pumpMap(
      tester,
      width: 360,
      height: 617,
      style: const AppBrazilStoreSalesMapStyle(
        height: 600,
        showLegend: false,
        showStoreDetail: false,
        showRegionFilter: false,
        showMarkerScaleLegend: false,
        stateLabelMode: AppBrazilStoreSalesStateLabelMode.stateName,
      ),
      points: const <AppBrazilStoreSalesPoint>[],
    );

    final regionMap = tester
        .widget<AppRegionMapChart<AppBrazilStoreSalesStateBucket>>(
          find
              .byWidgetPredicate(
                (widget) =>
                    widget is AppRegionMapChart<AppBrazilStoreSalesStateBucket>,
              )
              .first,
        );
    final wrappedLabel = regionMap.regionLabelBuilder(
      const AppBrazilStoreSalesStateBucket(
        uf: 'MS',
        stateName: 'Mato Grosso do Sul',
        regionKey: 'CO',
        regionName: 'Centro-Oeste',
        salesAmount: 0,
        salesCount: 0,
        storeCount: 0,
      ),
    );

    expect(wrappedLabel, 'Mato Grosso\ndo Sul');
    expect(regionMap.style.dataLabelTextStyle?.fontSize, 7);
  });

  testWidgets('state tooltip includes full state name and UF', (tester) async {
    await _pumpMap(
      tester,
      style: const AppBrazilStoreSalesMapStyle(
        showLegend: false,
        showStoreDetail: false,
        showRegionFilter: false,
        showMarkerScaleLegend: false,
        stateLabelMode: AppBrazilStoreSalesStateLabelMode.stateName,
      ),
      points: const <AppBrazilStoreSalesPoint>[],
    );

    final regionMap = tester
        .widget<AppRegionMapChart<AppBrazilStoreSalesStateBucket>>(
          find
              .byWidgetPredicate(
                (widget) =>
                    widget is AppRegionMapChart<AppBrazilStoreSalesStateBucket>,
              )
              .first,
        );
    final tooltip = regionMap.metrics.first.tooltipBuilder!(
      const AppBrazilStoreSalesStateBucket(
        uf: 'MT',
        stateName: 'Mato Grosso',
        regionKey: 'CO',
        regionName: 'Centro-Oeste',
        salesAmount: 1200,
        salesCount: 12,
        storeCount: 1,
      ),
    );

    expect(tooltip, contains('Mato Grosso (MT)'));
    expect(tooltip, contains('12 vendas'));
  });

  testWidgets('pending sales markers use a distinct loading color', (
    tester,
  ) async {
    await _pumpMap(
      tester,
      style: const AppBrazilStoreSalesMapStyle(
        showLegend: false,
        showStoreDetail: false,
        showRegionFilter: false,
        showMarkerScaleLegend: false,
      ),
      points: const <AppBrazilStoreSalesPoint>[
        AppBrazilStoreSalesPoint(
          id: 'store-1',
          name: 'Casa do Mel',
          uf: 'MT',
          city: 'Tangara da Serra',
          latitude: -14.6229,
          longitude: -57.4933,
          salesAmount: 0,
          salesCount: 0,
          salesDataLoading: true,
        ),
      ],
    );

    final regionMap = tester
        .widget<AppRegionMapChart<AppBrazilStoreSalesStateBucket>>(
          find
              .byWidgetPredicate(
                (widget) =>
                    widget is AppRegionMapChart<AppBrazilStoreSalesStateBucket>,
              )
              .first,
        );

    expect(regionMap.points.single.style?.color, AppColors.light.secondary);
    expect(regionMap.points.single.style?.strokeWidth, 2.4);
  });

  testWidgets(
    'does not re-emit diagnostics when points list is recreated with same data',
    (tester) async {
      var diagnosticsEmissions = 0;
      const point = AppBrazilStoreSalesPoint(
        id: 'store-1',
        name: 'Casa do Mel',
        fantasyName: 'Casa do Mel',
        uf: 'MT',
        city: 'Tangara da Serra',
        municipalityCode: '5107958',
        latitude: -14.6229,
        longitude: -57.4933,
        salesAmount: 84246.26,
        salesCount: 1568,
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return Column(
                  children: [
                    TextButton(
                      onPressed: () => setState(() {}),
                      child: const Text('rebuild'),
                    ),
                    SizedBox(
                      width: 720,
                      height: 400,
                      child: AppBrazilStoreSalesMapChart(
                        // New list instance each rebuild to exercise snapshot reuse.
                        // ignore: prefer_const_literals_to_create_immutables
                        points: <AppBrazilStoreSalesPoint>[point],
                        style: _baseStyle,
                        onDiagnosticsChanged: (_) {
                          diagnosticsEmissions += 1;
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
      expect(diagnosticsEmissions, greaterThan(0));
      final afterFirst = diagnosticsEmissions;

      await tester.tap(find.text('rebuild'));
      await tester.pump();
      await tester.pump();

      expect(diagnosticsEmissions, afterFirst);
    },
  );

  testWidgets(
    'filterBranchIds stays stable while selectedStoreId toggles map pin',
    (tester) async {
      const point = AppBrazilStoreSalesPoint(
        id: 'store-1',
        name: 'Casa do Mel',
        fantasyName: 'Casa do Mel',
        uf: 'MT',
        city: 'Tangara da Serra',
        latitude: -14.6229,
        longitude: -57.4933,
        salesAmount: 84246.26,
        salesCount: 1568,
      );
      const event = AppBrazilStoreSalesPointTapEvent(
        point: point,
        index: 0,
        metric: AppBrazilStoreSalesMapMetric.revenue,
      );
      final mapPin = ValueNotifier<String?>(null);
      addTearDown(mapPin.dispose);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: ValueListenableBuilder<String?>(
              valueListenable: mapPin,
              builder: (context, pin, _) {
                return Center(
                  child: SizedBox(
                    width: 720,
                    height: 560,
                    child: AppBrazilStoreSalesMapChart(
                      points: const <AppBrazilStoreSalesPoint>[point],
                      selectedStoreId: pin,
                      filterBranchIds: const <String>{'store-1'},
                      fixedBranchIds: const <String>{'store-1'},
                      style: _baseStyle,
                      onBranchFilter: (_) {
                        mapPin.value = mapPin.value == 'store-1'
                            ? null
                            : 'store-1';
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      var chart = tester.widget<AppBrazilStoreSalesMapChart>(
        find.byType(AppBrazilStoreSalesMapChart),
      );
      expect(chart.filterBranchIds, <String>{'store-1'});
      expect(chart.fixedBranchIds, <String>{'store-1'});
      expect(chart.selectedStoreId, isNull);

      chart.onBranchFilter!(event);
      await tester.pump();

      chart = tester.widget(find.byType(AppBrazilStoreSalesMapChart));
      expect(chart.filterBranchIds, <String>{'store-1'});
      expect(chart.fixedBranchIds, <String>{'store-1'});
      expect(chart.selectedStoreId, 'store-1');

      chart.onBranchFilter!(event);
      await tester.pump();

      chart = tester.widget(find.byType(AppBrazilStoreSalesMapChart));
      expect(chart.filterBranchIds, <String>{'store-1'});
      expect(chart.fixedBranchIds, <String>{'store-1'});
      expect(chart.selectedStoreId, isNull);
    },
  );
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
  double width = 720,
  double? height,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: width,
            height: height,
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
  ValueChanged<AppBrazilStoreSalesPoint>? onPinBranch,
  String? pinBranchLabel,
  String Function(AppBrazilStoreSalesPoint)? pinBranchLabelBuilder,
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
            onPinBranch: onPinBranch,
            pinBranchLabel: pinBranchLabel,
            pinBranchLabelBuilder: pinBranchLabelBuilder,
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

Future<void> _pumpSelectedAnchor(
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
          child: AppBrazilStoreSalesSelectedMarkerDetailAnchor(
            group: AppBrazilStoreSalesMarkerGroup(points: points),
            selectedStoreId: points.first.id,
            metric: AppBrazilStoreSalesMapMetric.revenue,
            onClose: () {},
            onSelectBranch: (_) {},
            selectBranchLabelBuilder: (_) => 'Fixar filial',
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
  await tester.pump();
}
