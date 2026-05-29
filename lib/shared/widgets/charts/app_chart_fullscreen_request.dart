import 'package:flutter/material.dart';

/// App-agnostic description of a chart that wants to be presented full screen.
///
/// Shared chart widgets emit this request instead of depending on the app
/// router; the app layer maps it to its fullscreen route. This keeps the
/// `shared/` layer free of `app/` dependencies (DIP).
class AppChartFullscreenRequest {
  const AppChartFullscreenRequest({
    required this.chartBuilder,
    this.title,
    this.subtitle,
    this.semanticsLabel,
  });

  final WidgetBuilder chartBuilder;
  final String? title;
  final String? subtitle;
  final String? semanticsLabel;
}

/// Callback emitted by a shared chart to request a fullscreen presentation.
///
/// The [context] is the chart's own context, so callers do not need to capture
/// one separately.
typedef AppChartFullscreenRequestCallback =
    void Function(BuildContext context, AppChartFullscreenRequest request);
