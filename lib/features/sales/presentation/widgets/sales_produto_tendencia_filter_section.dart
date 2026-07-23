import 'package:colmeia/core/formatters/app_br_formatters.dart';
import 'package:colmeia/features/agent_queries/domain/entities/sales_trend_filter_limits.dart';
import 'package:colmeia/features/agent_queries/domain/entities/sales_trend_metric_mode.dart';
import 'package:colmeia/features/sales/presentation/controllers/sales_produto_tendencia_controller.dart';
import 'package:colmeia/features/sales/presentation/share/sales_produto_tendencia_share.dart';
import 'package:colmeia/features/sales/presentation/state/sales_produto_tendencia_presentation_state.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_card_filter_trigger.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/filters/dashboard_filter.dart';
import 'package:colmeia/shared/widgets/app_tag_chip.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SalesProdutoTendenciaFilterSection extends StatelessWidget {
  const SalesProdutoTendenciaFilterSection({
    required this.onOpenFilters,
    super.key,
    this.onClearClassificacaoFilter,
  });

  final VoidCallback onOpenFilters;
  final VoidCallback? onClearClassificacaoFilter;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.appTokens;

    return Selector<
      SalesProdutoTendenciaController,
      _SalesProdutoTendenciaFilterSlice
    >(
      selector: (_, controller) =>
          _SalesProdutoTendenciaFilterSlice.from(controller.state, l10n),
      builder: (context, slice, _) {
        final activeFilterChips = slice.buildActiveFilterChips(
          l10n: l10n,
          onClearClassificacaoFilter: onClearClassificacaoFilter,
        );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            SalesCardFilterTrigger(
              onTap: onOpenFilters,
              buttonSemanticsLabel: l10n.reportFiltersButton,
              summaryItems: <SalesCardFilterSummaryItem>[
                SalesCardFilterSummaryItem(
                  label: l10n.salesBranchFilterLabel,
                  value: slice.selectedBranchName,
                ),
                SalesCardFilterSummaryItem(
                  label: l10n.salesProdutoTendenciaFilterCurrentPeriod,
                  value: slice.periodoAtualLabel,
                ),
                SalesCardFilterSummaryItem(
                  label: l10n.salesProdutoTendenciaFilterPreviousPeriod,
                  value: slice.periodoAnteriorLabel,
                ),
                SalesCardFilterSummaryItem(
                  label: l10n.reportFiltersTitle,
                  value: l10n.salesProdutoTendenciaActiveFiltersSummary(
                    slice.activeDetailFilterCount,
                  ),
                ),
              ],
              enabled: !slice.loading,
            ),
            if (activeFilterChips.isNotEmpty) ...<Widget>[
              SizedBox(height: tokens.gapMd),
              Wrap(
                spacing: tokens.gapSm,
                runSpacing: tokens.gapSm,
                children: activeFilterChips
                    .map(
                      (chip) => AppTagChip(
                        label: chip.label,
                        onRemove: chip.onRemove,
                        removeSemanticsLabel: chip.removeSemanticsLabel,
                      ),
                    )
                    .toList(growable: false),
              ),
            ],
          ],
        );
      },
    );
  }
}

@immutable
class _SalesProdutoTendenciaFilterSlice {
  const _SalesProdutoTendenciaFilterSlice({
    required this.selectedBranchName,
    required this.periodoAtualLabel,
    required this.periodoAnteriorLabel,
    required this.activeDetailFilterCount,
    required this.searchTerm,
    required this.classificacao,
    required this.codGrupoProduto,
    required this.grupoProdutoLabel,
    required this.codMarca,
    required this.marcaProdutoLabel,
    required this.codFilial,
    required this.filialLabel,
    required this.metricMode,
    required this.minVolumeUnits,
    required this.trendThresholdPercent,
    required this.loading,
  });

  factory _SalesProdutoTendenciaFilterSlice.from(
    SalesProdutoTendenciaPresentationState state,
    AppLocalizations l10n,
  ) {
    final selectedBranch = state.availableAgents
        .cast<DashboardAgentOption?>()
        .firstWhere(
          (agent) => agent?.agentId == state.selectedAgentId,
          orElse: () => null,
        );
    final activeDetailFilterCount = _activeFilterCount(state);
    return _SalesProdutoTendenciaFilterSlice(
      selectedBranchName: selectedBranch?.name ?? l10n.salesBranchPickerEmpty,
      periodoAtualLabel: _dateRangeLabel(state.periodoAtual),
      periodoAnteriorLabel: _dateRangeLabel(state.periodoAnterior),
      activeDetailFilterCount: activeDetailFilterCount,
      searchTerm: state.searchTerm.trim(),
      classificacao: state.classificacao,
      codGrupoProduto: state.codGrupoProduto,
      grupoProdutoLabel: state.grupoProdutoLabel,
      codMarca: state.codMarca,
      marcaProdutoLabel: state.marcaProdutoLabel,
      codFilial: state.codFilial,
      filialLabel: state.filialLabel,
      metricMode: state.metricMode,
      minVolumeUnits: state.minVolumeUnits,
      trendThresholdPercent: state.trendThresholdPercent,
      loading: state.loading,
    );
  }

  final String selectedBranchName;
  final String periodoAtualLabel;
  final String periodoAnteriorLabel;
  final int activeDetailFilterCount;
  final String searchTerm;
  final String? classificacao;
  final int? codGrupoProduto;
  final String? grupoProdutoLabel;
  final int? codMarca;
  final String? marcaProdutoLabel;
  final int? codFilial;
  final String? filialLabel;
  final SalesTrendMetricMode metricMode;
  final int minVolumeUnits;
  final double trendThresholdPercent;
  final bool loading;

  static int _activeFilterCount(SalesProdutoTendenciaPresentationState state) {
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
    if (state.codFilial != null) {
      count++;
    }
    if (state.metricMode != SalesTrendMetricMode.quantity) {
      count++;
    }
    if (state.minVolumeUnits != SalesTrendFilterLimits.defaultMinVolumeUnits) {
      count++;
    }
    if (state.trendThresholdPercent !=
        SalesTrendFilterLimits.defaultTrendThresholdPercent) {
      count++;
    }
    return count;
  }

  static String _dateRangeLabel(DateTimeRange range) {
    return '${AppBrFormatters.shortDateFormat.format(range.start)} · '
        '${AppBrFormatters.shortDateFormat.format(range.end)}';
  }

  List<_SalesProdutoTendenciaFilterChip> buildActiveFilterChips({
    required AppLocalizations l10n,
    VoidCallback? onClearClassificacaoFilter,
  }) {
    final chips = <_SalesProdutoTendenciaFilterChip>[];
    if (searchTerm.isNotEmpty) {
      chips.add(
        _SalesProdutoTendenciaFilterChip(
          label: '${l10n.salesProdutoTendenciaFilterSearch}: $searchTerm',
        ),
      );
    }
    final activeClassificacao = classificacao;
    if (activeClassificacao != null) {
      chips.add(
        _SalesProdutoTendenciaFilterChip(
          label:
              '${l10n.salesProdutoTendenciaFilterClassification}: '
              '${salesProdutoTendenciaClassificacaoLabel(l10n, activeClassificacao)}',
          onRemove: onClearClassificacaoFilter,
          removeSemanticsLabel:
              l10n.salesProdutoTendenciaRemoveClassificacaoFilterSemantics,
        ),
      );
    }
    if (codGrupoProduto != null) {
      final grupoLabel = grupoProdutoLabel ?? '#$codGrupoProduto';
      chips.add(
        _SalesProdutoTendenciaFilterChip(
          label: '${l10n.salesProdutoTendenciaFilterGroup}: $grupoLabel',
        ),
      );
    }
    if (codMarca != null) {
      final marcaLabel = marcaProdutoLabel ?? '#$codMarca';
      chips.add(
        _SalesProdutoTendenciaFilterChip(
          label: '${l10n.salesProdutoTendenciaFilterBrand}: $marcaLabel',
        ),
      );
    }
    if (codFilial != null) {
      final label = filialLabel ?? '#$codFilial';
      chips.add(
        _SalesProdutoTendenciaFilterChip(
          label: '${l10n.salesTrendFilterFilialLabel}: $label',
        ),
      );
    }
    if (metricMode != SalesTrendMetricMode.quantity) {
      chips.add(
        _SalesProdutoTendenciaFilterChip(
          label:
              '${l10n.salesTrendFilterMetricTitle}: '
              '${l10n.salesTrendFilterMetricRevenue}',
        ),
      );
    }
    if (minVolumeUnits != SalesTrendFilterLimits.defaultMinVolumeUnits) {
      chips.add(
        _SalesProdutoTendenciaFilterChip(
          label: '${l10n.salesTrendFilterMinVolumeTitle}: $minVolumeUnits',
        ),
      );
    }
    if (trendThresholdPercent !=
        SalesTrendFilterLimits.defaultTrendThresholdPercent) {
      chips.add(
        _SalesProdutoTendenciaFilterChip(
          label:
              '${l10n.salesTrendFilterThresholdTitle}: '
              '${l10n.salesTrendFilterThresholdPercentLabel((trendThresholdPercent * 100).round())}',
        ),
      );
    }
    return chips;
  }

  @override
  bool operator ==(Object other) {
    return other is _SalesProdutoTendenciaFilterSlice &&
        other.selectedBranchName == selectedBranchName &&
        other.periodoAtualLabel == periodoAtualLabel &&
        other.periodoAnteriorLabel == periodoAnteriorLabel &&
        other.activeDetailFilterCount == activeDetailFilterCount &&
        other.searchTerm == searchTerm &&
        other.classificacao == classificacao &&
        other.codGrupoProduto == codGrupoProduto &&
        other.grupoProdutoLabel == grupoProdutoLabel &&
        other.codMarca == codMarca &&
        other.marcaProdutoLabel == marcaProdutoLabel &&
        other.codFilial == codFilial &&
        other.filialLabel == filialLabel &&
        other.metricMode == metricMode &&
        other.minVolumeUnits == minVolumeUnits &&
        other.trendThresholdPercent == trendThresholdPercent &&
        other.loading == loading;
  }

  @override
  int get hashCode => Object.hash(
    selectedBranchName,
    periodoAtualLabel,
    periodoAnteriorLabel,
    activeDetailFilterCount,
    searchTerm,
    classificacao,
    codGrupoProduto,
    grupoProdutoLabel,
    Object.hash(
      codMarca,
      marcaProdutoLabel,
      codFilial,
      filialLabel,
      metricMode,
      minVolumeUnits,
      trendThresholdPercent,
      loading,
    ),
  );
}

@immutable
class _SalesProdutoTendenciaFilterChip {
  const _SalesProdutoTendenciaFilterChip({
    required this.label,
    this.onRemove,
    this.removeSemanticsLabel,
  });

  final String label;
  final VoidCallback? onRemove;
  final String? removeSemanticsLabel;

  @override
  bool operator ==(Object other) {
    return other is _SalesProdutoTendenciaFilterChip &&
        other.label == label &&
        other.removeSemanticsLabel == removeSemanticsLabel;
  }

  @override
  int get hashCode => Object.hash(label, removeSemanticsLabel);
}
