import 'dart:async';

import 'package:colmeia/core/formatters/app_br_formatters.dart';
import 'package:colmeia/features/agent_queries/presentation/agent_query_failure_support_context.dart';
import 'package:colmeia/features/sales/presentation/controllers/sales_produto_tendencia_controller.dart';
import 'package:colmeia/features/sales/presentation/share/sales_produto_tendencia_share.dart';
import 'package:colmeia/features/sales/presentation/state/sales_produto_tendencia_presentation_state.dart';
import 'package:colmeia/features/sales/presentation/utils/sales_trend_date_preset.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_produto_tendencia_chart_nav_grid.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_produto_tendencia_details_section.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_produto_tendencia_summary_section.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/agent_query_error_panel.dart';
import 'package:colmeia/shared/widgets/app_inline_error_panel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SalesProdutoTendenciaBodySection extends StatelessWidget {
  const SalesProdutoTendenciaBodySection({
    required this.onRetryReload,
    required this.onClearDetailFilters,
    required this.onOpenFilters,
    required this.onChartSelected,
    required this.onClassificacaoSelected,
    required this.onClearClassificacaoFilter,
    required this.retryCountdownLabel,
    this.detailsSectionKey,
    this.classificacaoShareKey,
    this.onShareClassificacao,
    super.key,
  });

  final GlobalKey? detailsSectionKey;
  final VoidCallback onRetryReload;
  final VoidCallback onClearDetailFilters;
  final VoidCallback onOpenFilters;
  final void Function(
    SalesProdutoTendenciaPresentationState state,
    SalesProdutoTendenciaChartId chartId,
  )
  onChartSelected;
  final ValueChanged<String> onClassificacaoSelected;
  final VoidCallback onClearClassificacaoFilter;
  final String? retryCountdownLabel;
  final Key? classificacaoShareKey;
  final VoidCallback? onShareClassificacao;

  @override
  Widget build(BuildContext context) {
    return Selector<
      SalesProdutoTendenciaController,
      _SalesProdutoTendenciaBodySlice
    >(
      selector: (_, controller) =>
          _SalesProdutoTendenciaBodySlice.from(controller.state),
      builder: (context, slice, _) {
        final l10n = AppLocalizations.of(context);
        final tokens = context.appTokens;
        final state = slice.state;
        final controller = context.read<SalesProdutoTendenciaController>();

        if (state.selectedAgentId == null) {
          return AppInlineErrorPanel(
            tone: AppInlinePanelTone.informational,
            title: l10n.salesBranchRequiredTitle,
            message: l10n.salesBranchRequiredMessage,
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
                'screen': 'sales_produto_tendencia',
              },
            ),
          );
        }

        if (state.authenticationFailed) {
          return AppInlineErrorPanel(
            message: l10n.agentSqlErrorAuthenticationFailed,
            onRetry: onRetryReload,
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            SalesProdutoTendenciaSummarySection(
              l10n: l10n,
              summaryRows: state.summaryRows,
              loading: state.loading,
              periodoAtual: state.periodoAtual,
              periodoAnterior: state.periodoAnterior,
              periodoAtualDescriptor: salesTrendRangeDescriptorLabel(
                l10n,
                state.periodoAtual,
              ),
              periodoAnteriorDescriptor: salesTrendRangeDescriptorLabel(
                l10n,
                state.periodoAnterior,
              ),
              activeClassificacao: state.classificacao,
              hasActiveDetailFilters: slice.hasActiveDetailFilters,
              onClearFilters: onClearDetailFilters,
              onOpenFilters: onOpenFilters,
              onClearClassificacaoFilter: onClearClassificacaoFilter,
              onClassificacaoSelected: onClassificacaoSelected,
              classificacaoShareKey: classificacaoShareKey,
              onShareClassificacao: onShareClassificacao,
            ),
            SizedBox(height: tokens.sectionSpacing),
            SalesProdutoTendenciaChartNavGrid(
              l10n: l10n,
              loading: state.loading,
              sectionTitle: l10n.salesProdutoTendenciaChartsSectionTitle,
              isChartReady: (chartId) => slice.isChartReady(chartId),
              onChartSelected: (chartId) => onChartSelected(state, chartId),
            ),
            SizedBox(height: tokens.sectionSpacing),
            SalesProdutoTendenciaDetailsSection(
              key: detailsSectionKey,
              l10n: l10n,
              rows: state.rows,
              totalCount: state.totalCount,
              loading: state.loading,
              currentPage: state.page,
              pageSize: state.pageSize,
              onPageSelected: (page) => unawaited(controller.selectPage(page)),
              onPageSizeChanged: (size) =>
                  unawaited(controller.changePageSize(size)),
              classLabelBuilder: (value) =>
                  salesProdutoTendenciaClassificacaoLabel(l10n, value),
              activeClassificacao: state.classificacao,
              periodoAtualLabel:
                  '${AppBrFormatters.shortDate(state.periodoAtual.start)} - '
                  '${AppBrFormatters.shortDate(state.periodoAtual.end)}',
              periodoAnteriorLabel:
                  '${AppBrFormatters.shortDate(state.periodoAnterior.start)} - '
                  '${AppBrFormatters.shortDate(state.periodoAnterior.end)}',
              hasActiveDetailFilters: slice.hasActiveDetailFilters,
              onClearFilters: onClearDetailFilters,
              onOpenFilters: onOpenFilters,
            ),
          ],
        );
      },
    );
  }
}

@immutable
class _SalesProdutoTendenciaBodySlice {
  const _SalesProdutoTendenciaBodySlice({
    required this.state,
    required this.hasActiveDetailFilters,
    required this.summaryFingerprint,
    required this.topMoversFingerprint,
    required this.detailsFingerprint,
  });

  factory _SalesProdutoTendenciaBodySlice.from(
    SalesProdutoTendenciaPresentationState state,
  ) {
    return _SalesProdutoTendenciaBodySlice(
      state: state,
      hasActiveDetailFilters: _hasActiveDetailFilters(state),
      summaryFingerprint: Object.hashAll(state.summaryRows),
      topMoversFingerprint: Object.hash(
        Object.hashAll(state.topGainers),
        Object.hashAll(state.topLosers),
      ),
      detailsFingerprint: Object.hash(
        state.page,
        state.pageSize,
        state.totalCount,
        Object.hashAll(state.rows),
      ),
    );
  }

  final SalesProdutoTendenciaPresentationState state;
  final bool hasActiveDetailFilters;
  final int summaryFingerprint;
  final int topMoversFingerprint;
  final int detailsFingerprint;

  bool isChartReady(SalesProdutoTendenciaChartId chartId) {
    return switch (chartId) {
      SalesProdutoTendenciaChartId.classificacao =>
        state.summaryRows.isNotEmpty,
      SalesProdutoTendenciaChartId.topGainers => state.topGainers.isNotEmpty,
      SalesProdutoTendenciaChartId.topLosers => state.topLosers.isNotEmpty,
    };
  }

  static bool _hasActiveDetailFilters(
    SalesProdutoTendenciaPresentationState state,
  ) {
    return state.searchTerm.trim().isNotEmpty ||
        state.classificacao != null ||
        state.codGrupoProduto != null ||
        state.codMarca != null;
  }

  @override
  bool operator ==(Object other) {
    return other is _SalesProdutoTendenciaBodySlice &&
        other.state.selectedAgentId == state.selectedAgentId &&
        other.state.loading == state.loading &&
        other.state.authenticationFailed == state.authenticationFailed &&
        other.state.loadFailure == state.loadFailure &&
        other.state.periodoAtual == state.periodoAtual &&
        other.state.periodoAnterior == state.periodoAnterior &&
        other.state.classificacao == state.classificacao &&
        other.hasActiveDetailFilters == hasActiveDetailFilters &&
        other.summaryFingerprint == summaryFingerprint &&
        other.topMoversFingerprint == topMoversFingerprint &&
        other.detailsFingerprint == detailsFingerprint;
  }

  @override
  int get hashCode => Object.hash(
    state.selectedAgentId,
    state.loading,
    state.authenticationFailed,
    state.loadFailure,
    state.periodoAtual,
    state.periodoAnterior,
    state.classificacao,
    hasActiveDetailFilters,
    summaryFingerprint,
    topMoversFingerprint,
    detailsFingerprint,
  );
}
