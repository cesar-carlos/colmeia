import 'package:checks/checks.dart';
import 'package:colmeia/features/agent_queries/domain/entities/cadastro_filial_row.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_margem_produto_filters_sheet.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const lojaA = CadastroFilialRow(
    codEmpresa: 1,
    codFilial: 1,
    nomeFilial: 'Matriz',
  );
  const lojaB = CadastroFilialRow(
    codEmpresa: 1,
    codFilial: 2,
    nomeFilial: 'Filial Centro',
    nomeFantasia: 'Centro',
  );

  test('picks the only branch without using a hardcoded pair', () {
    final selected = salesMargemProdutoMatchFilial(
      items: const <CadastroFilialRow>[lojaB],
      codEmpresa: 9,
      codFilial: 9,
    );

    check(selected).equals(lojaB);
  });

  test('keeps the persisted branch when several are available', () {
    final selected = salesMargemProdutoMatchFilial(
      items: const <CadastroFilialRow>[lojaA, lojaB],
      codEmpresa: 1,
      codFilial: 2,
    );

    check(selected).equals(lojaB);
  });

  test('falls back to the first branch when the persisted pair is missing', () {
    final selected = salesMargemProdutoMatchFilial(
      items: const <CadastroFilialRow>[lojaA, lojaB],
      codEmpresa: 8,
      codFilial: 8,
    );

    check(selected).equals(lojaA);
  });

  test('returns null when the agent has no branches', () {
    final selected = salesMargemProdutoMatchFilial(
      items: const <CadastroFilialRow>[],
      codEmpresa: 1,
      codFilial: 1,
    );

    check(selected).isNull();
  });

  test('find returns the exact pair and ignores a lone mismatch', () {
    final found = salesMargemProdutoFindFilial(
      items: const <CadastroFilialRow>[lojaA],
      codEmpresa: 1,
      codFilial: 2,
    );

    check(found).isNull();
    check(
      salesMargemProdutoFindFilial(
        items: const <CadastroFilialRow>[lojaA, lojaB],
        codEmpresa: 1,
        codFilial: 2,
      ),
    ).equals(lojaB);
  });
}
