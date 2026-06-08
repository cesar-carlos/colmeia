import 'package:colmeia/shared/widgets/app_skeleton.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_fade_in.dart';
import 'package:flutter/material.dart';

enum OverviewChartStageVisualState {
  skeletonWithChart,
  placeholder,
  ready,
}

/// Shared staged loading wrapper for overview home and chart detail surfaces.
class OverviewChartStagedBlock extends StatelessWidget {
  const OverviewChartStagedBlock({
    required this.visualState,
    required this.loadingSemanticsLabel,
    required this.showDelay,
    required this.child,
    super.key,
    this.placeholderHeight,
  });

  final OverviewChartStageVisualState visualState;
  final Duration showDelay;
  final String loadingSemanticsLabel;
  final Widget child;
  final double? placeholderHeight;

  @override
  Widget build(BuildContext context) {
    switch (visualState) {
      case OverviewChartStageVisualState.skeletonWithChart:
        return AppSkeleton(
          enabled: true,
          showDelay: showDelay,
          loadingSemanticsLabel: loadingSemanticsLabel,
          child: child,
        );
      case OverviewChartStageVisualState.placeholder:
        return AppSkeleton(
          enabled: true,
          showDelay: showDelay,
          loadingSemanticsLabel: loadingSemanticsLabel,
          child: SizedBox(height: placeholderHeight),
        );
      case OverviewChartStageVisualState.ready:
        return AppSkeleton(
          enabled: false,
          showDelay: showDelay,
          loadingSemanticsLabel: loadingSemanticsLabel,
          child: AppChartFadeIn(
            child: RepaintBoundary(child: child),
          ),
        );
    }
  }
}
