import 'package:colmeia/features/sales/presentation/widgets/sales_notas_entrada_columns.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_data_grid_density.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/design_system/app_typography_tokens.dart';
import 'package:flutter/material.dart';

class SalesNotasEntradaNotesTotalsFooter extends StatelessWidget {
  const SalesNotasEntradaNotesTotalsFooter({
    required this.totalValorCompra,
    super.key,
  });

  final double totalValorCompra;

  @override
  Widget build(BuildContext context) {
    return _TotalsFooterShell(
      totalValorCompra: totalValorCompra,
      leading: const <Widget>[
        SizedBox(width: SalesNotasEntradaTableLayout.documentoWidth),
        SizedBox(width: SalesNotasEntradaTableLayout.dateWidth),
        SizedBox(width: SalesNotasEntradaTableLayout.dateWidth),
        SizedBox(width: SalesNotasEntradaTableLayout.lancamentoWidth),
        SizedBox(width: SalesNotasEntradaTableLayout.codFornecedorWidth),
      ],
      trailing: const <Widget>[
        SizedBox(width: SalesNotasEntradaTableLayout.cnpjWidth),
      ],
      fornecedorMinWidth: SalesNotasEntradaTableLayout.fornecedorMinWidth,
    );
  }
}

class SalesNotasEntradaResumoTotalsFooter extends StatelessWidget {
  const SalesNotasEntradaResumoTotalsFooter({
    required this.totalValorCompra,
    super.key,
  });

  final double totalValorCompra;

  @override
  Widget build(BuildContext context) {
    return _TotalsFooterShell(
      totalValorCompra: totalValorCompra,
      leading: const <Widget>[
        SizedBox(width: SalesNotasEntradaResumoTableLayout.codFornecedorWidth),
      ],
      trailing: const <Widget>[
        SizedBox(width: SalesNotasEntradaResumoTableLayout.cnpjWidth),
        SizedBox(width: SalesNotasEntradaResumoTableLayout.qtdNotasWidth),
        SizedBox(width: SalesNotasEntradaResumoTableLayout.ticketMedioWidth),
      ],
      fornecedorMinWidth: SalesNotasEntradaResumoTableLayout.fornecedorMinWidth,
    );
  }
}

class _TotalsFooterShell extends StatelessWidget {
  const _TotalsFooterShell({
    required this.totalValorCompra,
    required this.leading,
    required this.trailing,
    required this.fornecedorMinWidth,
  });

  final double totalValorCompra;
  final List<Widget> leading;
  final List<Widget> trailing;
  final double fornecedorMinWidth;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final tokens = theme.appTokens;
    final scheme = theme.colorScheme;
    final typography = theme.appTypography;
    const tabularFigures = <FontFeature>[FontFeature.tabularFigures()];
    final amount = formatSalesNotasEntradaCurrency(totalValorCompra);
    final label = '${l10n.salesNotasEntradaTotalsAmountLabel}:';
    final labelStyle = typography.caption.copyWith(
      color: scheme.onSurfaceVariant,
    );
    final amountStyle = typography.caption.copyWith(
      color: scheme.onSurface,
      fontWeight: FontWeight.w700,
      fontFeatures: tabularFigures,
    );

    return Semantics(
      label: l10n.salesNotasEntradaTotalsSemantics,
      value: amount,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: scheme.outlineVariant.withValues(alpha: 0.9),
            ),
          ),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: kAppCompactDataRowHeight,
          ),
          child: Padding(
            padding: appDataGridRowPadding(tokens),
            child: Row(
              children: <Widget>[
                ...leading,
                Expanded(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minWidth: fornecedorMinWidth),
                    child: Text(
                      label,
                      textAlign: TextAlign.end,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: labelStyle,
                    ),
                  ),
                ),
                ...trailing,
                SizedBox(
                  width: SalesNotasEntradaTableLayout.valorWidth,
                  child: Text(
                    amount,
                    textAlign: TextAlign.end,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: amountStyle,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
