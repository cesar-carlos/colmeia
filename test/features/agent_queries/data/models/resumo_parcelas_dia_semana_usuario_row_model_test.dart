import 'package:checks/checks.dart';
import 'package:colmeia/features/agent_queries/data/models/resumo_parcelas_dia_semana_usuario_row_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ResumoParcelasDiaSemanaUsuarioRowModel', () {
    test('fromMap accepts camelCase keys', () {
      final model = ResumoParcelasDiaSemanaUsuarioRowModel.fromMap(
        <String, dynamic>{
          'codEmpresa': 1,
          'codFilial': 6,
          'nomeUsuario': 'Ada',
          'diaSemanaNumero': 2,
          'diaSemana': 'Segunda',
          'qtdVendas': 10,
          'valorParcela': 99.5,
        },
      );
      check(model.codEmpresa).equals(1);
      check(model.codFilial).equals(6);
      check(model.nomeUsuario).equals('Ada');
      check(model.diaSemanaNumero).equals(2);
      check(model.diaSemana).equals('Segunda');
      check(model.qtdVendas).equals(10);
      check(model.valorParcela).equals(99.5);
    });

    test('fromMap parses string numerics and lowercase keys', () {
      final model = ResumoParcelasDiaSemanaUsuarioRowModel.fromMap(
        <String, dynamic>{
          'CodEmpresa': '1',
          'CodFilial': '6',
          'NomeUsuario': 'Bob',
          'DiaSemanaNumero': '3',
          'diasemana': 'Terça',
          'qtdvendas': '5',
          'valorparcela': '12.5',
        },
      );
      check(model.codEmpresa).equals(1);
      check(model.codFilial).equals(6);
      check(model.nomeUsuario).equals('Bob');
      check(model.diaSemanaNumero).equals(3);
      check(model.diaSemana).equals('Terça');
      check(model.qtdVendas).equals(5);
      check(model.valorParcela).equals(12.5);
    });

    test('fromMap throws when DiaSemana mismatches DiaSemanaNumero', () {
      expect(
        () => ResumoParcelasDiaSemanaUsuarioRowModel.fromMap(
          <String, dynamic>{
            'CodEmpresa': 1,
            'CodFilial': 1,
            'NomeUsuario': 'X',
            'DiaSemanaNumero': 2,
            'DiaSemana': 'WrongLabel',
            'QtdVendas': 1,
            'ValorParcela': 1.0,
          },
        ),
        throwsFormatException,
      );
    });
  });
}
