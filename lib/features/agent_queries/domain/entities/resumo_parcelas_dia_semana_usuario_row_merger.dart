import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_dia_semana_labels.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_dia_semana_usuario_row.dart';

typedef _Key = ({
  int codEmpresa,
  int codFilial,
  String nomeUsuario,
  int diaSemanaNumero,
});

/// Combines [ResumoParcelasDiaSemanaUsuarioRow] from multiple agents.
///
/// Groups by company, branch, user name, and weekday number. The `diaSemana`
/// field always comes from [ResumoParcelasDiaSemanaLabels] so merged rows stay
/// consistent.
///
/// Summing `qtdVendas` across agents assumes each agent contributes disjoint
/// sale sets for the same key; overlapping mirrored data can inflate counts.
abstract final class ResumoParcelasDiaSemanaUsuarioRowMerger {
  static List<ResumoParcelasDiaSemanaUsuarioRow> merge(
    Iterable<ResumoParcelasDiaSemanaUsuarioRow> rows,
  ) {
    final byKey = <_Key, ({int qtdVendas, double valorParcela})>{};
    for (final row in rows) {
      final n = row.diaSemanaNumero;
      if (n < 1 || n > 7) {
        continue;
      }
      final key = (
        codEmpresa: row.codEmpresa,
        codFilial: row.codFilial,
        nomeUsuario: row.nomeUsuario,
        diaSemanaNumero: n,
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
        final e = a.codEmpresa.compareTo(b.codEmpresa);
        if (e != 0) {
          return e;
        }
        final f = a.codFilial.compareTo(b.codFilial);
        if (f != 0) {
          return f;
        }
        final u = a.nomeUsuario.compareTo(b.nomeUsuario);
        if (u != 0) {
          return u;
        }
        return a.diaSemanaNumero.compareTo(b.diaSemanaNumero);
      });
    return <ResumoParcelasDiaSemanaUsuarioRow>[
      for (final key in keys)
        ResumoParcelasDiaSemanaUsuarioRow(
          codEmpresa: key.codEmpresa,
          codFilial: key.codFilial,
          nomeUsuario: key.nomeUsuario,
          diaSemanaNumero: key.diaSemanaNumero,
          diaSemana: ResumoParcelasDiaSemanaLabels.labelFor(
            key.diaSemanaNumero,
          ),
          qtdVendas: byKey[key]!.qtdVendas,
          valorParcela: byKey[key]!.valorParcela,
        ),
    ];
  }
}
