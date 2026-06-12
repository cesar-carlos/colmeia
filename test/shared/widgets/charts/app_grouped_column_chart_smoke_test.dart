import 'package:colmeia/app/theme/app_theme.dart';
import 'package:colmeia/shared/widgets/charts/app_grouped_column_chart.dart';
import 'package:colmeia/shared/widgets/charts/app_grouped_column_chart_series.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

void main() {
  testWidgets('AppGroupedColumnChart mounts with sample series', (tester) async {
    final primaryFormat = NumberFormat.compact();
    final secondaryFormat = NumberFormat.compact();

    await tester.pumpWidget(
      _TestApp(
        child: SizedBox(
          width: 640,
          height: 320,
          child: AppGroupedColumnChart<_GroupedSamplePoint>(
            items: const <_GroupedSamplePoint>[
              _GroupedSamplePoint(label: 'Jan', primary: 120, secondary: 18),
              _GroupedSamplePoint(label: 'Feb', primary: 150, secondary: 22),
            ],
            xLabelBuilder: _groupedSampleLabel,
            series: <AppGroupedColumnChartSeries<_GroupedSamplePoint>>[
              AppGroupedColumnChartSeries<_GroupedSamplePoint>(
                name: 'Primary',
                color: Colors.blue,
                valueMapper: (point) => point.primary,
              ),
              AppGroupedColumnChartSeries<_GroupedSamplePoint>(
                name: 'Secondary',
                color: Colors.green,
                valueMapper: (point) => point.secondary,
                yAxis: AppGroupedColumnYAxis.secondary,
              ),
            ],
            primaryAxisFormat: primaryFormat,
            secondaryAxisFormat: secondaryFormat,
            height: 280,
            tooltipBuilder: _groupedTooltip,
          ),
        ),
      ),
    );

    expect(find.byType(AppGroupedColumnChart<_GroupedSamplePoint>), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 500));
  });
}

String _groupedSampleLabel(_GroupedSamplePoint point) => point.label;

Widget _groupedTooltip(
  dynamic data,
  dynamic point,
  dynamic series,
  int pointIndex,
  int seriesIndex,
) {
  return const SizedBox.shrink();
}

class _GroupedSamplePoint {
  const _GroupedSamplePoint({
    required this.label,
    required this.primary,
    required this.secondary,
  });

  final String label;
  final double primary;
  final double secondary;
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
