import 'package:checks/checks.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_vendas_produto_vendido_sql_periodo_filter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('validation rejects SQL LIKE wildcards in origem', () {
    final withPercent = ResumoVendasProdutoVendidoSqlPeriodoFilter(
      dataVendaInicio: DateTime.utc(2026, 1, 1),
      dataVendaFim: DateTime.utc(2026, 1, 31),
      origem: 'Frente%',
    );
    check(withPercent.validationError()).isNotNull();

    final withUnderscore = ResumoVendasProdutoVendidoSqlPeriodoFilter(
      dataVendaInicio: DateTime.utc(2026, 1, 1),
      dataVendaFim: DateTime.utc(2026, 1, 31),
      origem: 'Frente_Loja',
    );
    check(withUnderscore.validationError()).isNotNull();
  });

  test('validation accepts default exact origem', () {
    final filter = ResumoVendasProdutoVendidoSqlPeriodoFilter(
      dataVendaInicio: DateTime.utc(2026, 1, 1),
      dataVendaFim: DateTime.utc(2026, 1, 31),
    );
    check(filter.validationError()).isNull();
  });
}
