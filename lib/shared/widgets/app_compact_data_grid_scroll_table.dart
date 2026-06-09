import 'package:colmeia/shared/design_system/app_data_grid_density.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/charts/chart_horizontal_scroll_shell.dart';
import 'package:flutter/material.dart';

/// Horizontally scrollable compact data grid with an optional vertically
/// scrollable body and a header that stays pinned when [itemCount] exceeds
/// [kAppCompactDataGridStickyRowThreshold].
class AppCompactDataGridScrollTable extends StatefulWidget {
  const AppCompactDataGridScrollTable({
    required this.header,
    required this.contentWidth,
    required this.itemCount,
    required this.itemBuilder,
    super.key,
    this.semanticsHint,
    this.showHorizontalFade = true,
  });

  final Widget header;
  final double contentWidth;
  final int itemCount;
  final Widget Function(BuildContext context, int index) itemBuilder;
  final String? semanticsHint;
  final bool showHorizontalFade;

  @override
  State<AppCompactDataGridScrollTable> createState() =>
      _AppCompactDataGridScrollTableState();
}

class _AppCompactDataGridScrollTableState
    extends State<AppCompactDataGridScrollTable> {
  late final ScrollController _horizontalController;
  late final ScrollController _verticalController;

  @override
  void initState() {
    super.initState();
    _horizontalController = ScrollController();
    _verticalController = ScrollController();
  }

  @override
  void dispose() {
    _horizontalController.dispose();
    _verticalController.dispose();
    super.dispose();
  }

  bool get _stickyBodyEnabled =>
      widget.itemCount > kAppCompactDataGridStickyRowThreshold;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.appTokens;
    final rowDividerColor =
        theme.colorScheme.outlineVariant.withValues(alpha: 0.35);
    final headerDividerColor =
        theme.colorScheme.outlineVariant.withValues(alpha: 0.5);
    final rowDivider = Divider(
      height: appDataGridRowDividerHeight(tokens),
      color: rowDividerColor,
    );

    final listBody = ListView.separated(
      controller: _stickyBodyEnabled ? _verticalController : null,
      shrinkWrap: !_stickyBodyEnabled,
      physics: _stickyBodyEnabled
          ? const ClampingScrollPhysics()
          : const NeverScrollableScrollPhysics(),
      primary: false,
      itemCount: widget.itemCount,
      separatorBuilder: (_, _) => rowDivider,
      itemBuilder: widget.itemBuilder,
    );

    final body = _stickyBodyEnabled
        ? ConstrainedBox(
            constraints: const BoxConstraints(
              maxHeight: kAppCompactDataGridStickyBodyMaxHeight,
            ),
            child: ScrollConfiguration(
              behavior: ScrollConfiguration.of(context).copyWith(
                scrollbars: false,
              ),
              child: Scrollbar(
                controller: _verticalController,
                thumbVisibility:
                    chartHorizontalScrollScrollbarThumbVisible(context),
                child: listBody,
              ),
            ),
          )
        : listBody;

    final tableColumn = SizedBox(
      width: widget.contentWidth,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          widget.header,
          Divider(
            height: appDataGridRowDividerHeight(tokens),
            color: headerDividerColor,
          ),
          body,
        ],
      ),
    );

    Widget scrollable = Scrollbar(
      controller: _horizontalController,
      thumbVisibility: chartHorizontalScrollScrollbarThumbVisible(context),
      child: SingleChildScrollView(
        controller: _horizontalController,
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: tableColumn,
      ),
    );

    final hint = widget.semanticsHint;
    if (hint != null && hint.isNotEmpty) {
      scrollable = Semantics(hint: hint, child: scrollable);
    }

    if (!widget.showHorizontalFade) {
      return scrollable;
    }

    return _HorizontalScrollFadeShell(
      controller: _horizontalController,
      child: scrollable,
    );
  }
}

class _HorizontalScrollFadeShell extends StatefulWidget {
  const _HorizontalScrollFadeShell({
    required this.controller,
    required this.child,
  });

  final ScrollController controller;
  final Widget child;

  @override
  State<_HorizontalScrollFadeShell> createState() =>
      _HorizontalScrollFadeShellState();
}

class _HorizontalScrollFadeShellState extends State<_HorizontalScrollFadeShell> {
  bool _showLeftFade = false;
  bool _showRightFade = true;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _onScroll();
      }
    });
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onScroll);
    super.dispose();
  }

  void _onScroll() {
    final controller = widget.controller;
    if (!controller.hasClients) {
      return;
    }
    final pos = controller.position;
    if (!pos.hasContentDimensions) {
      return;
    }
    final showLeft = pos.pixels > kChartHorizontalScrollEdgeThreshold;
    final showRight =
        pos.pixels < pos.maxScrollExtent - kChartHorizontalScrollEdgeThreshold;
    if (showLeft == _showLeftFade && showRight == _showRightFade) {
      return;
    }
    setState(() {
      _showLeftFade = showLeft;
      _showRightFade = showRight;
    });
  }

  @override
  Widget build(BuildContext context) {
    final fadeColor = Theme.of(context).colorScheme.surface;
    return Stack(
      children: <Widget>[
        widget.child,
        if (_showLeftFade)
          _EdgeFade(color: fadeColor, alignment: Alignment.centerLeft),
        if (_showRightFade)
          _EdgeFade(color: fadeColor, alignment: Alignment.centerRight),
      ],
    );
  }
}

class _EdgeFade extends StatelessWidget {
  const _EdgeFade({
    required this.color,
    required this.alignment,
  });

  final Color color;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    final isLeft = alignment == Alignment.centerLeft;
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
              begin: isLeft ? Alignment.centerLeft : Alignment.centerRight,
              end: isLeft ? Alignment.centerRight : Alignment.centerLeft,
              colors: <Color>[
                color.withValues(alpha: 0.85),
                color.withValues(alpha: 0),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
