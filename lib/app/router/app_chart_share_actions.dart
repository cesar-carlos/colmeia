import 'dart:async';

import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_capture_helper.dart';
import 'package:colmeia/shared/widgets/charts/chart_share_action_icon.dart';
import 'package:colmeia/shared/widgets/charts/chart_share_result.dart';
import 'package:colmeia/shared/widgets/charts/chart_share_table_data.dart';
import 'package:flutter/material.dart';

/// Captures [shareKey], builds a PDF, and opens the share sheet.
Future<void> shareChartCapture(
  BuildContext context,
  GlobalKey shareKey, {
  String? subject,
  String? title,
  String? subtitle,
  String? filterSummary,
  ChartShareTableData? tableData,
}) async {
  final result = await captureAndShareChart(
    shareKey,
    subject: subject,
    title: title ?? subject,
    subtitle: subtitle,
    filterSummary: filterSummary,
    tableData: tableData,
  );
  if (!context.mounted) {
    return;
  }
  if (result is ChartShareFailure) {
    final l10n = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.chartShareFailed)),
    );
  }
}

/// Share action for fullscreen chart scaffolds (header trailing slot).
Widget buildChartFullscreenShareTrailing({
  required BuildContext context,
  required GlobalKey shareKey,
  required String subject,
  String? subtitle,
  String? filterSummary,
  ChartShareTableData? tableData,
}) {
  final l10n = AppLocalizations.of(context);
  return IconButton(
    onPressed: () => unawaited(
      shareChartCapture(
        context,
        shareKey,
        subject: subject,
        title: subject,
        subtitle: subtitle,
        filterSummary: filterSummary,
        tableData: tableData,
      ),
    ),
    tooltip: l10n.chartShareTooltip,
    icon: Icon(chartShareActionIcon()),
  );
}
