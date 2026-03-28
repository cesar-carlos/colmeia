import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_presets.dart';
import 'package:flutter/material.dart';

class AppChartTheme {
  const AppChartTheme({
    required this.height,
    required this.primaryColor,
    required this.gradient,
    required this.enableSelectionZooming,
    required this.palette,
  });

  factory AppChartTheme.fromContext(
    BuildContext context, {
    required AppChartPreset preset,
  }) {
    final tokens = Theme.of(context).extension<AppThemeTokens>()!;
    final height = switch (preset) {
      AppChartPreset.compact => tokens.chartCompactHeight,
      AppChartPreset.standard => tokens.chartStandardHeight,
      AppChartPreset.explorable => tokens.chartStandardHeight,
    };

    final primaryColor = tokens.chartSeriesPrimary;
    final gradient = LinearGradient(
      colors: <Color>[
        primaryColor.withValues(alpha: 0.35),
        primaryColor.withValues(alpha: 0.05),
      ],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    );

    final palette = <Color>[
      tokens.chartSeriesPrimary,
      tokens.chartSeriesSecondary,
      tokens.chartSeriesTertiary,
      tokens.chartSeriesPrimary.withValues(alpha: 0.55),
      tokens.chartSeriesSecondary.withValues(alpha: 0.55),
    ];

    return AppChartTheme(
      height: height,
      primaryColor: primaryColor,
      gradient: gradient,
      enableSelectionZooming: preset == AppChartPreset.explorable,
      palette: palette,
    );
  }

  final double height;
  final Color primaryColor;
  final LinearGradient gradient;
  final bool enableSelectionZooming;

  /// Ordered color palette for multi-series charts. Wraps around when the
  /// series count exceeds the palette length.
  final List<Color> palette;

  /// Returns the palette color at [index], wrapping around if needed.
  Color paletteColor(int index) => palette[index % palette.length];
}
