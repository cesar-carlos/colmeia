class DashboardCategoryShare {
  const DashboardCategoryShare({
    required this.label,
    required this.percent,
  });

  final String label;

  /// Share in the 0–100 range.
  final double percent;
}
