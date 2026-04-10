import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_mensal_labels.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_mensal_row.dart';

/// Result of [ResumoParcelasMensalRowMerger.mergeWithStats].
typedef ResumoParcelasMensalMergeResult = ({
  List<ResumoParcelasMensalRow> rows,
  int skippedInvalidInputRows,
});

/// Combines [ResumoParcelasMensalRow] from multiple agents by calendar month.
///
/// Use when the cross-agent report concatenates per-agent rows and the UI
/// needs one row per `(ano, mes)` with summed counts and values.
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
        <({int ano, int mes}), ({int quantidade, double valorTotal})>{};
    for (final row in rows) {
      final m = row.mes;
      if (m < 1 ||
          m > 12 ||
          !ResumoParcelasMensalLabels.isValidCalendarYear(row.ano)) {
        skippedInvalidInputRows++;
        continue;
      }
      final key = (ano: row.ano, mes: m);
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
        return c != 0 ? c : a.mes.compareTo(b.mes);
      });
    final merged = <ResumoParcelasMensalRow>[
      for (final k in keys)
        ResumoParcelasMensalRow(
          ano: k.ano,
          mes: k.mes,
          anoMes: ResumoParcelasMensalLabels.format(k.ano, k.mes),
          quantidade: byKey[k]!.quantidade,
          valorTotal: byKey[k]!.valorTotal,
        ),
    ];
    return (
      rows: merged,
      skippedInvalidInputRows: skippedInvalidInputRows,
    );
  }
}
