import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_dia_semana_labels.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_dia_semana_row.dart';

/// Combines [ResumoParcelasDiaSemanaRow] from multiple agents.
///
/// Groups by weekday number. `diaSemana` always comes from
/// `ResumoParcelasDiaSemanaLabels` so merged rows stay consistent.
abstract final class ResumoParcelasDiaSemanaRowMerger {
  static List<ResumoParcelasDiaSemanaRow> merge(
    Iterable<ResumoParcelasDiaSemanaRow> rows,
  ) {
    final byNumero = <int, ({int quantidade, double valorTotal})>{};
    for (final row in rows) {
      final n = row.diaSemanaNumero;
      if (n < 1 || n > 7) {
        continue;
      }
      final existing = byNumero[n];
      if (existing == null) {
        byNumero[n] = (quantidade: row.quantidade, valorTotal: row.valorTotal);
      } else {
        byNumero[n] = (
          quantidade: existing.quantidade + row.quantidade,
          valorTotal: existing.valorTotal + row.valorTotal,
        );
      }
    }
    final numeros = byNumero.keys.toList(growable: false)..sort();
    return <ResumoParcelasDiaSemanaRow>[
      for (final n in numeros)
        ResumoParcelasDiaSemanaRow(
          diaSemanaNumero: n,
          diaSemana: ResumoParcelasDiaSemanaLabels.labelFor(n),
          quantidade: byNumero[n]!.quantidade,
          valorTotal: byNumero[n]!.valorTotal,
        ),
    ];
  }
}
