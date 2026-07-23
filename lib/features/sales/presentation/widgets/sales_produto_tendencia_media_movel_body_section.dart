import 'dart:async';
import 'dart:math' as math;

import 'package:colmeia/features/agent_queries/domain/entities/produto_vendido_tendencia_de_venda_media_movel_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/produto_vendido_tendencia_de_venda_media_movel_row.dart';
import 'package:colmeia/features/agent_queries/presentation/agent_query_failure_support_context.dart';
import 'package:colmeia/features/agent_queries/presentation/widgets/agent_query_error_panel_factory.dart';
import 'package:colmeia/features/sales/presentation/controllers/sales_produto_tendencia_media_movel_controller.dart';
import 'package:colmeia/features/sales/presentation/state/sales_produto_tendencia_media_movel_presentation_state.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_produto_tendencia_media_movel_chart_nav_grid.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_produto_tendencia_media_movel_details_section.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_produto_tendencia_media_movel_summary_section.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/app_inline_error_panel.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_header_trailing.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SalesProdutoTendenciaMediaMovelBodySection extends StatelessWidget {
  const SalesProdutoTendenciaMediaMovelBodySection({
    required this.onRetryReload,
    required this.onClearDetailFilters,
    required this.onOpenFilters,
    required this.onChartSelected,
    required this.onClassificacaoSelected,
    required this.onClearClassificacaoFilter,
    required this.retryCountdownLabel,
    required this.detailsShareKey,
    required this.onShareDetails,
    this.detailsSectionKey,
    super.key,
  });

  final VoidCallback onRetryReload;
  final VoidCallback onClearDetailFilters;
  final VoidCallback onOpenFilters;
  final void Function(
    SalesProdutoTendenciaMediaMovelPresentationState state,
    SalesProdutoTendenciaMediaMovelChartId chartId,
    List<SalesProdutoTendenciaMediaMovelClassBucket> buckets,
  )
  onChartSelected;
  final ValueChanged<String> onClassificacaoSelected;
  final VoidCallback onClearClassificacaoFilter;
  final String? retryCountdownLabel;
  final GlobalKey detailsShareKey;
  final GlobalKey? detailsSectionKey;
  final VoidCallback onShareDetails;

  @override
  Widget build(BuildContext context) {
    return Selector<
      SalesProdutoTendenciaMediaMovelController,
      _SalesProdutoTendenciaMediaMovelShellSlice
    >(
      selector: (_, controller) =>
          _SalesProdutoTendenciaMediaMovelShellSlice.from(controller.state),
      builder: (context, slice, _) {
        final l10n = AppLocalizations.of(context);
        final tokens = context.appTokens;
        final state = slice.state;

        if (state.selectedAgentId == null ||
            state.selectedAgentId!.trim().isEmpty) {
          return AppInlineErrorPanel(
            tone: AppInlinePanelTone.informational,
            title: l10n.salesBranchRequiredTitle,
            message: l10n.salesProdutoTendenciaMediaMovelSelectAgentHint,
          );
        }

        if (state.loadFailure != null) {
          return AgentQueryErrorPanelFactory.fromFailure(
            state.loadFailure!,
            l10n,
            onRetry: onRetryReload,
            retryCountdownLabel: retryCountdownLabel,
            supportContext: AgentQueryFailureSupportContext.environment(
              extra: <String, String>{
                'agentId': ?state.selectedAgentId,
                'screen': 'sales_produto_tendencia_media_movel',
              },
            ),
          );
        }

        if (state.authenticationFailed) {
          return AppInlineErrorPanel(
            title: l10n.salesProdutoTendenciaMediaMovelDetailsTitle,
            message: l10n.agentSqlErrorAuthenticationFailed,
            onRetry: onRetryReload,
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            SalesProdutoTendenciaMediaMovelSummarySection(
              l10n: l10n,
              summary: slice.summary,
              summaryRows: state.summaryRows,
              loading: state.loading,
              hasSummaryRows: slice.hasSummary,
              activeClassificacao: state.classificacao,
              hasActiveDetailFilters: slice.hasActiveDetailFilters,
              onClearFilters: onClearDetailFilters,
              onOpenFilters: onOpenFilters,
              onClearClassificacaoFilter: onClearClassificacaoFilter,
              onClassificacaoSelected: onClassificacaoSelected,
            ),
            SizedBox(height: tokens.sectionSpacing),
            SalesProdutoTendenciaMediaMovelChartNavGrid(
              l10n: l10n,
              loading: state.loading,
              sectionTitle: l10n.salesProdutoTendenciaChartsSectionTitle,
              isChartReady: (chartId) => slice.isChartReady(chartId),
              onChartSelected: (chartId) => onChartSelected(
                state,
                chartId,
                slice.summary.buckets,
              ),
            ),
            SizedBox(height: tokens.sectionSpacing),
            Selector<
              SalesProdutoTendenciaMediaMovelController,
              _SalesProdutoTendenciaMediaMovelDetailsSlice
            >(
              selector: (_, controller) =>
                  _SalesProdutoTendenciaMediaMovelDetailsSlice.from(
                    controller.state,
                  ),
              builder: (context, details, _) {
                final controller = context
                    .read<SalesProdutoTendenciaMediaMovelController>();
                return SalesProdutoTendenciaMediaMovelDetailsSection(
                  key: detailsSectionKey,
                  l10n: l10n,
                  loading: details.tableLoading,
                  paginationEnabled:
                      !details.loading && !details.detailsLoading,
                  rows: details.rows,
                  totalCount: details.totalCount,
                  pageSize: details.pageSize,
                  currentPage: details.page,
                  totalPages: details.totalPages,
                  rangeStart: details.rangeStart,
                  rangeEnd: details.rangeEnd,
                  sortBy: details.sortBy,
                  hasActiveDetailFilters: details.hasActiveDetailFilters,
                  onClearFilters: onClearDetailFilters,
                  onOpenFilters: onOpenFilters,
                  headerTrailing: AppChartHeaderTrailing(
                    shareProgressKey: detailsShareKey,
                    shareEnabled:
                        !details.tableLoading && details.totalCount > 0,
                    onShare: details.tableLoading || details.totalCount <= 0
                        ? null
                        : onShareDetails,
                  ),
                  onPageSelected: (page) {
                    unawaited(controller.selectPage(page));
                  },
                  onNext: details.page < details.totalPages
                      ? () => unawaited(
                          controller.selectPage(details.page + 1),
                        )
                      : null,
                  onPrevious: details.page > 1
                      ? () => unawaited(
                          controller.selectPage(details.page - 1),
                        )
                      : null,
                  onPageSizeChanged: (value) {
                    unawaited(controller.changePageSize(value));
                  },
                );
              },
            ),
          ],
        );
      },
    );
  }
}

@immutable
class _SalesProdutoTendenciaMediaMovelShellSlice {
  const _SalesProdutoTendenciaMediaMovelShellSlice({
    required this.state,
    required this.summary,
    required this.hasSummary,
    required this.hasActiveDetailFilters,
    required this.summaryFingerprint,
  });

  factory _SalesProdutoTendenciaMediaMovelShellSlice.from(
    SalesProdutoTendenciaMediaMovelPresentationState state,
  ) {
    final summary = buildSalesProdutoTendenciaMediaMovelSummary(
      state.summaryRows,
    );
    return _SalesProdutoTendenciaMediaMovelShellSlice(
      state: state,
      summary: summary,
      hasSummary: state.summaryRows.isNotEmpty,
      hasActiveDetailFilters: _hasActiveDetailFilters(state),
      summaryFingerprint: Object.hashAll(state.summaryRows),
    );
  }

  final SalesProdutoTendenciaMediaMovelPresentationState state;
  final SalesProdutoTendenciaMediaMovelSummary summary;
  final bool hasSummary;
  final bool hasActiveDetailFilters;
  final int summaryFingerprint;

  bool isChartReady(SalesProdutoTendenciaMediaMovelChartId chartId) {
    if (state.summaryRows.isEmpty) {
      return false;
    }
    return switch (chartId) {
      SalesProdutoTendenciaMediaMovelChartId.countByClassificacao =>
        state.summaryRows.isNotEmpty,
      SalesProdutoTendenciaMediaMovelChartId.impactByClassificacao =>
        state.summaryRows.isNotEmpty,
    };
  }

  @override
  bool operator ==(Object other) {
    return other is _SalesProdutoTendenciaMediaMovelShellSlice &&
        other.state.selectedAgentId == state.selectedAgentId &&
        other.state.loading == state.loading &&
        other.state.authenticationFailed == state.authenticationFailed &&
        other.state.loadFailure == state.loadFailure &&
        other.hasSummary == hasSummary &&
        other.state.classificacao == state.classificacao &&
        other.hasActiveDetailFilters == hasActiveDetailFilters &&
        other.summaryFingerprint == summaryFingerprint;
  }

  @override
  int get hashCode => Object.hash(
    state.selectedAgentId,
    state.loading,
    state.authenticationFailed,
    state.loadFailure,
    hasSummary,
    state.classificacao,
    hasActiveDetailFilters,
    summaryFingerprint,
  );
}

@immutable
class _SalesProdutoTendenciaMediaMovelDetailsSlice {
  const _SalesProdutoTendenciaMediaMovelDetailsSlice({
    required this.rows,
    required this.totalCount,
    required this.page,
    required this.pageSize,
    required this.totalPages,
    required this.rangeStart,
    required this.rangeEnd,
    required this.sortBy,
    required this.loading,
    required this.detailsLoading,
    required this.hasActiveDetailFilters,
    required this.detailsFingerprint,
  });

  factory _SalesProdutoTendenciaMediaMovelDetailsSlice.from(
    SalesProdutoTendenciaMediaMovelPresentationState state,
  ) {
    final totalPages = state.pageResult.totalCount == 0
        ? 0
        : (state.pageResult.totalCount / state.pageSize).ceil();
    final rangeStart = state.pageResult.totalCount == 0
        ? 0
        : ((state.page - 1) * state.pageSize) + 1;
    final rangeEnd = state.pageResult.totalCount == 0
        ? 0
        : math.min(
            state.page * state.pageSize,
            state.pageResult.totalCount,
          );
    return _SalesProdutoTendenciaMediaMovelDetailsSlice(
      rows: state.pageResult.items,
      totalCount: state.pageResult.totalCount,
      page: state.page,
      pageSize: state.pageSize,
      totalPages: totalPages,
      rangeStart: rangeStart,
      rangeEnd: rangeEnd,
      sortBy: state.sortBy,
      loading: state.loading,
      detailsLoading: state.detailsLoading,
      hasActiveDetailFilters: _hasActiveDetailFilters(state),
      detailsFingerprint: Object.hash(
        state.page,
        state.pageSize,
        state.pageResult.totalCount,
        Object.hashAll(state.pageResult.items),
        state.sortBy,
        state.detailsLoading,
        state.loading,
      ),
    );
  }

  final List<ProdutoVendidoTendenciaDeVendaMediaMovelRow> rows;
  final int totalCount;
  final int page;
  final int pageSize;
  final int totalPages;
  final int rangeStart;
  final int rangeEnd;
  final ProdutoVendidoTendenciaDeVendaMediaMovelSortBy sortBy;
  final bool loading;
  final bool detailsLoading;
  final bool hasActiveDetailFilters;
  final int detailsFingerprint;

  bool get tableLoading => loading || detailsLoading;

  @override
  bool operator ==(Object other) {
    return other is _SalesProdutoTendenciaMediaMovelDetailsSlice &&
        other.detailsFingerprint == detailsFingerprint &&
        other.hasActiveDetailFilters == hasActiveDetailFilters;
  }

  @override
  int get hashCode => Object.hash(detailsFingerprint, hasActiveDetailFilters);
}

bool _hasActiveDetailFilters(
  SalesProdutoTendenciaMediaMovelPresentationState state,
) {
  var count = 0;
  if (state.searchTerm.trim().isNotEmpty) {
    count++;
  }
  if (state.classificacao != null) {
    count++;
  }
  if (state.codGrupoProduto != null) {
    count++;
  }
  if (state.codMarca != null) {
    count++;
  }
  if (state.sortBy !=
      ProdutoVendidoTendenciaDeVendaMediaMovelSortBy.tendenciaPercentualDesc) {
    count++;
  }
  if (state.pageSize !=
      ProdutoVendidoTendenciaDeVendaMediaMovelFilter.defaultPageSize) {
    count++;
  }
  return count > 0;
}
