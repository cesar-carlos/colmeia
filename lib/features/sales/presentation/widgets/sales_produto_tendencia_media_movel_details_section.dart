import 'dart:math' as math;

import 'package:colmeia/features/agent_queries/domain/entities/produto_vendido_tendencia_de_venda_media_movel_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/produto_vendido_tendencia_de_venda_media_movel_row.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_produto_tendencia_filtered_empty_state.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_produto_tendencia_media_movel_classificacao_labels.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_produto_tendencia_media_movel_section_header.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/app_section_card.dart';
import 'package:colmeia/shared/widgets/app_skeleton.dart';
import 'package:colmeia/shared/widgets/charts/chart_horizontal_scroll_shell.dart';
import 'package:colmeia/shared/widgets/pagination/app_table_pagination_footer.dart';
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
                            color: Theme.of(context)
                                .colorScheme
                                .outlineVariant
                                .withValues(alpha: 0.35),
                          ),
                      ],
                    ],
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
                          Text(scrollHint),
                          SizedBox(height: tokens.gapMd),
                        ],
                        ChartHorizontalScrollShell(
                          ConstrainedBox(
                            constraints: BoxConstraints(
                              minWidth: resolvedWidth,
                            ),
                            child: DataTable(
                              columns: <DataColumn>[
                                DataColumn(
                                  label: Text(
                                    l10n.salesProdutoTendenciaMediaMovelColProduct,
                                  ),
                                ),
                                DataColumn(
                                  label: Text(
                                    l10n.salesProdutoTendenciaMediaMovelColClassificacao,
                                  ),
                                ),
                                DataColumn(
                                  label: Text(
                                    l10n.salesProdutoTendenciaMediaMovelColGrupo,
                                  ),
                                ),
                                DataColumn(
                                  numeric: true,
                                  label: Text(
                                    l10n.salesProdutoTendenciaMediaMovelColMediaAtual,
                                  ),
                                ),
                                DataColumn(
                                  numeric: true,
                                  label: Text(
                                    l10n.salesProdutoTendenciaMediaMovelColMediaAnterior,
                                  ),
                                ),
                                DataColumn(
                                  numeric: true,
                                  label: Text(
                                    l10n.salesProdutoTendenciaMediaMovelColDiferenca,
                                  ),
                                ),
                                DataColumn(
                                  numeric: true,
                                  label: Text(
                                    l10n.salesProdutoTendenciaMediaMovelColPercentual,
                                  ),
                                ),
                              ],
                              rows: rows
                                  .map(
                                    (row) => DataRow(
                                      cells: <DataCell>[
                                        DataCell(Text(row.nomeProduto)),
                                        DataCell(
                                          Text(
                                            produtoTendenciaMediaMovelClassificacaoLabel(
                                              l10n,
                                              row.classificacao,
                                            ),
                                          ),
                                        ),
                                        DataCell(
                                          Text(row.nomeGrupoProduto ?? '-'),
                                        ),
                                        DataCell(
                                          Text(
                                            decimalFormat.format(
                                              row.mediaAtual,
                                            ),
                                          ),
                                        ),
                                        DataCell(
                                          Text(
                                            decimalFormat.format(
                                              row.mediaAnterior,
                                            ),
                                          ),
                                        ),
                                        DataCell(
                                          Text(
                                            decimalFormat.format(
                                              row.diferenca,
                                            ),
                                          ),
                                        ),
                                        DataCell(
                                          Text(
                                            '${decimalFormat.format(row.tendenciaPercentual)}%',
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                  .toList(growable: false),
                            ),
                          ),
                          bottomTrackSlot:
                              kChartHorizontalScrollBottomTrackSlot,
                          semanticsHint: hasHorizontalOverflow
                              ? scrollHint
                              : null,
                          showFade: hasHorizontalOverflow,
                        ),
                      ],
                    );
                  },
                ),
                ),
              if (rows.isNotEmpty) ...<Widget>[
                SizedBox(height: tokens.gapMd),
                Text(
                  l10n.salesProdutoTendenciaMediaMovelDetailsNotice(
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
  static const double _horizontalMargins = 96;

  static double minScrollContentWidth(AppThemeTokens tokens) {
    return _product +
        _classification +
        _group +
        (_numeric * 4) +
        _horizontalMargins +
        (tokens.gapMd * 2);
  }
}
