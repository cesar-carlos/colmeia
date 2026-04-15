import 'package:colmeia/features/agent_queries/domain/entities/resumo_vendas_diarias_por_vendedor_row.dart';

typedef _Key = ({
  int codEmpresa,
  int codFilial,
  DateTime dataVendaDay,
  String anoMesDataVenda,
  int? codVendedor,
  String? nomeVendedor,
});

/// Combines [ResumoVendasDiariasPorVendedorRow] values from multiple agents.
///
/// Groups by the same dimensions as the SQL `GROUP BY`, summing `qtdVendas`
/// and `valorTotalVenda`. Nullable seller dimensions match SQL `NULL`
/// grouping.
///
/// The merge key does not include agent id: it assumes ERP keys are globally
/// unique across agents. If the same sale could appear in more than one agent
/// result, summing `qtdVendas` would overcount.
abstract final class ResumoVendasDiariasPorVendedorRowMerger {
  static List<ResumoVendasDiariasPorVendedorRow> merge(
    Iterable<ResumoVendasDiariasPorVendedorRow> rows,
  ) {
    final byKey = <_Key, ({int qtdVendas, double valorTotalVenda})>{};
    for (final row in rows) {
      final day = DateTime(
        row.dataVenda.year,
        row.dataVenda.month,
        row.dataVenda.day,
      );
      final key = (
        codEmpresa: row.codEmpresa,
        codFilial: row.codFilial,
        dataVendaDay: day,
        anoMesDataVenda: row.anoMesDataVenda,
        codVendedor: row.codVendedor,
        nomeVendedor: row.nomeVendedor,
      );
      final acc = byKey.putIfAbsent(
        key,
        () => (qtdVendas: 0, valorTotalVenda: 0.0),
      );
      byKey[key] = (
        qtdVendas: acc.qtdVendas + row.qtdVendas,
        valorTotalVenda: acc.valorTotalVenda + row.valorTotalVenda,
      );
    }
    final keys = byKey.keys.toList(growable: false)..sort(_compareKeys);
    return <ResumoVendasDiariasPorVendedorRow>[
      for (final key in keys)
        ResumoVendasDiariasPorVendedorRow(
          codEmpresa: key.codEmpresa,
          codFilial: key.codFilial,
          dataVenda: key.dataVendaDay,
          anoMesDataVenda: key.anoMesDataVenda,
          codVendedor: key.codVendedor,
          nomeVendedor: key.nomeVendedor,
          qtdVendas: byKey[key]!.qtdVendas,
          valorTotalVenda: byKey[key]!.valorTotalVenda,
        ),
    ];
  }

  static int _compareKeys(_Key a, _Key b) {
    var c = a.codEmpresa.compareTo(b.codEmpresa);
    if (c != 0) {
      return c;
    }
    c = a.codFilial.compareTo(b.codFilial);
    if (c != 0) {
      return c;
    }
    c = a.dataVendaDay.compareTo(b.dataVendaDay);
    if (c != 0) {
      return c;
    }
    c = a.anoMesDataVenda.compareTo(b.anoMesDataVenda);
    if (c != 0) {
      return c;
    }
    c = _compareNullableInt(a.codVendedor, b.codVendedor);
    if (c != 0) {
      return c;
    }
    return _compareNullableString(a.nomeVendedor, b.nomeVendedor);
  }

  static int _compareNullableInt(int? a, int? b) {
    if (a == null && b == null) {
      return 0;
    }
    if (a == null) {
      return -1;
    }
    if (b == null) {
      return 1;
    }
    return a.compareTo(b);
  }

  static int _compareNullableString(String? a, String? b) {
    if (a == null && b == null) {
      return 0;
    }
    if (a == null) {
      return -1;
    }
    if (b == null) {
      return 1;
    }
    return a.compareTo(b);
  }
}
