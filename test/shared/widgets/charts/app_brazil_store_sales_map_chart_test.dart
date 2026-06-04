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

import '../../../support/widget_test_l10n.dart';

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

    expect(find.text('Casa do Mel Matriz'), findsOneWidget);
    expect(find.text('Casa do Mel'), findsOneWidget);
    expect(find.text('Empresa 1 - Filial 1'), findsNothing);
    expect(find.text('Filial Tangara'), findsOneWidget);
    expect(find.text(r'R$ 84.246,26'), findsOneWidget);
    final l10n = localizedFromWidget<AppBrazilStoreSalesMapChart>(tester);
    expect(
      find.text(l10n.brazilStoreSalesMapDetailChipSales('1.568')),
      findsOneWidget,
    );
    expect(find.text('Tangara da Serra / MT'), findsOneWidget);
    expect(
      find.text(l10n.brazilStoreSalesMapIbgeCodeLabel('5107958')),
      findsOneWidget,
    );
    expect(find.text(l10n.brazilStoreSalesMapLocationIbge), findsOneWidget);
  });

  testWidgets(
    'shows a desktop sidebar list in fullscreen mode and selects a branch on tap',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await _pumpMap(
        tester,
        width: 1400,
        height: 780,
        showDesktopBranchSidebar: true,
        style: _baseStyle.copyWith(showRegionFilter: true),
        points: const <AppBrazilStoreSalesPoint>[
          AppBrazilStoreSalesPoint(
            id: 'store-1',
            name: 'Filial Cuiaba',
            fantasyName: 'Mel Cuiaba',
            uf: 'MT',
            city: 'Cuiaba',
            latitude: -15.60,
            longitude: -56.10,
            salesAmount: 4200,
            salesCount: 42,
          ),
          AppBrazilStoreSalesPoint(
            id: 'store-2',
            name: 'Filial Sao Paulo',
            fantasyName: 'Mel Sao Paulo',
            uf: 'SP',
            city: 'Sao Paulo',
            latitude: -23.55,
            longitude: -46.63,
            salesAmount: 9800,
            salesCount: 98,
          ),
        ],
      );

      expect(
        find.byKey(const ValueKey<String>('brazil-store-sales-map-sidebar')),
        findsOneWidget,
      );
      expect(
        find.byKey(
          const ValueKey<String>('brazil-store-sales-map-sidebar-floating'),
        ),
        findsOneWidget,
      );
      final l10n = localizedFromWidget<AppBrazilStoreSalesMapChart>(tester);
      expect(find.text(l10n.brazilStoreSalesMapSidebarTitle), findsOneWidget);
      expect(
        find.text(l10n.brazilStoreSalesMapSidebarSummary(2, r'R$ 14.000,00')),
        findsOneWidget,
      );
      expect(find.text('Filial Sao Paulo'), findsOneWidget);
      expect(find.text('Filial Cuiaba'), findsOneWidget);
      expect(find.text('Mel Sao Paulo'), findsOneWidget);
      expect(find.text('Mel Cuiaba'), findsOneWidget);
      expect(find.text('Sao Paulo / SP'), findsOneWidget);
      expect(find.text('Cuiaba / MT'), findsOneWidget);
      expect(find.text(r'R$ 9.800,00'), findsOneWidget);
      expect(find.text(r'R$ 4.200,00'), findsOneWidget);

      final saoPauloTop = tester.getTopLeft(find.text('Filial Sao Paulo')).dy;
      final cuiabaTop = tester.getTopLeft(find.text('Filial Cuiaba')).dy;
      expect(saoPauloTop, lessThan(cuiabaTop));
      final sidebarRect = tester.getRect(
        find.byKey(
          const ValueKey<String>('brazil-store-sales-map-sidebar-floating'),
        ),
      );
      final regionMapRect = tester.getRect(
        find
            .byWidgetPredicate(
              (widget) =>
                  widget is AppRegionMapChart<AppBrazilStoreSalesStateBucket>,
            )
            .first,
      );
      expect(sidebarRect.left, greaterThanOrEqualTo(regionMapRect.left));
      expect(sidebarRect.top, greaterThan(regionMapRect.top));
      expect(sidebarRect.right, lessThan(regionMapRect.right));
      expect(sidebarRect.bottom, lessThan(regionMapRect.bottom));
      expect(sidebarRect.height, lessThan(regionMapRect.height * 0.92));

      final cuiabaItem = find.byKey(
        const ValueKey<String>(
          'brazil-store-sales-map-sidebar-item-store-1',
        ),
      );
      await tester.tap(cuiabaItem);
      await tester.pump();
      await tester.pump();

      expect(
        find.byKey(
          const ValueKey<String>('brazil-store-sales-map-store-detail'),
        ),
        findsOneWidget,
      );
      expect(find.text('Filial Cuiaba'), findsWidgets);
      final selectedCard = find.descendant(
        of: cuiabaItem,
        matching: find.byType(DecoratedBox),
      );
      final selectedDecoration =
          tester.widget<DecoratedBox>(selectedCard.first).decoration
              as BoxDecoration;
      expect(selectedDecoration.border, isA<Border>());
      expect((selectedDecoration.border! as Border).top.width, 1.8);
    },
  );

  testWidgets(
    'bounded height leaves no gap below store detail when selection is below map',
    (tester) async {
      const viewportHeight = 780.0;
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await _pumpMap(
        tester,
        width: 1400,
        height: viewportHeight,
        showDesktopBranchSidebar: true,
        style: _baseStyle.copyWith(showStoreDetail: true),
        points: const <AppBrazilStoreSalesPoint>[
          AppBrazilStoreSalesPoint(
            id: 'store-1',
            name: 'Casa do Mel Barra do Garcas',
            fantasyName: 'Casa do Mel',
            uf: 'MT',
            city: 'Barra do Garcas',
            latitude: -15.8908,
            longitude: -52.2569,
            salesAmount: 12500,
            salesCount: 210,
          ),
        ],
      );

      await tester.tap(
        find.byKey(
          const ValueKey<String>(
            'brazil-store-sales-map-sidebar-item-store-1',
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      final storeDetail = find.byKey(
        const ValueKey<String>('brazil-store-sales-map-store-detail'),
      );
      expect(storeDetail, findsOneWidget);

      final contentRect = tester.getRect(
        find.byKey(const ValueKey<String>('brazil-store-sales-map-content')),
      );
      final detailRect = tester.getRect(storeDetail);
      expect(contentRect.bottom - detailRect.bottom, lessThan(8));
    },
  );

  testWidgets(
    'bounded height leaves no gap below UF state detail',
    (tester) async {
      const viewportHeight = 780.0;
      await _pumpMap(
        tester,
        height: viewportHeight,
        style: _baseStyle.copyWith(showStoreDetail: true),
        points: const <AppBrazilStoreSalesPoint>[
          AppBrazilStoreSalesPoint(
            id: 'store-1',
            name: 'Casa do Mel',
            uf: 'MS',
            city: 'Campo Grande',
            latitude: -20.4697,
            longitude: -54.6201,
            salesAmount: 5000,
            salesCount: 80,
          ),
        ],
      );

      final regionMap = tester
          .widget<AppRegionMapChart<AppBrazilStoreSalesStateBucket>>(
            find.byWidgetPredicate(
              (widget) =>
                  widget is AppRegionMapChart<AppBrazilStoreSalesStateBucket>,
            ),
          );
      final bucket = regionMap.items.firstWhere((item) => item.uf == 'MS');
      regionMap.onRegionTapEvent?.call(
        AppMapRegionTapEvent<AppBrazilStoreSalesStateBucket>(
          item: bucket,
          regionKey: bucket.uf,
          regionLabel: bucket.stateName,
          metricKey: AppBrazilStoreSalesMapMetric.revenue.key,
          metricValue: bucket.salesAmount,
          index: regionMap.items.indexOf(bucket),
        ),
      );
      await tester.pump();
      await tester.pump();

      final stateDetail = find.byKey(
        const ValueKey<String>('brazil-store-sales-map-state-detail'),
      );
      expect(stateDetail, findsOneWidget);

      final contentRect = tester.getRect(
        find.byKey(const ValueKey<String>('brazil-store-sales-map-content')),
      );
      final detailRect = tester.getRect(stateDetail);
      expect(contentRect.bottom - detailRect.bottom, lessThan(8));
    },
  );

  testWidgets(
    'desktop sidebar requires useful width and clears branch selection when scope hides the store',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1220, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await _pumpMap(
        tester,
        width: 1220,
        height: 780,
        showDesktopBranchSidebar: true,
        style: _baseStyle.copyWith(showRegionFilter: true),
        points: const <AppBrazilStoreSalesPoint>[
          AppBrazilStoreSalesPoint(
            id: 'store-1',
            name: 'Filial Cuiaba',
            fantasyName: 'Mel Cuiaba',
            uf: 'MT',
            city: 'Cuiaba',
            latitude: -15.60,
            longitude: -56.10,
            salesAmount: 4200,
            salesCount: 42,
          ),
          AppBrazilStoreSalesPoint(
            id: 'store-2',
            name: 'Filial Sao Paulo',
            fantasyName: 'Mel Sao Paulo',
            uf: 'SP',
            city: 'Sao Paulo',
            latitude: -23.55,
            longitude: -46.63,
            salesAmount: 9800,
            salesCount: 98,
          ),
        ],
      );

      expect(
        find.byKey(const ValueKey<String>('brazil-store-sales-map-sidebar')),
        findsNothing,
      );

      await tester.binding.setSurfaceSize(const Size(1400, 900));
      await _pumpMap(
        tester,
        width: 1400,
        height: 780,
        showDesktopBranchSidebar: true,
        style: _baseStyle.copyWith(showRegionFilter: true),
        points: const <AppBrazilStoreSalesPoint>[
          AppBrazilStoreSalesPoint(
            id: 'store-1',
            name: 'Filial Cuiaba',
            fantasyName: 'Mel Cuiaba',
            uf: 'MT',
            city: 'Cuiaba',
            latitude: -15.60,
            longitude: -56.10,
            salesAmount: 4200,
            salesCount: 42,
          ),
          AppBrazilStoreSalesPoint(
            id: 'store-2',
            name: 'Filial Sao Paulo',
            fantasyName: 'Mel Sao Paulo',
            uf: 'SP',
            city: 'Sao Paulo',
            latitude: -23.55,
            longitude: -46.63,
            salesAmount: 9800,
            salesCount: 98,
          ),
        ],
      );

      expect(find.text('Mel Cuiaba'), findsOneWidget);
      expect(find.text('Mel Sao Paulo'), findsOneWidget);

      await tester.tap(
        find.byKey(
          const ValueKey<String>(
            'brazil-store-sales-map-sidebar-item-store-1',
          ),
        ),
      );
      await tester.pump();

      expect(
        find.byKey(
          const ValueKey<String>('brazil-store-sales-map-store-detail'),
        ),
        findsOneWidget,
      );

      await tester.tap(find.text('Sudeste'));
      await tester.pump();
      await tester.pump();

      expect(find.text('Mel Sao Paulo'), findsOneWidget);
      expect(find.text('Mel Cuiaba'), findsNothing);
      expect(
        find.byKey(
          const ValueKey<String>('brazil-store-sales-map-store-detail'),
        ),
        findsNothing,
      );
    },
  );

  testWidgets(
    'clean fullscreen chrome hides legends and supports collapsing the floating sidebar',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await _pumpMap(
        tester,
        width: 1400,
        height: 780,
        showDesktopBranchSidebar: true,
        presentationMode:
            AppBrazilStoreSalesMapPresentationMode.cleanFullscreen,
        style: _baseStyle.copyWith(
          showLegend: true,
          showMarkerScaleLegend: true,
          showMetricSelector: true,
          showRegionFilter: true,
        ),
        points: const <AppBrazilStoreSalesPoint>[
          AppBrazilStoreSalesPoint(
            id: 'store-1',
            name: 'Filial Cuiaba',
            fantasyName: 'Mel Cuiaba',
            uf: 'MT',
            city: 'Cuiaba',
            latitude: -15.60,
            longitude: -56.10,
            salesAmount: 4200,
            salesCount: 42,
          ),
          AppBrazilStoreSalesPoint(
            id: 'store-2',
            name: 'Filial Sao Paulo',
            fantasyName: 'Mel Sao Paulo',
            uf: 'SP',
            city: 'Sao Paulo',
            latitude: -23.55,
            longitude: -46.63,
            salesAmount: 9800,
            salesCount: 98,
          ),
        ],
      );

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
      expect(regionMap.style.showLegend, isFalse);
      expect(regionMap.style.showGroupLabels, isFalse);
      expect(
        find.byKey(const ValueKey<String>('app-region-map-metric-selector')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('app-region-map-scope-selector')),
        findsOneWidget,
      );
      final l10n = localizedFromWidget<AppBrazilStoreSalesMapChart>(tester);
      expect(
        find.text(l10n.regionMapMetricGroupLabel.toUpperCase()),
        findsNothing,
      );
      expect(
        find.text(l10n.regionMapScopeGroupLabel.toUpperCase()),
        findsNothing,
      );
      expect(
        find.byKey(
          const ValueKey<String>('brazil-store-sales-map-legend-button'),
        ),
        findsNothing,
      );
      expect(
        find.text(l10n.brazilStoreSalesMapLegendButton),
        findsNothing,
      );

      await tester.tap(
        find.byKey(
          const ValueKey<String>('brazil-store-sales-map-sidebar-collapse'),
        ),
      );
      await tester.pump();

      expect(
        find.byKey(const ValueKey<String>('brazil-store-sales-map-sidebar')),
        findsNothing,
      );
      expect(
        find.byKey(
          const ValueKey<String>('brazil-store-sales-map-sidebar-collapsed'),
        ),
        findsOneWidget,
      );

      await tester.tap(
        find.byKey(
          const ValueKey<String>('brazil-store-sales-map-sidebar-collapsed'),
        ),
      );
      await tester.pump();

      expect(
        find.byKey(const ValueKey<String>('brazil-store-sales-map-sidebar')),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'desktop sidebar shows explicit empty state for regions without visible branches',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await _pumpMap(
        tester,
        width: 1400,
        height: 780,
        showDesktopBranchSidebar: true,
        style: _baseStyle.copyWith(showRegionFilter: true),
        points: const <AppBrazilStoreSalesPoint>[
          AppBrazilStoreSalesPoint(
            id: 'store-1',
            name: 'Filial Cuiaba',
            fantasyName: 'Mel Cuiaba',
            uf: 'MT',
            city: 'Cuiaba',
            latitude: -15.60,
            longitude: -56.10,
            salesAmount: 4200,
            salesCount: 42,
          ),
        ],
      );

      await tester.tap(find.text('Norte'));
      await tester.pump();
      await tester.pump();

      expect(
        find.byKey(const ValueKey<String>('brazil-store-sales-map-sidebar')),
        findsOneWidget,
      );
      expect(
        find.byKey(
          const ValueKey<String>('brazil-store-sales-map-sidebar-empty'),
        ),
        findsOneWidget,
      );
      final l10n = localizedFromWidget<AppBrazilStoreSalesMapChart>(tester);
      expect(
        find.text(l10n.brazilStoreSalesMapSidebarEmptyStateTitle),
        findsOneWidget,
      );
      expect(
        find.text(l10n.brazilStoreSalesMapSidebarEmptyStateMessage),
        findsOneWidget,
      );
      expect(find.text('Mel Cuiaba'), findsNothing);
    },
  );

  testWidgets(
    'desktop sidebar filters branches locally and updates the summary',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await _pumpMap(
        tester,
        width: 1400,
        height: 780,
        showDesktopBranchSidebar: true,
        style: _baseStyle.copyWith(
          selectedMarkerDetailPlacement:
              AppBrazilStoreSalesSelectedMarkerDetailPlacement.overlay,
        ),
        points: const <AppBrazilStoreSalesPoint>[
          AppBrazilStoreSalesPoint(
            id: 'store-1',
            name: 'Filial Cuiaba',
            fantasyName: 'Mel Cuiaba',
            uf: 'MT',
            city: 'Cuiaba',
            latitude: -15.60,
            longitude: -56.10,
            salesAmount: 4200,
            salesCount: 42,
          ),
          AppBrazilStoreSalesPoint(
            id: 'store-2',
            name: 'Filial Sao Paulo',
            fantasyName: 'Mel Sao Paulo',
            uf: 'SP',
            city: 'Sao Paulo',
            latitude: -23.55,
            longitude: -46.63,
            salesAmount: 9800,
            salesCount: 98,
          ),
          AppBrazilStoreSalesPoint(
            id: 'store-3',
            name: 'Filial Porto Alegre',
            fantasyName: 'Mel Sul',
            uf: 'RS',
            city: 'Porto Alegre',
            latitude: -30.03,
            longitude: -51.23,
            salesAmount: 7300,
            salesCount: 67,
          ),
        ],
      );

      await tester.enterText(
        find.byKey(
          const ValueKey<String>('brazil-store-sales-map-sidebar-search'),
        ),
        'mel sul',
      );
      await tester.pump();

      expect(find.text('Filial Porto Alegre'), findsOneWidget);
      expect(find.text('Mel Sul'), findsOneWidget);
      expect(find.text('Filial Sao Paulo'), findsNothing);
      expect(find.text('Filial Cuiaba'), findsNothing);
      final l10n = localizedFromWidget<AppBrazilStoreSalesMapChart>(tester);
      expect(
        find.text(l10n.brazilStoreSalesMapSidebarCountSummary(1)),
        findsOneWidget,
      );
      expect(
        find.text(
          l10n.brazilStoreSalesMapSidebarRevenueSummary(r'R$ 7.300,00'),
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'desktop sidebar hover previews a branch without changing persistent selection and shows search empty state',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final points = <AppBrazilStoreSalesPoint>[
        const AppBrazilStoreSalesPoint(
          id: 'store-1',
          name: 'Filial Cuiaba',
          fantasyName: 'Mel Cuiaba',
          uf: 'MT',
          city: 'Cuiaba',
          latitude: -15.60,
          longitude: -56.10,
          salesAmount: 4200,
          salesCount: 42,
        ),
        const AppBrazilStoreSalesPoint(
          id: 'store-2',
          name: 'Filial Sao Paulo',
          fantasyName: 'Mel Sao Paulo',
          uf: 'SP',
          city: 'Sao Paulo',
          latitude: -23.55,
          longitude: -46.63,
          salesAmount: 9800,
          salesCount: 98,
        ),
      ];

      await _pumpMap(
        tester,
        width: 1400,
        height: 780,
        showDesktopBranchSidebar: true,
        style: _baseStyle.copyWith(
          selectedMarkerDetailPlacement:
              AppBrazilStoreSalesSelectedMarkerDetailPlacement.overlay,
        ),
        points: points,
      );

      final previewHandle =
          tester.state(
                find.byType(AppBrazilStoreSalesMapChart),
              )
              as AppBrazilStoreSalesMapChartPreviewTestHandle;
      final snapshotDataBefore = previewHandle.snapshotDataIdentityForTesting;
      final mapPointsBefore = previewHandle.snapshotMapPointsIdentityForTesting;

      previewHandle.previewBranchForTesting(points[1]);
      await tester.pump();
      await tester.pump();

      expect(previewHandle.previewedStoreIdForTesting, 'store-2');
      expect(
        previewHandle.snapshotDataIdentityForTesting,
        same(snapshotDataBefore),
      );
      expect(
        previewHandle.snapshotMapPointsIdentityForTesting,
        same(mapPointsBefore),
      );
      expect(
        find.byKey(
          const ValueKey<String>('brazil-store-sales-map-store-detail'),
        ),
        findsNothing,
      );

      previewHandle.clearPreviewBranchForTesting();
      await tester.pump(const Duration(milliseconds: 200));

      expect(previewHandle.previewedStoreIdForTesting, isNull);
      expect(
        previewHandle.snapshotDataIdentityForTesting,
        same(snapshotDataBefore),
      );
      expect(
        previewHandle.snapshotMapPointsIdentityForTesting,
        same(mapPointsBefore),
      );

      await tester.enterText(
        find.byKey(
          const ValueKey<String>('brazil-store-sales-map-sidebar-search'),
        ),
        'inexistente',
      );
      await tester.pump();

      final l10n = localizedFromWidget<AppBrazilStoreSalesMapChart>(tester);
      expect(
        find.text(l10n.brazilStoreSalesMapSidebarSearchEmptyStateTitle),
        findsOneWidget,
      );
      expect(
        find.text(l10n.brazilStoreSalesMapSidebarSearchEmptyStateMessage),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'desktop sidebar supports keyboard navigation and status rows',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await _pumpMap(
        tester,
        width: 1400,
        height: 780,
        showDesktopBranchSidebar: true,
        points: const <AppBrazilStoreSalesPoint>[
          AppBrazilStoreSalesPoint(
            id: 'store-loading',
            name: 'Filial carregando',
            fantasyName: 'Mel Cuiaba',
            uf: 'MT',
            city: 'Cuiaba',
            latitude: -15.60,
            longitude: -56.10,
            salesAmount: 0,
            salesCount: 0,
            salesDataLoading: true,
          ),
          AppBrazilStoreSalesPoint(
            id: 'store-unavailable',
            name: 'Filial indisponivel',
            fantasyName: 'Mel Norte',
            uf: 'PA',
            city: 'Belem',
            latitude: -1.45,
            longitude: -48.50,
            salesAmount: 0,
            salesCount: 0,
            salesDataUnavailable: true,
            salesDataStatusLabel: 'Vendas indisponiveis',
          ),
          AppBrazilStoreSalesPoint(
            id: 'store-zero',
            name: 'Filial zerada',
            fantasyName: 'Mel Sul',
            uf: 'RS',
            city: 'Porto Alegre',
            latitude: -30.03,
            longitude: -51.23,
            salesAmount: 0,
            salesCount: 0,
          ),
        ],
      );

      final l10n = localizedFromWidget<AppBrazilStoreSalesMapChart>(tester);
      expect(
        find.text(l10n.brazilStoreSalesMapSalesLoadingLabel),
        findsOneWidget,
      );
      expect(find.text('Vendas indisponiveis'), findsOneWidget);
      expect(
        find.text(l10n.brazilStoreSalesMapSidebarZeroSalesLabel),
        findsOneWidget,
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();

      expect(
        find.byKey(
          const ValueKey<String>('brazil-store-sales-map-store-detail'),
        ),
        findsOneWidget,
      );
      expect(find.text('Mel Sul'), findsWidgets);
    },
  );

  testWidgets('uses custom marker detail on Windows without native tooltip', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    try {
      await _pumpMap(
        tester,
        style: _baseStyle.copyWith(
          selectedMarkerDetailPlacement:
              AppBrazilStoreSalesSelectedMarkerDetailPlacement.overlay,
        ),
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
      expect(regionMap.style.showTooltip, isFalse);
      expect(
        find.byType(AppBrazilStoreSalesBranchHoverDetailAnchor),
        findsNothing,
      );
      expect(
        find.byType(AppBrazilStoreSalesSelectedMarkerDetailAnchor),
        findsNothing,
      );
      expect(
        find.byKey(
          const ValueKey<String>('brazil-store-sales-map-store-detail'),
        ),
        findsOneWidget,
      );
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets(
    'marker tap shows branch detail on Windows with production style',
    (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;
      try {
        await _pumpMap(
          tester,
          width: 1280,
          height: 720,
          showDesktopBranchSidebar: true,
          presentationMode:
              AppBrazilStoreSalesMapPresentationMode.cleanFullscreen,
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
          style: const AppBrazilStoreSalesMapStyle(
            height: 560,
            showLegend: false,
            showMetricSelector: false,
            showRegionFilter: false,
            showMarkerScaleLegend: false,
            enableProximityCluster: true,
          ),
        );

        final regionMap = tester
            .widget<AppRegionMapChart<AppBrazilStoreSalesStateBucket>>(
              find.byWidgetPredicate(
                (widget) =>
                    widget is AppRegionMapChart<AppBrazilStoreSalesStateBucket>,
              ),
            );
        regionMap.onPointTap?.call(
          AppMapPointTapEvent(
            point: regionMap.points.first,
            index: 0,
          ),
        );
        await tester.pump();
        await tester.pump();

        expect(
          find.byKey(
            const ValueKey<String>('brazil-store-sales-map-store-detail'),
          ),
          findsOneWidget,
        );
        expect(find.text('Casa do Mel'), findsOneWidget);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    },
  );

  testWidgets(
    'marker tap keeps branch detail when map emits region tap for same UF',
    (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;
      try {
        const store = AppBrazilStoreSalesPoint(
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
        await _pumpMap(
          tester,
          width: 1280,
          height: 720,
          presentationMode:
              AppBrazilStoreSalesMapPresentationMode.cleanFullscreen,
          points: const <AppBrazilStoreSalesPoint>[store],
          style: const AppBrazilStoreSalesMapStyle(
            height: 560,
            showLegend: false,
            showMetricSelector: false,
            showRegionFilter: false,
            showMarkerScaleLegend: false,
            enableProximityCluster: true,
          ),
        );

        final regionMap = tester
            .widget<AppRegionMapChart<AppBrazilStoreSalesStateBucket>>(
              find.byWidgetPredicate(
                (widget) =>
                    widget is AppRegionMapChart<AppBrazilStoreSalesStateBucket>,
              ),
            );
        final markerIndex = regionMap.points.indexWhere((point) {
          final payload = point.payload;
          return payload is AppBrazilStoreSalesMarkerGroup &&
              !payload.isCluster;
        });
        expect(markerIndex, greaterThanOrEqualTo(0));

        regionMap.onPointTap?.call(
          AppMapPointTapEvent(
            point: regionMap.points[markerIndex],
            index: markerIndex,
          ),
        );
        await tester.pump();
        await tester.pump();

        final bucket = regionMap.items.firstWhere((item) => item.uf == 'MT');
        regionMap.onRegionTapEvent?.call(
          AppMapRegionTapEvent<AppBrazilStoreSalesStateBucket>(
            item: bucket,
            regionKey: bucket.uf,
            regionLabel: bucket.stateName,
            metricKey: AppBrazilStoreSalesMapMetric.revenue.key,
            metricValue: bucket.salesAmount,
            index: regionMap.items.indexOf(bucket),
          ),
        );
        await tester.pump();

        expect(
          find.byKey(
            const ValueKey<String>('brazil-store-sales-map-store-detail'),
          ),
          findsOneWidget,
        );
        expect(find.text('Casa do Mel'), findsOneWidget);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    },
  );

  testWidgets(
    'repeated region tap while store selected keeps snapshot data stable',
    (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;
      try {
        const store = AppBrazilStoreSalesPoint(
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
        await _pumpMap(
          tester,
          width: 1280,
          height: 720,
          presentationMode:
              AppBrazilStoreSalesMapPresentationMode.cleanFullscreen,
          points: const <AppBrazilStoreSalesPoint>[store],
          style: const AppBrazilStoreSalesMapStyle(
            height: 560,
            showLegend: false,
            showMetricSelector: false,
            showRegionFilter: false,
            showMarkerScaleLegend: false,
            enableProximityCluster: true,
          ),
        );

        final chartState =
            tester.state<State<AppBrazilStoreSalesMapChart>>(
                  find.byType(AppBrazilStoreSalesMapChart),
                )
                as AppBrazilStoreSalesMapChartPreviewTestHandle;
        final regionMap = tester
            .widget<AppRegionMapChart<AppBrazilStoreSalesStateBucket>>(
              find.byWidgetPredicate(
                (widget) =>
                    widget is AppRegionMapChart<AppBrazilStoreSalesStateBucket>,
              ),
            );
        final markerIndex = regionMap.points.indexWhere((point) {
          final payload = point.payload;
          return payload is AppBrazilStoreSalesMarkerGroup &&
              !payload.isCluster;
        });
        expect(markerIndex, greaterThanOrEqualTo(0));

        regionMap.onPointTap?.call(
          AppMapPointTapEvent(
            point: regionMap.points[markerIndex],
            index: markerIndex,
          ),
        );
        await tester.pump();
        final identityAfterTap = chartState.snapshotDataIdentityForTesting;

        final bucket = regionMap.items.firstWhere((item) => item.uf == 'MT');
        final regionTap = AppMapRegionTapEvent<AppBrazilStoreSalesStateBucket>(
          item: bucket,
          regionKey: bucket.uf,
          regionLabel: bucket.stateName,
          metricKey: AppBrazilStoreSalesMapMetric.revenue.key,
          metricValue: bucket.salesAmount,
          index: regionMap.items.indexOf(bucket),
        );
        for (var repeat = 0; repeat < 8; repeat++) {
          regionMap.onRegionTapEvent?.call(regionTap);
          await tester.pump();
        }

        expect(
          chartState.snapshotDataIdentityForTesting,
          same(identityAfterTap),
        );
        expect(
          find.byKey(
            const ValueKey<String>('brazil-store-sales-map-store-detail'),
          ),
          findsOneWidget,
        );
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    },
  );

  testWidgets(
    'region tap on different UF clears store detail selection',
    (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;
      try {
        const store = AppBrazilStoreSalesPoint(
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
        await _pumpMap(
          tester,
          width: 1280,
          height: 720,
          presentationMode:
              AppBrazilStoreSalesMapPresentationMode.cleanFullscreen,
          points: const <AppBrazilStoreSalesPoint>[store],
          style: const AppBrazilStoreSalesMapStyle(
            height: 560,
            showLegend: false,
            showMetricSelector: false,
            showRegionFilter: false,
            showMarkerScaleLegend: false,
            enableProximityCluster: true,
          ),
        );

        final regionMap = tester
            .widget<AppRegionMapChart<AppBrazilStoreSalesStateBucket>>(
              find.byWidgetPredicate(
                (widget) =>
                    widget is AppRegionMapChart<AppBrazilStoreSalesStateBucket>,
              ),
            );
        final markerIndex = regionMap.points.indexWhere((point) {
          final payload = point.payload;
          return payload is AppBrazilStoreSalesMarkerGroup &&
              !payload.isCluster;
        });
        expect(markerIndex, greaterThanOrEqualTo(0));

        regionMap.onPointTap?.call(
          AppMapPointTapEvent(
            point: regionMap.points[markerIndex],
            index: markerIndex,
          ),
        );
        await tester.pump();
        await tester.pump();

        expect(
          find.byKey(
            const ValueKey<String>('brazil-store-sales-map-store-detail'),
          ),
          findsOneWidget,
        );

        final spBucket = regionMap.items.firstWhere((item) => item.uf == 'SP');
        regionMap.onRegionTapEvent?.call(
          AppMapRegionTapEvent<AppBrazilStoreSalesStateBucket>(
            item: spBucket,
            regionKey: spBucket.uf,
            regionLabel: spBucket.stateName,
            metricKey: AppBrazilStoreSalesMapMetric.revenue.key,
            metricValue: spBucket.salesAmount,
            index: regionMap.items.indexOf(spBucket),
          ),
        );
        await tester.pump();

        expect(
          find.byKey(
            const ValueKey<String>('brazil-store-sales-map-store-detail'),
          ),
          findsNothing,
        );
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    },
  );

  testWidgets(
    'cluster tap stabilizes snapshot data under auto-focus and sidebar',
    (tester) async {
      const clusterPoints = <AppBrazilStoreSalesPoint>[
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
        AppBrazilStoreSalesPoint(
          id: 'store-2',
          name: 'Mel Norte',
          fantasyName: 'Mel Norte',
          uf: 'MT',
          city: 'Tangara da Serra',
          latitude: -14.6229,
          longitude: -57.4933,
          salesAmount: 4200,
          salesCount: 88,
        ),
      ];

      await _pumpMap(
        tester,
        points: clusterPoints,
        width: 1280,
        height: 720,
        showDesktopBranchSidebar: true,
        presentationMode:
            AppBrazilStoreSalesMapPresentationMode.cleanFullscreen,
        style: _baseStyle.copyWith(
          enableZoomPan: true,
          enableProximityCluster: true,
        ),
      );

      final chartState =
          tester.state<State<AppBrazilStoreSalesMapChart>>(
                find.byType(AppBrazilStoreSalesMapChart),
              )
              as AppBrazilStoreSalesMapChartPreviewTestHandle;
      final identityBeforeTap = chartState.snapshotDataIdentityForTesting;

      final regionMap = tester
          .widget<AppRegionMapChart<AppBrazilStoreSalesStateBucket>>(
            find.byWidgetPredicate(
              (widget) =>
                  widget is AppRegionMapChart<AppBrazilStoreSalesStateBucket>,
            ),
          );
      final clusterIndex = regionMap.points.indexWhere((point) {
        final payload = point.payload;
        return payload is AppBrazilStoreSalesMarkerGroup && payload.isCluster;
      });
      expect(clusterIndex, greaterThanOrEqualTo(0));
      regionMap.onPointTap?.call(
        AppMapPointTapEvent(
          point: regionMap.points[clusterIndex],
          index: clusterIndex,
        ),
      );
      await tester.pump();
      final identityAfterTap = chartState.snapshotDataIdentityForTesting;
      expect(identityAfterTap, same(identityBeforeTap));

      for (var frame = 0; frame < 8; frame++) {
        await tester.pump(const Duration(milliseconds: 120));
      }

      expect(
        chartState.snapshotDataIdentityForTesting,
        same(identityBeforeTap),
      );

      for (var zoomStep = 0; zoomStep < 12; zoomStep++) {
        regionMap.onViewportChanged?.call(
          AppMapViewportChangedEvent(
            viewport: AppMapViewport(zoomLevel: 1.0 + zoomStep * 0.15),
          ),
        );
        await tester.pump(const Duration(milliseconds: 60));
      }

      expect(
        chartState.snapshotDataIdentityForTesting,
        same(identityBeforeTap),
      );
      expect(
        find.byKey(
          const ValueKey<String>('brazil-store-sales-map-municipality-detail'),
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'single store focus ignores viewport clustering churn after tap',
    (tester) async {
      const store = AppBrazilStoreSalesPoint(
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

      await _pumpMap(
        tester,
        points: const <AppBrazilStoreSalesPoint>[store],
        style: _baseStyle.copyWith(
          enableZoomPan: true,
          enableProximityCluster: true,
        ),
      );

      final chartState =
          tester.state<State<AppBrazilStoreSalesMapChart>>(
                find.byType(AppBrazilStoreSalesMapChart),
              )
              as AppBrazilStoreSalesMapChartPreviewTestHandle;
      final regionMap = tester
          .widget<AppRegionMapChart<AppBrazilStoreSalesStateBucket>>(
            find.byWidgetPredicate(
              (widget) =>
                  widget is AppRegionMapChart<AppBrazilStoreSalesStateBucket>,
            ),
          );
      final markerIndex = regionMap.points.indexWhere((point) {
        final payload = point.payload;
        return payload is AppBrazilStoreSalesMarkerGroup && !payload.isCluster;
      });
      expect(markerIndex, greaterThanOrEqualTo(0));

      regionMap.onPointTap?.call(
        AppMapPointTapEvent(
          point: regionMap.points[markerIndex],
          index: markerIndex,
        ),
      );
      await tester.pump();
      final identityAfterTap = chartState.snapshotDataIdentityForTesting;

      for (var zoomStep = 0; zoomStep < 12; zoomStep++) {
        regionMap.onViewportChanged?.call(
          AppMapViewportChangedEvent(
            viewport: AppMapViewport(zoomLevel: 1.0 + zoomStep * 0.2),
          ),
        );
        await tester.pump(const Duration(milliseconds: 60));
      }

      expect(
        chartState.snapshotDataIdentityForTesting,
        same(identityAfterTap),
      );
    },
  );

  testWidgets(
    'single store tap without auto focus keeps snapshot data stable',
    (tester) async {
      const store = AppBrazilStoreSalesPoint(
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

      await _pumpMap(
        tester,
        points: const <AppBrazilStoreSalesPoint>[store],
        style: _baseStyle.copyWith(
          enableZoomPan: true,
          enableProximityCluster: true,
          autoFocusSelectedStore: false,
        ),
      );

      final chartState =
          tester.state<State<AppBrazilStoreSalesMapChart>>(
                find.byType(AppBrazilStoreSalesMapChart),
              )
              as AppBrazilStoreSalesMapChartPreviewTestHandle;
      final identityBeforeTap = chartState.snapshotDataIdentityForTesting;
      final mapPointsBeforeTap =
          chartState.snapshotMapPointsIdentityForTesting;
      final regionMap = tester
          .widget<AppRegionMapChart<AppBrazilStoreSalesStateBucket>>(
            find.byWidgetPredicate(
              (widget) =>
                  widget is AppRegionMapChart<AppBrazilStoreSalesStateBucket>,
            ),
          );
      final markerIndex = regionMap.points.indexWhere((point) {
        final payload = point.payload;
        return payload is AppBrazilStoreSalesMarkerGroup && !payload.isCluster;
      });
      expect(markerIndex, greaterThanOrEqualTo(0));

      regionMap.onPointTap?.call(
        AppMapPointTapEvent(
          point: regionMap.points[markerIndex],
          index: markerIndex,
        ),
      );
      await tester.pump();

      expect(
        chartState.snapshotDataIdentityForTesting,
        same(identityBeforeTap),
      );
      expect(
        chartState.snapshotMapPointsIdentityForTesting,
        same(mapPointsBeforeTap),
      );
      expect(
        find.byKey(
          const ValueKey<String>('brazil-store-sales-map-store-detail'),
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'marker tap withdraws preferred viewport after user zoom',
    (tester) async {
      const store = AppBrazilStoreSalesPoint(
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

      await _pumpMap(
        tester,
        points: const <AppBrazilStoreSalesPoint>[store],
        style: _baseStyle.copyWith(
          enableZoomPan: true,
          enableProximityCluster: true,
          autoFocusSelectedStore: false,
        ),
      );

      final regionMap = tester
          .widget<AppRegionMapChart<AppBrazilStoreSalesStateBucket>>(
            find.byWidgetPredicate(
              (widget) =>
                  widget is AppRegionMapChart<AppBrazilStoreSalesStateBucket>,
            ),
          );
      expect(regionMap.preferredViewport, isNotNull);

      regionMap.onViewportChanged?.call(
        const AppMapViewportChangedEvent(
          viewport: AppMapViewport(zoomLevel: 1.8),
          source: AppMapViewportChangeSource.user,
        ),
      );
      await tester.pump();

      final markerIndex = regionMap.points.indexWhere((point) {
        final payload = point.payload;
        return payload is AppBrazilStoreSalesMarkerGroup && !payload.isCluster;
      });
      expect(markerIndex, greaterThanOrEqualTo(0));

      final chartState =
          tester.state<State<AppBrazilStoreSalesMapChart>>(
                find.byType(AppBrazilStoreSalesMapChart),
              )
              as AppBrazilStoreSalesMapChartPreviewTestHandle;

      regionMap.onPointTap?.call(
        AppMapPointTapEvent(
          point: regionMap.points[markerIndex],
          index: markerIndex,
        ),
      );
      await tester.pump();

      expect(chartState.suppressPreferredViewportForTesting, isTrue);
      expect(
        find.byKey(
          const ValueKey<String>('brazil-store-sales-map-store-detail'),
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'controlled selected store without auto focus keeps snapshot data stable',
    (tester) async {
      const store = AppBrazilStoreSalesPoint(
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

      const style = AppBrazilStoreSalesMapStyle(
        height: 360,
        showLegend: false,
        showMetricSelector: false,
        showRegionFilter: false,
        showMarkerScaleLegend: false,
        enableProximityCluster: true,
        autoFocusSelectedStore: false,
        markerVisual: AppBrazilStoreSalesMarkerVisual.storeIcon,
        selectedMarkerDetailPlacement:
            AppBrazilStoreSalesSelectedMarkerDetailPlacement.belowMap,
      );

      await _pumpMap(
        tester,
        points: const <AppBrazilStoreSalesPoint>[store],
        style: style,
      );

      final chartState =
          tester.state<State<AppBrazilStoreSalesMapChart>>(
                find.byType(AppBrazilStoreSalesMapChart),
              )
              as AppBrazilStoreSalesMapChartPreviewTestHandle;
      final identityBeforeSelection = chartState.snapshotDataIdentityForTesting;

      await _pumpMap(
        tester,
        points: const <AppBrazilStoreSalesPoint>[store],
        selectedStoreId: 'store-1',
        style: style,
      );

      expect(
        chartState.snapshotDataIdentityForTesting,
        same(identityBeforeSelection),
      );
      expect(
        find.byKey(
          const ValueKey<String>('brazil-store-sales-map-store-detail'),
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'Windows wheel zoom without selection does not resample snapshot data',
    (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;
      try {
        await _pumpMap(
          tester,
          points: const <AppBrazilStoreSalesPoint>[
            AppBrazilStoreSalesPoint(
              id: 'store-1',
              name: 'Casa do Mel',
              uf: 'MT',
              city: 'Tangara',
              latitude: -14.62,
              longitude: -57.49,
              salesAmount: 100,
              salesCount: 10,
            ),
            AppBrazilStoreSalesPoint(
              id: 'store-2',
              name: 'Mel Norte',
              uf: 'SP',
              city: 'Sao Paulo',
              latitude: -23.55,
              longitude: -46.63,
              salesAmount: 200,
              salesCount: 20,
            ),
          ],
          style: _baseStyle.copyWith(
            enableZoomPan: true,
            enableProximityCluster: true,
          ),
        );

        final chartState =
            tester.state<State<AppBrazilStoreSalesMapChart>>(
                  find.byType(AppBrazilStoreSalesMapChart),
                )
                as AppBrazilStoreSalesMapChartPreviewTestHandle;
        final identityBeforeZoom = chartState.snapshotDataIdentityForTesting;
        final regionMap = tester
            .widget<AppRegionMapChart<AppBrazilStoreSalesStateBucket>>(
              find.byWidgetPredicate(
                (widget) =>
                    widget is AppRegionMapChart<AppBrazilStoreSalesStateBucket>,
              ),
            );

        for (var zoomStep = 0; zoomStep < 12; zoomStep++) {
          regionMap.onViewportChanged?.call(
            AppMapViewportChangedEvent(
              viewport: AppMapViewport(zoomLevel: 1.45 - zoomStep * 0.05),
            ),
          );
          await tester.pump(const Duration(milliseconds: 60));
        }
        await tester.pump(const Duration(milliseconds: 600));

        expect(
          chartState.snapshotDataIdentityForTesting,
          same(identityBeforeZoom),
        );
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    },
  );

  testWidgets(
    'selected marker detail anchor shows a persistent floating card',
    (
      tester,
    ) async {
      var clearedSelection = false;
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
        onClearSelection: () {
          clearedSelection = true;
        },
        locale: const Locale('en'),
      );

      expect(
        find.byKey(const ValueKey<String>('brazil-store-sales-branch-card')),
        findsOneWidget,
      );
      expect(find.text('Casa do Mel'), findsOneWidget);
      expect(find.text('Unpin from map'), findsOneWidget);

      await tester.tap(
        find.byKey(
          const ValueKey<String>('brazil-store-sales-branch-card-select'),
        ),
      );
      await tester.pump();

      expect(clearedSelection, isTrue);
    },
  );

  testWidgets(
    'selected marker detail keeps show-on-map action when browsing another branch in the same group',
    (tester) async {
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
          AppBrazilStoreSalesPoint(
            id: 'store-2',
            name: 'Mel Norte',
            fantasyName: 'Mel Norte',
            uf: 'MT',
            city: 'Tangara da Serra',
            latitude: -14.6229,
            longitude: -57.4933,
            salesAmount: 4200,
            salesCount: 88,
          ),
        ],
        locale: const Locale('en'),
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();

      expect(find.text('Mel Norte'), findsOneWidget);
      expect(find.text('Show on map'), findsOneWidget);
      expect(find.text('Unpin from map'), findsNothing);
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

    expect(find.text('Jardim'), findsOneWidget);
    expect(find.text('Tangara da Serra / MT'), findsOneWidget);
    expect(find.text(r'R$ 24.246,26'), findsOneWidget);
    final l10n = localizedFromWidget<AppBrazilStoreSalesMapChart>(tester);
    expect(
      find.text(l10n.brazilStoreSalesMapDetailChipSales('468')),
      findsOneWidget,
    );
    expect(
      find.text(l10n.brazilStoreSalesMapCarouselPosition('1', '2')),
      findsWidgets,
    );
    expect(
      find.text(l10n.brazilStoreSalesMapMarkerGroupTotalTitle),
      findsOneWidget,
    );
    expect(find.text(r'R$ 84.246,26'), findsOneWidget);
    expect(
      find.text(l10n.brazilStoreSalesMapDetailChipSales('1.568')),
      findsOneWidget,
    );
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
    expect(find.text('Filial cadastro'), findsOneWidget);
    expect(find.text('Sinop / MT'), findsOneWidget);
    expect(find.text(r'R$ 3.421,77'), findsOneWidget);
    final l10n = localizedFromWidget<Scaffold>(tester);
    expect(
      find.text(l10n.brazilStoreSalesMapDetailChipSales('64')),
      findsOneWidget,
    );
    expect(find.text('Empresa 7 - Filial 3'), findsNothing);
    expect(find.text('Filial Norte'), findsOneWidget);
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

    expect(find.text('Filial sem venda disponivel'), findsOneWidget);
    expect(find.text('Mel Sinop'), findsOneWidget);
    final l10n = localizedFromWidget<Scaffold>(tester);
    expect(
      find.text(l10n.brazilStoreSalesMapDetailChipSales('0')),
      findsOneWidget,
    );
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

    expect(find.text('Filial carregando'), findsOneWidget);
    expect(find.text('Mel Sinop'), findsOneWidget);
    final l10n = localizedFromWidget<Scaffold>(tester);
    expect(
      find.text(l10n.brazilStoreSalesMapSalesLoadingLabel),
      findsOneWidget,
    );
    expect(find.text(r'R$ 0,00'), findsNothing);
    expect(
      find.text(l10n.brazilStoreSalesMapDetailChipSales('0')),
      findsNothing,
    );
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

    expect(find.text('Matriz'), findsOneWidget);
    final l10n = localizedFromWidget<Scaffold>(tester);
    expect(
      find.text(l10n.brazilStoreSalesMapCarouselPosition('1', '2')),
      findsWidgets,
    );

    await tester.tap(
      find.byKey(const ValueKey<String>('brazil-store-sales-branch-card-next')),
    );
    await tester.pump();

    expect(find.text('Filial 2'), findsOneWidget);
    expect(find.text(r'R$ 1.421,77'), findsOneWidget);
    expect(
      find.text(l10n.brazilStoreSalesMapDetailChipSales('44')),
      findsOneWidget,
    );
    expect(
      find.text(l10n.brazilStoreSalesMapCarouselPosition('2', '2')),
      findsWidgets,
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
    expect(find.text('Matriz'), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    expect(find.text('Filial 2'), findsOneWidget);

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
    expect(find.text('Filial cadastro'), findsOneWidget);
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
    final l10n = localizedFromWidget<AppBrazilStoreSalesMapChart>(tester);
    expect(find.text(l10n.brazilStoreSalesMapLegendButton), findsOneWidget);
    expect(
      find.byKey(
        const ValueKey<String>('brazil-store-sales-map-legend-button'),
      ),
      findsOneWidget,
    );
    expect(
      find.text(l10n.brazilStoreSalesMapMarkerSizeLegend),
      findsNothing,
    );

    await tester.tap(find.text(l10n.brazilStoreSalesMapLegendButton));
    await tester.pumpAndSettle();

    expect(
      find.text(l10n.brazilStoreSalesMapMarkerSizeLegend),
      findsOneWidget,
    );
  });

  testWidgets('exposes stable selector and diagnostics anchors', (
    tester,
  ) async {
    await _pumpMap(
      tester,
      style: const AppBrazilStoreSalesMapStyle(
        height: 360,
        showLegend: false,
        showRegionFilter: false,
        showMarkerScaleLegend: false,
        enableZoomPan: false,
      ),
      points: const <AppBrazilStoreSalesPoint>[
        AppBrazilStoreSalesPoint(
          id: 'valid',
          name: 'Loja Valida',
          uf: 'MT',
          city: 'Cuiaba',
          latitude: -15.6,
          longitude: -56.1,
          salesAmount: 10,
          salesCount: 1,
        ),
        AppBrazilStoreSalesPoint(
          id: 'invalid',
          name: 'Loja Invalida',
          uf: 'MT',
          city: 'Cuiaba',
          latitude: -99,
          longitude: -56.1,
          salesAmount: 10,
          salesCount: 1,
        ),
      ],
    );

    expect(
      find.byKey(const ValueKey<String>('app-region-map-metric-selector')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('brazil-store-sales-map-data-quality')),
      findsOneWidget,
    );
  });

  testWidgets(
    'mobile marker tap does not render below-map detail duplicate',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 720));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await _pumpMap(
        tester,
        width: 390,
        height: 640,
        style: _baseStyle.copyWith(showStoreDetail: true),
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

      final regionMap = tester
          .widget<AppRegionMapChart<AppBrazilStoreSalesStateBucket>>(
            find.byWidgetPredicate(
              (widget) =>
                  widget is AppRegionMapChart<AppBrazilStoreSalesStateBucket>,
            ),
          );
      final markerIndex = regionMap.points.indexWhere((point) {
        final payload = point.payload;
        return payload is AppBrazilStoreSalesMarkerGroup && !payload.isCluster;
      });
      expect(markerIndex, greaterThanOrEqualTo(0));

      regionMap.onPointTap?.call(
        AppMapPointTapEvent(
          point: regionMap.points[markerIndex],
          index: markerIndex,
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(
        find.byKey(
          const ValueKey<String>('brazil-store-sales-map-store-detail'),
        ),
        findsNothing,
      );
    },
  );

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
      final l10n = localizedFromWidget<AppBrazilStoreSalesMapChart>(tester);
      expect(find.text(l10n.brazilStoreSalesMapLegendButton), findsOneWidget);
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

  testWidgets('state tooltip localizes english copy when locale is en', (
    tester,
  ) async {
    await _pumpMap(
      tester,
      locale: const Locale('en'),
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
    expect(tooltip, contains('12 sales'));
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
    'clears internal store selection when refreshed points omit the store',
    (tester) async {
      const storeOne = AppBrazilStoreSalesPoint(
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
      const storeTwo = AppBrazilStoreSalesPoint(
        id: 'store-2',
        name: 'Filial Sul',
        fantasyName: 'Mel Sul',
        uf: 'SP',
        city: 'Sao Paulo',
        latitude: -23.55,
        longitude: -46.63,
        salesAmount: 1200,
        salesCount: 12,
      );
      var points = const <AppBrazilStoreSalesPoint>[storeOne, storeTwo];

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
                      onPressed: () => setState(() {
                        points = const <AppBrazilStoreSalesPoint>[storeTwo];
                      }),
                      child: const Text('refresh points'),
                    ),
                    SizedBox(
                      width: 720,
                      height: 400,
                      child: AppBrazilStoreSalesMapChart(
                        points: points,
                        style: _baseStyle,
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

      final regionMapFinder = find.byWidgetPredicate(
        (widget) => widget is AppRegionMapChart<AppBrazilStoreSalesStateBucket>,
      );
      final regionMapBefore =
          tester.widget<AppRegionMapChart<AppBrazilStoreSalesStateBucket>>(
        regionMapFinder.first,
      );
      final storeOneIndex = regionMapBefore.points.indexWhere((point) {
        final payload = point.payload;
        return payload is AppBrazilStoreSalesMarkerGroup &&
            payload.points.any((branch) => branch.id == 'store-1');
      });
      expect(storeOneIndex, greaterThanOrEqualTo(0));

      regionMapBefore.onPointTap?.call(
        AppMapPointTapEvent(
          point: regionMapBefore.points[storeOneIndex],
          index: storeOneIndex,
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.text('Casa do Mel'), findsOneWidget);

      await tester.tap(find.text('refresh points'));
      await tester.pump();
      await tester.pump();

      expect(find.text('Casa do Mel'), findsNothing);
      expect(
        find.byKey(
          const ValueKey<String>('brazil-store-sales-map-store-detail'),
        ),
        findsNothing,
      );
    },
  );

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
  Locale locale = const Locale('pt', 'BR'),
  bool showDesktopBranchSidebar = false,
  AppBrazilStoreSalesMapPresentationMode presentationMode =
      AppBrazilStoreSalesMapPresentationMode.standard,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(),
      locale: locale,
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
              showDesktopBranchSidebar: showDesktopBranchSidebar,
              presentationMode: presentationMode,
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
  Locale locale = const Locale('pt', 'BR'),
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(),
      locale: locale,
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

Future<void> _pumpSelectedAnchor(
  WidgetTester tester, {
  required List<AppBrazilStoreSalesPoint> points,
  Locale locale = const Locale('pt', 'BR'),
  VoidCallback? onClearSelection,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(),
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Center(
          child: AppBrazilStoreSalesSelectedMarkerDetailAnchor(
            group: AppBrazilStoreSalesMarkerGroup(points: points),
            selectedStoreId: points.first.id,
            metric: AppBrazilStoreSalesMapMetric.revenue,
            onClose: () {},
            onClearSelection: onClearSelection,
            onSelectBranch: (_) {},
            selectBranchLabel: 'Show on map',
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
