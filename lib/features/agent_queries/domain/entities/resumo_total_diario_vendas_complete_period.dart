import 'package:colmeia/features/agent_queries/domain/entities/resumo_total_diario_vendas_row.dart';

/// One calendar day per row across the filter start/end dates (inclusive),
/// summing all branch rows into a single series for charting.
///
/// Output rows use `ResumoTotalDiarioVendasRow.aggregatedBranchSentinel` for
/// `codEmpresa` and `codFilial`.
abstract final class ResumoTotalDiarioVendasCompletePeriod {
  static List<ResumoTotalDiarioVendasRow> fill({
    required DateTime dataVendaInicio,
    required DateTime dataVendaFim,
    required Iterable<ResumoTotalDiarioVendasRow> rows,
  }) {
    final start = DateTime(
      dataVendaInicio.year,
      dataVendaInicio.month,
      dataVendaInicio.day,
    );
    final end = DateTime(
      dataVendaFim.year,
      dataVendaFim.month,
      dataVendaFim.day,
    );
    if (end.isBefore(start)) {
      return <ResumoTotalDiarioVendasRow>[];
    }

    final byDay = <DateTime, ({int qtdVendas, double valor})>{};
    for (final row in rows) {
      final d = DateTime(
        row.dataVenda.year,
        row.dataVenda.month,
        row.dataVenda.day,
      );
      final acc = byDay[d];
      if (acc == null) {
        byDay[d] = (
          qtdVendas: row.qtdVendas,
          valor: row.valorTotalDiarioVenda,
        );
      } else {
        byDay[d] = (
          qtdVendas: acc.qtdVendas + row.qtdVendas,
          valor: acc.valor + row.valorTotalDiarioVenda,
        );
      }
    }

    final out = <ResumoTotalDiarioVendasRow>[];
    var cursor = start;
    while (!cursor.isAfter(end)) {
      final acc = byDay[cursor];
      out.add(
        ResumoTotalDiarioVendasRow(
          codEmpresa: ResumoTotalDiarioVendasRow.aggregatedBranchSentinel,
          codFilial: ResumoTotalDiarioVendasRow.aggregatedBranchSentinel,
          dataVenda: cursor,
          qtdVendas: acc?.qtdVendas ?? 0,
          valorTotalDiarioVenda: acc?.valor ?? 0,
        ),
      );
      cursor = cursor.add(const Duration(days: 1));
    }
    return out;
  }
}
