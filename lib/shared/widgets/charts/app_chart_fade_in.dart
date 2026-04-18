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
/// Originated as the private `_StagedFadeIn` widget inside the overview home
/// staged mounter; promoted to the design-system layer so any consumer chart
/// card (overview, agent reports, future dashboards) can opt into the same
/// entrance treatment.
class AppChartFadeIn extends StatelessWidget {
  const AppChartFadeIn({
    required this.child,
    super.key,
    this.duration = const Duration(milliseconds: 220),
    this.slideOffsetPx = 6,
    this.curve = Curves.easeOutCubic,
  });

  final Widget child;

  /// Total tween duration. Default `220 ms` matches the value used by the
  /// overview home staged mounter.
  final Duration duration;

  /// Initial vertical offset (in logical pixels) — the child slides up this
  /// many pixels while fading in. Set to `0` to disable the slide and use
  /// fade-only.
  final double slideOffsetPx;

  /// Easing applied to the fade + translate.
  final Curve curve;

  @override
  Widget build(BuildContext context) {
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reduceMotion) {
      return child;
    }
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: duration,
      curve: curve,
      builder: (context, t, c) {
        if (slideOffsetPx == 0) {
          return Opacity(opacity: t, child: c);
        }
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, (1 - t) * slideOffsetPx),
            child: c,
          ),
        );
      },
      child: child,
    );
  }
}
