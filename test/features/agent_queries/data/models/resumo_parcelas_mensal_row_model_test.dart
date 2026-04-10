import 'package:checks/checks.dart';
import 'package:colmeia/features/agent_queries/data/models/resumo_parcelas_mensal_row_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ResumoParcelasMensalRowModel', () {
    test('fromMap accepts camelCase keys', () {
      final model = ResumoParcelasMensalRowModel.fromMap(
        <String, dynamic>{
          'ano': 2026,
          'mes': 3,
          'quantidade': 42,
          'valorTotal': 150.5,
        },
      );
      check(model.ano).equals(2026);
      check(model.mes).equals(3);
      check(model.quantidade).equals(42);
      check(model.valorTotal).equals(150.5);
      check(model.toEntity().anoMes).equals('2026/03');
    });

    test('fromMap accepts all-lowercase keys (bridge JSON)', () {
      final model = ResumoParcelasMensalRowModel.fromMap(
        <String, dynamic>{
          'ano': 2025,
          'mes': '11',
          'quantidade': '10',
          'valortotal': '123.4500000',
        },
      );
      check(model.ano).equals(2025);
      check(model.mes).equals(11);
      check(model.quantidade).equals(10);
      check(model.valorTotal).equals(123.45);
      check(model.toEntity().anoMes).equals('2025/11');
    });

    test('fromMap parses ValorTotal from decimal string with comma', () {
      final model = ResumoParcelasMensalRowModel.fromMap(
        <String, dynamic>{
          'Ano': 2024,
          'Mes': 7,
          'Quantidade': 1,
          'ValorTotal': '1234,56',
        },
      );
      check(model.valorTotal).equals(1234.56);
      check(model.toEntity().anoMes).equals('2024/07');
    });

    test('fromMap throws FormatException when Mes is missing', () {
      expect(
        () => ResumoParcelasMensalRowModel.fromMap(
          <String, dynamic>{
            'Ano': 2026,
            'Quantidade': 1,
            'ValorTotal': 1.0,
          },
        ),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
