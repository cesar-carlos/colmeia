import 'package:checks/checks.dart';
import 'package:colmeia/features/agent_queries/data/models/resumo_parcelas_dia_semana_row_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ResumoParcelasDiaSemanaRowModel', () {
    test('fromMap accepts camelCase keys', () {
      final model = ResumoParcelasDiaSemanaRowModel.fromMap(
        <String, dynamic>{
          'codEmpresa': 1,
          'codFilial': 6,
          'diaSemanaNumero': 2,
          'diaSemana': 'Segunda',
          'qtdVendas': 10,
          'valorParcela': 99.5,
        },
      );
      check(model.codEmpresa).equals(1);
      check(model.codFilial).equals(6);
      check(model.diaSemanaNumero).equals(2);
      check(model.diaSemana).equals('Segunda');
      check(model.qtdVendas).equals(10);
      check(model.valorParcela).equals(99.5);
    });

    test('fromMap parses string DiaSemanaNumero and lowercase keys', () {
      final model = ResumoParcelasDiaSemanaRowModel.fromMap(
        <String, dynamic>{
          'CodEmpresa': '1',
          'CodFilial': '6',
          'DiaSemanaNumero': '3',
          'diasemana': 'Terça',
          'qtdvendas': '5',
          'valorparcela': '12.5',
        },
      );
      check(model.codEmpresa).equals(1);
      check(model.codFilial).equals(6);
      check(model.diaSemanaNumero).equals(3);
      check(model.diaSemana).equals('Terça');
      check(model.qtdVendas).equals(5);
      check(model.valorParcela).equals(12.5);
    });

    test('fromMap throws when DiaSemana mismatches DiaSemanaNumero', () {
      expect(
        () => ResumoParcelasDiaSemanaRowModel.fromMap(
          <String, dynamic>{
            'CodEmpresa': 1,
            'CodFilial': 1,
            'DiaSemanaNumero': 2,
            'DiaSemana': 'WrongLabel',
            'QtdVendas': 1,
            'ValorParcela': 1.0,
          },
        ),
        throwsFormatException,
      );
    });

    test('fromMap throws when DiaSemana missing', () {
      expect(
        () => ResumoParcelasDiaSemanaRowModel.fromMap(
          <String, dynamic>{
            'CodEmpresa': 1,
            'CodFilial': 1,
            'DiaSemanaNumero': 1,
            'QtdVendas': 1,
            'ValorParcela': 1.0,
          },
        ),
        throwsFormatException,
      );
    });
  });
}
