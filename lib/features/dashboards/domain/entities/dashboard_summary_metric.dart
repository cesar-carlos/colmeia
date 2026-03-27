enum DashboardSummaryMetricIcon {
  trendingUp,
  trendingDown,
  receiptLong,
  payments,
  insights,
  ;

  String get wireName => switch (this) {
    DashboardSummaryMetricIcon.trendingUp => 'trending_up',
    DashboardSummaryMetricIcon.trendingDown => 'trending_down',
    DashboardSummaryMetricIcon.receiptLong => 'receipt_long',
    DashboardSummaryMetricIcon.payments => 'payments',
    DashboardSummaryMetricIcon.insights => 'insights',
  };

  static DashboardSummaryMetricIcon fromWireName(String iconName) {
    return switch (iconName) {
      'trending_up' => DashboardSummaryMetricIcon.trendingUp,
      'trending_down' => DashboardSummaryMetricIcon.trendingDown,
      'receipt_long' => DashboardSummaryMetricIcon.receiptLong,
      'payments' => DashboardSummaryMetricIcon.payments,
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
