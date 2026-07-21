import 'package:checks/checks.dart';
import 'package:colmeia/features/agent_queries/domain/entities/ranking_produtos_faturamento_filter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final periodStart = DateTime(2026, 3, 10);
  final periodEnd = DateTime(2026, 4, 8);

  RankingProdutosFaturamentoFilter valid({
    int quantidadeProdutos = 15,
    String origem = 'FrenteLoja',
    String preVenda = 'N',
    int? codEmpresa,
    int? codFilial,
  }) {
    return RankingProdutosFaturamentoFilter(
      dataVendaInicio: periodStart,
      dataVendaFim: periodEnd,
      quantidadeProdutos: quantidadeProdutos,
      origem: origem,
      preVenda: preVenda,
      codEmpresa: codEmpresa,
      codFilial: codFilial,
    );
  }

  test('validationError returns null for a valid filter', () {
    check(valid().validationError()).isNull();
  });

  test('validationError rejects quantidadeProdutos below min', () {
    check(
      valid(quantidadeProdutos: 0).validationError(),
    ).equals(
      'quantidadeProdutos must be at least '
      '${RankingProdutosFaturamentoFilter.minQuantidadeProdutos}',
    );
  });

  test('validationError rejects quantidadeProdutos above max', () {
    check(
      valid(
        quantidadeProdutos:
            RankingProdutosFaturamentoFilter.maxQuantidadeProdutos + 1,
      ).validationError(),
    ).equals(
      'quantidadeProdutos must be at most '
      '${RankingProdutosFaturamentoFilter.maxQuantidadeProdutos}',
    );
  });

  test('validationError rejects origem with a single quote', () {
    check(
      valid(origem: "O'Reilly").validationError(),
    ).equals('origem must not contain single quotes');
  });

  test('validationError rejects origem LIKE wildcards', () {
    check(valid(origem: 'Frente%').validationError()).isNotNull();
  });

  test('validationError rejects invalid preVenda', () {
    check(valid(preVenda: 'X').validationError()).equals(
      "preVenda must be 'S' or 'N'",
    );
  });

  test('validationError requires codEmpresa when codFilial is set', () {
    check(valid(codFilial: 1).validationError()).equals(
      'codEmpresa is required when codFilial is set',
    );
  });

  test('validationError rejects inverted date range', () {
    final filter = RankingProdutosFaturamentoFilter(
      dataVendaInicio: periodEnd,
      dataVendaFim: periodStart,
      quantidadeProdutos: 15,
    );
    check(filter.validationError()).equals(
      'dataVendaFim must be on or after dataVendaInicio',
    );
  });
}
