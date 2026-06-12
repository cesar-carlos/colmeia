import 'dart:async';

import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/charts/app_brazil_store_sales_map_chart/brazil_map_chart_auxiliary_surface.dart';
import 'package:colmeia/shared/widgets/charts/app_brazil_store_sales_map_chart/brazil_map_chart_store_marker_widget.dart';
import 'package:colmeia/shared/widgets/charts/app_brazil_store_sales_map_models.dart';
import 'package:colmeia/shared/widgets/charts/app_map_models.dart';
import 'package:colmeia/shared/widgets/charts/brazil_map_store_sales_display_helpers.dart';
import 'package:flutter/material.dart';

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
    super.key,
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
    super.key,
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
              foregroundColor: colorScheme.onSurfaceVariant,
              padding: EdgeInsets.symmetric(
                horizontal: tokens.gapSm,
                vertical: tokens.gapXs,
              ),
              minimumSize: const Size(48, 48),
              tapTargetSize: MaterialTapTargetSize.padded,
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
    super.key,
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
class BrazilMapChartMarkerScaleLegendItem extends StatelessWidget {
  const BrazilMapChartMarkerScaleLegendItem({
    required this.label,
    required this.size,
    required this.color,
    required this.strokeColor,
    required this.visual,
    super.key,
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
