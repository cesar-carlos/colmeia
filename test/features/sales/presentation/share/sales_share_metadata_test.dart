import 'package:colmeia/features/agent_queries/domain/entities/produto_vendido_tendencia_de_venda_media_movel_row.dart';
import 'package:colmeia/features/agent_queries/domain/entities/produto_vendido_tendencia_de_venda_summary_row.dart';
import 'package:colmeia/features/sales/domain/entities/sales_monthly_pnl_point.dart';
import 'package:colmeia/features/sales/presentation/pages/sales_produto_tendencia_media_movel_widgets.dart';
import 'package:colmeia/features/sales/presentation/share/sales_monthly_pnl_share.dart';
import 'package:colmeia/features/sales/presentation/share/sales_produto_tendencia_media_movel_share.dart';
import 'package:colmeia/features/sales/presentation/share/sales_produto_tendencia_share.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppLocalizations l10n;
  late AppThemeTokens tokens;

  setUp(() {
    l10n = lookupAppLocalizations(const Locale('en'));
    tokens = AppThemeTokens.light;
  });

  test('media movel count share metadata includes bucket rows', () {
    const buckets = <SalesProdutoTendenciaMediaMovelClassBucket>[
      SalesProdutoTendenciaMediaMovelClassBucket(
        classificacao: 'CRESCENDO',
        count: 12,
        impacto: 40,
      ),
    ];

    final metadata = buildSalesProdutoTendenciaMediaMovelCountShareMetadata(
      l10n: l10n,
      buckets: buckets,
      tokens: tokens,
    );

    expect(
      metadata.title,
      l10n.salesProdutoTendenciaMediaMovelSummaryByClassificacaoTitle,
    );
    expect(metadata.tableData?.rows.single.last, '12');
    expect(metadata.chartExportBuilder, isNotNull);
  });

  test('media movel details share metadata formats product rows', () {
    const rows = <ProdutoVendidoTendenciaDeVendaMediaMovelRow>[
      ProdutoVendidoTendenciaDeVendaMediaMovelRow(
        codEmpresa: 1,
        codFilial: 1,
        codProduto: 7,
        nomeProduto: 'Coffee',
        codUnidadeMedida: 'UN',
        mediaAtual: 10,
        mediaAnterior: 8,
        diferenca: 2,
        tendenciaPercentual: 25,
        classificacao: 'CRESCENDO',
        nomeGrupoProduto: 'Beverages',
      ),
    ];

    final metadata = buildSalesProdutoTendenciaMediaMovelDetailsShareMetadata(
      l10n: l10n,
      rows: rows,
      filterSummary: '7 days',
    );

    expect(metadata.filterSummary, '7 days');
    expect(metadata.tableData?.rows.single.first, 'Coffee');
    expect(metadata.chartExportBuilder, isNull);
  });

  test('monthly pnl line share metadata includes month values', () {
    const points = <SalesMonthlyPnlPoint>[
      SalesMonthlyPnlPoint(
        anoMes: '2026/05',
        year: 2026,
        month: 5,
        venda: 1000,
        lucro: 200,
        custoMercadoria: 700,
      ),
    ];

    final metadata = buildSalesMonthlyPnlLineChartShareMetadata(
      l10n: l10n,
      points: points,
    );

    expect(metadata.title, l10n.salesMonthlyPnlChartTitle);
    expect(metadata.tableData?.rows.single.first, '2026/05');
  });

  test('tendencia classificacao share metadata uses summary buckets', () {
    final metadata = buildSalesProdutoTendenciaClassificacaoShareMetadata(
      l10n: l10n,
      summaryRows: const <ProdutoVendidoTendenciaDeVendaSummaryRow>[
        ProdutoVendidoTendenciaDeVendaSummaryRow(
          classificacao: 'CRESCENDO',
          quantidadeProdutos: 3,
          impactoLiquido: 10,
        ),
      ],
      buckets: const <SalesProdutoTendenciaClassBucket>[
        SalesProdutoTendenciaClassBucket(
          classificacao: 'CRESCENDO',
          count: 3,
          impacto: 10,
        ),
      ],
      tokens: tokens,
    );

    expect(
      metadata.title,
      l10n.salesProdutoTendenciaSummaryByClassificacaoTitle,
    );
    expect(metadata.tableData?.rows.single[1], '3');
  });
}
