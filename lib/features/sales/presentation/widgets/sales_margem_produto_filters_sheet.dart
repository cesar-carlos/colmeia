import 'dart:async';

import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/cadastro_filial_row.dart';
import 'package:colmeia/features/agent_queries/domain/ports/agent_queries_cancel_scope.dart';
import 'package:colmeia/features/agent_queries/presentation/localization/agent_query_failure_l10n.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_filters_sheet_scaffold.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_single_agent_picker_control.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/filters/dashboard_filter.dart';
import 'package:colmeia/shared/utils/app_branch_display_model.dart';
import 'package:colmeia/shared/widgets/app_inline_error_panel.dart';
import 'package:colmeia/shared/widgets/app_section_card.dart';
import 'package:colmeia/shared/widgets/forms/app_dropdown_field.dart';
import 'package:colmeia/shared/widgets/forms/app_text_field.dart';
import 'package:flutter/material.dart';

typedef SalesMargemProdutoFiliaisLoader =
    Future<AppResult<List<CadastroFilialRow>>> Function(
      String agentId, {
      AgentQueriesCancelScope? cancelScope,
    });

String salesMargemProdutoFilialKey({
  required int codEmpresa,
  required int codFilial,
}) => '$codEmpresa:$codFilial';

String salesMargemProdutoFilialLabel(CadastroFilialRow row) {
  final display = resolveAppBranchDisplayModel(
    registrationName: row.nomeFilial,
    fantasyName: row.nomeFantasia,
  );
  if (display.primaryName.isNotEmpty) {
    return display.primaryName;
  }
  return '${row.codEmpresa}/${row.codFilial}';
}

CadastroFilialRow? salesMargemProdutoFindFilial({
  required List<CadastroFilialRow> items,
  int? codEmpresa,
  int? codFilial,
}) {
  if (codEmpresa == null || codFilial == null) {
    return null;
  }
  for (final row in items) {
    if (row.codEmpresa == codEmpresa && row.codFilial == codFilial) {
      return row;
    }
  }
  return null;
}

CadastroFilialRow? salesMargemProdutoMatchFilial({
  required List<CadastroFilialRow> items,
  int? codEmpresa,
  int? codFilial,
}) {
  if (items.isEmpty) {
    return null;
  }
  return salesMargemProdutoFindFilial(
        items: items,
        codEmpresa: codEmpresa,
        codFilial: codFilial,
      ) ??
      items.first;
}

class SalesMargemProdutoFiltersSheet extends StatefulWidget {
  const SalesMargemProdutoFiltersSheet({
    required this.l10n,
    required this.availableAgents,
    required this.initialSelectedAgentId,
    required this.initialFiliais,
    required this.initialCodEmpresa,
    required this.initialCodFilial,
    required this.loadFiliais,
    required this.onApply,
    super.key,
  });

  final AppLocalizations l10n;
  final List<DashboardAgentOption> availableAgents;
  final String? initialSelectedAgentId;
  final List<CadastroFilialRow> initialFiliais;
  final int? initialCodEmpresa;
  final int? initialCodFilial;
  final SalesMargemProdutoFiliaisLoader loadFiliais;
  final ValueChanged<Map<String, Object?>> onApply;

  @override
  State<SalesMargemProdutoFiltersSheet> createState() =>
      _SalesMargemProdutoFiltersSheetState();
}

class _SalesMargemProdutoFiltersSheetState
    extends State<SalesMargemProdutoFiltersSheet> {
  String? _selectedAgentId;
  List<CadastroFilialRow> _filiais = const <CadastroFilialRow>[];
  CadastroFilialRow? _selectedFilial;
  bool _filiaisLoading = false;
  AppFailure? _filiaisFailure;
  int _filiaisGeneration = 0;
  AgentQueriesCancelScope? _filiaisCancelScope;

  @override
  void initState() {
    super.initState();
    _selectedAgentId = widget.initialSelectedAgentId;
    _filiais = List<CadastroFilialRow>.from(widget.initialFiliais);
    _selectedFilial = salesMargemProdutoMatchFilial(
      items: _filiais,
      codEmpresa: widget.initialCodEmpresa,
      codFilial: widget.initialCodFilial,
    );
    final agentId = _selectedAgentId?.trim();
    if (agentId != null && agentId.isNotEmpty && _filiais.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        unawaited(_reloadFiliais(agentId));
      });
    }
  }

  @override
  void dispose() {
    _filiaisCancelScope?.cancelAll();
    super.dispose();
  }

  Future<void> _onAgentChanged(String agentId) async {
    setState(() {
      _selectedAgentId = agentId;
      _filiais = const <CadastroFilialRow>[];
      _selectedFilial = null;
      _filiaisFailure = null;
    });
    await _reloadFiliais(agentId);
  }

  Future<void> _reloadFiliais(String agentId) async {
    final generation = ++_filiaisGeneration;
    _filiaisCancelScope?.cancelAll();
    final cancelScope = AgentQueriesCancelScope();
    _filiaisCancelScope = cancelScope;
    setState(() {
      _filiaisLoading = true;
      _filiaisFailure = null;
    });

    final result = await widget.loadFiliais(
      agentId,
      cancelScope: cancelScope,
    );
    if (!mounted || generation != _filiaisGeneration) {
      return;
    }

    result.fold(
      (items) {
        setState(() {
          _filiais = items;
          final preferPersisted = agentId == widget.initialSelectedAgentId;
          _selectedFilial = salesMargemProdutoMatchFilial(
            items: items,
            codEmpresa: preferPersisted ? widget.initialCodEmpresa : null,
            codFilial: preferPersisted ? widget.initialCodFilial : null,
          );
          _filiaisLoading = false;
          _filiaisFailure = null;
        });
      },
      (failure) {
        setState(() {
          _filiais = const <CadastroFilialRow>[];
          _selectedFilial = null;
          _filiaisLoading = false;
          _filiaisFailure = failure;
        });
      },
    );
  }

  void _apply() {
    final selectedAgentId = _selectedAgentId;
    final selectedFilial = _selectedFilial;
    if (selectedAgentId == null || selectedAgentId.trim().isEmpty) {
      return;
    }
    if (selectedFilial == null) {
      return;
    }
    widget.onApply(<String, Object?>{
      'agentId': selectedAgentId,
      'codEmpresa': selectedFilial.codEmpresa,
      'codFilial': selectedFilial.codFilial,
    });
    Navigator.of(context).pop();
  }

  void _clear() {
    setState(() {
      _selectedFilial =
          salesMargemProdutoFindFilial(
            items: _filiais,
            codEmpresa: widget.initialCodEmpresa,
            codFilial: widget.initialCodFilial,
          ) ??
          (_filiais.isEmpty ? null : _filiais.first);
    });
  }

  CadastroFilialRow? _filialForKey(String key) {
    for (final row in _filiais) {
      if (salesMargemProdutoFilialKey(
            codEmpresa: row.codEmpresa,
            codFilial: row.codFilial,
          ) ==
          key) {
        return row;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.appTokens;
    final l10n = widget.l10n;
    final selectedAgentMissingToken =
        _selectedAgentId != null &&
        widget.availableAgents.any(
          (agent) =>
              agent.agentId == _selectedAgentId &&
              agent.missingLocalClientToken,
        );
    final filialKey = _selectedFilial == null
        ? null
        : salesMargemProdutoFilialKey(
            codEmpresa: _selectedFilial!.codEmpresa,
            codFilial: _selectedFilial!.codFilial,
          );
    final showFilialDropdown = _filiais.length > 1;

    return SalesFiltersSheetScaffold(
      title: l10n.reportFiltersTitleWithContext(
        l10n.salesCardMargemProdutoTitle,
      ),
      description: l10n.reportFiltersDescription,
      primaryActionLabel: l10n.reportFiltersApplyAction,
      secondaryActionLabel: l10n.reportFiltersClearAction,
      onPrimaryAction: _apply,
      onSecondaryAction: _clear,
      canPrimaryAction: _selectedFilial != null && !_filiaisLoading,
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
                unawaited(_onAgentChanged(agentId));
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
              title: l10n.salesMargemProdutoFilterFilial,
              subtitle: l10n.salesMargemProdutoIntroSubtitle,
              requiredBadgeLabel: l10n.reportFiltersRequiredCount(1),
            ),
            SizedBox(height: tokens.gapSm),
            if (_filiaisFailure != null)
              AppInlineErrorPanel(
                message: agentQueryFailureUserMessage(_filiaisFailure!, l10n),
                onRetry: _selectedAgentId == null
                    ? null
                    : () => unawaited(_reloadFiliais(_selectedAgentId!)),
              )
            else if (_filiaisLoading)
              const LinearProgressIndicator()
            else if (_filiais.isEmpty)
              AppInlineErrorPanel(
                tone: AppInlinePanelTone.informational,
                message: l10n.salesMargemProdutoNoBranchEmpty,
                onRetry: _selectedAgentId == null
                    ? null
                    : () => unawaited(_reloadFiliais(_selectedAgentId!)),
              )
            else if (showFilialDropdown)
              AppSectionCard(
                color: theme.colorScheme.surfaceContainerLow,
                child: AppDropdownField<String>(
                  label: l10n.salesMargemProdutoFilterFilial,
                  value: filialKey,
                  density: AppTextFieldDensity.compact,
                  emptyLabel: l10n.salesMargemProdutoNoBranchEmpty,
                  options: <AppDropdownOption<String>>[
                    for (final row in _filiais)
                      AppDropdownOption<String>(
                        value: salesMargemProdutoFilialKey(
                          codEmpresa: row.codEmpresa,
                          codFilial: row.codFilial,
                        ),
                        label: salesMargemProdutoFilialLabel(row),
                      ),
                  ],
                  onChanged: (value) {
                    if (value == null) {
                      return;
                    }
                    setState(() {
                      _selectedFilial = _filialForKey(value) ?? _selectedFilial;
                    });
                  },
                ),
              )
            else
              AppSectionCard(
                color: theme.colorScheme.surfaceContainerLow,
                child: Text(
                  salesMargemProdutoFilialLabel(_filiais.first),
                  style: theme.textTheme.bodyLarge,
                ),
              ),
          ],
        );
      },
    );
  }
}
