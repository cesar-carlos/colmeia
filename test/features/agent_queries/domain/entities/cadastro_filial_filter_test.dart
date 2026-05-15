import 'package:checks/checks.dart';
import 'package:colmeia/features/agent_queries/domain/entities/cadastro_filial_filter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CadastroFilialFilter', () {
    test('computes row window from page and pageSize', () {
      const filter = CadastroFilialFilter(page: 3, pageSize: 10);

      check(filter.startRow).equals(21);
      check(filter.endRow).equals(30);
    });

    test('accepts optional company and branch filters', () {
      const filter = CadastroFilialFilter(codEmpresa: 1, codFilial: 0);

      check(filter.validationError()).isNull();
    });

    test('rejects invalid pagination and numeric filters', () {
      check(
        const CadastroFilialFilter(codEmpresa: 0).validationError(),
      ).equals('codEmpresa must be greater than zero');
      check(
        const CadastroFilialFilter(codFilial: -1).validationError(),
      ).equals('codFilial must be greater than or equal to zero');
      check(
        const CadastroFilialFilter(page: 0).validationError(),
      ).equals('page must be >= 1');
      check(
        const CadastroFilialFilter(pageSize: 0).validationError(),
      ).equals('pageSize must be >= 1');
      check(
        const CadastroFilialFilter(
          pageSize: CadastroFilialFilter.maxPageSize + 1,
        ).validationError(),
      ).equals('pageSize must be <= ${CadastroFilialFilter.maxPageSize}');
    });
  });
}
