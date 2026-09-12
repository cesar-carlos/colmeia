import 'package:checks/checks.dart';
import 'package:colmeia/features/agent_queries/data/queries/resumo_vendas_diarias_por_vendedor_bairro_options_sql.dart';
import 'package:colmeia/features/agent_queries/data/queries/resumo_vendas_diarias_por_vendedor_municipio_options_sql.dart';
import 'package:colmeia/features/agent_queries/data/queries/resumo_vendas_diarias_por_vendedor_vendedor_options_sql.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final queries = <String, String>{
    'vendedor': ResumoVendasDiariasPorVendedorVendedorOptionsSql.query,
    'bairro': ResumoVendasDiariasPorVendedorBairroOptionsSql.query,
    'municipio': ResumoVendasDiariasPorVendedorMunicipioOptionsSql.query,
  };

  for (final entry in queries.entries) {
    test('${entry.key} binds limit and searchPattern once without TOP', () {
      final sql = entry.value;

      check(_count(sql, ':limit')).equals(1);
      check(_count(sql, ':searchPattern')).equals(1);
      check(sql).contains('CAST(:limit AS INTEGER)');
      check(sql).contains('CAST(:searchPattern AS VARCHAR(255))');
      check(sql).not((it) => it.contains('CAST(:searchPattern AS INTEGER)'));
      check(sql).contains('p.SearchPattern IS NULL');
      check(sql).contains('ROW_NUMBER() OVER');
      check(sql).contains('n.Rn <= p.MaxRows');
      check(sql).not((it) => it.contains('SELECT TOP'));
      check(sql).not((it) => it.contains("COALESCE(:searchPattern, '%')"));
    });
  }

  test('vendedor projects seller code and display name', () {
    const sql = ResumoVendasDiariasPorVendedorVendedorOptionsSql.query;

    check(sql).contains('FROM Vendedor v');
    check(sql).contains('n.CodVendedor');
    check(sql).contains('n.NomeVendedor');
  });

  test('bairro unions cliente and fornecedor labels', () {
    final sql = ResumoVendasDiariasPorVendedorBairroOptionsSql.query;

    check(sql).contains('FROM Cliente cli');
    check(sql).contains('FROM Fornecedor forn');
    check(sql).contains('UNION ALL');
    check(sql).contains('LEN(b.NomeBairro) > 3');
  });

  test('municipio reads cadastro names', () {
    final sql = ResumoVendasDiariasPorVendedorMunicipioOptionsSql.query;

    check(sql).contains('FROM Municipio m');
    check(sql).contains('LEN(b.NomeMunicipio) > 3');
  });
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
