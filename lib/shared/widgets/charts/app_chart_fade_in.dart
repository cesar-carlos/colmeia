import 'package:colmeia/shared/design_system/app_motion_tokens.dart';
import 'package:flutter/material.dart';

/// Plays a one-shot fade + subtle slide-up the first time the wrapped chart
/// (or any heavy widget) is mounted.
///
/// The animation runs once when the element is first inserted and then stays
/// at the final state — Flutter preserves the [TweenAnimationBuilder] state
/// across rebuilds whenever the surrounding element identity does not change
/// (for example sibling cards in the overview staged mounter advancing their
/// own pipeline).
///
/// Respects the OS reduce-motion preference via
/// [MediaQueryData.disableAnimations] — when enabled, the [child] is rendered
/// immediately without any opacity/translate work.
///
/// Defaults (`duration`, `slideOffsetPx`, `curve`) come from
/// [AppMotionTokens] resolved from the active theme so charts across the app
/// share the same entrance treatment.
class AppChartFadeIn extends StatelessWidget {
  const AppChartFadeIn({
    required this.child,
    super.key,
    this.duration,
    this.slideOffsetPx,
    this.curve,
  });

  final Widget child;

  /// Overrides [AppMotionTokens.chartFadeIn] when provided.
  final Duration? duration;

  /// Overrides [AppMotionTokens.chartFadeInSlideOffsetPx]. Set to `0` to
  /// disable the slide and use fade-only.
  final double? slideOffsetPx;

  /// Overrides [AppMotionTokens.chartFadeInCurve].
  final Curve? curve;

  @override
  Widget build(BuildContext context) {
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reduceMotion) {
      return child;
    }
    final motion = context.appMotion;
    final resolvedDuration = duration ?? motion.chartFadeIn;
    final resolvedSlide = slideOffsetPx ?? motion.chartFadeInSlideOffsetPx;
    final resolvedCurve = curve ?? motion.chartFadeInCurve;
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: resolvedDuration,
      curve: resolvedCurve,
      builder: (context, t, c) {
        if (resolvedSlide == 0) {
          return Opacity(opacity: t, child: c);
        }
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, (1 - t) * resolvedSlide),
            child: c,
          ),
        );
      },
      child: child,
    );
  }
}
