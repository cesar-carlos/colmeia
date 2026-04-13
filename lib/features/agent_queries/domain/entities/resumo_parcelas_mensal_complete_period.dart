import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_mensal_labels.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_mensal_row.dart';

/// Builds one row per calendar month overlapping the closed sale date range.
///
/// Uses [DateTime.year] and [DateTime.month] for the same calendar boundaries
/// as the period filter and `AgentQueriesSqlLocalDate` SQL params. Missing
/// months get zero [ResumoParcelasMensalRow.qtdVendas] and
/// [ResumoParcelasMensalRow.valorParcela].
///
/// Input rows may include multiple `(codEmpresa, codFilial)` per month; before
/// emitting the series, values are **collapsed** to a single row per
/// `(ano, mes)` by summing [ResumoParcelasMensalRow.qtdVendas] and
/// [ResumoParcelasMensalRow.valorParcela] across branches. That sum of
/// `qtdVendas` is a sum of per-branch distinct sale counts, not a single
/// global `COUNT(DISTINCT)` across branches (sale ids include branch in SQL).
/// Output rows use [ResumoParcelasMensalRow.aggregatedBranchSentinel] for
/// `codEmpresa` and `codFilial` to mark that aggregation.
///
/// Invalid `mes` or rows with invalid calendar [ResumoParcelasMensalRow.ano]
/// for [ResumoParcelasMensalLabels.isValidCalendarYear] are ignored when
/// aggregating inputs.
abstract final class ResumoParcelasMensalCompletePeriod {
  static List<ResumoParcelasMensalRow> fill({
    required DateTime dataVendaInicio,
    required DateTime dataVendaFim,
    required Iterable<ResumoParcelasMensalRow> rows,
  }) {
    if (dataVendaFim.isBefore(dataVendaInicio)) {
      return <ResumoParcelasMensalRow>[];
    }

    final byKey =
        <({int ano, int mes}), ({int qtdVendas, double valorParcela})>{};
    for (final row in rows) {
      final m = row.mes;
      if (m < 1 || m > 12) {
        continue;
      }
      if (!ResumoParcelasMensalLabels.isValidCalendarYear(row.ano)) {
        continue;
      }
      final key = (ano: row.ano, mes: m);
      final acc = byKey[key];
      if (acc == null) {
        byKey[key] = (qtdVendas: row.qtdVendas, valorParcela: row.valorParcela);
      } else {
        byKey[key] = (
          qtdVendas: acc.qtdVendas + row.qtdVendas,
          valorParcela: acc.valorParcela + row.valorParcela,
        );
      }
    }

    var y = dataVendaInicio.year;
    var month = dataVendaInicio.month;
    final endY = dataVendaFim.year;
    final endM = dataVendaFim.month;

    final out = <ResumoParcelasMensalRow>[];
    while (y < endY || (y == endY && month <= endM)) {
      final key = (ano: y, mes: month);
      final acc = byKey[key];
      out.add(
        ResumoParcelasMensalRow(
          codEmpresa: ResumoParcelasMensalRow.aggregatedBranchSentinel,
          codFilial: ResumoParcelasMensalRow.aggregatedBranchSentinel,
          ano: y,
          mes: month,
          anoMes: ResumoParcelasMensalLabels.format(y, month),
          qtdVendas: acc?.qtdVendas ?? 0,
          valorParcela: acc?.valorParcela ?? 0,
        ),
      );
      if (month == 12) {
        y++;
        month = 1;
      } else {
        month++;
      }
    }
    return out;
  }
}
