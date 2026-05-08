import 'package:colmeia/features/overview/domain/entities/overview_filter.dart';
import 'package:colmeia/features/sales/presentation/utils/sales_anchor_month_support.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_anchor_month_filters_context.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_filters_sheet_scaffold.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_single_agent_picker_control.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/app_inline_error_panel.dart';
import 'package:colmeia/shared/widgets/app_section_card.dart';
import 'package:colmeia/shared/widgets/forms/app_dropdown_field.dart';
import 'package:colmeia/shared/widgets/forms/app_text_field.dart';
import 'package:flutter/material.dart';

/// Branch + reference month filters shared by sales charts anchored to a month.
class SalesBranchAnchorMonthFiltersSheet extends StatefulWidget {
  const SalesBranchAnchorMonthFiltersSheet({
    required this.l10n,
    required this.filtersContext,
    required this.availableAgents,
    required this.initialSelectedAgentId,
    required this.initialAnchorYearMonth,
    required this.onApply,
    super.key,
  });

  final AppLocalizations l10n;
  final SalesAnchorMonthFiltersContext filtersContext;
  final List<OverviewAgentOption> availableAgents;
  final String? initialSelectedAgentId;
  final OverviewYearMonth initialAnchorYearMonth;
  final ValueChanged<Map<String, Object?>> onApply;

  @override
  State<SalesBranchAnchorMonthFiltersSheet> createState() =>
      _SalesBranchAnchorMonthFiltersSheetState();
}

class _SalesBranchAnchorMonthFiltersSheetState
    extends State<SalesBranchAnchorMonthFiltersSheet> {
  String? _selectedAgentId;
  late OverviewYearMonth _anchorYearMonth;

  @override
  void initState() {
    super.initState();
    _selectedAgentId = widget.initialSelectedAgentId;
    _anchorYearMonth = widget.initialAnchorYearMonth;
  }

  void _apply() {
    final selectedAgentId = _selectedAgentId;
    if (selectedAgentId == null || selectedAgentId.trim().isEmpty) {
      return;
    }
    widget.onApply(<String, Object?>{
      'agentId': selectedAgentId,
      'anchorYearMonth': _anchorYearMonth,
    });
    Navigator.of(context).pop();
  }

  void _clear() {
    setState(() {
      _anchorYearMonth = OverviewYearMonth.fromDate(DateTime.now());
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;
    final selectedAgentMissingToken =
        _selectedAgentId != null &&
        widget.availableAgents.any(
          (agent) =>
              agent.agentId == _selectedAgentId &&
              agent.missingLocalClientToken,
        );
    final monthOptions = salesAnchorMonthDropdownOptions(
      context: context,
      l10n: widget.l10n,
      selected: _anchorYearMonth,
    );

    return SalesFiltersSheetScaffold(
      title: widget.l10n.reportFiltersTitleWithContext(
        widget.filtersContext.filtersSheetTitle(widget.l10n),
      ),
      description: widget.l10n.reportFiltersDescription,
      primaryActionLabel: widget.l10n.reportFiltersApplyAction,
      secondaryActionLabel: widget.l10n.reportFiltersClearAction,
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
              title: widget.l10n.salesBranchFilterLabel,
              subtitle: widget.l10n.salesBranchRequiredMessage,
              requiredBadgeLabel: widget.l10n.reportFiltersRequiredCount(1),
            ),
            SizedBox(height: tokens.gapSm),
            SalesBranchPickerControl(
              l10n: widget.l10n,
              availableBranches: widget.availableAgents,
              selectedBranchId: _selectedAgentId,
              showTrailingFilterButton: false,
              onSelectionChanged: (agentId) {
                setState(() => _selectedAgentId = agentId);
              },
            ),
            if (selectedAgentMissingToken) ...<Widget>[
              SizedBox(height: tokens.gapMd),
              AppInlineErrorPanel(
                tone: AppInlinePanelTone.informational,
                message: widget.l10n.salesBranchFilterMissingClientTokenBanner,
              ),
            ],
            SizedBox(height: tokens.sectionSpacing),
            SalesFiltersSectionHeader(
              title: widget.l10n.salesMonthlyPnlFilterAnchorMonth,
            ),
            SizedBox(height: tokens.gapSm),
            AppSectionCard(
              color: theme.colorScheme.surfaceContainerLow,
              child: AppDropdownField<OverviewYearMonth>(
                label: widget.l10n.salesMonthlyPnlFilterAnchorMonth,
                value: _anchorYearMonth,
                density: AppTextFieldDensity.compact,
                options: monthOptions,
                onChanged: (value) {
                  if (value == null) {
                    return;
                  }
                  setState(() => _anchorYearMonth = value);
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
