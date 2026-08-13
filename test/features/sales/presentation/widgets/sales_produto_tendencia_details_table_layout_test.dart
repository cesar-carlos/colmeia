import 'package:checks/checks.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_produto_tendencia_details_section.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SalesProdutoTendenciaDetailsTableLayout', () {
    test('should omit grupo from the minimum width', () {
      final withoutPeriod = SalesProdutoTendenciaDetailsTableLayout.minWidth();
      check(withoutPeriod).equals(
        SalesProdutoTendenciaDetailsTableLayout.productMinWidth +
            SalesProdutoTendenciaDetailsTableLayout.classificacaoWidth +
            SalesProdutoTendenciaDetailsTableLayout.deltaWidth +
            SalesProdutoTendenciaDetailsTableLayout.percentualWidth,
      );
    });

    test('should add both period quantity columns without a group slot', () {
      final withPeriod = SalesProdutoTendenciaDetailsTableLayout.minWidth(
        showPeriodQuantityColumns: true,
      );
      final withoutPeriod = SalesProdutoTendenciaDetailsTableLayout.minWidth();
      check(withPeriod - withoutPeriod).equals(
        SalesProdutoTendenciaDetailsTableLayout.qtdWidth * 2,
      );
    });
  });
}
