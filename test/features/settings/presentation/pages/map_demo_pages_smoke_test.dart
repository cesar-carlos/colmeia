import 'package:colmeia/app/theme/app_theme.dart';
import 'package:colmeia/features/settings/presentation/pages/app_brazil_store_sales_map_chart_demo_page.dart';
import 'package:colmeia/features/settings/presentation/pages/app_region_map_drilldown_demo_page.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('drill-down map demo mounts on Windows without throwing', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    try {
      await tester.pumpWidget(
        const _TestApp(child: AppRegionMapDrillDownDemoPage()),
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
      try {
        await tester.pumpWidget(
          const _TestApp(child: AppBrazilStoreSalesMapChartDemoPage()),
        );
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.text('AppBrazilStoreSalesMapChart'), findsOneWidget);
        expect(find.text('Performance de lojas'), findsOneWidget);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    },
  );
}

class _TestApp extends StatelessWidget {
  const _TestApp({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: AppTheme.light(),
      home: Scaffold(body: child),
    );
  }
}
