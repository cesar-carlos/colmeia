import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcela_forma_pagamento_diario_row.dart';

typedef _Key = ({
  int codEmpresa,
  int codFilial,
  int codProdutoVendido,
  String origem,
  int codOrigem,
  DateTime dataVendaDay,
  String anoMesDataVenda,
  String nomeUsuario,
  int? codVendedor,
  String? nomeVendedor,
});

/// Combines ResumoVendaProdutoDiarioRow values from multiple agents.
///
/// Groups by the same dimensions as the SQL GROUP BY, summing qtdVendas and
/// valorTotalVenda. Nullable seller dimensions match SQL NULL grouping.
///
/// The merge key does not include agent id: it assumes ERP keys such as
/// codProdutoVendido are globally unique across agents. If two agents could
/// reuse the same key for different sales, sums would be wrong and the data
/// model for multi-agent runs would need revisiting.
abstract final class ResumoVendaProdutoDiarioRowMerger {
  static List<ResumoVendaProdutoDiarioRow> merge(
    Iterable<ResumoVendaProdutoDiarioRow> rows,
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
        codProdutoVendido: row.codProdutoVendido,
        origem: row.origem,
        codOrigem: row.codOrigem,
        dataVendaDay: day,
        anoMesDataVenda: row.anoMesDataVenda,
        nomeUsuario: row.nomeUsuario,
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
    return <ResumoVendaProdutoDiarioRow>[
      for (final key in keys)
        ResumoVendaProdutoDiarioRow(
          codEmpresa: key.codEmpresa,
          codFilial: key.codFilial,
          codProdutoVendido: key.codProdutoVendido,
          origem: key.origem,
          codOrigem: key.codOrigem,
          dataVenda: key.dataVendaDay,
          anoMesDataVenda: key.anoMesDataVenda,
          nomeUsuario: key.nomeUsuario,
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
    c = a.codProdutoVendido.compareTo(b.codProdutoVendido);
    if (c != 0) {
      return c;
    }
    c = a.origem.compareTo(b.origem);
    if (c != 0) {
      return c;
    }
    c = a.codOrigem.compareTo(b.codOrigem);
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
    c = a.nomeUsuario.compareTo(b.nomeUsuario);
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
