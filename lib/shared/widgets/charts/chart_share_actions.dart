import 'package:colmeia/shared/widgets/charts/app_chart_fullscreen_request.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_share_request.dart';
import 'package:colmeia/shared/widgets/charts/chart_share_metadata.dart';
import 'package:flutter/material.dart';

/// Encapsulates share and fullscreen emitters for chart widgets.
///
/// Keeps feature/shared chart widgets decoupled from `app/` by routing through
/// the app-agnostic callback pattern (composition, not widget inheritance).
class ChartShareActions {
  const ChartShareActions({
    required this.context,
    required this.captureKey,
    required this.metadata,
    this.onRequestShare,
    this.onRequestFullscreen,
    this.shareEnabled = true,
  });

  final BuildContext context;
  final GlobalKey captureKey;
  final ChartShareMetadata metadata;
  final AppChartShareRequestCallback? onRequestShare;
  final AppChartFullscreenRequestCallback? onRequestFullscreen;
  final bool shareEnabled;

  void openShare() {
    if (!shareEnabled) {
      return;
    }
    final emit = onRequestShare;
    if (emit == null) {
      return;
    }
    emit(context, metadata.toShareRequest(captureKey));
  }

  void openFullscreen(AppChartFullscreenRequest request) {
    final emit = onRequestFullscreen;
    if (emit == null) {
      return;
    }
    emit(context, request);
  }

  VoidCallback? shareCallback({bool? enabled}) {
    final resolvedEnabled = enabled ?? shareEnabled;
    if (onRequestShare == null || !resolvedEnabled) {
      return null;
    }
    return openShare;
  }

  VoidCallback? fullscreenCallback(VoidCallback openFullscreen) {
    if (onRequestFullscreen == null) {
      return null;
    }
    return openFullscreen;
  }
}
