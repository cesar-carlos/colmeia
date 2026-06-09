import 'dart:async';

import 'package:colmeia/core/formatters/app_br_formatters.dart';
import 'package:colmeia/core/layout/app_breakpoints.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_colors.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/maps/app_location_lookup_normalizer.dart';
import 'package:colmeia/shared/utils/app_branch_display_model.dart';
import 'package:colmeia/shared/widgets/app_section_card.dart';
import 'package:colmeia/shared/widgets/app_tag_chip.dart';
import 'package:colmeia/shared/widgets/charts/app_brazil_store_sales_map_data.dart';
import 'package:colmeia/shared/widgets/charts/app_brazil_store_sales_map_localizations.dart';
import 'package:colmeia/shared/widgets/charts/app_brazil_store_sales_map_models.dart';
import 'package:colmeia/shared/widgets/charts/app_brazil_store_sales_map_overlay_chrome.dart';
import 'package:colmeia/shared/widgets/charts/app_map_models.dart';
import 'package:colmeia/shared/widgets/charts/brazil_map_chart_visual_snapshot.dart';
import 'package:colmeia/shared/widgets/charts/brazil_map_layout_constants.dart';
import 'package:colmeia/shared/widgets/charts/brazil_map_store_sales_display_helpers.dart';
import 'package:colmeia/shared/widgets/forms/app_choice_chip.dart';
import 'package:colmeia/shared/widgets/forms/app_segmented_control.dart';
import 'package:colmeia/shared/widgets/forms/app_text_field.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class BrazilMapChartMarkerScaleLegend extends StatelessWidget {
  const BrazilMapChartMarkerScaleLegend({
    required this.sizeLegendLabel,
    required this.metric,
    required this.minValue,
    required this.maxValue,
    required this.minSize,
    required this.maxSize,
    required this.color,
    required this.strokeColor,
    required this.visual,
  });

  final String sizeLegendLabel;
  final AppBrazilStoreSalesMapMetric metric;
  final num minValue;
  final num maxValue;
  final double minSize;
  final double maxSize;
  final Color color;
  final Color strokeColor;
  final AppBrazilStoreSalesMarkerVisual visual;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppThemeTokens>()!;

    return Padding(
      padding: EdgeInsets.only(top: tokens.gapMd),
      child: BrazilMapChartAuxiliarySurface(
        child: BrazilMapChartMarkerScaleLegendContent(
          sizeLegendLabel: sizeLegendLabel,
          metric: metric,
          minValue: minValue,
          maxValue: maxValue,
          minSize: minSize,
          maxSize: maxSize,
          color: color,
          strokeColor: strokeColor,
          visual: visual,
        ),
      ),
    );
  }
}

class BrazilMapChartMarkerScaleLegendMenuButton extends StatelessWidget {
  const BrazilMapChartMarkerScaleLegendMenuButton({
    required this.sizeLegendLabel,
    required this.metric,
    required this.minValue,
    required this.maxValue,
    required this.minSize,
    required this.maxSize,
    required this.color,
    required this.strokeColor,
    required this.visual,
  });

  final String sizeLegendLabel;
  final AppBrazilStoreSalesMapMetric metric;
  final num minValue;
  final num maxValue;
  final double minSize;
  final double maxSize;
  final Color color;
  final Color strokeColor;
  final AppBrazilStoreSalesMarkerVisual visual;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppThemeTokens>()!;
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.only(top: tokens.gapMd),
      child: BrazilMapChartAuxiliarySurface(
        child: Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            key: const ValueKey<String>('brazil-store-sales-map-legend-button'),
            onPressed: () => _showLegendSheet(context),
            icon: const Icon(Icons.info_outline_rounded, size: 18),
            label: Text(
              AppLocalizations.of(context).brazilStoreSalesMapLegendButton,
            ),
            style: TextButton.styleFrom(
              visualDensity: VisualDensity.compact,
              foregroundColor: colorScheme.onSurfaceVariant,
              padding: EdgeInsets.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ),
      ),
    );
  }

  void _showLegendSheet(BuildContext context) {
    unawaited(
      showModalBottomSheet<void>(
        context: context,
        useSafeArea: true,
        showDragHandle: true,
        builder: (context) {
          final tokens = Theme.of(context).extension<AppThemeTokens>()!;
          return Padding(
            padding: EdgeInsets.fromLTRB(
              tokens.contentSpacing,
              tokens.gapSm,
              tokens.contentSpacing,
              tokens.contentSpacing,
            ),
            child: KeyedSubtree(
              key: const ValueKey<String>(
                'brazil-store-sales-map-legend-content',
              ),
              child: BrazilMapChartMarkerScaleLegendContent(
                sizeLegendLabel: sizeLegendLabel,
                metric: metric,
                minValue: minValue,
                maxValue: maxValue,
                minSize: minSize,
                maxSize: maxSize,
                color: color,
                strokeColor: strokeColor,
                visual: visual,
              ),
            ),
          );
        },
      ),
    );
  }
}

class BrazilMapChartMarkerScaleLegendContent extends StatelessWidget {
  const BrazilMapChartMarkerScaleLegendContent({
    required this.sizeLegendLabel,
    required this.metric,
    required this.minValue,
    required this.maxValue,
    required this.minSize,
    required this.maxSize,
    required this.color,
    required this.strokeColor,
    required this.visual,
  });

  final String sizeLegendLabel;
  final AppBrazilStoreSalesMapMetric metric;
  final num minValue;
  final num maxValue;
  final double minSize;
  final double maxSize;
  final Color color;
  final Color strokeColor;
  final AppBrazilStoreSalesMarkerVisual visual;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppThemeTokens>()!;
    final textStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    );
    final middleValue = maxValue <= minValue
        ? minValue
        : minValue + ((maxValue - minValue) / 2);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(sizeLegendLabel, style: textStyle),
          SizedBox(width: tokens.gapMd),
          BrazilMapChartMarkerScaleLegendItem(
            label: brazilMapChartFormatMetricValue(context, metric, minValue),
            size: minSize,
            color: color,
            strokeColor: strokeColor,
            visual: visual,
          ),
          SizedBox(width: tokens.gapMd),
          BrazilMapChartMarkerScaleLegendItem(
            label: brazilMapChartFormatMetricValue(
              context,
              metric,
              middleValue,
            ),
            size: minSize + ((maxSize - minSize) / 2),
            color: color,
            strokeColor: strokeColor,
            visual: visual,
          ),
          SizedBox(width: tokens.gapMd),
          BrazilMapChartMarkerScaleLegendItem(
            label: brazilMapChartFormatMetricValue(context, metric, maxValue),
            size: maxSize,
            color: color,
            strokeColor: strokeColor,
            visual: visual,
          ),
        ],
      ),
    );
  }
}

class BrazilMapChartAuxiliarySurface extends StatelessWidget {
  const BrazilMapChartAuxiliarySurface({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppThemeTokens>()!;
    final colorScheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        border: Border.all(color: colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(tokens.formFieldRadius),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: tokens.gapMd,
          vertical: tokens.gapSm,
        ),
        child: child,
      ),
    );
  }
}

class BrazilMapChartDataQualityNotice extends StatelessWidget {
  const BrazilMapChartDataQualityNotice({required this.diagnostics});

  final AppBrazilStoreSalesMapDiagnostics diagnostics;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppThemeTokens>()!;
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final details = <String>[
      if (diagnostics.invalidCoordinateCount > 0)
        l10n.brazilStoreSalesMapDataQualityInvalidCoords(
          brazilMapChartFormatSalesCount(
            context,
            diagnostics.invalidCoordinateCount,
          ),
        ),
      if (diagnostics.unknownUfCount > 0)
        l10n.brazilStoreSalesMapDataQualityUnknownUf(
          brazilMapChartFormatSalesCount(context, diagnostics.unknownUfCount),
        ),
      if (diagnostics.filteredByRegionCount > 0)
        l10n.brazilStoreSalesMapDataQualityOutsideClip(
          brazilMapChartFormatSalesCount(
            context,
            diagnostics.filteredByRegionCount,
          ),
        ),
    ].join(' | ');

    return Padding(
      padding: EdgeInsets.only(top: tokens.gapSm),
      child: KeyedSubtree(
        key: const ValueKey<String>('brazil-store-sales-map-data-quality'),
        child: BrazilMapChartAuxiliarySurface(
          child: Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                size: 16,
                color: colorScheme.onSurfaceVariant,
              ),
              SizedBox(width: tokens.gapSm),
              Expanded(
                child: Text(
                  '${l10n.brazilStoreSalesMapDataQualityLead(brazilMapChartFormatSalesCount(context, diagnostics.discardedPointCount))}'
                  '${details.isEmpty ? '' : ': $details'}.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class BrazilMapChartMarkerScaleLegendItem extends StatelessWidget {
  const BrazilMapChartMarkerScaleLegendItem({
    required this.label,
    required this.size,
    required this.color,
    required this.strokeColor,
    required this.visual,
  });

  final String label;
  final double size;
  final Color color;
  final Color strokeColor;
  final AppBrazilStoreSalesMarkerVisual visual;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppThemeTokens>()!;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        BrazilMapChartStoreMarker(
          style: AppMapMarkerStyle(
            size: size,
            color: color,
            strokeColor: strokeColor,
          ),
          count: 1,
          visual: visual,
          semanticLabel: label,
        ),
        SizedBox(width: tokens.gapXs),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class BrazilMapChartStateLabelResolver {
  const BrazilMapChartStateLabelResolver({
    required this.context,
    required this.style,
  });

  final BuildContext context;
  final AppBrazilStoreSalesMapStyle style;

  String labelFor(
    AppBrazilStoreSalesStateBucket bucket, {
    bool compact = false,
  }) {
    final requestedLabelMode = style.stateLabelMode;
    if (compact &&
        requestedLabelMode != AppBrazilStoreSalesStateLabelMode.stateName) {
      return bucket.uf;
    }

    final labelMode = switch (requestedLabelMode) {
      AppBrazilStoreSalesStateLabelMode.responsive =>
        AppBreakpoints.isDesktop(context)
            ? AppBrazilStoreSalesStateLabelMode.stateName
            : AppBrazilStoreSalesStateLabelMode.uf,
      final labelMode => labelMode,
    };

    return switch (labelMode) {
      AppBrazilStoreSalesStateLabelMode.uf => bucket.uf,
      AppBrazilStoreSalesStateLabelMode.stateName =>
        compact ? _compactStateNameLabel(bucket) : bucket.stateName,
      AppBrazilStoreSalesStateLabelMode.responsive => bucket.uf,
    };
  }

  TextStyle? dataLabelTextStyle({
    required bool compact,
    required double maxWidth,
  }) {
    final theme = Theme.of(context);
    final base = theme.textTheme.labelSmall;
    final requestedLabelMode = style.stateLabelMode;
    final usesStateNames =
        requestedLabelMode == AppBrazilStoreSalesStateLabelMode.stateName ||
        (requestedLabelMode == AppBrazilStoreSalesStateLabelMode.responsive &&
            AppBreakpoints.isDesktop(context));
    final compactStateNames = compact && usesStateNames;
    final fontSize = compactStateNames
        ? _compactStateLabelFontSize(maxWidth)
        : (compact ? 10.0 : null);

    return base?.copyWith(
      color: theme.colorScheme.onSurface.withValues(
        alpha: compactStateNames ? 0.88 : 1,
      ),
      fontWeight: compactStateNames ? FontWeight.w800 : FontWeight.w700,
      fontSize: fontSize,
      height: compactStateNames ? 1.04 : null,
    );
  }

  double _compactStateLabelFontSize(double maxWidth) {
    if (!maxWidth.isFinite) {
      return 9;
    }
    if (maxWidth < 380) {
      return 7;
    }
    if (maxWidth < 600) {
      return 8;
    }
    return 9;
  }

  String _compactStateNameLabel(AppBrazilStoreSalesStateBucket bucket) {
    final languageCode = Localizations.localeOf(context).languageCode;
    if (languageCode != 'pt') {
      return bucket.stateName;
    }
    return switch (bucket.uf) {
      'DF' => 'Distrito\nFederal',
      'ES' => 'Espirito\nSanto',
      'MS' => 'Mato Grosso\ndo Sul',
      'MT' => 'Mato\nGrosso',
      'MG' => 'Minas\nGerais',
      'RJ' => 'Rio de\nJaneiro',
      'RN' => 'Rio Grande\ndo Norte',
      'RS' => 'Rio Grande\ndo Sul',
      'SC' => 'Santa\nCatarina',
      'SP' => 'Sao\nPaulo',
      final _ => bucket.stateName,
    };
  }
}

class BrazilMapChartStoreMarker extends StatelessWidget {
  const BrazilMapChartStoreMarker({
    required this.style,
    required this.count,
    required this.visual,
    required this.semanticLabel,
    super.key,
  });

  final AppMapMarkerStyle style;
  final int count;
  final AppBrazilStoreSalesMarkerVisual visual;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final markerColor = style.color ?? context.appColors.tertiary;
    final markerStrokeColor =
        style.strokeColor ?? Theme.of(context).colorScheme.surface;
    final dimension = style.size;
    final showCount = count > 1 && dimension >= 22;
    final colorScheme = Theme.of(context).colorScheme;

    return Semantics(
      button: true,
      label: semanticLabel,
      child: SizedBox.square(
        dimension: dimension,
        child: switch (visual) {
          AppBrazilStoreSalesMarkerVisual.dot => DecoratedBox(
            decoration: BoxDecoration(
              color: markerColor,
              shape: BoxShape.circle,
              border: Border.all(
                color: markerStrokeColor,
                width: style.strokeWidth,
              ),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.shadow.withValues(alpha: 0.16),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: showCount
                ? Center(
                    child: Text(
                      count > 99 ? '99+' : count.toString(),
                      maxLines: 1,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: colorScheme.onTertiary,
                        fontWeight: FontWeight.w800,
                        fontSize: dimension >= 28 ? 10 : 8,
                      ),
                    ),
                  )
                : null,
          ),
          AppBrazilStoreSalesMarkerVisual.bubble => DecoratedBox(
            decoration: BoxDecoration(
              color: markerColor.withValues(alpha: 0.16),
              shape: BoxShape.circle,
              border: Border.all(
                color: markerColor.withValues(alpha: 0.82),
                width: 2.2,
              ),
            ),
            child: showCount
                ? Center(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: colorScheme.surface.withValues(alpha: 0.86),
                        shape: BoxShape.circle,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Text(
                          count > 99 ? '99+' : count.toString(),
                          maxLines: 1,
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: markerColor,
                                fontWeight: FontWeight.w800,
                                fontSize: dimension >= 48 ? 11 : 9,
                              ),
                        ),
                      ),
                    ),
                  )
                : null,
          ),
          AppBrazilStoreSalesMarkerVisual.storeIcon => Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: markerColor,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: markerStrokeColor,
                      width: style.strokeWidth,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.shadow.withValues(alpha: 0.18),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.storefront_rounded,
                    size: (dimension * 0.52).clamp(13, 22).toDouble(),
                    color: colorScheme.onTertiary,
                  ),
                ),
              ),
              if (showCount)
                Positioned(
                  right: -2,
                  top: -2,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: markerColor,
                        width: 1.4,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(
                        BrazilMapLayoutConstants.tightInternalPadding,
                      ),
                      child: Text(
                        count > 99 ? '99+' : count.toString(),
                        maxLines: 1,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: markerColor,
                          fontWeight: FontWeight.w800,
                          fontSize: 8,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        },
      ),
    );
  }
}
