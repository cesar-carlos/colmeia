import 'dart:math' as math;

import 'package:colmeia/features/agent_queries/domain/entities/nota_entrada_resumo_fornecedor_row.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_notas_entrada_columns.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_notas_entrada_totals_footer.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_data_grid_density.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/app_compact_data_grid_scroll_table.dart';
import 'package:flutter/material.dart';

class SalesNotasEntradaResumoGrid extends StatelessWidget {
  const SalesNotasEntradaResumoGrid({
    required this.l10n,
    required this.rows,
    required this.totalValorCompra,
    super.key,
    this.onSupplierSelected,
  });

  final AppLocalizations l10n;
  final List<NotaEntradaResumoFornecedorRow> rows;
  final double totalValorCompra;
  final ValueChanged<NotaEntradaResumoFornecedorRow>? onSupplierSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.appTokens;
    final labels = SalesNotasEntradaColumnLabels.fromL10n(l10n);

    return LayoutBuilder(
      builder: (context, constraints) {
        final minTable =
            SalesNotasEntradaResumoTableLayout.minScrollContentWidth(
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
              header: SalesNotasEntradaResumoTableHeader(labels: labels),
              footer: SalesNotasEntradaResumoTotalsFooter(
                totalValorCompra: totalValorCompra,
              ),
              itemBuilder: (context, index) {
                return SalesNotasEntradaResumoTableRow(
                  row: rows[index],
                  onTap: onSupplierSelected == null
                      ? null
                      : () => onSupplierSelected!(rows[index]),
                );
              },
            ),
          ],
        );
      },
    );
  }
}

class SalesNotasEntradaResumoTableHeader extends StatelessWidget {
  const SalesNotasEntradaResumoTableHeader({required this.labels, super.key});

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
              SizedBox(
                width: SalesNotasEntradaResumoTableLayout.codFornecedorWidth,
                child: Text(labels.codFornecedor, style: labelStyle),
              ),
              Expanded(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    minWidth:
                        SalesNotasEntradaResumoTableLayout.fornecedorMinWidth,
                  ),
                  child: Text(labels.fornecedor, style: labelStyle),
                ),
              ),
              SizedBox(
                width: SalesNotasEntradaResumoTableLayout.cnpjWidth,
                child: Text(labels.cnpjCpf, style: labelStyle),
              ),
              SizedBox(
                width: SalesNotasEntradaResumoTableLayout.qtdNotasWidth,
                child: Text(
                  labels.qtdNotas,
                  style: endLabelStyle,
                  textAlign: TextAlign.end,
                ),
              ),
              SizedBox(
                width: SalesNotasEntradaResumoTableLayout.ticketMedioWidth,
                child: Text(
                  labels.ticketMedio,
                  style: endLabelStyle,
                  textAlign: TextAlign.end,
                ),
              ),
              SizedBox(
                width: SalesNotasEntradaResumoTableLayout.valorWidth,
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

class SalesNotasEntradaResumoTableRow extends StatelessWidget {
  const SalesNotasEntradaResumoTableRow({
    required this.row,
    super.key,
    this.onTap,
  });

  final NotaEntradaResumoFornecedorRow row;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.appTokens;
    const tabularFigures = <FontFeature>[FontFeature.tabularFigures()];
    final bodyStyle = theme.textTheme.bodyMedium;
    final tabularStyle = bodyStyle?.copyWith(fontFeatures: tabularFigures);
    final content = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: kAppCompactDataRowHeight),
      child: Padding(
        padding: appDataGridRowPadding(tokens),
        child: Row(
          children: <Widget>[
            SizedBox(
              width: SalesNotasEntradaResumoTableLayout.codFornecedorWidth,
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
                  minWidth:
                      SalesNotasEntradaResumoTableLayout.fornecedorMinWidth,
                ),
                child: Text(
                  row.nomeFornecedor,
                  softWrap: true,
                  maxLines: 3,
                ),
              ),
            ),
            SizedBox(
              width: SalesNotasEntradaResumoTableLayout.cnpjWidth,
              child: Text(
                formatSalesNotasEntradaTaxId(row.cnpjCpfFornecedor),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: tabularStyle,
              ),
            ),
            SizedBox(
              width: SalesNotasEntradaResumoTableLayout.qtdNotasWidth,
              child: Text(
                '${row.qtdNotas}',
                textAlign: TextAlign.end,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: tabularStyle,
              ),
            ),
            SizedBox(
              width: SalesNotasEntradaResumoTableLayout.ticketMedioWidth,
              child: Text(
                formatSalesNotasEntradaCurrency(row.ticketMedio),
                textAlign: TextAlign.end,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: tabularStyle,
              ),
            ),
            SizedBox(
              width: SalesNotasEntradaResumoTableLayout.valorWidth,
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
    if (onTap == null) {
      return content;
    }

    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onTap,
        child: Semantics(button: true, child: content),
      ),
    );
  }
}
