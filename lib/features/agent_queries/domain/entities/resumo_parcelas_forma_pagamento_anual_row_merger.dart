import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_forma_pagamento_anual_row.dart';

typedef _Key = ({int ano, String descricaoFormaPagamento});

/// Combines [ResumoParcelasFormaPagamentoAnualRow] from multiple agents.
///
/// Groups by year and payment method description (exact string match as
/// returned from SQL). Use for consolidated totals when the cross-agent
/// report exposes a simple concatenation of participant rows.
abstract final class ResumoParcelasFormaPagamentoAnualRowMerger {
  static List<ResumoParcelasFormaPagamentoAnualRow> merge(
    Iterable<ResumoParcelasFormaPagamentoAnualRow> rows,
  ) {
    final byKey = <_Key, ({int quantidade, double valorTotal})>{};
    for (final row in rows) {
      final key = (
        ano: row.ano,
        descricaoFormaPagamento: row.descricaoFormaPagamento,
      );
      final acc = byKey.putIfAbsent(
        key,
        () => (quantidade: 0, valorTotal: 0),
      );
      byKey[key] = (
        quantidade: acc.quantidade + row.quantidade,
        valorTotal: acc.valorTotal + row.valorTotal,
      );
    }
    final keys = byKey.keys.toList(growable: false)
      ..sort((a, b) {
        final c = a.ano.compareTo(b.ano);
        if (c != 0) {
          return c;
        }
        return a.descricaoFormaPagamento.compareTo(b.descricaoFormaPagamento);
      });
    return <ResumoParcelasFormaPagamentoAnualRow>[
      for (final key in keys)
        ResumoParcelasFormaPagamentoAnualRow(
          ano: key.ano,
          descricaoFormaPagamento: key.descricaoFormaPagamento,
          quantidade: byKey[key]!.quantidade,
          valorTotal: byKey[key]!.valorTotal,
        ),
    ];
  }
}
