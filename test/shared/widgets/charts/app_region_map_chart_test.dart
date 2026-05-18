import 'dart:convert';
import 'dart:typed_data';

import 'package:colmeia/app/theme/app_theme.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/widgets/charts/app_region_map_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('uses localized default chrome labels in portuguese', (
    tester,
  ) async {
    await _pumpRegionChart(
      tester,
      scopeOptions: const <AppMapScopeOption>[
        AppMapScopeOption(key: 'SE', label: 'Sudeste'),
      ],
      currentDrillLevel: AppMapDrillLevel.state,
      onDrillUpRequested: (_) {},
    );

    expect(find.text('MÉTRICA'), findsOneWidget);
    expect(find.text('ESCOPO'), findsOneWidget);
    expect(find.text('Todas as regiões'), findsOneWidget);
    expect(find.text('Voltar para regiões'), findsOneWidget);
    expect(find.bySemanticsLabel('Métrica do mapa'), findsOneWidget);
    expect(find.bySemanticsLabel('Escopo territorial'), findsOneWidget);
  });

  testWidgets('uses localized default loading label in english', (
    tester,
  ) async {
    await _pumpRegionChart(
      tester,
      locale: const Locale('en'),
      isLoading: true,
    );

    expect(find.text('Loading map…'), findsOneWidget);
  });

  testWidgets('uses localized default empty label in english', (tester) async {
    await _pumpRegionChart(
      tester,
      locale: const Locale('en'),
      items: const <String>[],
    );

    expect(find.text('No territorial data to show.'), findsOneWidget);
  });
}

Future<void> _pumpRegionChart(
  WidgetTester tester, {
  Locale locale = const Locale('pt', 'BR'),
  List<String> items = const <String>['SP'],
  List<AppMapScopeOption> scopeOptions = const <AppMapScopeOption>[],
  AppMapDrillLevel currentDrillLevel = AppMapDrillLevel.region,
  ValueChanged<AppMapDrillUpEvent>? onDrillUpRequested,
  bool isLoading = false,
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
            width: 480,
            child: AppRegionMapChart<String>(
              items: items,
              mapDefinition: AppMapDefinition.memory(
                sourceBytes: _geoJsonBytes,
                shapeDataField: 'UF',
                regionLevel: AppMapRegionLevel.state,
              ),
              metrics: const <AppMapMetric<String>>[
                AppMapMetric<String>(
                  key: 'revenue',
                  label: 'Revenue',
                  valueBuilder: _constantMetricValue,
                ),
                AppMapMetric<String>(
                  key: 'sales',
                  label: 'Sales',
                  valueBuilder: _constantMetricValue,
                ),
              ],
              regionKeyBuilder: _regionKey,
              regionLabelBuilder: _regionLabel,
              scopeOptions: scopeOptions,
              currentDrillLevel: currentDrillLevel,
              onScopeChanged: scopeOptions.isEmpty ? null : (_) {},
              onDrillUpRequested: onDrillUpRequested,
              isLoading: isLoading,
              style: const AppRegionMapChartStyle(height: 240),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

String _regionKey(String item) => item;

String _regionLabel(String item) => item;

num _constantMetricValue(String item) => 1;

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
                <num>[-48, -24.5],
                <num>[-44, -24.5],
                <num>[-44, -20],
                <num>[-48, -20],
                <num>[-48, -24.5],
              ],
            ],
          },
        },
      ],
    }),
  ),
);
