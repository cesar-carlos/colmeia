import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_dia_semana_labels.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_dia_semana_row.dart';

/// Builds a fixed Sunday–Saturday list (numbers 1–7) for charts.
///
/// Missing weekdays get zero `qtdVendas` and `valorParcela`; duplicate numbers
/// are summed. Rows from multiple branches collapse into one series per weekday
/// using [ResumoParcelasDiaSemanaRow.aggregatedBranchSentinel] for company and
/// branch codes.
abstract final class ResumoParcelasDiaSemanaCompleteWeek {
  static List<ResumoParcelasDiaSemanaRow> fill(
    Iterable<ResumoParcelasDiaSemanaRow> rows,
  ) {
    final byNumero = <int, ({int qtdVendas, double valorParcela})>{};
    for (final row in rows) {
      final n = row.diaSemanaNumero;
      if (n < 1 || n > 7) {
        continue;
      }
      final acc = byNumero[n];
      if (acc == null) {
        byNumero[n] = (
          qtdVendas: row.qtdVendas,
          valorParcela: row.valorParcela,
        );
      } else {
        byNumero[n] = (
          qtdVendas: acc.qtdVendas + row.qtdVendas,
          valorParcela: acc.valorParcela + row.valorParcela,
        );
      }
    }
    return <ResumoParcelasDiaSemanaRow>[
      for (var n = 1; n <= 7; n++)
        ResumoParcelasDiaSemanaRow(
          codEmpresa: ResumoParcelasDiaSemanaRow.aggregatedBranchSentinel,
          codFilial: ResumoParcelasDiaSemanaRow.aggregatedBranchSentinel,
          diaSemanaNumero: n,
          diaSemana: ResumoParcelasDiaSemanaLabels.labelFor(n),
          qtdVendas: byNumero[n]?.qtdVendas ?? 0,
          valorParcela: byNumero[n]?.valorParcela ?? 0,
        ),
    ];
  }
}
