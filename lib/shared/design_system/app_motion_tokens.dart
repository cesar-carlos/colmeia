import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

/// Motion tokens for the Hive design system: durations, easing curves, and
/// composable helpers for staged dashboard entrances.
///
/// Centralizes values that previously lived as local constants in
/// `app_chart_fade_in.dart`, `overview_home_charts_below_kpis.dart`, and the
/// sales monthly P&L cards. Consumers read these from the active theme via
/// `Theme.of(context).extension<AppMotionTokens>()` (or `context.appMotion`
/// from the extension below) so the values stay editable in one place and
/// future themes (e.g. reduced-motion variant) can swap them via
/// [ThemeData.extensions].
class AppMotionTokens extends ThemeExtension<AppMotionTokens> {
  const AppMotionTokens({
    required this.chartFadeIn,
    required this.chartFadeInSlideOffsetPx,
    required this.chartFadeInCurve,
    required this.chartSeriesAnimation,
    required this.dashboardStageDelayBase,
    required this.dashboardStageDelayStep,
  });

  /// Default tokens used by all themes today. Kept as a single source so the
  /// light/dark themes do not drift in motion values.
  static const AppMotionTokens standard = AppMotionTokens(
    chartFadeIn: Duration(milliseconds: 220),
    chartFadeInSlideOffsetPx: 6,
    chartFadeInCurve: Curves.easeOutCubic,
    chartSeriesAnimation: Duration(milliseconds: 150),
    dashboardStageDelayBase: Duration.zero,
    dashboardStageDelayStep: Duration(milliseconds: 40),
  );

  /// Fade-in duration used by `AppChartFadeIn` and any chart card that opts
  /// into a one-shot entrance animation.
  final Duration chartFadeIn;

  /// Initial vertical translate (in logical pixels) applied while the fade-in
  /// is in flight. Set the value to `0` in a custom theme to disable the
  /// slide and use fade-only.
  final double chartFadeInSlideOffsetPx;

  /// Easing applied to [chartFadeIn].
  final Curve chartFadeInCurve;

  /// Default Syncfusion series animation duration (used by overview and sales
  /// monthly P&L percent charts).
  final Duration chartSeriesAnimation;

  /// First skeleton `showDelay` for staged dashboard mounts. Combined with
  /// [dashboardStageDelayStep] via [dashboardStageDelay].
  final Duration dashboardStageDelayBase;

  /// Additive step between successive staged sections in dashboards.
  final Duration dashboardStageDelayStep;

  /// Stagger helper. `dashboardStageDelay(0)` returns the base, `(1)` adds
  /// one step, and so on. Designed for consumers that iterate over a list
  /// of section descriptors.
  Duration dashboardStageDelay(int index) {
    if (index <= 0) {
      return dashboardStageDelayBase;
    }
    return dashboardStageDelayBase + dashboardStageDelayStep * index;
  }

  @override
  AppMotionTokens copyWith({
    Duration? chartFadeIn,
    double? chartFadeInSlideOffsetPx,
    Curve? chartFadeInCurve,
    Duration? chartSeriesAnimation,
    Duration? dashboardStageDelayBase,
    Duration? dashboardStageDelayStep,
  }) {
    return AppMotionTokens(
      chartFadeIn: chartFadeIn ?? this.chartFadeIn,
      chartFadeInSlideOffsetPx:
          chartFadeInSlideOffsetPx ?? this.chartFadeInSlideOffsetPx,
      chartFadeInCurve: chartFadeInCurve ?? this.chartFadeInCurve,
      chartSeriesAnimation: chartSeriesAnimation ?? this.chartSeriesAnimation,
      dashboardStageDelayBase:
          dashboardStageDelayBase ?? this.dashboardStageDelayBase,
      dashboardStageDelayStep:
          dashboardStageDelayStep ?? this.dashboardStageDelayStep,
    );
  }

  @override
  AppMotionTokens lerp(ThemeExtension<AppMotionTokens>? other, double t) {
    if (other is! AppMotionTokens) {
      return this;
    }
    return AppMotionTokens(
      chartFadeIn: _lerpDuration(chartFadeIn, other.chartFadeIn, t),
      chartFadeInSlideOffsetPx: lerpDouble(
            chartFadeInSlideOffsetPx,
            other.chartFadeInSlideOffsetPx,
            t,
          ) ??
          chartFadeInSlideOffsetPx,
      // Curves are not numerically interpolatable; snap to the target half-way
      // through to avoid mixing easing shapes.
      chartFadeInCurve: t < 0.5 ? chartFadeInCurve : other.chartFadeInCurve,
      chartSeriesAnimation: _lerpDuration(
        chartSeriesAnimation,
        other.chartSeriesAnimation,
        t,
      ),
      dashboardStageDelayBase: _lerpDuration(
        dashboardStageDelayBase,
        other.dashboardStageDelayBase,
        t,
      ),
      dashboardStageDelayStep: _lerpDuration(
        dashboardStageDelayStep,
        other.dashboardStageDelayStep,
        t,
      ),
    );
  }

  static Duration _lerpDuration(Duration a, Duration b, double t) {
    final ms = lerpDouble(
      a.inMicroseconds.toDouble(),
      b.inMicroseconds.toDouble(),
      t,
    );
    if (ms == null) {
      return a;
    }
    return Duration(microseconds: ms.round());
  }
}

extension AppMotionTokensThemeDataX on ThemeData {
  /// Resolves the active motion tokens, falling back to
  /// [AppMotionTokens.standard] when no extension is registered (covers
  /// stand-alone tests that instantiate a bare [ThemeData]).
  AppMotionTokens get appMotion =>
      extension<AppMotionTokens>() ?? AppMotionTokens.standard;
}

extension AppMotionTokensBuildContextX on BuildContext {
  AppMotionTokens get appMotion => Theme.of(this).appMotion;
}
