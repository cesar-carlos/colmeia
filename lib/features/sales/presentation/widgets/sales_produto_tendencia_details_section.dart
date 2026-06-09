import 'dart:math' as math;

import 'package:colmeia/features/agent_queries/domain/entities/produto_vendido_tendencia_de_venda_row.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_colors.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/app_section_card_with_heading.dart';
import 'package:colmeia/shared/widgets/app_skeleton.dart';
import 'package:colmeia/shared/widgets/charts/chart_horizontal_scroll_shell.dart';
import 'package:colmeia/shared/widgets/pagination/app_table_pagination_footer.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SalesProdutoTendenciaDetailsSection extends StatelessWidget {
  const SalesProdutoTendenciaDetailsSection({
    required this.l10n,
    required this.rows,
    required this.totalCount,
    required this.loading,
    required this.currentPage,
    required this.pageSize,
    required this.onPageSelected,
    required this.onPageSizeChanged,
    required this.classLabelBuilder,
    super.key,
  });

  final AppLocalizations l10n;
  final List<ProdutoVendidoTendenciaDeVendaRow> rows;
  final int totalCount;
  final bool loading;
  final int currentPage;
  final int pageSize;
  final ValueChanged<int> onPageSelected;
  final ValueChanged<int> onPageSizeChanged;
  final String Function(String value) classLabelBuilder;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.appTokens;
    final rowNumber = NumberFormat.decimalPattern(l10n.localeName);
    final totalPages = totalCount == 0
        ? 0
        : (totalCount / pageSize).ceil();
    final rangeStart = totalCount == 0
        ? 0
        : ((currentPage - 1) * pageSize) + 1;
    final rangeEnd = totalCount == 0
        ? 0
        : math.min(currentPage * pageSize, totalCount);

    return AppSectionCardWithHeading(
      title: l10n.salesProdutoTendenciaDetailsTitle,
      subtitle: l10n.salesProdutoTendenciaDetailsSubtitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (rows.isNotEmpty) ...<Widget>[
            SizedBox(height: tokens.gapXs),
            Text(
              l10n.salesProdutoTendenciaDetailsHorizontalScrollCaption,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          SizedBox(height: tokens.contentSpacing),
          if (loading && rows.isEmpty)
            AppSkeleton(
              enabled: true,
              loadingSemanticsLabel:
                  l10n.salesProdutoTendenciaLoadingTrendSemantics,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  for (var i = 0; i < 5; i++) ...<Widget>[
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: tokens.gapSm,
                        vertical: tokens.gapSm,
                      ),
                      child: const Text(
                        '—',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (i < 4)
                      Divider(
                        height: tokens.gapMd * 2,
                        color: theme.colorScheme.outlineVariant.withValues(
                          alpha: 0.35,
                        ),
                      ),
                  ],
                ],
              ),
            )
          else if (rows.isEmpty)
            Text(
              l10n.salesProdutoTendenciaNoData,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            )
          else ...<Widget>[
            LayoutBuilder(
              builder: (context, constraints) {
                final minTable =
                    SalesProdutoTendenciaDetailsTableLayout.minScrollContentWidth(
                      tokens,
                    );
                final outer = constraints.maxWidth;
                final contentWidth = outer.isFinite && outer > 0
                    ? math.max(outer, minTable)
                    : minTable;
                return ChartHorizontalScrollShell(
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: SizedBox(
                      width: contentWidth,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          SalesProdutoTendenciaDetailsTableHeader(l10n: l10n),
                          Divider(
                            height: tokens.gapMd * 2,
                            color: theme.colorScheme.outlineVariant.withValues(
                              alpha: 0.5,
                            ),
                          ),
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: rows.length,
                            separatorBuilder: (_, _) => Divider(
                              height: tokens.gapMd * 2,
                              color: theme.colorScheme.outlineVariant
                                  .withValues(alpha: 0.35),
                            ),
                            itemBuilder: (context, index) {
                              final row = rows[index];
                              return SalesProdutoTendenciaDetailsRow(
                                row: row,
                                l10n: l10n,
                                classLabel: classLabelBuilder(
                                  row.classificacao,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  semanticsHint:
                      l10n.salesProdutoTendenciaDetailsHorizontalScrollCaption,
                );
              },
            ),
            SizedBox(height: tokens.contentSpacing),
            AppTablePaginationFooter(
              currentPage: currentPage,
              totalPages: totalPages,
              pageSize: pageSize,
              rangeStart: rangeStart,
              rangeEnd: rangeEnd,
              totalItems: totalCount,
              entityLabel: l10n.salesProdutoTendenciaDetailsEntityLabel,
              pageSizeOptions: const <int>[10, 20, 50, 100],
              itemsPerPageLabel: l10n.salesProdutoTendenciaFilterPageSize,
              onPageSizeChanged: onPageSizeChanged,
              onPrevious: currentPage > 1
                  ? () => onPageSelected(currentPage - 1)
                  : null,
              onNext: currentPage < totalPages
                  ? () => onPageSelected(currentPage + 1)
                  : null,
              onPageSelected: onPageSelected,
            ),
            SizedBox(height: tokens.gapSm),
            Text(
              l10n.salesProdutoTendenciaDetailsNotice(
                rowNumber.format(pageSize),
              ),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Minimum column widths for the trend details grid so labels stay on one line
/// when the viewport is narrow; the table scrolls horizontally as a unit.
abstract final class SalesProdutoTendenciaDetailsTableLayout {
  static double _product(AppThemeTokens t) => math.max(220, t.gapMd * 18);
  static double _classificacao(AppThemeTokens t) => math.max(120, t.gapMd * 10);
  static double _grupo(AppThemeTokens t) => math.max(132, t.gapMd * 11);
  static double _delta(AppThemeTokens t) => math.max(104, t.gapMd * 9);
  static double _percentual(AppThemeTokens t) => math.max(104, t.gapMd * 9);

  static double minWidth(AppThemeTokens t) =>
      _product(t) + _classificacao(t) + _grupo(t) + _delta(t) + _percentual(t);

  /// Row [Padding] uses [AppThemeTokens.gapSm] on each horizontal side.
  static double minScrollContentWidth(AppThemeTokens t) =>
      minWidth(t) + 2 * t.gapSm;
}

class SalesProdutoTendenciaDetailsTableHeader extends StatelessWidget {
  const SalesProdutoTendenciaDetailsTableHeader({required this.l10n, super.key});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.appTokens;
    final style = theme.textTheme.labelMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
      fontWeight: FontWeight.w700,
    );
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: tokens.gapSm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: SalesProdutoTendenciaDetailsTableLayout._product(tokens),
            child: Text(l10n.salesProdutoTendenciaColProduct, style: style),
          ),
          SizedBox(
            width: SalesProdutoTendenciaDetailsTableLayout._classificacao(
              tokens,
            ),
            child: Text(
              l10n.salesProdutoTendenciaColClassificacao,
              style: style,
            ),
          ),
          SizedBox(
            width: SalesProdutoTendenciaDetailsTableLayout._grupo(tokens),
            child: Text(l10n.salesProdutoTendenciaColGrupo, style: style),
          ),
          SizedBox(
            width: SalesProdutoTendenciaDetailsTableLayout._delta(tokens),
            child: Text(
              l10n.salesProdutoTendenciaColDiferenca,
              style: style,
              textAlign: TextAlign.end,
            ),
          ),
          SizedBox(
            width: SalesProdutoTendenciaDetailsTableLayout._percentual(tokens),
            child: Text(
              l10n.salesProdutoTendenciaColPercentual,
              style: style,
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}

class SalesProdutoTendenciaDetailsRow extends StatelessWidget {
  const SalesProdutoTendenciaDetailsRow({
    required this.row,
    required this.l10n,
    required this.classLabel,
    super.key,
  });

  final ProdutoVendidoTendenciaDeVendaRow row;
  final AppLocalizations l10n;
  final String classLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.appTokens;
    final numberFmt = NumberFormat.decimalPattern(l10n.localeName);
    final percentText = '${row.percentualTendencia.toStringAsFixed(1)}%';
    const tabularFigures = <FontFeature>[FontFeature.tabularFigures()];

    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 48),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: tokens.gapSm),
        child: Row(
          children: <Widget>[
            SizedBox(
              width: SalesProdutoTendenciaDetailsTableLayout._product(tokens),
              child: Text(
                row.nomeProduto,
                softWrap: true,
                maxLines: 4,
              ),
            ),
            SizedBox(
              width: SalesProdutoTendenciaDetailsTableLayout._classificacao(
                tokens,
              ),
              child: Text(
                classLabel,
                softWrap: true,
                maxLines: 3,
                style: theme.textTheme.bodySmall,
              ),
            ),
            SizedBox(
              width: SalesProdutoTendenciaDetailsTableLayout._grupo(tokens),
              child: Text(
                (row.nomeGrupoProduto?.trim().isNotEmpty ?? false)
                    ? row.nomeGrupoProduto!
                    : l10n.salesProdutoTendenciaFilterAllOption,
                softWrap: true,
                maxLines: 4,
              ),
            ),
            SizedBox(
              width: SalesProdutoTendenciaDetailsTableLayout._delta(tokens),
              child: Text(
                numberFmt.format(row.diferenca.round()),
                textAlign: TextAlign.end,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontFeatures: tabularFigures,
                ),
              ),
            ),
            SizedBox(
              width: SalesProdutoTendenciaDetailsTableLayout._percentual(
                tokens,
              ),
              child: Text(
                percentText,
                textAlign: TextAlign.end,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontFeatures: tabularFigures,
                  color: row.percentualTendencia >= 0
                      ? theme.appColors.tertiary
                      : theme.appColors.error,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
