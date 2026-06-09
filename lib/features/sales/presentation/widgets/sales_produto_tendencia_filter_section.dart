import 'package:colmeia/core/formatters/app_br_formatters.dart';
import 'package:colmeia/features/sales/presentation/controllers/sales_produto_tendencia_controller.dart';
import 'package:colmeia/features/sales/presentation/share/sales_produto_tendencia_share.dart';
import 'package:colmeia/features/sales/presentation/state/sales_produto_tendencia_presentation_state.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_card_filter_trigger.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/filters/dashboard_filter.dart';
import 'package:colmeia/shared/widgets/app_tag_chip.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SalesProdutoTendenciaFilterSection extends StatelessWidget {
  const SalesProdutoTendenciaFilterSection({
    required this.onOpenFilters,
    super.key,
  });

  final VoidCallback onOpenFilters;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.appTokens;

    return Selector<SalesProdutoTendenciaController,
        _SalesProdutoTendenciaFilterSlice>(
      selector: (_, controller) =>
          _SalesProdutoTendenciaFilterSlice.from(controller.state, l10n),
      builder: (context, slice, _) {
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
            if (slice.activeFilterChipLabels.isNotEmpty) ...<Widget>[
              SizedBox(height: tokens.gapMd),
              Wrap(
                spacing: tokens.gapSm,
                runSpacing: tokens.gapSm,
                children: slice.activeFilterChipLabels
                    .map((label) => AppTagChip(label: label))
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
    required this.activeFilterChipLabels,
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
    final activeFilterChipLabels = _activeFilterChipLabels(l10n, state);
    return _SalesProdutoTendenciaFilterSlice(
      selectedBranchName: selectedBranch?.name ?? l10n.salesBranchPickerEmpty,
      periodoAtualLabel: _dateRangeLabel(state.periodoAtual),
      periodoAnteriorLabel: _dateRangeLabel(state.periodoAnterior),
      activeDetailFilterCount: activeFilterChipLabels.length,
      activeFilterChipLabels: activeFilterChipLabels,
      loading: state.loading,
    );
  }

  final String selectedBranchName;
  final String periodoAtualLabel;
  final String periodoAnteriorLabel;
  final int activeDetailFilterCount;
  final List<String> activeFilterChipLabels;
  final bool loading;

  static String _dateRangeLabel(DateTimeRange range) {
    return '${AppBrFormatters.shortDateFormat.format(range.start)} · '
        '${AppBrFormatters.shortDateFormat.format(range.end)}';
  }

  static List<String> _activeFilterChipLabels(
    AppLocalizations l10n,
    SalesProdutoTendenciaPresentationState state,
  ) {
    final labels = <String>[];
    final trimmedSearch = state.searchTerm.trim();
    if (trimmedSearch.isNotEmpty) {
      labels.add('${l10n.salesProdutoTendenciaFilterSearch}: $trimmedSearch');
    }
    if (state.classificacao != null) {
      labels.add(
        '${l10n.salesProdutoTendenciaFilterClassification}: '
        '${salesProdutoTendenciaClassificacaoLabel(l10n, state.classificacao)}',
      );
    }
    if (state.codGrupoProduto != null) {
      final grupoLabel = state.grupoProdutoLabel ?? '#${state.codGrupoProduto}';
      labels.add('${l10n.salesProdutoTendenciaFilterGroup}: $grupoLabel');
    }
    if (state.codMarca != null) {
      final marcaLabel = state.marcaProdutoLabel ?? '#${state.codMarca}';
      labels.add('${l10n.salesProdutoTendenciaFilterBrand}: $marcaLabel');
    }
    return labels;
  }

  @override
  bool operator ==(Object other) {
    return other is _SalesProdutoTendenciaFilterSlice &&
        other.selectedBranchName == selectedBranchName &&
        other.periodoAtualLabel == periodoAtualLabel &&
        other.periodoAnteriorLabel == periodoAnteriorLabel &&
        other.activeDetailFilterCount == activeDetailFilterCount &&
        listEquals(other.activeFilterChipLabels, activeFilterChipLabels) &&
        other.loading == loading;
  }

  @override
  int get hashCode => Object.hash(
    selectedBranchName,
    periodoAtualLabel,
    periodoAnteriorLabel,
    activeDetailFilterCount,
    Object.hashAll(activeFilterChipLabels),
    loading,
  );
}
