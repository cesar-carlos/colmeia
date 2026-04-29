import 'dart:async';

import 'package:colmeia/core/di/injector.dart';
import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/formatters/app_br_formatters.dart';
import 'package:colmeia/core/layout/app_responsive_spacing.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_produto_vendido_produto_rank_lucro_use_case.dart';
import 'package:colmeia/features/agent_queries/domain/entities/produto_vendido_produto_rank_lucro_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/produto_vendido_produto_rank_lucro_row.dart';
import 'package:colmeia/features/agent_queries/domain/entities/produto_vendido_produto_rank_lucro_sort_by.dart';
import 'package:colmeia/features/auth/presentation/controllers/auth_controller.dart';
import 'package:colmeia/features/sales/data/sales_preferences.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_agent_required_gate.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/app_inline_error_panel.dart';
import 'package:colmeia/shared/widgets/app_section_card.dart';
import 'package:colmeia/shared/widgets/charts/app_comparison_bar_chart.dart';
import 'package:colmeia/shared/widgets/navigation/app_shell_page_intro.dart';
import 'package:colmeia/shared/widgets/reports/app_report_inline_filters_bar.dart';
import 'package:colmeia/shared/widgets/reports/app_report_models.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class SalesProdutoRankLucroPage extends StatefulWidget {
  const SalesProdutoRankLucroPage({super.key});

  @override
  State<SalesProdutoRankLucroPage> createState() =>
      _SalesProdutoRankLucroPageState();
}

class _SalesProdutoRankLucroPageState extends State<SalesProdutoRankLucroPage> {
  late final SalesPreferences _prefs;
  late final LoadProdutoVendidoProdutoRankLucroUseCase _loadRanking;

  String? _selectedAgentId;

  Map<String, Object?> _filters = <String, Object?>{};
  List<ProdutoVendidoProdutoRankLucroRow> _rows =
      const <ProdutoVendidoProdutoRankLucroRow>[];

  bool _loading = false;
  String? _error;

  DateTimeRange _fullMonthInclusiveRange(DateTime anchor) => DateTimeRange(
    start: DateTime(anchor.year, anchor.month),
    end: DateTime(anchor.year, anchor.month + 1, 0),
  );

  @override
  void initState() {
    super.initState();
    _prefs = getIt<SalesPreferences>();
    _loadRanking = getIt<LoadProdutoVendidoProdutoRankLucroUseCase>();
    _selectedAgentId = _prefs.selectedAgentId;
    final restored = _prefs.restoreProdutoRankLucroFilters();
    final defaultRange = _fullMonthInclusiveRange(DateTime.now());
    final restoredPeriod = restored['periodo'];
    final period =
        restoredPeriod is DateTimeRange ? restoredPeriod : defaultRange;
    final restoredSort = restored['sortBy'] as String?;
    final sortBy =
        restoredSort != null &&
            SalesPreferences.produtoRankLucroSortByAllowedValues.contains(
              restoredSort,
            )
        ? restoredSort
        : 'qtdItensVendido';
    _filters = <String, Object?>{
      'periodo': period,
      'sortBy': sortBy,
    };
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_reload());
    });
  }

  Future<void> _reload() async {
    final auth = context.read<AuthController>();
    final userId = auth.session?.userId;
    final agentId = _selectedAgentId;

    setState(() {
      _loading = true;
      _error = null;
    });

    if (userId == null || agentId == null || agentId.trim().isEmpty) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loading = false;
        _rows = const <ProdutoVendidoProdutoRankLucroRow>[];
        _error = null;
      });
      return;
    }

    final range =
        (_filters['periodo'] as DateTimeRange?) ??
        _fullMonthInclusiveRange(DateTime.now());
    final sortKey = _filters['sortBy'] as String? ?? 'qtdItensVendido';
    final sortBy = switch (sortKey) {
      'totalValorLucro' => ProdutoVendidoProdutoRankLucroSortBy.totalValorLucro,
      _ => ProdutoVendidoProdutoRankLucroSortBy.qtdItensVendido,
    };

    final result = await _loadRanking(
      userId: userId,
      agentId: agentId.trim(),
      filter: ProdutoVendidoProdutoRankLucroFilter(
        dataVendaInicio: range.start,
        dataVendaFim: range.end,
        sortBy: sortBy,
      ),
    );

    if (!mounted) {
      return;
    }

    result.fold(
      (rows) {
        setState(() {
          _rows = rows;
          _loading = false;
          _error = null;
        });
      },
      (exception) {
        setState(() {
          _loading = false;
          _rows = const <ProdutoVendidoProdutoRankLucroRow>[];
          _error = _failureMessage(exception);
        });
      },
    );
  }

  String _failureMessage(Object exception) {
    final err = exception;
    return err is AppFailure ? err.displayMessage : exception.toString();
  }

  void _onFiltersChanged(Map<String, Object?> next) {
    setState(() => _filters = next);
    unawaited(_prefs.persistProdutoRankLucroFilters(next));
    unawaited(_reload());
  }

  ProdutoVendidoProdutoRankLucroSortBy _sortByEnum(String? key) {
    return switch (key) {
      'totalValorLucro' =>
        ProdutoVendidoProdutoRankLucroSortBy.totalValorLucro,
      _ => ProdutoVendidoProdutoRankLucroSortBy.qtdItensVendido,
    };
  }

  num _chartValueFor(ProdutoVendidoProdutoRankLucroRow row, String? sortKey) {
    final enumKey = _sortByEnum(sortKey);
    return switch (enumKey) {
      ProdutoVendidoProdutoRankLucroSortBy.totalValorLucro =>
        row.totalValorLucro,
      _ => row.qtdItensVendido,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = Theme.of(context).extension<AppThemeTokens>()!;
    final theme = Theme.of(context);
    final sortKey = _filters['sortBy'] as String? ?? 'qtdItensVendido';
    final metricProfit = sortKey == 'totalValorLucro';
    final range =
        (_filters['periodo'] as DateTimeRange?) ??
        _fullMonthInclusiveRange(DateTime.now());
    final periodSubtitle =
        '${AppBrFormatters.shortDateFormat.format(range.start)} – '
        '${AppBrFormatters.shortDateFormat.format(range.end)}';
    final axisFormat =
        metricProfit
            ? AppBrFormatters.compactCurrencyFormatForLocale(l10n.localeName)
            : NumberFormat.decimalPattern(l10n.localeName);

    final filterDescriptors = <AppReportFilterDescriptor>[
      AppReportFilterDescriptor(
        name: 'periodo',
        label: l10n.salesProdutoRankLucroFilterPeriod,
        type: AppReportFilterType.dateRange,
      ),
      AppReportFilterDescriptor(
        name: 'sortBy',
        label: l10n.salesProdutoRankLucroFilterSortBy,
        type: AppReportFilterType.singleSelect,
        options: <AppReportFilterOption>[
          AppReportFilterOption(
            value: 'qtdItensVendido',
            label: l10n.salesProdutoRankLucroSortQuantity,
          ),
          AppReportFilterOption(
            value: 'totalValorLucro',
            label: l10n.salesProdutoRankLucroSortProfit,
          ),
        ],
      ),
    ];

    final chartStyles = AppComparisonBarChartStyle(
      animationDuration: const Duration(milliseconds: 350),
      enableTapHighlight: true,
      stickyPrimaryYAxisWhileScrolling: false,
      wrapXAxisLabelsInTwoLines: true,
      autoRotateXLabels: false,
      yAxisFormat: axisFormat,
      showDataLabels: true,
      tooltipLabelMaxChars: 56,
      minBarWidth: 104,
      enableAutoScroll: false,
      categoryAutoScrollingDelta: 8,
      height: tokens.chartStandardHeight + tokens.contentSpacing * 2,
      horizontalScrollSemanticsHint: l10n.overviewComparisonBarHorizontalScrollHint,
    );

    return SingleChildScrollView(
      padding: context.pageScrollPadding(tokens),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          AppShellPageIntro(
            sectionLabel: l10n.shellNavSalesLabel,
            title: l10n.salesCardProdutoRankLucroTitle,
            subtitle: l10n.salesHubSubtitle,
          ),
          SizedBox(height: tokens.sectionSpacing),
          SalesAgentRequiredGate(
            selectedAgentId: _selectedAgentId,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                AppReportInlineFiltersBar(
                  filters: filterDescriptors,
                  initialValues: _filters,
                  onFiltersChanged: _onFiltersChanged,
                ),
                SizedBox(height: tokens.sectionSpacing),
                if (_error != null && _error!.trim().isNotEmpty)
                  AppInlineErrorPanel(
                    message: _error!,
                    onRetry: () => unawaited(_reload()),
                  )
                else
                  AppSectionCard(
                    child: Padding(
                      padding: EdgeInsets.all(tokens.contentSpacing),
                      child:
                          AppComparisonBarChart<ProdutoVendidoProdutoRankLucroRow>(
                            title: l10n.salesProdutoRankLucroChartTitle,
                            subtitle: periodSubtitle,
                            items: _rows,
                            labelBuilder:
                                (r) => r.nomeProduto.trim(),
                            valueBuilder:
                                (r) => _chartValueFor(r, sortKey),
                            isLoading: _loading && _error == null,
                            tooltipLabelBuilder: (
                              r,
                              value,
                            ) {
                              final name = r.nomeProduto.trim();
                              final text =
                                  metricProfit
                                      ? AppBrFormatters.smartCompactCurrency(value)
                                      : axisFormat.format(value.toDouble());
                              return '$name • $text';
                            },
                            dataLabelBuilder:
                                (row, value) =>
                                    metricProfit
                                        ? AppBrFormatters.smartCompactCurrency(value)
                                        : axisFormat.format(value.toDouble()),
                            style: chartStyles,
                            emptyPlaceholder: Center(
                              child: Text(
                                l10n.chartComparisonEmptyDefault,
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
