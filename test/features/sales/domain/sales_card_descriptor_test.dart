import 'package:checks/checks.dart';
import 'package:colmeia/features/sales/domain/sales_card_descriptor.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('allSalesCards', () {
    test('contains sales trend card descriptor', () {
      final descriptor = allSalesCards.cast<SalesCardDescriptor?>().firstWhere(
        (card) => card?.id == 'produto_tendencia_venda',
        orElse: () => null,
      );

      check(descriptor).isNotNull();
      check(descriptor!.route).equals('/sales/produto_tendencia_venda');
      check(descriptor.l10nTitleKey).equals('salesCardProdutoTendenciaTitle');
    });
  });
}
