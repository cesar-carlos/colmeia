import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/widgets/charts/app_brazil_store_sales_map_chart/brazil_map_chart_branch_carousel_navigation_widgets.dart';
import 'package:colmeia/shared/widgets/charts/app_brazil_store_sales_map_chart/brazil_map_chart_branch_detail_surface_widget.dart';
import 'package:colmeia/shared/widgets/charts/app_brazil_store_sales_map_data.dart';
import 'package:colmeia/shared/widgets/charts/app_brazil_store_sales_map_models.dart';
import 'package:colmeia/shared/widgets/charts/brazil_map_chart_visual_snapshot.dart';
import 'package:colmeia/shared/widgets/charts/brazil_map_store_sales_display_helpers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class BrazilMapChartSelectedMarkerBranchCarouselCard extends StatefulWidget {
  const BrazilMapChartSelectedMarkerBranchCarouselCard({
    required this.group,
    required this.metric,
    super.key,
    this.initialStoreId,
    this.onClose,
    this.onDismiss,
    this.onClearSelection,
    this.onSelectBranch,
    this.selectBranchLabel,
    this.selectBranchLabelBuilder,
    this.showTechnicalLocationDetails = true,
  });

  final AppBrazilStoreSalesMarkerGroup group;
  final AppBrazilStoreSalesMapMetric metric;
  final String? initialStoreId;
  final VoidCallback? onClose;
  final VoidCallback? onDismiss;
  final VoidCallback? onClearSelection;
  final ValueChanged<AppBrazilStoreSalesPoint>? onSelectBranch;
  final String? selectBranchLabel;
  final String Function(AppBrazilStoreSalesPoint)? selectBranchLabelBuilder;
  final bool showTechnicalLocationDetails;

  @override
  State<BrazilMapChartSelectedMarkerBranchCarouselCard> createState() =>
      BrazilMapChartSelectedMarkerBranchCarouselCardState();
}

class BrazilMapChartSelectedMarkerBranchCarouselCardState
    extends State<BrazilMapChartSelectedMarkerBranchCarouselCard> {
  late int _selectedIndex;
  late List<AppBrazilStoreSalesPoint> _orderedPoints;

  @override
  void initState() {
    super.initState();
    _orderedPoints = brazilMapOrderedBranchPoints(
      widget.group,
      initialStoreId: widget.initialStoreId,
    );
    _selectedIndex = _initialIndex();
  }

  @override
  void didUpdateWidget(
    covariant BrazilMapChartSelectedMarkerBranchCarouselCard oldWidget,
  ) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.group != widget.group ||
        oldWidget.initialStoreId != widget.initialStoreId) {
      _orderedPoints = brazilMapOrderedBranchPoints(
        widget.group,
        initialStoreId: widget.initialStoreId,
      );
      _selectedIndex = _initialIndex();
    } else if (_selectedIndex >= _orderedPoints.length) {
      _selectedIndex = 0;
    }
  }

  int _initialIndex() {
    final storeId = widget.initialStoreId;
    if (storeId == null) {
      return 0;
    }

    final index = _orderedPoints.indexWhere(
      (point) => point.id == storeId,
    );
    return index < 0 ? 0 : index;
  }

  void _move(int delta) {
    final count = _orderedPoints.length;
    if (count <= 1) {
      return;
    }

    final nextIndex = (_selectedIndex + delta).clamp(0, count - 1);
    if (nextIndex == _selectedIndex) {
      return;
    }
    setState(() {
      _selectedIndex = nextIndex;
    });
  }

  @override
  Widget build(BuildContext context) {
    final point = _orderedPoints[_selectedIndex];
    final count = _orderedPoints.length;
    final selectedStoreId = widget.initialStoreId;
    final isPinnedPoint =
        selectedStoreId != null && point.id == selectedStoreId;
    final branchAction = isPinnedPoint
        ? widget.onClearSelection
        : widget.onSelectBranch == null
        ? null
        : () => widget.onSelectBranch!(point);
    final branchActionLabel = isPinnedPoint
        ? AppLocalizations.of(context).brazilStoreSalesMapUnpinBranchButton
        : widget.selectBranchLabelBuilder?.call(point) ??
              widget.selectBranchLabel;

    return Focus(
      autofocus: defaultTargetPlatform != TargetPlatform.windows,
      onKeyEvent: _handleKeyEvent,
      child: BrazilMapChartSelectedMarkerBranchDetailSurface(
        point: point,
        metric: widget.metric,
        onClose: widget.onClose,
        showTechnicalLocationDetails: widget.showTechnicalLocationDetails,
        branchPositionLabel: count > 1
            ? AppLocalizations.of(context).brazilStoreSalesMapCarouselPosition(
                brazilMapChartFormatSalesCount(context, _selectedIndex + 1),
                brazilMapChartFormatSalesCount(context, count),
              )
            : null,
        aggregateSummary: count > 1
            ? BrazilMapChartBranchAggregateSummary(
                group: widget.group,
                metric: widget.metric,
              )
            : null,
        onSelectBranch: branchAction,
        selectBranchLabel: branchActionLabel,
        navigation: count > 1
            ? BrazilMapChartBranchCarouselNavigation(
                currentIndex: _selectedIndex,
                points: _orderedPoints,
                onPrevious: () => _move(-1),
                onNext: () => _move(1),
                onSelectIndex: (index) {
                  setState(() {
                    _selectedIndex = index;
                  });
                },
              )
            : null,
      ),
    );
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) {
      return KeyEventResult.ignored;
    }

    if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      _move(-1);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      _move(1);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.escape) {
      final dismiss = widget.onDismiss ?? widget.onClose;
      dismiss?.call();
      return dismiss == null ? KeyEventResult.ignored : KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }
}
