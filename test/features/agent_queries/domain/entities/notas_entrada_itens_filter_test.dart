import 'package:checks/checks.dart';
import 'package:colmeia/features/agent_queries/domain/entities/notas_entrada_itens_filter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('accepts a positive purchase id', () {
    const filter = NotasEntradaItensFilter(compraId: 80);

    check(filter.compraId).equals(80);
    check(filter.validationError()).isNull();
  });

  test('rejects a non-positive purchase id', () {
    check(
      const NotasEntradaItensFilter(compraId: 0).validationError(),
    ).equals('compraId must be greater than zero');
  });
}
