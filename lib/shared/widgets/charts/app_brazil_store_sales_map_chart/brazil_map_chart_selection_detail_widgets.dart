import 'package:colmeia/core/formatters/app_br_formatters.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/app_tag_chip.dart';
import 'package:colmeia/shared/widgets/charts/app_brazil_store_sales_map_chart/brazil_map_chart_branch_detail_widgets.dart';
import 'package:colmeia/shared/widgets/charts/app_brazil_store_sales_map_chart/brazil_map_chart_detail_surfaces.dart';
import 'package:colmeia/shared/widgets/charts/app_brazil_store_sales_map_data.dart';
import 'package:colmeia/shared/widgets/charts/app_brazil_store_sales_map_models.dart';
import 'package:colmeia/shared/widgets/charts/brazil_map_chart_visual_snapshot.dart';
import 'package:flutter/material.dart';

class BrazilMapChartSelectedStateDetail extends StatelessWidget {
  const BrazilMapChartSelectedStateDetail({
    required this.bucket,
    required this.metric,
    super.key,
  });

  final AppBrazilStoreSalesStateBucket bucket;
  final AppBrazilStoreSalesMapMetric metric;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppThemeTokens>()!;
    final l10n = AppLocalizations.of(context);

    return Padding(
      padding: EdgeInsets.only(top: tokens.gapMd),
      child: KeyedSubtree(
        key: const ValueKey<String>('brazil-store-sales-map-state-detail'),
        child: BrazilMapChartSelectedMarkerDetailSurface(
          title: bucket.stateName,
          subtitle: l10n.brazilStoreSalesMapStateSelectedSubtitle(bucket.uf),
          icon: Icons.map_outlined,
          metric: metric,
          child: Wrap(
            spacing: tokens.gapSm,
            runSpacing: tokens.gapSm,
            children: <Widget>[
              AppTagChip(
                label: AppBrFormatters.currency(bucket.salesAmount),
                icon: Icons.attach_money,
              ),
              AppTagChip(
                label: l10n.brazilStoreSalesMapDetailChipSales(
                  brazilMapChartFormatSalesCount(context, bucket.salesCount),
                ),
                icon: Icons.receipt_long_outlined,
              ),
              AppTagChip(
                label: l10n.brazilStoreSalesMapDetailChipBranches(
                  brazilMapChartFormatSalesCount(context, bucket.storeCount),
                ),
                icon: Icons.storefront_outlined,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class BrazilMapChartSelectedMunicipalityDetail extends StatelessWidget {
  const BrazilMapChartSelectedMunicipalityDetail({
    required this.group,
    required this.metric,
    super.key,
    this.selectedStoreId,
    this.onSelectBranch,
    this.selectBranchLabelBuilder,
  });

  final AppBrazilStoreSalesMarkerGroup group;
  final AppBrazilStoreSalesMapMetric metric;
  final String? selectedStoreId;
  final ValueChanged<AppBrazilStoreSalesPoint>? onSelectBranch;
  final String Function(AppBrazilStoreSalesPoint)? selectBranchLabelBuilder;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppThemeTokens>()!;

    return Padding(
      padding: EdgeInsets.only(top: tokens.gapMd),
      child: KeyedSubtree(
        key: const ValueKey<String>(
          'brazil-store-sales-map-municipality-detail',
        ),
        child: BrazilMapChartSelectedMarkerGroupDetailCard(
          group: group,
          metric: metric,
          initialStoreId: selectedStoreId,
          onSelectBranch: onSelectBranch,
          selectBranchLabelBuilder: selectBranchLabelBuilder,
        ),
      ),
    );
  }
}

class BrazilMapChartSelectedStoreDetail extends StatelessWidget {
  const BrazilMapChartSelectedStoreDetail({
    required this.point,
    required this.metric,
    super.key,
  });

  final AppBrazilStoreSalesPoint point;
  final AppBrazilStoreSalesMapMetric metric;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppThemeTokens>()!;

    return Padding(
      padding: EdgeInsets.only(top: tokens.gapMd),
      child: KeyedSubtree(
        key: const ValueKey<String>('brazil-store-sales-map-store-detail'),
        child: BrazilMapChartSelectedMarkerStoreDetailCard(
          point: point,
          metric: metric,
        ),
      ),
    );
  }
}
