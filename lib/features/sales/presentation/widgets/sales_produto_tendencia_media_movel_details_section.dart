import 'dart:math' as math;

import 'package:colmeia/features/agent_queries/domain/entities/produto_vendido_tendencia_de_venda_media_movel_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/produto_vendido_tendencia_de_venda_media_movel_row.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_produto_tendencia_filtered_empty_state.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_produto_tendencia_media_movel_classificacao_labels.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_produto_tendencia_media_movel_section_header.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_data_grid_density.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/app_compact_data_grid_scroll_table.dart';
import 'package:colmeia/shared/widgets/app_section_card.dart';
import 'package:colmeia/shared/widgets/app_skeleton.dart';
import 'package:colmeia/shared/widgets/pagination/app_table_pagination_footer.dart';
import 'package:colmeia/shared/widgets/pagination/app_table_pagination_notice.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SalesProdutoTendenciaMediaMovelDetailsSection extends StatelessWidget {
  const SalesProdutoTendenciaMediaMovelDetailsSection({
    required this.l10n,
    required this.rows,
    required this.totalCount,
    required this.pageSize,
    required this.currentPage,
    required this.totalPages,
    required this.rangeStart,
    required this.rangeEnd,
    required this.sortBy,
    required this.onPageSelected,
    required this.onNext,
    required this.onPrevious,
    required this.onPageSizeChanged,
    this.loading = false,
    this.headerTrailing,
    super.key,
    this.hasActiveDetailFilters = false,
    this.onClearFilters,
    this.onOpenFilters,
  });

  final AppLocalizations l10n;
  final bool loading;
  final List<ProdutoVendidoTendenciaDeVendaMediaMovelRow> rows;
  final int totalCount;
  final int pageSize;
  final int currentPage;
  final int totalPages;
  final int rangeStart;
  final int rangeEnd;
  final ProdutoVendidoTendenciaDeVendaMediaMovelSortBy sortBy;
  final ValueChanged<int> onPageSelected;
  final VoidCallback? onNext;
  final VoidCallback? onPrevious;
  final ValueChanged<int> onPageSizeChanged;
  final Widget? headerTrailing;
  final bool hasActiveDetailFilters;
  final VoidCallback? onClearFilters;
  final VoidCallback? onOpenFilters;

  @override
  Widget build(BuildContext context) {
    final tokens = context.appTokens;
    final decimalFormat = NumberFormat.decimalPattern(l10n.localeName);
    final scrollHint =
        l10n.salesProdutoTendenciaMediaMovelDetailsHorizontalScrollCaption;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        SalesProdutoTendenciaMediaMovelSectionHeader(
          title: l10n.salesProdutoTendenciaMediaMovelDetailsTitle,
          subtitle: l10n.salesProdutoTendenciaMediaMovelDetailsSubtitle,
          trailing: headerTrailing,
        ),
        SizedBox(height: tokens.gapMd),
        AppSectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                l10n.salesProdutoTendenciaMediaMovelDetailsSortedBy(
                  produtoTendenciaMediaMovelSortLabel(l10n, sortBy),
                ),
              ),
              SizedBox(height: tokens.gapXs),
              if (loading && rows.isEmpty)
                AppSkeleton(
                  enabled: true,
                  loadingSemanticsLabel:
                      l10n.salesProdutoTendenciaLoadingTrendSemantics,
                  child: appDataGridSkeletonColumn(
                    tokens: tokens,
                    dividerColor: Theme.of(context)
                        .colorScheme
                        .outlineVariant
                        .withValues(alpha: 0.35),
                  ),
                )
              else if (rows.isEmpty)
                SalesProdutoTendenciaFilteredEmptyState(
                  l10n: l10n,
                  message: l10n.salesProdutoTendenciaMediaMovelNoData,
                  hasActiveDetailFilters: hasActiveDetailFilters,
                  onClearFilters: onClearFilters,
                  onOpenFilters: onOpenFilters,
                )
              else
                AppSkeleton(
                  enabled: loading,
                  loadingSemanticsLabel:
                      l10n.salesProdutoTendenciaMediaMovelChartNavLoadingSemantics,
                  child: LayoutBuilder(
                  builder: (context, constraints) {
                    final minTableWidth =
                        _SalesProdutoTendenciaMediaMovelDetailsTableLayout.minScrollContentWidth(
                          tokens,
                        );
                    final outerWidth = constraints.maxWidth;
                    final resolvedWidth = outerWidth.isFinite && outerWidth > 0
                        ? math.max(outerWidth, minTableWidth)
                        : minTableWidth;
                    final hasHorizontalOverflow =
                        outerWidth.isFinite &&
                        outerWidth > 0 &&
                        minTableWidth > outerWidth;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        if (hasHorizontalOverflow) ...<Widget>[
                          Text(
                            scrollHint,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                          ),
                          SizedBox(height: tokens.gapXs),
                        ],
                        AppCompactDataGridScrollTable(
                          contentWidth: resolvedWidth,
                          itemCount: rows.length,
                          semanticsHint:
                              hasHorizontalOverflow ? scrollHint : null,
                          showHorizontalFade: hasHorizontalOverflow,
                          header:
                              SalesProdutoTendenciaMediaMovelDetailsTableHeader(
                            l10n: l10n,
                          ),
                          itemBuilder: (context, index) {
                            return SalesProdutoTendenciaMediaMovelDetailsRow(
                              row: rows[index],
                              l10n: l10n,
                              decimalFormat: decimalFormat,
                            );
                          },
                        ),
                      ],
                    );
                  },
                ),
                ),
              if (rows.isNotEmpty) ...<Widget>[
                AppTablePaginationNotice(
                  totalPages: totalPages,
                  message: l10n.salesProdutoTendenciaMediaMovelDetailsNotice(
                    '$pageSize',
                  ),
                ),
              ],
              if (totalPages > 0) ...<Widget>[
                SizedBox(height: tokens.gapMd),
                AppTablePaginationFooter(
                  currentPage: currentPage,
                  totalPages: totalPages,
                  pageSize: pageSize,
                  rangeStart: rangeStart,
                  rangeEnd: rangeEnd,
                  totalItems: totalCount,
                  entityLabel:
                      l10n.salesProdutoTendenciaMediaMovelDetailsEntityLabel,
                  onPrevious: onPrevious,
                  onNext: onNext,
                  onPageSelected: onPageSelected,
                  pageSizeOptions: const <int>[10, 20, 50, 100],
                  onPageSizeChanged: onPageSizeChanged,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _SalesProdutoTendenciaMediaMovelDetailsTableLayout {
  static const double _product = 320;
  static const double _classification = 180;
  static const double _group = 180;
  static const double _numeric = 132;

  static double product(AppThemeTokens tokens) => _product;
  static double classification(AppThemeTokens tokens) => _classification;
  static double group(AppThemeTokens tokens) => _group;
  static double numeric(AppThemeTokens tokens) => _numeric;

  static double minScrollContentWidth(AppThemeTokens tokens) {
    return _product +
        _classification +
        _group +
        (_numeric * 4) +
        (tokens.gapSm * 2);
  }
}

class SalesProdutoTendenciaMediaMovelDetailsTableHeader extends StatelessWidget {
  const SalesProdutoTendenciaMediaMovelDetailsTableHeader({
    required this.l10n,
    super.key,
  });

  final AppLocalizations l10n;

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
    return DecoratedBox(
      decoration: appDataGridHeaderDecoration(scheme),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: kAppCompactHeaderRowHeight),
        child: Padding(
          padding: appDataGridRowPadding(tokens),
          child: Row(
            children: <Widget>[
              SizedBox(
                width: _SalesProdutoTendenciaMediaMovelDetailsTableLayout.product(
                  tokens,
                ),
                child: Text(
                  l10n.salesProdutoTendenciaMediaMovelColProduct,
                  style: labelStyle,
                ),
              ),
              SizedBox(
                width:
                    _SalesProdutoTendenciaMediaMovelDetailsTableLayout.classification(
                  tokens,
                ),
                child: Text(
                  l10n.salesProdutoTendenciaMediaMovelColClassificacao,
                  style: labelStyle,
                ),
              ),
              SizedBox(
                width: _SalesProdutoTendenciaMediaMovelDetailsTableLayout.group(
                  tokens,
                ),
                child: Text(
                  l10n.salesProdutoTendenciaMediaMovelColGrupo,
                  style: labelStyle,
                ),
              ),
              SizedBox(
                width: _SalesProdutoTendenciaMediaMovelDetailsTableLayout.numeric(
                  tokens,
                ),
                child: Text(
                  l10n.salesProdutoTendenciaMediaMovelColMediaAtual,
                  style: endLabelStyle,
                  textAlign: TextAlign.end,
                ),
              ),
              SizedBox(
                width: _SalesProdutoTendenciaMediaMovelDetailsTableLayout.numeric(
                  tokens,
                ),
                child: Text(
                  l10n.salesProdutoTendenciaMediaMovelColMediaAnterior,
                  style: endLabelStyle,
                  textAlign: TextAlign.end,
                ),
              ),
              SizedBox(
                width: _SalesProdutoTendenciaMediaMovelDetailsTableLayout.numeric(
                  tokens,
                ),
                child: Text(
                  l10n.salesProdutoTendenciaMediaMovelColDiferenca,
                  style: endLabelStyle,
                  textAlign: TextAlign.end,
                ),
              ),
              SizedBox(
                width: _SalesProdutoTendenciaMediaMovelDetailsTableLayout.numeric(
                  tokens,
                ),
                child: Text(
                  l10n.salesProdutoTendenciaMediaMovelColPercentual,
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

class SalesProdutoTendenciaMediaMovelDetailsRow extends StatelessWidget {
  const SalesProdutoTendenciaMediaMovelDetailsRow({
    required this.row,
    required this.l10n,
    required this.decimalFormat,
    super.key,
  });

  final ProdutoVendidoTendenciaDeVendaMediaMovelRow row;
  final AppLocalizations l10n;
  final NumberFormat decimalFormat;

  static const List<FontFeature> _tabularFigures = <FontFeature>[
    FontFeature.tabularFigures(),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.appTokens;
    final numericStyle = theme.textTheme.bodyMedium?.copyWith(
      fontFeatures: _tabularFigures,
    );

    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: kAppCompactDataRowHeight),
      child: Padding(
        padding: appDataGridRowPadding(tokens),
        child: Row(
          children: <Widget>[
            SizedBox(
              width: _SalesProdutoTendenciaMediaMovelDetailsTableLayout.product(
                tokens,
              ),
              child: Text(
                row.nomeProduto,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(
              width:
                  _SalesProdutoTendenciaMediaMovelDetailsTableLayout.classification(
                tokens,
              ),
              child: Text(
                produtoTendenciaMediaMovelClassificacaoLabel(
                  l10n,
                  row.classificacao,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall,
              ),
            ),
            SizedBox(
              width: _SalesProdutoTendenciaMediaMovelDetailsTableLayout.group(
                tokens,
              ),
              child: Text(
                row.nomeGrupoProduto ?? '-',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(
              width: _SalesProdutoTendenciaMediaMovelDetailsTableLayout.numeric(
                tokens,
              ),
              child: Text(
                decimalFormat.format(row.mediaAtual),
                textAlign: TextAlign.end,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: numericStyle,
              ),
            ),
            SizedBox(
              width: _SalesProdutoTendenciaMediaMovelDetailsTableLayout.numeric(
                tokens,
              ),
              child: Text(
                decimalFormat.format(row.mediaAnterior),
                textAlign: TextAlign.end,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: numericStyle,
              ),
            ),
            SizedBox(
              width: _SalesProdutoTendenciaMediaMovelDetailsTableLayout.numeric(
                tokens,
              ),
              child: Text(
                decimalFormat.format(row.diferenca),
                textAlign: TextAlign.end,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: numericStyle,
              ),
            ),
            SizedBox(
              width: _SalesProdutoTendenciaMediaMovelDetailsTableLayout.numeric(
                tokens,
              ),
              child: Text(
                '${decimalFormat.format(row.tendenciaPercentual)}%',
                textAlign: TextAlign.end,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontFeatures: _tabularFigures,
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
