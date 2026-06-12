import 'package:colmeia/core/layout/app_breakpoints.dart';
import 'package:colmeia/shared/widgets/charts/app_brazil_store_sales_map_models.dart';
import 'package:flutter/material.dart';

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
