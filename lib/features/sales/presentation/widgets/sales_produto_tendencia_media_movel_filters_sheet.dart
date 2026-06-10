import 'package:colmeia/features/agent_queries/domain/entities/produto_vendido_tendencia_de_venda_media_movel_filter.dart';
import 'package:colmeia/features/sales/presentation/async_search/sales_produto_dimension_async_search_loaders.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_filters_sheet_scaffold.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_produto_tendencia_media_movel_classificacao_labels.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_single_agent_picker_control.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_colors.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/filters/dashboard_filter.dart';
import 'package:colmeia/shared/widgets/app_inline_error_panel.dart';
import 'package:colmeia/shared/widgets/app_section_card.dart';
import 'package:colmeia/shared/widgets/forms/app_async_search_field.dart';
import 'package:colmeia/shared/widgets/forms/app_choice_chip.dart';
import 'package:colmeia/shared/widgets/forms/app_dropdown_field.dart';
import 'package:colmeia/shared/widgets/forms/app_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const List<int> kSalesProdutoTendenciaMediaMovelWindowPresets = <int>[
  7,
  14,
  30,
  60,
];

class SalesProdutoTendenciaMediaMovelFiltersSheet extends StatefulWidget {
  const SalesProdutoTendenciaMediaMovelFiltersSheet({
    required this.l10n,
    required this.availableAgents,
    required this.initialSelectedAgentId,
    required this.initialQuantidadeDias,
    required this.initialSearchTerm,
    required this.initialClassificacao,
    required this.initialCodGrupoProduto,
    required this.initialCodMarca,
    required this.initialGrupoProdutoLabel,
    required this.initialMarcaProdutoLabel,
    required this.initialSortBy,
    required this.initialPageSize,
    required this.grupoProdutoLoaderFactory,
    required this.marcaProdutoLoaderFactory,
    super.key,
  });

  final AppLocalizations l10n;
  final List<DashboardAgentOption> availableAgents;
  final String? initialSelectedAgentId;
  final int initialQuantidadeDias;
  final String initialSearchTerm;
  final String? initialClassificacao;
  final int? initialCodGrupoProduto;
  final int? initialCodMarca;
  final String? initialGrupoProdutoLabel;
  final String? initialMarcaProdutoLabel;
  final ProdutoVendidoTendenciaDeVendaMediaMovelSortBy initialSortBy;
  final int initialPageSize;
  final SalesProdutoDimensionLoaderFactory grupoProdutoLoaderFactory;
  final SalesProdutoDimensionLoaderFactory marcaProdutoLoaderFactory;

  @override
  State<SalesProdutoTendenciaMediaMovelFiltersSheet> createState() =>
      _SalesProdutoTendenciaMediaMovelFiltersSheetState();
}

class _SalesProdutoTendenciaMediaMovelFiltersSheetState
    extends State<SalesProdutoTendenciaMediaMovelFiltersSheet> {
  static const List<int> _pageSizeOptions = <int>[10, 20, 50, 100];

  late final AppAsyncSearchLoader<int> _grupoProdutoLoader;
  late final AppAsyncSearchLoader<int> _marcaProdutoLoader;

  String? _selectedAgentId;
  late final TextEditingController _quantidadeDiasController;
  late final TextEditingController _searchController;
  String? _classificacao;
  int? _codGrupoProduto;
  int? _codMarca;
  String? _grupoProdutoLabel;
  String? _marcaProdutoLabel;
  late ProdutoVendidoTendenciaDeVendaMediaMovelSortBy _sortBy;
  int _pageSize =
      ProdutoVendidoTendenciaDeVendaMediaMovelFilter.defaultPageSize;

  @override
  void initState() {
    super.initState();
    _selectedAgentId = widget.initialSelectedAgentId;
    _grupoProdutoLoader = widget.grupoProdutoLoaderFactory(
      () => _selectedAgentId,
    );
    _marcaProdutoLoader = widget.marcaProdutoLoaderFactory(
      () => _selectedAgentId,
    );
    _quantidadeDiasController = TextEditingController(
      text: '${widget.initialQuantidadeDias}',
    );
    _searchController = TextEditingController(text: widget.initialSearchTerm);
    _classificacao = widget.initialClassificacao;
    _codGrupoProduto = widget.initialCodGrupoProduto;
    _codMarca = widget.initialCodMarca;
    _grupoProdutoLabel = widget.initialGrupoProdutoLabel;
    _marcaProdutoLabel = widget.initialMarcaProdutoLabel;
    _sortBy = widget.initialSortBy;
    _pageSize = widget.initialPageSize;
  }

  @override
  void dispose() {
    _quantidadeDiasController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  int get _quantidadeDias =>
      int.tryParse(_quantidadeDiasController.text.trim()) ?? 0;

  int? get _selectedWindowPreset {
    final days = _quantidadeDias;
    return kSalesProdutoTendenciaMediaMovelWindowPresets.contains(days)
        ? days
        : null;
  }

  String? get _validationMessage {
    final error = ProdutoVendidoTendenciaDeVendaMediaMovelFilter(
      quantidadeDias: _quantidadeDias,
      searchTerm: _searchController.text,
      classificacao: _classificacao,
      codGrupoProduto: _codGrupoProduto,
      codMarca: _codMarca,
      sortBy: _sortBy,
      pageSize: _pageSize,
    ).validationError();

    if (error == null) {
      return null;
    }
    return switch (error) {
      ProdutoVendidoTendenciaDeVendaMediaMovelFilter
          .errorQuantidadeDiasMustBePositive =>
        widget.l10n.salesProdutoTendenciaMediaMovelFilterQuantidadeDiasInvalid,
      _ when error.contains('quantidadeDias must be <=') =>
        widget.l10n.salesProdutoTendenciaMediaMovelFilterQuantidadeDiasTooLarge(
          ProdutoVendidoTendenciaDeVendaMediaMovelFilter.maxQuantidadeDias,
        ),
      _ =>
        widget.l10n.salesProdutoTendenciaMediaMovelFilterQuantidadeDiasInvalid,
    };
  }

  bool get _canApply {
    final selectedAgentId = _selectedAgentId;
    return selectedAgentId != null &&
        selectedAgentId.trim().isNotEmpty &&
        _validationMessage == null;
  }

  void _apply() {
    if (!_canApply) {
      return;
    }
    Navigator.of(context).pop(<String, Object?>{
      'agentId': _selectedAgentId,
      'quantidadeDias': _quantidadeDias,
      'searchTerm': _searchController.text,
      'classificacao': _classificacao,
      'codGrupoProduto': _codGrupoProduto,
      'codMarca': _codMarca,
      'grupoProdutoLabel': _grupoProdutoLabel,
      'marcaProdutoLabel': _marcaProdutoLabel,
      'sortBy': _sortBy.name,
      'pageSize': _pageSize,
    });
  }

  void _clear() {
    setState(() {
      _quantidadeDiasController.text = '7';
      _searchController.text = '';
      _classificacao = null;
      _codGrupoProduto = null;
      _codMarca = null;
      _grupoProdutoLabel = null;
      _marcaProdutoLabel = null;
      _sortBy = ProdutoVendidoTendenciaDeVendaMediaMovelSortBy
          .tendenciaPercentualDesc;
      _pageSize =
          ProdutoVendidoTendenciaDeVendaMediaMovelFilter.defaultPageSize;
    });
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

    return SalesFiltersSheetScaffold(
      title: l10n.reportFiltersTitleWithContext(
        l10n.salesCardProdutoTendenciaMediaMovelTitle,
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
            _SalesProdutoTendenciaMediaMovelFiltersSectionHeader(
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
            _SalesProdutoTendenciaMediaMovelFiltersSectionHeader(
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
                    l10n.salesProdutoTendenciaMediaMovelFilterQuantidadeDiasPresetsTitle,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: tokens.gapXs),
                  Wrap(
                    spacing: tokens.gapSm,
                    runSpacing: tokens.gapSm,
                    children: kSalesProdutoTendenciaMediaMovelWindowPresets
                        .map(
                          (days) => AppChoiceChip(
                            label: l10n
                                .salesProdutoTendenciaMediaMovelFilterQuantidadeDiasValue(
                                  days,
                                ),
                            selected: _selectedWindowPreset == days,
                            onSelected: () {
                              setState(() {
                                _quantidadeDiasController.text = '$days';
                              });
                            },
                          ),
                        )
                        .toList(growable: false),
                  ),
                  SizedBox(height: tokens.contentSpacing),
                  AppTextField(
                    controller: _quantidadeDiasController,
                    keyboardType: TextInputType.number,
                    inputFormatters: <TextInputFormatter>[
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    density: AppTextFieldDensity.compact,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      labelText: l10n
                          .salesProdutoTendenciaMediaMovelFilterQuantidadeDias,
                      hintText: l10n
                          .salesProdutoTendenciaMediaMovelFilterQuantidadeDiasHint,
                      helperText: l10n
                          .salesProdutoTendenciaMediaMovelFilterQuantidadeDiasHelper,
                      errorText: _validationMessage,
                    ),
                  ),
                  SizedBox(height: tokens.contentSpacing),
                  AppTextField(
                    controller: _searchController,
                    label: l10n.salesProdutoTendenciaFilterSearch,
                    hintText:
                        l10n.salesProdutoTendenciaMediaMovelFilterSearchHint,
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
                      ...ProdutoVendidoTendenciaDeVendaMediaMovelFilter
                          .allowedClassificacoes
                          .map(
                            (value) => AppDropdownOption<String?>(
                              value: value,
                              label:
                                  produtoTendenciaMediaMovelClassificacaoLabel(
                                    l10n,
                                    value,
                                  ),
                            ),
                          ),
                    ],
                    onChanged: (value) {
                      setState(() => _classificacao = value);
                    },
                  ),
                  SizedBox(height: tokens.contentSpacing),
                  AppAsyncSearchField<int>(
                    label: l10n.salesProdutoTendenciaFilterGroup,
                    hintText: l10n.salesProdutoTendenciaFilterAllOption,
                    searchHintText: l10n.salesProdutoTendenciaFilterSearchHint,
                    minSearchLengthHint: l10n.appAsyncSearchMinSearchLengthHint(
                      2,
                    ),
                    emptyResultsLabel: l10n.appAsyncSearchEmptyResults,
                    clearOptionLabel: l10n.salesProdutoTendenciaFilterAllOption,
                    value: _codGrupoProduto,
                    selectedDisplayLabel: _grupoProdutoLabel,
                    density: AppTextFieldDensity.compact,
                    enabled: _selectedAgentId != null,
                    loader: _grupoProdutoLoader,
                    onChanged: (value, {label}) {
                      setState(() {
                        _codGrupoProduto = value;
                        _grupoProdutoLabel = value == null ? null : label;
                      });
                    },
                  ),
                  SizedBox(height: tokens.contentSpacing),
                  AppAsyncSearchField<int>(
                    label: l10n.salesProdutoTendenciaFilterBrand,
                    hintText: l10n.salesProdutoTendenciaFilterAllOption,
                    searchHintText: l10n.salesProdutoTendenciaFilterSearchHint,
                    minSearchLengthHint: l10n.appAsyncSearchMinSearchLengthHint(
                      2,
                    ),
                    emptyResultsLabel: l10n.appAsyncSearchEmptyResults,
                    clearOptionLabel: l10n.salesProdutoTendenciaFilterAllOption,
                    value: _codMarca,
                    selectedDisplayLabel: _marcaProdutoLabel,
                    density: AppTextFieldDensity.compact,
                    enabled: _selectedAgentId != null,
                    loader: _marcaProdutoLoader,
                    onChanged: (value, {label}) {
                      setState(() {
                        _codMarca = value;
                        _marcaProdutoLabel = value == null ? null : label;
                      });
                    },
                  ),
                  SizedBox(height: tokens.contentSpacing),
                  AppDropdownField<
                    ProdutoVendidoTendenciaDeVendaMediaMovelSortBy
                  >(
                    label: l10n.salesProdutoTendenciaMediaMovelFilterSortBy,
                    value: _sortBy,
                    density: AppTextFieldDensity.compact,
                    options: ProdutoVendidoTendenciaDeVendaMediaMovelSortBy
                        .values
                        .map(
                          (value) =>
                              AppDropdownOption<
                                ProdutoVendidoTendenciaDeVendaMediaMovelSortBy
                              >(
                                value: value,
                                label: produtoTendenciaMediaMovelSortLabel(
                                  l10n,
                                  value,
                                ),
                              ),
                        )
                        .toList(growable: false),
                    onChanged: (value) {
                      if (value == null) {
                        return;
                      }
                      setState(() => _sortBy = value);
                    },
                  ),
                  SizedBox(height: tokens.contentSpacing),
                  AppDropdownField<int>(
                    label: l10n.salesProdutoTendenciaFilterPageSize,
                    value: _pageSize,
                    density: AppTextFieldDensity.compact,
                    options: _pageSizeOptions
                        .map(
                          (value) => AppDropdownOption<int>(
                            value: value,
                            label: '$value',
                          ),
                        )
                        .toList(growable: false),
                    onChanged: (value) {
                      if (value == null) {
                        return;
                      }
                      setState(() => _pageSize = value);
                    },
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SalesProdutoTendenciaMediaMovelFiltersSectionHeader
    extends StatelessWidget {
  const _SalesProdutoTendenciaMediaMovelFiltersSectionHeader({
    required this.title,
    required this.subtitle,
    this.requiredBadgeLabel,
  });

  final String title;
  final String subtitle;
  final String? requiredBadgeLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.appTokens;
    final colors = theme.appColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (requiredBadgeLabel != null)
              DecoratedBox(
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(tokens.formFieldRadius),
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: tokens.gapSm,
                    vertical: tokens.gapXs,
                  ),
                  child: Text(
                    requiredBadgeLabel!,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
          ],
        ),
        SizedBox(height: tokens.gapXs),
        Text(
          subtitle,
          style: theme.textTheme.bodySmall?.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
