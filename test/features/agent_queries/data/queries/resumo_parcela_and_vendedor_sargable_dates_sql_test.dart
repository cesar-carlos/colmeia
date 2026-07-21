import 'package:checks/checks.dart';
import 'package:colmeia/features/agent_queries/data/queries/resumo_parcela_forma_pagamento_diario_sql.dart';
import 'package:colmeia/features/agent_queries/data/queries/resumo_parcela_forma_pagamento_sql.dart';
import 'package:colmeia/features/agent_queries/data/queries/resumo_parcela_por_usuario_sql.dart';
import 'package:colmeia/features/agent_queries/data/queries/resumo_parcelas_anual_sql.dart';
import 'package:colmeia/features/agent_queries/data/queries/resumo_parcelas_dia_semana_sql.dart';
import 'package:colmeia/features/agent_queries/data/queries/resumo_parcelas_dia_semana_usuario_sql.dart';
import 'package:colmeia/features/agent_queries/data/queries/resumo_parcelas_forma_pagamento_por_mes_sql.dart';
import 'package:colmeia/features/agent_queries/data/queries/resumo_parcelas_mensal_sql.dart';
import 'package:colmeia/features/agent_queries/data/queries/resumo_vendas_diarias_por_vendedor_sql.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final samples = <String>[
    ResumoParcelaFormaPagamentoSql.query,
    ResumoParcelaFormaPagamentoDiarioSql.query,
    ResumoParcelaPorUsuarioSql.query,
    ResumoParcelasAnualSql.query(),
    ResumoParcelasDiaSemanaSql.query(),
    ResumoParcelasDiaSemanaUsuarioSql.query(),
    ResumoParcelasFormaPagamentoPorMesSql.query(),
    ResumoParcelasMensalSql.query(),
    ResumoVendasDiariasPorVendedorSql.query(),
  ];

  test('parcel and seller summaries use half-open DataVenda predicates', () {
    for (final sql in samples) {
      check(sql).contains('DataVenda >= CAST(:dataVendaInicio AS DATE)');
      check(sql).contains(
        'DataVenda < DATEADD(day, 1, CAST(:dataVendaFim AS DATE))',
      );
      check(sql.contains('DataVenda BETWEEN')).isFalse();
    }
  });
}
