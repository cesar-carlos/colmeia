import 'package:colmeia/core/formatters/app_br_formatters.dart';
import 'package:colmeia/core/layout/app_breakpoints.dart';
import 'package:colmeia/features/agent_queries/domain/entities/margem_produto_row.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_margem_produto_sort.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/widgets/reports/app_report_column.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SalesMargemProdutoColumnLabels {
  const SalesMargemProdutoColumnLabels({
    required this.codigo,
    required this.produto,
    required this.grupo,
    required this.marca,
    required this.custo,
    required this.preco,
    required this.markup,
    required this.margem,
  });

  factory SalesMargemProdutoColumnLabels.fromL10n(AppLocalizations l10n) {
    return SalesMargemProdutoColumnLabels(
      codigo: l10n.salesMargemProdutoColumnCodigo,
      produto: l10n.salesMargemProdutoColumnProduto,
      grupo: l10n.salesMargemProdutoColumnGrupo,
      marca: l10n.salesMargemProdutoColumnMarca,
      custo: l10n.salesMargemProdutoColumnCusto,
      preco: l10n.salesMargemProdutoColumnPreco,
      markup: l10n.salesMargemProdutoColumnMarkup,
      margem: l10n.salesMargemProdutoColumnMargem,
    );
  }

  final String codigo;
  final String produto;
  final String grupo;
  final String marca;
  final String custo;
  final String preco;
  final String markup;
  final String margem;
}

/// Compact ID column: out of fill mode so leftover width goes to the name.
const double _codigoColumnWidth = 80;

/// Product name is the only fill column; keep a readable floor on small screens.
const double _produtoColumnMinWidth = 260;

const double _textColumnWidth = 140;
const double _currencyColumnWidth = 128;
const double _percentColumnWidth = 104;

final NumberFormat _percentFormat = NumberFormat('#,##0.0', 'pt_BR');

String formatSalesMargemProdutoCurrency(Object? value) {
  if (value is! num) {
    return '';
  }
  return AppBrFormatters.currencyFormat.format(value);
}

String formatSalesMargemProdutoPercent(Object? value) {
  if (value is! num) {
    return '';
  }
  return '${_percentFormat.format(value)}%';
}

Color? salesMargemProdutoSignedPercentColor(
  ColorScheme scheme,
  Object? value,
) {
  if (value is! num) {
    return null;
  }
  return value >= 0 ? scheme.tertiary : scheme.error;
}

List<AppReportColumn<MargemProdutoRow>> buildSalesMargemProdutoColumns({
  required SalesMargemProdutoColumnLabels labels,
}) {
  return <AppReportColumn<MargemProdutoRow>>[
    AppReportColumn<MargemProdutoRow>(
      key: SalesMargemProdutoSort.columnCodigo,
      label: labels.codigo,
      valueGetter: (row) => row.codProduto,
      numeric: true,
      pinned: true,
      width: _codigoColumnWidth,
    ),
    AppReportColumn<MargemProdutoRow>(
      key: SalesMargemProdutoSort.columnProduto,
      label: labels.produto,
      valueGetter: (row) => row.nomeProduto,
      minWidth: _produtoColumnMinWidth,
    ),
    AppReportColumn<MargemProdutoRow>(
      key: SalesMargemProdutoSort.columnGrupo,
      label: labels.grupo,
      valueGetter: (row) => row.nomeGrupoProduto,
      width: _textColumnWidth,
      minWidth: _textColumnWidth,
      hideBelowBreakpoint: AppBreakpoints.reportColumnHideMedium,
    ),
    AppReportColumn<MargemProdutoRow>(
      key: SalesMargemProdutoSort.columnMarca,
      label: labels.marca,
      valueGetter: (row) => row.nomeMarca,
      width: _textColumnWidth,
      minWidth: _textColumnWidth,
      hideBelowBreakpoint: AppBreakpoints.reportColumnHideMedium,
    ),
    AppReportColumn<MargemProdutoRow>(
      key: SalesMargemProdutoSort.columnCustoReposicao,
      label: labels.custo,
      valueGetter: (row) => row.custoReposicao,
      formatter: formatSalesMargemProdutoCurrency,
      numeric: true,
      width: _currencyColumnWidth,
      minWidth: _currencyColumnWidth,
    ),
    AppReportColumn<MargemProdutoRow>(
      key: SalesMargemProdutoSort.columnPrecoVenda,
      label: labels.preco,
      valueGetter: (row) => row.precoVendaProduto,
      formatter: formatSalesMargemProdutoCurrency,
      numeric: true,
      width: _currencyColumnWidth,
      minWidth: _currencyColumnWidth,
    ),
    AppReportColumn<MargemProdutoRow>(
      key: SalesMargemProdutoSort.columnMarkup,
      label: labels.markup,
      valueGetter: (row) => row.percentualMarkupCustoCompraProduto,
      formatter: formatSalesMargemProdutoPercent,
      numeric: true,
      width: _percentColumnWidth,
      minWidth: _percentColumnWidth,
      valueColor: (context, value) => salesMargemProdutoSignedPercentColor(
        Theme.of(context).colorScheme,
        value,
      ),
    ),
    AppReportColumn<MargemProdutoRow>(
      key: SalesMargemProdutoSort.columnMargem,
      label: labels.margem,
      valueGetter: (row) => row.margemLucroProduto,
      formatter: formatSalesMargemProdutoPercent,
      numeric: true,
      width: _percentColumnWidth,
      minWidth: _percentColumnWidth,
      valueColor: (context, value) => salesMargemProdutoSignedPercentColor(
        Theme.of(context).colorScheme,
        value,
      ),
    ),
  ];
}
