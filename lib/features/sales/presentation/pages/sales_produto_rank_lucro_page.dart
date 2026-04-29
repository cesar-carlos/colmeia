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
import 'package:colmeia/features/client_agents/domain/repositories/agent_client_token_reader.dart';
import 'package:colmeia/features/sales/data/sales_preferences.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_agent_required_gate.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_colors.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/design_system/app_typography_tokens.dart';
import 'package:colmeia/shared/widgets/app_inline_error_panel.dart';
import 'package:colmeia/shared/widgets/app_section_card.dart';
import 'package:colmeia/shared/widgets/charts/app_horizontal_progress_chart.dart';
import 'package:colmeia/shared/widgets/navigation/app_shell_page_intro.dart';
import 'package:colmeia/shared/widgets/reports/app_report_filters_panel.dart';
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

const double _kProdutoRankFilterCircleSize = 44;
const Color _kProdutoRankFilterCircleFill = Color(0xFFFFE5D9);
const Color _kProdutoRankFilterCircleIcon = Color(0xFF5D4037);

class _SalesProdutoRankLucroPageState extends State<SalesProdutoRankLucroPage> {
  late final SalesPreferences _prefs;
  late final AgentClientTokenReader _clientTokenReader;
  late final LoadProdutoVendidoProdutoRankLucroUseCase _loadRanking;

  String? _selectedAgentId;
  String? _cachedClientTokenUserId;
  String? _cachedClientTokenAgentId;
  String? _cachedClientToken;

  Map<String, Object?> _filters = <String, Object?>{};
  List<ProdutoVendidoProdutoRankLucroRow> _rows =
      const <ProdutoVendidoProdutoRankLucroRow>[];

  bool _loading = false;
  String? _error;

  DateTimeRange _fullMonthInclusiveRange(DateTime anchor) => DateTimeRange(
    start: DateTime(anchor.year, anchor.month),
    end: DateTime(anchor.year, anchor.month + 1, 0),
  );

  Future<String?> _resolveClientToken({
    required String userId,
    required String agentId,
  }) async {
    if (_cachedClientTokenUserId == userId &&
        _cachedClientTokenAgentId == agentId) {
      return _cachedClientToken;
    }

    final tokenByAgent = await _clientTokenReader.readMany(
      userId: userId,
      agentIds: <String>[agentId],
    );
    final resolved = tokenByAgent[agentId]?.trim();
    _cachedClientTokenUserId = userId;
    _cachedClientTokenAgentId = agentId;
    return _cachedClientToken =
        resolved == null || resolved.isEmpty ? null : resolved;
  }

  @override
  void initState() {
    super.initState();
    _prefs = getIt<SalesPreferences>();
    _clientTokenReader = getIt<AgentClientTokenReader>();
    _loadRanking = getIt<LoadProdutoVendidoProdutoRankLucroUseCase>();
    _selectedAgentId = _prefs.selectedAgentId;
    final restored = _prefs.restoreProdutoRankLucroFilters();
    final defaultRange = _fullMonthInclusiveRange(DateTime.now());
    final restoredPeriod = restored['periodo'];
    final period = restoredPeriod is DateTimeRange
        ? restoredPeriod
        : defaultRange;
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

    final trimmedAgentId = agentId.trim();
    final clientToken = await _resolveClientToken(
      userId: userId,
      agentId: trimmedAgentId,
    );
    if (!mounted) {
      return;
    }
    if (clientToken == null) {
      setState(() {
        _loading = false;
        _rows = const <ProdutoVendidoProdutoRankLucroRow>[];
        _error = AppLocalizations.of(context).agentSqlErrorAuthenticationFailed;
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
      agentId: trimmedAgentId,
      filter: ProdutoVendidoProdutoRankLucroFilter(
        dataVendaInicio: range.start,
        dataVendaFim: range.end,
        sortBy: sortBy,
      ),
      clientToken: clientToken,
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

  Future<void> _openFiltersSheet(
    List<AppReportFilterDescriptor> filterDescriptors,
  ) async {
    if (!mounted) {
      return;
    }
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) {
        final tokens = Theme.of(context).extension<AppThemeTokens>()!;
        final sheetL10n = AppLocalizations.of(context);
        final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
        return Padding(
          padding: EdgeInsets.fromLTRB(
            tokens.contentSpacing,
            tokens.gapMd,
            tokens.contentSpacing,
            tokens.contentSpacing + bottomInset,
          ),
          child: SingleChildScrollView(
            child: AppReportFiltersPanel(
              title: sheetL10n.reportFiltersTitleWithContext(
                sheetL10n.salesCardProdutoRankLucroTitle,
              ),
              filters: filterDescriptors,
              initialValues: _filters,
              onApply: (values) {
                _onFiltersChanged(values);
                Navigator.of(context).pop();
              },
              onClear: () {
                _onFiltersChanged(const <String, Object?>{});
                Navigator.of(context).pop();
              },
            ),
          ),
        );
      },
    );
  }

  ProdutoVendidoProdutoRankLucroSortBy _sortByEnum(String? key) {
    return switch (key) {
      'totalValorLucro' => ProdutoVendidoProdutoRankLucroSortBy.totalValorLucro,
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

  int _rowRankOf(ProdutoVendidoProdutoRankLucroRow row) {
    final index = _rows.indexOf(row);
    return index >= 0 ? index + 1 : 0;
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
    final axisFormat = metricProfit
        ? AppBrFormatters.compactCurrencyFormat
        : NumberFormat.decimalPattern('pt_BR');

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
    final metricLabel = metricProfit
        ? l10n.salesProdutoRankLucroSortProfit
        : l10n.salesProdutoRankLucroSortQuantity;
    final metricSubtitle = 'Top 15 • $metricLabel';

    final maxValue = _rows.isEmpty
        ? 0.0
        : _rows
            .map((r) => _chartValueFor(r, sortKey))
            .reduce((a, b) => a > b ? a : b)
            .toDouble();

    final chartStyles = AppHorizontalProgressChartStyle(
      barColor: theme.appColors.primary,
      trackColor: theme.colorScheme.surfaceContainerHigh,
      rowSpacing: tokens.gapMd,
      barHeight: 10,
      rowPadding: EdgeInsets.symmetric(vertical: tokens.gapXs),
      valueTextStyle: theme.appTypography.body.copyWith(
        fontWeight: FontWeight.w700,
        color: theme.appColors.primary,
      ),
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
                _ProdutoRankLucroFilterTrigger(
                  l10n: l10n,
                  periodLabel: periodSubtitle,
                  metricLabel: metricLabel,
                  isLoading: _loading,
                  onOpenFilters: () => unawaited(
                    _openFiltersSheet(filterDescriptors),
                  ),
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
                          AppHorizontalProgressChart<
                            ProdutoVendidoProdutoRankLucroRow
                          >(
                            titleWidget: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  l10n.salesProdutoRankLucroChartTitle,
                                  style: theme.appTypography.sectionHeaderH2
                                      .copyWith(fontWeight: FontWeight.w700),
                                ),
                                SizedBox(height: tokens.gapXs),
                                Text(
                                  periodSubtitle,
                                  style: theme.appTypography.caption.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                SizedBox(height: tokens.gapXs / 2),
                                Text(
                                  metricSubtitle,
                                  style: theme.appTypography.utilityOverline
                                      .copyWith(
                                        color: theme.appColors.onSurfaceVariant,
                                      ),
                                ),
                              ],
                            ),
                            items: _rows,
                            labelBuilder: (r) => r.nomeProduto.trim(),
                            valueBuilder: (r) => _chartValueFor(r, sortKey).toDouble(),
                            maxValue: maxValue,
                            isLoading: _loading && _error == null,
                            rowLeadingBuilder: (context, row) => _RankBadge(
                              rank: _rowRankOf(row),
                            ),
                            rowTooltipBuilder: (r, value, _) {
                              final name = r.nomeProduto.trim();
                              final text = metricProfit
                                  ? AppBrFormatters.smartCompactCurrency(value)
                                  : axisFormat.format(value);
                              return '$name • $text';
                            },
                            valueLabelBuilder:
                                (r, value, _) => metricProfit
                                    ? AppBrFormatters.smartCompactCurrency(
                                        value,
                                      )
                                    : axisFormat.format(value),
                            showDividers: true,
                            style: chartStyles,
                            wrapInCard: false,
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

class _ProdutoRankLucroFilterTrigger extends StatelessWidget {
  const _ProdutoRankLucroFilterTrigger({
    required this.l10n,
    required this.periodLabel,
    required this.metricLabel,
    required this.onOpenFilters,
    this.isLoading = false,
  });

  final AppLocalizations l10n;
  final String periodLabel;
  final String metricLabel;
  final VoidCallback onOpenFilters;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;
    final typography = theme.appTypography;
    final colors = theme.appColors;
    final scheme = theme.colorScheme;
    final enabled = !isLoading;

    void open() {
      if (!enabled) {
        return;
      }
      onOpenFilters();
    }

    Widget summaryBlock({
      required String overline,
      required String value,
    }) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            overline.toUpperCase(),
            style: typography.utilityOverline.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
          SizedBox(height: tokens.gapXs),
          Semantics(
            button: true,
            label: '$overline: $value',
            child: InkWell(
              onTap: enabled ? open : null,
              borderRadius: BorderRadius.circular(tokens.formFieldRadius),
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: tokens.gapXs),
                child: Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: typography.body.copyWith(
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurface,
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }

    return AppSectionCard(
      child: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          Padding(
            padding: EdgeInsetsDirectional.only(
              end: _kProdutoRankFilterCircleSize + tokens.gapSm,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                summaryBlock(
                  overline: l10n.salesProdutoRankLucroFilterPeriod,
                  value: periodLabel,
                ),
                SizedBox(height: tokens.gapSm),
                summaryBlock(
                  overline: l10n.salesProdutoRankLucroFilterSortBy,
                  value: metricLabel,
                ),
              ],
            ),
          ),
          PositionedDirectional(
            end: 0,
            top: 0,
            bottom: 0,
            child: Center(
              child: Semantics(
                button: true,
                label: l10n.reportFiltersButton,
                child: Material(
                  color: _kProdutoRankFilterCircleFill,
                  shape: const CircleBorder(),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: enabled ? open : null,
                    child: SizedBox(
                      width: _kProdutoRankFilterCircleSize,
                      height: _kProdutoRankFilterCircleSize,
                      child: Icon(
                        Icons.filter_list_rounded,
                        size: 22,
                        color: enabled
                            ? _kProdutoRankFilterCircleIcon
                            : scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RankBadge extends StatelessWidget {
  const _RankBadge({required this.rank});

  final int rank;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;
    final colors = theme.appColors;

    final (background, foreground, icon) = switch (rank) {
      1 => (
        colors.primaryContainer,
        colors.onPrimaryContainer,
        Icons.workspace_premium_rounded,
      ),
      2 => (
        colors.secondaryContainer,
        colors.onSecondaryContainer,
        Icons.military_tech_rounded,
      ),
      3 => (
        colors.tertiaryFixed,
        colors.onTertiaryFixed,
        Icons.stars_rounded,
      ),
      _ => (
        theme.colorScheme.surfaceContainerHigh,
        colors.onSurfaceVariant,
        null,
      ),
    };
    final showMedal = rank >= 1 && rank <= 3;

    return Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(tokens.formFieldRadius),
      ),
      child: showMedal
          ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Icon(icon, size: 12, color: foreground),
                Text(
                  '$rank',
                  style: theme.appTypography.caption.copyWith(
                    fontWeight: FontWeight.w800,
                    color: foreground,
                    height: 1,
                  ),
                ),
              ],
            )
          : Text(
              rank > 0 ? '$rank' : '–',
              style: theme.appTypography.caption.copyWith(
                fontWeight: FontWeight.w800,
                color: foreground,
              ),
            ),
    );
  }
}
