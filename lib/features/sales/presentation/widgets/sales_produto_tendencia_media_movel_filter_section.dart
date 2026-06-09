import 'dart:async';

import 'package:colmeia/features/agent_queries/domain/entities/produto_vendido_tendencia_de_venda_media_movel_filter.dart';
import 'package:colmeia/features/sales/presentation/controllers/sales_produto_tendencia_media_movel_controller.dart';
import 'package:colmeia/features/sales/presentation/state/sales_produto_tendencia_media_movel_presentation_state.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_card_filter_trigger.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_produto_tendencia_media_movel_classificacao_labels.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_single_agent_picker_control.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/filters/dashboard_filter.dart';
import 'package:colmeia/shared/widgets/app_tag_chip.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SalesProdutoTendenciaMediaMovelFilterSection extends StatelessWidget {
  const SalesProdutoTendenciaMediaMovelFilterSection({
    required this.onOpenFilters,
    super.key,
  });

  final VoidCallback onOpenFilters;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.appTokens;

    return Selector<SalesProdutoTendenciaMediaMovelController,
        _SalesProdutoTendenciaMediaMovelFilterSlice>(
      selector: (_, controller) =>
          _SalesProdutoTendenciaMediaMovelFilterSlice.from(
            controller.state,
            l10n,
          ),
      builder: (context, slice, _) {
        final controller =
            context.read<SalesProdutoTendenciaMediaMovelController>();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            SalesBranchPickerControl(
              l10n: l10n,
              availableBranches: slice.availableAgents,
              selectedBranchId: slice.selectedAgentId,
              onSelectionChanged: (agentId) {
                unawaited(controller.changeAgent(agentId));
              },
            ),
            SizedBox(height: tokens.gapMd),
            SalesCardFilterTrigger(
              enabled: !slice.loading,
              summaryItems: <SalesCardFilterSummaryItem>[
                SalesCardFilterSummaryItem(
                  label: l10n.salesBranchFilterLabel,
                  value: slice.selectedBranchName,
                ),
                SalesCardFilterSummaryItem(
                  label: l10n.salesProdutoTendenciaMediaMovelFilterQuantidadeDias,
                  value: l10n
                      .salesProdutoTendenciaMediaMovelFilterQuantidadeDiasValue(
                        slice.quantidadeDias,
                      ),
                ),
                SalesCardFilterSummaryItem(
                  label: l10n.salesProdutoTendenciaMediaMovelFilterSortBy,
                  value: produtoTendenciaMediaMovelSortLabel(
                    l10n,
                    slice.sortBy,
                  ),
                ),
                SalesCardFilterSummaryItem(
                  label: l10n.reportFiltersTitle,
                  value: l10n.salesProdutoTendenciaMediaMovelActiveFiltersSummary(
                    slice.activeFilterCount,
                  ),
                ),
              ],
              onTap: onOpenFilters,
              buttonSemanticsLabel: l10n.reportFiltersTitleWithContext(
                l10n.salesCardProdutoTendenciaMediaMovelTitle,
              ),
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
class _SalesProdutoTendenciaMediaMovelFilterSlice {
  const _SalesProdutoTendenciaMediaMovelFilterSlice({
    required this.availableAgents,
    required this.selectedAgentId,
    required this.selectedBranchName,
    required this.quantidadeDias,
    required this.sortBy,
    required this.activeFilterCount,
    required this.activeFilterChipLabels,
    required this.loading,
  });

  factory _SalesProdutoTendenciaMediaMovelFilterSlice.from(
    SalesProdutoTendenciaMediaMovelPresentationState state,
    AppLocalizations l10n,
  ) {
    final selectedBranch = state.availableAgents
        .cast<DashboardAgentOption?>()
        .firstWhere(
          (agent) => agent?.agentId == state.selectedAgentId,
          orElse: () => null,
        );
    final activeFilterChipLabels = _activeFilterChipLabels(l10n, state);
    return _SalesProdutoTendenciaMediaMovelFilterSlice(
      availableAgents: state.availableAgents,
      selectedAgentId: state.selectedAgentId,
      selectedBranchName:
          selectedBranch?.name ?? l10n.salesBranchRequiredMessage,
      quantidadeDias: state.quantidadeDias,
      sortBy: state.sortBy,
      activeFilterCount: _activeFilterCount(l10n, state),
      activeFilterChipLabels: activeFilterChipLabels,
      loading: state.loading,
    );
  }

  final List<DashboardAgentOption> availableAgents;
  final String? selectedAgentId;
  final String selectedBranchName;
  final int quantidadeDias;
  final ProdutoVendidoTendenciaDeVendaMediaMovelSortBy sortBy;
  final int activeFilterCount;
  final List<String> activeFilterChipLabels;
  final bool loading;

  static List<String> _activeFilterChipLabels(
    AppLocalizations l10n,
    SalesProdutoTendenciaMediaMovelPresentationState state,
  ) {
    final labels = <String>[];
    final trimmedSearch = state.searchTerm.trim();
    if (trimmedSearch.isNotEmpty) {
      labels.add('${l10n.salesProdutoTendenciaFilterSearch}: $trimmedSearch');
    }
    if (state.classificacao != null) {
      labels.add(
        '${l10n.salesProdutoTendenciaFilterClassification}: '
        '${produtoTendenciaMediaMovelClassificacaoLabel(l10n, state.classificacao!)}',
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

  static int _activeFilterCount(
    AppLocalizations l10n,
    SalesProdutoTendenciaMediaMovelPresentationState state,
  ) {
    var count = _activeFilterChipLabels(l10n, state).length;
    if (state.sortBy !=
        ProdutoVendidoTendenciaDeVendaMediaMovelSortBy
            .tendenciaPercentualDesc) {
      count++;
    }
    if (state.pageSize !=
        ProdutoVendidoTendenciaDeVendaMediaMovelFilter.defaultPageSize) {
      count++;
    }
    return count;
  }

  @override
  bool operator ==(Object other) {
    return other is _SalesProdutoTendenciaMediaMovelFilterSlice &&
        listEquals(other.availableAgents, availableAgents) &&
        other.selectedAgentId == selectedAgentId &&
        other.selectedBranchName == selectedBranchName &&
        other.quantidadeDias == quantidadeDias &&
        other.sortBy == sortBy &&
        other.activeFilterCount == activeFilterCount &&
        listEquals(other.activeFilterChipLabels, activeFilterChipLabels) &&
        other.loading == loading;
  }

  @override
  int get hashCode => Object.hash(
    Object.hashAll(availableAgents),
    selectedAgentId,
    selectedBranchName,
    quantidadeDias,
    sortBy,
    activeFilterCount,
    Object.hashAll(activeFilterChipLabels),
    loading,
  );
}
