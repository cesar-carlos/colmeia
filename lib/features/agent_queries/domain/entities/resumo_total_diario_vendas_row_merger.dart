import 'package:colmeia/features/agent_queries/domain/entities/resumo_total_diario_vendas_row.dart';

/// Combines [ResumoTotalDiarioVendasRow] from multiple agents by company,
/// branch, and calendar sale day.
///
/// **Cross-agent semantics**: each agent contributes distinct branch keys in
/// typical deployments. Summing `qtdVendas` across agents for the same key
/// only matches DB truth when agent datasets do not overlap for that branch.
abstract final class ResumoTotalDiarioVendasRowMerger {
  static List<ResumoTotalDiarioVendasRow> merge(
    Iterable<ResumoTotalDiarioVendasRow> rows,
  ) {
    final byKey =
        <
          ({
            int codEmpresa,
            int codFilial,
            DateTime dataVenda,
          }),
          ({
            int qtdVendas,
            double valorTotalDiarioVenda,
          })
        >{};
    for (final row in rows) {
      final key = (
        codEmpresa: row.codEmpresa,
        codFilial: row.codFilial,
        dataVenda: DateTime(
          row.dataVenda.year,
          row.dataVenda.month,
          row.dataVenda.day,
        ),
      );
      final acc = byKey.putIfAbsent(
        key,
        () => (qtdVendas: 0, valorTotalDiarioVenda: 0),
      );
      byKey[key] = (
        qtdVendas: acc.qtdVendas + row.qtdVendas,
        valorTotalDiarioVenda:
            acc.valorTotalDiarioVenda + row.valorTotalDiarioVenda,
      );
    }
    final keys = byKey.keys.toList(growable: false)
      ..sort((a, b) {
        final byE = a.codEmpresa.compareTo(b.codEmpresa);
        if (byE != 0) {
          return byE;
        }
        final byF = a.codFilial.compareTo(b.codFilial);
        if (byF != 0) {
          return byF;
        }
        return a.dataVenda.compareTo(b.dataVenda);
      });
    return keys
        .map(
          (k) => ResumoTotalDiarioVendasRow(
            codEmpresa: k.codEmpresa,
            codFilial: k.codFilial,
            dataVenda: k.dataVenda,
            qtdVendas: byKey[k]!.qtdVendas,
            valorTotalDiarioVenda: byKey[k]!.valorTotalDiarioVenda,
          ),
        )
        .toList(growable: false);
  }
}
