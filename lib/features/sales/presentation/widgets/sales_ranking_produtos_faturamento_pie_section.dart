import 'dart:math' as math;

import 'package:colmeia/core/formatters/app_br_formatters.dart';
import 'package:colmeia/features/agent_queries/domain/entities/ranking_produtos_faturamento_row.dart';
import 'package:colmeia/features/sales/presentation/utils/sales_ranking_produtos_faturamento_branch_metrics.dart';
import 'package:colmeia/features/sales/presentation/utils/sales_ranking_produtos_faturamento_donut_segments.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_ranking_produtos_faturamento_grid_style.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/design_system/app_typography_tokens.dart';
import 'package:colmeia/shared/widgets/charts/app_category_donut_card.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_presets.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_theme.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Pie chart (100% branch share) shown above the ranking detail table.
///
/// Category legend is omitted; the table below is the source of truth for labels.
class SalesRankingProdutosFaturamentoPieSection extends StatelessWidget {
  const SalesRankingProdutosFaturamentoPieSection({
    required this.l10n,
    required this.rows,
    this.isLoading = false,
    super.key,
  });

  final AppLocalizations l10n;
  final List<RankingProdutosFaturamentoRow> rows;
  final bool isLoading;

  static const AppCategoryDonutCardStyle _basePieStyle =
      AppCategoryDonutCardStyle(
        innerRadius: '0%',
        outerRadius: '88%',
        doughnutAnimationDurationMs: 0,
        showLegend: false,
      );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.appTokens;
    final total = branchRevenueTotal(rows);
    final percentFormat = NumberFormat('#,##0.0', 'pt_BR');
    final segments = rankingProdutosFaturamentoDonutSegments(
      rows: rows,
      diversosLabel: l10n.salesRankingProdutosFaturamentoDiversosLabel,
      palette: AppChartTheme.fromContext(
        context,
        preset: AppChartPreset.standard,
      ).palette,
      diversosColor: theme.colorScheme.outline.withValues(alpha: 0.55),
    );

    final titleStyle = theme.appTypography.sectionHeaderH2.copyWith(
      fontWeight: FontWeight.w700,
      fontSize: (theme.appTypography.sectionHeaderH2.fontSize ?? 18) * 0.92,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final boundedHeight =
            constraints.hasBoundedHeight && constraints.maxHeight.isFinite;
        final double chartHeight;
        if (boundedHeight) {
          chartHeight = math.max(
            160,
            constraints.maxHeight - kSalesRankingFaturamentoPieTitleBandHeight,
          );
        } else {
          chartHeight = kSalesRankingFaturamentoPieChartHeight;
        }

        final chart = AppCategoryDonutCard(
          title: l10n.salesRankingProdutosFaturamentoChartTitle,
          showHeader: false,
          wrapInSectionCard: false,
          isLoading: isLoading && rows.isEmpty,
          segments: segments,
          centerPrimaryLabel: total > 0
              ? AppBrFormatters.compactCurrency(total)
              : null,
          centerSecondaryLabel: rows.isEmpty
              ? null
              : '${percentFormat.format(branchPercentSum(rows))}%',
          style: _basePieStyle.copyWith(chartMinHeight: chartHeight),
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: boundedHeight ? MainAxisSize.max : MainAxisSize.min,
          children: <Widget>[
            Text(
              l10n.salesRankingProdutosFaturamentoChartTitle,
              style: titleStyle,
            ),
            SizedBox(height: tokens.gapSm),
            if (boundedHeight)
              Expanded(child: chart)
            else
              SizedBox(
                height: chartHeight,
                child: chart,
              ),
          ],
        );
      },
    );
  }
}
