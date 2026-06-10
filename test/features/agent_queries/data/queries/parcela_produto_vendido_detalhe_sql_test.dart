import 'package:colmeia/features/agent_queries/data/queries/parcela_produto_vendido_detalhe_sql.dart';
import 'package:colmeia/features/agent_queries/data/queries/resumo_parcela_forma_pagamento_sql_v2.dart';
import 'package:colmeia/features/agent_queries/data/queries/resumo_parcelas_mensal_sql.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ParcelaProdutoVendidoDetalheSql', () {
    test('overview aggregate omits cliente/municipio/vendedor joins', () {
      const sql = ParcelaProdutoVendidoDetalheSql
          .selectFromParcelLinesForOverviewAggregate;

      expect(sql, contains('ValorTrocoParcela'));
      expect(sql, contains('ValorTotalParcelasRateioTroco'));
      expect(sql, isNot(contains('INNER JOIN Cliente')));
      expect(sql, isNot(contains('INNER JOIN Municipio')));
      expect(sql, isNot(contains('LEFT JOIN Vendedor')));
      expect(sql, isNot(contains('NomeMunicipio')));
    });

    test('full projection keeps cliente/municipio/vendedor joins', () {
      const sql =
          ParcelaProdutoVendidoDetalheSql.selectFromParcelLinesThroughJoins;

      expect(sql, contains('INNER JOIN Cliente'));
      expect(sql, contains('INNER JOIN Municipio'));
      expect(sql, contains('LEFT JOIN Vendedor'));
      expect(sql, contains('NomeMunicipio'));
    });
  });

  group('overview resumo consumers', () {
    test(
      'ResumoParcelaFormaPagamentoSqlV2 uses overview slice and half-open dates',
      () {
        const sql = ResumoParcelaFormaPagamentoSqlV2.query;

        expect(
          sql,
          contains(
            ParcelaProdutoVendidoDetalheSql
                .selectFromParcelLinesForOverviewAggregate,
          ),
        );
        expect(sql, contains('DataVenda >= CAST(:dataVendaInicio AS DATE)'));
        expect(
          sql,
          contains('DataVenda < DATEADD(day, 1, CAST(:dataVendaFim AS DATE))'),
        );
        expect(sql, isNot(contains('DataVenda BETWEEN')));
      },
    );

    test(
      'ResumoParcelasMensalSql uses overview slice without unused middle columns',
      () {
        final sql = ResumoParcelasMensalSql.query();

        expect(
          sql,
          contains(
            ParcelaProdutoVendidoDetalheSql
                .selectFromParcelLinesForOverviewAggregate,
          ),
        );
        expect(sql, isNot(contains('NomeMunicipio')));
        expect(sql, isNot(contains('CodRegiao')));
      },
    );
  });
}
