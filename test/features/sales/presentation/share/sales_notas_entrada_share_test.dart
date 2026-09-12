import 'package:colmeia/features/agent_queries/domain/entities/nota_entrada_resumo_fornecedor_row.dart';
import 'package:colmeia/features/agent_queries/domain/entities/nota_entrada_row.dart';
import 'package:colmeia/features/sales/presentation/share/sales_notas_entrada_share.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_notas_entrada_columns.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/widgets/charts/chart_share_pdf_orientation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

NotaEntradaRow _row() {
  return NotaEntradaRow(
    compraId: 80,
    codEmpresa: 1,
    codFilial: 1,
    nomeFilial: 'Lucas Centro',
    codTipoOperacaoCompra: 1,
    descricaoTipoOperacaoCompra: 'Compra',
    numeroDocumento: 'NF-100',
    dataEmissao: DateTime(2026, 9),
    dataEntrada: DateTime(2026, 9, 2),
    dataLancamento: DateTime(2026, 9, 3),
    codFornecedor: 8,
    nomeFornecedor: 'Casa do Mel',
    cnpjCpfFornecedor: '12345678000195',
    valorTotalCompra: 150.5,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppLocalizations l10n;

  setUp(() async {
    await initializeDateFormatting('pt_BR');
    l10n = lookupAppLocalizations(const Locale('pt', 'BR'));
  });

  test('share metadata formats catalog columns in landscape', () {
    final metadata = buildSalesNotasEntradaShareMetadata(
      l10n: l10n,
      rows: <NotaEntradaRow>[_row()],
      totalValorCompra: 1250.5,
      exportHeaderContext: buildSalesNotasEntradaShareExportHeaderContext(
        l10n: l10n,
        agentName: 'Lucas Centro',
        dataLancamentoInicio: DateTime(2026, 9),
        dataLancamentoFim: DateTime(2026, 9, 12),
        searchTerm: 'Mel',
      ),
    );

    expect(metadata.title, l10n.salesCardNotasEntradaTitle);
    expect(metadata.subtitle, l10n.salesNotasEntradaIntroSubtitle);
    expect(metadata.pdfOrientation, ChartSharePdfOrientation.landscape);
    expect(metadata.includeChartImage, isFalse);
    expect(
      metadata.tableData?.headers,
      <String>[
        l10n.salesNotasEntradaColumnDocumento,
        l10n.salesNotasEntradaColumnEmissao,
        l10n.salesNotasEntradaColumnEntrada,
        l10n.salesNotasEntradaColumnLancamento,
        l10n.salesNotasEntradaColumnCodFornecedor,
        l10n.salesNotasEntradaColumnFornecedor,
        l10n.salesNotasEntradaColumnCnpjCpf,
        l10n.salesNotasEntradaColumnValorTotal,
      ],
    );
    expect(metadata.tableData?.rows.single[0], 'NF-100');
    expect(metadata.tableData?.rows.single[5], 'Casa do Mel');
    expect(
      metadata.tableData?.rows.single.last,
      formatSalesNotasEntradaCurrency(150.5),
    );
    expect(metadata.tableData?.footerRows, hasLength(1));
    expect(
      metadata.tableData?.footerRows.single.last,
      formatSalesNotasEntradaCurrency(1250.5),
    );
    expect(
      metadata.tableData?.footerRows.single.first,
      '${l10n.salesNotasEntradaTotalsAmountLabel}:',
    );
    expect(metadata.filterSummary, contains('Lucas Centro'));
    expect(metadata.filterSummary, contains('Mel'));
    expect(
      metadata.filterSummary,
      isNot(contains(l10n.salesNotasEntradaTotalsAmountLabel)),
    );
  });

  test('summary share metadata uses supplier total columns', () {
    final metadata = buildSalesNotasEntradaResumoShareMetadata(
      l10n: l10n,
      rows: <NotaEntradaResumoFornecedorRow>[
        const NotaEntradaResumoFornecedorRow(
          codEmpresa: 1,
          codFilial: 1,
          nomeFilial: 'Lucas Centro',
          codFornecedor: 8,
          nomeFornecedor: 'Casa do Mel',
          cnpjCpfFornecedor: '12345678000195',
          qtdNotas: 2,
          ticketMedio: 75.25,
          valorTotalCompra: 150.5,
        ),
      ],
      totalValorCompra: 980.25,
      exportHeaderContext: buildSalesNotasEntradaShareExportHeaderContext(
        l10n: l10n,
        agentName: 'Lucas Centro',
        dataLancamentoInicio: DateTime(2026, 9),
        dataLancamentoFim: DateTime(2026, 9, 12),
        searchTerm: 'Mel',
      ),
    );

    expect(metadata.title, l10n.salesCardNotasEntradaTitle);
    expect(metadata.subtitle, l10n.salesNotasEntradaSummarySubtitle);
    expect(metadata.pdfOrientation, ChartSharePdfOrientation.landscape);
    expect(
      metadata.tableData?.headers,
      <String>[
        l10n.salesNotasEntradaColumnCodFornecedor,
        l10n.salesNotasEntradaColumnFornecedor,
        l10n.salesNotasEntradaColumnCnpjCpf,
        l10n.salesNotasEntradaColumnQtdNotas,
        l10n.salesNotasEntradaColumnTicketMedio,
        l10n.salesNotasEntradaColumnValorTotal,
      ],
    );
    expect(metadata.tableData?.rows.single[0], '8');
    expect(metadata.tableData?.rows.single[1], 'Casa do Mel');
    expect(metadata.tableData?.rows.single[3], '2');
    expect(
      metadata.tableData?.rows.single[4],
      formatSalesNotasEntradaCurrency(75.25),
    );
    expect(
      metadata.tableData?.footerRows.single.last,
      formatSalesNotasEntradaCurrency(980.25),
    );
    expect(
      metadata.tableData?.footerRows.single.first,
      '${l10n.salesNotasEntradaTotalsAmountLabel}:',
    );
    expect(metadata.filterSummary, contains('Mel'));
    expect(
      metadata.filterSummary,
      isNot(contains(l10n.salesNotasEntradaTotalsAmountLabel)),
    );
  });
}
