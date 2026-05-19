import 'package:colmeia/features/agent_queries/data/queries/resumo_parcela_forma_pagamento_sql.dart';
import 'package:colmeia/features/agent_queries/data/queries/resumo_parcela_por_usuario_sql.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'parcel resumo SQL sent to the bridge must not contain block comments',
    () {
      expect(
        ResumoParcelaFormaPagamentoSql.query,
        isNot(contains('/*')),
        reason: 'Hub/agent validators may reject /* */ as dangerous patterns',
      );
      expect(ResumoParcelaPorUsuarioSql.query, isNot(contains('/*')));
    },
  );
}
