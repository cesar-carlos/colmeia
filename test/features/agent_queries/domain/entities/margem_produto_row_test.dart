import 'package:checks/checks.dart';
import 'package:colmeia/features/agent_queries/domain/entities/margem_produto_row.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MargemProdutoRow derived metrics', () {
    test(
      'returns null profit and percents when replacement cost is missing',
      () {
        const row = MargemProdutoRow(
          codEmpresa: 1,
          codFilial: 1,
          nomeFilial: 'Loja',
          codProduto: 10,
          nomeProduto: 'Mel',
          precoVendaProduto: 25,
        );

        check(row.lucro).isNull();
        check(row.markupSobreCustoPercent).isNull();
        check(row.margemLucroBrutoPercent).isNull();
      },
    );

    test('keeps zero cost distinct from missing cost', () {
      const row = MargemProdutoRow(
        codEmpresa: 1,
        codFilial: 1,
        nomeFilial: 'Loja',
        codProduto: 10,
        nomeProduto: 'Mel',
        custoReposicao: 0,
        precoVendaProduto: 25,
        percentualMarkupCustoCompraProduto: 0,
        margemLucroProduto: 100,
      );

      check(row.lucro).equals(25);
      check(row.markupSobreCustoPercent).equals(0);
      check(row.margemLucroBrutoPercent).equals(100);
    });
  });
}
