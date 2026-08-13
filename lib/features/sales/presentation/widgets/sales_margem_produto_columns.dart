import 'package:colmeia/core/formatters/app_br_formatters.dart';
import 'package:colmeia/core/layout/app_breakpoints.dart';
import 'package:colmeia/features/agent_queries/domain/entities/margem_produto_row.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_margem_produto_sort.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/widgets/reports/app_report_column.dart';
import 'package:intl/intl.dart';

class SalesMargemProdutoColumnLabels {
  const SalesMargemProdutoColumnLabels({
    required this.produto,
    required this.custo,
    required this.preco,
    required this.markup,
    required this.margem,
    required this.grupo,
    required this.marca,
  });

  factory SalesMargemProdutoColumnLabels.fromL10n(AppLocalizations l10n) {
    return SalesMargemProdutoColumnLabels(
      produto: l10n.salesMargemProdutoColumnProduto,
      custo: l10n.salesMargemProdutoColumnCusto,
      preco: l10n.salesMargemProdutoColumnPreco,
      markup: l10n.salesMargemProdutoColumnMarkup,
      margem: l10n.salesMargemProdutoColumnMargem,
      grupo: l10n.salesMargemProdutoColumnGrupo,
      marca: l10n.salesMargemProdutoColumnMarca,
    );
  }

  final String produto;
  final String custo;
  final String preco;
  final String markup;
  final String margem;
  final String grupo;
  final String marca;
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

String salesMargemProdutoOptionalText(Object? value) {
  if (value is! String) {
    return '';
  }
  return value.trim();
}

List<AppReportColumn<MargemProdutoRow>> buildSalesMargemProdutoColumns({
  required SalesMargemProdutoColumnLabels labels,
}) {
  return <AppReportColumn<MargemProdutoRow>>[
    AppReportColumn<MargemProdutoRow>(
      key: SalesMargemProdutoSort.columnProduto,
      label: labels.produto,
      valueGetter: (row) => row.nomeProduto,
      pinned: true,
      sortable: false,
      minWidth: 220,
    ),
    AppReportColumn<MargemProdutoRow>(
      key: SalesMargemProdutoSort.columnCustoReposicao,
      label: labels.custo,
      valueGetter: (row) => row.custoReposicao,
      formatter: formatSalesMargemProdutoCurrency,
      numeric: true,
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
      minWidth: 112,
    ),
    AppReportColumn<MargemProdutoRow>(
      key: SalesMargemProdutoSort.columnMargem,
      label: labels.margem,
      valueGetter: (row) => row.margemLucroProduto,
      formatter: formatSalesMargemProdutoPercent,
      numeric: true,
      minWidth: 128,
    ),
    AppReportColumn<MargemProdutoRow>(
      key: SalesMargemProdutoSort.columnGrupo,
      label: labels.grupo,
      valueGetter: (row) => row.nomeGrupoProduto,
      formatter: salesMargemProdutoOptionalText,
      sortable: false,
      minWidth: 140,
      hideBelowBreakpoint: AppBreakpoints.reportColumnHideNarrow,
    ),
    AppReportColumn<MargemProdutoRow>(
      key: SalesMargemProdutoSort.columnMarca,
      label: labels.marca,
      valueGetter: (row) => row.nomeMarca,
      formatter: salesMargemProdutoOptionalText,
      sortable: false,
      minWidth: 140,
      hideBelowBreakpoint: AppBreakpoints.reportColumnHideNarrow,
    ),
  ];
}
