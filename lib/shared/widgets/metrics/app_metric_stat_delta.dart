import 'package:colmeia/shared/design_system/app_colors.dart';
import 'package:flutter/material.dart';

/// Semantic sign of a KPI delta string for styling (colors, pill).
enum MetricDeltaSign {
  negative,
  neutral,
  positive,
}

/// Leading icon for KPI delta rows (stacked metric card trend line).
IconData metricDeltaTrendIcon(MetricDeltaSign sign) {
  return switch (sign) {
    MetricDeltaSign.negative => Icons.trending_down_rounded,
    MetricDeltaSign.neutral => Icons.horizontal_rule_rounded,
    MetricDeltaSign.positive => Icons.trending_up_rounded,
  };
}

/// Splits a trend line into a leading delta segment and an optional comparison
/// suffix after ` vs ` (case-insensitive), for two-tone typography.
({String primary, String? suffix}) splitMetricTrendLabel(String raw) {
  final trimmed = raw.trim();
  final match = RegExp(r'\s+vs\s+', caseSensitive: false).firstMatch(trimmed);
  if (match == null) {
    return (primary: trimmed, suffix: null);
  }
  final primary = trimmed.substring(0, match.start).trim();
  final suffix = trimmed.substring(match.start).trim();
  if (primary.isEmpty) {
    return (primary: trimmed, suffix: null);
  }
  return (primary: primary, suffix: suffix);
}

/// Parses [raw] delta text for KPI trend badges.
///
/// Negative values start with ASCII `-` or Unicode minus `−`. Values that
/// resolve numerically to zero (e.g. `+0%`, `-0,0%`) are neutral
/// ([MetricDeltaSign.neutral]).
/// Em-dash / en-dash only, `=`, and `≈` are treated as neutral.
MetricDeltaSign parseMetricDeltaSign(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) {
    return MetricDeltaSign.neutral;
  }
  if (trimmed == '—' || trimmed == '–' || trimmed == '=' || trimmed == '≈') {
    return MetricDeltaSign.neutral;
  }
  if (isZeroDeltaString(trimmed)) {
    return MetricDeltaSign.neutral;
  }
  if (trimmed.startsWith('-') || trimmed.startsWith('−')) {
    return MetricDeltaSign.negative;
  }
  return MetricDeltaSign.positive;
}

/// Whether [raw] represents a zero delta (after optional leading sign).
bool isZeroDeltaString(String raw) {
  var t = raw.trim();
  if (t.isEmpty) {
    return true;
  }
  if (t.startsWith('+') || t.startsWith('-') || t.startsWith('−')) {
    t = t.substring(1).trim();
  }
  final match = RegExp(r'(\d+[,.]?\d*)').firstMatch(t);
  if (match == null) {
    return false;
  }
  final numStr = match.group(1)!.replaceAll(',', '.');
  final v = double.tryParse(numStr);
  if (v == null) {
    return false;
  }
  return v.abs() < 0.0001;
}

/// Foreground for plain trend text (non-pill).
Color metricDeltaForeground(AppColors colors, MetricDeltaSign sign) {
  return switch (sign) {
    MetricDeltaSign.negative => colors.error,
    MetricDeltaSign.neutral => colors.onSurfaceVariant,
    MetricDeltaSign.positive => colors.tertiary,
  };
}

/// Soft pill background for the trend badge.
Color metricDeltaPillBackground(AppColors colors, MetricDeltaSign sign) {
  return switch (sign) {
    MetricDeltaSign.negative => Color.alphaBlend(
      colors.errorContainer.withValues(alpha: 0.85),
      colors.surfaceContainerLowest,
    ),
    MetricDeltaSign.neutral => Color.alphaBlend(
      colors.surfaceContainerHighest.withValues(alpha: 0.9),
      colors.surfaceContainerLowest,
    ),
    MetricDeltaSign.positive => Color.alphaBlend(
      colors.tertiaryContainer.withValues(alpha: 0.75),
      colors.surfaceContainerLowest,
    ),
  };
}

/// Text color on top of [metricDeltaPillBackground].
Color metricDeltaPillForeground(AppColors colors, MetricDeltaSign sign) {
  return switch (sign) {
    MetricDeltaSign.negative => colors.onErrorContainer,
    MetricDeltaSign.neutral => colors.onSurfaceVariant,
    MetricDeltaSign.positive => colors.onTertiaryContainer,
  };
}
