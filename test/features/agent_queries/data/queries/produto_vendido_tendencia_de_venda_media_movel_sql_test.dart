import 'package:checks/checks.dart';
import 'package:colmeia/features/agent_queries/data/queries/produto_vendido_tendencia_de_venda_media_movel_sql.dart';
import 'package:colmeia/features/agent_queries/domain/entities/produto_vendido_tendencia_de_venda_media_movel_filter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final sql = ProdutoVendidoTendenciaDeVendaMediaMovelSql.pagedQuery(
    quantidadeDias: 7,
  );

  test('query keeps CTE structure for daily and moving-average flow', () {
    check(sql).contains('WITH Diario AS (');
    check(sql).contains('Movel AS (');
    check(sql).contains('UltimaLinha AS (');
    check(sql).contains('Resultado AS (');
    check(sql).contains('Tot AS (');
    check(sql).contains('Numbered AS (');
  });

  test('query uses named params for pagination', () {
    check(sql).contains(':startRow');
    check(sql).contains(':endRow');
  });

  test('query inlines moving-average window and lookback literals', () {
    check(sql).contains('ROWS BETWEEN 6 PRECEDING AND CURRENT ROW');
    check(sql).contains('ROWS BETWEEN 13 PRECEDING AND 7 PRECEDING');
    check(sql).contains('DATEADD(DAY, -13, CAST(GETDATE() AS DATE))');
  });

  test('query computes moving-average metrics and classification', () {
    check(sql).contains("pv.Origem = 'FrenteLoja'");
    check(sql).contains('tos.CodEmpresa = pv.CodEmpresa');
    check(sql).contains(
      'tos.CodTipoOperacaoSaida = pv.CodTipoOperacaoSaida',
    );
    check(sql.contains('tos.CodFilial = pv.CodFilial')).isFalse();
    check(sql).contains('AS MediaAtual');
    check(sql).contains('AS MediaAnterior');
    check(sql).contains('AS Diferenca');
    check(sql).contains('AS TendenciaPercentual');
    check(sql).contains("THEN 'NOVO'");
    check(sql).contains("THEN 'PAROU'");
    check(sql).contains("THEN 'CRESCENDO'");
    check(sql).contains("THEN 'CAINDO'");
    check(sql).contains("ELSE 'ESTAVEL'");
  });

  test('query carries total count through left-joined pagination', () {
    check(sql).contains('SELECT COUNT(*) AS TotalCount FROM Filtrado');
    check(
      sql,
    ).contains('LEFT JOIN Numbered N ON N.Rn BETWEEN :startRow AND :endRow');
    check(sql).contains('ORDER BY COALESCE(N.Rn, 2147483647)');
  });

  test(
    'row_number ordering uses empresa, filial, tendencia percentual DESC',
    () {
      final rowNumberBlock = sql.split('ROW_NUMBER() OVER').last;
      final empresa = rowNumberBlock.indexOf('f.CodEmpresa ASC');
      final filial = rowNumberBlock.indexOf('f.CodFilial ASC');
      final tendencia = rowNumberBlock.indexOf('f.TendenciaPercentual DESC');
      final diferenca = rowNumberBlock.indexOf('f.Diferenca DESC');
      final nomeProduto = rowNumberBlock.indexOf('f.NomeProduto ASC');
      check(empresa).isGreaterThan(-1);
      check(empresa).isLessThan(filial);
      check(filial).isLessThan(tendencia);
      check(tendencia).isLessThan(diferenca);
      check(diferenca).isLessThan(nomeProduto);
      check(rowNumberBlock.contains('f.CodProduto ASC')).isFalse();
    },
  );

  test('query keeps default optional filter predicates as tautologies', () {
    check(sql).contains('AND (1 = 1)');
    check(sql).contains('WHERE (1 = 1)');
  });

  test('query inlines optional detail filters as SQL literals', () {
    final filtered = ProdutoVendidoTendenciaDeVendaMediaMovelSql.pagedQuery(
      quantidadeDias: 14,
      searchTerm: "fox' prime",
      classificacao: 'CRESCENDO',
      codGrupoProduto: 14,
      codMarca: 490,
    );

    check(filtered).contains('AND p.CodGrupoProduto = 14');
    check(filtered).contains('AND p.CodMarca = 490');
    check(filtered).contains("N'%fox'' prime%'");
    check(filtered).contains("WHERE Classificacao = N'CRESCENDO'");
    check(filtered).contains('ROWS BETWEEN 27 PRECEDING AND 14 PRECEDING');
  });

  test('pagedQuery validates quantidadeDias', () {
    expect(
      () => ProdutoVendidoTendenciaDeVendaMediaMovelSql.pagedQuery(
        quantidadeDias: 0,
      ),
      throwsArgumentError,
    );
  });

  test('pagedQuery supports sorting by diferenca and nomeProduto', () {
    final byDiferenca = ProdutoVendidoTendenciaDeVendaMediaMovelSql.pagedQuery(
      quantidadeDias: 7,
      sortBy: ProdutoVendidoTendenciaDeVendaMediaMovelSortBy.diferencaDesc,
    );
    check(byDiferenca).contains('f.Diferenca DESC');
    check(byDiferenca).contains('f.TendenciaPercentual DESC');

    final byNome = ProdutoVendidoTendenciaDeVendaMediaMovelSql.pagedQuery(
      quantidadeDias: 7,
      sortBy: ProdutoVendidoTendenciaDeVendaMediaMovelSortBy.nomeProdutoAsc,
    );
    check(byNome).contains('f.NomeProduto ASC');
  });
}
