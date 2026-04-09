enum OverviewSummaryMetricIcon {
  trendingUp,
  trendingDown,
  receiptLong,
  payments,
  insights,
  ;

  String get wireName => switch (this) {
    OverviewSummaryMetricIcon.trendingUp => 'trending_up',
    OverviewSummaryMetricIcon.trendingDown => 'trending_down',
    OverviewSummaryMetricIcon.receiptLong => 'receipt_long',
    OverviewSummaryMetricIcon.payments => 'payments',
    OverviewSummaryMetricIcon.insights => 'insights',
  };

  static OverviewSummaryMetricIcon fromWireName(String iconName) {
    return switch (iconName) {
      'trending_up' => OverviewSummaryMetricIcon.trendingUp,
      'trending_down' => OverviewSummaryMetricIcon.trendingDown,
      'receipt_long' => OverviewSummaryMetricIcon.receiptLong,
      'payments' => OverviewSummaryMetricIcon.payments,
      _ => OverviewSummaryMetricIcon.insights,
    };
  }
}

class OverviewSummaryMetric {
  const OverviewSummaryMetric({
    required this.title,
    required this.value,
    required this.icon,
    this.deltaLabel,
  });

  final String title;
  final String value;
  final String? deltaLabel;
  final OverviewSummaryMetricIcon icon;
}
