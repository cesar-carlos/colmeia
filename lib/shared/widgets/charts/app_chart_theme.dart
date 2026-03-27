import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_presets.dart';
import 'package:flutter/material.dart';

class AppChartTheme {
  const AppChartTheme({
    required this.height,
    required this.primaryColor,
    required this.gradient,
    required this.enableSelectionZooming,
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

    return AppChartTheme(
      height: height,
      primaryColor: primaryColor,
      gradient: gradient,
      enableSelectionZooming: preset == AppChartPreset.explorable,
    );
  }

  final double height;
  final Color primaryColor;
  final LinearGradient gradient;
  final bool enableSelectionZooming;
}
