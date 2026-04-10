import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_anual_row.dart';

/// Combines [ResumoParcelasAnualRow] from multiple agents by calendar year.
///
/// Use when the cross-agent report concatenates per-agent rows and the UI
/// needs one row per `ano` with summed counts and values.
abstract final class ResumoParcelasAnualRowMerger {
  static List<ResumoParcelasAnualRow> merge(
    Iterable<ResumoParcelasAnualRow> rows,
  ) {
    final byAno = <int, ({int quantidade, double valorTotal})>{};
    for (final row in rows) {
      final acc = byAno.putIfAbsent(
        row.ano,
        () => (quantidade: 0, valorTotal: 0),
      );
      byAno[row.ano] = (
        quantidade: acc.quantidade + row.quantidade,
        valorTotal: acc.valorTotal + row.valorTotal,
      );
    }
    final anos = byAno.keys.toList(growable: false)..sort();
    return <ResumoParcelasAnualRow>[
      for (final ano in anos)
        ResumoParcelasAnualRow(
          ano: ano,
          quantidade: byAno[ano]!.quantidade,
          valorTotal: byAno[ano]!.valorTotal,
        ),
    ];
  }
}
