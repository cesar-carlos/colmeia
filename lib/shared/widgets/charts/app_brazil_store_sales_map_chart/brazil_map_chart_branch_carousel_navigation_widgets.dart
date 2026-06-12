import 'package:colmeia/core/formatters/app_br_formatters.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/app_tag_chip.dart';
import 'package:colmeia/shared/widgets/charts/app_brazil_store_sales_map_data.dart';
import 'package:colmeia/shared/widgets/charts/app_brazil_store_sales_map_models.dart';
import 'package:colmeia/shared/widgets/charts/app_brazil_store_sales_map_overlay_chrome.dart';
import 'package:colmeia/shared/widgets/charts/brazil_map_chart_visual_snapshot.dart';
import 'package:colmeia/shared/widgets/charts/brazil_map_store_sales_display_helpers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class BrazilMapChartBranchCarouselNavigation extends StatelessWidget {
  const BrazilMapChartBranchCarouselNavigation({
    required this.currentIndex,
    required this.points,
    required this.onPrevious,
    required this.onNext,
    required this.onSelectIndex,
    super.key,
  });

  final int currentIndex;
  final List<AppBrazilStoreSalesPoint> points;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final ValueChanged<int> onSelectIndex;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppThemeTokens>()!;
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final branchCount = points.length;
    final showBranchPicker = branchCount >= 10;

    final pickerTooltip = defaultTargetPlatform == TargetPlatform.windows
        ? ''
        : l10n.brazilStoreSalesMapChooseBranchMenuTooltip;

    return Row(
      children: [
        if (showBranchPicker) ...[
          PopupMenuButton<int>(
            key: const ValueKey<String>(
              'brazil-store-sales-branch-card-picker',
            ),
            tooltip: pickerTooltip,
            onSelected: onSelectIndex,
            itemBuilder: (context) => [
              for (var index = 0; index < points.length; index++)
                PopupMenuItem<int>(
                  value: index,
                  child: Text(
                    '${brazilMapChartFormatSalesCount(context, index + 1)}. '
                    '${brazilMapBranchDisplayNameUi(context, points[index])}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
            icon: const Icon(Icons.list_alt_outlined),
          ),
          SizedBox(width: tokens.gapXs),
        ],
        AppBrazilStoreSalesMapWindowsSafeOverlayIconButton(
          key: const ValueKey<String>(
            'brazil-store-sales-branch-card-previous',
          ),
          icon: Icons.chevron_left_rounded,
          dimension: 34,
          onPressed: currentIndex > 0 ? onPrevious : null,
          tooltipMessage:
              l10n.brazilStoreSalesMapBranchNavigationPreviousTooltip,
        ),
        Expanded(
          child: Text(
            l10n.brazilStoreSalesMapCarouselPosition(
              brazilMapChartFormatSalesCount(context, currentIndex + 1),
              brazilMapChartFormatSalesCount(context, branchCount),
            ),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        SizedBox(width: tokens.gapXs),
        AppBrazilStoreSalesMapWindowsSafeOverlayIconButton(
          key: const ValueKey<String>('brazil-store-sales-branch-card-next'),
          icon: Icons.chevron_right_rounded,
          dimension: 34,
          onPressed: currentIndex < branchCount - 1 ? onNext : null,
          tooltipMessage: l10n.brazilStoreSalesMapBranchNavigationNextTooltip,
        ),
      ],
    );
  }
}

class BrazilMapChartBranchAggregateSummary extends StatelessWidget {
  const BrazilMapChartBranchAggregateSummary({
    required this.group,
    required this.metric,
    super.key,
  });

  final AppBrazilStoreSalesMarkerGroup group;
  final AppBrazilStoreSalesMapMetric metric;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppThemeTokens>()!;
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final hasLoadingSales = group.points.any(
      (point) => point.salesDataLoading,
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(tokens.formFieldRadius),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: EdgeInsets.all(tokens.gapSm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.brazilStoreSalesMapMarkerGroupTotalTitle,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: tokens.gapXs),
            Wrap(
              spacing: tokens.gapSm,
              runSpacing: tokens.gapSm,
              children: [
                if (hasLoadingSales)
                  AppTagChip(
                    label: l10n.brazilStoreSalesMapSalesLoadingLabel,
                    icon: Icons.sync_rounded,
                  )
                else ...[
                  AppTagChip(
                    label: AppBrFormatters.currency(group.salesAmount),
                    icon: Icons.attach_money,
                  ),
                  AppTagChip(
                    label: l10n.brazilStoreSalesMapDetailChipSales(
                      brazilMapChartFormatSalesCount(context, group.salesCount),
                    ),
                    icon: Icons.receipt_long_outlined,
                  ),
                ],
                AppTagChip(
                  label: l10n.brazilStoreSalesMapDetailChipBranches(
                    brazilMapChartFormatSalesCount(
                      context,
                      group.points.length,
                    ),
                  ),
                  icon: Icons.storefront_outlined,
                ),
                AppTagChip(label: brazilMapChartMetricShortLabel(l10n, metric)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
