class OverviewCategoryShare {
  const OverviewCategoryShare({
    required this.label,
    required this.percent,
    this.amount,
  });

  final String label;

  /// Share in the 0–100 range.
  final double percent;

  /// Revenue (or other weight) for this category when the API sends it.
  /// When every row in a list has [amount], the donut uses real weights.
  final double? amount;
}
