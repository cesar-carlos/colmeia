import 'package:checks/checks.dart';
import 'package:colmeia/features/agent_queries/data/models/resumo_parcelas_mensal_row_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ResumoParcelasMensalRowModel', () {
    test('fromMap accepts camelCase keys', () {
      final model = ResumoParcelasMensalRowModel.fromMap(
        <String, dynamic>{
          'codEmpresa': 1,
          'codFilial': 6,
          'ano': 2026,
          'mes': 3,
          'qtdVendas': 42,
          'valorParcela': 150.5,
        },
      );
      check(model.codEmpresa).equals(1);
      check(model.codFilial).equals(6);
      check(model.ano).equals(2026);
      check(model.mes).equals(3);
      check(model.qtdVendas).equals(42);
      check(model.valorParcela).equals(150.5);
      check(model.toEntity().anoMes).equals('2026/03');
    });

    test('fromMap accepts all-lowercase keys (bridge JSON)', () {
      final model = ResumoParcelasMensalRowModel.fromMap(
        <String, dynamic>{
          'codempresa': 1,
          'codfilial': 2,
          'ano': 2025,
          'mes': '11',
          'qtdvendas': '10',
          'valorparcela': '123.4500000',
        },
      );
      check(model.codEmpresa).equals(1);
      check(model.codFilial).equals(2);
      check(model.ano).equals(2025);
      check(model.mes).equals(11);
      check(model.qtdVendas).equals(10);
      check(model.valorParcela).equals(123.45);
      check(model.toEntity().anoMes).equals('2025/11');
    });

    test('fromMap parses ValorParcela from decimal string with comma', () {
      final model = ResumoParcelasMensalRowModel.fromMap(
        <String, dynamic>{
          'CodEmpresa': 1,
          'CodFilial': 1,
          'Ano': 2024,
          'Mes': 7,
          'QtdVendas': 1,
          'ValorParcela': '1234,56',
        },
      );
      check(model.valorParcela).equals(1234.56);
      check(model.toEntity().anoMes).equals('2024/07');
    });

    test('fromMap throws FormatException when Mes is missing', () {
      expect(
        () => ResumoParcelasMensalRowModel.fromMap(
          <String, dynamic>{
            'CodEmpresa': 1,
            'CodFilial': 1,
            'Ano': 2026,
            'QtdVendas': 1,
            'ValorParcela': 1.0,
          },
        ),
        throwsA(isA<FormatException>()),
      );
    });

    test('fromMap accepts AnoMes when it matches Ano and Mes', () {
      final model = ResumoParcelasMensalRowModel.fromMap(
        <String, dynamic>{
          'CodEmpresa': 1,
          'CodFilial': 1,
          'Ano': 2026,
          'Mes': 9,
          'AnoMes': '2026/09',
          'QtdVendas': 1,
          'ValorParcela': 1.0,
        },
      );
      check(model.toEntity().anoMes).equals('2026/09');
    });

    test(
      'fromMap accepts AnoMes without zero-padded month when Ano/Mes match',
      () {
        final model = ResumoParcelasMensalRowModel.fromMap(
          <String, dynamic>{
            'CodEmpresa': 1,
            'CodFilial': 1,
            'Ano': 2026,
            'Mes': 9,
            'AnoMes': '2026/9',
            'QtdVendas': 1,
            'ValorParcela': 1.0,
          },
        );
        check(model.toEntity().anoMes).equals('2026/09');
      },
    );

    test('fromMap throws when AnoMes disagrees with Ano/Mes', () {
      expect(
        () => ResumoParcelasMensalRowModel.fromMap(
          <String, dynamic>{
            'CodEmpresa': 1,
            'CodFilial': 1,
            'Ano': 2026,
            'Mes': 1,
            'AnoMes': '2026/02',
            'QtdVendas': 1,
            'ValorParcela': 1.0,
          },
        ),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'message',
            contains('AnoMes'),
          ),
        ),
      );
    });
  });
}
