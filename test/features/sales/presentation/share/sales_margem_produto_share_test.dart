import 'package:colmeia/features/agent_queries/domain/entities/margem_produto_row.dart';
import 'package:colmeia/features/sales/presentation/share/sales_chart_share_export_filter.dart';
import 'package:colmeia/features/sales/presentation/share/sales_margem_produto_share.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_margem_produto_columns.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/widgets/charts/chart_pdf_exporter.dart';
import 'package:colmeia/shared/widgets/charts/chart_share_export_header_context.dart';
import 'package:colmeia/shared/widgets/charts/chart_share_pdf_limits.dart';
import 'package:colmeia/shared/widgets/charts/chart_share_pdf_orientation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

MargemProdutoRow _row({
  required int codProduto,
  required String nome,
  required double custo,
  required double preco,
  required double markup,
  required double margem,
}) {
  return MargemProdutoRow(
    codEmpresa: 1,
    codFilial: 1,
    nomeFilial: 'Lucas Centro',
    codProduto: codProduto,
    nomeProduto: nome,
    custoReposicao: custo,
    precoVendaProduto: preco,
    percentualMarkupCustoCompraProduto: markup,
    margemLucroProduto: margem,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppLocalizations l10n;

  setUp(() {
    l10n = lookupAppLocalizations(const Locale('pt', 'BR'));
  });

  test('share metadata formats catalog columns in landscape', () {
    final rows = <MargemProdutoRow>[
      _row(
        codProduto: 1,
        nome: 'Mel',
        custo: 4.5,
        preco: 9,
        markup: 100,
        margem: 50,
      ),
      _row(
        codProduto: 2,
        nome: 'Cafe',
        custo: 12.5,
        preco: 20,
        markup: 60,
        margem: 37.5,
      ),
    ];

    final metadata = buildSalesMargemProdutoShareMetadata(
      l10n: l10n,
      rows: rows,
      exportHeaderContext: buildSalesSingleAgentChartShareExportHeaderContext(
        l10n: l10n,
        agentName: 'Agente Centro',
        parameters: <ChartShareExportHeaderParameter>[
          ChartShareExportHeaderParameter(
            label: l10n.salesMargemProdutoFilterFilial,
            value: 'Lucas Centro',
          ),
        ],
      ),
    );

    expect(metadata.title, l10n.salesCardMargemProdutoTitle);
    expect(metadata.subject, l10n.salesCardMargemProdutoTitle);
    expect(metadata.subtitle, l10n.salesMargemProdutoIntroSubtitle);
    expect(metadata.pdfOrientation, ChartSharePdfOrientation.landscape);
    expect(metadata.chartExportBuilder, isNull);
    expect(metadata.includeChartImage, isFalse);
    expect(
      metadata.tableData?.headers,
      <String>[
        l10n.salesMargemProdutoColumnProduto,
        l10n.salesMargemProdutoColumnCusto,
        l10n.salesMargemProdutoColumnPreco,
        l10n.salesMargemProdutoColumnMarkup,
        l10n.salesMargemProdutoColumnMargem,
      ],
    );
    expect(metadata.tableData?.rows.length, 2);
    expect(metadata.tableData?.rows.first[0], 'Mel');
    expect(
      metadata.tableData?.rows.first[1],
      formatSalesMargemProdutoCurrency(4.5),
    );
    expect(
      metadata.tableData?.rows.first[2],
      formatSalesMargemProdutoCurrency(9),
    );
    expect(
      metadata.tableData?.rows.first[3],
      formatSalesMargemProdutoPercent(100),
    );
    expect(
      metadata.tableData?.rows.first[4],
      formatSalesMargemProdutoPercent(50),
    );
    expect(metadata.filterSummary, contains('Agente Centro'));
    expect(metadata.filterSummary, contains('Lucas Centro'));
  });

  test('share metadata truncates table rows over limit', () {
    final rows = List<MargemProdutoRow>.generate(
      ChartSharePdfLimits.maxTableRows + 1,
      (index) => _row(
        codProduto: index,
        nome: 'Product $index',
        custo: 10,
        preco: 20,
        markup: 100,
        margem: 50,
      ),
    );

    final metadata = buildSalesMargemProdutoShareMetadata(
      l10n: l10n,
      rows: rows,
    );

    const totalRows = ChartSharePdfLimits.maxTableRows + 1;
    expect(metadata.tableData?.rows.length, ChartSharePdfLimits.maxTableRows);
    expect(
      metadata.filterSummary,
      contains('${ChartSharePdfLimits.maxTableRows}'),
    );
    expect(metadata.filterSummary, contains('$totalRows'));
  });

  test(
    'share metadata builds a landscape PDF for a wrapping catalog',
    () async {
      final rows = List<MargemProdutoRow>.generate(
        185,
        (index) => _row(
          codProduto: index + 1,
          nome: 'MACA PERUANA VITAMINA C+ZINCO 60 CAPS ${index + 1}',
          custo: 47.9,
          preco: 119.8,
          markup: 150,
          margem: 60,
        ),
      );

      final metadata = buildSalesMargemProdutoShareMetadata(
        l10n: l10n,
        rows: rows,
        exportHeaderContext: buildSalesSingleAgentChartShareExportHeaderContext(
          l10n: l10n,
          agentName: 'Agente Centro',
          parameters: <ChartShareExportHeaderParameter>[
            ChartShareExportHeaderParameter(
              label: l10n.salesMargemProdutoFilterFilial,
              value: 'Lucas Centro',
            ),
          ],
        ),
      );

      final bytes = await ChartPdfExporter.build(
        title: metadata.title,
        subtitle: metadata.subtitle,
        filterSummary: metadata.filterSummary,
        tableData: metadata.tableData,
        pdfOrientation: metadata.pdfOrientation,
      );

      expect(bytes, isNotEmpty);
      expect(String.fromCharCodes(bytes.take(4)), '%PDF');
    },
  );
}
