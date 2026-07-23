import 'package:colmeia/shared/widgets/charts/app_chart_fullscreen_request.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_share_request.dart';
import 'package:colmeia/shared/widgets/charts/chart_share_metadata.dart';
import 'package:flutter/material.dart';

/// Encapsulates share and fullscreen emitters for chart widgets.
///
/// Keeps feature/shared chart widgets decoupled from `app/` by routing through
/// the app-agnostic callback pattern (composition, not widget inheritance).
///
/// Prefer [metadataBuilder] when building the table/PDF payload is non-trivial:
/// the work then runs only when the user opens share, not on every rebuild.
class ChartShareActions {
  const ChartShareActions({
    required this.context,
    required this.captureKey,
    this.metadata,
    this.metadataBuilder,
    this.onRequestShare,
    this.onRequestFullscreen,
    this.shareEnabled = true,
  }) : assert(
         metadata != null || metadataBuilder != null,
         'Provide metadata or metadataBuilder.',
       );

  final BuildContext context;
  final GlobalKey captureKey;
  final ChartShareMetadata? metadata;
  final ChartShareMetadata Function()? metadataBuilder;
  final AppChartShareRequestCallback? onRequestShare;
  final AppChartFullscreenRequestCallback? onRequestFullscreen;
  final bool shareEnabled;

  ChartShareMetadata get _resolvedMetadata {
    final built = metadataBuilder?.call();
    return built ?? metadata!;
  }

  void openShare() {
    if (!shareEnabled) {
      return;
    }
    final emit = onRequestShare;
    if (emit == null) {
      return;
    }
    emit(context, _resolvedMetadata.toShareRequest(captureKey));
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
