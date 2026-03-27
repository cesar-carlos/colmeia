enum DashboardSummaryMetricIcon {
  trendingUp,
  receiptLong,
  insights
  ;

  String get wireName => switch (this) {
    DashboardSummaryMetricIcon.trendingUp => 'trending_up',
    DashboardSummaryMetricIcon.receiptLong => 'receipt_long',
    DashboardSummaryMetricIcon.insights => 'insights',
  };

  static DashboardSummaryMetricIcon fromWireName(String iconName) {
    return switch (iconName) {
      'trending_up' => DashboardSummaryMetricIcon.trendingUp,
      'receipt_long' => DashboardSummaryMetricIcon.receiptLong,
      _ => DashboardSummaryMetricIcon.insights,
    };
  }
}

class DashboardSummaryMetric {
  const DashboardSummaryMetric({
    required this.title,
    required this.value,
    required this.deltaLabel,
    required this.icon,
  });

  final String title;
  final String value;
  final String deltaLabel;
  final DashboardSummaryMetricIcon icon;
}
