import 'package:checks/checks.dart';
import 'package:colmeia/features/agent_queries/data/queries/produto_vendido_tendencia_de_venda_screen_sql.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final sql = ProdutoVendidoTendenciaDeVendaScreenSql.query(
    startRow: 1,
    endRow: 20,
  );

  test('screen query shares a single filtered universe CTE', () {
    check(sql).contains('WITH Parametros AS (');
    check(sql).contains('BaseVendas AS (');
    check(sql).contains('Resultado AS (');
    check('WITH'.allMatches(sql).length).equals(1);
    check('BaseVendas AS ('.allMatches(sql).length).equals(1);
  });

  test('screen query tags SUMMARY, PAGE, GAINER, and LOSER row kinds', () {
    check(sql).contains('AS RowKind');
    check(sql).contains("'SUMMARY'");
    check(sql).contains("'PAGE'");
    check(sql).contains("'GAINER'");
    check(sql).contains("'LOSER'");
    check(sql).contains('UNION ALL');
  });

  test('screen query uses half-open sargable DataVenda predicates', () {
    check(sql).contains('pv.DataVenda >= prm.PeriodoAtualInicio');
    check(sql).contains(
      'pv.DataVenda < DATEADD(day, 1, prm.PeriodoAtualFim)',
    );
    check(sql.contains('CAST(pv.DataVenda AS DATE)')).isFalse();
  });

  test('screen query applies separate page and summary classificacao filters', () {
    final filtered = ProdutoVendidoTendenciaDeVendaScreenSql.query(
      startRow: 1,
      endRow: 20,
      pageClassificacao: 'CRESCENDO',
      summaryClassificacao: 'CAINDO',
    );

    check(filtered).contains("WHERE Classificacao = N'CRESCENDO'");
    check(filtered).contains("WHERE Classificacao = N'CAINDO'");
  });

  test('screen query inlines pagination bounds and top movers limit', () {
    check(sql).contains('N.RowNum BETWEEN 1 AND 20');
    check(sql).contains('SELECT TOP 15');
    check(sql.contains(':startRow')).isFalse();
    check(sql.contains(':endRow')).isFalse();
  });

  test('screen query validates bounds', () {
    expect(
      () => ProdutoVendidoTendenciaDeVendaScreenSql.query(
        startRow: 0,
        endRow: 20,
      ),
      throwsArgumentError,
    );
    expect(
      () => ProdutoVendidoTendenciaDeVendaScreenSql.query(
        startRow: 20,
        endRow: 19,
      ),
      throwsArgumentError,
    );
  });
}
