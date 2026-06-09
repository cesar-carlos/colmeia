import 'package:colmeia/app/theme/app_theme.dart';
import 'package:colmeia/features/agent_queries/domain/entities/produto_vendido_tendencia_de_venda_summary_row.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_produto_tendencia_classificacao_chart_support.dart';
import 'package:colmeia/shared/design_system/app_colors.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('salesProdutoTendenciaOrderedClassBuckets', () {
    test('orders buckets to match KPI strip and omits zero counts', () {
      const summaryRows = <ProdutoVendidoTendenciaDeVendaSummaryRow>[
        ProdutoVendidoTendenciaDeVendaSummaryRow(
          classificacao: 'PAROU DE VENDER',
          quantidadeProdutos: 1,
          impactoLiquido: -4,
        ),
        ProdutoVendidoTendenciaDeVendaSummaryRow(
          classificacao: 'CRESCENDO',
          quantidadeProdutos: 22,
          impactoLiquido: 80,
        ),
        ProdutoVendidoTendenciaDeVendaSummaryRow(
          classificacao: 'ESTAVEL',
          quantidadeProdutos: 11,
          impactoLiquido: 5,
        ),
      ];

      final buckets = salesProdutoTendenciaOrderedClassBuckets(summaryRows);

      expect(
        buckets.map((bucket) => bucket.classificacao).toList(),
        <String>['CRESCENDO', 'PAROU DE VENDER', 'ESTAVEL'],
      );
      expect(buckets.first.count, 22);
    });
  });

  group('salesProdutoTendenciaClassificacaoColor', () {
    test('maps classifications to semantic palette colors', () {
      final colors = AppTheme.light().extension<AppColors>()!;

      expect(
        salesProdutoTendenciaClassificacaoColor(colors, 'CRESCENDO'),
        colors.tertiary,
      );
      expect(
        salesProdutoTendenciaClassificacaoColor(colors, 'CAINDO'),
        colors.error,
      );
      expect(
        salesProdutoTendenciaClassificacaoColor(colors, 'NOVO PRODUTO'),
        colors.primary,
      );
      expect(
        salesProdutoTendenciaClassificacaoColor(colors, 'PAROU DE VENDER'),
        colors.onSurfaceVariant,
      );
      expect(
        salesProdutoTendenciaClassificacaoColor(colors, 'ESTAVEL'),
        colors.outline,
      );
    });
  });
}
