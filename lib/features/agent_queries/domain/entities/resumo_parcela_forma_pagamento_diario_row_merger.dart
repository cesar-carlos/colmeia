import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcela_forma_pagamento_diario_row.dart';

typedef _Key = ({DateTime dataVendaDay, String descricaoFormaPagamento});

/// Combines [ResumoParcelaFormaPagamentoDiarioRow] from multiple agents.
///
/// Groups by calendar day and payment method description. Use when the
/// cross-agent report exposes a simple concatenation of participant rows.
abstract final class ResumoParcelaFormaPagamentoDiarioRowMerger {
  static List<ResumoParcelaFormaPagamentoDiarioRow> merge(
    Iterable<ResumoParcelaFormaPagamentoDiarioRow> rows,
  ) {
    final byKey = <_Key, ({int quantidade, double valorTotal})>{};
    for (final row in rows) {
      final day = DateTime(
        row.dataVenda.year,
        row.dataVenda.month,
        row.dataVenda.day,
      );
      final key = (
        dataVendaDay: day,
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
        final c = a.dataVendaDay.compareTo(b.dataVendaDay);
        if (c != 0) {
          return c;
        }
        return a.descricaoFormaPagamento.compareTo(b.descricaoFormaPagamento);
      });
    return <ResumoParcelaFormaPagamentoDiarioRow>[
      for (final key in keys)
        ResumoParcelaFormaPagamentoDiarioRow(
          dataVenda: key.dataVendaDay,
          descricaoFormaPagamento: key.descricaoFormaPagamento,
          quantidade: byKey[key]!.quantidade,
          valorTotal: byKey[key]!.valorTotal,
        ),
    ];
  }
}
