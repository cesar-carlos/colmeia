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
    this.onClearClassificacaoFilter,
  });

  final VoidCallback onOpenFilters;
  final VoidCallback? onClearClassificacaoFilter;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.appTokens;

    return Selector<
      SalesProdutoTendenciaMediaMovelController,
      _SalesProdutoTendenciaMediaMovelFilterSlice
    >(
      selector: (_, controller) =>
          _SalesProdutoTendenciaMediaMovelFilterSlice.from(
            controller.state,
            l10n,
          ),
      builder: (context, slice, _) {
        final controller = context
            .read<SalesProdutoTendenciaMediaMovelController>();
        final activeFilterChips = slice.buildActiveFilterChips(
          l10n: l10n,
          onClearClassificacaoFilter: onClearClassificacaoFilter,
        );

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
                  label:
                      l10n.salesProdutoTendenciaMediaMovelFilterQuantidadeDias,
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
                  value: l10n
                      .salesProdutoTendenciaMediaMovelActiveFiltersSummary(
                        slice.activeFilterCount,
                      ),
                ),
              ],
              onTap: onOpenFilters,
              buttonSemanticsLabel: l10n.reportFiltersTitleWithContext(
                l10n.salesCardProdutoTendenciaMediaMovelTitle,
              ),
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
class _SalesProdutoTendenciaMediaMovelFilterSlice {
  const _SalesProdutoTendenciaMediaMovelFilterSlice({
    required this.availableAgents,
    required this.selectedAgentId,
    required this.selectedBranchName,
    required this.quantidadeDias,
    required this.sortBy,
    required this.activeFilterCount,
    required this.searchTerm,
    required this.classificacao,
    required this.codGrupoProduto,
    required this.grupoProdutoLabel,
    required this.codMarca,
    required this.marcaProdutoLabel,
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
    return _SalesProdutoTendenciaMediaMovelFilterSlice(
      availableAgents: state.availableAgents,
      selectedAgentId: state.selectedAgentId,
      selectedBranchName:
          selectedBranch?.name ?? l10n.salesBranchRequiredMessage,
      quantidadeDias: state.quantidadeDias,
      sortBy: state.sortBy,
      activeFilterCount: _activeFilterCount(l10n, state),
      searchTerm: state.searchTerm.trim(),
      classificacao: state.classificacao,
      codGrupoProduto: state.codGrupoProduto,
      grupoProdutoLabel: state.grupoProdutoLabel,
      codMarca: state.codMarca,
      marcaProdutoLabel: state.marcaProdutoLabel,
      loading: state.loading,
    );
  }

  final List<DashboardAgentOption> availableAgents;
  final String? selectedAgentId;
  final String selectedBranchName;
  final int quantidadeDias;
  final ProdutoVendidoTendenciaDeVendaMediaMovelSortBy sortBy;
  final int activeFilterCount;
  final String searchTerm;
  final String? classificacao;
  final int? codGrupoProduto;
  final String? grupoProdutoLabel;
  final int? codMarca;
  final String? marcaProdutoLabel;
  final bool loading;

  List<_SalesProdutoTendenciaMediaMovelFilterChip> buildActiveFilterChips({
    required AppLocalizations l10n,
    VoidCallback? onClearClassificacaoFilter,
  }) {
    final chips = <_SalesProdutoTendenciaMediaMovelFilterChip>[];
    if (searchTerm.isNotEmpty) {
      chips.add(
        _SalesProdutoTendenciaMediaMovelFilterChip(
          label: '${l10n.salesProdutoTendenciaFilterSearch}: $searchTerm',
        ),
      );
    }
    final activeClassificacao = classificacao;
    if (activeClassificacao != null) {
      chips.add(
        _SalesProdutoTendenciaMediaMovelFilterChip(
          label:
              '${l10n.salesProdutoTendenciaFilterClassification}: '
              '${produtoTendenciaMediaMovelClassificacaoLabel(l10n, activeClassificacao)}',
          onRemove: onClearClassificacaoFilter,
          removeSemanticsLabel: l10n
              .salesProdutoTendenciaMediaMovelRemoveClassificacaoFilterSemantics,
        ),
      );
    }
    if (codGrupoProduto != null) {
      final grupoLabel = grupoProdutoLabel ?? '#$codGrupoProduto';
      chips.add(
        _SalesProdutoTendenciaMediaMovelFilterChip(
          label: '${l10n.salesProdutoTendenciaFilterGroup}: $grupoLabel',
        ),
      );
    }
    if (codMarca != null) {
      final marcaLabel = marcaProdutoLabel ?? '#$codMarca';
      chips.add(
        _SalesProdutoTendenciaMediaMovelFilterChip(
          label: '${l10n.salesProdutoTendenciaFilterBrand}: $marcaLabel',
        ),
      );
    }
    return chips;
  }

  static int _activeFilterCount(
    AppLocalizations l10n,
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
        other.searchTerm == searchTerm &&
        other.classificacao == classificacao &&
        other.codGrupoProduto == codGrupoProduto &&
        other.grupoProdutoLabel == grupoProdutoLabel &&
        other.codMarca == codMarca &&
        other.marcaProdutoLabel == marcaProdutoLabel &&
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
    searchTerm,
    classificacao,
    codGrupoProduto,
    grupoProdutoLabel,
    codMarca,
    marcaProdutoLabel,
    loading,
  );
}

@immutable
class _SalesProdutoTendenciaMediaMovelFilterChip {
  const _SalesProdutoTendenciaMediaMovelFilterChip({
    required this.label,
    this.onRemove,
    this.removeSemanticsLabel,
  });

  final String label;
  final VoidCallback? onRemove;
  final String? removeSemanticsLabel;

  @override
  bool operator ==(Object other) {
    return other is _SalesProdutoTendenciaMediaMovelFilterChip &&
        other.label == label &&
        other.removeSemanticsLabel == removeSemanticsLabel;
  }

  @override
  int get hashCode => Object.hash(label, removeSemanticsLabel);
}
