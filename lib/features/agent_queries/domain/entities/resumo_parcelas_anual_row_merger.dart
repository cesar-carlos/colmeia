import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_anual_row.dart';

typedef _Key = ({
  int codEmpresa,
  int codFilial,
  int anoDataVenda,
  String codFormaPagamento,
  String descricaoFormaPagamento,
});

/// Combines [ResumoParcelasAnualRow] from multiple agents.
///
/// Groups by company, branch, sale year, and payment method (exact string
/// match as returned from SQL). Sums `qtdVendas` and `valorParcela` for
/// matching keys.
///
/// If the same real-world sale could appear in more than one agent result,
/// summing `qtdVendas` across agents may overcount distinct sales.
abstract final class ResumoParcelasAnualRowMerger {
  static List<ResumoParcelasAnualRow> merge(
    Iterable<ResumoParcelasAnualRow> rows,
  ) {
    final byKey = <_Key, ({int qtdVendas, double valorParcela})>{};
    for (final row in rows) {
      final key = (
        codEmpresa: row.codEmpresa,
        codFilial: row.codFilial,
        anoDataVenda: row.anoDataVenda,
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
        final y = a.anoDataVenda.compareTo(b.anoDataVenda);
        if (y != 0) {
          return y;
        }
        final e = a.codEmpresa.compareTo(b.codEmpresa);
        if (e != 0) {
          return e;
        }
        final f = a.codFilial.compareTo(b.codFilial);
        if (f != 0) {
          return f;
        }
        final c = a.codFormaPagamento.compareTo(b.codFormaPagamento);
        if (c != 0) {
          return c;
        }
        return a.descricaoFormaPagamento.compareTo(b.descricaoFormaPagamento);
      });
    return <ResumoParcelasAnualRow>[
      for (final key in keys)
        ResumoParcelasAnualRow(
          codEmpresa: key.codEmpresa,
          codFilial: key.codFilial,
          anoDataVenda: key.anoDataVenda,
          codFormaPagamento: key.codFormaPagamento,
          descricaoFormaPagamento: key.descricaoFormaPagamento,
          qtdVendas: byKey[key]!.qtdVendas,
          valorParcela: byKey[key]!.valorParcela,
        ),
    ];
  }
}
