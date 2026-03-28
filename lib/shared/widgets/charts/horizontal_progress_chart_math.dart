/// Controls how the trailing value label is formatted.
enum AppHorizontalProgressValueLabelMode {
  /// Uses percent when the row maximum is close to `100`.
  auto,

  /// Always formats as percentage.
  percent,

  /// Always formats as a plain number.
  number,
}

const double _percentScaleEpsilon = 0.0001;
const double _integerTolerance = 0.0001;

/// Pure helpers for horizontal progress charts (bar fill + default value text).
double normalizedHorizontalProgress({
  required double rawValue,
  required double maxValue,
}) {
  final safeRawValue = sanitizeHorizontalProgressNumber(rawValue);
  final safeMaxValue = sanitizeHorizontalProgressNumber(maxValue);
  if (safeMaxValue <= 0) {
    return 0;
  }
  return (safeRawValue / safeMaxValue).clamp(0.0, 1.0);
}

/// Makes chart calculations resilient to `NaN` / `Infinity`.
double sanitizeHorizontalProgressNumber(
  double value, {
  double fallback = 0,
}) {
  return value.isFinite ? value : fallback;
}

/// Default text for the trailing value column.
///
/// When [rowMaxValue] is `100`, [displayValue] is shown as a percentage.
/// Otherwise it is shown as a compact number (0 or 1 decimal place).
String defaultHorizontalProgressValueLabel({
  required double displayValue,
  required double rowMaxValue,
  AppHorizontalProgressValueLabelMode mode =
      AppHorizontalProgressValueLabelMode.auto,
}) {
  final safeDisplayValue = sanitizeHorizontalProgressNumber(displayValue);
  final safeRowMaxValue = sanitizeHorizontalProgressNumber(rowMaxValue);
  final shouldFormatAsPercent = switch (mode) {
    AppHorizontalProgressValueLabelMode.percent => true,
    AppHorizontalProgressValueLabelMode.number => false,
    AppHorizontalProgressValueLabelMode.auto =>
      (safeRowMaxValue - 100).abs() < _percentScaleEpsilon,
  };

  if (shouldFormatAsPercent) {
    return safeDisplayValue >= 10
        ? '${safeDisplayValue.round()}%'
        : '${safeDisplayValue.toStringAsFixed(1)}%';
  }

  final rounded = safeDisplayValue.roundToDouble();
  final looksInteger = (safeDisplayValue - rounded).abs() < _integerTolerance;
  return looksInteger
      ? rounded.toStringAsFixed(0)
      : safeDisplayValue.toStringAsFixed(1);
}
