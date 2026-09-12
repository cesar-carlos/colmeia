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

  test('numbers pages by launch date and purchase id with catalog totals', () {
    final sql = _query();

    check(sql).contains('COUNT(*) AS TotalCount');
    check(sql).contains(
      'CAST(COALESCE(SUM(ValorTotalCompra), 0) AS DOUBLE PRECISION) AS TotalValorCompra',
    );
    check(sql).contains('Tot.TotalValorCompra');
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

  test('summary groups Base by supplier identity and sums purchase total', () {
    final sql = _summaryQuery();

    check(sql).contains('CAST(SUM(b.ValorTotalCompra) AS DOUBLE PRECISION)');
    check(sql).contains('COUNT(*) AS QtdNotas');
    check(sql).contains(
      'SUM(b.ValorTotalCompra) / NULLIF(COUNT(*), 0) AS DOUBLE PRECISION',
    );
    check(sql).contains('AS TicketMedio');
    check(sql).contains('N.QtdNotas');
    check(sql).contains('N.TicketMedio');
    check(sql).contains('N.ValorTotalCompra');
    check(sql.indexOf('N.QtdNotas')).isLessThan(sql.indexOf('N.TicketMedio'));
    check(sql.indexOf('N.TicketMedio')).isLessThan(
      sql.indexOf('N.ValorTotalCompra'),
    );
    check(sql).contains('GROUP BY');
    check(sql).contains('b.CodFornecedor');
    check(sql).contains('b.NomeFornecedor');
    check(sql).contains('b.NomeFantasiaFornecedor');
    check(sql).contains('b.CnpjCpfFornecedor');
    check(sql).contains('COUNT(*) AS TotalCount');
    check(sql).contains(
      'CAST(COALESCE(SUM(ValorTotalCompra), 0) AS DOUBLE PRECISION) AS TotalValorCompra',
    );
    check(sql).contains('FROM Agrupado');
    check(sql).contains('Tot.TotalValorCompra');
    check(sql).contains('a.ValorTotalCompra DESC');
    check(sql).contains('a.CodFornecedor ASC');
    check(sql).contains('N.Rn BETWEEN :startRow AND :endRow');
    check(sql).not((it) => it.contains('SELECT TOP'));
    check(sql).not((it) => it.contains('AS DOUBLE\n'));
    check(sql).not((it) => it.contains('AS DOUBLE,'));
  });

  test('summary binds each parameter once and keeps the supplier LIKE', () {
    final sql = _summaryQuery(
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
    check(sql).contains('prm.NomeFornecedorPattern IS NULL');
    check(sql).contains('CAST(f.CodFornecedor AS VARCHAR(20))');
    check(sql).contains("cc.Cancelada = 'N'");
  });

  test('binds CodFornecedor equality only when requested', () {
    final notes = _query();
    final notesWithCode = _query(hasCodFornecedor: true);
    final summary = _summaryQuery();
    final summaryWithCode = _summaryQuery(hasCodFornecedor: true);

    check(notes).not((it) => it.contains(':codFornecedor'));
    check(notes)
        .not((it) => it.contains('cc.CodFornecedor = prm.CodFornecedor'));
    check(_count(notesWithCode, ':codFornecedor')).equals(1);
    check(notesWithCode).contains('CAST(:codFornecedor AS INTEGER)');
    check(notesWithCode).contains('cc.CodFornecedor = prm.CodFornecedor');

    check(summary).not((it) => it.contains(':codFornecedor'));
    check(summary).not(
      (it) => it.contains('cc.CodFornecedor = prm.CodFornecedor'),
    );
    check(_count(summaryWithCode, ':codFornecedor')).equals(1);
    check(summaryWithCode).contains('cc.CodFornecedor = prm.CodFornecedor');
  });
}

String _query({
  bool hasDataLancamentoInicio = false,
  bool hasDataLancamentoFim = false,
  bool hasCodFornecedor = false,
}) {
  return NotasEntradaSql.pagedQuery(
    hasDataLancamentoInicio: hasDataLancamentoInicio,
    hasDataLancamentoFim: hasDataLancamentoFim,
    hasCodFornecedor: hasCodFornecedor,
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

String _summaryQuery({
  bool hasDataLancamentoInicio = false,
  bool hasDataLancamentoFim = false,
  bool hasCodFornecedor = false,
}) {
  return NotasEntradaSql.pagedSupplierSummaryQuery(
    hasDataLancamentoInicio: hasDataLancamentoInicio,
    hasDataLancamentoFim: hasDataLancamentoFim,
    hasCodFornecedor: hasCodFornecedor,
  );
}
