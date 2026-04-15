import 'package:colmeia/core/formatters/app_br_formatters.dart';
import 'package:colmeia/features/overview/domain/entities/overview_monthly_parcel_point.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/charts/app_combo_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class OverviewMonthlyParcelsComboChart extends StatelessWidget {
  const OverviewMonthlyParcelsComboChart({
    required this.l10n,
    required this.points,
    required this.loadFailed,
    super.key,
  });

  final AppLocalizations l10n;
  final List<OverviewMonthlyParcelPoint> points;
  final bool loadFailed;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppThemeTokens>()!;
    final localeName = Localizations.localeOf(context).toString();
    final leftAxisFormat = NumberFormat.decimalPattern(localeName);
    final rightAxisFormat =
        AppBrFormatters.compactCurrencyFormatForLocale(localeName);

    final emptyMessage = loadFailed
        ? l10n.overviewMonthlyParcelsLoadFailed
        : l10n.overviewMonthlyParcelsEmpty;

    return Semantics(
      label: l10n.overviewMonthlyParcelsChartSemantics,
      child: AppComboChart<OverviewMonthlyParcelPoint>(
        title: l10n.overviewMonthlyParcelsTitle,
        subtitle: l10n.overviewMonthlyParcelsSubtitle,
        items: points,
        xLabelBuilder: (p) => p.anoMes,
        barValueBuilder: (p) => p.qtdVendas,
        barSeriesLabel: l10n.overviewMonthlyParcelsSalesSeriesLabel,
        lineValueBuilder: (p) => p.valorParcela,
        lineSeriesLabel: l10n.overviewMonthlyParcelsAmountSeriesLabel,
        style: AppComboChartStyle(
          height: tokens.chartStandardHeight + tokens.contentSpacing,
          leftAxisFormat: leftAxisFormat,
          rightAxisFormat: rightAxisFormat,
          chartPadding: EdgeInsets.only(top: tokens.gapSm),
        ),
        emptyPlaceholder: points.isEmpty
            ? Padding(
                padding: EdgeInsets.symmetric(vertical: tokens.contentSpacing),
                child: Center(
                  child: Text(
                    emptyMessage,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              )
            : null,
      ),
    );
  }
}
