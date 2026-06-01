import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/features/agent_queries/domain/entities/grupo_produto_option.dart';
import 'package:colmeia/features/agent_queries/domain/entities/marca_produto_option.dart';
import 'package:colmeia/features/agent_queries/domain/entities/produto_vendido_tendencia_de_venda_filter.dart';
import 'package:colmeia/features/agent_queries/presentation/agent_query_failure_support_context.dart';
import 'package:colmeia/features/agent_queries/presentation/widgets/agent_query_load_error_surface.dart';
import 'package:colmeia/features/sales/presentation/utils/sales_trend_date_preset.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_filters_sheet_scaffold.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_single_agent_picker_control.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/filters/dashboard_filter.dart';
import 'package:colmeia/shared/widgets/app_inline_error_panel.dart';
import 'package:colmeia/shared/widgets/app_section_card.dart';
import 'package:colmeia/shared/widgets/forms/app_choice_chip.dart';
import 'package:colmeia/shared/widgets/forms/app_date_picker_field.dart';
import 'package:colmeia/shared/widgets/forms/app_dropdown_field.dart';
import 'package:colmeia/shared/widgets/forms/app_text_field.dart';
import 'package:flutter/material.dart';

/// Modal bottom-sheet form that owns the filter state for the produto
/// tendência screen: branch picker, current/previous period ranges, free
/// text search, classification dropdown, grupo/marca dropdowns, and page
/// size.
///
/// The sheet keeps its own draft state, validates period rules locally
/// (`Periodo anterior deve preceder o atual`, `Periodos devem cobrir
/// janelas equivalentes`), and only emits `onApply` once the user taps
/// "Aplicar" with valid input — the host page is never re-rendered while
/// the user is still editing filters.
class SalesProdutoTendenciaFiltersSheet extends StatefulWidget {
  const SalesProdutoTendenciaFiltersSheet({
    required this.l10n,
    required this.availableAgents,
    required this.initialSelectedAgentId,
    required this.initialPeriodoAtual,
    required this.initialPeriodoAnterior,
    required this.initialSearchTerm,
    required this.initialClassificacao,
    required this.initialCodGrupoProduto,
    required this.initialCodMarca,
    required this.initialPageSize,
    required this.grupoOptions,
    required this.marcaOptions,
    required this.onApply,
    super.key,
    this.dimensionOptionsLoadFailure,
    this.onRetryDimensionOptions,
    this.dimensionOptionsRetryCountdownLabel,
  });

  final AppLocalizations l10n;
  final List<DashboardAgentOption> availableAgents;
  final String? initialSelectedAgentId;
  final DateTimeRange initialPeriodoAtual;
  final DateTimeRange initialPeriodoAnterior;
  final String initialSearchTerm;
  final String? initialClassificacao;
  final int? initialCodGrupoProduto;
  final int? initialCodMarca;
  final int initialPageSize;
  final List<GrupoProdutoOption> grupoOptions;
  final List<MarcaProdutoOption> marcaOptions;
  final ValueChanged<Map<String, Object?>> onApply;
  final AppFailure? dimensionOptionsLoadFailure;
  final VoidCallback? onRetryDimensionOptions;
  final String? dimensionOptionsRetryCountdownLabel;

  @override
  State<SalesProdutoTendenciaFiltersSheet> createState() =>
      _SalesProdutoTendenciaFiltersSheetState();
}

class _SalesProdutoTendenciaFiltersSheetState
    extends State<SalesProdutoTendenciaFiltersSheet> {
  String? _selectedAgentId;
  DateTimeRange? _periodoAtual;
  DateTimeRange? _periodoAnterior;
  late final TextEditingController _searchController;
  String? _classificacao;
  int? _codGrupoProduto;
  int? _codMarca;
  late int _pageSize;

  SalesTrendDatePreset? get _selectedPreset {
    for (final preset in SalesTrendDatePreset.values) {
      final current = salesTrendCurrentRangeForPreset(preset);
      final previous = salesTrendAutoPreviousRange(current);
      if (salesTrendSameRange(_periodoAtual, current) &&
          salesTrendSameRange(_periodoAnterior, previous)) {
        return preset;
      }
    }
    return null;
  }

  String? get _periodValidationMessage {
    final periodoAtual = _periodoAtual;
    final periodoAnterior = _periodoAnterior;
    if (periodoAtual == null || periodoAnterior == null) {
      return null;
    }

    final error = ProdutoVendidoTendenciaDeVendaFilter(
      periodoAtualInicio: periodoAtual.start,
      periodoAtualFim: periodoAtual.end,
      periodoAnteriorInicio: periodoAnterior.start,
      periodoAnteriorFim: periodoAnterior.end,
      searchTerm: _searchController.text,
      classificacao: _classificacao,
      codGrupoProduto: _codGrupoProduto,
      codMarca: _codMarca,
      pageSize: _pageSize,
    ).validationError();

    return _localizedPeriodValidationMessage(error);
  }

  bool get _canApply {
    final selectedAgentId = _selectedAgentId;
    return selectedAgentId != null &&
        selectedAgentId.trim().isNotEmpty &&
        _periodoAtual != null &&
        _periodoAnterior != null &&
        _periodValidationMessage == null;
  }

  String? _rangeHelperText(DateTimeRange? range) {
    if (range == null) {
      return null;
    }
    return salesTrendRangeDescriptorLabel(widget.l10n, range);
  }

  @override
  void initState() {
    super.initState();
    _selectedAgentId = widget.initialSelectedAgentId;
    _periodoAtual = widget.initialPeriodoAtual;
    _periodoAnterior = widget.initialPeriodoAnterior;
    _searchController = TextEditingController(text: widget.initialSearchTerm);
    _classificacao = widget.initialClassificacao;
    _codGrupoProduto = widget.initialCodGrupoProduto;
    _codMarca = widget.initialCodMarca;
    _pageSize = widget.initialPageSize;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String? _localizedPeriodValidationMessage(String? error) {
    if (error == null) {
      return null;
    }

    final l10n = widget.l10n;
    return switch (error) {
      ProdutoVendidoTendenciaDeVendaFilter
          .errorPeriodoAnteriorMustBeBeforeAtual =>
        l10n.salesProdutoTendenciaFilterPeriodsOrderError,
      ProdutoVendidoTendenciaDeVendaFilter
          .errorPeriodsMustCoverEquivalentWindows =>
        l10n.salesProdutoTendenciaFilterPeriodsEquivalentWindowError,
      _ => null,
    };
  }

  void _apply() {
    if (!_canApply) {
      return;
    }
    final selectedAgentId = _selectedAgentId!;
    widget.onApply(<String, Object?>{
      'agentId': selectedAgentId,
      'periodoAtual': _periodoAtual,
      'periodoAnterior': _periodoAnterior,
      'searchTerm': _searchController.text,
      'classificacao': _classificacao,
      'codGrupoProduto': _codGrupoProduto,
      'codMarca': _codMarca,
      'pageSize': _pageSize,
    });
    Navigator.of(context).pop();
  }

  void _applyPreset(SalesTrendDatePreset preset) {
    final current = salesTrendCurrentRangeForPreset(preset);
    setState(() {
      _periodoAtual = current;
      _periodoAnterior = salesTrendAutoPreviousRange(current);
    });
  }

  void _autoAdjustPreviousPeriod() {
    final periodoAtual = _periodoAtual;
    if (periodoAtual == null) {
      return;
    }
    setState(() {
      _periodoAnterior = salesTrendAutoPreviousRange(periodoAtual);
    });
  }

  void _clear() {
    final now = DateTime.now();
    setState(() {
      _periodoAtual = salesTrendFullMonthInclusiveRange(now);
      _periodoAnterior = salesTrendPreviousMonthInclusiveRange(now);
      _searchController.text = '';
      _classificacao = null;
      _codGrupoProduto = null;
      _codMarca = null;
      _pageSize = ProdutoVendidoTendenciaDeVendaFilter.defaultPageSize;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.appTokens;
    final l10n = widget.l10n;
    final periodValidationMessage = _periodValidationMessage;
    final selectedPreset = _selectedPreset;
    final selectedAgentMissingToken =
        _selectedAgentId != null &&
        widget.availableAgents.any(
          (agent) =>
              agent.agentId == _selectedAgentId &&
              agent.missingLocalClientToken,
        );

    return SalesFiltersSheetScaffold(
      title: l10n.reportFiltersTitleWithContext(
        l10n.salesCardProdutoTendenciaTitle,
      ),
      description: l10n.reportFiltersDescription,
      primaryActionLabel: l10n.reportFiltersApplyAction,
      secondaryActionLabel: l10n.reportFiltersClearAction,
      onPrimaryAction: _apply,
      onSecondaryAction: _clear,
      canPrimaryAction: _canApply,
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
            if (selectedAgentMissingToken) ...<Widget>[
              SizedBox(height: tokens.gapMd),
              AppInlineErrorPanel(
                tone: AppInlinePanelTone.informational,
                message: l10n.salesBranchFilterMissingClientTokenBanner,
              ),
            ],
            if (AgentQueryLoadErrorSurface.hasErrorFor(
              loadFailure: widget.dimensionOptionsLoadFailure,
            )) ...<Widget>[
              SizedBox(height: tokens.gapMd),
              AgentQueryLoadErrorSurface(
                loadFailure: widget.dimensionOptionsLoadFailure,
                onRetry: widget.onRetryDimensionOptions,
                retryCountdownLabel: widget.dimensionOptionsRetryCountdownLabel,
                variant: AppInlineErrorPanelVariant.plain,
                supportContext: AgentQueryFailureSupportContext.environment(
                  extra: <String, String>{
                    'agentId': ?_selectedAgentId,
                    'screen': 'sales_produto_tendencia_filters',
                  },
                ),
              ),
            ],
            SizedBox(height: tokens.sectionSpacing),
            SalesFiltersSectionHeader(
              title: l10n.reportFiltersTitle,
              subtitle: l10n.reportFiltersDescription,
            ),
            SizedBox(height: tokens.gapSm),
            AppSectionCard(
              color: theme.colorScheme.surfaceContainerLow,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Text(
                    l10n.salesProdutoTendenciaFilterQuickPeriodsTitle,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: tokens.gapXs),
                  Text(
                    l10n.salesProdutoTendenciaFilterQuickPeriodsSubtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  SizedBox(height: tokens.gapMd),
                  Wrap(
                    spacing: tokens.gapSm,
                    runSpacing: tokens.gapSm,
                    children: <Widget>[
                      AppChoiceChip(
                        label:
                            l10n.salesProdutoTendenciaFilterPresetCurrentMonth,
                        selected:
                            selectedPreset == SalesTrendDatePreset.currentMonth,
                        icon: Icons.calendar_view_month_rounded,
                        onSelected: () => _applyPreset(
                          SalesTrendDatePreset.currentMonth,
                        ),
                      ),
                      AppChoiceChip(
                        label:
                            l10n.salesProdutoTendenciaFilterPresetPreviousMonth,
                        selected:
                            selectedPreset ==
                            SalesTrendDatePreset.previousMonth,
                        icon: Icons.history_rounded,
                        onSelected: () => _applyPreset(
                          SalesTrendDatePreset.previousMonth,
                        ),
                      ),
                      AppChoiceChip(
                        label: l10n.salesProdutoTendenciaFilterPresetLast7Days,
                        selected:
                            selectedPreset == SalesTrendDatePreset.last7Days,
                        icon: Icons.date_range_rounded,
                        onSelected: () =>
                            _applyPreset(SalesTrendDatePreset.last7Days),
                      ),
                      AppChoiceChip(
                        label: l10n.salesProdutoTendenciaFilterPresetLast30Days,
                        selected:
                            selectedPreset == SalesTrendDatePreset.last30Days,
                        icon: Icons.insights_rounded,
                        onSelected: () =>
                            _applyPreset(SalesTrendDatePreset.last30Days),
                      ),
                    ],
                  ),
                  SizedBox(height: tokens.gapSm),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: _periodoAtual == null
                          ? null
                          : _autoAdjustPreviousPeriod,
                      icon: const Icon(Icons.auto_fix_high_rounded, size: 18),
                      label: Text(
                        l10n.salesProdutoTendenciaFilterAutoAdjustPreviousAction,
                      ),
                    ),
                  ),
                  AppInlineErrorPanel(
                    variant: AppInlineErrorPanelVariant.plain,
                    tone: AppInlinePanelTone.informational,
                    title: l10n.salesProdutoTendenciaFilterRuleHelperTitle,
                    message: l10n.salesProdutoTendenciaFilterRuleHelper,
                  ),
                  SizedBox(height: tokens.contentSpacing),
                  AppDateRangePickerField(
                    label: l10n.salesProdutoTendenciaFilterCurrentPeriod,
                    pickerTitle: l10n.salesProdutoTendenciaFilterCurrentPeriod,
                    value: _periodoAtual,
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now(),
                    density: AppTextFieldDensity.compact,
                    helperText: _rangeHelperText(_periodoAtual),
                    errorText: periodValidationMessage,
                    onChanged: (value) {
                      setState(() {
                        _periodoAtual = value;
                        _periodoAnterior = value == null
                            ? null
                            : salesTrendAutoPreviousRange(value);
                      });
                    },
                  ),
                  SizedBox(height: tokens.contentSpacing),
                  AppDateRangePickerField(
                    label: l10n.salesProdutoTendenciaFilterPreviousPeriod,
                    pickerTitle: l10n.salesProdutoTendenciaFilterPreviousPeriod,
                    value: _periodoAnterior,
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now(),
                    density: AppTextFieldDensity.compact,
                    helperText: _rangeHelperText(_periodoAnterior),
                    errorText: periodValidationMessage,
                    onChanged: (value) {
                      setState(() => _periodoAnterior = value);
                    },
                  ),
                  SizedBox(height: tokens.contentSpacing),
                  AppTextField(
                    controller: _searchController,
                    label: l10n.salesProdutoTendenciaFilterSearch,
                    hintText: l10n.salesProdutoTendenciaFilterSearchHint,
                    density: AppTextFieldDensity.compact,
                  ),
                  SizedBox(height: tokens.contentSpacing),
                  AppDropdownField<String?>(
                    label: l10n.salesProdutoTendenciaFilterClassification,
                    value: _classificacao,
                    density: AppTextFieldDensity.compact,
                    options: <AppDropdownOption<String?>>[
                      AppDropdownOption<String?>(
                        value: null,
                        label: l10n.salesProdutoTendenciaFilterAllOption,
                      ),
                      AppDropdownOption<String?>(
                        value: 'CRESCENDO',
                        label: l10n.salesProdutoTendenciaClassificacaoGrowing,
                      ),
                      AppDropdownOption<String?>(
                        value: 'CAINDO',
                        label: l10n.salesProdutoTendenciaClassificacaoFalling,
                      ),
                      AppDropdownOption<String?>(
                        value: 'NOVO PRODUTO',
                        label: l10n.salesProdutoTendenciaClassificacaoNew,
                      ),
                      AppDropdownOption<String?>(
                        value: 'PAROU DE VENDER',
                        label: l10n.salesProdutoTendenciaClassificacaoStopped,
                      ),
                      AppDropdownOption<String?>(
                        value: 'ESTAVEL',
                        label: l10n.salesProdutoTendenciaClassificacaoStable,
                      ),
                    ],
                    onChanged: (value) {
                      setState(() => _classificacao = value);
                    },
                  ),
                  SizedBox(height: tokens.contentSpacing),
                  AppDropdownField<int?>(
                    label: l10n.salesProdutoTendenciaFilterGroup,
                    value: _codGrupoProduto,
                    density: AppTextFieldDensity.compact,
                    options: <AppDropdownOption<int?>>[
                      AppDropdownOption<int?>(
                        value: null,
                        label: l10n.salesProdutoTendenciaFilterAllOption,
                      ),
                      ...widget.grupoOptions.map(
                        (option) => AppDropdownOption<int?>(
                          value: option.codGrupoProduto,
                          label: option.nomeGrupoProduto,
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() => _codGrupoProduto = value);
                    },
                  ),
                  SizedBox(height: tokens.contentSpacing),
                  AppDropdownField<int?>(
                    label: l10n.salesProdutoTendenciaFilterBrand,
                    value: _codMarca,
                    density: AppTextFieldDensity.compact,
                    options: <AppDropdownOption<int?>>[
                      AppDropdownOption<int?>(
                        value: null,
                        label: l10n.salesProdutoTendenciaFilterAllOption,
                      ),
                      ...widget.marcaOptions.map(
                        (option) => AppDropdownOption<int?>(
                          value: option.codMarca,
                          label: option.nomeMarca,
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() => _codMarca = value);
                    },
                  ),
                  SizedBox(height: tokens.contentSpacing),
                  AppDropdownField<int>(
                    label: l10n.salesProdutoTendenciaFilterPageSize,
                    value: _pageSize,
                    density: AppTextFieldDensity.compact,
                    options: const <AppDropdownOption<int>>[
                      AppDropdownOption<int>(value: 10, label: '10'),
                      AppDropdownOption<int>(value: 20, label: '20'),
                      AppDropdownOption<int>(value: 50, label: '50'),
                      AppDropdownOption<int>(value: 100, label: '100'),
                    ],
                    onChanged: (value) {
                      if (value == null) {
                        return;
                      }
                      setState(() => _pageSize = value);
                    },
                  ),
                  if (periodValidationMessage != null) ...<Widget>[
                    SizedBox(height: tokens.contentSpacing),
                    AppInlineErrorPanel(
                      variant: AppInlineErrorPanelVariant.plain,
                      title: l10n.salesProdutoTendenciaFilterApplyDisabledTitle,
                      message: periodValidationMessage,
                      belowMessage: Text(
                        l10n.salesProdutoTendenciaFilterApplyDisabledHint,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      actions: Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: _periodoAtual == null
                              ? null
                              : _autoAdjustPreviousPeriod,
                          icon: const Icon(
                            Icons.auto_fix_high_rounded,
                            size: 18,
                          ),
                          label: Text(
                            l10n.salesProdutoTendenciaFilterAutoAdjustPreviousAction,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
