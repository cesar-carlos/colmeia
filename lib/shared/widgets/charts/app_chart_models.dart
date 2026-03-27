class AppChartPoint {
  const AppChartPoint({
    required this.label,
    required this.value,
  });

  final String label;
  final num value;
}

class AppChartSeries {
  const AppChartSeries({
    required this.id,
    required this.points,
  });

  final String id;
  final List<AppChartPoint> points;
}
