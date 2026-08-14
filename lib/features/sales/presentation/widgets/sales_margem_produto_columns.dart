import 'package:colmeia/core/formatters/app_br_formatters.dart';
import 'package:colmeia/features/agent_queries/domain/entities/margem_produto_row.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_margem_produto_sort.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/widgets/reports/app_report_column.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SalesMargemProdutoColumnLabels {
  const SalesMargemProdutoColumnLabels({
    required this.produto,
    required this.custo,
    required this.preco,
    required this.markup,
    required this.margem,
  });

  factory SalesMargemProdutoColumnLabels.fromL10n(AppLocalizations l10n) {
    return SalesMargemProdutoColumnLabels(
      produto: l10n.salesMargemProdutoColumnProduto,
      custo: l10n.salesMargemProdutoColumnCusto,
      preco: l10n.salesMargemProdutoColumnPreco,
      markup: l10n.salesMargemProdutoColumnMarkup,
      margem: l10n.salesMargemProdutoColumnMargem,
    );
  }

  final String produto;
  final String custo;
  final String preco;
  final String markup;
  final String margem;
}

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
      key: SalesMargemProdutoSort.columnProduto,
      label: labels.produto,
      valueGetter: (row) => row.nomeProduto,
      sortable: false,
      minWidth: 220,
    ),
    AppReportColumn<MargemProdutoRow>(
      key: SalesMargemProdutoSort.columnCustoReposicao,
      label: labels.custo,
      valueGetter: (row) => row.custoReposicao,
      formatter: formatSalesMargemProdutoCurrency,
      numeric: true,
      sortable: false,
      minWidth: 128,
    ),
    AppReportColumn<MargemProdutoRow>(
      key: SalesMargemProdutoSort.columnPrecoVenda,
      label: labels.preco,
      valueGetter: (row) => row.precoVendaProduto,
      formatter: formatSalesMargemProdutoCurrency,
      numeric: true,
      sortable: false,
      minWidth: 128,
    ),
    AppReportColumn<MargemProdutoRow>(
      key: SalesMargemProdutoSort.columnMarkup,
      label: labels.markup,
      valueGetter: (row) => row.percentualMarkupCustoCompraProduto,
      formatter: formatSalesMargemProdutoPercent,
      numeric: true,
      sortable: false,
      minWidth: 112,
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
      sortable: false,
      minWidth: 128,
      valueColor: (context, value) => salesMargemProdutoSignedPercentColor(
        Theme.of(context).colorScheme,
        value,
      ),
    ),
  ];
}
