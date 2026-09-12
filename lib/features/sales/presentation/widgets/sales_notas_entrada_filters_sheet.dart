import 'package:colmeia/features/sales/presentation/widgets/sales_filters_sheet_scaffold.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_single_agent_picker_control.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/filters/dashboard_filter.dart';
import 'package:colmeia/shared/widgets/app_inline_error_panel.dart';
import 'package:colmeia/shared/widgets/forms/app_date_picker_field.dart';
import 'package:flutter/material.dart';

class SalesNotasEntradaFiltersSheet extends StatefulWidget {
  const SalesNotasEntradaFiltersSheet({
    required this.l10n,
    required this.availableAgents,
    required this.initialSelectedAgentId,
    required this.initialDataLancamentoInicio,
    required this.initialDataLancamentoFim,
    required this.onApply,
    super.key,
  });

  final AppLocalizations l10n;
  final List<DashboardAgentOption> availableAgents;
  final String? initialSelectedAgentId;
  final DateTime initialDataLancamentoInicio;
  final DateTime initialDataLancamentoFim;
  final void Function({
    required String? selectedAgentId,
    required DateTime dataLancamentoInicio,
    required DateTime dataLancamentoFim,
  })
  onApply;

  @override
  State<SalesNotasEntradaFiltersSheet> createState() =>
      _SalesNotasEntradaFiltersSheetState();
}

class _SalesNotasEntradaFiltersSheetState
    extends State<SalesNotasEntradaFiltersSheet> {
  String? _selectedAgentId;
  late DateTimeRange _dataLancamentoRange;

  @override
  void initState() {
    super.initState();
    _selectedAgentId = widget.initialSelectedAgentId;
    _dataLancamentoRange = _initialRange();
  }

  DateTimeRange _initialRange() => DateTimeRange(
    start: widget.initialDataLancamentoInicio,
    end: widget.initialDataLancamentoFim,
  );

  DateTimeRange _defaultRange() {
    final today = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );
    return DateTimeRange(
      start: DateTime(today.year, today.month),
      end: today,
    );
  }

  void _apply() {
    final selectedAgentId = _selectedAgentId;
    if (selectedAgentId == null || selectedAgentId.trim().isEmpty) {
      return;
    }
    widget.onApply(
      selectedAgentId: selectedAgentId,
      dataLancamentoInicio: _dataLancamentoRange.start,
      dataLancamentoFim: _dataLancamentoRange.end,
    );
    Navigator.of(context).pop();
  }

  void _clear() {
    setState(() {
      _dataLancamentoRange = _defaultRange();
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
        l10n.salesCardNotasEntradaTitle,
      ),
      description: l10n.salesNotasEntradaFiltersDescription,
      primaryActionLabel: l10n.reportFiltersApplyAction,
      secondaryActionLabel: l10n.reportFiltersClearAction,
      onPrimaryAction: _apply,
      onSecondaryAction: _clear,
      canPrimaryAction: _selectedAgentId != null,
      bodyBuilder: (scrollController) => ListView(
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
          if (selectedAgentMissingToken) ...<Widget>[
            SizedBox(height: tokens.gapMd),
            AppInlineErrorPanel(
              tone: AppInlinePanelTone.informational,
              message: l10n.salesBranchFilterMissingClientTokenBanner,
            ),
          ],
          SizedBox(height: tokens.sectionSpacing),
          SalesFiltersSectionHeader(
            title: l10n.salesNotasEntradaLaunchPeriodLabel,
          ),
          SizedBox(height: tokens.gapSm),
          AppDateRangePickerField(
            label: l10n.salesNotasEntradaLaunchDateLabel,
            pickerTitle: l10n.salesNotasEntradaLaunchDatePickerTitle,
            value: _dataLancamentoRange,
            onChanged: (value) {
              if (value != null) {
                setState(() => _dataLancamentoRange = value);
              }
            },
          ),
        ],
      ),
    );
  }
}
