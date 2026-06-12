import 'package:colmeia/core/formatters/app_br_formatters.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_colors.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/app_tag_chip.dart';
import 'package:colmeia/shared/widgets/charts/app_brazil_store_sales_map_chart/brazil_map_chart_detail_surfaces.dart';
import 'package:colmeia/shared/widgets/charts/app_brazil_store_sales_map_models.dart';
import 'package:colmeia/shared/widgets/charts/app_brazil_store_sales_map_overlay_chrome.dart';
import 'package:colmeia/shared/widgets/charts/brazil_map_chart_visual_snapshot.dart';
import 'package:colmeia/shared/widgets/charts/brazil_map_store_sales_display_helpers.dart';
import 'package:flutter/material.dart';

class BrazilMapChartSelectedMarkerBranchDetailSurface extends StatelessWidget {
  const BrazilMapChartSelectedMarkerBranchDetailSurface({
    required this.point,
    required this.metric,
    super.key,
    this.onClose,
    this.showTechnicalLocationDetails = true,
    this.branchPositionLabel,
    this.aggregateSummary,
    this.onSelectBranch,
    this.selectBranchLabel,
    this.navigation,
  });

  final AppBrazilStoreSalesPoint point;
  final AppBrazilStoreSalesMapMetric metric;
  final VoidCallback? onClose;
  final bool showTechnicalLocationDetails;
  final String? branchPositionLabel;
  final Widget? aggregateSummary;
  final VoidCallback? onSelectBranch;
  final String? selectBranchLabel;
  final Widget? navigation;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppThemeTokens>()!;
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final cityLabel = brazilMapCityLabelFor(point);
    final municipalityCode = point.municipalityCode?.trim();
    final branchName = brazilMapBranchNameLabel(point);
    final agentName = brazilMapTrimmedOrNull(point.agentName);
    final legacySubtitle = brazilMapTrimmedOrNull(point.subtitle);
    final maxCardHeight = (MediaQuery.sizeOf(context).height - 48).clamp(
      260.0,
      460.0,
    );

    return Semantics(
      container: true,
      label: l10n.brazilStoreSalesMapBranchDetailSemanticsLabel,
      child: AppBrazilStoreSalesMapOverlayTooltipScope(
        child: BrazilMapChartMapDetailCard(
          key: const ValueKey<String>('brazil-store-sales-branch-card'),
          elevation: 8,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxCardHeight),
            child: SingleChildScrollView(
              key: const ValueKey<String>(
                'brazil-store-sales-branch-card-scroll',
              ),
              padding: EdgeInsets.all(tokens.contentSpacing),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.storefront_outlined,
                        color: context.appColors.secondary,
                        size: 20,
                      ),
                      SizedBox(width: tokens.gapSm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              brazilMapBranchDisplayNameUi(context, point),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            SizedBox(height: tokens.gapXs),
                            Text(
                              cityLabel,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: tokens.gapSm),
                      if (onClose == null)
                        AppTagChip(
                          label:
                              branchPositionLabel ??
                              brazilMapChartMetricShortLabel(l10n, metric),
                        )
                      else
                        AppBrazilStoreSalesMapWindowsSafeOverlayIconButton(
                          key: const ValueKey<String>(
                            'brazil-store-sales-branch-card-close',
                          ),
                          icon: Icons.close_rounded,
                          iconSize: 18,
                          dimension: 32,
                          onPressed: onClose,
                          tooltipMessage:
                              l10n.brazilStoreSalesMapCloseBranchDetailsTooltip,
                        ),
                    ],
                  ),
                  SizedBox(height: tokens.gapMd),
                  if (onClose != null) ...[
                    Wrap(
                      spacing: tokens.gapSm,
                      runSpacing: tokens.gapSm,
                      children: [
                        AppTagChip(
                          label: l10n.brazilStoreSalesMapBranchPinnedChip,
                        ),
                        AppTagChip(
                          label: brazilMapChartMetricShortLabel(l10n, metric),
                        ),
                        if (branchPositionLabel != null)
                          AppTagChip(label: branchPositionLabel!),
                      ],
                    ),
                    SizedBox(height: tokens.gapSm),
                  ],
                  if (aggregateSummary != null) ...[
                    aggregateSummary!,
                    SizedBox(height: tokens.gapMd),
                  ],
                  Wrap(
                    spacing: tokens.gapSm,
                    runSpacing: tokens.gapSm,
                    children: [
                      if (point.salesDataLoading)
                        AppTagChip(
                          label: l10n.brazilStoreSalesMapSalesLoadingLabel,
                          icon: Icons.sync_rounded,
                        )
                      else ...[
                        AppTagChip(
                          label: AppBrFormatters.currency(point.salesAmount),
                          icon: Icons.attach_money,
                        ),
                        AppTagChip(
                          label: l10n.brazilStoreSalesMapDetailChipSales(
                            brazilMapChartFormatSalesCount(
                              context,
                              point.salesCount,
                            ),
                          ),
                          icon: Icons.receipt_long_outlined,
                        ),
                      ],
                      if (!point.salesDataLoading && point.salesDataUnavailable)
                        AppTagChip(
                          label:
                              point.salesDataStatusLabel ??
                              l10n.brazilStoreSalesMapSalesUnavailableFallback,
                          icon: Icons.sync_problem_outlined,
                        ),
                      if (agentName != null)
                        AppTagChip(
                          label: brazilMapAgentChipLabel(l10n, agentName),
                          icon: Icons.hub_outlined,
                        )
                      else if (legacySubtitle != null)
                        AppTagChip(
                          label: legacySubtitle,
                          icon: Icons.hub_outlined,
                        ),
                      if (branchName != null)
                        AppTagChip(
                          label: branchName,
                          icon: Icons.store_mall_directory_outlined,
                        ),
                      if (showTechnicalLocationDetails &&
                          municipalityCode != null &&
                          municipalityCode.isNotEmpty)
                        AppTagChip(
                          label: l10n.brazilStoreSalesMapIbgeCodeLabel(
                            municipalityCode,
                          ),
                          icon: Icons.pin_drop_outlined,
                        ),
                      if (showTechnicalLocationDetails)
                        AppTagChip(
                          label: brazilMapLocationResolutionLabel(
                            l10n,
                            point.locationResolution,
                          ),
                          icon: Icons.my_location_outlined,
                        ),
                      if (showTechnicalLocationDetails)
                        AppTagChip(
                          label:
                              '${point.latitude.toStringAsFixed(4)}, '
                              '${point.longitude.toStringAsFixed(4)}',
                          icon: Icons.explore_outlined,
                        ),
                    ],
                  ),
                  if (onSelectBranch != null) ...[
                    SizedBox(height: tokens.gapMd),
                    Align(
                      alignment: Alignment.centerRight,
                      child: OutlinedButton.icon(
                        key: const ValueKey<String>(
                          'brazil-store-sales-branch-card-select',
                        ),
                        onPressed: onSelectBranch,
                        icon: const Icon(Icons.push_pin_outlined, size: 18),
                        label: Text(
                          selectBranchLabel ??
                              l10n.brazilStoreSalesMapSelectBranchButton,
                        ),
                      ),
                    ),
                  ],
                  if (navigation != null) ...[
                    SizedBox(height: tokens.gapMd),
                    Divider(color: colorScheme.outlineVariant, height: 1),
                    SizedBox(height: tokens.gapXs),
                    navigation!,
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
