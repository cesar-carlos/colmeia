import 'dart:math' as math;

import 'package:colmeia/features/agent_queries/domain/entities/nota_entrada_row.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_notas_entrada_columns.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_notas_entrada_search_field.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_data_grid_density.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/app_compact_data_grid_scroll_table.dart';
import 'package:colmeia/shared/widgets/app_inline_error_panel.dart';
import 'package:colmeia/shared/widgets/app_section_card.dart';
import 'package:colmeia/shared/widgets/app_skeleton.dart';
import 'package:flutter/material.dart';

class SalesNotasEntradaTable extends StatelessWidget {
  const SalesNotasEntradaTable({
    required this.l10n,
    required this.rows,
    required this.isLoading,
    required this.paginationFooter,
    required this.searchTerm,
    required this.onSearchChanged,
    super.key,
    this.headerTrailing,
    this.loadErrorPanel,
  });

  final AppLocalizations l10n;
  final List<NotaEntradaRow> rows;
  final bool isLoading;
  final Widget paginationFooter;
  final String? searchTerm;
  final ValueChanged<String> onSearchChanged;
  final Widget? headerTrailing;
  final Widget? loadErrorPanel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.appTokens;
    final labels = SalesNotasEntradaColumnLabels.fromL10n(l10n);
    final hasSearch = (searchTerm ?? '').trim().isNotEmpty;

    return AppSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _TableToolbar(
            searchTerm: searchTerm,
            searchHint: l10n.salesNotasEntradaSearchHint,
            onSearchChanged: onSearchChanged,
            headerTrailing: headerTrailing,
          ),
          SizedBox(height: tokens.contentSpacing),
          if (loadErrorPanel != null) ...<Widget>[
            loadErrorPanel!,
            SizedBox(height: tokens.sectionSpacing),
          ],
          if (isLoading && rows.isEmpty)
            AppSkeleton(
              enabled: true,
              loadingSemanticsLabel: l10n.reportLoadingTableSemantics,
              child: appDataGridSkeletonColumn(
                tokens: tokens,
                dividerColor: theme.colorScheme.outlineVariant.withValues(
                  alpha: 0.35,
                ),
              ),
            )
          else if (rows.isEmpty && loadErrorPanel == null)
            AppInlineErrorPanel(
              variant: AppInlineErrorPanelVariant.plain,
              tone: AppInlinePanelTone.informational,
              message: hasSearch
                  ? l10n.salesNotasEntradaEmptySearch
                  : l10n.salesNotasEntradaEmpty,
            )
          else ...<Widget>[
            AppSkeleton(
              enabled: isLoading,
              loadingSemanticsLabel: l10n.reportLoadingTableSemantics,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final minTable =
                      SalesNotasEntradaTableLayout.minScrollContentWidth(
                        tokens,
                      );
                  final outer = constraints.maxWidth;
                  final hasHorizontalOverflow =
                      outer.isFinite && outer > 0 && minTable > outer;
                  final contentWidth = outer.isFinite && outer > 0
                      ? math.max(outer, minTable)
                      : minTable;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      if (hasHorizontalOverflow) ...<Widget>[
                        Text(
                          l10n.salesNotasEntradaHorizontalScrollCaption,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        SizedBox(height: tokens.gapXs),
                      ],
                      AppCompactDataGridScrollTable(
                        contentWidth: contentWidth,
                        itemCount: rows.length,
                        semanticsHint: hasHorizontalOverflow
                            ? l10n.salesNotasEntradaHorizontalScrollCaption
                            : null,
                        showHorizontalFade: hasHorizontalOverflow,
                        header: SalesNotasEntradaTableHeader(labels: labels),
                        itemBuilder: (context, index) {
                          return SalesNotasEntradaTableRow(row: rows[index]);
                        },
                      ),
                    ],
                  );
                },
              ),
            ),
            SizedBox(height: tokens.contentSpacing),
            paginationFooter,
          ],
        ],
      ),
    );
  }
}

class _TableToolbar extends StatelessWidget {
  const _TableToolbar({
    required this.searchTerm,
    required this.searchHint,
    required this.onSearchChanged,
    this.headerTrailing,
  });

  final String? searchTerm;
  final String searchHint;
  final ValueChanged<String> onSearchChanged;
  final Widget? headerTrailing;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).appTokens;
    final searchField = SalesNotasEntradaSearchField(
      searchTerm: searchTerm,
      hintText: searchHint,
      onSearchChanged: onSearchChanged,
    );
    final trailing = headerTrailing;
    if (trailing == null) {
      return searchField;
    }
    return Row(
      children: <Widget>[
        Expanded(child: searchField),
        SizedBox(width: tokens.gapSm),
        trailing,
      ],
    );
  }
}

class SalesNotasEntradaTableHeader extends StatelessWidget {
  const SalesNotasEntradaTableHeader({required this.labels, super.key});

  final SalesNotasEntradaColumnLabels labels;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.appTokens;
    final labelStyle = appDataGridHeaderLabelStyle(theme: theme);
    final endLabelStyle = appDataGridHeaderLabelStyle(
      theme: theme,
      textAlign: TextAlign.end,
    );

    return DecoratedBox(
      decoration: appDataGridHeaderDecoration(theme.colorScheme),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minHeight: kAppCompactHeaderRowHeight,
        ),
        child: Padding(
          padding: appDataGridRowPadding(tokens),
          child: Row(
            children: <Widget>[
              _FixedCell(
                width: SalesNotasEntradaTableLayout.documentoWidth,
                child: Text(labels.documento, style: labelStyle),
              ),
              _FixedCell(
                width: SalesNotasEntradaTableLayout.dateWidth,
                child: Text(labels.emissao, style: labelStyle),
              ),
              _FixedCell(
                width: SalesNotasEntradaTableLayout.dateWidth,
                child: Text(labels.entrada, style: labelStyle),
              ),
              _FixedCell(
                width: SalesNotasEntradaTableLayout.lancamentoWidth,
                child: Text(labels.lancamento, style: labelStyle),
              ),
              _FixedCell(
                width: SalesNotasEntradaTableLayout.codFornecedorWidth,
                child: Text(labels.codFornecedor, style: labelStyle),
              ),
              Expanded(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    minWidth: SalesNotasEntradaTableLayout.fornecedorMinWidth,
                  ),
                  child: Text(labels.fornecedor, style: labelStyle),
                ),
              ),
              _FixedCell(
                width: SalesNotasEntradaTableLayout.cnpjWidth,
                child: Text(labels.cnpjCpf, style: labelStyle),
              ),
              _FixedCell(
                width: SalesNotasEntradaTableLayout.valorWidth,
                child: Text(
                  labels.valorTotal,
                  style: endLabelStyle,
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SalesNotasEntradaTableRow extends StatelessWidget {
  const SalesNotasEntradaTableRow({required this.row, super.key});

  final NotaEntradaRow row;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.appTokens;
    const tabularFigures = <FontFeature>[FontFeature.tabularFigures()];
    final bodyStyle = theme.textTheme.bodyMedium;
    final tabularStyle = bodyStyle?.copyWith(fontFeatures: tabularFigures);
    final mutedTabularStyle = theme.textTheme.bodySmall?.copyWith(
      fontFeatures: tabularFigures,
      color: theme.colorScheme.onSurfaceVariant,
    );

    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: kAppCompactDataRowHeight),
      child: Padding(
        padding: appDataGridRowPadding(tokens),
        child: Row(
          children: <Widget>[
            _FixedCell(
              width: SalesNotasEntradaTableLayout.documentoWidth,
              child: Text(
                row.numeroDocumento,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: tabularStyle,
              ),
            ),
            _FixedCell(
              width: SalesNotasEntradaTableLayout.dateWidth,
              child: Text(
                formatSalesNotasEntradaDate(row.dataEmissao),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: mutedTabularStyle,
              ),
            ),
            _FixedCell(
              width: SalesNotasEntradaTableLayout.dateWidth,
              child: Text(
                formatSalesNotasEntradaDate(row.dataEntrada),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: mutedTabularStyle,
              ),
            ),
            _FixedCell(
              width: SalesNotasEntradaTableLayout.lancamentoWidth,
              child: Text(
                formatSalesNotasEntradaLaunchDate(row.dataLancamento),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: mutedTabularStyle,
              ),
            ),
            _FixedCell(
              width: SalesNotasEntradaTableLayout.codFornecedorWidth,
              child: Text(
                '${row.codFornecedor}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: tabularStyle,
              ),
            ),
            Expanded(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  minWidth: SalesNotasEntradaTableLayout.fornecedorMinWidth,
                ),
                child: Text(
                  row.nomeFornecedor,
                  softWrap: true,
                  maxLines: 3,
                ),
              ),
            ),
            _FixedCell(
              width: SalesNotasEntradaTableLayout.cnpjWidth,
              child: Text(
                formatSalesNotasEntradaTaxId(row.cnpjCpfFornecedor),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: tabularStyle,
              ),
            ),
            _FixedCell(
              width: SalesNotasEntradaTableLayout.valorWidth,
              child: Text(
                formatSalesNotasEntradaCurrency(row.valorTotalCompra),
                textAlign: TextAlign.end,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: tabularStyle?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FixedCell extends StatelessWidget {
  const _FixedCell({required this.width, required this.child});

  final double width;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(width: width, child: child);
  }
}
