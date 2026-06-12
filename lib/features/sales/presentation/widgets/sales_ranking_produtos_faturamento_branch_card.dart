import 'dart:async';

import 'package:colmeia/app/router/app_chart_fullscreen_routes.dart';
import 'package:colmeia/app/router/chart_share_icon_button.dart';
import 'package:colmeia/core/formatters/app_br_formatters.dart';
import 'package:colmeia/core/layout/app_breakpoints.dart';
import 'package:colmeia/features/agent_queries/domain/entities/ranking_produtos_faturamento_row.dart';
import 'package:colmeia/features/sales/presentation/share/sales_ranking_produtos_faturamento_share.dart';
import 'package:colmeia/features/sales/presentation/utils/sales_ranking_produtos_faturamento_branch_metrics.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_ranking_produtos_faturamento_details_table.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_ranking_produtos_faturamento_grid_style.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_ranking_produtos_faturamento_pie_section.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_colors.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/design_system/app_typography_tokens.dart';
import 'package:colmeia/shared/widgets/app_inline_error_panel.dart';
import 'package:colmeia/shared/widgets/app_section_card.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_header_trailing.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_share_request.dart';
import 'package:colmeia/shared/widgets/charts/chart_share_actions.dart';
import 'package:colmeia/shared/widgets/charts/chart_share_export_header_context.dart';
import 'package:colmeia/shared/widgets/charts/chart_share_metadata.dart';
import 'package:colmeia/shared/widgets/metrics/app_compact_kpi_stat.dart';
import 'package:colmeia/shared/widgets/reports/app_report_models.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SalesRankingProdutosFaturamentoBranchCard extends StatefulWidget {
  const SalesRankingProdutosFaturamentoBranchCard({
    required this.l10n,
    required this.codEmpresa,
    required this.codFilial,
    required this.rows,
    required this.metricSubtitle,
    this.branchDisplayName,
    this.exportHeaderContext,
    this.isLoading = false,
    this.onRequestShare,
    super.key,
  });

  final AppLocalizations l10n;
  final int codEmpresa;
  final int codFilial;
  final List<RankingProdutosFaturamentoRow> rows;
  final String metricSubtitle;
  final String? branchDisplayName;
  final ChartShareExportHeaderContext? exportHeaderContext;
  final bool isLoading;
  final AppChartShareRequestCallback? onRequestShare;

  @override
  State<SalesRankingProdutosFaturamentoBranchCard> createState() =>
      _SalesRankingProdutosFaturamentoBranchCardState();
}

class _SalesRankingProdutosFaturamentoBranchCardState
    extends State<SalesRankingProdutosFaturamentoBranchCard> {
  final GlobalKey _shareKey = GlobalKey();
  late List<RankingProdutosFaturamentoRow> _displayRows;
  List<AppReportSortDescriptor> _currentSorts =
      const <AppReportSortDescriptor>[];

  @override
  void initState() {
    super.initState();
    _displayRows = List<RankingProdutosFaturamentoRow>.from(widget.rows);
  }

  @override
  void didUpdateWidget(
    covariant SalesRankingProdutosFaturamentoBranchCard oldWidget,
  ) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.rows, widget.rows)) {
      _displayRows = sortRankingProdutosFaturamentoRows(
        widget.rows,
        _currentSorts,
      );
    }
  }

  String get _branchTitle {
    final displayName = widget.branchDisplayName?.trim();
    if (displayName != null && displayName.isNotEmpty) {
      return displayName;
    }
    return _branchMeta;
  }

  String get _branchMeta =>
      widget.l10n.salesRankingProdutosFaturamentoBranchHeader(
        widget.codEmpresa,
        widget.codFilial,
      );

  double? _tableMaxHeight({double? heightOverride}) {
    final rowCount = _displayRows.isEmpty ? 3 : _displayRows.length;
    const headerHeight = kSalesRankingFaturamentoGridHeaderRowHeight;
    const dataRowHeight = kSalesRankingFaturamentoGridDataRowHeight;
    const dividerAllowance = 16;
    final computedHeight =
        headerHeight + dividerAllowance + (dataRowHeight * rowCount);
    return (heightOverride ?? computedHeight).clamp(120.0, 520.0);
  }

  void _onSortChanged(List<AppReportSortDescriptor> sorts) {
    setState(() {
      _currentSorts = sorts;
      _displayRows = sortRankingProdutosFaturamentoRows(widget.rows, sorts);
    });
  }

  ChartShareMetadata get _shareMetadata =>
      buildSalesRankingProdutosFaturamentoShareMetadata(
        l10n: widget.l10n,
        branchTitle: _branchTitle,
        metricSubtitle: widget.metricSubtitle,
        displayRows: _displayRows,
        exportHeaderContext: widget.exportHeaderContext,
      );

  void _openFullscreen() {
    final rowsSnapshot = List<RankingProdutosFaturamentoRow>.from(_displayRows);
    final sortsSnapshot = List<AppReportSortDescriptor>.from(_currentSorts);
    final l10n = widget.l10n;
    final branchTitle = _branchTitle;
    final metricSubtitle = widget.metricSubtitle;

    final rowsForChart = List<RankingProdutosFaturamentoRow>.from(widget.rows);
    final shareMetadata = buildSalesRankingProdutosFaturamentoShareMetadata(
      l10n: l10n,
      branchTitle: branchTitle,
      metricSubtitle: metricSubtitle,
      displayRows: rowsSnapshot,
      exportHeaderContext: widget.exportHeaderContext,
    );
    final fullscreenShareKey = GlobalKey();

    unawaited(
      context.pushChartFullscreen<void>(
        extra: AppChartFullscreenRouteExtra(
          title: branchTitle,
          subtitle: metricSubtitle,
          headerTrailing: buildChartFullscreenShareTrailing(
            context: context,
            shareKey: fullscreenShareKey,
            metadata: shareMetadata,
          ),
          chartBuilder: (fullscreenContext) {
            return RepaintBoundary(
              key: fullscreenShareKey,
              child: _SalesRankingProdutosFaturamentoFullscreenBody(
                l10n: l10n,
                rows: rowsForChart,
                displayRows: rowsSnapshot,
                initialSorts: sortsSnapshot,
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildGrid(BuildContext context, {double? heightOverride}) {
    return RepaintBoundary(
      child: SalesRankingProdutosFaturamentoDetailsTable(
        l10n: widget.l10n,
        rows: _displayRows,
        currentSorts: _currentSorts,
        onSortChanged: _onSortChanged,
        maxHeight: _tableMaxHeight(heightOverride: heightOverride),
        isLoading: widget.isLoading && _displayRows.isEmpty,
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.appTokens;
    final shareActions = ChartShareActions(
      context: context,
      captureKey: _shareKey,
      metadata: _shareMetadata,
      onRequestShare: widget.onRequestShare,
      shareEnabled: !widget.isLoading,
    );
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                _branchTitle,
                style: theme.appTypography.sectionHeaderH2.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (_branchTitle != _branchMeta) ...<Widget>[
                SizedBox(height: tokens.gapXs),
                Text(
                  _branchMeta,
                  style: theme.appTypography.body.copyWith(
                    color: theme.appColors.onSurfaceVariant,
                  ),
                ),
              ],
              SizedBox(height: tokens.gapXs),
              Text(
                widget.metricSubtitle,
                style: theme.appTypography.utilityOverline.copyWith(
                  color: theme.appColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        AppChartHeaderTrailing(
          onOpenFullscreen: widget.rows.isEmpty ? null : _openFullscreen,
          openFullscreenTooltip:
              widget.l10n.salesRankingProdutosFaturamentoFullscreenTooltip,
          onShare: widget.rows.isEmpty ? null : shareActions.shareCallback(),
          shareProgressKey: _shareKey,
          shareEnabled: !widget.isLoading,
        ),
      ],
    );
  }

  Widget _buildChartColumn(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.appTokens;
    final total = branchRevenueTotal(widget.rows);
    final percentFormat = NumberFormat('#,##0.0', 'pt_BR');
    final showPercentHint = branchPercentSumDiverges(widget.rows);
    final leadInsight = branchLeadProductInsight(widget.rows);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _buildHeader(context),
        SizedBox(height: tokens.gapMd),
        AppCompactKpiStat(
          label: widget.l10n.salesRankingProdutosFaturamentoBranchTotalLabel,
          value: AppBrFormatters.compactCurrency(total),
        ),
        if (leadInsight != null) ...<Widget>[
          SizedBox(height: tokens.gapSm),
          Text(
            widget.l10n.salesRankingProdutosFaturamentoLeadInsight(
              leadInsight.productName,
              percentFormat.format(leadInsight.percentual),
            ),
            style: theme.appTypography.body.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
        SizedBox(height: tokens.contentSpacing),
        SalesRankingProdutosFaturamentoPieSection(
          l10n: widget.l10n,
          rows: widget.rows,
          isLoading: widget.isLoading,
        ),
        if (showPercentHint) ...<Widget>[
          SizedBox(height: tokens.gapMd),
          AppInlineErrorPanel(
            tone: AppInlinePanelTone.informational,
            message: widget.l10n.salesRankingProdutosFaturamentoPercentSumHint(
              percentFormat.format(branchPercentSum(widget.rows)),
            ),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).appTokens;
    return LayoutBuilder(
      builder: (context, constraints) {
        final useDesktopLayout = constraints.maxWidth >= AppBreakpoints.desktop;

        return RepaintBoundary(
          key: _shareKey,
          child: AppSectionCard(
            child: useDesktopLayout
                ? Row(
                    key: const Key('sales-ranking-branch-desktop-layout'),
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Expanded(
                        flex: 5,
                        child: _buildChartColumn(context),
                      ),
                      SizedBox(width: tokens.sectionSpacing),
                      Expanded(
                        flex: 6,
                        child: _buildGrid(context, heightOverride: 520),
                      ),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      _buildChartColumn(context),
                      SizedBox(height: tokens.contentSpacing),
                      _buildGrid(context),
                    ],
                  ),
          ),
        );
      },
    );
  }
}

class _SalesRankingProdutosFaturamentoFullscreenBody extends StatefulWidget {
  const _SalesRankingProdutosFaturamentoFullscreenBody({
    required this.l10n,
    required this.rows,
    required this.displayRows,
    required this.initialSorts,
  });

  final AppLocalizations l10n;
  final List<RankingProdutosFaturamentoRow> rows;
  final List<RankingProdutosFaturamentoRow> displayRows;
  final List<AppReportSortDescriptor> initialSorts;

  @override
  State<_SalesRankingProdutosFaturamentoFullscreenBody> createState() =>
      _SalesRankingProdutosFaturamentoFullscreenBodyState();
}

class _SalesRankingProdutosFaturamentoFullscreenBodyState
    extends State<_SalesRankingProdutosFaturamentoFullscreenBody> {
  late List<RankingProdutosFaturamentoRow> _displayRows;
  late List<AppReportSortDescriptor> _currentSorts;

  @override
  void initState() {
    super.initState();
    _currentSorts = List<AppReportSortDescriptor>.from(widget.initialSorts);
    _displayRows = List<RankingProdutosFaturamentoRow>.from(widget.displayRows);
  }

  void _onSortChanged(List<AppReportSortDescriptor> sorts) {
    setState(() {
      _currentSorts = sorts;
      _displayRows = sortRankingProdutosFaturamentoRows(widget.rows, sorts);
    });
  }

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).appTokens;

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxHeight = constraints.maxHeight;
        if (!maxHeight.isFinite || maxHeight <= 0) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Flexible(
              flex: 2,
              child: SalesRankingProdutosFaturamentoPieSection(
                l10n: widget.l10n,
                rows: widget.rows,
              ),
            ),
            SizedBox(height: tokens.gapMd),
            Expanded(
              flex: 3,
              child: RepaintBoundary(
                child: SalesRankingProdutosFaturamentoDetailsTable(
                  l10n: widget.l10n,
                  rows: _displayRows,
                  currentSorts: _currentSorts,
                  onSortChanged: _onSortChanged,
                  expandVertically: true,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
