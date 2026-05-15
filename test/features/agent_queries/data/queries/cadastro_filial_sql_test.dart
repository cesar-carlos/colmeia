import 'package:checks/checks.dart';
import 'package:colmeia/features/agent_queries/data/queries/cadastro_filial_sql.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CadastroFilialSql', () {
    test('pagedQuery uses direct branch catalog joins and paging params', () {
      const sql = CadastroFilialSql.pagedQuery;

      check(sql).contains('FROM Filial f');
      check(sql).contains('LEFT JOIN Municipio m ON');
      check(sql).contains('TRIM(m.Nome) AS NomeMunicipio');
      check(sql).contains('REPLACE(REPLACE(REPLACE(TRIM(f.CEP)');
      check(sql).contains('COUNT(*) AS TotalCount');
      check(sql).contains(
        'ROW_NUMBER() OVER (ORDER BY b.CodEmpresa, b.CodFilial) AS Rn',
      );
      check(sql).contains(':codEmpresa');
      check(sql).contains(':codFilial');
      check(sql).contains(':startRow');
      check(sql).contains(':endRow');
      check(sql.contains('?')).isFalse();
    });
  });
}
