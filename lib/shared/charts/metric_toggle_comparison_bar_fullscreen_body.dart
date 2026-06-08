import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:flutter/material.dart';

/// Shared fullscreen body layout: metric toggle on top, fixed-height chart below.
///
/// Used by daily and weekday sales trend charts to avoid duplicating the
/// [LayoutBuilder] height math in every fullscreen route.
Widget buildMetricToggleComparisonBarFullscreenBody({
  required AppThemeTokens tokens,
  required Widget metricToggle,
  required Widget Function(double availableChartHeight) chartBuilder,
}) {
  return LayoutBuilder(
    builder: (context, constraints) {
      final availableChartHeight =
          (constraints.maxHeight - tokens.contentSpacing - 48)
              .clamp(220.0, constraints.maxHeight);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          metricToggle,
          SizedBox(height: tokens.contentSpacing),
          SizedBox(
            height: availableChartHeight,
            child: chartBuilder(availableChartHeight),
          ),
        ],
      );
    },
  );
}
