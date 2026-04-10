import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_mensal_labels.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_mensal_row.dart';

/// Builds one row per calendar month overlapping the closed sale date range.
///
/// Uses [DateTime.year] and [DateTime.month] for the same calendar boundaries
/// as the period filter and `AgentQueriesSqlLocalDate` SQL params. Missing
/// months get zero quantity and total; duplicate `(ano, mes)` are summed.
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
        <({int ano, int mes}), ({int quantidade, double valorTotal})>{};
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
        byKey[key] = (quantidade: row.quantidade, valorTotal: row.valorTotal);
      } else {
        byKey[key] = (
          quantidade: acc.quantidade + row.quantidade,
          valorTotal: acc.valorTotal + row.valorTotal,
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
          ano: y,
          mes: month,
          anoMes: ResumoParcelasMensalLabels.format(y, month),
          quantidade: acc?.quantidade ?? 0,
          valorTotal: acc?.valorTotal ?? 0,
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
