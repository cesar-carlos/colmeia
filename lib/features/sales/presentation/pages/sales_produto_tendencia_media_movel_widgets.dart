import 'dart:math' as math;

import 'package:colmeia/features/agent_queries/domain/entities/grupo_produto_option.dart';
import 'package:colmeia/features/agent_queries/domain/entities/produto_vendido_tendencia_de_venda_media_movel_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/produto_vendido_tendencia_de_venda_media_movel_row.dart';
import 'package:colmeia/features/agent_queries/domain/entities/produto_vendido_tendencia_de_venda_media_movel_summary_row.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_filters_sheet_scaffold.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_single_agent_picker_control.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_trend_comparison_bar_chart_style.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_colors.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/filters/dashboard_filter.dart';
import 'package:colmeia/shared/widgets/app_inline_error_panel.dart';
import 'package:colmeia/shared/widgets/app_section_card.dart';
import 'package:colmeia/shared/widgets/app_skeleton.dart';
import 'package:colmeia/shared/widgets/charts/app_comparison_bar_chart.dart';
import 'package:colmeia/shared/widgets/charts/chart_horizontal_scroll_shell.dart';
import 'package:colmeia/shared/widgets/forms/app_choice_chip.dart';
import 'package:colmeia/shared/widgets/forms/app_dropdown_field.dart';
import 'package:colmeia/shared/widgets/forms/app_text_field.dart';
import 'package:colmeia/shared/widgets/metrics/app_metric_stat_card.dart';
import 'package:colmeia/shared/widgets/pagination/app_table_pagination_footer.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

const List<int> kSalesProdutoTendenciaMediaMovelWindowPresets = <int>[
  7,
  14,
  30,
  60,
];

String produtoTendenciaMediaMovelClassificacaoLabel(
  AppLocalizations l10n,
  String value,
) {
  return switch (value.trim().toUpperCase()) {
    'CRESCENDO' => l10n.salesProdutoTendenciaMediaMovelClassificacaoGrowing,
    'CAINDO' => l10n.salesProdutoTendenciaMediaMovelClassificacaoFalling,
    'NOVO' => l10n.salesProdutoTendenciaMediaMovelClassificacaoNew,
    'PAROU' => l10n.salesProdutoTendenciaMediaMovelClassificacaoStopped,
    'ESTAVEL' => l10n.salesProdutoTendenciaMediaMovelClassificacaoStable,
    _ => value,
  };
}

String produtoTendenciaMediaMovelSortLabel(
  AppLocalizations l10n,
  ProdutoVendidoTendenciaDeVendaMediaMovelSortBy sortBy,
) {
  return switch (sortBy) {
    ProdutoVendidoTendenciaDeVendaMediaMovelSortBy.tendenciaPercentualDesc =>
      l10n.salesProdutoTendenciaMediaMovelSortTrendPercent,
    ProdutoVendidoTendenciaDeVendaMediaMovelSortBy.diferencaDesc =>
      l10n.salesProdutoTendenciaMediaMovelSortDifference,
    ProdutoVendidoTendenciaDeVendaMediaMovelSortBy.nomeProdutoAsc =>
      l10n.salesProdutoTendenciaMediaMovelSortProductName,
  };
}

SalesProdutoTendenciaMediaMovelSummary
buildSalesProdutoTendenciaMediaMovelSummary(
  List<ProdutoVendidoTendenciaDeVendaMediaMovelSummaryRow> summaryRows,
) {
  final counts = <String, int>{};
  final impacts = <String, double>{};
  var netImpact = 0.0;

  for (final row in summaryRows) {
    final classificacao = row.classificacao.trim().toUpperCase();
    counts[classificacao] =
        (counts[classificacao] ?? 0) + row.quantidadeProdutos;
    impacts[classificacao] = (impacts[classificacao] ?? 0) + row.impactoLiquido;
    netImpact += row.impactoLiquido;
  }

  final buckets =
      counts.entries
          .map(
            (entry) => SalesProdutoTendenciaMediaMovelClassBucket(
              classificacao: entry.key,
              count: entry.value,
              impacto: impacts[entry.key] ?? 0,
            ),
          )
          .toList(growable: false)
        ..sort((a, b) => b.count.compareTo(a.count));

  return SalesProdutoTendenciaMediaMovelSummary(
    countGrowing: counts['CRESCENDO'] ?? 0,
    countFalling: counts['CAINDO'] ?? 0,
    countNew: counts['NOVO'] ?? 0,
    countStopped: counts['PAROU'] ?? 0,
    netImpact: netImpact,
    buckets: buckets,
  );
}

class SalesProdutoTendenciaMediaMovelSummary {
  const SalesProdutoTendenciaMediaMovelSummary({
    required this.countGrowing,
    required this.countFalling,
    required this.countNew,
    required this.countStopped,
    required this.netImpact,
    required this.buckets,
  });

  final int countGrowing;
  final int countFalling;
  final int countNew;
  final int countStopped;
  final double netImpact;
  final List<SalesProdutoTendenciaMediaMovelClassBucket> buckets;
}

class SalesProdutoTendenciaMediaMovelClassBucket {
  const SalesProdutoTendenciaMediaMovelClassBucket({
    required this.classificacao,
    required this.count,
    required this.impacto,
  });

  final String classificacao;
  final int count;
  final double impacto;
}

class SalesProdutoTendenciaMediaMovelLoadingSection extends StatelessWidget {
  const SalesProdutoTendenciaMediaMovelLoadingSection({
    required this.title,
    required this.subtitle,
    super.key,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final tokens = context.appTokens;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        SalesProdutoTendenciaMediaMovelSectionHeader(
          title: title,
          subtitle: subtitle,
        ),
        SizedBox(height: tokens.gapMd),
        const AppSkeleton(
          enabled: true,
          child: SizedBox(
            height: 120,
            width: double.infinity,
          ),
        ),
      ],
    );
  }
}

class SalesProdutoTendenciaMediaMovelSummarySection extends StatelessWidget {
  const SalesProdutoTendenciaMediaMovelSummarySection({
    required this.l10n,
    required this.summary,
    super.key,
  });

  final AppLocalizations l10n;
  final SalesProdutoTendenciaMediaMovelSummary summary;

  @override
  Widget build(BuildContext context) {
    final tokens = context.appTokens;
    final numberFormat = NumberFormat.decimalPattern('pt_BR');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        SalesProdutoTendenciaMediaMovelSectionHeader(
          title: l10n.salesProdutoTendenciaMediaMovelSummaryTitle,
          subtitle: l10n.salesProdutoTendenciaMediaMovelSummarySubtitle,
        ),
        SizedBox(height: tokens.gapMd),
        Wrap(
          spacing: tokens.gapMd,
          runSpacing: tokens.gapMd,
          children: <Widget>[
            _SalesProdutoTendenciaMediaMovelKpiCard(
              label: l10n.salesProdutoTendenciaMediaMovelKpiGrowing,
              value: numberFormat.format(summary.countGrowing),
              icon: Icons.trending_up_rounded,
              emphasis: AppMetricStatCardEmphasis.hero,
            ),
            _SalesProdutoTendenciaMediaMovelKpiCard(
              label: l10n.salesProdutoTendenciaMediaMovelKpiFalling,
              value: numberFormat.format(summary.countFalling),
              icon: Icons.trending_down_rounded,
            ),
            _SalesProdutoTendenciaMediaMovelKpiCard(
              label: l10n.salesProdutoTendenciaMediaMovelKpiNewProducts,
              value: numberFormat.format(summary.countNew),
              icon: Icons.fiber_new_rounded,
            ),
            _SalesProdutoTendenciaMediaMovelKpiCard(
              label: l10n.salesProdutoTendenciaMediaMovelKpiStopped,
              value: numberFormat.format(summary.countStopped),
              icon: Icons.pause_circle_outline_rounded,
            ),
            _SalesProdutoTendenciaMediaMovelKpiCard(
              label: l10n.salesProdutoTendenciaMediaMovelKpiNetImpact,
              value: numberFormat.format(summary.netImpact),
              icon: Icons.swap_vert_rounded,
            ),
          ],
        ),
      ],
    );
  }
}

class SalesProdutoTendenciaMediaMovelCountChartSection extends StatelessWidget {
  const SalesProdutoTendenciaMediaMovelCountChartSection({
    required this.l10n,
    required this.buckets,
    super.key,
  });

  final AppLocalizations l10n;
  final List<SalesProdutoTendenciaMediaMovelClassBucket> buckets;

  @override
  Widget build(BuildContext context) {
    final tokens = context.appTokens;
    final locale = Localizations.localeOf(context).toLanguageTag();

    return AppComparisonBarChart<SalesProdutoTendenciaMediaMovelClassBucket>(
      title: l10n.salesProdutoTendenciaMediaMovelSummaryByClassificacaoTitle,
      subtitle:
          l10n.salesProdutoTendenciaMediaMovelSummaryByClassificacaoSubtitle,
      items: buckets,
      labelBuilder: (bucket) => produtoTendenciaMediaMovelClassificacaoLabel(
        l10n,
        bucket.classificacao,
      ),
      valueBuilder: (bucket) => bucket.count,
      dataLabelBuilder: (bucket, value) => '${bucket.count}',
      tooltipLabelBuilder: (bucket, value) =>
          '${produtoTendenciaMediaMovelClassificacaoLabel(l10n, bucket.classificacao)}: '
          '${bucket.count}',
      style: salesTrendHomeLikeComparisonBarChartStyle(
        tokens: tokens,
        l10n: l10n,
        yAxisFormat: NumberFormat.compact(locale: locale),
      ),
      emptyPlaceholder: AppSectionCard(
        child: Text(l10n.salesProdutoTendenciaMediaMovelNoData),
      ),
    );
  }
}

class SalesProdutoTendenciaMediaMovelImpactChartSection
    extends StatelessWidget {
  const SalesProdutoTendenciaMediaMovelImpactChartSection({
    required this.l10n,
    required this.buckets,
    super.key,
  });

  final AppLocalizations l10n;
  final List<SalesProdutoTendenciaMediaMovelClassBucket> buckets;

  @override
  Widget build(BuildContext context) {
    final tokens = context.appTokens;
    final locale = Localizations.localeOf(context).toLanguageTag();

    return AppComparisonBarChart<SalesProdutoTendenciaMediaMovelClassBucket>(
      title: l10n.salesProdutoTendenciaMediaMovelSummaryByImpactTitle,
      subtitle: l10n.salesProdutoTendenciaMediaMovelSummaryByImpactSubtitle,
      items: buckets,
      labelBuilder: (bucket) => produtoTendenciaMediaMovelClassificacaoLabel(
        l10n,
        bucket.classificacao,
      ),
      valueBuilder: (bucket) => bucket.impacto,
      dataLabelBuilder: (bucket, value) =>
          NumberFormat.decimalPattern('pt_BR').format(bucket.impacto),
      tooltipLabelBuilder: (bucket, value) =>
          '${produtoTendenciaMediaMovelClassificacaoLabel(l10n, bucket.classificacao)}: '
          '${NumberFormat.decimalPattern('pt_BR').format(bucket.impacto)}',
      style: salesTrendHomeLikeComparisonBarChartStyle(
        tokens: tokens,
        l10n: l10n,
        yAxisFormat: NumberFormat.compact(locale: locale),
        minPlottedValueShareOfMax: 0,
      ),
      emptyPlaceholder: AppSectionCard(
        child: Text(l10n.salesProdutoTendenciaMediaMovelNoData),
      ),
    );
  }
}

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
    super.key,
  });

  final AppLocalizations l10n;
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

  @override
  Widget build(BuildContext context) {
    final tokens = context.appTokens;
    final scrollHint =
        l10n.salesProdutoTendenciaMediaMovelDetailsHorizontalScrollCaption;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        SalesProdutoTendenciaMediaMovelSectionHeader(
          title: l10n.salesProdutoTendenciaMediaMovelDetailsTitle,
          subtitle: l10n.salesProdutoTendenciaMediaMovelDetailsSubtitle,
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
              if (rows.isEmpty)
                Text(l10n.salesProdutoTendenciaMediaMovelNoData)
              else
                LayoutBuilder(
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
                                          Text(_formatDecimal(row.mediaAtual)),
                                        ),
                                        DataCell(
                                          Text(
                                            _formatDecimal(row.mediaAnterior),
                                          ),
                                        ),
                                        DataCell(
                                          Text(_formatDecimal(row.diferenca)),
                                        ),
                                        DataCell(
                                          Text(
                                            _formatPercent(
                                              row.tendenciaPercentual,
                                            ),
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

  String _formatDecimal(num value) {
    return NumberFormat.decimalPattern('pt_BR').format(value);
  }

  String _formatPercent(num value) {
    return '${NumberFormat.decimalPattern('pt_BR').format(value)}%';
  }
}

class SalesProdutoTendenciaMediaMovelSectionHeader extends StatelessWidget {
  const SalesProdutoTendenciaMediaMovelSectionHeader({
    required this.title,
    required this.subtitle,
    super.key,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.appTokens;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: tokens.gapXs),
        Text(
          subtitle,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.appColors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class SalesProdutoTendenciaMediaMovelFiltersSheet extends StatefulWidget {
  const SalesProdutoTendenciaMediaMovelFiltersSheet({
    required this.l10n,
    required this.availableAgents,
    required this.initialSelectedAgentId,
    required this.initialQuantidadeDias,
    required this.initialSearchTerm,
    required this.initialClassificacao,
    required this.initialCodGrupoProduto,
    required this.initialSortBy,
    required this.initialPageSize,
    required this.grupoOptions,
    super.key,
  });

  final AppLocalizations l10n;
  final List<DashboardAgentOption> availableAgents;
  final String? initialSelectedAgentId;
  final int initialQuantidadeDias;
  final String initialSearchTerm;
  final String? initialClassificacao;
  final int? initialCodGrupoProduto;
  final ProdutoVendidoTendenciaDeVendaMediaMovelSortBy initialSortBy;
  final int initialPageSize;
  final List<GrupoProdutoOption> grupoOptions;

  @override
  State<SalesProdutoTendenciaMediaMovelFiltersSheet> createState() =>
      _SalesProdutoTendenciaMediaMovelFiltersSheetState();
}

class _SalesProdutoTendenciaMediaMovelFiltersSheetState
    extends State<SalesProdutoTendenciaMediaMovelFiltersSheet> {
  static const List<int> _pageSizeOptions = <int>[10, 20, 50, 100];

  String? _selectedAgentId;
  late final TextEditingController _quantidadeDiasController;
  late final TextEditingController _searchController;
  String? _classificacao;
  int? _codGrupoProduto;
  late ProdutoVendidoTendenciaDeVendaMediaMovelSortBy _sortBy;
  int _pageSize =
      ProdutoVendidoTendenciaDeVendaMediaMovelFilter.defaultPageSize;

  @override
  void initState() {
    super.initState();
    _selectedAgentId = widget.initialSelectedAgentId;
    _quantidadeDiasController = TextEditingController(
      text: '${widget.initialQuantidadeDias}',
    );
    _searchController = TextEditingController(text: widget.initialSearchTerm);
    _classificacao = widget.initialClassificacao;
    _codGrupoProduto = widget.initialCodGrupoProduto;
    _sortBy = widget.initialSortBy;
    _pageSize = widget.initialPageSize;
  }

  @override
  void dispose() {
    _quantidadeDiasController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  int get _quantidadeDias =>
      int.tryParse(_quantidadeDiasController.text.trim()) ?? 0;

  int? get _selectedWindowPreset {
    final days = _quantidadeDias;
    return kSalesProdutoTendenciaMediaMovelWindowPresets.contains(days)
        ? days
        : null;
  }

  String? get _validationMessage {
    final error = ProdutoVendidoTendenciaDeVendaMediaMovelFilter(
      quantidadeDias: _quantidadeDias,
      searchTerm: _searchController.text,
      classificacao: _classificacao,
      codGrupoProduto: _codGrupoProduto,
      sortBy: _sortBy,
      pageSize: _pageSize,
    ).validationError();

    if (error == null) {
      return null;
    }
    return switch (error) {
      ProdutoVendidoTendenciaDeVendaMediaMovelFilter
          .errorQuantidadeDiasMustBePositive =>
        widget.l10n.salesProdutoTendenciaMediaMovelFilterQuantidadeDiasInvalid,
      _ when error.contains('quantidadeDias must be <=') =>
        widget.l10n.salesProdutoTendenciaMediaMovelFilterQuantidadeDiasTooLarge(
          ProdutoVendidoTendenciaDeVendaMediaMovelFilter.maxQuantidadeDias,
        ),
      _ =>
        widget.l10n.salesProdutoTendenciaMediaMovelFilterQuantidadeDiasInvalid,
    };
  }

  bool get _canApply {
    final selectedAgentId = _selectedAgentId;
    return selectedAgentId != null &&
        selectedAgentId.trim().isNotEmpty &&
        _validationMessage == null;
  }

  void _apply() {
    if (!_canApply) {
      return;
    }
    Navigator.of(context).pop(<String, Object?>{
      'agentId': _selectedAgentId,
      'quantidadeDias': _quantidadeDias,
      'searchTerm': _searchController.text,
      'classificacao': _classificacao,
      'codGrupoProduto': _codGrupoProduto,
      'sortBy': _sortBy.name,
      'pageSize': _pageSize,
    });
  }

  void _clear() {
    setState(() {
      _quantidadeDiasController.text = '7';
      _searchController.text = '';
      _classificacao = null;
      _codGrupoProduto = null;
      _sortBy = ProdutoVendidoTendenciaDeVendaMediaMovelSortBy
          .tendenciaPercentualDesc;
      _pageSize =
          ProdutoVendidoTendenciaDeVendaMediaMovelFilter.defaultPageSize;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.appTokens;
    final l10n = widget.l10n;
    final selectedAgentMissingToken =
        _selectedAgentId != null &&
        widget.availableAgents.any(
          (agent) =>
              agent.agentId == _selectedAgentId &&
              agent.missingLocalClientToken,
        );

    return SalesFiltersSheetScaffold(
      title: l10n.reportFiltersTitleWithContext(
        l10n.salesCardProdutoTendenciaMediaMovelTitle,
      ),
      description: l10n.reportFiltersDescription,
      primaryActionLabel: l10n.reportFiltersApplyAction,
      secondaryActionLabel: l10n.reportFiltersClearAction,
      onPrimaryAction: _apply,
      onSecondaryAction: _clear,
      canPrimaryAction: _canApply,
      bodyBuilder: (scrollController) {
        return ListView(
          controller: scrollController,
          padding: EdgeInsets.fromLTRB(
            tokens.contentSpacing,
            0,
            tokens.contentSpacing,
            tokens.contentSpacing,
          ),
          children: <Widget>[
            _SalesProdutoTendenciaMediaMovelFiltersSectionHeader(
              title: l10n.salesBranchFilterLabel,
              subtitle: l10n.salesBranchRequiredMessage,
              requiredBadgeLabel: l10n.reportFiltersRequiredCount(1),
            ),
            SizedBox(height: tokens.gapSm),
            SalesBranchPickerControl(
              l10n: l10n,
              availableBranches: widget.availableAgents,
              selectedBranchId: _selectedAgentId,
              showTrailingFilterButton: false,
              onSelectionChanged: (agentId) {
                setState(() => _selectedAgentId = agentId);
              },
            ),
            if (selectedAgentMissingToken) ...<Widget>[
              SizedBox(height: tokens.gapMd),
              AppInlineErrorPanel(
                tone: AppInlinePanelTone.informational,
                message: l10n.salesBranchFilterMissingClientTokenBanner,
              ),
            ],
            SizedBox(height: tokens.sectionSpacing),
            _SalesProdutoTendenciaMediaMovelFiltersSectionHeader(
              title: l10n.reportFiltersTitle,
              subtitle: l10n.reportFiltersDescription,
            ),
            SizedBox(height: tokens.gapSm),
            AppSectionCard(
              color: theme.colorScheme.surfaceContainerLow,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Text(
                    l10n.salesProdutoTendenciaMediaMovelFilterQuantidadeDiasPresetsTitle,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: tokens.gapXs),
                  Wrap(
                    spacing: tokens.gapSm,
                    runSpacing: tokens.gapSm,
                    children: kSalesProdutoTendenciaMediaMovelWindowPresets
                        .map(
                          (days) => AppChoiceChip(
                            label: l10n
                                .salesProdutoTendenciaMediaMovelFilterQuantidadeDiasValue(
                                  days,
                                ),
                            selected: _selectedWindowPreset == days,
                            onSelected: () {
                              setState(() {
                                _quantidadeDiasController.text = '$days';
                              });
                            },
                          ),
                        )
                        .toList(growable: false),
                  ),
                  SizedBox(height: tokens.contentSpacing),
                  AppTextField(
                    controller: _quantidadeDiasController,
                    keyboardType: TextInputType.number,
                    inputFormatters: <TextInputFormatter>[
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    density: AppTextFieldDensity.compact,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      labelText: l10n
                          .salesProdutoTendenciaMediaMovelFilterQuantidadeDias,
                      hintText: l10n
                          .salesProdutoTendenciaMediaMovelFilterQuantidadeDiasHint,
                      helperText: l10n
                          .salesProdutoTendenciaMediaMovelFilterQuantidadeDiasHelper,
                      errorText: _validationMessage,
                    ),
                  ),
                  SizedBox(height: tokens.contentSpacing),
                  AppTextField(
                    controller: _searchController,
                    label: l10n.salesProdutoTendenciaFilterSearch,
                    hintText:
                        l10n.salesProdutoTendenciaMediaMovelFilterSearchHint,
                    density: AppTextFieldDensity.compact,
                  ),
                  SizedBox(height: tokens.contentSpacing),
                  AppDropdownField<String?>(
                    label: l10n.salesProdutoTendenciaFilterClassification,
                    value: _classificacao,
                    density: AppTextFieldDensity.compact,
                    options: <AppDropdownOption<String?>>[
                      AppDropdownOption<String?>(
                        value: null,
                        label: l10n.salesProdutoTendenciaFilterAllOption,
                      ),
                      ...ProdutoVendidoTendenciaDeVendaMediaMovelFilter
                          .allowedClassificacoes
                          .map(
                            (value) => AppDropdownOption<String?>(
                              value: value,
                              label:
                                  produtoTendenciaMediaMovelClassificacaoLabel(
                                    l10n,
                                    value,
                                  ),
                            ),
                          ),
                    ],
                    onChanged: (value) {
                      setState(() => _classificacao = value);
                    },
                  ),
                  SizedBox(height: tokens.contentSpacing),
                  AppDropdownField<int?>(
                    label: l10n.salesProdutoTendenciaFilterGroup,
                    value: _codGrupoProduto,
                    density: AppTextFieldDensity.compact,
                    options: <AppDropdownOption<int?>>[
                      AppDropdownOption<int?>(
                        value: null,
                        label: l10n.salesProdutoTendenciaFilterAllOption,
                      ),
                      ...widget.grupoOptions.map(
                        (option) => AppDropdownOption<int?>(
                          value: option.codGrupoProduto,
                          label: option.nomeGrupoProduto,
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() => _codGrupoProduto = value);
                    },
                  ),
                  SizedBox(height: tokens.contentSpacing),
                  AppDropdownField<
                    ProdutoVendidoTendenciaDeVendaMediaMovelSortBy
                  >(
                    label: l10n.salesProdutoTendenciaMediaMovelFilterSortBy,
                    value: _sortBy,
                    density: AppTextFieldDensity.compact,
                    options: ProdutoVendidoTendenciaDeVendaMediaMovelSortBy
                        .values
                        .map(
                          (value) =>
                              AppDropdownOption<
                                ProdutoVendidoTendenciaDeVendaMediaMovelSortBy
                              >(
                                value: value,
                                label: produtoTendenciaMediaMovelSortLabel(
                                  l10n,
                                  value,
                                ),
                              ),
                        )
                        .toList(growable: false),
                    onChanged: (value) {
                      if (value == null) {
                        return;
                      }
                      setState(() => _sortBy = value);
                    },
                  ),
                  SizedBox(height: tokens.contentSpacing),
                  AppDropdownField<int>(
                    label: l10n.salesProdutoTendenciaFilterPageSize,
                    value: _pageSize,
                    density: AppTextFieldDensity.compact,
                    options: _pageSizeOptions
                        .map(
                          (value) => AppDropdownOption<int>(
                            value: value,
                            label: '$value',
                          ),
                        )
                        .toList(growable: false),
                    onChanged: (value) {
                      if (value == null) {
                        return;
                      }
                      setState(() => _pageSize = value);
                    },
                  ),
                ],
              ),
            ),
          ],
        );
      },
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

class _SalesProdutoTendenciaMediaMovelKpiCard extends StatelessWidget {
  const _SalesProdutoTendenciaMediaMovelKpiCard({
    required this.label,
    required this.value,
    required this.icon,
    this.emphasis = AppMetricStatCardEmphasis.standard,
  });

  final String label;
  final String value;
  final IconData icon;
  final AppMetricStatCardEmphasis emphasis;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: 220,
      child: AppMetricStatCard(
        emphasis: emphasis,
        leading: Icon(icon, color: scheme.primary),
        label: label,
        value: value,
      ),
    );
  }
}

class _SalesProdutoTendenciaMediaMovelFiltersSectionHeader
    extends StatelessWidget {
  const _SalesProdutoTendenciaMediaMovelFiltersSectionHeader({
    required this.title,
    required this.subtitle,
    this.requiredBadgeLabel,
  });

  final String title;
  final String subtitle;
  final String? requiredBadgeLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.appTokens;
    final colors = theme.appColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (requiredBadgeLabel != null)
              DecoratedBox(
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(tokens.formFieldRadius),
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: tokens.gapSm,
                    vertical: tokens.gapXs,
                  ),
                  child: Text(
                    requiredBadgeLabel!,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
          ],
        ),
        SizedBox(height: tokens.gapXs),
        Text(
          subtitle,
          style: theme.textTheme.bodySmall?.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
