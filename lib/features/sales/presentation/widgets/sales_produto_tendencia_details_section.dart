import 'dart:math' as math;

import 'package:colmeia/features/agent_queries/domain/entities/produto_vendido_tendencia_de_venda_row.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_produto_tendencia_filtered_empty_state.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_data_grid_density.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/app_compact_data_grid_scroll_table.dart';
import 'package:colmeia/shared/widgets/app_section_card_with_heading.dart';
import 'package:colmeia/shared/widgets/app_skeleton.dart';
import 'package:colmeia/shared/widgets/pagination/app_table_pagination_footer.dart';
import 'package:colmeia/shared/widgets/pagination/app_table_pagination_notice.dart';
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
    this.paginationEnabled = true,
    this.activeClassificacao,
    this.periodoAtualLabel,
    this.periodoAnteriorLabel,
    this.hasActiveDetailFilters = false,
    this.onClearFilters,
    this.onOpenFilters,
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
  final bool paginationEnabled;
  final String? activeClassificacao;
  final String? periodoAtualLabel;
  final String? periodoAnteriorLabel;
  final bool hasActiveDetailFilters;
  final VoidCallback? onClearFilters;
  final VoidCallback? onOpenFilters;

  bool get _showPeriodQuantityColumns => activeClassificacao != null;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.appTokens;
    final rowNumber = NumberFormat.decimalPattern(l10n.localeName);
    final totalPages = totalCount == 0 ? 0 : (totalCount / pageSize).ceil();
    final rangeStart = totalCount == 0 ? 0 : ((currentPage - 1) * pageSize) + 1;
    final rangeEnd = totalCount == 0
        ? 0
        : math.min(currentPage * pageSize, totalCount);

    return AppSectionCardWithHeading(
      title: l10n.salesProdutoTendenciaDetailsTitle,
      subtitle: l10n.salesProdutoTendenciaDetailsSubtitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (_showPeriodQuantityColumns &&
              periodoAnteriorLabel != null &&
              periodoAtualLabel != null) ...<Widget>[
            Text(
              l10n.salesProdutoTendenciaDetailsPeriodComparisonCaption(
                periodoAnteriorLabel!,
                periodoAtualLabel!,
              ),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: tokens.gapXs),
          ],
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
              child: appDataGridSkeletonColumn(
                tokens: tokens,
                dividerColor: theme.colorScheme.outlineVariant.withValues(
                  alpha: 0.35,
                ),
              ),
            )
          else if (rows.isEmpty)
            SalesProdutoTendenciaFilteredEmptyState(
              l10n: l10n,
              message: l10n.salesProdutoTendenciaNoData,
              hasActiveDetailFilters: hasActiveDetailFilters,
              onClearFilters: onClearFilters,
              onOpenFilters: onOpenFilters,
            )
          else ...<Widget>[
            AppSkeleton(
              enabled: loading,
              loadingSemanticsLabel:
                  l10n.salesProdutoTendenciaLoadingTrendSemantics,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final minTable =
                      SalesProdutoTendenciaDetailsTableLayout.minScrollContentWidth(
                        tokens,
                        showPeriodQuantityColumns: _showPeriodQuantityColumns,
                      );
                  final outer = constraints.maxWidth;
                  final contentWidth = outer.isFinite && outer > 0
                      ? math.max(outer, minTable)
                      : minTable;
                  return AppCompactDataGridScrollTable(
                    contentWidth: contentWidth,
                    itemCount: rows.length,
                    semanticsHint: l10n
                        .salesProdutoTendenciaDetailsHorizontalScrollCaption,
                    header: SalesProdutoTendenciaDetailsTableHeader(
                      l10n: l10n,
                      showPeriodQuantityColumns: _showPeriodQuantityColumns,
                    ),
                    itemBuilder: (context, index) {
                      final row = rows[index];
                      return SalesProdutoTendenciaDetailsRow(
                        row: row,
                        l10n: l10n,
                        classLabel: classLabelBuilder(row.classificacao),
                        showPeriodQuantityColumns: _showPeriodQuantityColumns,
                      );
                    },
                  );
                },
              ),
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
              enabled: paginationEnabled && !loading,
              onPageSizeChanged: onPageSizeChanged,
              onPrevious: currentPage > 1
                  ? () => onPageSelected(currentPage - 1)
                  : null,
              onNext: currentPage < totalPages
                  ? () => onPageSelected(currentPage + 1)
                  : null,
              onPageSelected: onPageSelected,
            ),
            AppTablePaginationNotice(
              totalPages: totalPages,
              message: l10n.salesProdutoTendenciaDetailsNotice(
                rowNumber.format(pageSize),
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
  static double _qtd(AppThemeTokens t) => math.max(96, t.gapMd * 8);
  static double _delta(AppThemeTokens t) => math.max(104, t.gapMd * 9);
  static double _percentual(AppThemeTokens t) => math.max(104, t.gapMd * 9);

  static double minWidth(
    AppThemeTokens t, {
    bool showPeriodQuantityColumns = false,
  }) {
    var width =
        _product(t) +
        _classificacao(t) +
        _grupo(t) +
        _delta(t) +
        _percentual(t);
    if (showPeriodQuantityColumns) {
      width += _qtd(t) * 2;
    }
    return width;
  }

  /// Row [Padding] uses [AppThemeTokens.gapSm] on each horizontal side.
  static double minScrollContentWidth(
    AppThemeTokens t, {
    bool showPeriodQuantityColumns = false,
  }) =>
      minWidth(t, showPeriodQuantityColumns: showPeriodQuantityColumns) +
      2 * t.gapSm;
}

class SalesProdutoTendenciaDetailsTableHeader extends StatelessWidget {
  const SalesProdutoTendenciaDetailsTableHeader({
    required this.l10n,
    super.key,
    this.showPeriodQuantityColumns = false,
  });

  final AppLocalizations l10n;
  final bool showPeriodQuantityColumns;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.appTokens;
    final scheme = theme.colorScheme;
    final labelStyle = appDataGridHeaderLabelStyle(theme: theme);
    final endLabelStyle = appDataGridHeaderLabelStyle(
      theme: theme,
      textAlign: TextAlign.end,
    );
    final periodHeaderStyle = endLabelStyle.copyWith(
      fontWeight: FontWeight.w700,
      color: scheme.primary,
    );
    return DecoratedBox(
      decoration: appDataGridHeaderDecoration(scheme),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minHeight: kAppCompactHeaderRowHeight,
        ),
        child: Padding(
          padding: appDataGridRowPadding(tokens),
          child: Row(
            children: <Widget>[
              SizedBox(
                width: SalesProdutoTendenciaDetailsTableLayout._product(tokens),
                child: Text(
                  l10n.salesProdutoTendenciaColProduct,
                  style: labelStyle,
                ),
              ),
              SizedBox(
                width: SalesProdutoTendenciaDetailsTableLayout._classificacao(
                  tokens,
                ),
                child: Text(
                  l10n.salesProdutoTendenciaColClassificacao,
                  style: labelStyle,
                ),
              ),
              SizedBox(
                width: SalesProdutoTendenciaDetailsTableLayout._grupo(tokens),
                child: Text(
                  l10n.salesProdutoTendenciaColGrupo,
                  style: labelStyle,
                ),
              ),
              if (showPeriodQuantityColumns) ...<Widget>[
                SizedBox(
                  width: SalesProdutoTendenciaDetailsTableLayout._qtd(tokens),
                  child: Text(
                    l10n.salesProdutoTendenciaColQtdAnterior,
                    style: periodHeaderStyle,
                    textAlign: TextAlign.end,
                  ),
                ),
                SizedBox(
                  width: SalesProdutoTendenciaDetailsTableLayout._qtd(tokens),
                  child: Text(
                    l10n.salesProdutoTendenciaColQtdAtual,
                    style: periodHeaderStyle,
                    textAlign: TextAlign.end,
                  ),
                ),
              ],
              SizedBox(
                width: SalesProdutoTendenciaDetailsTableLayout._delta(tokens),
                child: Text(
                  l10n.salesProdutoTendenciaColDiferenca,
                  style: endLabelStyle,
                  textAlign: TextAlign.end,
                ),
              ),
              SizedBox(
                width: SalesProdutoTendenciaDetailsTableLayout._percentual(
                  tokens,
                ),
                child: Text(
                  l10n.salesProdutoTendenciaColPercentual,
                  style: endLabelStyle,
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),
        ),
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
    this.showPeriodQuantityColumns = false,
  });

  final ProdutoVendidoTendenciaDeVendaRow row;
  final AppLocalizations l10n;
  final String classLabel;
  final bool showPeriodQuantityColumns;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.appTokens;
    final numberFmt = NumberFormat.decimalPattern(l10n.localeName);
    final percentText = '${row.percentualTendencia.toStringAsFixed(1)}%';
    const tabularFigures = <FontFeature>[FontFeature.tabularFigures()];

    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: kAppCompactDataRowHeight),
      child: Padding(
        padding: appDataGridRowPadding(tokens),
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
            if (showPeriodQuantityColumns) ...<Widget>[
              SizedBox(
                width: SalesProdutoTendenciaDetailsTableLayout._qtd(tokens),
                child: Text(
                  numberFmt.format(row.qtdAnterior.round()),
                  textAlign: TextAlign.end,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontFeatures: tabularFigures,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              SizedBox(
                width: SalesProdutoTendenciaDetailsTableLayout._qtd(tokens),
                child: Text(
                  numberFmt.format(row.qtdAtual.round()),
                  textAlign: TextAlign.end,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontFeatures: tabularFigures,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
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
                      ? theme.colorScheme.tertiary
                      : theme.colorScheme.error,
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
