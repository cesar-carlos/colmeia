import 'dart:math' as math;

import 'package:colmeia/features/agent_queries/domain/entities/nota_entrada_item_row.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_notas_entrada_columns.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_notas_entrada_itens_columns.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_data_grid_density.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/app_compact_data_grid_scroll_table.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SalesNotasEntradaItensGrid extends StatelessWidget {
  const SalesNotasEntradaItensGrid({
    required this.l10n,
    required this.rows,
    super.key,
  });

  final AppLocalizations l10n;
  final List<NotaEntradaItemRow> rows;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.appTokens;
    final labels = SalesNotasEntradaItensColumnLabels.fromL10n(l10n);
    final columns = SalesNotasEntradaItensVisibleColumns.fromRows(rows);
    final quantityFormat = NumberFormat.decimalPattern(l10n.localeName);

    return LayoutBuilder(
      builder: (context, constraints) {
        final minTable =
            SalesNotasEntradaItensTableLayout.minScrollContentWidth(
              tokens,
              columns,
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
              header: _ItemsHeader(labels: labels, columns: columns),
              itemBuilder: (context, index) {
                return _ItemsRow(
                  row: rows[index],
                  columns: columns,
                  quantityFormat: quantityFormat,
                );
              },
            ),
          ],
        );
      },
    );
  }
}

class _ItemsHeader extends StatelessWidget {
  const _ItemsHeader({
    required this.labels,
    required this.columns,
  });

  final SalesNotasEntradaItensColumnLabels labels;
  final SalesNotasEntradaItensVisibleColumns columns;

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
              Expanded(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    minWidth: SalesNotasEntradaItensTableLayout.nomeMinWidth,
                  ),
                  child: Text(
                    labels.nome,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: labelStyle,
                  ),
                ),
              ),
              _FixedCell(
                width: SalesNotasEntradaItensTableLayout.unidadeWidth,
                child: Text(
                  labels.unidade,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: labelStyle,
                ),
              ),
              _QtyCell(label: labels.quantidade, style: endLabelStyle),
              _EndCell(label: labels.valorUnitario, style: endLabelStyle),
              _EndCell(label: labels.valorTotal, style: endLabelStyle),
              if (columns.subtotal)
                _EndCell(label: labels.subtotal, style: endLabelStyle),
              if (columns.descontoItem)
                _EndCell(label: labels.descontoItem, style: endLabelStyle),
              if (columns.descontoTotal)
                _EndCell(label: labels.descontoTotal, style: endLabelStyle),
              if (columns.descontoProporcional)
                _EndCell(
                  label: labels.descontoProporcional,
                  style: endLabelStyle,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ItemsRow extends StatelessWidget {
  const _ItemsRow({
    required this.row,
    required this.columns,
    required this.quantityFormat,
  });

  final NotaEntradaItemRow row;
  final SalesNotasEntradaItensVisibleColumns columns;
  final NumberFormat quantityFormat;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.appTokens;
    const tabularFigures = <FontFeature>[FontFeature.tabularFigures()];
    final bodyStyle = theme.textTheme.bodyMedium;
    final tabularStyle = bodyStyle?.copyWith(fontFeatures: tabularFigures);
    final endStyle = tabularStyle;
    final unidadeCodigo = row.codUnidadeMedida?.trim();
    final unidadeLabel = unidadeCodigo == null || unidadeCodigo.isEmpty
        ? '—'
        : unidadeCodigo;
    final nome = row.nomeProduto.trim();
    final displayName = nome.isEmpty ? '—' : nome;

    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: kAppCompactDataRowHeight),
      child: Padding(
        padding: appDataGridRowPadding(tokens),
        child: Row(
          children: <Widget>[
            Expanded(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  minWidth: SalesNotasEntradaItensTableLayout.nomeMinWidth,
                ),
                child: _ProductCell(
                  code: '${row.codProduto}',
                  name: displayName,
                ),
              ),
            ),
            _FixedCell(
              width: SalesNotasEntradaItensTableLayout.unidadeWidth,
              child: Text(
                unidadeLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            _QtyCellValue(
              text: quantityFormat.format(row.quantidade),
              style: endStyle,
            ),
            _MoneyCell(
              text: formatSalesNotasEntradaCurrency(row.valorUnitario),
              style: endStyle,
            ),
            _MoneyCell(
              text: formatSalesNotasEntradaCurrency(row.valorTotal),
              style: endStyle?.copyWith(fontWeight: FontWeight.w600),
            ),
            if (columns.subtotal)
              _MoneyCell(
                text: formatSalesNotasEntradaCurrency(row.subTotal),
                style: endStyle,
              ),
            if (columns.descontoItem)
              _MoneyCell(
                text: formatSalesNotasEntradaCurrency(row.valorDescontoItem),
                style: endStyle,
              ),
            if (columns.descontoTotal)
              _MoneyCell(
                text: formatSalesNotasEntradaCurrency(row.valorTotalDesconto),
                style: endStyle,
              ),
            if (columns.descontoProporcional)
              _MoneyCell(
                text: formatSalesNotasEntradaCurrency(
                  row.valorDescontoProporcional,
                ),
                style: endStyle,
              ),
          ],
        ),
      ),
    );
  }
}

class _ProductCell extends StatelessWidget {
  const _ProductCell({
    required this.code,
    required this.name,
  });

  final String code;
  final String name;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final codeStyle = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          name,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          code,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: codeStyle,
        ),
      ],
    );
  }
}

class _QtyCell extends StatelessWidget {
  const _QtyCell({required this.label, required this.style});

  final String label;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: SalesNotasEntradaItensTableLayout.quantidadeWidth,
      child: Text(
        label,
        style: style,
        textAlign: TextAlign.end,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class _QtyCellValue extends StatelessWidget {
  const _QtyCellValue({required this.text, required this.style});

  final String text;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: SalesNotasEntradaItensTableLayout.quantidadeWidth,
      child: Text(
        text,
        textAlign: TextAlign.end,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: style,
      ),
    );
  }
}

class _EndCell extends StatelessWidget {
  const _EndCell({required this.label, required this.style});

  final String label;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: SalesNotasEntradaItensTableLayout.moneyWidth,
      child: Text(
        label,
        style: style,
        textAlign: TextAlign.end,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class _MoneyCell extends StatelessWidget {
  const _MoneyCell({required this.text, required this.style});

  final String text;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: SalesNotasEntradaItensTableLayout.moneyWidth,
      child: Text(
        text,
        textAlign: TextAlign.end,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: style,
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
