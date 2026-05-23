import 'package:colmeia/features/agent_queries/data/queries/cadastro_filial_sql.dart';
import 'package:colmeia/features/agent_queries/domain/entities/cadastro_filial_filter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CadastroFilialSql', () {
    test('query uses direct branch catalog joins and paging params', () {
      final sql = CadastroFilialSql.query();

      expect(sql, contains('FROM Filial f'));
      expect(sql, contains('LEFT JOIN Municipio m ON'));
      expect(sql, contains('TRIM(m.Nome) AS NomeMunicipio'));
      expect(sql, contains('REPLACE(REPLACE(REPLACE(TRIM(f.CEP)'));
      expect(sql, contains('COUNT(*) AS TotalCount'));
      expect(
        sql,
        contains(
          'ROW_NUMBER() OVER (ORDER BY b.CodEmpresa, b.CodFilial) AS Rn',
        ),
      );
      expect(sql, contains(':startRow'));
      expect(sql, contains(':endRow'));
      expect(sql.contains('?'), isFalse);
    });

    test('query inlines a grouped branch predicate for multiple branches', () {
      final sql = CadastroFilialSql.query(
        branches: const <CadastroFilialBranchRef>[
          CadastroFilialBranchRef(agentId: 'a', codEmpresa: 1, codFilial: 2),
          CadastroFilialBranchRef(agentId: 'a', codEmpresa: 1, codFilial: 1),
          CadastroFilialBranchRef(agentId: 'b', codEmpresa: 2, codFilial: 9),
        ],
        hasSelectedBranches: true,
      );

      expect(sql, contains('f.CodEmpresa = 1 AND f.CodFilial IN (1, 2)'));
      expect(sql, contains('f.CodEmpresa = 2 AND f.CodFilial = 9'));
      expect(sql, isNot(contains('AND 1 = 0')));
    });

    test(
      'query short-circuits to no rows when selected branches miss agent',
      () {
        final sql = CadastroFilialSql.query(hasSelectedBranches: true);

        expect(sql, contains('AND 1 = 0'));
      },
    );
  });
}
