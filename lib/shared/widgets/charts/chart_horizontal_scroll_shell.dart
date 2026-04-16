import 'package:flutter/material.dart';

/// Width of the edge fade overlays in logical pixels.
const double kChartHorizontalScrollFadeWidth = 32;

/// Threshold below which scroll position is considered "at end" (float noise).
const double kChartHorizontalScrollEdgeThreshold = 0.5;

/// Vertical space reserved under the chart so the horizontal [Scrollbar] thumb
/// sits below the plot (including category labels), matching other home charts.
const double kChartHorizontalScrollBottomTrackSlot = 10;

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

  /// Insets the bottom of the horizontal scroll viewport so the scrollbar thumb
  /// sits below the chart (including category labels). When positive, [child]
  /// height should be `outerHeight - bottomTrackSlot`. Defaults to `0`
  /// (scrollbar at the bottom edge of the chart). Use
  /// [kChartHorizontalScrollBottomTrackSlot] with callers that reserve space.
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
    final slot = widget.bottomTrackSlot;
    Widget scrollable = Scrollbar(
      controller: _controller,
      thumbVisibility: chartHorizontalScrollScrollbarThumbVisible(context),
      child: SingleChildScrollView(
        controller: _controller,
        scrollDirection: Axis.horizontal,
        physics: const ClampingScrollPhysics(),
        padding: slot > 0 ? EdgeInsets.only(bottom: slot) : EdgeInsets.zero,
        child: Align(
          alignment: Alignment.topLeft,
          child: widget.child,
        ),
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
