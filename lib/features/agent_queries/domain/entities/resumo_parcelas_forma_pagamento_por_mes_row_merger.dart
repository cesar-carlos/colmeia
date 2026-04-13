import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_forma_pagamento_por_mes_row.dart';

typedef _Key = ({
  int codEmpresa,
  int codFilial,
  String nomeUsuario,
  String anoMesDataVenda,
  String codFormaPagamento,
  String descricaoFormaPagamento,
});

/// Combines [ResumoParcelasFormaPagamentoPorMesRow] from multiple agents.
///
/// Groups by company, branch, user, sale month label, and payment method
/// (exact string match as returned from SQL). Sums `qtdVendas` and
/// `valorParcela` for matching keys.
abstract final class ResumoParcelasFormaPagamentoPorMesRowMerger {
  static List<ResumoParcelasFormaPagamentoPorMesRow> merge(
    Iterable<ResumoParcelasFormaPagamentoPorMesRow> rows,
  ) {
    final byKey = <_Key, ({int qtdVendas, double valorParcela})>{};
    for (final row in rows) {
      final key = (
        codEmpresa: row.codEmpresa,
        codFilial: row.codFilial,
        nomeUsuario: row.nomeUsuario,
        anoMesDataVenda: row.anoMesDataVenda,
        codFormaPagamento: row.codFormaPagamento,
        descricaoFormaPagamento: row.descricaoFormaPagamento,
      );
      final acc = byKey.putIfAbsent(
        key,
        () => (qtdVendas: 0, valorParcela: 0),
      );
      byKey[key] = (
        qtdVendas: acc.qtdVendas + row.qtdVendas,
        valorParcela: acc.valorParcela + row.valorParcela,
      );
    }
    final keys = byKey.keys.toList(growable: false)
      ..sort((a, b) {
        final m = a.anoMesDataVenda.compareTo(b.anoMesDataVenda);
        if (m != 0) {
          return m;
        }
        final e = a.codEmpresa.compareTo(b.codEmpresa);
        if (e != 0) {
          return e;
        }
        final f = a.codFilial.compareTo(b.codFilial);
        if (f != 0) {
          return f;
        }
        final u = a.nomeUsuario.compareTo(b.nomeUsuario);
        if (u != 0) {
          return u;
        }
        final c = a.codFormaPagamento.compareTo(b.codFormaPagamento);
        if (c != 0) {
          return c;
        }
        return a.descricaoFormaPagamento.compareTo(b.descricaoFormaPagamento);
      });
    return <ResumoParcelasFormaPagamentoPorMesRow>[
      for (final key in keys)
        ResumoParcelasFormaPagamentoPorMesRow(
          codEmpresa: key.codEmpresa,
          codFilial: key.codFilial,
          nomeUsuario: key.nomeUsuario,
          anoMesDataVenda: key.anoMesDataVenda,
          codFormaPagamento: key.codFormaPagamento,
          descricaoFormaPagamento: key.descricaoFormaPagamento,
          qtdVendas: byKey[key]!.qtdVendas,
          valorParcela: byKey[key]!.valorParcela,
        ),
    ];
  }
}
