import 'dart:math' as math;

import 'package:colmeia/core/formatters/app_br_formatters.dart';
import 'package:colmeia/core/layout/app_breakpoints.dart';
import 'package:colmeia/features/sales/application/load_sales_live_map_use_case.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/metrics/app_metric_stat_card.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

const int _kSalesLiveMapKpiNarrowColumns = 2;
const int _kSalesLiveMapKpiWideColumns = 3;
const int _kSalesLiveMapKpiExtraWideColumns = 5;

/// View model rendered by [SalesLiveMapKpiGrid]. Decouples the grid from
/// [SalesLiveMapLoadResult] so the skeleton, tests and future widgets can
/// supply numeric placeholders without faking a full load result.
@immutable
class SalesLiveMapKpiGridModel {
  const SalesLiveMapKpiGridModel({
    required this.totalRevenue,
    required this.totalSalesCount,
    required this.mappedBranchCount,
    required this.totalBranchCount,
    required this.mappedMunicipalityCount,
    required this.queriedAgentCount,
    required this.plannedAgentCount,
    this.locationDiagnostics = const SalesLiveMapLocationDiagnostics(),
  });

  factory SalesLiveMapKpiGridModel.fromLoadResult(
    SalesLiveMapLoadResult result,
  ) {
    return SalesLiveMapKpiGridModel(
      totalRevenue: result.totalRevenue,
      totalSalesCount: result.totalSalesCount,
      mappedBranchCount: result.mappedBranchCount,
      totalBranchCount: result.totalBranchCount,
      mappedMunicipalityCount: result.mappedMunicipalityCount,
      queriedAgentCount: result.queriedAgentCount,
      plannedAgentCount: result.plannedAgentCount,
      locationDiagnostics: result.locationDiagnostics,
    );
  }

  final double totalRevenue;
  final int totalSalesCount;
  final int mappedBranchCount;
  final int totalBranchCount;
  final int mappedMunicipalityCount;
  final int queriedAgentCount;
  final int plannedAgentCount;
  final SalesLiveMapLocationDiagnostics locationDiagnostics;
}

class SalesLiveMapKpiGrid extends StatelessWidget {
  const SalesLiveMapKpiGrid({
    required this.model,
    super.key,
  });

  final SalesLiveMapKpiGridModel model;

  @override
  Widget build(BuildContext context) {
    final tokens = context.appTokens;
    final l10n = AppLocalizations.of(context);
    final integerFormat = NumberFormat.decimalPattern(l10n.localeName);
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= AppBreakpoints.kpiGridWide;
        final columns = constraints.maxWidth >= AppBreakpoints.kpiGridExtraWide
            ? _kSalesLiveMapKpiExtraWideColumns
            : (isWide
                  ? _kSalesLiveMapKpiWideColumns
                  : _kSalesLiveMapKpiNarrowColumns);
        final gap = tokens.gapMd;
        final width = math.max<double>(
          0,
          (constraints.maxWidth - (gap * (columns - 1))) / columns,
        );

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: <Widget>[
            SizedBox(
              width: width,
              child: AppMetricStatCard(
                leading: const Icon(Icons.payments_outlined),
                label: l10n.salesLiveMapKpiRevenue,
                value: AppBrFormatters.smartCompactCurrencyForLocale(
                  model.totalRevenue,
                  l10n.localeName,
                ),
                tooltipMessage: AppBrFormatters.currency(model.totalRevenue),
                emphasis: AppMetricStatCardEmphasis.hero,
              ),
            ),
            SizedBox(
              width: width,
              child: AppMetricStatCard(
                leading: const Icon(Icons.receipt_long_outlined),
                label: l10n.salesLiveMapKpiSales,
                value: integerFormat.format(model.totalSalesCount),
              ),
            ),
            SizedBox(
              width: width,
              child: AppMetricStatCard(
                leading: const Icon(Icons.storefront_outlined),
                label: l10n.salesLiveMapKpiBranchesOnMap,
                value: '${model.mappedBranchCount}/${model.totalBranchCount}',
                tooltipMessage: _branchesOnMapTooltip(l10n),
              ),
            ),
            SizedBox(
              width: width,
              child: AppMetricStatCard(
                leading: const Icon(Icons.location_city_outlined),
                label: l10n.salesLiveMapKpiMunicipalitiesOnMap,
                value: integerFormat.format(model.mappedMunicipalityCount),
              ),
            ),
            SizedBox(
              width: width,
              child: AppMetricStatCard(
                leading: const Icon(Icons.hub_outlined),
                label: l10n.salesLiveMapKpiQueriedAgents,
                value:
                    '${model.queriedAgentCount}/${model.plannedAgentCount}',
              ),
            ),
          ],
        );
      },
    );
  }

  String? _branchesOnMapTooltip(AppLocalizations l10n) {
    final diagnostics = model.locationDiagnostics;
    if (!diagnostics.hasAnySignal) {
      return null;
    }

    return l10n.salesLiveMapKpiBranchesOnMapTooltip(
      diagnostics.resolvedByProvidedGeoPointCount,
      diagnostics.resolvedByIbgeMunicipalityCodeCount,
      diagnostics.resolvedByCepCount,
      diagnostics.resolvedByCityUfCount,
      diagnostics.resolvedByCapitalUfCount,
      diagnostics.resolvedByStateUfCount,
      diagnostics.unresolvedBranchCount,
    );
  }
}
