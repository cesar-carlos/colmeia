import 'dart:math' as math;

import 'package:colmeia/core/formatters/app_br_formatters.dart';
import 'package:colmeia/features/sales/application/load_sales_live_map_use_case.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/metrics/app_metric_stat_card.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

final NumberFormat _integerFormat = NumberFormat.decimalPattern('pt_BR');

class SalesLiveMapKpiGrid extends StatelessWidget {
  const SalesLiveMapKpiGrid({
    required this.result,
    super.key,
  });

  final SalesLiveMapLoadResult result;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppThemeTokens>()!;
    final l10n = AppLocalizations.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 720;
        final columns = constraints.maxWidth >= 960 ? 5 : (isWide ? 3 : 2);
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
                value: AppBrFormatters.compactCurrency(result.totalRevenue),
                tooltipMessage: AppBrFormatters.currency(result.totalRevenue),
                emphasis: AppMetricStatCardEmphasis.hero,
              ),
            ),
            SizedBox(
              width: width,
              child: AppMetricStatCard(
                leading: const Icon(Icons.receipt_long_outlined),
                label: l10n.salesLiveMapKpiSales,
                value: _integerFormat.format(result.totalSalesCount),
              ),
            ),
            SizedBox(
              width: width,
              child: AppMetricStatCard(
                leading: const Icon(Icons.storefront_outlined),
                label: l10n.salesLiveMapKpiBranchesOnMap,
                value: '${result.mappedBranchCount}/${result.totalBranchCount}',
              ),
            ),
            SizedBox(
              width: width,
              child: AppMetricStatCard(
                leading: const Icon(Icons.location_city_outlined),
                label: l10n.salesLiveMapKpiMunicipalitiesOnMap,
                value: _integerFormat.format(result.mappedMunicipalityCount),
              ),
            ),
            SizedBox(
              width: width,
              child: AppMetricStatCard(
                leading: const Icon(Icons.hub_outlined),
                label: l10n.salesLiveMapKpiQueriedAgents,
                value:
                    '${result.queriedAgentCount}/${result.plannedAgentCount}',
              ),
            ),
          ],
        );
      },
    );
  }
}
