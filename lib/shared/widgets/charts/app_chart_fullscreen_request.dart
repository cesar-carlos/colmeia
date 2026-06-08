import 'package:colmeia/shared/widgets/charts/chart_share_metadata.dart';
import 'package:colmeia/shared/widgets/charts/chart_share_table_data.dart';
import 'package:flutter/material.dart';

/// App-agnostic description of a chart that wants to be presented full screen.
///
/// Shared chart widgets emit this request instead of depending on the app
/// router; the app layer maps it to its fullscreen route. This keeps the
/// `shared/` layer free of `app/` dependencies (DIP).
typedef AppChartFullscreenHeaderTrailingBuilder =
    Widget Function(BuildContext context, GlobalKey shareCaptureKey);

class AppChartFullscreenRequest {
  const AppChartFullscreenRequest({
    required this.chartBuilder,
    this.title,
    this.subtitle,
    this.filterSummary,
    this.tableData,
    this.shareMetadata,
    this.semanticsLabel,
    this.shareCaptureKey,
    this.shareSubject,
    this.headerTrailingBuilder,
  });

  final WidgetBuilder chartBuilder;
  final String? title;
  final String? subtitle;
  final String? filterSummary;
  final ChartShareTableData? tableData;
  final ChartShareMetadata? shareMetadata;
  final String? semanticsLabel;

  /// When set with [shareSubject], enables share from the fullscreen scaffold.
  final GlobalKey? shareCaptureKey;
  final String? shareSubject;

  /// Optional trailing actions for the fullscreen scaffold header.
  ///
  /// When [shareCaptureKey] is provided, the app layer also injects a share
  /// action unless this builder fully replaces that behavior.
  final AppChartFullscreenHeaderTrailingBuilder? headerTrailingBuilder;

  ChartShareMetadata resolveShareMetadata() {
    final metadata = shareMetadata;
    if (metadata != null) {
      return metadata;
    }
    return ChartShareMetadata(
      title: shareSubject ?? title ?? 'chart',
      subtitle: subtitle,
      filterSummary: filterSummary,
      tableData: tableData,
      subject: shareSubject,
    );
  }
}

/// Callback emitted by a shared chart to request a fullscreen presentation.
///
/// The [context] is the chart's own context, so callers do not need to capture
/// one separately.
typedef AppChartFullscreenRequestCallback =
    void Function(BuildContext context, AppChartFullscreenRequest request);
