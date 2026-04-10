import 'package:checks/checks.dart';
import 'package:colmeia/features/agent_queries/data/models/resumo_parcelas_dia_semana_row_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ResumoParcelasDiaSemanaRowModel', () {
    test('fromMap accepts camelCase keys', () {
      final model = ResumoParcelasDiaSemanaRowModel.fromMap(
        <String, dynamic>{
          'diaSemanaNumero': 2,
          'diaSemana': 'Segunda',
          'quantidade': 10,
          'valorTotal': 99.5,
        },
      );
      check(model.diaSemanaNumero).equals(2);
      check(model.diaSemana).equals('Segunda');
      check(model.quantidade).equals(10);
      check(model.valorTotal).equals(99.5);
    });

    test('fromMap parses string DiaSemanaNumero and lowercase keys', () {
      final model = ResumoParcelasDiaSemanaRowModel.fromMap(
        <String, dynamic>{
          'DiaSemanaNumero': '3',
          'diasemana': 'Terça',
          'quantidade': '5',
          'valortotal': '12.5',
        },
      );
      check(model.diaSemanaNumero).equals(3);
      check(model.diaSemana).equals('Terça');
      check(model.quantidade).equals(5);
      check(model.valorTotal).equals(12.5);
    });

    test('toEntity uses canonical weekday label from numero', () {
      final model = ResumoParcelasDiaSemanaRowModel.fromMap(
        <String, dynamic>{
          'DiaSemanaNumero': 2,
          'DiaSemana': 'WrongLabel',
          'Quantidade': 1,
          'ValorTotal': 1.0,
        },
      );
      check(model.toEntity().diaSemana).equals('Segunda');
    });

    test('fromMap throws when DiaSemana missing', () {
      expect(
        () => ResumoParcelasDiaSemanaRowModel.fromMap(
          <String, dynamic>{
            'DiaSemanaNumero': 1,
            'Quantidade': 1,
            'ValorTotal': 1.0,
          },
        ),
        throwsFormatException,
      );
    });
  });
}
