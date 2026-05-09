import 'dart:convert';

import 'package:colmeia/app/theme/app_theme.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_presets.dart';
import 'package:colmeia/shared/widgets/charts/app_region_map_chart.dart';
import 'package:colmeia/shared/widgets/charts/engines/syncfusion_region_map_chart.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syncfusion_flutter_maps/maps.dart';

void main() {
  testWidgets('excludes SfMaps semantics on Windows', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    final semantics = tester.ensureSemantics();
    try {
      await tester.pumpWidget(const _TestApp(child: _TestRegionMap()));

      expect(find.byType(SfMaps), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (widget) => widget is ExcludeSemantics && widget.child is SfMaps,
        ),
        findsOneWidget,
      );
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Semantics &&
              widget.properties.label ==
                  'Mapa territorial. Metrica: Receita. 1 regioes.',
        ),
        findsOneWidget,
      );
    } finally {
      semantics.dispose();
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('can keep native SfMaps semantics on Windows when opted out', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    try {
      await tester.pumpWidget(
        const _TestApp(
          child: _TestRegionMap(
            style: AppRegionMapChartStyle(
              height: 240,
              excludeNativeMapSemanticsOnWindows: false,
            ),
          ),
        ),
      );

      expect(find.byType(SfMaps), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (widget) => widget is ExcludeSemantics && widget.child is SfMaps,
        ),
        findsNothing,
      );
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('uses custom fallback semantics label on Windows', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    try {
      await tester.pumpWidget(
        const _TestApp(
          child: _TestRegionMap(
            style: AppRegionMapChartStyle(
              height: 240,
              mapSemanticsLabel: 'Mapa de teste acessivel',
            ),
          ),
        ),
      );

      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Semantics &&
              widget.properties.label == 'Mapa de teste acessivel',
        ),
        findsOneWidget,
      );
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('keeps SfMaps semantics enabled outside Windows', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    try {
      await tester.pumpWidget(const _TestApp(child: _TestRegionMap()));

      expect(find.byType(SfMaps), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (widget) => widget is ExcludeSemantics && widget.child is SfMaps,
        ),
        findsNothing,
      );
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });
}

class _TestRegionMap extends StatelessWidget {
  const _TestRegionMap({
    this.style = const AppRegionMapChartStyle(height: 240),
  });

  final AppRegionMapChartStyle style;

  @override
  Widget build(BuildContext context) {
    return SyncfusionRegionMapChart<String>(
      items: const <String>['SP'],
      mapDefinition: AppMapDefinition.memory(
        sourceBytes: _geoJsonBytes,
        shapeDataField: 'UF',
        regionLevel: AppMapRegionLevel.state,
      ),
      metric: AppMapMetric<String>(
        key: 'revenue',
        label: 'Receita',
        valueBuilder: (_) => 1,
      ),
      regionKeyBuilder: (item) => item,
      regionLabelBuilder: (item) => item,
      currentDrillLevel: AppMapDrillLevel.state,
      style: style,
      preset: AppChartPreset.standard,
    );
  }
}

class _TestApp extends StatelessWidget {
  const _TestApp({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: AppTheme.light(),
      home: Scaffold(body: Center(child: child)),
    );
  }
}

final Uint8List _geoJsonBytes = Uint8List.fromList(
  utf8.encode(
    jsonEncode(<String, Object?>{
      'type': 'FeatureCollection',
      'features': <Object?>[
        <String, Object?>{
          'type': 'Feature',
          'properties': <String, String>{'UF': 'SP'},
          'geometry': <String, Object?>{
            'type': 'Polygon',
            'coordinates': <Object?>[
              <Object?>[
                <double>[-48, -24],
                <double>[-46, -24],
                <double>[-46, -22],
                <double>[-48, -22],
                <double>[-48, -24],
              ],
            ],
          },
        },
      ],
    }),
  ),
);
