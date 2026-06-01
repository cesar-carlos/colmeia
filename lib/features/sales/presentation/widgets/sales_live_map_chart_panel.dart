import 'package:colmeia/features/sales/domain/entities/sales_live_map_metric.dart';
import 'package:colmeia/features/sales/domain/entities/sales_live_map_point.dart';
import 'package:colmeia/features/sales/presentation/mappers/sales_live_map_chart_mapper.dart';
import 'package:colmeia/features/sales/presentation/mappers/sales_live_map_visual_spec_mapper.dart';
import 'package:colmeia/features/sales/presentation/models/sales_live_map_visual_spec.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/app_section_card.dart';
import 'package:colmeia/shared/widgets/charts/app_brazil_store_sales_map_chart.dart';
import 'package:colmeia/shared/widgets/charts/app_brazil_store_sales_map_models.dart';
import 'package:flutter/material.dart';

enum SalesLiveMapChartPanelMode {
  inline,
  fullscreen,
}

class SalesLiveMapChartPanel extends StatelessWidget {
  const SalesLiveMapChartPanel({
    required this.mode,
    required this.points,
    required this.metric,
    required this.filterBranchIds,
    required this.visualSpec,
    required this.isRefreshing,
    required this.onMetricChanged,
    super.key,
    this.onOpenFullscreen,
    this.showSidebar = false,
    this.showHeader = true,
    this.title,
    this.subtitle,
  });

  final SalesLiveMapChartPanelMode mode;
  final List<SalesLiveMapPoint> points;
  final SalesLiveMapMetric metric;
  final Set<String> filterBranchIds;
  final SalesLiveMapVisualSpec visualSpec;
  final bool isRefreshing;
  final ValueChanged<SalesLiveMapMetric> onMetricChanged;
  final VoidCallback? onOpenFullscreen;
  final bool showSidebar;
  final bool showHeader;
  final String? title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final chartPoints = SalesLiveMapChartMapper.toChartPoints(points, l10n);
    final chartStyle = SalesLiveMapVisualSpecMapper.toChartStyle(visualSpec);
    final chart = AppBrazilStoreSalesMapChart(
      title: showHeader ? title : null,
      subtitle: showHeader ? subtitle : null,
      points: chartPoints,
      initialMetric: SalesLiveMapChartMapper.toChartMetric(metric),
      filterBranchIds: filterBranchIds,
      fixedBranchIds: filterBranchIds,
      style: chartStyle,
      isRefreshing: isRefreshing,
      onMetricChanged: (metric) =>
          onMetricChanged(SalesLiveMapChartMapper.fromChartMetric(metric)),
      onOpenFullscreen: showHeader ? onOpenFullscreen : null,
      showDesktopBranchSidebar: showSidebar,
      presentationMode: switch (mode) {
        SalesLiveMapChartPanelMode.inline =>
          AppBrazilStoreSalesMapPresentationMode.inlineOperational,
        SalesLiveMapChartPanelMode.fullscreen =>
          AppBrazilStoreSalesMapPresentationMode.cleanFullscreen,
      },
    );

    if (mode == SalesLiveMapChartPanelMode.inline) {
      return chart;
    }

    final tokens = context.appTokens;
    return AppSectionCard(
      padding: EdgeInsets.fromLTRB(
        tokens.contentSpacing,
        tokens.contentSpacing,
        tokens.contentSpacing,
        0,
      ),
      child: LayoutBuilder(
        builder: (context, cardConstraints) {
          final maxHeight = cardConstraints.maxHeight;
          if (maxHeight.isFinite && maxHeight < double.infinity) {
            return SizedBox(height: maxHeight, child: chart);
          }
          return chart;
        },
      ),
    );
  }
}
