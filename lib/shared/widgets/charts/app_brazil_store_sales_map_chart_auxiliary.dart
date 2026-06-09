part of 'app_brazil_store_sales_map_chart.dart';

class _MarkerScaleLegend extends StatelessWidget {
  const _MarkerScaleLegend({
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
      child: _MapAuxiliarySurface(
        child: _MarkerScaleLegendContent(
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

class _MarkerScaleLegendMenuButton extends StatelessWidget {
  const _MarkerScaleLegendMenuButton({
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
      child: _MapAuxiliarySurface(
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
              child: _MarkerScaleLegendContent(
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

class _MarkerScaleLegendContent extends StatelessWidget {
  const _MarkerScaleLegendContent({
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
          _MarkerScaleLegendItem(
            label: _formatMetricValue(context, metric, minValue),
            size: minSize,
            color: color,
            strokeColor: strokeColor,
            visual: visual,
          ),
          SizedBox(width: tokens.gapMd),
          _MarkerScaleLegendItem(
            label: _formatMetricValue(context, metric, middleValue),
            size: minSize + ((maxSize - minSize) / 2),
            color: color,
            strokeColor: strokeColor,
            visual: visual,
          ),
          SizedBox(width: tokens.gapMd),
          _MarkerScaleLegendItem(
            label: _formatMetricValue(context, metric, maxValue),
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

class _MapAuxiliarySurface extends StatelessWidget {
  const _MapAuxiliarySurface({required this.child});

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

class _MapDataQualityNotice extends StatelessWidget {
  const _MapDataQualityNotice({required this.diagnostics});

  final AppBrazilStoreSalesMapDiagnostics diagnostics;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppThemeTokens>()!;
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final details = <String>[
      if (diagnostics.invalidCoordinateCount > 0)
        l10n.brazilStoreSalesMapDataQualityInvalidCoords(
          _formatSalesCount(context, diagnostics.invalidCoordinateCount),
        ),
      if (diagnostics.unknownUfCount > 0)
        l10n.brazilStoreSalesMapDataQualityUnknownUf(
          _formatSalesCount(context, diagnostics.unknownUfCount),
        ),
      if (diagnostics.filteredByRegionCount > 0)
        l10n.brazilStoreSalesMapDataQualityOutsideClip(
          _formatSalesCount(context, diagnostics.filteredByRegionCount),
        ),
    ].join(' | ');

    return Padding(
      padding: EdgeInsets.only(top: tokens.gapSm),
      child: KeyedSubtree(
        key: const ValueKey<String>('brazil-store-sales-map-data-quality'),
        child: _MapAuxiliarySurface(
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
                  '${l10n.brazilStoreSalesMapDataQualityLead(_formatSalesCount(context, diagnostics.discardedPointCount))}'
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

class _MarkerScaleLegendItem extends StatelessWidget {
  const _MarkerScaleLegendItem({
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
        _StoreMapMarker(
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

class _BrazilMapStateLabelResolver {
  const _BrazilMapStateLabelResolver({
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
