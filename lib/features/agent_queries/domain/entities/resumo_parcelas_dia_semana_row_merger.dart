import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_dia_semana_labels.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_dia_semana_row.dart';

/// Combines [ResumoParcelasDiaSemanaRow] from multiple agents.
///
/// Groups by company, branch, and weekday number. The `diaSemana` field always
/// comes from [ResumoParcelasDiaSemanaLabels] so merged rows stay consistent.
///
/// Summing `qtdVendas` across agents assumes each agent contributes disjoint
/// sale sets for the same key; overlapping mirrored data can inflate counts.
abstract final class ResumoParcelasDiaSemanaRowMerger {
  static List<ResumoParcelasDiaSemanaRow> merge(
    Iterable<ResumoParcelasDiaSemanaRow> rows,
  ) {
    final byKey =
        <
          String,
          ({
            int codEmpresa,
            int codFilial,
            int diaSemanaNumero,
            int qtdVendas,
            double valorParcela,
          })
        >{};
    for (final row in rows) {
      final n = row.diaSemanaNumero;
      if (n < 1 || n > 7) {
        continue;
      }
      final key = '${row.codEmpresa}|${row.codFilial}|$n';
      final existing = byKey[key];
      if (existing == null) {
        byKey[key] = (
          codEmpresa: row.codEmpresa,
          codFilial: row.codFilial,
          diaSemanaNumero: n,
          qtdVendas: row.qtdVendas,
          valorParcela: row.valorParcela,
        );
      } else {
        byKey[key] = (
          codEmpresa: existing.codEmpresa,
          codFilial: existing.codFilial,
          diaSemanaNumero: existing.diaSemanaNumero,
          qtdVendas: existing.qtdVendas + row.qtdVendas,
          valorParcela: existing.valorParcela + row.valorParcela,
        );
      }
    }
    final sortedKeys = byKey.keys.toList(growable: false)
      ..sort((a, b) {
        final va = byKey[a]!;
        final vb = byKey[b]!;
        final c = va.codEmpresa.compareTo(vb.codEmpresa);
        if (c != 0) {
          return c;
        }
        final f = va.codFilial.compareTo(vb.codFilial);
        if (f != 0) {
          return f;
        }
        return va.diaSemanaNumero.compareTo(vb.diaSemanaNumero);
      });
    return <ResumoParcelasDiaSemanaRow>[
      for (final key in sortedKeys)
        ResumoParcelasDiaSemanaRow(
          codEmpresa: byKey[key]!.codEmpresa,
          codFilial: byKey[key]!.codFilial,
          diaSemanaNumero: byKey[key]!.diaSemanaNumero,
          diaSemana: ResumoParcelasDiaSemanaLabels.labelFor(
            byKey[key]!.diaSemanaNumero,
          ),
          qtdVendas: byKey[key]!.qtdVendas,
          valorParcela: byKey[key]!.valorParcela,
        ),
    ];
  }
}
