import 'dart:async';
import 'dart:math' as math;

import 'package:colmeia/features/agent_queries/domain/entities/produto_vendido_tendencia_de_venda_media_movel_filter.dart';
import 'package:colmeia/features/agent_queries/presentation/agent_query_failure_support_context.dart';
import 'package:colmeia/features/sales/presentation/controllers/sales_produto_tendencia_media_movel_controller.dart';
import 'package:colmeia/features/sales/presentation/state/sales_produto_tendencia_media_movel_presentation_state.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_produto_tendencia_media_movel_chart_nav_grid.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_produto_tendencia_media_movel_details_section.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_produto_tendencia_media_movel_summary_section.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/agent_query_error_panel.dart';
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
      _SalesProdutoTendenciaMediaMovelBodySlice
    >(
      selector: (_, controller) =>
          _SalesProdutoTendenciaMediaMovelBodySlice.from(controller.state),
      builder: (context, slice, _) {
        final l10n = AppLocalizations.of(context);
        final tokens = context.appTokens;
        final state = slice.state;
        final controller = context
            .read<SalesProdutoTendenciaMediaMovelController>();

        if (state.selectedAgentId == null ||
            state.selectedAgentId!.trim().isEmpty) {
          return AppInlineErrorPanel(
            tone: AppInlinePanelTone.informational,
            title: l10n.salesBranchRequiredTitle,
            message: l10n.salesProdutoTendenciaMediaMovelSelectAgentHint,
          );
        }

        if (state.loadFailure != null) {
          return AgentQueryErrorPanel.fromFailure(
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
            SalesProdutoTendenciaMediaMovelDetailsSection(
              key: detailsSectionKey,
              l10n: l10n,
              loading: state.loading,
              rows: state.pageResult.items,
              totalCount: state.pageResult.totalCount,
              pageSize: state.pageSize,
              currentPage: state.page,
              totalPages: slice.totalPages,
              rangeStart: slice.rangeStart,
              rangeEnd: slice.rangeEnd,
              sortBy: state.sortBy,
              hasActiveDetailFilters: slice.hasActiveDetailFilters,
              onClearFilters: onClearDetailFilters,
              onOpenFilters: onOpenFilters,
              headerTrailing: AppChartHeaderTrailing(
                shareProgressKey: detailsShareKey,
                shareEnabled: !state.loading && state.pageResult.totalCount > 0,
                onShare: state.loading || state.pageResult.totalCount <= 0
                    ? null
                    : onShareDetails,
              ),
              onPageSelected: (page) {
                unawaited(controller.selectPage(page));
              },
              onNext: state.page < slice.totalPages
                  ? () => unawaited(controller.selectPage(state.page + 1))
                  : null,
              onPrevious: state.page > 1
                  ? () => unawaited(controller.selectPage(state.page - 1))
                  : null,
              onPageSizeChanged: (value) {
                unawaited(controller.changePageSize(value));
              },
            ),
          ],
        );
      },
    );
  }
}

@immutable
class _SalesProdutoTendenciaMediaMovelBodySlice {
  const _SalesProdutoTendenciaMediaMovelBodySlice({
    required this.state,
    required this.summary,
    required this.hasSummary,
    required this.hasActiveDetailFilters,
    required this.totalPages,
    required this.rangeStart,
    required this.rangeEnd,
    required this.summaryFingerprint,
    required this.detailsFingerprint,
  });

  factory _SalesProdutoTendenciaMediaMovelBodySlice.from(
    SalesProdutoTendenciaMediaMovelPresentationState state,
  ) {
    final summary = buildSalesProdutoTendenciaMediaMovelSummary(
      state.summaryRows,
    );
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
    return _SalesProdutoTendenciaMediaMovelBodySlice(
      state: state,
      summary: summary,
      hasSummary: state.summaryRows.isNotEmpty,
      hasActiveDetailFilters: _hasActiveDetailFilters(state),
      totalPages: totalPages,
      rangeStart: rangeStart,
      rangeEnd: rangeEnd,
      summaryFingerprint: Object.hashAll(state.summaryRows),
      detailsFingerprint: Object.hash(
        state.page,
        state.pageSize,
        state.pageResult.totalCount,
        Object.hashAll(state.pageResult.items),
        state.sortBy,
      ),
    );
  }

  final SalesProdutoTendenciaMediaMovelPresentationState state;
  final SalesProdutoTendenciaMediaMovelSummary summary;
  final bool hasSummary;
  final bool hasActiveDetailFilters;
  final int totalPages;
  final int rangeStart;
  final int rangeEnd;
  final int summaryFingerprint;
  final int detailsFingerprint;

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

  static bool _hasActiveDetailFilters(
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
        ProdutoVendidoTendenciaDeVendaMediaMovelSortBy
            .tendenciaPercentualDesc) {
      count++;
    }
    if (state.pageSize !=
        ProdutoVendidoTendenciaDeVendaMediaMovelFilter.defaultPageSize) {
      count++;
    }
    return count > 0;
  }

  @override
  bool operator ==(Object other) {
    return other is _SalesProdutoTendenciaMediaMovelBodySlice &&
        other.state.selectedAgentId == state.selectedAgentId &&
        other.state.loading == state.loading &&
        other.state.authenticationFailed == state.authenticationFailed &&
        other.state.loadFailure == state.loadFailure &&
        other.hasSummary == hasSummary &&
        other.state.classificacao == state.classificacao &&
        other.hasActiveDetailFilters == hasActiveDetailFilters &&
        other.totalPages == totalPages &&
        other.rangeStart == rangeStart &&
        other.rangeEnd == rangeEnd &&
        other.summaryFingerprint == summaryFingerprint &&
        other.detailsFingerprint == detailsFingerprint;
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
    totalPages,
    rangeStart,
    rangeEnd,
    summaryFingerprint,
    detailsFingerprint,
  );
}
