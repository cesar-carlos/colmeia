import 'package:flutter/material.dart';

enum AppGroupedColumnYAxis { primary, secondary }

class AppGroupedColumnChartSeries<T> {
  const AppGroupedColumnChartSeries({
    required this.name,
    required this.color,
    required this.valueMapper,
    this.yAxis = AppGroupedColumnYAxis.primary,
  });

  final String name;
  final Color color;
  final double Function(T item) valueMapper;
  final AppGroupedColumnYAxis yAxis;
}

class AppGroupedColumnChartLayout {
  const AppGroupedColumnChartLayout._();

  static const double defaultCategorySlotWidth = 72;
  static const double defaultHorizontalPadding = 24;
  static const double defaultMinPlotWidth = 560;
}
