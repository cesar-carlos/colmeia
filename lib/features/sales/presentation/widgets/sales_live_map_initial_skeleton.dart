import 'package:colmeia/features/sales/domain/entities/sales_live_map_metric.dart';
import 'package:colmeia/features/sales/domain/entities/sales_live_map_point.dart';
import 'package:colmeia/features/sales/presentation/models/sales_live_map_visual_spec.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_live_map_chart_panel.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_live_map_kpi_grid.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/app_skeleton.dart';
import 'package:flutter/material.dart';

const double _kSalesLiveMapSkeletonRevenue = 128000;
const int _kSalesLiveMapSkeletonSalesCount = 420;
const int _kSalesLiveMapSkeletonBranchCount = 12;
const int _kSalesLiveMapSkeletonMunicipalityCount = 8;
const int _kSalesLiveMapSkeletonAgentCount = 3;

const SalesLiveMapKpiGridModel _kSalesLiveMapSkeletonKpiModel =
    SalesLiveMapKpiGridModel(
      totalRevenue: _kSalesLiveMapSkeletonRevenue,
      totalSalesCount: _kSalesLiveMapSkeletonSalesCount,
      mappedBranchCount: _kSalesLiveMapSkeletonBranchCount,
      totalBranchCount: _kSalesLiveMapSkeletonBranchCount,
      mappedMunicipalityCount: _kSalesLiveMapSkeletonMunicipalityCount,
      queriedAgentCount: _kSalesLiveMapSkeletonAgentCount,
      plannedAgentCount: _kSalesLiveMapSkeletonAgentCount,
    );

class SalesLiveMapInitialSkeleton extends StatelessWidget {
  const SalesLiveMapInitialSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = context.appTokens;
    return AppSkeleton(
      enabled: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const SalesLiveMapKpiGrid(model: _kSalesLiveMapSkeletonKpiModel),
          SizedBox(height: tokens.sectionSpacing),
          SalesLiveMapChartPanel(
            mode: SalesLiveMapChartPanelMode.inline,
            title: AppLocalizations.of(context).salesLiveMapChartTitle,
            points: const <SalesLiveMapPoint>[],
            metric: SalesLiveMapMetric.revenue,
            filterBranchIds: const <String>{},
            visualSpec: const SalesLiveMapVisualSpec.operational(),
            isRefreshing: false,
            onMetricChanged: _ignoreMetricChanged,
          ),
        ],
      ),
    );
  }
}

void _ignoreMetricChanged(SalesLiveMapMetric _) {}
