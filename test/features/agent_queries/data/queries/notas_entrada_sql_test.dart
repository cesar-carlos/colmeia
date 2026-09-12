import 'package:checks/checks.dart';
import 'package:colmeia/features/agent_queries/data/queries/notas_entrada_sql.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('binds the active company and branch scope', () {
    final sql = _query();

    check(sql).contains("cc.Cancelada = 'N'");
    check(sql).contains('cc.CodEmpresa = prm.CodEmpresa');
    check(sql).contains('cc.CodFilial = prm.CodFilial');
  });

  test('binds page window and each optional date parameter once', () {
    final sql = _query(
      hasDataLancamentoInicio: true,
      hasDataLancamentoFim: true,
    );

    check(_count(sql, ':dataLancamentoInicio')).equals(1);
    check(_count(sql, ':dataLancamentoFim')).equals(1);
    check(_count(sql, ':codEmpresa')).equals(1);
    check(_count(sql, ':codFilial')).equals(1);
    check(_count(sql, ':startRow')).equals(1);
    check(_count(sql, ':endRow')).equals(1);
    check(_count(sql, ':nomeFornecedorPattern')).equals(1);
  });

  test('applies optional inclusive calendar-day filters to DataInclusao', () {
    final sql = _query(
      hasDataLancamentoInicio: true,
      hasDataLancamentoFim: true,
    );

    check(sql).contains('cc.DataInclusao >= prm.DataLancamentoInicio');
    check(sql).contains(
      'cc.DataInclusao < DATEADD(day, 1, prm.DataLancamentoFim)',
    );
  });

  test('numbers pages by launch date and purchase id with a total count', () {
    final sql = _query();

    check(sql).contains('COUNT(*) AS TotalCount');
    check(sql).contains('ROW_NUMBER() OVER');
    check(sql).contains('b.DataLancamento DESC');
    check(sql).contains('b.CompraId DESC');
    check(sql).contains('N.Rn BETWEEN :startRow AND :endRow');
    check(sql).not((it) => it.contains('SELECT TOP'));
  });

  test('filters suppliers with an optional accent-folded contains match', () {
    final sql = _query();

    check(sql).contains('prm.NomeFornecedorPattern IS NULL');
    check(sql).contains('LIKE');
    check(sql).contains('CAST(f.CodFornecedor AS VARCHAR(20))');
    check(sql).contains('f.cnpj_cpf');
    check(sql).contains('TRIM(f.RazaoSocial)');
    check(_count(sql, ':nomeFornecedorPattern')).equals(1);
  });

  test('does not send SQL comments', () {
    final sql = _query();

    check(sql).not((it) => it.contains('DECLARE'));
    check(sql).not((it) => it.contains('/*'));
  });
}

String _query({
  bool hasDataLancamentoInicio = false,
  bool hasDataLancamentoFim = false,
}) {
  return NotasEntradaSql.pagedQuery(
    hasDataLancamentoInicio: hasDataLancamentoInicio,
    hasDataLancamentoFim: hasDataLancamentoFim,
  );
}

int _count(String source, String needle) {
  var count = 0;
  var from = 0;
  while (true) {
    final index = source.indexOf(needle, from);
    if (index < 0) {
      return count;
    }
    count += 1;
    from = index + needle.length;
  }
}
