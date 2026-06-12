import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_colors.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/app_section_card.dart'
    show AppSectionCard;
import 'package:colmeia/shared/widgets/app_tag_chip.dart';
import 'package:colmeia/shared/widgets/charts/app_brazil_store_sales_map_models.dart';
import 'package:colmeia/shared/widgets/charts/brazil_map_store_sales_display_helpers.dart';
import 'package:colmeia/shared/widgets/widgets.dart' show AppSectionCard;
import 'package:flutter/material.dart';

class BrazilMapChartSelectedMarkerDetailSurface extends StatelessWidget {
  const BrazilMapChartSelectedMarkerDetailSurface({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.metric,
    required this.child,
    super.key,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final AppBrazilStoreSalesMapMetric metric;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppThemeTokens>()!;
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);

    return BrazilMapChartMapDetailCard(
      child: Padding(
        padding: EdgeInsets.all(tokens.contentSpacing),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: context.appColors.secondary, size: 20),
                SizedBox(width: tokens.gapSm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: tokens.gapXs),
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: tokens.gapSm),
                AppTagChip(label: brazilMapChartMetricShortLabel(l10n, metric)),
              ],
            ),
            SizedBox(height: tokens.gapMd),
            child,
          ],
        ),
      ),
    );
  }
}

/// Shared surface for overlay and below-map detail cards in the Brazil
/// store-sales map. Wraps a [Material] + [DecoratedBox] pair to provide the
/// correct radius, border, background colour, and shadow for map-local cards
/// without using the full [AppSectionCard] radius (which is too large for
/// compact detail surfaces).
class BrazilMapChartMapDetailCard extends StatelessWidget {
  const BrazilMapChartMapDetailCard({
    required this.child,
    super.key,
    this.elevation = 0,
  });

  final Widget child;
  final double elevation;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppThemeTokens>()!;
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: colorScheme.surface,
      elevation: elevation,
      shadowColor: colorScheme.shadow.withValues(alpha: 0.22),
      borderRadius: BorderRadius.circular(tokens.formFieldRadius),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(tokens.formFieldRadius),
          border: Border.all(color: colorScheme.outlineVariant),
        ),
        child: child,
      ),
    );
  }
}

class BrazilMapChartStoreSalesMapContent extends StatelessWidget {
  const BrazilMapChartStoreSalesMapContent({
    required this.regionMapBuilder,
    required this.fixedRegionMapHeight,
    this.regionMapStyleHeightForAvailableArea,
    this.expandMapVertically = false,
    super.key,
    this.mapOverlay,
    this.diagnostics,
    this.markerLegend,
    this.detail,
  });

  final Widget Function(double height) regionMapBuilder;
  final double fixedRegionMapHeight;
  final double Function(double availableMapAreaHeight)?
  regionMapStyleHeightForAvailableArea;
  final bool expandMapVertically;
  final Widget? mapOverlay;
  final Widget? diagnostics;
  final Widget? markerLegend;
  final Widget? detail;

  Widget _regionMapStack(double height) {
    final regionMap = regionMapBuilder(height);
    if (mapOverlay == null) {
      return regionMap;
    }
    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        regionMap,
        mapOverlay!,
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final mapSection = expandMapVertically
        ? Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final resolvedHeight =
                    regionMapStyleHeightForAvailableArea?.call(
                      constraints.maxHeight,
                    ) ??
                    fixedRegionMapHeight;
                return _regionMapStack(resolvedHeight);
              },
            ),
          )
        : _regionMapStack(fixedRegionMapHeight);
    final children = <Widget>[mapSection];
    if (diagnostics != null) {
      children.add(diagnostics!);
    }
    if (markerLegend != null) {
      children.add(markerLegend!);
    }
    if (detail != null) {
      children.add(detail!);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    );
  }
}
