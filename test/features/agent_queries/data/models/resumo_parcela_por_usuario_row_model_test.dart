import 'package:checks/checks.dart';
import 'package:colmeia/features/agent_queries/data/models/resumo_parcela_por_usuario_row_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ResumoParcelaPorUsuarioRowModel', () {
    test('fromMap accepts camelCase keys', () {
      final model = ResumoParcelaPorUsuarioRowModel.fromMap(
        <String, dynamic>{
          'codEmpresa': 10,
          'codFilial': 20,
          'nomeUsuario': 'Caixa',
          'qtdVendas': 3,
          'valorParcela': 155.75,
        },
      );
      check(model.toEntity().codEmpresa).equals(10);
      check(model.toEntity().codFilial).equals(20);
      check(model.toEntity().nomeUsuario).equals('Caixa');
      check(model.toEntity().qtdVendas).equals(3);
      check(model.toEntity().valorParcela).equals(155.75);
    });

    test('fromMap accepts all-lowercase keys (bridge JSON)', () {
      final model = ResumoParcelaPorUsuarioRowModel.fromMap(
        <String, dynamic>{
          'codempresa': 1,
          'codfilial': 2,
          'nomeusuario': '  OP  ',
          'qtdvendas': 5,
          'valorparcela': '123.4500000',
        },
      );
      check(model.toEntity().nomeUsuario).equals('OP');
      check(model.toEntity().valorParcela).equals(123.45);
    });
  });
}
