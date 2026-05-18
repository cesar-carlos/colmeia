import 'dart:convert';

import 'package:colmeia/app/theme/app_theme.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_presets.dart';
import 'package:colmeia/shared/widgets/charts/app_region_map_chart.dart';
import 'package:colmeia/shared/widgets/charts/engines/syncfusion_region_map_chart.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
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

  testWidgets('remounts SfMaps when marker points change', (tester) async {
    await tester.pumpWidget(const _TestApp(child: _MutableMarkerRegionMap()));

    final initialKey = tester.widget<SfMaps>(find.byType(SfMaps)).key;

    await tester.tap(find.byKey(const ValueKey<String>('add-marker')));
    await tester.pump();

    final updatedKey = tester.widget<SfMaps>(find.byType(SfMaps)).key;
    expect(updatedKey, isNot(initialKey));
  });

  testWidgets('keeps SfMaps mounted when only marker style changes', (
    tester,
  ) async {
    await tester.pumpWidget(const _TestApp(child: _MutableMarkerStyleMap()));

    final initialKey = tester.widget<SfMaps>(find.byType(SfMaps)).key;

    await tester.tap(find.byKey(const ValueKey<String>('change-marker-style')));
    await tester.pump();

    final updatedKey = tester.widget<SfMaps>(find.byType(SfMaps)).key;
    expect(updatedKey, initialKey);
  });

  testWidgets('remounts SfMaps when region metric values change', (
    tester,
  ) async {
    await tester.pumpWidget(const _TestApp(child: _MutableRegionMetricMap()));

    final initialKey = tester.widget<SfMaps>(find.byType(SfMaps)).key;

    await tester.tap(
      find.byKey(const ValueKey<String>('change-region-metric')),
    );
    await tester.pump();

    final updatedKey = tester.widget<SfMaps>(find.byType(SfMaps)).key;
    expect(updatedKey, isNot(initialKey));
  });

  testWidgets(
    'remounts SfMaps when marker coordinates change with same count',
    (
      tester,
    ) async {
      await tester.pumpWidget(
        const _TestApp(child: _MutableMarkerCoordinatesRegionMap()),
      );

      final initialKey = tester.widget<SfMaps>(find.byType(SfMaps)).key;

      await tester.tap(
        find.byKey(const ValueKey<String>('change-marker-coordinates')),
      );
      await tester.pump();

      final updatedKey = tester.widget<SfMaps>(find.byType(SfMaps)).key;
      expect(updatedKey, isNot(initialKey));
    },
  );

  testWidgets('zooms with mouse wheel on desktop when over the map', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    final viewports = <AppMapViewport>[];
    try {
      await tester.pumpWidget(
        _TestApp(
          child: _TestRegionMap(
            preset: AppChartPreset.explorable,
            style: const AppRegionMapChartStyle(
              height: 240,
              maxZoomLevel: 2,
            ),
            onViewportChanged: (event) => viewports.add(event.viewport),
          ),
        ),
      );

      await _sendPointerScrollOver(tester, find.byType(SfMaps), -120);

      expect(viewports, isNotEmpty);
      expect(viewports.last.zoomLevel, closeTo(1.35, 0.01));

      await _sendPointerScrollOver(tester, find.byType(SfMaps), 120);

      expect(viewports.last.zoomLevel, closeTo(1, 0.01));
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('mouse wheel zoom respects min and max zoom limits', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    final viewports = <AppMapViewport>[];
    try {
      await tester.pumpWidget(
        _TestApp(
          child: _TestRegionMap(
            preset: AppChartPreset.explorable,
            style: const AppRegionMapChartStyle(
              height: 240,
              maxZoomLevel: 1.4,
            ),
            onViewportChanged: (event) => viewports.add(event.viewport),
          ),
        ),
      );

      await _sendPointerScrollOver(tester, find.byType(SfMaps), -120);
      await _sendPointerScrollOver(tester, find.byType(SfMaps), -120);

      expect(viewports.last.zoomLevel, closeTo(1.4, 0.01));

      await _sendPointerScrollOver(tester, find.byType(SfMaps), 120);
      await _sendPointerScrollOver(tester, find.byType(SfMaps), 120);

      expect(viewports.last.zoomLevel, closeTo(1, 0.01));
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('keeps a map centering button available over the map', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    final viewports = <AppMapViewport>[];
    try {
      await tester.pumpWidget(
        _TestApp(
          child: _TestRegionMap(
            preset: AppChartPreset.explorable,
            preferredViewport: const AppMapViewport(
              zoomLevel: 1,
              centerLatitude: -23,
              centerLongitude: -47,
            ),
            style: const AppRegionMapChartStyle(
              height: 240,
              maxZoomLevel: 2,
            ),
            onViewportChanged: (event) => viewports.add(event.viewport),
          ),
        ),
      );
      await tester.pump();

      expect(find.byIcon(Icons.my_location_rounded), findsOneWidget);

      await _sendPointerScrollOver(tester, find.byType(SfMaps), -120);
      await tester.pump();
      await tester.pump();

      expect(viewports, isNotEmpty);
      expect(find.byIcon(Icons.my_location_rounded), findsOneWidget);

      await tester.tap(find.byIcon(Icons.my_location_rounded));
      await tester.pump();

      expect(find.byIcon(Icons.my_location_rounded), findsOneWidget);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('mouse wheel outside the map does not zoom the map', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    final viewports = <AppMapViewport>[];
    try {
      await tester.pumpWidget(
        _TestApp(
          child: Column(
            children: <Widget>[
              const SizedBox(
                key: ValueKey<String>('outside-map-area'),
                height: 80,
                width: 400,
              ),
              _TestRegionMap(
                preset: AppChartPreset.explorable,
                onViewportChanged: (event) => viewports.add(event.viewport),
              ),
            ],
          ),
        ),
      );

      await _sendPointerScrollOver(
        tester,
        find.byKey(const ValueKey<String>('outside-map-area')),
        -120,
      );

      expect(viewports, isEmpty);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('does not install mouse wheel listener on mobile', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    try {
      await tester.pumpWidget(
        const _TestApp(
          child: _TestRegionMap(
            preset: AppChartPreset.explorable,
          ),
        ),
      );

      expect(find.byType(SfMaps), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (widget) => widget is Listener && widget.onPointerSignal != null,
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
    this.points = const <AppMapPoint>[],
    this.preset = AppChartPreset.standard,
    this.preferredViewport,
    this.onViewportChanged,
  });

  final AppRegionMapChartStyle style;
  final List<AppMapPoint> points;
  final AppChartPreset preset;
  final AppMapViewport? preferredViewport;
  final ValueChanged<AppMapViewportChangedEvent>? onViewportChanged;

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
      preferredViewport: preferredViewport,
      style: style,
      preset: preset,
      points: points,
      onViewportChanged: onViewportChanged,
    );
  }
}

class _MutableMarkerRegionMap extends StatefulWidget {
  const _MutableMarkerRegionMap();

  @override
  State<_MutableMarkerRegionMap> createState() =>
      _MutableMarkerRegionMapState();
}

class _MutableMarkerRegionMapState extends State<_MutableMarkerRegionMap> {
  var _hasMarker = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ElevatedButton(
          key: const ValueKey<String>('add-marker'),
          onPressed: () {
            setState(() {
              _hasMarker = true;
            });
          },
          child: const Text('Add marker'),
        ),
        _TestRegionMap(
          points: _hasMarker
              ? const <AppMapPoint>[
                  AppMapPoint(latitude: -23, longitude: -47),
                ]
              : const <AppMapPoint>[],
        ),
      ],
    );
  }
}

class _MutableMarkerStyleMap extends StatefulWidget {
  const _MutableMarkerStyleMap();

  @override
  State<_MutableMarkerStyleMap> createState() => _MutableMarkerStyleMapState();
}

class _MutableMarkerStyleMapState extends State<_MutableMarkerStyleMap> {
  var _selected = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ElevatedButton(
          key: const ValueKey<String>('change-marker-style'),
          onPressed: () {
            setState(() {
              _selected = !_selected;
            });
          },
          child: const Text('Change marker style'),
        ),
        _TestRegionMap(
          points: <AppMapPoint>[
            AppMapPoint(
              latitude: -23,
              longitude: -47,
              style: AppMapMarkerStyle(
                size: _selected ? 18 : 10,
                color: _selected ? Colors.orange : Colors.blue,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _MutableRegionMetricMap extends StatefulWidget {
  const _MutableRegionMetricMap();

  @override
  State<_MutableRegionMetricMap> createState() =>
      _MutableRegionMetricMapState();
}

class _MutableRegionMetricMapState extends State<_MutableRegionMetricMap> {
  var _metricValue = 1.0;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        ElevatedButton(
          key: const ValueKey<String>('change-region-metric'),
          onPressed: () {
            setState(() {
              _metricValue = 12.0;
            });
          },
          child: const Text('Change region metric'),
        ),
        SyncfusionRegionMapChart<String>(
          items: const <String>['SP'],
          mapDefinition: AppMapDefinition.memory(
            sourceBytes: _geoJsonBytes,
            shapeDataField: 'UF',
            regionLevel: AppMapRegionLevel.state,
          ),
          metric: AppMapMetric<String>(
            key: 'revenue',
            label: 'Receita',
            valueBuilder: (_) => _metricValue,
          ),
          regionKeyBuilder: (item) => item,
          regionLabelBuilder: (item) => item,
          currentDrillLevel: AppMapDrillLevel.state,
          style: const AppRegionMapChartStyle(height: 240),
          preset: AppChartPreset.standard,
          points: const <AppMapPoint>[
            AppMapPoint(latitude: -23, longitude: -47),
          ],
        ),
      ],
    );
  }
}

class _MutableMarkerCoordinatesRegionMap extends StatefulWidget {
  const _MutableMarkerCoordinatesRegionMap();

  @override
  State<_MutableMarkerCoordinatesRegionMap> createState() =>
      _MutableMarkerCoordinatesRegionMapState();
}

class _MutableMarkerCoordinatesRegionMapState
    extends State<_MutableMarkerCoordinatesRegionMap> {
  var _latitude = -23.0;
  var _longitude = -47.0;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        ElevatedButton(
          key: const ValueKey<String>('change-marker-coordinates'),
          onPressed: () {
            setState(() {
              _latitude = -22.5;
              _longitude = -46.5;
            });
          },
          child: const Text('Change marker coordinates'),
        ),
        _TestRegionMap(
          points: <AppMapPoint>[
            AppMapPoint(latitude: _latitude, longitude: _longitude),
          ],
        ),
      ],
    );
  }
}

Future<void> _sendPointerScrollOver(
  WidgetTester tester,
  Finder finder,
  double dy,
) async {
  final position = tester.getCenter(finder);
  final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
  await gesture.addPointer(location: position);
  await gesture.moveTo(position);
  await tester.pump();
  await tester.sendEventToBinding(
    PointerScrollEvent(
      position: position,
      scrollDelta: Offset(0, dy),
    ),
  );
  await tester.pump();
  await gesture.removePointer();
}

class _TestApp extends StatelessWidget {
  const _TestApp({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: AppTheme.light(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
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
