import 'package:colmeia/core/formatters/app_br_formatters.dart';
import 'package:colmeia/features/agent_queries/domain/entities/produto_vendido_tendencia_de_venda_summary_row.dart';
import 'package:colmeia/features/sales/presentation/share/sales_produto_tendencia_share.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_produto_tendencia_kpi_card.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_colors.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/app_inline_error_panel.dart';
import 'package:colmeia/shared/widgets/app_section_card_with_heading.dart';
import 'package:colmeia/shared/widgets/app_skeleton.dart';
import 'package:colmeia/shared/widgets/app_tag_chip.dart';
import 'package:colmeia/shared/widgets/metrics/app_responsive_metric_stat_grid.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SalesProdutoTendenciaSummarySection extends StatelessWidget {
  const SalesProdutoTendenciaSummarySection({
    required this.l10n,
    required this.summaryRows,
    required this.loading,
    required this.periodoAtual,
    required this.periodoAnterior,
    required this.periodoAtualDescriptor,
    required this.periodoAnteriorDescriptor,
    super.key,
  });

  final AppLocalizations l10n;
  final List<ProdutoVendidoTendenciaDeVendaSummaryRow> summaryRows;
  final bool loading;
  final DateTimeRange periodoAtual;
  final DateTimeRange periodoAnterior;
  final String periodoAtualDescriptor;
  final String periodoAnteriorDescriptor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.appTokens;
    final colors = theme.appColors;
    final summary = buildSalesProdutoTendenciaSummary(summaryRows);

    return AppSectionCardWithHeading(
      title: l10n.salesProdutoTendenciaSummaryTitle,
      subtitle: l10n.salesProdutoTendenciaSummarySubtitle,
      headingBottom: Wrap(
        spacing: tokens.gapSm,
        runSpacing: tokens.gapSm,
        children: <Widget>[
          AppTagChip(
            icon: Icons.timeline_rounded,
            label:
                '${l10n.salesProdutoTendenciaComparisonCurrentChip}: '
                '${AppBrFormatters.shortDate(periodoAtual.start)} - '
                '${AppBrFormatters.shortDate(periodoAtual.end)} • '
                '$periodoAtualDescriptor',
          ),
          AppTagChip(
            icon: Icons.history_rounded,
            label:
                '${l10n.salesProdutoTendenciaComparisonPreviousChip}: '
                '${AppBrFormatters.shortDate(periodoAnterior.start)} - '
                '${AppBrFormatters.shortDate(periodoAnterior.end)} • '
                '$periodoAnteriorDescriptor',
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (loading && summaryRows.isEmpty)
            AppSkeleton(
              enabled: true,
              loadingSemanticsLabel:
                  l10n.salesProdutoTendenciaLoadingTrendSemantics,
              child: _TrendSummaryKpiStrip(
                l10n: l10n,
                summary: buildSalesProdutoTendenciaSummary(
                  const <ProdutoVendidoTendenciaDeVendaSummaryRow>[],
                ),
                colors: colors,
              ),
            )
          else if (summaryRows.isEmpty)
            AppInlineErrorPanel(
              tone: AppInlinePanelTone.informational,
              variant: AppInlineErrorPanelVariant.plain,
              message: l10n.salesProdutoTendenciaNoData,
            )
          else
            _TrendSummaryKpiStrip(
              l10n: l10n,
              summary: summary,
              colors: colors,
            ),
        ],
      ),
    );
  }
}

class _TrendSummaryKpiStrip extends StatelessWidget {
  const _TrendSummaryKpiStrip({
    required this.l10n,
    required this.summary,
    required this.colors,
  });

  final AppLocalizations l10n;
  final SalesProdutoTendenciaSummary summary;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    final locale = l10n.localeName;
    final nf = NumberFormat.decimalPattern(locale);
    return AppResponsiveMetricStatGrid(
      children: <Widget>[
        SalesProdutoTendenciaKpiCard(
          icon: Icons.trending_up_rounded,
          label: l10n.salesProdutoTendenciaKpiGrowing,
          value: nf.format(summary.countGrowing),
          iconForeground: colors.tertiary,
        ),
        SalesProdutoTendenciaKpiCard(
          icon: Icons.trending_down_rounded,
          label: l10n.salesProdutoTendenciaKpiFalling,
          value: nf.format(summary.countFalling),
          iconForeground: colors.error,
        ),
        SalesProdutoTendenciaKpiCard(
          icon: Icons.new_releases_outlined,
          label: l10n.salesProdutoTendenciaKpiNewProducts,
          value: nf.format(summary.countNew),
          iconForeground: colors.primary,
        ),
        SalesProdutoTendenciaKpiCard(
          icon: Icons.pause_circle_outline_rounded,
          label: l10n.salesProdutoTendenciaKpiStopped,
          value: nf.format(summary.countStopped),
          iconForeground: colors.onSurfaceVariant,
        ),
        SalesProdutoTendenciaKpiCard(
          icon: Icons.horizontal_rule_rounded,
          label: l10n.salesProdutoTendenciaKpiStable,
          value: nf.format(summary.countStable),
          iconForeground: colors.onSurfaceVariant,
        ),
        SalesProdutoTendenciaKpiCard(
          icon: Icons.balance_rounded,
          label: l10n.salesProdutoTendenciaKpiNetImpact,
          value: nf.format(summary.netImpact),
          iconForeground:
              summary.netImpact >= 0 ? colors.tertiary : colors.error,
        ),
      ],
    );
  }
}
