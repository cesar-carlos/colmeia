import 'package:colmeia/shared/widgets/charts/app_brazil_store_sales_map_chart/brazil_map_chart_branch_carousel_card.dart';
import 'package:colmeia/shared/widgets/charts/app_brazil_store_sales_map_chart/brazil_map_chart_branch_detail_surface_widget.dart';
import 'package:colmeia/shared/widgets/charts/app_brazil_store_sales_map_data.dart';
import 'package:colmeia/shared/widgets/charts/app_brazil_store_sales_map_models.dart';
import 'package:flutter/material.dart';

export 'brazil_map_chart_branch_carousel_card.dart';
export 'brazil_map_chart_branch_carousel_navigation_widgets.dart';
export 'brazil_map_chart_branch_detail_surface_widget.dart';

class BrazilMapChartSelectedMarkerGroupDetailCard extends StatelessWidget {
  const BrazilMapChartSelectedMarkerGroupDetailCard({
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
  Widget build(BuildContext context) {
    return BrazilMapChartSelectedMarkerBranchCarouselCard(
      group: group,
      metric: metric,
      initialStoreId: initialStoreId,
      onClose: onClose,
      onDismiss: onDismiss,
      onClearSelection: onClearSelection,
      onSelectBranch: onSelectBranch,
      selectBranchLabel: selectBranchLabel,
      selectBranchLabelBuilder: selectBranchLabelBuilder,
      showTechnicalLocationDetails: showTechnicalLocationDetails,
    );
  }
}

class BrazilMapChartSelectedMarkerStoreDetailCard extends StatelessWidget {
  const BrazilMapChartSelectedMarkerStoreDetailCard({
    required this.point,
    required this.metric,
    super.key,
    this.showTechnicalLocationDetails = true,
  });

  final AppBrazilStoreSalesPoint point;
  final AppBrazilStoreSalesMapMetric metric;
  final bool showTechnicalLocationDetails;

  @override
  Widget build(BuildContext context) {
    return BrazilMapChartSelectedMarkerBranchDetailSurface(
      point: point,
      metric: metric,
      showTechnicalLocationDetails: showTechnicalLocationDetails,
    );
  }
}
