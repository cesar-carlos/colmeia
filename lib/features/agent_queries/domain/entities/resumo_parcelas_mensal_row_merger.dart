import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_mensal_labels.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_mensal_row.dart';

/// Result of [ResumoParcelasMensalRowMerger.mergeWithStats].
typedef ResumoParcelasMensalMergeResult = ({
  List<ResumoParcelasMensalRow> rows,
  int skippedInvalidInputRows,
});

/// Combines [ResumoParcelasMensalRow] from multiple agents by company, branch,
/// and calendar month.
///
/// Use when the cross-agent report concatenates per-agent rows and the UI
/// needs one row per `(codEmpresa, codFilial, ano, mes)` with summed counts and
/// values.
///
/// **Cross-agent semantics**: each agent row carries `qtdVendas` from
/// `COUNT(DISTINCT Id)` on that agent's database. Summing across agents is only
/// correct when the same logical sale cannot appear under the same
/// `(codEmpresa, codFilial, ano, mes)` from two participants (disjoint data
/// per agent). If agents mirror the same dataset, merged counts and amounts
/// can be overstated.
abstract final class ResumoParcelasMensalRowMerger {
  static List<ResumoParcelasMensalRow> merge(
    Iterable<ResumoParcelasMensalRow> rows,
  ) {
    return mergeWithStats(rows).rows;
  }

  /// Like [merge], plus how many input rows were skipped (`mes` not in 1..12 or
  /// `ano` outside `ResumoParcelasMensalLabels` calendar bounds).
  static ResumoParcelasMensalMergeResult mergeWithStats(
    Iterable<ResumoParcelasMensalRow> rows,
  ) {
    var skippedInvalidInputRows = 0;
    final byKey =
        <
          ({
            int codEmpresa,
            int codFilial,
            int ano,
            int mes,
          }),
          ({
            int qtdVendas,
            double valorParcela,
          })
        >{};
    for (final row in rows) {
      final m = row.mes;
      if (m < 1 ||
          m > 12 ||
          !ResumoParcelasMensalLabels.isValidCalendarYear(row.ano)) {
        skippedInvalidInputRows++;
        continue;
      }
      final key = (
        codEmpresa: row.codEmpresa,
        codFilial: row.codFilial,
        ano: row.ano,
        mes: m,
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
        final byEmpresa = a.codEmpresa.compareTo(b.codEmpresa);
        if (byEmpresa != 0) {
          return byEmpresa;
        }
        final byFilial = a.codFilial.compareTo(b.codFilial);
        if (byFilial != 0) {
          return byFilial;
        }
        final byAno = a.ano.compareTo(b.ano);
        return byAno != 0 ? byAno : a.mes.compareTo(b.mes);
      });
    final merged = <ResumoParcelasMensalRow>[
      for (final k in keys)
        ResumoParcelasMensalRow(
          codEmpresa: k.codEmpresa,
          codFilial: k.codFilial,
          ano: k.ano,
          mes: k.mes,
          anoMes: ResumoParcelasMensalLabels.format(k.ano, k.mes),
          qtdVendas: byKey[k]!.qtdVendas,
          valorParcela: byKey[k]!.valorParcela,
        ),
    ];
    return (
      rows: merged,
      skippedInvalidInputRows: skippedInvalidInputRows,
    );
  }
}
