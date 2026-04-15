import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_anual_row.dart';

typedef _Key = ({
  int codEmpresa,
  int codFilial,
  int anoDataVenda,
});

/// Combines `ResumoParcelasAnualRow` values from multiple agents.
///
/// Groups by company, branch, and sale calendar year. Sums `qtdVendas` and
/// `valorTotalVenda` for matching keys. Result order follows
/// `ResumoParcelasAnualSql` (`CodEmpresa`, `CodFilial`, `AnoDataVenda`).
///
/// If the same real-world sale could appear in more than one agent result,
/// summing `qtdVendas` across agents may overcount distinct sales.
abstract final class ResumoParcelasAnualRowMerger {
  static List<ResumoParcelasAnualRow> merge(
    Iterable<ResumoParcelasAnualRow> rows,
  ) {
    final byKey = <_Key, ({int qtdVendas, double valorTotalVenda})>{};
    for (final row in rows) {
      final key = (
        codEmpresa: row.codEmpresa,
        codFilial: row.codFilial,
        anoDataVenda: row.anoDataVenda,
      );
      final acc = byKey.putIfAbsent(
        key,
        () => (qtdVendas: 0, valorTotalVenda: 0),
      );
      byKey[key] = (
        qtdVendas: acc.qtdVendas + row.qtdVendas,
        valorTotalVenda: acc.valorTotalVenda + row.valorTotalVenda,
      );
    }
    final keys = byKey.keys.toList(growable: false)
      ..sort((a, b) {
        final e = a.codEmpresa.compareTo(b.codEmpresa);
        if (e != 0) {
          return e;
        }
        final f = a.codFilial.compareTo(b.codFilial);
        if (f != 0) {
          return f;
        }
        return a.anoDataVenda.compareTo(b.anoDataVenda);
      });
    return <ResumoParcelasAnualRow>[
      for (final key in keys)
        ResumoParcelasAnualRow(
          codEmpresa: key.codEmpresa,
          codFilial: key.codFilial,
          anoDataVenda: key.anoDataVenda,
          qtdVendas: byKey[key]!.qtdVendas,
          valorTotalVenda: byKey[key]!.valorTotalVenda,
        ),
    ];
  }
}
