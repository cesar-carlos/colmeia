import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_dia_semana_labels.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_dia_semana_row.dart';

/// Builds a fixed Sunday–Saturday list (numbers 1–7) for charts.
///
/// Missing weekdays get zero quantity and total; duplicate numbers are summed.
abstract final class ResumoParcelasDiaSemanaCompleteWeek {
  static List<ResumoParcelasDiaSemanaRow> fill(
    Iterable<ResumoParcelasDiaSemanaRow> rows,
  ) {
    final byNumero = <int, ({int quantidade, double valorTotal})>{};
    for (final row in rows) {
      final n = row.diaSemanaNumero;
      if (n < 1 || n > 7) {
        continue;
      }
      final acc = byNumero[n];
      if (acc == null) {
        byNumero[n] = (quantidade: row.quantidade, valorTotal: row.valorTotal);
      } else {
        byNumero[n] = (
          quantidade: acc.quantidade + row.quantidade,
          valorTotal: acc.valorTotal + row.valorTotal,
        );
      }
    }
    return <ResumoParcelasDiaSemanaRow>[
      for (var n = 1; n <= 7; n++)
        ResumoParcelasDiaSemanaRow(
          diaSemanaNumero: n,
          diaSemana: ResumoParcelasDiaSemanaLabels.labelFor(n),
          quantidade: byNumero[n]?.quantidade ?? 0,
          valorTotal: byNumero[n]?.valorTotal ?? 0,
        ),
    ];
  }
}
