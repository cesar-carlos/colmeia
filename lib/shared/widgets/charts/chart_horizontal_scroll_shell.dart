import 'package:flutter/material.dart';

/// Width of the edge fade overlays in logical pixels.
const double kChartHorizontalScrollFadeWidth = 32;

/// Threshold below which scroll position is considered "at end" (float noise).
const double kChartHorizontalScrollEdgeThreshold = 0.5;

/// Vertical strip placed **below** the chart inside the horizontally scrollable
/// column so the [Scrollbar] thumb sits over this strip instead of over category
/// labels (see [ChartHorizontalScrollShell]).
const double kChartHorizontalScrollBottomTrackSlot = 22;

bool chartHorizontalScrollScrollbarThumbVisible(BuildContext context) {
  switch (Theme.of(context).platform) {
    case TargetPlatform.windows:
    case TargetPlatform.macOS:
    case TargetPlatform.linux:
      return true;
    case TargetPlatform.android:
    case TargetPlatform.fuchsia:
    case TargetPlatform.iOS:
      return false;
  }
}

/// Horizontal scroll for wide charts: [Scrollbar] on desktop, optional edge
/// fades, optional semantics hint for the scroll gesture.
class ChartHorizontalScrollShell extends StatefulWidget {
  const ChartHorizontalScrollShell(
    this.child, {
    super.key,
    this.showFade = true,
    this.semanticsHint,
    this.bottomTrackSlot = 0,
  });

  final Widget child;
  final bool showFade;
  final String? semanticsHint;

  /// When positive, a blank strip this tall is stacked **below** [child] inside
  /// the scrollable so the horizontal scrollbar thumb paints over the strip, not
  /// over X-axis labels. Callers should size [child] with height
  /// `outerHeight - bottomTrackSlot`. Defaults to `0` (no strip). Prefer
  /// [kChartHorizontalScrollBottomTrackSlot] for comparison-style charts.
  final double bottomTrackSlot;

  @override
  State<ChartHorizontalScrollShell> createState() =>
      _ChartHorizontalScrollShellState();
}

class _ChartHorizontalScrollShellState
    extends State<ChartHorizontalScrollShell> {
  late final ScrollController _controller;
  bool _showLeftFade = false;
  bool _showRightFade = true;

  @override
  void initState() {
    super.initState();
    _controller = ScrollController();
    if (widget.showFade) {
      _controller.addListener(_onScroll);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _onScroll();
        }
      });
    }
  }

  void _onScroll() {
    if (!_controller.hasClients) return;
    final pos = _controller.position;
    final showLeft = pos.pixels > kChartHorizontalScrollEdgeThreshold;
    final showRight =
        pos.pixels < pos.maxScrollExtent - kChartHorizontalScrollEdgeThreshold;
    if (showLeft == _showLeftFade && showRight == _showRightFade) return;
    setState(() {
      _showLeftFade = showLeft;
      _showRightFade = showRight;
    });
  }

  @override
  void dispose() {
    if (widget.showFade) {
      _controller.removeListener(_onScroll);
    }
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baseSlot = widget.bottomTrackSlot;
    final slot = baseSlot <= 0
        ? 0.0
        : MediaQuery.textScalerOf(context).scale(baseSlot).clamp(18.0, 56.0);
    final scrollChild = slot > 0
        ? Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              widget.child,
              SizedBox(height: slot),
            ],
          )
        : Align(
            alignment: Alignment.topLeft,
            child: widget.child,
          );
    Widget scrollable = Scrollbar(
      controller: _controller,
      thumbVisibility: chartHorizontalScrollScrollbarThumbVisible(context),
      child: SingleChildScrollView(
        controller: _controller,
        scrollDirection: Axis.horizontal,
        physics: const ClampingScrollPhysics(),
        child: scrollChild,
      ),
    );
    final hint = widget.semanticsHint;
    if (hint != null && hint.isNotEmpty) {
      scrollable = Semantics(hint: hint, child: scrollable);
    }

    if (!widget.showFade) {
      return scrollable;
    }

    final fadeColor = Theme.of(context).colorScheme.surface;
    return Stack(
      children: <Widget>[
        scrollable,
        if (_showLeftFade) _buildFade(fadeColor, isLeft: true),
        if (_showRightFade) _buildFade(fadeColor, isLeft: false),
      ],
    );
  }

  Widget _buildFade(Color fadeColor, {required bool isLeft}) {
    return Positioned(
      left: isLeft ? 0 : null,
      right: isLeft ? null : 0,
      top: 0,
      bottom: 0,
      width: kChartHorizontalScrollFadeWidth,
      child: IgnorePointer(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: <Color>[
                fadeColor.withValues(alpha: isLeft ? 0.85 : 0),
                fadeColor.withValues(alpha: isLeft ? 0 : 0.85),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
