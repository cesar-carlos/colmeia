import 'package:colmeia/features/agent_queries/domain/entities/margem_produto_filter.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_filters_sheet_scaffold.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_single_agent_picker_control.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/filters/dashboard_filter.dart';
import 'package:colmeia/shared/widgets/app_inline_error_panel.dart';
import 'package:colmeia/shared/widgets/forms/app_dropdown_field.dart';
import 'package:material_ui/material_ui.dart';

String salesMargemProdutoCostFilterLabel(
  AppLocalizations l10n,
  MargemProdutoCostFilter filter,
) => switch (filter) {
  MargemProdutoCostFilter.all => l10n.salesMargemProdutoCostAll,
  MargemProdutoCostFilter.withCost => l10n.salesMargemProdutoCostWith,
  MargemProdutoCostFilter.withoutCost => l10n.salesMargemProdutoCostWithout,
};

class SalesMargemProdutoFiltersSheet extends StatefulWidget {
  const SalesMargemProdutoFiltersSheet({
    required this.l10n,
    required this.availableAgents,
    required this.initialSelectedAgentId,
    required this.onApply,
    this.initialCostFilter = MargemProdutoCostFilter.withCost,
    super.key,
  });

  final AppLocalizations l10n;
  final List<DashboardAgentOption> availableAgents;
  final String? initialSelectedAgentId;
  final MargemProdutoCostFilter initialCostFilter;
  final ValueChanged<Map<String, Object?>> onApply;

  @override
  State<SalesMargemProdutoFiltersSheet> createState() =>
      _SalesMargemProdutoFiltersSheetState();
}

class _SalesMargemProdutoFiltersSheetState
    extends State<SalesMargemProdutoFiltersSheet> {
  String? _selectedAgentId;
  late MargemProdutoCostFilter _costFilter;

  @override
  void initState() {
    super.initState();
    _selectedAgentId = widget.initialSelectedAgentId;
    _costFilter = widget.initialCostFilter;
  }

  void _apply() {
    final selectedAgentId = _selectedAgentId;
    if (selectedAgentId == null || selectedAgentId.trim().isEmpty) {
      return;
    }
    widget.onApply(<String, Object?>{
      'agentId': selectedAgentId,
      'costFilter': _costFilter.name,
    });
    Navigator.of(context).pop();
  }

  void _clear() {
    setState(() {
      _selectedAgentId = widget.initialSelectedAgentId;
      _costFilter = MargemProdutoCostFilter.withCost;
    });
  }

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).appTokens;
    final l10n = widget.l10n;
    final selectedAgentMissingToken =
        _selectedAgentId != null &&
        widget.availableAgents.any(
          (agent) =>
              agent.agentId == _selectedAgentId &&
              agent.missingLocalClientToken,
        );

    return SalesFiltersSheetScaffold(
      title: l10n.reportFiltersTitleWithContext(
        l10n.salesCardMargemProdutoTitle,
      ),
      description: l10n.reportFiltersDescription,
      primaryActionLabel: l10n.reportFiltersApplyAction,
      secondaryActionLabel: l10n.reportFiltersClearAction,
      onPrimaryAction: _apply,
      onSecondaryAction: _clear,
      canPrimaryAction: _selectedAgentId != null,
      bodyBuilder: (scrollController) {
        return ListView(
          controller: scrollController,
          padding: EdgeInsets.fromLTRB(
            tokens.contentSpacing,
            0,
            tokens.contentSpacing,
            tokens.contentSpacing,
          ),
          children: <Widget>[
            SalesFiltersSectionHeader(
              title: l10n.salesBranchFilterLabel,
              subtitle: l10n.salesBranchRequiredMessage,
              requiredBadgeLabel: l10n.reportFiltersRequiredCount(1),
            ),
            SizedBox(height: tokens.gapSm),
            SalesBranchPickerControl(
              l10n: l10n,
              availableBranches: widget.availableAgents,
              selectedBranchId: _selectedAgentId,
              showTrailingFilterButton: false,
              onSelectionChanged: (agentId) {
                setState(() => _selectedAgentId = agentId);
              },
            ),
            SizedBox(height: tokens.gapMd),
            AppDropdownField<MargemProdutoCostFilter>(
              label: l10n.salesMargemProdutoCostFilter,
              helperText: l10n.salesMargemProdutoCostHelp,
              value: _costFilter,
              options: [
                for (final filter in MargemProdutoCostFilter.values)
                  AppDropdownOption(
                    value: filter,
                    label: salesMargemProdutoCostFilterLabel(l10n, filter),
                  ),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _costFilter = value);
              },
            ),
            if (selectedAgentMissingToken) ...<Widget>[
              SizedBox(height: tokens.gapMd),
              AppInlineErrorPanel(
                tone: AppInlinePanelTone.informational,
                message: l10n.salesBranchFilterMissingClientTokenBanner,
              ),
            ],
          ],
        );
      },
    );
  }
}
