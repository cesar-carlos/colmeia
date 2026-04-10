import 'package:checks/checks.dart';
import 'package:colmeia/features/agent_queries/data/models/resumo_parcelas_anual_row_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ResumoParcelasAnualRowModel', () {
    test('fromMap accepts camelCase keys', () {
      final model = ResumoParcelasAnualRowModel.fromMap(
        <String, dynamic>{
          'ano': 2026,
          'quantidade': 42,
          'valorTotal': 150.5,
        },
      );
      check(model.ano).equals(2026);
      check(model.quantidade).equals(42);
      check(model.valorTotal).equals(150.5);
      check(model.toEntity().ano).equals(2026);
    });

    test('fromMap accepts all-lowercase keys (bridge JSON)', () {
      final model = ResumoParcelasAnualRowModel.fromMap(
        <String, dynamic>{
          'ano': 2025,
          'quantidade': '10',
          'valortotal': '123.4500000',
        },
      );
      check(model.ano).equals(2025);
      check(model.quantidade).equals(10);
      check(model.valorTotal).equals(123.45);
    });

    test('fromMap parses ValorTotal from decimal string with comma', () {
      final model = ResumoParcelasAnualRowModel.fromMap(
        <String, dynamic>{
          'Ano': 2024,
          'Quantidade': 1,
          'ValorTotal': '1234,56',
        },
      );
      check(model.valorTotal).equals(1234.56);
    });

    test('fromMap throws FormatException when Ano is missing', () {
      expect(
        () => ResumoParcelasAnualRowModel.fromMap(
          <String, dynamic>{
            'quantidade': 1,
            'valorTotal': 1.0,
          },
        ),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
