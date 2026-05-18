import 'dart:ui' show Size;

import 'package:colmeia/features/settings/presentation/pages/app_brazil_store_sales_map_chart_demo_page.dart';
import 'package:colmeia/features/settings/presentation/pages/app_region_map_drilldown_demo_page.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/localized_test_app.dart';

void main() {
  testWidgets('drill-down map demo mounts on Windows without throwing', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    try {
      await tester.pumpWidget(
        const LocalizedTestApp(child: AppRegionMapDrillDownDemoPage()),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(AppRegionMapDrillDownDemoPage), findsOneWidget);
      expect(find.text('Performance territorial'), findsOneWidget);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets(
    'Brazil store sales map demo mounts on Windows without throwing',
    (
      tester,
    ) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;
      tester.view.physicalSize = const Size(1200, 1800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      try {
        await tester.pumpWidget(
          const LocalizedTestApp(
            child: AppBrazilStoreSalesMapChartDemoPage(),
          ),
        );
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.text('AppBrazilStoreSalesMapChart'), findsOneWidget);
        expect(find.text('Tipo do mapa'), findsOneWidget);
        expect(find.text('Pontos'), findsOneWidget);
        expect(find.text('Bolhas'), findsOneWidget);
        expect(find.text('Bolhas por UF'), findsOneWidget);
        expect(find.text('Ícone loja'), findsOneWidget);
        expect(find.text('Performance de lojas'), findsOneWidget);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    },
  );

  testWidgets(
    'Brazil store sales map demo switches visual type',
    (
      tester,
    ) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;
      tester.view.physicalSize = const Size(1200, 1800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      try {
        await tester.pumpWidget(
          const LocalizedTestApp(
            child: AppBrazilStoreSalesMapChartDemoPage(),
          ),
        );
        await tester.pump(const Duration(milliseconds: 300));

        await tester.tap(find.text('Bolhas por UF'));
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.text('Mapa com bolhas por UF'), findsOneWidget);

        await tester.tap(find.text('Ícone loja'));
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.text('Mapa com icone de loja'), findsOneWidget);

        await tester.tap(find.text('Pontos'));
        await tester.pump(const Duration(milliseconds: 300));
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    },
  );
}
